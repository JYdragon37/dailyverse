import SwiftUI

// Design Ref: §4.4 — Permission Priming + 첫 알람 설정
// Plan SC: 알람 설정율 70%+ / 알림 허용율 60%+ (Priming: 45% → 65%+)

struct ONBAlarmPermissionView: View {
    @ObservedObject var vm: OnboardingViewModel

    // 알람 설정 여부 (Priming 섹션 표시 트리거)
    private var hasAnyAlarm: Bool {
        vm.morningAlarmEnabled
    }

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

                        // 헤더
                        VStack(alignment: .leading, spacing: 8) {
                            Text("매일 아침,\n알람 시간을 설정해주세요")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("말씀이 알람과 함께 도착해요")
                                .font(.dvBody)
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .padding(.horizontal, 28)

                        Spacer().frame(height: 32)

                        // 알람 시간 카드
                        VStack(spacing: 12) {
                            ONBAlarmTimeRow(
                                icon: "sunrise.fill",
                                label: "아침",
                                iconColor: Color(red: 1.0, green: 0.78, blue: 0.25),
                                isEnabled: $vm.morningAlarmEnabled,
                                time: $vm.morningAlarmTime
                            )
                        }
                        .padding(.horizontal, 28)

                        // 알림 미리보기 영역 (CTA 제외)
                        permissionInfoSection

                        Spacer().frame(height: 24)
                    }
                }

                // CTA — ScrollView 밖에 항상 하단 고정
                pinnedCTASection
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: hasAnyAlarm)
    }

    // MARK: - 알림 미리보기 (스크롤 영역, CTA 제외)

    private var permissionInfoSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 16)

            // 구분선
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 28)

            // 알림 배너 목업 (Permission Priming 핵심)
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.dvAccentGold.opacity(0.18))
                        .frame(width: 54, height: 54)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.dvAccentGold)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("DailyVerse")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    Text("\"두려워하지 말라 내가 너와 함께 함이라\"")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)

            Spacer().frame(height: 16)

            // 설명 문구
            Text("시끄러운 알람 소리 대신, 마음을 울리는 말씀으로\n하루를 뜻깊게 시작하세요")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 28)
        }
    }

    // MARK: - 알람 미설정 시 안내 텍스트 (스크롤 영역, CTA 제외)

    private var skipInfoSection: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)

            Text("알람을 설정하지 않아도 시작할 수 있어요")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }

    // MARK: - 하단 고정 CTA (ScrollView 밖)

    private var pinnedCTASection: some View {
        VStack(spacing: 12) {
            if hasAnyAlarm {
                // 알림 허용 버튼
                Button {
                    Task {
                        await vm.requestNotification()
                        vm.completeOnboarding()
                    }
                } label: {
                    Text("알림 허용하기")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2340"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                        )
                }
                .accessibilityLabel("알림 권한 허용 후 시작하기")

                // 나중에 버튼
                Button {
                    vm.completeOnboarding()
                } label: {
                    Text("나중에")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.65))
                        .frame(height: 44)
                }
                .accessibilityLabel("알림 허용 건너뛰기")
            } else {
                // 알림 허용 버튼 (알람 없어도 알림은 받을 수 있음)
                Button {
                    Task {
                        await vm.requestNotification()
                        vm.completeOnboarding()
                    }
                } label: {
                    Text("알림 허용하기")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2340"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white)
                        )
                }
                .accessibilityLabel("알림 권한 허용 후 시작하기")

                // 나중에 (텍스트 버튼)
                Button {
                    vm.completeOnboarding()
                } label: {
                    Text("나중에")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.65))
                        .frame(height: 44)
                }
                .accessibilityLabel("알림 건너뛰기")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: hasAnyAlarm)
    }
}

#Preview {
    ONBAlarmPermissionView(vm: OnboardingViewModel())
        .preferredColorScheme(.dark)
}
