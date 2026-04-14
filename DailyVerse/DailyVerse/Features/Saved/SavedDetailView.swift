import SwiftUI
import Combine
import Photos

struct SavedDetailView: View {
    let savedVerse: SavedVerse
    var onDelete: (() -> Void)? = nil

    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var showVerseDetail = false
    @State private var loadedVerse: Verse? = nil
    @State private var isSavingImage = false
    @State private var imageSaveMessage: String? = nil

    // MARK: - Computed Properties

    private var verseText: String {
        // 우선순위: 로드된 말씀 → Core Data 캐시 → 폴백
        if let v = loadedVerse { return v.verseFullKo }
        if let v = DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId) { return v.verseFullKo }
        if let v = Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId }) { return v.verseFullKo }
        return "말씀을 불러오는 중..."
    }

    private var verseReference: String {
        if let v = loadedVerse { return v.reference }
        if let v = DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId) { return v.reference }
        return Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId })?.reference ?? ""
    }

    private var verseInterpretation: String? {
        loadedVerse?.interpretation
            ?? DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId)?.interpretation
            ?? Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId })?.interpretation
    }

    private var verseApplication: String? {
        loadedVerse?.application
            ?? DailyCacheManager.shared.loadCachedVerse(id: savedVerse.verseId)?.application
            ?? Verse.fallbackVerses.first(where: { $0.id == savedVerse.verseId })?.application
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
                .font(.custom("Georgia-BoldItalic", size: 21))
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
        if !verseReference.isEmpty {
            parts.append(verseReference)
        }
        parts.append("")
        parts.append("DailyVerse")
        return parts.joined(separator: "\n")
    }

    // MARK: - Verse Detail Sheet

    private var verseDetailSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 8)

                // 오늘의 적용
                if let application = verseApplication {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("오늘의 적용", systemImage: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(application)
                            .font(.system(size: 19, weight: .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }

                if verseApplication != nil && verseInterpretation != nil {
                    Divider().padding(.vertical, 4)
                }

                // 해석
                if let interpretation = verseInterpretation {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("해석", systemImage: "text.magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(interpretation)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
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
                    .accessibilityLabel("이 말씀 저장 해제")

                    ShareLink(item: shareText) {
                        Label("공유", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.15))
                            .cornerRadius(14)
                    }
                    .foregroundColor(.white)
                    .accessibilityLabel("이 말씀 공유하기")
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
        .task { await loadVerseIfNeeded() }
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

    // MARK: - Image Download

    private func downloadImage() {
        guard let urlStr = savedVerse.imageUrl, let url = URL(string: urlStr) else { return }
        isSavingImage = true
        Task {
            // 사진 권한 요청
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                await show(message: "사진 접근 권한이 필요해요. 설정에서 허용해주세요.")
                return
            }
            // 이미지 다운로드
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { throw URLError(.badServerResponse) }
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                await show(message: "사진첩에 저장됐어요 ✓")
            } catch {
                await show(message: "저장에 실패했어요. 다시 시도해주세요.")
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
