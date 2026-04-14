import SwiftUI

// MARK: - MeditationEntryDetailView
// 묵상 달력 날짜 탭 시 표시되는 풀스크린 상세 뷰

struct MeditationEntryDetailView: View {
    let entry: MeditationEntry
    @Environment(\.dismiss) private var dismiss

    @State private var verse: Verse? = nil
    @State private var showDetailSheet = false

    // MARK: - Background

    private var backgroundGradient: LinearGradient {
        let mode = AppMode(rawValue: entry.mode) ?? AppMode.current()
        return LinearGradient(colors: mode.gradientColors, startPoint: .top, endPoint: .bottom)
    }

    // MARK: - 4-Stop 감성 오버레이
    // 상단(날짜) · 중앙(배경 노출) · 말씀 블록 · 하단(버튼) 구간별 독립 처리

    private var overlayGradient: some View {
        LinearGradient(
            stops: [
                .init(color: .black.opacity(0.70), location: 0.00),
                .init(color: .black.opacity(0.15), location: 0.28),
                .init(color: .black.opacity(0.35), location: 0.55),
                .init(color: .black.opacity(0.78), location: 1.00),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - 날짜 블록
    // 연도(작게·흐리게) / 구분선 / 월·일(크게·선명하게) / 요일(보통·중간)
    // 설계 의도: 이 날의 묵상이 인생의 고정된 한 순간임을 시각적 계층으로 표현

    private var dateBlock: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 연도 — 맥락 레이어
            Text(entryYear)
                .font(.system(size: 14, weight: .medium))
                .tracking(3)
                .foregroundColor(.white.opacity(0.50))

            // 시각적 구분선
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 20, height: 1)
                .padding(.vertical, 6)

            // 월·일 — 핵심 정보, 가장 크고 선명하게
            Text(entryMonthDay)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            // 요일 — 보조 정보
            Text(entryWeekday)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.70))
                .padding(.top, 2)

