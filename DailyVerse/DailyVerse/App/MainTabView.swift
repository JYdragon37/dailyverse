import SwiftUI

// v5.4 — safeAreaInset 방식 커스텀 탭바
// safeAreaInset(edge: .bottom)으로 DVTabBar를 safe area 경계에 배치
// → DVTabBar 배경이 home indicator 영역까지 확장 (ignoresSafeArea)
// → 수동 safeAreaBottom 계산 불필요, 위치 항상 정확

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var upsellManager: UpsellManager
    @EnvironmentObject private var permissionManager: PermissionManager

    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(viewModel: HomeViewModel(
                    authManager: authManager,
                    subscriptionManager: subscriptionManager,
                    upsellManager: upsellManager,
                    permissionManager: permissionManager
                ))
                .tag(0)

                AlarmListView()
                    .tag(1)

                SavedView()
                    .tag(2)

                GalleryView()
                    .tag(3)

                SettingsView()
                    .tag(4)
            }

            // Calm 스타일 그라데이션 — 콘텐츠 하단이 탭바로 자연스럽게 페이드
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.40), Color.black.opacity(0.80)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                .allowsHitTesting(false)
            }
        }
        // DVTabBar를 safe area 하단 경계에 배치 (home indicator 위)
        .safeAreaInset(edge: .bottom, spacing: 0) {
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

// MARK: - DVTabBar

private struct DVTabBar: View {
    @Binding var selectedTab: Int

    private let tabs: [(Int, String, String)] = [
        (0, "홈",     "house.fill"),
        (1, "알람",   "alarm.fill"),
        (2, "말씀들", "bookmark.fill"),
        (3, "갤러리", "photo.on.rectangle"),
        (4, "프로필", "person.circle"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 상단 미세 구분선
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(tabs, id: \.0) { tag, label, icon in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tag
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: selectedTab == tag ? .semibold : .light))
                                .scaleEffect(selectedTab == tag ? 1.1 : 1.0)
                                .frame(height: 26)
                            Text(label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tag ? Color.dvGold : Color.white.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .contentShape(Rectangle())
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    .accessibilityLabel(label)
                }
            }
            .padding(.horizontal, 20)
        }
        // 배경: dvBgDeep 색상이 home indicator 영역까지 확장
        .background(
            Color(red: 9/255, green: 13/255, blue: 24/255).opacity(0.92)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
        .environmentObject(SubscriptionManager())
        .environmentObject(PermissionManager())
        .environmentObject(UpsellManager())
}
