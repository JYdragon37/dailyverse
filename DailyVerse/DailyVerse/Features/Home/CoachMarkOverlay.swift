import SwiftUI
import Combine

enum CoachMarkStep {
    case verseCard
    case alarmTab
}

struct CoachMarkOverlay: View {
    @AppStorage("coachMarkShown") private var coachMarkShown = false

    @State private var currentStep: CoachMarkStep = .verseCard
    @State private var isVisible: Bool = true
    @State private var stepOpacity: Double = 1.0

    // 말씀 카드 영역 좌표 (GeometryReader로 부모가 주입)
    var verseCardFrame: CGRect = .zero

    var body: some View {
        if !coachMarkShown && isVisible {
            ZStack {
                // 반투명 어두운 배경
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .onTapGesture {
                        advanceStep()
                    }

                // 단계별 가이드 콘텐츠
                VStack {
                    Spacer()

                    switch currentStep {
                    case .verseCard:
                        verseCardGuide
                    case .alarmTab:
                        alarmTabGuide
                    }

                    Spacer()
                }
                .opacity(stepOpacity)
            }
            .onAppear {
                scheduleAutoAdvance()
            }
        }
    }

    // MARK: - Step 1: 말씀 카드 가이드

    private var verseCardGuide: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 44))
                .foregroundColor(.white)

            Text("말씀 카드를 탭해보세요")
                .font(.dvTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("전체 말씀과 해석을 확인할 수 있어요")
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: advanceStep) {
                Text("다음")
                    .font(.dvBody)
                    .foregroundColor(.dvAccent)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule().stroke(Color.dvAccent, lineWidth: 1)
                    )
            }
            .padding(.top, 8)
            .accessibilityLabel("코치마크 다음 단계")
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Step 2: 알람 탭 가이드

    private var alarmTabGuide: some View {
        VStack(spacing: 16) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 44))
                .foregroundColor(.dvAccent)

            Text("알람을 설정하면 매일 말씀을 받아요")
                .font(.dvTitle)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("원하는 시간에 성경 말씀과 함께 하루를 시작해보세요")
                .font(.dvBody)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: dismiss) {
                Text("시작하기")
                    .font(.dvBody)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            .accessibilityLabel("코치마크 완료")
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Actions

    private func advanceStep() {
        switch currentStep {
        case .verseCard:
            transition(to: .alarmTab)
        case .alarmTab:
            dismiss()
        }
    }

    private func transition(to step: CoachMarkStep) {
        withAnimation(.easeOut(duration: 0.25)) {
            stepOpacity = 0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            currentStep = step
            withAnimation(.easeIn(duration: 0.25)) {
                stepOpacity = 1
            }
            scheduleAutoAdvance()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        coachMarkShown = true
    }

    private func scheduleAutoAdvance() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !coachMarkShown, isVisible else { return }
            advanceStep()
        }
    }
}

#Preview {
    ZStack {
        // 배경 시뮬레이션
        LinearGradient(
            colors: [Color(red: 0.1, green: 0.15, blue: 0.3), Color.black],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()

        CoachMarkOverlay()
    }
}
