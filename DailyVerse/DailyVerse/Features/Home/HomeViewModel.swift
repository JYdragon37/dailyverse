import SwiftUI
import UIKit
import Combine
import CoreLocation

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

    // MARK: - Private State

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
        verseRepository: VerseRepository = VerseRepository(),
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

        // 날씨 로드 (위치 권한이 있을 때만)
        await loadWeatherIfPermitted()

        // 말씀 로드
        await loadVerse(for: currentMode)

        // 배경 이미지 로드 (#3 시간대별 배경)
        await loadBackground(for: currentMode)
        // 말씀 이미지 로드
        await syncPinnedImagesIfNeeded()
        await loadImage(for: currentMode)

        // 알람 CTA 재평가
        evaluateAlarmCTA()
    }

    /// 포그라운드 복귀 시 날씨만 갱신
    func refreshWeather() async {
        await loadWeatherIfPermitted()
    }

    /// 말씀 저장
    func saveVerse() {
        guard let verse = currentVerse else { return }

        // 비로그인 상태: pendingSave 설정 후 로그인 유도는 View 레이어에서 처리
        guard authManager.isLoggedIn, let userId = authManager.userId else {
            // pendingSave를 AuthManager에 예약
            let pending = makeSavedVerse(from: verse)
            authManager.setPendingSave(pending)
            // 로그인 시트 표시는 View에서 authManager.isLoggedIn 관찰로 처리
            return
        }

        let savedVerse = makeSavedVerse(from: verse)
        Task {
            do {
                let repo = SavedVerseRepository()
                try await repo.save(savedVerse, userId: userId)
                showToast("저장되었습니다")
            } catch {
                showToast("저장에 실패했습니다. 다시 시도해주세요")
            }
        }
    }

    /// 다음 말씀 로드 (v5.1: 단일 플랜 — 모든 유저 사용 가능)
    func nextVerse() async {
        guard let currentId = currentVerse?.id else { return }

        isLoading = true
        defer { isLoading = false }

        if let next = await verseRepository.nextVerse(
            excluding: currentId,
            for: currentMode,
            weather: weather
        ) {
            currentVerse = next
        } else {
            showToast("더 이상 표시할 말씀이 없어요")
        }
    }

    // MARK: - Private: Data Loading

    /// #3 시간대별 배경 이미지 로드 (background_images 컬렉션)
    private func loadBackground(for mode: AppMode) async {
        do {
            let bg = try await FirestoreService().fetchBackgroundImage(for: mode)
            currentBackground = bg
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
        let verse = await verseRepository.currentVerse(for: mode, weather: weather)
        currentVerse = verse
    }

    private func loadImage(for mode: AppMode) async {
        do {
            let images = try await verseRepository.fetchImages()
            #if DEBUG
            print("🖼️ [Image] Fetched \(images.count)개, mode=\(mode.rawValue)")
            images.forEach { print("  - \($0.id): \($0.storageUrl)") }
            #endif
            // v5.1: Gallery 핀 이미지 우선 적용
            let pinnedId = UserDefaults.standard.string(forKey: "pinnedImage_\(mode.rawValue)")
            currentImage = selectImage(from: images, mode: mode, pinnedImageId: pinnedId)
            #if DEBUG
            print("🖼️ [Image] Selected: \(currentImage?.id ?? "nil") | URL: \(currentImage?.storageUrl ?? "-")")
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

        // 모드 필터 우선 적용
        let modeFiltered = safe.filter {
            $0.mode.contains(mode.rawValue) || $0.mode.contains("all")
        }
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

    private func makeSavedVerse(from verse: Verse) -> SavedVerse {
        SavedVerse(
            id: UUID().uuidString,
            verseId: verse.id,
            imageId: currentImage?.id,           // v5.1: 저장 당시 배경 이미지 ID
            savedAt: Date(),
            mode: currentMode.rawValue,
            weatherTemp: weather?.temperature ?? 0,
            weatherCondition: weather?.condition ?? "any",
            weatherHumidity: weather?.humidity ?? 0,
            weatherDust: weather?.dustGrade,      // v5.1: 미세먼지 등급
            locationName: weather?.cityName ?? ""
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
            Text(verse.textKo)
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
