import SwiftUI

// MARK: - DevotionResponseView
// Screen 3 — 묵상 응답 (묵상 일상 적용 + 묵상 질문 + 한 줄 기도)

struct DevotionResponseView: View {

    let verse: Verse?
    let readingText: String          // Screen 2에서 전달받은 읽기 텍스트
    @ObservedObject var viewModel: MeditationViewModel
    @EnvironmentObject private var authManager: AuthManager

    // MARK: - Focus

    private enum Field: Hashable { case prayer }
    @FocusState private var focusedField: Field?

    // MARK: - Input State

    @State private var prayer: String = ""
    @State private var showComplete: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    applianceSection.padding(.bottom, 20)
                    dashedDivider.padding(.bottom, 20)
                    questionSection.padding(.bottom, 20)
                    dashedDivider.padding(.bottom, 20)
                    prayerSection.padding(.bottom, 20)
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .frame(maxWidth: .infinity)
            }

            bottomCTA
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.dvBgDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("묵상 응답")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text(formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .fullScreenCover(isPresented: $showComplete) {
            DevotionCompleteView(
                verse: verse,
                prayer: prayer,
                viewModel: viewModel
            )
        }
    }

    // MARK: - 섹션 1: 묵상 일상 적용

    private var applianceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("🌱 묵상 일상 적용")

            VStack(alignment: .leading, spacing: 8) {
                let appliance = verse.flatMap { v in
                    v.contemplationAppliance?.isEmpty == false ? v.contemplationAppliance : nil
                } ?? verse.flatMap { v in
                    v.application.isEmpty ? nil : v.application
                } ?? "오늘 이 말씀을 삶 속 어느 순간에 떠올릴 수 있을까요?"

                // #11: 닉네임 prefix
                let nickname = NicknameManager.shared.nickname
                let prefixed = "\(nickname), \(appliance)"

                Text(prefixed)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.88))
                    .lineSpacing(17 * 0.65)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dvBgSurface)
            )
        }
    }

    // MARK: - 섹션 2: 묵상 질문

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("💬 묵상 질문")

            VStack(alignment: .leading, spacing: 8) {
                let question = verse.flatMap { v in
                    v.question?.isEmpty == false ? v.question : nil
                } ?? "이 말씀이 오늘 나의 삶에 어떻게 다가왔나요?"

                Text(question)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.dvAccentGold)
                    .lineSpacing(16 * 0.6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("입력 없음. 마음속으로 생각해보세요.")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dvBgSurface)
            )
        }
    }

    // MARK: - 섹션 3: 한 줄 기도

    private var prayerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("✍️ 한 줄 기도")

            Text("오늘 묵상하며 떠오른 기도를 한 줄로 적어보세요. (선택)")
                .font(.dvCaption)
                .foregroundColor(.white.opacity(0.55))

            VStack(alignment: .trailing, spacing: 6) {
                TextField("주님, ...", text: $prayer)
                    .font(.dvBody)
                    .foregroundColor(.white)
                    .tint(.dvAccentGold)
                    .focused($focusedField, equals: .prayer)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.06))
                    )
                    .onChange(of: prayer) { newValue in
                        if newValue.count > 50 {
                            prayer = String(newValue.prefix(50))
                        }
                    }

                Text("\(prayer.count) / 50자")
                    .font(.dvCaption)
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.dvBgSurface)
            )
        }
    }

    // MARK: - Complete Handler

    private func handleComplete() {
        Task {
            await viewModel.saveGuided(
                userId: authManager.userId ?? "local",
                prayer: prayer.trimmingCharacters(in: .whitespacesAndNewlines),
                readingText: readingText
            )
            showComplete = true
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
    }

    private var dashedDivider: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .foregroundColor(Color.white.opacity(0.20))
        }
        .frame(height: 1)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일"
        return f.string(from: Date())
    }

    // MARK: - Bottom CTA (VStack 하단 고정)

    private var bottomCTA: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [Color.dvBgDeep.opacity(0), Color.dvBgDeep],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 20)
            .allowsHitTesting(false)

            Button { handleComplete() } label: {
                Text("✨ 묵상 마치기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.dvAccentGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.dvAccentGold.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.dvAccentGold.opacity(0.35), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 76)  // DVTabBar 위 여백 유지
        }
        .background(Color.dvBgDeep)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DevotionResponseView(
            verse: .fallbackRiseIgnite,
            readingText: "",
            viewModel: MeditationViewModel()
        )
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(UpsellManager())
    }
    .preferredColorScheme(.dark)
}