            // 도시명 — 위치 컨텍스트, 없으면 숨김
            if let city = entry.locationName, !city.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 11))
                    Text(city)
                        .font(.system(size: 14, weight: .regular))
                }
                .foregroundColor(.white.opacity(0.55))
                .padding(.top, 6)
            }
        }
        .shadow(color: .black.opacity(0.8), radius: 8, x: 0, y: 2)
    }

    // MARK: - 말씀 블록
    // 26pt semibold, 행간 1.6, 강한 그림자로 배경 위 선명도 확보

    private var verseBlock: some View {
        VStack(alignment: .leading, spacing: 0) {

            // 말씀 본문 — 화면의 주인공 (verse 로드 전에는 숨김)
            if let verseText = verse?.verseFullKo, !verseText.isEmpty {
                Text(verseText)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
                    .lineSpacing(11)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.9), radius: 12, x: 0, y: 4)
            }

            // 참조 — em dash로 시작, 중간 크기·중간 투명도
            Text("— \(entry.verseReference)")
                .font(.system(size: 14, weight: .medium))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.75))
                .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)
                .padding(.top, 20)

            // 묵상 기록 보기 힌트 — 선(rule) + 텍스트 + 아이콘 순서
            // 시선이 왼쪽에서 오른쪽으로 흐르며 위로 올리는 동작을 자연스럽게 유도
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 20, height: 1)
                Text("묵상 기록 보기")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.5))
                Image(systemName: "chevron.up")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.top, 28)
        }
        .onTapGesture {
            showDetailSheet = true
        }
        .accessibilityLabel("묵상 기록 보기")
        .accessibilityHint("탭하면 묵상 내용을 확인할 수 있어요")
    }

    // MARK: - Detail Sheet

    private var meditationDetailSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 8)

                // 날짜
                Text(formattedEntryDate)
                    .font(.dvCaption)
                    .foregroundColor(.secondary)

                // 해석 + 적용
                interpretationSection
                applicationSection

                // 질문
                VStack(alignment: .leading, spacing: 8) {
                    Label("묵상 질문", systemImage: "bubble.left")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(questionText)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(5)
                }

                // 읽기 텍스트 (있을 때만)
                if let reading = entry.readingText, !reading.isEmpty {
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("말씀 필사", systemImage: "pencil")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(reading)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }

                // 한 줄 기도 (있을 때만)
                if let prayer = entry.prayer, !prayer.isEmpty {
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("한 줄 기도", systemImage: "hands.sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        Text(prayer)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }

                // 기도 제목들 (있을 때만)
                if !entry.prayerItems.isEmpty {
                    Divider().padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("기도 제목", systemImage: "heart")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        ForEach(entry.prayerItems) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: item.isAnswered ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isAnswered ? .dvAccentGold : .secondary)
                                    .accessibilityLabel(item.isAnswered ? "응답됨" : "기도 중")
                                Text(item.text)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundColor(item.isAnswered ? .secondary : .primary)
                                    .strikethrough(item.isAnswered, color: .secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 해석 섹션

    @ViewBuilder
    private var interpretationSection: some View {
        let text = verse?.contemplationInterpretation ?? verse?.interpretation ?? ""
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("해석", systemImage: "lightbulb")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(5)
            }
            Divider().padding(.vertical, 4)
        }
    }

    // MARK: - 일상 적용 섹션

    @ViewBuilder
    private var applicationSection: some View {
        let text = verse?.application ?? ""
        if !text.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Label("일상 적용", systemImage: "heart.text.square")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(5)
            }
            Divider().padding(.vertical, 4)
        }
    }

    // MARK: - Helpers

    private var questionText: String {
        verse?.question
            ?? "이 말씀이 오늘 나의 삶에 어떻게 다가왔나요?"
    }

    private var parsedEntryDate: Date? {
        let parser = DateFormatter()
        parser.dateFormat = "yyyy-MM-dd"
        return parser.date(from: entry.dateKey)
    }

    /// "2026" 연도만 추출 — 날짜 블록 최상단 맥락 레이어
    private var entryYear: String {
        guard let date = parsedEntryDate else { return "" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy"
        return fmt.string(from: date)
    }

    /// "4월 12일" 형식
    private var entryMonthDay: String {
        guard let date = parsedEntryDate else { return entry.dateKey }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일"
        return fmt.string(from: date)
    }

    /// "토요일" 형식
    private var entryWeekday: String {
        guard let date = parsedEntryDate else { return "" }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "EEEE"
        return fmt.string(from: date)
    }

    /// 바텀시트 날짜 전체 표시용
    private var formattedEntryDate: String {
        guard let date = parsedEntryDate else { return entry.dateKey }
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "yyyy년 M월 d일 EEEE"
        return fmt.string(from: date)
    }

    // MARK: - Body

    var body: some View {
        ZStack {

            // 레이어 1: 배경 이미지 또는 모드 그라데이션
            if let urlString = entry.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        backgroundGradient
                    }
                }
                .ignoresSafeArea()
                .clipped()
            } else {
                backgroundGradient.ignoresSafeArea()
            }

            // 레이어 2: 4-stop 감성 오버레이
            overlayGradient

            // 레이어 3: 말씀 블록 — GeometryReader로 y 50% 위치 고정
            GeometryReader { geo in
                let w = geo.size.width
                let hPad: CGFloat = max(w * 0.10, 24.0)

                verseBlock
                    .padding(.horizontal, hPad)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .position(x: w / 2, y: geo.size.height * 0.50)
            }
        }
        // 레이어 4: 상단 오버레이 — 날짜(좌) + 닫기(우)
        .overlay(alignment: .top) {
            HStack(alignment: .top, spacing: 0) {

                // 날짜 블록: 연도 / 구분선 / 월·일 / 요일 3단 수직
                dateBlock

                Spacer()

                // 닫기 버튼 — 배경 최소화, 아이콘 차분하게
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(10)
                        .background(Color.white.opacity(0.10))
                        .clipShape(Circle())
                }
                .accessibilityLabel("닫기")
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
        }
        .sheet(isPresented: $showDetailSheet) {
            meditationDetailSheet
        }
        .task {
            let id = entry.verseId
            guard !id.isEmpty else { return }

            // 1. Core Data 캐시 (가장 빠름)
            if let v = DailyCacheManager.shared.loadCachedVerse(id: id) {
                verse = v; return
            }
            // 2. 번들 폴백 (오프라인 안전망)
            if let v = Verse.fallbackVerses.first(where: { $0.id == id }) {
                verse = v; return
            }
            // 3. VerseRepository — 메모리 캐시 우선, 없으면 Firestore 호출
            //    (fetchVerses는 30분 내 재호출 시 in-memory 반환 → 네트워크 불필요)
            if let verses = try? await VerseRepository.shared.fetchVerses() {
                verse = verses.first { $0.id == id }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleEntry = MeditationEntry(
        id: "preview-001",
        userId: "local",
        dateKey: "2026-04-10",
        verseId: "fallback_rise_ignite",
        verseReference: "이사야 41:10",
        mode: "rise_ignite",
        prayerItems: [
            PrayerItem(text: "가족의 건강", isAnswered: false),
            PrayerItem(text: "오늘 회의 잘 마무리되게", isAnswered: true)
        ],
        gratitudeNote: nil,
        createdAt: Date(),
        updatedAt: Date(),
        source: "guided",
        prayer: "주님, 오늘 하루도 함께해 주세요.",
        readingText: "두려워하지 말라 내가 너와 함께 함이라",
        imageUrl: nil
    )
    MeditationEntryDetailView(entry: sampleEntry)
}
