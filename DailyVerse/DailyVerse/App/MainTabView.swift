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
            .toolbar(.hidden, for: .tabBar)   // 네이티브 탭 바 숨김
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 83)  // 커스텀 탭 바 공간 확보
            }

            // 커스텀 탭 바 오버레이
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

    private let tabs: [(Int, String, String)] = [
        (0, "Home",     "house.fill"),
        (1, "Alarm",    "alarm.fill"),
        (2, "Saved",    "bookmark.fill"),
        (3, "Gallery",  "photo.on.rectangle"),
        (4, "Settings", "gearshape.fill"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 상단 미세 구분선
            Rectangle()
                .fill(Color.white.opacity(0.10))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(tabs, id: \.0) { tag, label, icon in
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedTab = tag
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 22))
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tag ? Color.dvGold : Color.dvTextHint)
                        .animation(.easeOut(duration: 0.2), value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(label)
                }
            }
            .padding(.top, 12)
            .padding(.bottom, safeAreaBottom + 8)
        }
        .background(
            ZStack {
                Color.dvBgDeep.opacity(0.85)
                Rectangle().fill(.ultraThinMaterial)
            }
        )
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
