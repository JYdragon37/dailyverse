import SwiftUI
import UIKit
import Combine
import CoreLocation
import FirebaseAnalytics
import FirebaseCrashlytics

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentMode: AppMode = AppMode.current()
    @Published var currentVerse: Verse?
    @Published var currentImage: VerseImage?
    @Published var currentBackground: BackgroundImage?   // #3 시간대별 배경
    @Published var weather: WeatherData?
    @Published var isLoading: Bool = false
    @Published var showAlarmCTA: Bool = false
    @Published var toastMessage: String?
    @Published var isSavedCurrentVerse: Bool = false

    // MARK: - Private State

    private var isTogglingSave = false

    private var modeCheckTimer: AnyCancellable?
    private var locationCancellables: Set<AnyCancellable> = []
    private var toastDismissTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let verseRepository: VerseRepository
    private let weatherService: WeatherServiceProtocol
    private let cacheManager: DailyCacheManager
    private let alarmRepository: AlarmRepository
    private let authManager: AuthManager
    private let subscriptionManager: SubscriptionManager
    private let upsellManager: UpsellManager
    private let permissionManager: PermissionManager

    // MARK: - Init

    init(
        verseRepository: VerseRepository = VerseRepository.shared,
        weatherService: WeatherServiceProtocol = WeatherService(),
        cacheManager: DailyCacheManager = DailyCacheManager.shared,
        alarmRepository: AlarmRepository = AlarmRepository(),
        authManager: AuthManager,
        subscriptionManager: SubscriptionManager,
        upsellManager: UpsellManager,
        permissionManager: PermissionManager
    ) {
        self.verseRepository = verseRepository
        self.weatherService = weatherService
        self.cacheManager = cacheManager
        self.alarmRepository = alarmRepository
        self.authManager = authManager
        self.subscriptionManager = subscriptionManager
        self.upsellManager = upsellManager
        self.permissionManager = permissionManager

        // 주의: init()에서 로컬 캐시로 동기 세팅하지 않음
        // 서버(app_config/today_verse)가 다른 말씀을 가리킬 경우 캐시가 서버를 덮어쓰는 버그 방지
        // loadVerse()가 비동기로 서버 우선 조회 후 세팅

        startModeCheckTimer()
        evaluateAlarmCTA()
        observeLocationUpdates()
    }

    deinit {
        modeCheckTimer?.cancel()
        toastDismissTask?.cancel()
    }

    // MARK: - Public Methods

    /// 앱 진입/포그라운드 복귀 시 전체 데이터 로드
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // 모드 갱신
        let latestMode = AppMode.current()
        if latestMode != currentMode {
            currentMode = latestMode
        }
        let mode = currentMode

        // 말씀을 가장 먼저, 날씨와 병렬 로드 → 글귀가 최대한 빨리 표시됨
        async let verseTask: () = loadVerse(for: mode)
        async let weatherTask: () = loadWeatherIfPermitted()
        await verseTask
        await weatherTask

        // 배경/이미지는 말씀 표시 후 백그라운드에서 로드
        await syncPinnedImagesIfNeeded()
        async let bgTask: () = loadBackground(for: mode)
        async let imgTask: () = loadImage(for: mode)
        await bgTask
        await imgTask

        // 알람 CTA 재평가
        evaluateAlarmCTA()

        // Design Ref: §6 — 위치권한 온보딩 제거 → 홈탭 첫 진입 시 요청
        checkAndRequestLocationIfNeeded()
    }

    /// 포그라운드 복귀 시 날씨만 갱신 (백그라운드 복귀 등 자동 갱신)
    func refreshWeather() async {
        await loadWeatherIfPermitted()
    }

    /// 수동 새로고침 — 캐시 강제 초기화 후 API 재요청 (AQI 포함)
    func forceRefreshWeather() async {
        WeatherCacheManager().clear()
        await loadWeatherIfPermitted()
    }

    /// 말씀 저장 여부 확인 (말씀 변경 시 호출)
    func checkIfSaved() async {
        guard authManager.isLoggedIn, let userId = authManager.userId,
              let verseId = currentVerse?.id else {
            isSavedCurrentVerse = false
            return
        }
        let repo = SavedVerseRepository()
        let all = (try? await repo.fetchAll(userId: userId)) ?? []
        isSavedCurrentVerse = all.contains { $0.verseId == verseId }
    }

    /// 말씀 저장 토글 — 이미 저장됐으면 삭제, 아니면 저장
    func toggleSave(displayedImageUrl: String? = nil) {
        guard let verse = currentVerse else { return }

        guard authManager.isLoggedIn, let userId = authManager.userId else {
            let pending = makeSavedVerse(from: verse, displayedImageUrl: displayedImageUrl)
            authManager.setPendingSave(pending)
            return
        }

        guard !isTogglingSave else { return }
        isTogglingSave = true
        // 낙관적 업데이트 — 즉시 UI 반영
        let wasSaved = isSavedCurrentVerse
        isSavedCurrentVerse = !wasSaved

        if wasSaved {
            // 삭제
            Task {
                defer { isTogglingSave = false }
                let repo = SavedVerseRepository()
                let all = (try? await repo.fetchAll(userId: userId)) ?? []
                if let target = all.first(where: { $0.verseId == verse.id }) {
                    try? await repo.delete(id: target.id, userId: userId)
                }
                Analytics.logEvent("verse_unsaved", parameters: ["verse_id": verse.id])
                showToast("저장이 취소되었습니다")
            }
        } else {
            // 저장
            let savedVerse = makeSavedVerse(from: verse, displayedImageUrl: displayedImageUrl)
            Task {
                defer { isTogglingSave = false }
                do {
                    let repo = SavedVerseRepository()
                    try await repo.save(savedVerse, userId: userId)
                    Analytics.logEvent("verse_saved", parameters: ["verse_id": verse.id])
                    showToast("저장되었습니다")
                } catch {
                    isSavedCurrentVerse = wasSaved  // 실패 시 롤백
                    showToast("저장에 실패했어요. 다시 시도해주세요")
                    Crashlytics.crashlytics().record(error: error)
                }
            }
        }
    }

    /// 말씀 저장 (레거시 — pendingSave 로그인 후 자동 저장에서만 사용)
    func saveVerse(displayedImageUrl: String? = nil) {
        guard let verse = currentVerse else { return }
        guard authManager.isLoggedIn, let userId = authManager.userId else {
            let pending = makeSavedVerse(from: verse, displayedImageUrl: displayedImageUrl)
            authManager.setPendingSave(pending)
            return
        }
        let savedVerse = makeSavedVerse(from: verse, displayedImageUrl: displayedImageUrl)
        Task {
            do {
                let repo = SavedVerseRepository()
                try await repo.save(savedVerse, userId: userId)
                isSavedCurrentVerse = true
                showToast("저장되었습니다")
            } catch {
                showToast("저장에 실패했어요. 다시 시도해주세요")
            }
        }
    }

    // nextVerse 제거됨 — 다음 말씀 기능 없음 (모든 유저 동일 말씀 정책)

    // MARK: - Private: Data Loading

    /// #3 시간대별 배경 이미지 로드 (background_images 컬렉션)
    /// 날씨 조건을 전달해 precipitation 계열(rainy/snowy) 이미지를 날씨에 맞게 필터링한 뒤 랜덤 선택
    private func loadBackground(for mode: AppMode) async {
        // 날씨 로드 전에도 동작하도록 fallback: 날씨 없으면 "all" 사용
        let condition = weather?.condition ?? "all"
        do {
            let candidates = try await FirestoreService().fetchBackgroundImages(for: mode, weatherCondition: condition)
            currentBackground = candidates.randomElement()
        } catch {
            currentBackground = nil
        }
    }

    /// Bug C 수정: 로그인 유저의 Firestore pinnedImages를 UserDefaults에 동기화
    /// 다른 기기에서 설정한 핀이 반영되도록 최초 로드 시 1회 수행
    private func syncPinnedImagesIfNeeded() async {
        guard let userId = authManager.userId else { return }
        guard let user = try? await FirestoreService().fetchUser(uid: userId) else { return }
        for mode in AppMode.allCases {
            if let pinnedId = user.pinnedImages.pinnedImageId(for: mode) {
                UserDefaults.standard.set(pinnedId, forKey: "pinnedImage_\(mode.rawValue)")
            }
        }
    }

    private func loadVerse(for mode: AppMode) async {
        // 조기 반환 없음 — VerseRepository.currentVerse()가 서버 우선으로 처리
        // 서버 ID == 현재 캐시 ID면 내부에서 빠른 경로로 반환 (Firestore 1회 read만)
        let verse = await verseRepository.currentVerse(for: mode, weather: weather)
        currentVerse = verse
    }

    private func loadImage(for mode: AppMode) async {
        do {
            // daily_cards 이미지 우선: 절기일에 특별 이미지 풀에서 랜덤 선택
            if let card = try? await FirestoreService().fetchDailyCard(for: Date(), mode: mode),
               !card.imageIds.isEmpty,
               let randomId = card.imageIds.randomElement(),
               let dailyImage = try? await FirestoreService().fetchDailyCardImage(id: randomId) {
                currentImage = dailyImage
                #if DEBUG
                print("🖼️ [Image] Daily card image: \(dailyImage.id) | event: \(card.eventName ?? "-")")
                #endif
                return
            }

            // 일반 날: 스코어링 알고리즘으로 선택
            let images = try await verseRepository.fetchImages()
            #if DEBUG
            print("🖼️ [Image] Fetched \(images.count)개, mode=\(mode.rawValue)")
            #endif
            let pinnedId = UserDefaults.standard.string(forKey: "pinnedImage_\(mode.rawValue)")
            currentImage = selectImage(from: images, mode: mode, pinnedImageId: pinnedId)
            #if DEBUG
            print("🖼️ [Image] Selected: \(currentImage?.id ?? "nil")")
            #endif
        } catch {
            #if DEBUG
            print("🖼️ [Image] 로드 실패: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadWeatherIfPermitted() async {
        guard permissionManager.locationAuthorized else { return }

        // 1. @Published currentLocation 우선, 없으면 CLLocationManager 캐시 사용
        let location: CLLocation
        if let recent = permissionManager.currentLocation {
            location = recent
        } else if let cached = permissionManager.locationManager.location {
            // CLLocationManager가 이미 캐시하고 있는 마지막 위치 사용
            location = cached
        } else {
            // 위치가 전혀 없으면 요청 후 delegate 콜백으로 재시도
            permissionManager.locationManager.requestLocation()
            return
        }

        do {
            weather = try await weatherService.fetchWeather(for: location)
        } catch {
            // 날씨 실패는 토스트 없이 조용히 처리 (말씀 경험이 핵심)
            // 기존 캐시가 있으면 유지됨 (WeatherService 내부 처리)
            #if DEBUG
            print("⚠️ [Weather] 날씨 로드 실패: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Private: Image Selection

    private func selectImage(from images: [VerseImage], mode: AppMode, pinnedImageId: String? = nil) -> VerseImage? {
        // v5.1: is_sacred_safe == true인 이미지만 홈/알람 배경 사용
        let safe = images.filter { $0.status == "active" && $0.isHomeSafe }
        guard !safe.isEmpty else { return nil }

        // v5.1: Gallery 핀 이미지 우선 적용
        if let pinnedId = pinnedImageId,
           let pinned = safe.first(where: { $0.id == pinnedId }) {
            return pinned
        }

        let season = currentSeasonTag()
        let weatherCondition = weather?.condition ?? "any"
        let currentThemes = mode.themes
        let currentMoods = mode.moods

        // 모드 필터 우선 적용 (구 mode 값 호환 포함)
        let modeFiltered = safe.filter { mode.matchesImageMode($0.mode) }
        let pool = modeFiltered.isEmpty ? safe : modeFiltered

        // 스코어 산정
        let scored = pool.map { image -> (VerseImage, Int) in
            var score = 0
            score += image.theme.contains("all") ? 3 : image.theme.filter { currentThemes.contains($0) }.count * 3
            score += image.mood.contains("all") ? 2 : image.mood.filter { currentMoods.contains($0) }.count * 2
            if image.weather.contains(weatherCondition) || image.weather.contains("any") { score += 2 }
            if image.season.contains(season) || image.season.contains("all") { score += 1 }

            // 톤 우선순위: AppMode.preferredImageTone 활용 (8 Zone 대응)
            let preferredTone = mode.preferredImageTone
            if image.tone == preferredTone { score += 2 }
            else if image.tone == "mid" { score += 1 }
            return (image, score)
        }

        let maxScore = scored.map { $0.1 }.max() ?? 0
        let topImages = scored.filter { $0.1 == maxScore }.map { $0.0 }
        return topImages.randomElement()
    }

    private func currentSeasonTag() -> String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: return "spring"
        case 6...8: return "summer"
        case 9...11: return "autumn"
        default: return "winter"
        }
    }

    // MARK: - Private: Location Permission (Design Ref: §6)

    /// 온보딩에서 제거된 위치권한 → 홈탭 첫 진입 시 한 번만 요청
    private func checkAndRequestLocationIfNeeded() {
        let alreadyRequested = UserDefaults.standard.bool(forKey: OnboardingKey.locationRequested.rawValue)
        guard !alreadyRequested else { return }
        guard permissionManager.locationStatus == .notDetermined else { return }
        Task {
            await permissionManager.requestLocationPermission()
            UserDefaults.standard.set(true, forKey: OnboardingKey.locationRequested.rawValue)
        }
    }

    // MARK: - Private: Alarm CTA

    /// 알람 0개 + 앱 설치 후 3일 이내일 때 CTA 노출
    private func evaluateAlarmCTA() {
        let alarmCount = alarmRepository.count()
        guard alarmCount == 0 else {
            showAlarmCTA = false
            return
        }

        let installDate: Date
        if let stored = UserDefaults.standard.object(forKey: "installDate") as? Date {
            installDate = stored
        } else {
            // 최초 실행 시 설치일 기록
            let now = Date()
            UserDefaults.standard.set(now, forKey: "installDate")
            installDate = now
        }

        let daysSinceInstall = Calendar.current.dateComponents(
            [.day], from: installDate, to: Date()
        ).day ?? 0

        showAlarmCTA = daysSinceInstall <= 3
    }

    // MARK: - Private: Location Observer

    /// 위치 업데이트 시 날씨 자동 재로드
    private func observeLocationUpdates() {
        permissionManager.$currentLocation
            .dropFirst()
            .compactMap { $0 }
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    await self?.loadWeatherIfPermitted()
                }
            }
            .store(in: &locationCancellables)
    }

    // MARK: - Private: Mode Timer

    /// 매분 시간대 체크 — 모드가 바뀌면 말씀/이미지 재로드
    private func startModeCheckTimer() {
        modeCheckTimer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let newMode = AppMode.current()
                guard newMode != self.currentMode else { return }
                self.currentMode = newMode
                Task { [weak self] in
                    guard let self else { return }
                    await self.loadVerse(for: newMode)
                    await self.loadImage(for: newMode)
                }
            }
    }

    // MARK: - Private: SavedVerse Factory

    private func makeSavedVerse(from verse: Verse, displayedImageUrl: String? = nil) -> SavedVerse {
        // displayedImageUrl: View에서 실제 표시된 URL (loadingCoordinator.zoneBgUrl) 우선
        // fallback: currentBackground → currentImage 순
        let displayImageUrl = displayedImageUrl ?? currentBackground?.storageUrl ?? currentImage?.storageUrl
        let displayImageId  = currentBackground?.id ?? currentImage?.id
        return SavedVerse(
            id: UUID().uuidString,
            verseId: verse.id,
            imageId: displayImageId,
            imageUrl: displayImageUrl,  // 유저가 본 배경 URL
            savedAt: Date(),
            mode: currentMode.rawValue,
            weatherTemp: weather?.temperature ?? 0,
            weatherCondition: weather?.condition ?? "any",
            weatherHumidity: weather?.humidity ?? 0,
            weatherDust: weather?.dustGrade,      // v5.1: 미세먼지 등급
            locationName: weather?.cityName ?? "",
            verseFullKo: verse.verseFullKo,
            source: .home                          // v5.2: 홈화면에서 저장
        )
    }

    // MARK: - Private: Toast

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        toastMessage = message
        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초
            guard !Task.isCancelled else { return }
            // @MainActor 클래스 내 Task는 이미 MainActor 컨텍스트에서 실행됨
            self?.toastMessage = nil
        }
    }
}

// MARK: - Preview Helper

extension HomeViewModel {
    static func preview() -> HomeViewModel {
        let vm = HomeViewModel(
            authManager: AuthManager(),
            subscriptionManager: SubscriptionManager(),
            upsellManager: UpsellManager(),
            permissionManager: PermissionManager()
        )
        vm.currentVerse = .fallbackMorning
        vm.weather = .placeholder
        return vm
    }
}

#Preview {
    let vm = HomeViewModel.preview()
    return VStack(spacing: 12) {
        Text(vm.currentMode.greeting)
            .font(.headline)
        if let verse = vm.currentVerse {
            Text(verse.verseShortKo)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            Text(verse.reference)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        if let weather = vm.weather {
            Text("\(weather.cityName) \(weather.temperature)°C")
                .font(.caption2)
        }
    }
    .padding()
}
