import SwiftUI
import Combine
import CoreLocation
import UserNotifications

// v5.1 — Settings 탭 (닉네임 추가, 단일 플랜, 외관 섹션)

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var permissionManager: PermissionManager
    @ObservedObject private var nicknameManager = NicknameManager.shared

    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var showLoginPrompt = false
    @State private var showNicknameEdit = false
    @State private var editingNickname = ""

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (build \(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                accountSection
                subscriptionSection
                permissionsSection
                appearanceSection
                homeBgSection
                appInfoSection
                feedbackSection
                // Fix 3: 탭바 겹침 방지 — 하단 여백
                Color.clear.listRowBackground(Color.clear).frame(height: 60)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await permissionManager.checkAll() }
        .alert("로그아웃", isPresented: $showSignOutAlert) {
            Button("로그아웃", role: .destructive) { authManager.signOut() }
            Button("취소", role: .cancel) {}
        } message: { Text("로그아웃 하시겠어요?") }
        .alert("계정을 탈퇴하시겠어요?", isPresented: $showDeleteAccountAlert) {
            Button("탈퇴하기", role: .destructive) {
                Task { try? await authManager.deleteAccount(subscriptionManager: subscriptionManager) }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("구독 중이라면 App Store에서 별도 해지해주세요.\n저장된 모든 말씀이 삭제됩니다.")
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet {
                showLoginPrompt = false
                Task { await authManager.signIn() }
            } onDismiss: { showLoginPrompt = false }
        }
        .alert("닉네임 변경", isPresented: $showNicknameEdit) {
            TextField("한글 5자 / 영어 8자 이내", text: $editingNickname)
            Button("저장") {
                Task {
                    await nicknameManager.setNickname(
                        editingNickname,
                        userId: authManager.userId
                    )
                }
            }
            Button("취소", role: .cancel) {}
        } message: { Text("한글 5자 또는 영어·숫자 8자 이내로 입력해주세요") }
    }

    // MARK: - Account

    private var accountSection: some View {
        Section("계정") {
            // 닉네임 (v5.1)
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.dvAccentGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("닉네임")
                        .font(.dvCaption).foregroundColor(.secondary)
                    Text(nicknameManager.nickname)
                        .font(.dvBody)
                }
                Spacer()
                Button("변경") {
                    editingNickname = nicknameManager.nickname
                    showNicknameEdit = true
                }
                .font(.dvCaption)
                .foregroundColor(.dvAccentGold)
            }

            if authManager.isLoggedIn {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.secondary)
                    Text(authManager.user?.email ?? "Apple 계정")
                        .font(.dvBody).foregroundColor(.secondary)
                }

                Button("로그아웃") { showSignOutAlert = true }
                    .foregroundColor(.primary)

                Button("계정 탈퇴", role: .destructive) { showDeleteAccountAlert = true }
            } else {
                Button {
                    showLoginPrompt = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "apple.logo")
                        Text("Apple로 시작하기")
                    }
                }
                .foregroundColor(.dvAccentGold)
            }
        }
    }

    // MARK: - Subscription (v5.1: 단일 플랜 안내)

    private var subscriptionSection: some View {
        Section("구독") {
            HStack {
                Label("현재 플랜", systemImage: "checkmark.seal.fill")
                    .foregroundColor(.dvAccentGold)
                Spacer()
                Text("전체 기능 제공")
                    .font(.dvCaption).foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("구독 기능은 향후 업데이트에서 도입됩니다")
                    .font(.dvCaption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Permissions

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

    // MARK: - Appearance (v5.1 신규)

    private var appearanceSection: some View {
        Section("외관") {
            HStack {
                Image(systemName: "moon.fill").foregroundColor(.dvAccentGold)
                Text("다크 모드")
                Spacer()
                Text("시스템 따라가기")
                    .font(.dvCaption).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Home Background

    private var homeBgSection: some View {
        Section("홈 배경") {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .foregroundColor(.dvAccentGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("배경 이미지 설정")
                        .font(.dvBody)
                    Text("말씀들 탭에서 저장한 말씀의 상세 화면에서 설정할 수 있어요")
                        .font(.dvCaption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - App Info

    private var appInfoSection: some View {
        Section("앱 정보") {
            HStack {
                Text("버전")
                Spacer()
                Text(appVersion).font(.dvCaption).foregroundColor(.secondary)
            }
            Link("이용약관", destination: URL(string: "https://example.com/terms")!)
                .foregroundColor(.primary)
            Link("개인정보처리방침", destination: URL(string: "https://example.com/privacy")!)
                .foregroundColor(.primary)
        }
    }

    // MARK: - Feedback

    private var feedbackSection: some View {
        Section("피드백") {
            Button {
                if let url = URL(string: "https://apps.apple.com/app/id0") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("⭐ 앱 리뷰 남기기", systemImage: "star.fill")
            }
            .foregroundColor(.primary)

            Link("📨 문의하기", destination: URL(string: "mailto:support@dailyverse.app")!)
                .foregroundColor(.primary)
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
                .foregroundColor(isGranted ? .dvAccentGold : .secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dvBody)
                Text(statusText).font(.dvCaption).foregroundColor(.secondary)
            }
            Spacer()
            if !isGranted {
                Button("설정 열기", action: onOpenSettings)
                    .font(.dvCaption)
                    .foregroundColor(.dvAccentGold)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
}
