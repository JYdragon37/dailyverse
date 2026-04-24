import SwiftUI

// MARK: - AlarmStage1View
// 알람 발동 시 첫 화면
// 배경: 브랜드 네온 크로스 이미지 (AlarmStage1BG)
// 구성: 시간(굵게, AM/PM 작게) + 요일·날짜(크게) + SNOOZE / WAKE UP CTA(다크)
// Wake Up → Stage 2 (말씀 화면)

struct AlarmStage1View: View {
    @EnvironmentObject private var coordinator: AlarmCoordinator

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now = Date()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── 배경 이미지 (가운데 수직선 정중앙 정렬) ─────────
                // scaledToFill + 명시적 frame + clipped → 크롭 기준점 중앙 고정
                Image("AlarmStage1BG")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                // ── 콘텐츠 ───────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()

                    // 시간 + 날짜 블록
                    VStack(spacing: 16) {
                        // 시간 (굵게 + AM/PM 작게)
                        HStack(alignment: .top, spacing: 6) {
                            Text(hourMinuteString)
                                .font(.system(size: 76, weight: .medium))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 4)

                            Text(amPmString)
                                .font(.system(size: 22, weight: .regular))
                                .foregroundColor(.white.opacity(0.80))
                                .padding(.top, 14)   // 숫자 상단에 맞춤
                                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 2)
                        }

                        // 요일 + 날짜 (더 크게)
                        Text(dateString)
                            .font(.system(size: 22, weight: .regular))
                            .tracking(1.8)
                            .foregroundColor(.white.opacity(0.90))
                            .shadow(color: .black.opacity(0.30), radius: 8, x: 0, y: 2)
                    }

                    Spacer()

                    // ── CTA 버튼 ─────────────────────────────────
                    VStack(spacing: 14) {
                        // SNOOZE
                        Button { coordinator.snooze() } label: {
                            Text("SNOOZE")
                                .font(.system(size: 16, weight: .medium))
                                .tracking(2.0)
                                .foregroundColor(.white.opacity(0.80))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.48))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                                )
                        }

                        // WAKE UP → Stage 2
                        Button { coordinator.dismissToStage2() } label: {
                            Text("WAKE UP")
                                .font(.system(size: 16, weight: .semibold))
                                .tracking(2.0)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.60))
                                        .overlay(Capsule().stroke(Color.white.opacity(0.30), lineWidth: 0.8))
                                )
                        }
                    }
                    .padding(.horizontal, 36)
                    .padding(.bottom, 52)
                }
            }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
        .onReceive(ticker) { date in now = date }
    }

    // MARK: - 포매터

    /// "07:00"
    private var hourMinuteString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "hh:mm"
        return f.string(from: now)
    }

    /// "AM" / "PM"
    private var amPmString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "a"
        return f.string(from: now)
    }

    /// "MONDAY, OCTOBER 26"
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
