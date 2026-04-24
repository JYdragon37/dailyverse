import SwiftUI
import Photos

// MARK: - MeditationEntryDetailView v3
// 묵상 다이어리 템플릿 — 라이트(크림)/다크(딥브라운) 모드 대응
// verseFullKo / readingText·prayer·prayerItems 자동 연계
// 갤러리 저장 기능 + mm 로고 콜로폰

struct MeditationEntryDetailView: View {
    let entry: MeditationEntry
    @ObservedObject var viewModel: MeditationViewModel
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var verse: Verse? = nil
    @State private var isSaving = false
    @State private var showSavedToast = false
    @State private var showEditFlow = false

    // MARK: - 다이어리 테마 (시스템 무관 독립 설정)
    @AppStorage("diaryPrefersDark") private var diaryPrefersDark: Bool = true

    // MARK: - 색상 팔레트 (diaryPrefersDark 기준)

    private var bgColor: Color {
        diaryPrefersDark
            ? Color(red: 0.10, green: 0.08, blue: 0.06)   // 다크: 딥 브라운
            : Color(red: 0.97, green: 0.93, blue: 0.87)   // 라이트: 크림
    }
    private var inkColor: Color {
        diaryPrefersDark
            ? Color(red: 0.90, green: 0.84, blue: 0.76)   // 다크: 크림색 텍스트
            : Color(red: 0.24, green: 0.16, blue: 0.10)   // 라이트: 진한 브라운
    }
    private var inkFaint: Color { inkColor.opacity(0.45) }
    private var ruleColor: Color { inkColor.opacity(0.18) }
    private let goldColor = Color(red: 0.72, green: 0.52, blue: 0.18)

