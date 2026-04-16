import SwiftUI
import Combine
import CoreLocation
import UserNotifications
import AuthenticationServices

// v5.1 — Settings 탭 (닉네임 추가, 단일 플랜, 외관 섹션)

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var permissionManager: PermissionManager
    @ObservedObject private var nicknameManager = NicknameManager.shared

    // Design Ref: §6 — 인사말 언어 설정 (ko/en/random, 기본값: random)
    @AppStorage("greetingLanguage") private var greetingLanguage: String = "random"

    @State private var showRetentionAlert = false       // 1단계: 붙잡기
    @State private var showDeleteAccountAlert = false   // 2단계: 최종 확인
    @State private var showSignOutAlert = false
    @State private var showLoginPrompt = false
    @State private var showNicknameEdit = false
    @State private var editingNickname = ""
    @State private var deleteErrorMessage: String? = nil
    #if DEBUG
    @State private var showOnboardingPreview = false
    @AppStorage("onboardingV2Completed") private var onboardingCompleted = false
    #endif
    // deleteSuccessMessage는 AuthManager.deletionCompleteMessage로 이동 (AppRootView에서 표시)

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
                #if DEBUG
                debugSection
                #endif
                // Fix 3: 탭바 겹침 방지 — 하단 여백
                Color.clear.listRowBackground(Color.clear).frame(height: 60)
            }
            .scrollContentBackground(.hidden)
            .background(Color.dvBgDeep.ignoresSafeArea())
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.dvBgDeep.opacity(0.85), for: .navigationBar)
        }
        .task { await permissionManager.checkAll() }
        // 1단계: 리텐션 팝업 (붙잡기)
        .alert("잠깐만요 🙏", isPresented: $showRetentionAlert) {
            Button("그래도 탈퇴할게요", role: .destructive) {
                showDeleteAccountAlert = true
            }
            Button("머물게요", role: .cancel) {}
        } message: {
            Text("지금까지 쌓아온 말씀과 묵상 기록이 모두 사라져요.\n정말 떠나실 건가요?")
        }
        .alert("로그아웃", isPresented: $showSignOutAlert) {
            Button("로그아웃", role: .destructive) { authManager.signOut() }
            Button("취소", role: .cancel) {}
        } message: { Text("로그아웃 하시겠어요?") }
        .alert("계정을 탈퇴하시겠어요?", isPresented: $showDeleteAccountAlert) {
            Button("탈퇴하기", role: .destructive) {
                Task {
                    do {
                        try await authManager.deleteAccount(subscriptionManager: subscriptionManager)
                    } catch let error as NSError
                        where error.domain == ASAuthorizationError.errorDomain
                           || error.code == ASAuthorizationError.canceled.rawValue {
                        // 유저가 Apple 인증을 취소한 경우 — 에러 없이 조용히 종료
                    } catch {
                        let msg = error.localizedDescription
                        deleteErrorMessage = msg.isEmpty ? "탈퇴 중 오류가 발생했습니다. 다시 시도해주세요." : msg
                    }
                }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("Apple 계정 인증 후 탈퇴가 진행됩니다.\n구독 중이라면 App Store에서 별도 해지해주세요.\n저장된 모든 말씀이 삭제됩니다.")
        }
        .alert("탈퇴 실패", isPresented: .init(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { deleteErrorMessage = nil }
        } message: {
            Text(deleteErrorMessage ?? "")
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showOnboardingPreview) {
            OnboardingContainerView()
        }
        #endif
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

                Button("계정 탈퇴", role: .destructive) { showRetentionAlert = true }
            } else {
                Button {
                    showLoginPrompt = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                        Text("로그인 / 회원가입")
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

            // 인사말 언어 설정
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.bubble.fill").foregroundColor(.dvAccentGold)
                    Text("인사말 언어")
                }
                Picker("인사말 언어", selection: $greetingLanguage) {
                    Text("한국어").tag("ko")
                    Text("English").tag("en")
                    Text("랜덤").tag("random")
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)
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

    // MARK: - Debug (DEBUG 빌드 전용)

    #if DEBUG
    private var debugSection: some View {
        Section {
            Button {
                onboardingCompleted = false
                showOnboardingPreview = true
            } label: {
                Label("온보딩 처음부터 보기", systemImage: "arrow.counterclockwise")
            }
            .foregroundColor(.orange)

            Button {
                DailyCacheManager.shared.clearCache()
            } label: {
                Label("말씀 캐시 초기화", systemImage: "trash")
            }
            .foregroundColor(.red)

            Button {
                UserDefaults.standard.set(false, forKey: "featureTourV2Shown")
            } label: {
                Label("피처 투어 다시보기", systemImage: "sparkles")
            }
            .foregroundColor(.blue)
        } header: {
            Text("🛠 개발자 옵션 (DEBUG only)")
        }
    }
    #endif

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
