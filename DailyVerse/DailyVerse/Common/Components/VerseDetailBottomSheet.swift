import SwiftUI
import GoogleMobileAds

// MARK: - 커스텀 Detent: 홈화면 날씨 위젯 아래까지 (화면의 약 78%)

struct VerseSheetDetent: CustomPresentationDetent {
    static func height(in context: Context) -> CGFloat? {
        context.maxDetentValue * 0.78
    }
}

// MARK: - VerseDetailBottomSheet

struct VerseDetailBottomSheet: View {
    let verse: Verse
    let onSave: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void

    @ObservedObject private var nicknameManager = NicknameManager.shared
    @State private var justSaved = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // 상단 여백 — 텍스트가 팝업 중앙에 자연스럽게 위치
                    Spacer(minLength: 12)

                    // 1. 일상 적용 (닉네임 포함)
                    VStack(alignment: .leading, spacing: 6) {
                        Label("오늘의 적용", systemImage: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(applicationWithNickname)
                            .font(.system(size: 19, weight: .regular))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }

                    Divider().padding(.vertical, 2)

                    // 3. 해석
                    VStack(alignment: .leading, spacing: 6) {
                        Label("해석", systemImage: "text.magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)

                        Text(verse.interpretation)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                    }

                    // 4. 광고 슬롯 (Medium Rectangle 300×250)
                    VerseBannerAdView()
                        .padding(.top, 8)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
            .safeAreaInset(edge: .bottom) { actionBar }
        }
        // 홈화면 날씨 위젯 아래부터 시작하는 커스텀 높이
        .presentationDetents([.custom(VerseSheetDetent.self)])
        .presentationDragIndicator(.visible)
        .modifier(PresentationCornerRadiusModifier(radius: 24))
    }

    private var applicationWithNickname: String {
        "\(nicknameManager.nickname), \(verse.application)"
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                guard !justSaved else { return }
                justSaved = true
                onSave()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(1.5))
                    justSaved = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .scaleEffect(justSaved ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: justSaved)
                    Text(justSaved ? "저장됨 ✓" : "저장")
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: justSaved
                            ? [Color.green.opacity(0.7), Color.green.opacity(0.5)]
                            : [Color.dvGold, Color.dvGold.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .animation(.easeInOut(duration: 0.3), value: justSaved)
            }
            .accessibilityLabel("말씀 저장하기")

            Button(action: onNext) {
                Text("다음 말씀")
                    .font(.system(size: 15, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.18), lineWidth: 1))
                    )
                    .foregroundColor(.white)
            }
            .accessibilityLabel("다음 말씀 보기")

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
                    )
                    .foregroundColor(.white.opacity(0.7))
            }
            .accessibilityLabel("닫기")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.dvBgDeep.opacity(0.85)
                .overlay(Rectangle().fill(.ultraThinMaterial))
        )
    }
}

// MARK: - AdMob 배너 광고 (Medium Rectangle 300×250)

private struct VerseBannerAdView: UIViewRepresentable {

    // TODO: 프로덕션 배포 전 실제 Ad Unit ID로 교체
    // 현재: AdMob 테스트 ID (실제 광고 미게재)
    // 실제 ID 예시: "ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX"
    private let adUnitID = "ca-app-pub-3940256099942544/2934735716"  // 테스트 ID

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeMediumRectangle)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.rootViewController
        banner.load(GADRequest())
        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}

    // 300×250 고정 크기
    static func dismantleUIView(_ uiView: GADBannerView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}

// MARK: - iOS 버전 호환 Corner Radius Modifier

private struct PresentationCornerRadiusModifier: ViewModifier {
    let radius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCornerRadius(radius)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            VerseDetailBottomSheet(
                verse: .fallbackRiseIgnite,
                onSave: {},
                onNext: {},
                onClose: {}
            )
        }
}