    // MARK: - 손글씨 폰트
    private func diaryFont(size: CGFloat) -> Font {
        Font.custom("NanumPen-Regular", size: size)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            bgColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    headerSection
                        .padding(.top, 16)
                        .padding(.horizontal, 28)

                    rule.padding(.horizontal, 28).padding(.top, 16)

                    verseSection
                        .padding(.horizontal, 28)
                        .padding(.top, 20)

                    rule.padding(.horizontal, 28).padding(.top, 20)

                    if let reading = entry.readingText, !reading.isEmpty {
                        diarySection(icon: "✍️", label: "묵상 소감", body: reading)
                        rule.padding(.horizontal, 28)
                    }

                    if let prayer = entry.prayer, !prayer.isEmpty {
                        diarySection(icon: "🙏", label: "기도", body: prayer)
                        rule.padding(.horizontal, 28)
                    }

                    if !entry.prayerItems.isEmpty {
                        gratitudeSection
                        rule.padding(.horizontal, 28)
                    }

                    if entry.readingText?.isEmpty != false
                        && entry.prayer?.isEmpty != false
                        && entry.prayerItems.isEmpty {
                        emptyState
                            .padding(.horizontal, 28)
                            .padding(.top, 32)
                    }

                    // ── 하단 콜로폰 (브랜드 마크) ──────────
                    colophon
                        .padding(.top, 36)
                        .padding(.bottom, 48)

                }
            }

            // ── 저장 완료 토스트 ──────────────────────────
            if showSavedToast {
                VStack {
                    Spacer()
                    Text("📷 갤러리에 저장됐어요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(inkColor.opacity(0.85)))
                    Spacer().frame(height: 80)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showSavedToast)
        // ── 상단 버튼 영역 — safeAreaInset: 스크롤 콘텐츠가 버튼 뒤로 올라가지 않음
        // (Day One, Apple Notes 등 주요 다이어리 앱 표준 패턴)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 10) {
                // 수정하기
                Button { showEditFlow = true } label: {
                    Text("수정하기")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(inkColor.opacity(0.60))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(inkColor.opacity(0.08))
                        .clipShape(Capsule())
                }

                Spacer()

                // 테마 토글 (다크↔라이트)
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { diaryPrefersDark.toggle() }
                } label: {
                    Image(systemName: diaryPrefersDark ? "sun.max" : "moon")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(inkColor.opacity(0.55))
                        .padding(9)
                        .background(inkColor.opacity(0.08))
                        .clipShape(Circle())
                }
                .accessibilityLabel(diaryPrefersDark ? "라이트 모드로 전환" : "다크 모드로 전환")

                // 갤러리 저장
                Button {
                    Task { await saveToGallery() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: inkColor.opacity(0.55)))
                            .frame(width: 16, height: 16)
                            .padding(9)
                            .background(inkColor.opacity(0.08))
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(inkColor.opacity(0.55))
                            .padding(9)
                            .background(inkColor.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .accessibilityLabel("이미지로 저장")
                .disabled(isSaving)

                // 닫기
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(inkColor.opacity(0.55))
                        .padding(9)
                        .background(inkColor.opacity(0.08))
                        .clipShape(Circle())
                }
                .accessibilityLabel("닫기")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(bgColor)
        }
        .fullScreenCover(isPresented: $showEditFlow) {
            NavigationStack {
                // 해석 + 묵상소감 페이지(DevotionVerseView) 먼저, 그 다음 응답 페이지
                DevotionVerseView(
                    verse: verse,
                    viewModel: viewModel,
                    prefillReadingText: entry.readingText ?? "",
                    editMode: true,
                    prefillPrayer: entry.prayer ?? "",
                    prefillGratitude: entry.prayerItems.map { $0.text }
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") { showEditFlow = false }
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .task {
            let id = entry.verseId
            guard !id.isEmpty else { return }
            if let v = DailyCacheManager.shared.loadCachedVerse(id: id) { verse = v; return }
            if let v = Verse.fallbackVerses.first(where: { $0.id == id }) { verse = v; return }
            if let verses = try? await VerseRepository.shared.fetchVerses() {
                verse = verses.first { $0.id == id }
            }
        }
    }

    // MARK: - 헤더 (연도 포함)

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("묵상")
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundColor(inkColor)

            Text(formattedDateWithYear)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(inkFaint)
        }
    }

    // MARK: - 말씀 (verseFullKo, 이탤릭 중앙)

    private var verseSection: some View {
        VStack(spacing: 14) {
            Text(verse?.verseFullKo ?? verse?.verseShortKo ?? "말씀을 불러오는 중이에요")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(inkColor.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)

            Text("— \(entry.verseReference)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(goldColor)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 4)
    }

    // MARK: - 다이어리 섹션

    private func diarySection(icon: String, label: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 13))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(goldColor)
                    .tracking(0.8)
            }
            Text(body)
                .font(diaryFont(size: 20))
                .foregroundColor(inkColor)
                .lineSpacing(9)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    // MARK: - 감사한 것

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("🌿").font(.system(size: 13))
                Text("감사한 것")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(goldColor)
                    .tracking(0.8)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.prayerItems.enumerated()), id: \.1.id) { idx, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1).")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(goldColor)
                            .frame(width: 18)
                        Text(item.text)
                            .font(diaryFont(size: 20))
                            .foregroundColor(inkColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    // MARK: - 하단 콜로폰 (로고)

    private var colophon: some View {
        VStack(spacing: 6) {
            Rectangle()
                .fill(ruleColor)
                .frame(width: 32, height: 0.7)

            Image("LogoMM")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .padding(.vertical, -18)
                .colorMultiply(inkColor)   // 잉크 갈색으로 렌더링
                .opacity(0.35)

            Text("morning manna")
                .font(.system(size: 10, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(inkColor.opacity(0.30))
                .tracking(1.2)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 빈 상태

    private var emptyState: some View {
        Text("아직 묵상 기록이 없어요")
            .font(.system(size: 15, weight: .regular, design: .serif))
            .italic()
            .foregroundColor(inkFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
    }

    // MARK: - 구분선

    private var rule: some View {
        Rectangle()
            .fill(ruleColor)
            .frame(height: 0.7)
    }

    // MARK: - 갤러리 저장

    @MainActor
    private func saveToGallery() async {
        isSaving = true

        // 렌더링할 스냅샷 뷰 생성
        let snapshot = DiarySnapshotView(
            entry: entry,
            verse: verse,
            bgColor: bgColor,
            inkColor: inkColor,
            inkFaint: inkFaint,
            ruleColor: ruleColor,
            goldColor: goldColor
        )

        let renderer = ImageRenderer(content: snapshot)
        renderer.scale = 3.0   // @3x 고해상도

        guard let uiImage = renderer.uiImage else {
            isSaving = false
            return
        }

        // 권한 요청 + 저장
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            isSaving = false
            return
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: uiImage)
            }
            isSaving = false
            showSavedToast = true
            // 2초 후 토스트 숨김
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSavedToast = false
        } catch {
            isSaving = false
        }
    }

    // MARK: - 날짜 포매터 (연도 포함)

    private var formattedDateWithYear: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: entry.dateKey) else { return entry.dateKey }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월 d일 EEEE"
        return fmt.string(from: date)
    }
}

