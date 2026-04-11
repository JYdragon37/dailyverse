import SwiftUI

// Design Ref: §4.3 — Headspace 2-Question 패턴, 테마 그리드 + 닉네임 동일 화면
// Plan SC: 테마 선택율 80%+ / 개인화 데이터 → 말씀 알고리즘 연동

struct ONBPersonalizeView: View {
    @ObservedObject var vm: OnboardingViewModel
    @FocusState private var isNicknameFocused: Bool

    var body: some View {
        ZStack {
            Color.dvBgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 64)

                    // 질문 헤더
                    VStack(alignment: .leading, spacing: 8) {
                        Text("지금 당신에게 필요한 건")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("어떤 말씀인가요?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.dvAccentGold)

                        Text("최대 3개까지 선택할 수 있어요")
                            .font(.dvCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 28)

                    // 테마 그리드 (2열 × 4행)
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 12
                    ) {
                        ForEach(OnboardingViewModel.themes) { theme in
                            ONBThemeChip(
                                emoji: theme.emoji,
                                label: theme.label,
                                isSelected: vm.selectedThemes.contains(theme.id),
                                onTap: { vm.toggleTheme(theme.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)

                    // 구분선
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                        Text("그리고")
                            .font(.dvCaption)
                            .foregroundColor(.white.opacity(0.4))
                            .fixedSize()
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 28)

                    // 닉네임
                    VStack(alignment: .leading, spacing: 10) {
                        Text("우리가 어떻게 불러드릴까요?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        TextField("친구", text: $vm.nicknameInput)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .tint(.dvAccentGold)
                            .focused($isNicknameFocused)
                            .submitLabel(.done)
                            .onSubmit { isNicknameFocused = false }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.07))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(
                                                isNicknameFocused
                                                    ? Color.dvAccentGold.opacity(0.6)
                                                    : Color.white.opacity(0.15),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .animation(.easeInOut(duration: 0.2), value: isNicknameFocused)
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 40)

                    // CTA
                    Button {
                        isNicknameFocused = false
                        vm.next()
                    } label: {
                        HStack(spacing: 8) {
                            if !vm.selectedThemes.isEmpty {
                                Text(vm.selectedThemes.prefix(3).map { id in
                                    OnboardingViewModel.themes.first { $0.id == id }?.emoji ?? ""
                                }.joined())
                                .font(.system(size: 16))
                            }
                            Text(vm.selectedThemes.isEmpty ? "건너뛰기" : "선택 완료 →")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(vm.selectedThemes.isEmpty ? .white.opacity(0.5) : .black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(vm.selectedThemes.isEmpty
                                      ? Color.white.opacity(0.08)
                                      : Color.dvAccentGold)
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 60)
                    .animation(.spring(response: 0.3), value: vm.selectedThemes.isEmpty)
                    .accessibilityLabel(vm.selectedThemes.isEmpty ? "건너뛰기" : "테마 선택 완료")
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}

#Preview {
    ONBPersonalizeView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
