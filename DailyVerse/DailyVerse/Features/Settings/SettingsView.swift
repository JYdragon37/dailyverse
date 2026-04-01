import SwiftUI
import Combine
import CoreLocation
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var permissionManager: PermissionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var showLoginPrompt = false
    @State private var showUpsell = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (build \(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                permissionsSection
                appInfoSection
                feedbackSection
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
        }
        .task {
            await permissionManager.checkAll()
        }
        .alert("로그아웃", isPresented: $showSignOutAlert) {
            Button("로그아웃", role: .destructive) {
                authManager.signOut()
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("로그아웃 하시겠어요?")
        }
        .alert("계정을 탈퇴하시겠어요?", isPresented: $showDeleteAccountAlert) {
            Button("탈퇴하기", role: .destructive) {
                Task { try? await authManager.deleteAccount(subscriptionManager: subscriptionManager) }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("구독 중이라면 App Store에서 별도로 해지해주세요.\n저장된 모든 말씀이 삭제됩니다.")
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet {
                showLoginPrompt = false
                Task { await authManager.signIn() }
            } onDismiss: {
                showLoginPrompt = false
            }
        }
        .sheet(isPresented: $showUpsell) {
            UpsellBottomSheet()
                .environmentObject(subscriptionManager)
                .environmentObject(upsellManager)
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        Section("계정") {
            if authManager.isLoggedIn {
                // 이메일 표시
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.dvAccent)
                        .accessibilityHidden(true)
                    Text(authManager.user?.email ?? "Apple 계정")
                        .font(.dvBody)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("로그인 계정: \(authManager.user?.email ?? "Apple 계정")")

                Button("로그아웃") {
                    showSignOutAlert = true
                }
                .foregroundColor(.primary)
                .accessibilityLabel("로그아웃 버튼")

                Button("계정 탈퇴", role: .destructive) {
                    showDeleteAccountAlert = true
                }
                .accessibilityLabel("계정 탈퇴 버튼")
            } else {
                Button {
                    showLoginPrompt = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                            .accessibilityHidden(true)
                        Text("Apple로 시작하기")
                    }
                }
                .foregroundColor(.dvAccent)
                .accessibilityLabel("Apple 계정으로 로그인")
            }
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        Section("구독") {
            if subscriptionManager.isPremium {
                Label("Premium 구독 중", systemImage: "crown.fill")
                    .foregroundColor(.dvAccent)
                    .accessibilityLabel("현재 Premium 구독 중")

                Button("구독 관리") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.primary)
                .accessibilityLabel("App Store 구독 관리 페이지 열기")
            } else {
                // 현재 플랜
                HStack {
                    Text("현재 플랜")
                        .font(.dvBody)
                    Spacer()
                    Text("Free")
                        .font(.dvBody)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("현재 플랜 Free")

                Button {
                    upsellManager.show(trigger: .nextVerse)
                    showUpsell = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium 시작하기")
                                .font(.dvBody)
                            Text("₩24,500/월")
                                .font(.dvCaption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .foregroundColor(.dvAccent)
                .accessibilityLabel("Premium 구독 시작하기 월 24500원")
            }
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        Section("권한") {
            PermissionRow(
                title: "위치",
                icon: "location.fill",
                statusText: permissionManager.locationStatusText,
                isGranted: permissionManager.locationAuthorized,
                onOpenSettings: { permissionManager.openAppSettings() }
            )

            PermissionRow(
                title: "알림",
                icon: "bell.fill",
                statusText: permissionManager.notificationStatusText,
                isGranted: permissionManager.notificationAuthorized,
                onOpenSettings: { permissionManager.openAppSettings() }
            )
        }
    }

    // MARK: - App Info Section

    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Text("버전")
                Spacer()
                Text(appVersion)
                    .font(.dvCaption)
                    .foregroundColor(.secondary)
            }
            .accessibilityLabel("앱 버전 \(appVersion)")

            Link("이용약관", destination: URL(string: "https://example.com/terms")!)
                .foregroundColor(.primary)
                .accessibilityLabel("이용약관 보기")

            Link("개인정보처리방침", destination: URL(string: "https://example.com/privacy")!)
                .foregroundColor(.primary)
                .accessibilityLabel("개인정보처리방침 보기")

            Link("오픈소스 라이선스", destination: URL(string: "https://example.com/opensource")!)
                .foregroundColor(.primary)
                .accessibilityLabel("오픈소스 라이선스 보기")
        }
    }

    // MARK: - Feedback Section

    private var feedbackSection: some View {
        Section("피드백") {
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id0000000000?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Text("앱 리뷰 남기기")
                }
            }
            .foregroundColor(.primary)
            .accessibilityLabel("App Store 리뷰 남기기")

            Link("문의하기", destination: URL(string: "mailto:support@dailyverse.app")!)
                .foregroundColor(.primary)
                .accessibilityLabel("이메일로 문의하기")
        }
    }
}

// MARK: - PermissionRow

private struct PermissionRow: View {
    let title: String
    let icon: String
    let statusText: String
    let isGranted: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(isGranted ? .dvAccent : .secondary)
                .frame(width: 20)
                .accessibilityHidden(true)

            Text(title)
                .font(.dvBody)

            Spacer()

            Text(statusText)
                .font(.dvCaption)
                .foregroundColor(isGranted ? .dvAccent : .secondary)

            if !isGranted {
                Button("재설정") {
                    onOpenSettings()
                }
                .font(.dvCaption)
                .foregroundColor(.dvAccent)
                .accessibilityLabel("\(title) 권한 설정 열기")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) 권한 상태: \(statusText)\(isGranted ? "" : ", 재설정 가능")")
    }
}

// MARK: - Preview

#Preview("비로그인 + Premium") {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
        .environmentObject(UpsellManager())
}

#Preview("비로그인 + Free") {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
        .environmentObject(UpsellManager())
}