// MARK: - DiarySnapshotView (ImageRenderer 렌더링 전용)

private struct DiarySnapshotView: View {
    let entry: MeditationEntry
    let verse: Verse?
    let bgColor: Color
    let inkColor: Color
    let inkFaint: Color
    let ruleColor: Color
    let goldColor: Color

    private let pageWidth: CGFloat = 390

    private func diaryFont(size: CGFloat) -> Font {
        Font.custom("NanumPen-Regular", size: size)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 헤더
            VStack(alignment: .leading, spacing: 5) {
                Text("묵상")
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundColor(inkColor)
                Text(formattedDate)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(inkFaint)
            }
            .padding(.horizontal, 28)
            .padding(.top, 40)

            snapRule.padding(.horizontal, 28).padding(.top, 16)

            // 말씀
            VStack(spacing: 14) {
                Text(verse?.verseFullKo ?? verse?.verseShortKo ?? "")
                    .font(.system(size: 18, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(inkColor.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                Text("— \(entry.verseReference)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(goldColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)

            snapRule.padding(.horizontal, 28)

            if let reading = entry.readingText, !reading.isEmpty {
                snapSection(icon: "✍️", label: "묵상 소감", body: reading)
                snapRule.padding(.horizontal, 28)
            }
            if let prayer = entry.prayer, !prayer.isEmpty {
                snapSection(icon: "🙏", label: "기도", body: prayer)
                snapRule.padding(.horizontal, 28)
            }
            if !entry.prayerItems.isEmpty {
                snapGratitude
                snapRule.padding(.horizontal, 28)
            }

            // 콜로폰
            VStack(spacing: 6) {
                Rectangle().fill(ruleColor).frame(width: 32, height: 0.7)
                Image("LogoMM")
                    .resizable().scaledToFit()
                    .frame(width: 48, height: 48)
                    .padding(.vertical, -18)
                    .colorMultiply(inkColor)
                    .opacity(0.35)
                Text("morning manna")
                    .font(.system(size: 10, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(inkColor.opacity(0.30))
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 36)
            .padding(.bottom, 48)
        }
        .frame(width: pageWidth)
        .background(bgColor)
    }

    private var snapRule: some View {
        Rectangle().fill(ruleColor).frame(height: 0.7)
    }

    private func snapSection(icon: String, label: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 13))
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(goldColor)
                    .tracking(0.8)
            }
            Text(body)
                .font(diaryFont(size: 20))
                .foregroundColor(inkColor)
                .lineSpacing(9)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    private var snapGratitude: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("🌿").font(.system(size: 13))
                Text("감사한 것")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(goldColor)
                    .tracking(0.8)
            }
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.prayerItems.enumerated()), id: \.1.id) { idx, item in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(idx + 1).")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(goldColor)
                            .frame(width: 18)
                        Text(item.text)
                            .font(diaryFont(size: 20))
                            .foregroundColor(inkColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    private var formattedDate: String {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: entry.dateKey) else { return entry.dateKey }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월 d일 EEEE"
        return fmt.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    let sampleEntry = MeditationEntry(
        id: "preview-001",
        userId: "local",
        dateKey: "2026-04-24",
        verseId: "v_200",
        verseReference: "시편 143:8",
        mode: "rise_ignite",
        prayerItems: [
            PrayerItem(text: "오늘 하루 감사한 말씀을 만났어요"),
            PrayerItem(text: "가족이 건강해서 감사해요"),
            PrayerItem(text: "평안한 아침 시간")
        ],
        gratitudeNote: nil,
        createdAt: Date(),
        updatedAt: Date(),
        source: "guided",
        prayer: "주님, 오늘도 말씀으로 하루를 시작하게 해주셔서 감사합니다.",
        readingText: "오늘 아침 이 말씀을 읽으며 하나님이 나의 하루를 인도하신다는 믿음이 생겼습니다.",
        imageUrl: nil
    )
    MeditationEntryDetailView(entry: sampleEntry, viewModel: MeditationViewModel())
        .environmentObject(AuthManager())
}
