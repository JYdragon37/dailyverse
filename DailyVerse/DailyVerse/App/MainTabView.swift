import SwiftUI

// v5.1 — 5탭: Home / Alarm / Saved / Gallery / Settings

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @EnvironmentObject private var permissionManager: PermissionManager

    @State private var selectedTab = 0

    var body: some View {
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

            // v5.1 신규 — Gallery 탭
            GalleryView()
                .tabItem { Label("Gallery", systemImage: "photo.on.rectangle") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
        .onReceive(NotificationCenter.default.publisher(for: .dvSwitchToAlarmTab)) { _ in
            selectedTab = 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .dvSwitchToHomeTab)) { _ in
            selectedTab = 0
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
        .environmentObject(UpsellManager())
}
