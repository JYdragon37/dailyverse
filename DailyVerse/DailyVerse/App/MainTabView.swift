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
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }

            // 하단 그라데이션 페이드 (Calm 스타일 — 탭바 배경 역할)
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.72)],
                startPoint: .init(x: 0.5, y: 0.0),
                endPoint: .bottom
            )
            .frame(height: 110)
            .allowsHitTesting(false)   // 탭 등 터치 이벤트 통과

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

    private let tabs: [(Int, String, String)] = [
        (0, "Home",     "house.fill"),
        (1, "Alarm",    "alarm.fill"),
        (2, "Saved",    "bookmark.fill"),
        (3, "Gallery",  "photo.on.rectangle"),
        (4, "Settings", "gearshape.fill"),
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { tag, label, icon in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tag
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: icon)
                            .font(.system(size: 21, weight: selectedTab == tag ? .semibold : .light))
                            .scaleEffect(selectedTab == tag ? 1.10 : 1.0)
                        Text(label)
                            .font(.system(size: 9.5, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tag ? Color.dvGold : Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, safeAreaBottom > 0 ? safeAreaBottom : 18)
                    .contentShape(Rectangle())
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                .accessibilityLabel(label)
            }
        }
        .background(Color.clear)  // 배경 완전 투명 — 그라데이션이 배경 역할
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
