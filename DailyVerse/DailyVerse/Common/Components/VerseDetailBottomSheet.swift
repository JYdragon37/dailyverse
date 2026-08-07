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
    let onMeditation: () -> Void
    let onClose: () -> Void
    var showMeditationButton: Bool = true   // 알람 팝업 컨텍스트에서는 false
    /// 저장 여부 — 부모(HomeView/AlarmStage2)가 viewModel.isSavedCurrentVerse로 제어
    /// isSaved 로컬 상태 제거: 로그인 여부와 무관하게 저장됨 표시되던 버그 수정
    @Binding var isSaved: Bool

    @ObservedObject private var nicknameManager = NicknameManager.shared
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @AppStorage("appLanguage") private var appLang: String = "ko"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // 상단 여백 — 텍스트가 팝업 중앙에 자연스럽게 위치
                    Spacer(minLength: 12)

                    // 1. 해석
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appLanguageString("verseDetail.interpretation.label"), systemImage: "text.magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.dvAccentGold)

                        Text(verse.interpretationText(lang: appLang))
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }

                    Divider().padding(.vertical, 4)

                    // 2. 일상 적용 (닉네임 포함)
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appLanguageString("verseDetail.application.label"), systemImage: "sparkles")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.dvAccentSky)

                        Text(applicationWithNickname)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }

                    // 4. 광고 슬롯 (Free 유저만)
                    if !subscriptionManager.isPremium {
                        BannerAdView()
                            .frame(width: 300, height: 250)
                            .clipped()
                            .padding(.top, 8)
                    }

                    // actionBar 높이 + safeArea 충분히 확보 (minHeight ~140pt)
                    Spacer(minLength: 160)
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
        .modifier(SheetDarkBackgroundModifier())
    }

    private var applicationWithNickname: String {
        "\(nicknameManager.nickname), \(verse.applicationText(lang: appLang))"
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            // 저장 버튼
            Button {
                onSave()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: isSaved ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .scaleEffect(isSaved ? 1.3 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isSaved)
                    Text(isSaved ? appLanguageString("verseDetail.save.saved") : appLanguageString("verseDetail.save.button"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: isSaved
                            ? [Color.green.opacity(0.7), Color.green.opacity(0.5)]
                            : [Color.dvGold, Color.dvGold.opacity(0.8)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .animation(.easeInOut(duration: 0.3), value: isSaved)
            }
            .accessibilityLabel(appLanguageString("verseDetail.save.accessibility"))

            // 묵상 버튼 (알람 팝업 컨텍스트에서는 숨김)
            if showMeditationButton { Button(action: onMeditation) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.and.scribble")
                        .font(.system(size: 14))
                    Text(appLanguageString("verseDetail.meditation.button"))
                        .font(.system(size: 15, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .accessibilityLabel(appLanguageString("verseDetail.meditation.accessibility"))
            }   // end if showMeditationButton

            // 닫기 버튼
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
            .accessibilityLabel(appLanguageString("verseDetail.close.accessibility"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.dvBgDeep.opacity(0.85)
                .overlay(Rectangle().fill(.ultraThinMaterial))
        )
    }
}

// BannerAdView → Common/Components/BannerAdView.swift 참조

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
                onMeditation: {},
                onClose: {},
                isSaved: .constant(false)
            )
        }
}

// MARK: - Sheet 어두운 배경 (iOS 버전 분기)

private struct SheetDarkBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            // regularMaterial: 뒤 배경이 은은하게 비치는 블러 재질
            // preferredColorScheme(.dark): 라이트모드 기기/시뮬레이터에서도 어둡게
            content
                .presentationBackground(Color.black.opacity(0.7))
                .preferredColorScheme(.dark)
        } else {
            content
                .background(Color.dvBgDeep)
                .preferredColorScheme(.dark)
        }
    }
}
