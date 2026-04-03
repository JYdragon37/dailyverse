import SwiftUI
import CoreMotion

// MARK: - WakeMissionView (Stage 1.5)

/// v5.1 — 웨이크업 미션 수행 화면
/// 미션 완료 시 Stage 2 (웰컴 스크린)으로 전환
struct WakeMissionView: View {
    let mission: String
    let nickname: String
    let verse: Verse?
    let onComplete: () -> Void
    let onSkip: () -> Void

    var body: some View {
        ZStack {
            Color.dvPrimaryDeep.ignoresSafeArea()

            VStack(spacing: 32) {
                // 상단 미션 안내
                VStack(spacing: 12) {
                    Text(missionTitle)
                        .font(.dvUITitle)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(missionDescription)
                        .font(.dvUIBody)
                        .foregroundColor(.dvTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 60)

                Spacer()

                // 미션별 UI
                missionContent

                Spacer()

                // 건너뛰기
                Button(action: onSkip) {
                    Text("건너뛰기")
                        .font(.dvCaption)
                        .foregroundColor(.dvTextMuted)
                }
                .padding(.bottom, 48)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationBarHidden(true)
    }

    // MARK: - Mission Content

    @ViewBuilder
    private var missionContent: some View {
        switch mission {
        case "shake":
            ShakeMissionContent(onComplete: onComplete)
        case "math":
            MathMissionContent(onComplete: onComplete)
        case "typing":
            TypingMissionContent(verse: verse, onComplete: onComplete)
        case "word":
            TypingMissionContent(verse: verse, onComplete: onComplete, useShortText: true)
        case "amen":
            // #1 아멘 입력 미션
            AmenMissionContent(onComplete: onComplete)
        default:
            // "none" — 즉시 완료 버튼
            Button(action: onComplete) {
                Text("말씀 보기")
                    .font(.dvUISubtitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.dvAccentGold)
                    .foregroundColor(.dvPrimaryDeep)
                    .cornerRadius(16)
                    .padding(.horizontal, 32)
            }
            .dvButtonEffect()
        }
    }

    // MARK: - Strings

    private var missionTitle: String {
        switch mission {
        case "shake":  return "폰을 흔들어 깨어나세요"
        case "math":   return "간단한 수학 문제를 풀어요"
        case "typing": return "말씀을 직접 타이핑해요"
        case "word":   return "오늘의 한마디 ✨"
        case "amen":   return "아멘으로 응답하세요"
        default:       return "준비되셨나요?"
        }
    }

    private var missionDescription: String {
        switch mission {
        case "shake":  return "3번 세게 흔들면 오늘의 말씀이 열립니다"
        case "math":   return "정답을 맞히면 오늘의 말씀을 만납니다"
        case "typing": return "손으로 직접 쓰며 말씀을 마음에 새겨요"
        case "word":   return "오늘의 한 문장을 그대로 따라 적어보세요"
        case "amen":   return "'아멘'을 입력하면 말씀 화면으로 넘어갑니다"
        default:       return "오늘의 말씀이 기다리고 있어요 🌿"
        }
    }
}

// MARK: - Shake Mission

private struct ShakeMissionContent: View {
    @StateObject private var detector = ShakeDetector()
    let onComplete: () -> Void
    private let requiredShakes = 3

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.dvAccentGold.opacity(0.3), lineWidth: 3)
                    .frame(width: 140, height: 140)
                Circle()
                    .trim(from: 0, to: CGFloat(detector.shakeCount) / CGFloat(requiredShakes))
                    .stroke(Color.dvAccentGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.3), value: detector.shakeCount)

                VStack(spacing: 4) {
                    Image(systemName: "iphone.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(.dvAccentGold)
                    Text("\(detector.shakeCount) / \(requiredShakes)")
                        .font(.dvUITitle)
                        .foregroundColor(.white)
                }
            }

            Text(detector.shakeCount >= requiredShakes ? "완료! 🎉" : "흔들기 \(requiredShakes - detector.shakeCount)번 남았어요")
                .font(.dvBody)
                .foregroundColor(detector.shakeCount >= requiredShakes ? .dvAccentGold : .dvTextSecondary)
        }
        .onChange(of: detector.shakeCount) { count in
            if count >= requiredShakes { onComplete() }
        }
        .onAppear { detector.start() }
        .onDisappear { detector.stop() }
    }
}

@MainActor
private final class ShakeDetector: ObservableObject {
    @Published var shakeCount = 0
    private let motionManager = CMMotionManager()
    private var lastShakeTime: Date = .distantPast

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            let magnitude = sqrt(
                data.acceleration.x * data.acceleration.x +
                data.acceleration.y * data.acceleration.y +
                data.acceleration.z * data.acceleration.z
            )
            if magnitude > 2.5 {
                let now = Date()
                guard now.timeIntervalSince(self?.lastShakeTime ?? .distantPast) > 0.5 else { return }
                Task { @MainActor [weak self] in
                    self?.shakeCount += 1
                    self?.lastShakeTime = now
                }
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }
}

