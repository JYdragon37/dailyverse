import SwiftUI

// MARK: - 글자수 가독성 테스트 뷰 (Dev Only — 테스트 완료 후 삭제)

// 테스트할 글자수 후보
private let shortKoCandidates: [Int] = [20, 28, 35, 42, 50]
private let fullKoCandidates:  [Int] = [50, 70, 90, 110, 130]
private let interpretCandidates: [Int] = [80, 120, 160, 200]
private let applicationCandidates: [Int] = [40, 60, 80, 100]

// 한국어 성경 텍스트 기반 샘플 (반복 확장)
private let baseText = "두려워하지말라내가너와함께함이라놀라지말라나는네하나님이됨이라내가너를굳세게하리라참으로너를도와주리라참으로너를붙드시리라여호와는나의목자시니내게부족함이없으리로다그가나를푸른풀밭에누이시며쉴만한물가로인도하시는도다내가능력주시는자안에서모든것을할수있느니라"

private func sample(_ count: Int) -> String {
    var result = ""
    while result.count < count { result += baseText }
    return String(result.prefix(count))
}

// MARK: - 메인 테스트 뷰 (탭별 분리)

struct TextLimitTestView: View {
    @State private var selectedTab = 0
    private let tabs = ["Stage1", "홈Full", "VerseCard", "Sheet"]

    var body: some View {
        VStack(spacing: 0) {
            // 탭 선택
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { i, t in
                    Button(t) { selectedTab = i }
                        .font(.system(size: 13, weight: selectedTab == i ? .bold : .regular))
                        .foregroundColor(selectedTab == i ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == i ? Color.blue.opacity(0.4) : Color.clear)
                }
            }
            .background(Color.black)

            // 탭 내용 (ScrollView로 모든 후보 한번에 비교)
            switch selectedTab {
            case 0: Stage1TestPanel()
            case 1: HomeFullTestPanel()
            case 2: VerseCardTestPanel()
            default: SheetTestPanel()
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Stage1 테스트 (verseShortKo, NotoSerifCJKkr-Regular 28pt, center, h-pad 32)

struct Stage1TestPanel: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                ForEach(shortKoCandidates, id: \.self) { count in
                    Stage1SingleTest(count: count)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.black)
    }
}

struct Stage1SingleTest: View {
    let count: Int
    var body: some View {
        ZStack {
            // 실제 AlarmStage1 배경과 동일
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.07, blue: 0.18)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 0) {
                // 상단 날씨 pill 시뮬레이션 (실제와 동일)
                Text("서울 15°C · 맑음 · 습도 62%")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                Spacer()

                // 날씨 스트립 시뮬레이션 (높이 고정)
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 70)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                // ── 말씀 텍스트 (실제 AlarmStage1과 동일) ──
                VStack(spacing: 14) {
                    Text(sample(count))
                        .font(.custom("PretendardVariable", size: 28))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 32)

                    Text("이사야 41:10")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.65))
                }

                Spacer()

                // 버튼 영역 시뮬레이션 (실제와 동일)
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 52)
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.85, green: 0.72, blue: 0.40))
                        .frame(height: 52)
                        .overlay(Text("말씀 보기").font(.system(size: 17, weight: .semibold)).foregroundColor(.black))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            // 글자수 라벨 (우상단)
            VStack {
                HStack {
                    Spacer()
                    Text("\(count)자")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(.top, 8).padding(.trailing, 8)
                }
                Spacer()
            }
        }
        .frame(width: 375, height: 700)  // SE 기준 (375pt)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - HomeView verseFullKo 테스트 (NotoSerifCJKkr-SemiBold 22pt, h-pad 13%↑40)

struct HomeFullTestPanel: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                ForEach(fullKoCandidates, id: \.self) { count in
                    HomeSingleTest(count: count, deviceWidth: 390, label: "16")
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.black)
    }
}

struct HomeSingleTest: View {
    let count: Int
    let deviceWidth: CGFloat
    let label: String

