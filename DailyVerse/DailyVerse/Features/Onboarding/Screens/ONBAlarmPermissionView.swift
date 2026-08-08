import SwiftUI

// Screen 3 — 첫 알람 설정 (온보딩 클라이맥스)
// 단순 시간 피커 + 알림 권한 요청
// 요일/테마 선택 없음 (기본: 매일)

struct ONBAlarmPermissionView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var contentOpacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 72)

                // 헤더
                VStack(alignment: .leading, spacing: 10) {
                    Text(appLanguageString("onboarding.alarmPermission.header1", args: vm.nicknameDisplay))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text(appLanguageString("onboarding.alarmPermission.header2"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Spacer().frame(height: 4)
                    Text(appLanguageString("onboarding.alarmPermission.subtitle"))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)

                Spacer().frame(height: 40)

                // 시간 피커
                DatePicker(
                    "",
                    selection: $vm.morningAlarmTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .colorScheme(.dark)
                .environment(\.locale, Locale(identifier: UserDefaults.standard.string(forKey: "appLanguage") == "en" ? "en_US" : "ko_KR"))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)

                Spacer().frame(height: 20)

                // 반복 안내
                HStack(spacing: 6) {
                    Image(systemName: "repeat")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                    Text(appLanguageString("onboarding.alarmPermission.repeatHint"))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 28)

                Spacer()
            }
            .opacity(contentOpacity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { ctaSection }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                contentOpacity = 1
            }
        }
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 10) {
            // 메인 CTA — 알림 권한 요청 후 완료
            Button {
                Task {
                    await vm.requestNotification()
                    vm.completeOnboarding()
                }
            } label: {
                Text(appLanguageString("onboarding.alarmPermission.cta"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A2340"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
            }
            .accessibilityLabel(appLanguageString("onboarding.alarmPermission.cta.accessibility"))

            // 나중에 하기
            Button {
                vm.completeOnboardingSkipAlarm()
            } label: {
                Text(appLanguageString("onboarding.alarmPermission.later"))
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.55))
                    .padding(.vertical, 8)
            }

            // 수정 가능 안내
            Text(appLanguageString("onboarding.alarmPermission.editHint"))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .padding(.top, 8)
    }
}

#Preview {
    ONBAlarmPermissionView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
