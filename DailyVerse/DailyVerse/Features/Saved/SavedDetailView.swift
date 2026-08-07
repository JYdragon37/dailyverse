import SwiftUI
import UIKit
import Combine
import Photos
import FirebaseAnalytics

struct SavedDetailView: View {
    let savedVerse: SavedVerse
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var nicknameManager = NicknameManager.shared
    @AppStorage("appLanguage") private var appLang: String = "ko"
    @State private var showVerseDetail = false
    @State private var loadedVerse: Verse? = nil
    @State private var isSavingImage = false
    @State private var imageSaveMessage: String? = nil
    @State private var isGeneratingShare = false
    // safeAreaInset 버그 방지: 뷰 전환 애니메이션 중 버튼 자동 실행 차단
    // (AlarmStage2View dismissAll() 의 2초 가드와 동일 원인)
    @State private var buttonsEnabled = false

    // MARK: - Computed Properties

    private var verseText: String {
        // 우선순위: 로드된 말씀 → Core Data 캐시 → 폴백
        if let v = loadedVerse { return v.verseFull(lang: appLang) }
        if let v = DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId) { return v.verseFull(lang: appLang) }
        if let v = Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId }) { return v.verseFull(lang: appLang) }
        return appLang == "en" ? "Loading verse..." : "말씀을 불러오는 중..."
    }

    private var verseReference: String {
        if let v = loadedVerse { return v.reference }
        if let v = DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId) { return v.reference }
        return Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId })?.reference ?? ""
    }

    private var verseInterpretation: String? {
        let v = loadedVerse
            ?? DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId)
            ?? Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId })
        return v?.interpretationText(lang: appLang)
    }

    private var verseApplication: String? {
        let v = loadedVerse
            ?? DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId)
            ?? Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId })
        return v?.applicationText(lang: appLang)
    }

    private var backgroundGradient: LinearGradient {
        // AppMode rawValue로 매핑하여 각 Zone의 그라데이션 사용
        let mode = AppMode(rawValue: savedVerse.mode) ?? AppMode.current()
        return LinearGradient(colors: mode.gradientColors, startPoint: .top, endPoint: .bottom)
    }

    /// HomeView verseCenter와 동일한 스타일
    private var verseBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verseText)
                .font(.custom("PretendardVariable", size: 21).weight(.semibold))
                .foregroundColor(.white)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

            HStack(spacing: 8) {
                if !verseReference.isEmpty {
                    Text(verseReference)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.top, 18)

            if verseInterpretation != nil {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .medium))
                    Text("해석 보기")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 20)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
    }

    private var shareText: String {
        var parts = [String]()
        parts.append("\"\(verseText)\"")
        if !verseReference.isEmpty { parts.append(verseReference) }
        parts.append(""); parts.append("morning manna")
        return parts.joined(separator: "\n")
    }

    private func handleShare() {
        Analytics.logEvent("verse_shared", parameters: ["verse_id": savedVerse.verseId])
        isGeneratingShare = true
        let text = verseText
        let ref  = verseReference
        Task {
            var shareImage: UIImage?

            // 배경 이미지가 있으면 합성, 없으면 그라데이션 카드
            if let urlStr = savedVerse.imageUrl, let url = URL(string: urlStr),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let bgImage = UIImage(data: data) {
                shareImage = compositeVerseImage(background: bgImage, verseText: text, reference: ref)
            } else {
                // 그라데이션 폴백 카드
                let size = CGSize(width: 1170, height: 2080)
                let format = UIGraphicsImageRendererFormat(); format.scale = 1
                shareImage = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
                    // 배경 그라데이션
                    let colors = [UIColor(red: 0.05, green: 0.07, blue: 0.13, alpha: 1),
                                  UIColor(red: 0.10, green: 0.14, blue: 0.24, alpha: 1)]
                    let gradient = CGGradient(
                        colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: colors.map(\.cgColor) as CFArray,
                        locations: [0, 1])!
                    ctx.cgContext.drawLinearGradient(gradient,
                        start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
                    // 텍스트
                    let para = NSMutableParagraphStyle(); para.alignment = .left; para.lineSpacing = 12
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 52, weight: .semibold),
                        .foregroundColor: UIColor.white,
                        .paragraphStyle: para
                    ]
                    let hPad: CGFloat = size.width * 0.13   // 화면 표시와 동일 비율
                    NSAttributedString(string: text, attributes: attrs)
                        .draw(in: CGRect(x: hPad, y: size.height * 0.38, width: size.width - hPad*2, height: size.height * 0.4))
                    let refAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 36, weight: .medium),
                        .foregroundColor: UIColor.white.withAlphaComponent(0.75)
                    ]
                    NSAttributedString(string: ref, attributes: refAttrs)
                        .draw(at: CGPoint(x: hPad, y: size.height * 0.72))
                    // mm 브랜드 로고 (하단 중앙)
                    if let logo = UIImage(named: "LogoMMColor") {
                        let logoSize = size.width * 0.12
                        let logoX = (size.width - logoSize) / 2
                        let logoY = size.height - logoSize - size.width * 0.07
                        logo.draw(in: CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize),
                                  blendMode: .normal, alpha: 0.70)
                    }
                }
            }

            await MainActor.run {
                if let image = shareImage {
                    let av = UIActivityViewController(
                        activityItems: [image],
                        applicationActivities: nil
                    )
                    // keyWindow 기준으로 가장 상단 VC 탐색
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first {
                        var presenter = window.rootViewController
                        while let presented = presenter?.presentedViewController {
                            presenter = presented
                        }
                        presenter?.present(av, animated: true)
                    }
                }
                isGeneratingShare = false
            }
        }
    }

    // MARK: - Verse Detail Sheet

    private var verseDetailSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 8)

                // 1. 해석
                if let interpretation = verseInterpretation {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("해석", systemImage: "text.magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.dvAccentGold)
                        Text(interpretation)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }
                }

                if verseInterpretation != nil && verseApplication != nil {
                    Divider().padding(.vertical, 4)
                }

                // 2. 오늘의 적용 (닉네임 포함)
                if let application = verseApplication {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("오늘의 적용", systemImage: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.dvAccentSky)
                        Text("\(nicknameManager.nickname), \(application)")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Body

    var body: some View {
        // 배경 레이어 + 말씀 레이어
        ZStack {
            // 풀스크린 배경
            Group {
                if let urlStr = savedVerse.imageUrl, let url = URL(string: urlStr) {
                    RemoteImageView(url: url) { backgroundGradient.ignoresSafeArea() }
                        .ignoresSafeArea()
                } else {
                    backgroundGradient.ignoresSafeArea()
                }
            }
            // 다크 오버레이
            LinearGradient(
                colors: [Color.black.opacity(0.25), Color.black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // 말씀 — HomeView와 동일 위치 (48%)
            GeometryReader { geo in
                let w = geo.size.width
                let hPad = max(w * 0.13, 40.0)
                verseBlock
                    .padding(.horizontal, hPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .position(x: w / 2, y: geo.size.height * 0.48)
                    .onTapGesture {
                        if verseInterpretation != nil { showVerseDetail = true }
                    }
            }
        }
        // 닫기 버튼 (우상단)
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(10)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .accessibilityLabel("닫기")
            .padding(.top, 56)
            .padding(.trailing, 20)
        }
        // 브랜딩 로고 (하단 중앙)
        .overlay(alignment: .bottom) {
            Image("LogoMMColor")
                .resizable()
                .scaledToFit()
                .frame(width: 48)
                .opacity(0.70)
                .padding(.bottom, 112)
                .allowsHitTesting(false)
        }
        // 하단 버튼 영역
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button { handleDelete() } label: {
                        Label("저장 해제", systemImage: "heart.slash.fill")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                    }
                    .foregroundColor(.white)
                    .disabled(!buttonsEnabled)
                    .accessibilityLabel("이 말씀 저장 해제")

                    Button {
                        handleShare()
                    } label: {
                        if isGeneratingShare {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(14)
                        } else {
                            Label("공유", systemImage: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(14)
                        }
                    }
                    .foregroundColor(.white)
                    .disabled(!buttonsEnabled || isGeneratingShare)
                    .accessibilityLabel("이 말씀 이미지로 공유하기")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // 이미지 저장 버튼 (imageUrl 있을 때만 표시)
                if savedVerse.imageUrl != nil {
                    Button {
                        guard !isSavingImage else { return }
                        downloadImage()
                    } label: {
                        HStack(spacing: 6) {
                            if isSavingImage {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.7)
                                    .tint(.white.opacity(0.6))
                            } else {
                                Image(systemName: "square.and.arrow.down").font(.system(size: 13))
                            }
                            Text(isSavingImage ? "저장 중..." : "이미지 저장")
                                .font(.dvCaption)
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                    }
                }
            }
            .background(
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.6)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        // 이미지 저장 결과 토스트
        .overlay(alignment: .bottom) {
            if let msg = imageSaveMessage {
                Text(msg)
                    .font(.dvCaption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.70))
                    .cornerRadius(10)
                    .padding(.bottom, 110)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: imageSaveMessage)
            }
        }
        .presentationDetents([.large])
        .task {
            await loadVerseIfNeeded()
            // safeAreaInset 버그: sheet 등장 애니메이션(약 0.4초) 동안 버튼 비활성
            try? await Task.sleep(for: .milliseconds(600))
            buttonsEnabled = true
        }
        .sheet(isPresented: $showVerseDetail) {
            verseDetailSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Load Verse

    private func loadVerseIfNeeded() async {
        // Core Data 캐시에 있으면 이미 verseText가 채워짐 → Firestore 불필요
        guard DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId) == nil else { return }
        guard Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId }) == nil else { return }
        // Firestore에서 단건 조회
        if let verse = try? await FirestoreService().fetchVerse(id: savedVerse.verseId) {
            await MainActor.run { loadedVerse = verse }
        }
    }

    // MARK: - Image Download (말씀 합성)

    private func downloadImage() {
        guard let urlStr = savedVerse.imageUrl, let url = URL(string: urlStr) else { return }
        isSavingImage = true
        let text = verseText
        let ref  = verseReference
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                await show(message: "사진 접근 권한이 필요해요. 설정에서 허용해주세요.")
                return
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let bgImage = UIImage(data: data) else { throw URLError(.badServerResponse) }
                let composited = compositeVerseImage(background: bgImage, verseText: text, reference: ref)
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: composited)
                }
                await show(message: "사진첩에 저장됐어요 ✓")
            } catch {
                await show(message: "저장에 실패했어요. 다시 시도해주세요.")
            }
        }
    }

    /// 배경 이미지에 말씀 텍스트 + 레퍼런스를 합성해 UIImage 반환
    private func compositeVerseImage(background: UIImage, verseText: String, reference: String) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = background.scale
        let renderer = UIGraphicsImageRenderer(size: background.size, format: format)

        return renderer.image { ctx in
            let size    = background.size
            let cgCtx   = ctx.cgContext
            let hPad    = size.width * 0.13   // 화면 표시와 동일: max(w * 0.13, 40)

            // 1. 배경 이미지
            background.draw(in: CGRect(origin: .zero, size: size))

            // 2. 다크 그라데이션 오버레이
            let colors = [UIColor.black.withAlphaComponent(0.20).cgColor,
                          UIColor.black.withAlphaComponent(0.62).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: colors, locations: [0, 1]) {
                cgCtx.drawLinearGradient(gradient,
                    start: .zero,
                    end: CGPoint(x: 0, y: size.height),
                    options: [])
            }

            // 3. 말씀 텍스트 (Georgia-BoldItalic)
            let verseFont = UIFont(name: "PretendardVariable", size: size.width * 0.057)
                         ?? UIFont.boldSystemFont(ofSize: size.width * 0.057)
            let paraStyle = NSMutableParagraphStyle()
            paraStyle.lineSpacing = size.width * 0.018
            let verseAttr: [NSAttributedString.Key: Any] = [
                .font: verseFont,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paraStyle
            ]
            let verseAS  = NSAttributedString(string: verseText, attributes: verseAttr)
            let maxW     = size.width - hPad * 2
            let verseH   = verseAS.boundingRect(
                with: CGSize(width: maxW, height: size.height * 0.55),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil
            ).height
            let verseY   = size.height * 0.38
            verseAS.draw(with: CGRect(x: hPad, y: verseY, width: maxW, height: verseH),
                         options: .usesLineFragmentOrigin, context: nil)

            // 4. 성경 레퍼런스
            let refFont = UIFont.systemFont(ofSize: size.width * 0.038, weight: .medium)
            let refAttr: [NSAttributedString.Key: Any] = [
                .font: refFont,
                .foregroundColor: UIColor.white.withAlphaComponent(0.80)
            ]
            let refY = verseY + verseH + size.width * 0.045
            NSAttributedString(string: reference, attributes: refAttr)
                .draw(with: CGRect(x: hPad, y: refY, width: maxW, height: size.width * 0.12),
                      options: .usesLineFragmentOrigin, context: nil)

            // 5. mm 브랜드 로고 (좌하단)
            if let logo = UIImage(named: "LogoMMColor") {
                let logoSize = size.width * 0.12
                let logoX = (size.width - logoSize) / 2   // 하단 중앙
                let logoY = size.height - logoSize - size.width * 0.08
                logo.draw(in: CGRect(x: logoX, y: logoY, width: logoSize, height: logoSize),
                          blendMode: .normal, alpha: 0.75)
            }
        }
    }

    @MainActor
    private func show(message: String) async {
        isSavingImage = false
        imageSaveMessage = message
        try? await Task.sleep(for: .seconds(2.5))
        imageSaveMessage = nil
    }

    // MARK: - Delete

    private func handleDelete() {
        onDelete?()
        dismiss()
    }
}

