import SwiftUI

// MARK: - AlarmStage1View
// DEPRECATED (2026-04-26): Stage 1 제거됨. iOS 26+(AlarmKit)·Legacy 모두 Stage2 직행.
// AlarmCoordinator.AlarmStage에서 .stage1 케이스 제거됨. 이 파일은 참조용으로만 보존.

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now = Date()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── 배경 ─────────────────────────────────────
                Image("AlarmStage1BG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── 콘텐츠 ───────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()

                    // 시간 카드
                    timeCard
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 28)

                    // 말씀 카드
                    verseCard
                        .padding(.horizontal, 24)

                    Spacer()

                    // 버튼
                    buttonGroup
                        .padding(.horizontal, 24)
                        .padding(.bottom, 52)
                }
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .onReceive(ticker) { date in now = date }
    }

    // MARK: - 시간 카드

    private var timeCard: some View {
        VStack(spacing: 8) {
            // 시간 + AM/PM
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(hourMinuteString)
                    .font(.system(size: 72, weight: .thin, design: .default))
                    .foregroundColor(.black.opacity(0.82))

                Text(amPmString)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.black.opacity(0.55))
                    .padding(.bottom, 6)
            }

            // 날짜
            Text(dateString)
                .font(.system(size: 14, weight: .medium))
                .tracking(1.6)
                .foregroundColor(.black.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .light)
        )
    }

    // MARK: - 말씀 카드

    @ViewBuilder
    private var verseCard: some View {
        if let verse = coordinator.activeVerse {
            ZStack {
                // 말씀 배경 이미지 (있을 때)
                if let urlStr = coordinator.activeImage?.storageUrl,
                   let url = URL(string: urlStr) {
                    RemoteImageView(url: url) {
                        Color.black.opacity(0.55)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.50))
                }

                // 이미지 위 다크 오버레이
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.38))

                // 말씀 텍스트
                VStack(spacing: 10) {
                    Text(verse.verseShortKo)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)

                    Text(verse.reference)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.72))
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
            }
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 버튼 그룹

    private var buttonGroup: some View {
        VStack(spacing: 12) {
            // snooze
            Button { coordinator.snooze() } label: {
                Text("snooze")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.black.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .light)
                    )
            }

            // wake up
            Button { coordinator.dismissToStage2() } label: {
                Text("wake up")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black.opacity(0.80))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(.thinMaterial)
                            .environment(\.colorScheme, .light)
                    )
            }
        }
    }

    // MARK: - 포매터

    private var hourMinuteString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "hh:mm"
        return f.string(from: now)
    }

    private var amPmString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "a"
        return f.string(from: now)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: now).uppercased()
    }
}

#Preview {
    AlarmStage1View()
        .environmentObject(AlarmCoordinator())
}
