import SwiftUI

// v5.2 — 5탭: Home / Alarm / Saved / Gallery / Settings
// Task 4: Calm 스타일 커스텀 탭 바 (네이티브 탭 바 숨기고 오버레이)

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @EnvironmentObject private var permissionManager: PermissionManager

    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: HomeViewModel(
                    authManager: authManager,
                    subscriptionManager: subscriptionManager,
                    upsellManager: upsellManager,
                    permissionManager: permissionManager
                ))
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

                AlarmListView()
                    .tabItem { Label("Alarm", systemImage: "alarm.fill") }
                    .tag(1)

                SavedView()
                    .tabItem { Label("Saved", systemImage: "bookmark.fill") }
                    .tag(2)

                GalleryView()
                    .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
                    .tag(3)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            // #2 Fix: safeAreaInset을 실제 탭바 높이(~84pt)에 맞게 조정
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 84)
            }

            // 하단 그라데이션 페이드 (Calm 스타일)
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.68)],
                startPoint: .init(x: 0.5, y: 0.0),
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)

            // 커스텀 탭 바 (배경 없음 — 그라데이션 위에 아이콘만 표시)
            DVTabBar(selectedTab: $selectedTab)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dvSwitchToAlarmTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .dvSwitchToHomeTab)) { _ in
            selectedTab = 0
        }
    }
}

// MARK: - DVTabBar (Calm 스타일)

private struct DVTabBar: View {
    @Binding var selectedTab: Int

    // #4 레이블 한국어 변경
    private let tabs: [(Int, String, String)] = [
        (0, "홈",     "house.fill"),
        (1, "알람",   "alarm.fill"),
        (2, "말씀들", "bookmark.fill"),
        (3, "갤러리", "photo.on.rectangle"),
        (4, "프로필", "person.circle"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Calm 스타일 상단 미세 구분선
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(tabs, id: \.0) { tag, label, icon in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tag
                        }
                    } label: {
                        VStack(spacing: 4) {
                            // #3 아이콘 24pt (Calm 레퍼런스 기준)
                            Image(systemName: icon)
                                .font(.system(size: 24, weight: selectedTab == tag ? .semibold : .light))
                                .scaleEffect(selectedTab == tag ? 1.08 : 1.0)
                                .frame(height: 28)  // 고정 높이로 정렬 보장
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tag ? Color.dvGold : Color.white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .padding(.bottom, safeAreaBottom > 0 ? safeAreaBottom + 2 : 20)
                        .contentShape(Rectangle())
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    .accessibilityLabel(label)
                }
            }
        }
        .background(Color.clear)
    }

    private var safeAreaBottom: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
        .environmentObject(UpsellManager())
}
