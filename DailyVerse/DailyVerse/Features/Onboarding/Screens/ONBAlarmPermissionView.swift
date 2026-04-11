import SwiftUI

// Design Ref: §4.4 — Permission Priming + 첫 알람 설정
// Plan SC: 알람 설정율 70%+ / 알림 허용율 60%+ (Priming: 45% → 65%+)

struct ONBAlarmPermissionView: View {
    @ObservedObject var vm: OnboardingViewModel

    // 알람 설정 여부 (Priming 섹션 표시 트리거)
    private var hasAnyAlarm: Bool {
        vm.morningAlarmEnabled || vm.eveningAlarmEnabled
    }

    var body: some View {
        ZStack {
            Color.dvBgDeep.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 64)

                    // 헤더
                    VStack(alignment: .leading, spacing: 8) {
                        Text("언제 말씀을 받고 싶으신가요?")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("알람이 울릴 때 함께 도착해요")
                            .font(.dvBody)
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 32)

                    // 알람 시간 카드
                    VStack(spacing: 12) {
                        ONBAlarmTimeRow(
                            icon: "☀️",
                            label: "아침",
                            isEnabled: $vm.morningAlarmEnabled,
                            time: $vm.morningAlarmTime
                        )
                        ONBAlarmTimeRow(
                            icon: "🌙",
                            label: "저녁",
                            isEnabled: $vm.eveningAlarmEnabled,
                            time: $vm.eveningAlarmTime
                        )
                    }
                    .padding(.horizontal, 28)

                    // Permission Priming 섹션 (알람 하나라도 켜면 등장)
                    if hasAnyAlarm {
                        permissionPrimingSection
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        skipSection
                    }

                    Spacer().frame(height: 60)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: hasAnyAlarm)
    }

    // MARK: - Permission Priming 섹션

    private var permissionPrimingSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 32)

            // 구분선
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 28)

            // 알림 배너 목업 (Permission Priming 핵심)
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.dvAccentGold.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.dvAccentGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("DailyVerse 🔔")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\"두려워하지 말라 내가 너와 함께 함이라\"")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)

            // 설명 문구
            Text("알람과 동시에 오늘의 말씀이 잠금화면에 나타나요\n허용하지 않으면 알람만 울립니다")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)

            // 알림 허용 버튼 (Pre-prompt CTA)
            Button {
                Task {
                    await vm.requestNotification()
                    vm.completeOnboarding()
                }
            } label: {
                Text("알림 허용하기")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.dvAccentGold)
                    )
            }
            .padding(.horizontal, 28)
            .accessibilityLabel("알림 권한 허용 후 시작하기")

            // 나중에 버튼
            Button {
                vm.completeOnboarding()
            } label: {
                Text("나중에")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.4))
            }
            .accessibilityLabel("알림 허용 건너뛰기")
        }
    }

    // MARK: - 알람 미설정 시 스킵 섹션

    private var skipSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Text("알람을 설정하지 않아도 시작할 수 있어요")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                vm.completeOnboarding()
            } label: {
                Text("건너뛰기")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.06))
                    )
            }
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    ONBAlarmPermissionView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
