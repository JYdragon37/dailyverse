import SwiftUI

// Design Ref: §4.3 — Headspace 2-Question 패턴, 테마 그리드 + 닉네임 동일 화면
// Plan SC: 테마 선택율 80%+ / 개인화 데이터 → 말씀 알고리즘 연동

struct ONBPersonalizeView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer().frame(height: 80)

                        // 질문 헤더
                        VStack(alignment: .leading, spacing: 8) {
                            Text("지금 당신에게 필요한 건")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            Text("어떤 말씀인가요?")
                                .font(.system(size: 28, weight: .heavy))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)

                            Text("최대 3개까지 선택할 수 있어요")
                                .font(.dvCaption)
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 4)
                        }
                        .padding(.horizontal, 28)

                        Spacer().frame(height: 20)

                        // 테마 그리드 (2열 × 4행)
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 10
                        ) {
                            ForEach(OnboardingViewModel.themes) { theme in
                                ONBThemeChip(
                                    emoji: theme.emoji,
                                    label: theme.label,
                                    iconColor: theme.color,
                                    isSelected: vm.selectedThemes.contains(theme.id),
                                    isDisabled: vm.selectedThemes.count >= 3 && !vm.selectedThemes.contains(theme.id),
                                    onTap: { vm.toggleTheme(theme.id) }
                                )
                            }
                        }
                        .padding(.horizontal, 28)

                        Spacer().frame(height: 24)
                    }
                }
                // CTA — ScrollView 밖에 항상 하단 고정
                VStack(spacing: 0) {
                    // 주 CTA — 항상 "다음으로 →" 고정
                    Button {
                        vm.next()
                    } label: {
                        HStack(spacing: 8) {
                            Text("다음으로 →")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(vm.selectedThemes.isEmpty ? Color.white.opacity(0.15) : Color.white.opacity(0.30))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.35), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .padding(.bottom, 20)
                    .animation(.spring(response: 0.3), value: vm.selectedThemes.isEmpty)
                    .accessibilityLabel(vm.selectedThemes.isEmpty ? "테마 없이 다음으로" : "테마 선택 완료")
                }
            }
        }
    }
}

#Preview {
    ONBPersonalizeView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