// MARK: - Preview

#Preview("아침 말씀") {
    let savedVerse = SavedVerse(
        id: "saved_preview_001",
        verseId: "fallback_morning",
        savedAt: Date(),
        mode: "morning",
        weatherTemp: 18,
        weatherCondition: "sunny",
        weatherHumidity: 65,
        locationName: "서울 강남구"
    )
    SavedDetailView(savedVerse: savedVerse, onDelete: nil)
        .environmentObject(AuthManager())
}

#Preview("저녁 말씀") {
    let savedVerse = SavedVerse(
        id: "saved_preview_002",
        verseId: "fallback_evening",
        savedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
        mode: "evening",
        weatherTemp: 8,
        weatherCondition: "rainy",
        weatherHumidity: 90,
        locationName: "부산 해운대구"
    )
    SavedDetailView(savedVerse: savedVerse, onDelete: nil)
        .environmentObject(AuthManager())
}

#Preview("위치 없음") {
    let savedVerse = SavedVerse(
        id: "saved_preview_003",
        verseId: "fallback_afternoon",
        savedAt: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
        mode: "afternoon",
        weatherTemp: 24,
        weatherCondition: "cloudy",
        weatherHumidity: 55,
        locationName: ""
    )
    SavedDetailView(savedVerse: savedVerse, onDelete: nil)
        .environmentObject(AuthManager())
}
