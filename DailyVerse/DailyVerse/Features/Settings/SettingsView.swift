import SwiftUI
import Combine
import CoreLocation
import UserNotifications
import AuthenticationServices

// v6.0 — Settings 전면 리디자인
// 참고: 2024-2025 iOS 트렌드 (Toss / Apple HIG)
// - 프로필 카드 상단 고정, 로그아웃·탈퇴 최하단 배치
// - 컬러 아이콘 원형 배지 + 둥근 카드 섹션
// - Form 제거 → 커스텀 ScrollView + VStack 카드

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var permissionManager: PermissionManager
    @ObservedObject private var nicknameManager = NicknameManager.shared

    @AppStorage("greetingLanguage") private var greetingLanguage: String = "random"
    @AppStorage("profileEmoji") private var profileEmoji: String = ""
    @AppStorage("meditationReminderEnabled") private var meditationReminderEnabled: Bool = true
    @AppStorage("meditationReminderHour") private var meditationReminderHour: Int = 21
    @AppStorage("meditationReminderMinute") private var meditationReminderMinute: Int = 0

    @State private var showRetentionAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showSignOutAlert = false
    @State private var showLoginPrompt = false
    @State private var showNicknameEdit = false
    @State private var showEmojiPicker = false
    @State private var showReminderTimePicker = false
    @State private var editingNickname = ""
    @State private var deleteErrorMessage: String? = nil

    #if DEBUG
    @State private var showOnboardingPreview = false
    @State private var showSplashPreview = false
    @AppStorage("onboardingV2Completed") private var onboardingCompleted = false
    @State private var contentVersion: String = "로딩 중..."
    #endif

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) (\(b))"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── 프로필 카드 ─────────────────────────
                    profileCard
                        .padding(.horizontal, 16)
                        .padding(.top, 4)

                    // ── 외관 ────────────────────────────────
                    sectionCard(title: "외관") { appearanceRows }

                    // ── 앱 설정 ─────────────────────────────
                    sectionCard(title: "앱 설정") { permissionRows }

                    // ── 묵상 리마인더 ────────────────────────
                    sectionCard(title: "묵상 리마인더") { meditationReminderRows }

                    // ── 앱 정보 ─────────────────────────────
                    sectionCard(title: "앱 정보") { appInfoRows }

                    // ── 피드백 ──────────────────────────────
                    sectionCard(title: "피드백") { feedbackRows }

                    // ── 광고 배너 (Free 유저만 표시) ──
                    if !subscriptionManager.isPremium {
                        BannerAdView()
                            .frame(width: 300, height: 250)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                    }

                    // ── 계정 관리 (로그인 시만, 최하단) ────
                    if authManager.isLoggedIn {
                        sectionCard(title: "계정 관리") { accountRows }
                    }

                    #if DEBUG
                    sectionCard(title: "🛠 개발자 옵션") { debugRows }
                    #endif

                    // 브랜드 footer (설정 탭 최하단)
                    Image("LogoMMColor")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64)
                        .opacity(0.20)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                }
            }
            .background(Color.dvBgDeep.ignoresSafeArea())
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.dvBgDeep.opacity(0.95), for: .navigationBar)
        }
        .task { await permissionManager.checkAll() }
        .task { await permissionManager.checkAlarmKit() }
        // ── Alerts ──────────────────────────────────────
        .alert("잠깐만요 🙏", isPresented: $showRetentionAlert) {
            Button("그래도 탈퇴할게요", role: .destructive) { showDeleteAccountAlert = true }
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
        } message: { Text(deleteErrorMessage ?? "") }
        .alert("닉네임 변경", isPresented: $showNicknameEdit) {
            TextField("한글 5자 / 영어 8자 이내", text: $editingNickname)
            Button("저장") {
                Task {
                    await nicknameManager.setNickname(editingNickname, userId: authManager.userId)
                }
            }
            Button("취소", role: .cancel) {}
        } message: { Text("한글 5자 또는 영어·숫자 8자 이내로 입력해주세요") }
        .sheet(isPresented: $showLoginPrompt) {
            LoginPromptSheet {
                showLoginPrompt = false
                Task { await authManager.signIn() }
            } onDismiss: { showLoginPrompt = false }
        }
        #if DEBUG
        .fullScreenCover(isPresented: $showOnboardingPreview) {
            OnboardingContainerView()
        }
        .fullScreenCover(isPresented: $showSplashPreview) {
            SplashView()
                .overlay(Color.clear.contentShape(Rectangle()).onTapGesture { showSplashPreview = false })
                .ignoresSafeArea()
        }
        #endif
    }

    // MARK: - 프로필 카드

    private var profileCard: some View {
        HStack(spacing: 14) {
            // ── 이모지 아바타 (탭 → 이모지 선택) ──────
            Button { showEmojiPicker = true } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#4EC4B0"), Color(hex: "#7A9AD0"), Color(hex: "#9080CC")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    if profileEmoji.isEmpty {
                        Text(String(nicknameManager.nickname.prefix(1)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text(profileEmoji)
                            .font(.system(size: 26))
                    }
                }
                .frame(width: 52, height: 52)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.20), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)

            // ── 닉네임 + 이메일 (탭 → 닉네임 수정) ──
            Button {
                editingNickname = nicknameManager.nickname
                showNicknameEdit = true
            } label: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text("안녕하세요, \(nicknameManager.nickname)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text("👋").font(.system(size: 15))
                    }
                    if authManager.isLoggedIn {
                        Text(authManager.user?.email ?? "Apple 계정")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.50))
                    } else {
                        Text("닉네임 변경")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.50))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Image(systemName: "pencil")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.30))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.dvBgSurface)
        )
        .sheet(isPresented: $showEmojiPicker) {
            emojiPickerSheet
        }
        // 비로그인 시 로그인 버튼 추가
        .overlay(alignment: .bottomTrailing) {
            if !authManager.isLoggedIn {
                Button {
                    showLoginPrompt = true
                } label: {
                    Text("로그인")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#1A2340"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.dvAccentGold)
                        .clipShape(Capsule())
                }
                .padding(16)
            }
        }
    }

    // MARK: - 섹션 카드 빌더

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.40))
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.dvBgSurface)
            )
            .padding(.horizontal, 16)
        }
    }

    // MARK: - 외관 섹션

    @ViewBuilder
    private var appearanceRows: some View {
        // 인사말 언어
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                iconBadge("text.bubble.fill", color: Color(hex: "#5E9CF5"))
                Text("인사말 언어")
                    .font(.dvBody)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            Picker("인사말 언어", selection: $greetingLanguage) {
                Text("한국어").tag("ko")
                Text("English").tag("en")
                Text("랜덤").tag("random")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }

    }

    // MARK: - 앱 설정 섹션

    @ViewBuilder
    private var permissionRows: some View {
        permissionRow(icon: "bell.fill", iconColor: Color(hex: "#E05E5E"),
                      title: "알림", statusText: permissionManager.notificationStatusText,
                      isGranted: permissionManager.notificationAuthorized)
        rowDivider
        permissionRow(icon: "location.fill", iconColor: Color(hex: "#5E9CF5"),
                      title: "위치", statusText: permissionManager.locationStatusText,
                      isGranted: permissionManager.locationAuthorized)
        if #available(iOS 26.0, *) {
            rowDivider
            permissionRow(icon: "alarm.fill", iconColor: Color(hex: "#E0965E"),
                          title: "알람", statusText: permissionManager.alarmKitStatus,
                          isGranted: permissionManager.alarmKitAuthorized)
        }
        rowDivider
        row(icon: "waveform", iconColor: Color(hex: "#5EC49F"), title: "실시간 활동") {
            Button("설정 열기") { permissionManager.openAppSettings() }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color.dvAccentGold)
        }
    }

    // MARK: - 묵상 리마인더 섹션

    @ViewBuilder
    private var meditationReminderRows: some View {
        // 온/오프 토글
        HStack(spacing: 14) {
            iconBadge("bell.badge.fill", color: Color(hex: "#9B7FD4"))
            VStack(alignment: .leading, spacing: 2) {
                Text("묵상 알림")
                    .font(.dvBody)
                    .foregroundColor(.white)
                Text("오늘 묵상을 기록하지 않았을 때 알려드려요")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Toggle("", isOn: $meditationReminderEnabled)
                .labelsHidden()
                .tint(Color(hex: "#9B7FD4"))
                .onChange(of: meditationReminderEnabled) { newValue in
                    if newValue {
                        NotificationManager.shared.scheduleMeditationEveningReminder()
                    } else {
                        NotificationManager.shared.disableMeditationReminder()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)

        // 시간 선택 (ON일 때만 표시)
        if meditationReminderEnabled {
            rowDivider
            Button {
                showReminderTimePicker = true
            } label: {
                HStack(spacing: 14) {
                    iconBadge("clock.fill", color: Color(hex: "#6B6B9A"))
                    Text("알림 시간")
                        .font(.dvBody)
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%02d:%02d", meditationReminderHour, meditationReminderMinute))
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "#9B7FD4"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showReminderTimePicker) {
                reminderTimePickerSheet
            }
        }
    }

    private var reminderTimePickerSheet: some View {
        VStack(spacing: 0) {
            // 핸들
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text("알림 시간 설정")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 8)

            Text("묵상을 기록하지 않았을 때 이 시간에 알려드려요")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.50))
                .padding(.bottom, 24)

            // DatePicker (시간만)
            DatePicker(
                "",
                selection: Binding(
                    get: {
                        var c = DateComponents()
                        c.hour = meditationReminderHour
                        c.minute = meditationReminderMinute
                        return Calendar.current.date(from: c) ?? Date()
                    },
                    set: { newDate in
                        let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                        meditationReminderHour = c.hour ?? 21
                        meditationReminderMinute = c.minute ?? 0
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .colorScheme(.dark)
            .padding(.horizontal, 24)

            Button {
                NotificationManager.shared.scheduleMeditationEveningReminder()
                showReminderTimePicker = false
            } label: {
                Text("저장")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "#1A2340"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dvAccentGold)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - 앱 정보 섹션

    @ViewBuilder
    private var appInfoRows: some View {
        Link(destination: URL(string: "https://jydragon37.github.io/dailyverse/legal/terms.html")!) {
            row(icon: "doc.text.fill", iconColor: Color(hex: "#8B8B9A"), title: "이용약관") {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .buttonStyle(.plain)

        rowDivider

        Link(destination: URL(string: "https://jydragon37.github.io/dailyverse/legal/privacy.html")!) {
            row(icon: "lock.shield.fill", iconColor: Color(hex: "#5E9CF5"), title: "개인정보처리방침") {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .buttonStyle(.plain)

        rowDivider

        row(icon: "info.circle.fill", iconColor: Color(hex: "#6B6B7A"), title: "버전") {
            Text(appVersion)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.40))
        }

        rowDivider

        // 개역한글 성경 출처 표기 (저작권 의무 표기)
        row(icon: "book.fill", iconColor: Color(hex: "#6B6B7A"), title: "성경 본문") {
            Text("개역한글, 대한성서공회")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    // MARK: - 피드백 섹션

    @ViewBuilder
    private var feedbackRows: some View {
        Button {
            if let url = URL(string: "https://apps.apple.com/app/id6763995142") {
                UIApplication.shared.open(url)
            }
        } label: {
            row(icon: "star.fill", iconColor: Color(hex: "#E0B85E"), title: "앱 리뷰 남기기") {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .buttonStyle(.plain)

        rowDivider

        Link(destination: URL(string: "mailto:morningmanna.app@gmail.com")!) {
            row(icon: "envelope.fill", iconColor: Color(hex: "#5E9CF5"), title: "문의하기") {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.25))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 계정 관리 섹션 (최하단, 로그인 시만)

    @ViewBuilder
    private var accountRows: some View {
        Button { showSignOutAlert = true } label: {
            row(icon: "rectangle.portrait.and.arrow.right",
                iconColor: Color(hex: "#8B8B9A"), title: "로그아웃") {
                EmptyView()
            }
        }
        .buttonStyle(.plain)

        rowDivider

        Button { showRetentionAlert = true } label: {
            HStack(spacing: 14) {
                iconBadge("person.fill.xmark", color: Color(hex: "#E05E5E").opacity(0.85))
                Text("계정 탈퇴")
                    .font(.dvBody)
                    .foregroundColor(Color(red: 0.88, green: 0.37, blue: 0.37))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Debug 섹션 (DEBUG only)

    #if DEBUG
    @ViewBuilder
    private var debugRows: some View {
        Button { showSplashPreview = true } label: {
            row(icon: "sparkle", iconColor: Color.dvAccentSky, title: "스플래시 미리보기") {
                EmptyView()
            }
        }
        .buttonStyle(.plain)

        rowDivider

        Button {
            onboardingCompleted = false
            showOnboardingPreview = true
        } label: {
            row(icon: "arrow.counterclockwise", iconColor: .orange, title: "온보딩 다시 보기") {
                EmptyView()
            }
        }
        .buttonStyle(.plain)

        rowDivider

        Button { DailyCacheManager.shared.clearCache() } label: {
            row(icon: "trash.fill", iconColor: .red, title: "말씀 캐시 초기화") {
                EmptyView()
            }
        }
        .buttonStyle(.plain)

        rowDivider

        Button {
            UserDefaults.standard.set(false, forKey: "featureTourV2Shown")
        } label: {
            row(icon: "sparkles", iconColor: .blue, title: "피처 투어 다시보기") {
                EmptyView()
            }
        }
        .buttonStyle(.plain)

        rowDivider

        // 콘텐츠 DB 버전
        row(icon: "cylinder.split.1x2.fill", iconColor: Color.dvAccentGold, title: "콘텐츠 DB 버전") {
            Text(contentVersion)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
        }
        .task {
            await fetchContentVersion()
        }
    }

    @MainActor
    private func fetchContentVersion() async {
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/dailyverse-9260d/databases/(default)/documents/app_config/content_version") else { return }
        // 공개 읽기 (규칙상 허용 시) 또는 토큰 없이 접근
        // 실제로는 Firebase SDK fetchDocument 사용 권장
        // 여기서는 FirestoreService를 통해 읽어옴
        if let data = try? await FirestoreService().fetchContentVersion() {
            contentVersion = data
        }
    }
    #endif

    // MARK: - 공통 컴포넌트

    @ViewBuilder
    private func row<Trailing: View>(
        icon: String,
        iconColor: Color,
        title: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon, color: iconColor)
            Text(title)
                .font(.dvBody)
                .foregroundColor(.white)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func permissionRow(icon: String, iconColor: Color, title: String, statusText: String, isGranted: Bool) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon, color: iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.dvBody).foregroundColor(.white)
                Text(statusText).font(.system(size: 12)).foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#5EC49F"))
            } else {
                Button("설정") { permissionManager.openAppSettings() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.dvAccentGold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func iconBadge(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 30, height: 30)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.07))
            .frame(height: 0.5)
            .padding(.leading, 60)
    }

    // MARK: - 이모지 피커 시트

    // 남성 — 다양한 헤어·나이·직업 스타일
    private let emojiMale: [String] = [
        "👦", "👨", "👴", "🧔‍♂️", "👱‍♂️", "👨‍🦱",
        "👨‍🦰", "👨‍🦳", "👨‍🦲", "👨‍💼", "👨‍🎓", "👨‍⚕️",
        "👨‍🍳", "👨‍🎤", "👨‍💻", "👨‍🏫", "👨‍🌾", "🕵️‍♂️",
    ]
    // 여성 — 다양한 헤어·나이·직업·스타일
    private let emojiFemale: [String] = [
        "👧", "👩", "👵", "👱‍♀️", "🧕", "👩‍🦱",
        "👩‍🦰", "👩‍🦳", "👩‍🦲", "👩‍💼", "👩‍🎓", "👩‍⚕️",
        "👩‍🍳", "👩‍🎤", "👩‍💻", "👩‍🏫", "💃", "🤱",
    ]

    private var emojiPickerSheet: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 핸들
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                Text("이모지 선택")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                // 초기화
                Button {
                    profileEmoji = ""
                    showEmojiPicker = false
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(profileEmoji.isEmpty ? 0.25 : 0.08))
                                .frame(width: 44, height: 44)
                            Text(String(nicknameManager.nickname.prefix(1)))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("이니셜로 돌아가기")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }

                emojiSection(title: "남성", emojis: emojiMale)
                emojiSection(title: "여성", emojis: emojiFemale)

                Spacer(minLength: 24)
            }
        }
        .background(Color.dvBgDeep.ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    private func emojiSection(title: String, emojis: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.8)
                .padding(.horizontal, 24)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        profileEmoji = emoji
                        showEmojiPicker = false
                    } label: {
                        ZStack {
                            Circle()
                                .fill(profileEmoji == emoji
                                      ? Color.dvAccentGold.opacity(0.25)
                                      : Color.white.opacity(0.08))
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Circle().stroke(
                                        profileEmoji == emoji ? Color.dvAccentGold.opacity(0.6) : Color.clear,
                                        lineWidth: 1.5
                                    )
                                )
                            Text(emoji).font(.system(size: 26))
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
        .preferredColorScheme(.dark)
}