    private var hPad: CGFloat { max(deviceWidth * 0.13, 40.0) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.28), Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 0) {
                // 상단 인사말 영역 시뮬 (고정 높이)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good Morning ☀️")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        Text("서울 · 15°C · 맑음")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 16)

                Spacer()

                // ── 말씀 텍스트 (실제 HomeView verseCenter와 동일) ──
                VStack(alignment: .leading, spacing: 0) {
                    Text(sample(count))
                        .font(.custom("PretendardVariable", size: 22).weight(.semibold))
                        .foregroundColor(.white)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.85), radius: 8, x: 0, y: 3)

                    HStack(spacing: 8) {
                        Text("이사야 41:10")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Hope")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.40))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 0.85, green: 0.72, blue: 0.40).opacity(0.2))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    .padding(.top, 18)

                    HStack(spacing: 8) {
                        Rectangle().fill(Color.white.opacity(0.30)).frame(width: 20, height: 1)
                        Text("말씀 깊게 보기")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.45))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .medium)).foregroundColor(.white.opacity(0.45))
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, hPad)

                Spacer()

                // 하단 탭바 여백
                Color.clear.frame(height: 90)
            }

            // 글자수 라벨
            VStack {
                HStack {
                    Spacer()
                    Text("\(count)자")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(.top, 8).padding(.trailing, 8)
                }
                Spacer()
            }
        }
        .frame(width: 375, height: 700)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - VerseCard 테스트 (verseShortKo, 26pt semibold)

struct VerseCardTestPanel: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                ForEach(shortKoCandidates, id: \.self) { count in
                    VerseCardSingleTest(count: count)
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.black)
    }
}

struct VerseCardSingleTest: View {
    let count: Int
    private let hPad: CGFloat = max(375 * 0.13, 40.0)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.28), Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            )

            VStack(spacing: 0) {
                // 인사말 영역
                HStack {
                    Text("Good Morning ☀️")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 24).padding(.top, 60)

                Spacer()

                // ── VerseCard 영역 (실제와 동일) ──
                VStack(alignment: .leading, spacing: 10) {
                    Text(sample(count))
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

                    HStack(spacing: 8) {
                        Text("이사야 41:10")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Hope")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 0.85, green: 0.72, blue: 0.40))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 0.85, green: 0.72, blue: 0.40).opacity(0.2))
                            .clipShape(Capsule())
                        Spacer()
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, hPad)

                Spacer()

                Color.clear.frame(height: 90)
            }

            // 글자수 라벨
            VStack {
                HStack {
                    Spacer()
                    Text("\(count)자")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(6)
                        .padding(.top, 8).padding(.trailing, 8)
                }
                Spacer()
            }
        }
        .frame(width: 375, height: 700)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - BottomSheet 테스트 (interpretation 17pt, application 19pt)

struct SheetTestPanel: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("interpretation (17pt)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)

                ForEach(interpretCandidates, id: \.self) { count in
                    SheetTextBlock(text: sample(count), fontSize: 17, label: "\(count)자")
                }

                Divider()

                Text("application (19pt)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)

                ForEach(applicationCandidates, id: \.self) { count in
                    SheetTextBlock(text: sample(count), fontSize: 19, label: "\(count)자 (application)")
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.white)
    }
}

struct SheetTextBlock: View {
    let text: String
    let fontSize: CGFloat
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 24)

            Text(text)
                .font(.system(size: fontSize, weight: .regular))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(fontSize == 17 ? 4 : 5)
                .padding(.horizontal, 24)

            Divider().padding(.horizontal, 24)
        }
    }
}

// MARK: - Previews

#Preview("Stage1 — iPhone SE 375pt") {
    Stage1TestPanel()
        .preferredColorScheme(.dark)
}

#Preview("Stage1 — iPhone 16 Pro Max 430pt") {
    // Pro Max는 Stage1 h-pad 32pt → 유효폭 366pt
    Stage1TestPanel()
        .preferredColorScheme(.dark)
}

#Preview("Home verseFullKo — SE") {
    HomeFullTestPanel()
        .preferredColorScheme(.dark)
}

#Preview("VerseCard — SE") {
    VerseCardTestPanel()
        .preferredColorScheme(.dark)
}

#Preview("BottomSheet") {
    SheetTestPanel()
}

#Preview("전체 탭뷰") {
    TextLimitTestView()
        .preferredColorScheme(.dark)
}
