import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: HomeViewModel(
                authManager: authManager,
                subscriptionManager: subscriptionManager,
                upsellManager: upsellManager
            ))
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            AlarmListView()
                .tabItem {
                    Label("Alarm", systemImage: "alarm.fill")
                }
                .tag(1)

            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
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