// MARK: - Math Mission

private struct MathMissionContent: View {
    @State private var answer = ""
    @State private var isWrong = false
    @State private var problem: MathProblem = MathProblem.random()
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            // 문제
            Text(problem.question)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // 답 입력
            VStack(spacing: 8) {
                TextField("답을 입력하세요", text: $answer)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                    .padding(.horizontal, 48)

                if isWrong {
                    Text("틀렸어요, 다시 해봐요!")
                        .font(.dvCaption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }

            Button(action: checkAnswer) {
                Text("확인")
                    .font(.dvUISubtitle)
                    .frame(width: 160)
                    .padding(.vertical, 16)
                    .background(Color.dvAccentGold)
                    .foregroundColor(.dvPrimaryDeep)
                    .cornerRadius(14)
            }
            .dvButtonEffect()
        }
    }

    private func checkAnswer() {
        if let val = Int(answer), val == problem.answer {
            onComplete()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isWrong = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isWrong = false
                answer = ""
                problem = MathProblem.random()
            }
        }
    }
}

private struct MathProblem {
    let question: String
    let answer: Int

    static func random() -> MathProblem {
        let a = Int.random(in: 1...20)
        let b = Int.random(in: 1...20)
        let ops = ["+", "-", "×"]
        let op = ops.randomElement()!
        switch op {
        case "+": return MathProblem(question: "\(a) + \(b) = ?", answer: a + b)
        case "-":
            let (big, small) = (max(a, b), min(a, b))
            return MathProblem(question: "\(big) - \(small) = ?", answer: big - small)
        default:  // ×
            let (x, y) = (Int.random(in: 1...9), Int.random(in: 1...9))
            return MathProblem(question: "\(x) × \(y) = ?", answer: x * y)
        }
    }
}

// MARK: - Typing Mission (DailyVerse 전용 ✨)

private struct TypingMissionContent: View {
    let verse: Verse?
    let onComplete: () -> Void
    var useShortText: Bool = false   // true: textKo(한 문장), false: textKo(동일)
    @State private var typedText = ""
    @FocusState private var isFocused: Bool

    private var targetText: String {
        // useShortText: 오늘의 한마디 미션 — 짧은 핵심 문장
        // 기본 typing 미션과 동일하게 textKo 사용
        verse?.textKo ?? "두려워하지 말라 내가 너와 함께 함이라"
    }

    private var progress: Double {
        guard !targetText.isEmpty else { return 0 }
        let correct = zip(typedText, targetText).filter { $0 == $1 }.count
        return Double(correct) / Double(targetText.count)
    }

    private var isComplete: Bool {
        typedText.trimmingCharacters(in: .whitespacesAndNewlines) == targetText
    }

    var body: some View {
        VStack(spacing: 20) {
            // 목표 텍스트
            Text(targetText)
                .font(.dvVerseText)
                .foregroundColor(.dvAccentSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(6)

            // 진행도
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.dvAccentGold)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut, value: progress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 32)

            // 입력 필드
            TextField("위 말씀을 타이핑하세요", text: $typedText, axis: .vertical)
                .font(.dvBody)
                .foregroundColor(.white)
                .padding(14)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 32)
                .focused($isFocused)
                .onChange(of: typedText) { _ in
                    if isComplete { onComplete() }
                }
        }
        .onAppear { isFocused = true }
    }
}

// MARK: - Amen Mission

private struct AmenMissionContent: View {
    let onComplete: () -> Void
    @State private var amenInput = ""
    @State private var isWrong = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("🙏")
                .font(.system(size: 64))

            VStack(spacing: 8) {
                TextField("아멘", text: $amenInput)
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(isWrong ? 0.08 : 0.12))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isWrong ? Color.red.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
                    .padding(.horizontal, 48)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { checkAmen() }

                if isWrong {
                    Text("다시 입력해주세요")
                        .font(.dvCaption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }

            Button(action: checkAmen) {
                Text("확인")
                    .font(.dvUISubtitle)
                    .frame(width: 140)
                    .padding(.vertical, 16)
                    .background(Color.dvAccentGold)
                    .foregroundColor(.dvPrimaryDeep)
                    .cornerRadius(14)
            }
            .dvButtonEffect()
        }
        .onAppear { isFocused = true }
    }

    private func checkAmen() {
        if amenInput.trimmingCharacters(in: .whitespacesAndNewlines) == "아멘" {
            onComplete()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isWrong = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isWrong = false; amenInput = ""
            }
        }
    }
}

// MARK: - Preview

#Preview {
    WakeMissionView(
        mission: "typing",
        nickname: "규",
        verse: .fallbackMorning,
        onComplete: {},
        onSkip: {}
    )
}
