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
                    Text(appLanguageString("wakeMission.skip"))
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
                Text(appLanguageString("wakeMission.viewVerse"))
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
        case "shake":  return appLanguageString("wakeMission.title.shake")
        case "math":   return appLanguageString("wakeMission.title.math")
        case "typing": return appLanguageString("wakeMission.title.typing")
        case "word":   return appLanguageString("wakeMission.title.word")
        case "amen":   return appLanguageString("wakeMission.title.amen")
        default:       return appLanguageString("wakeMission.title.none")
        }
    }

    private var missionDescription: String {
        switch mission {
        case "shake":  return appLanguageString("wakeMission.desc.shake")
        case "math":   return appLanguageString("wakeMission.desc.math")
        case "typing": return appLanguageString("wakeMission.desc.typing")
        case "word":   return appLanguageString("wakeMission.desc.word")
        case "amen":   return appLanguageString("wakeMission.desc.amen")
        default:       return appLanguageString("wakeMission.desc.none")
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

            Text(detector.shakeCount >= requiredShakes
                 ? appLanguageString("wakeMission.shake.done")
                 : appLanguageString("wakeMission.shake.remaining", args: requiredShakes - detector.shakeCount))
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
                TextField(appLanguageString("wakeMission.math.placeholder"), text: $answer)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(12)
                    .padding(.horizontal, 48)

                if isWrong {
                    Text(appLanguageString("wakeMission.math.wrong"))
                        .font(.dvCaption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }

            Button(action: checkAnswer) {
                Text(appLanguageString("common.confirm"))
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
    var useShortText: Bool = false   // true: verseShortKo(한 문장), false: verseShortKo(동일)
    @State private var typedText = ""
    @FocusState private var isFocused: Bool

    private var targetText: String {
        // useShortText: 오늘의 한마디 미션 — 짧은 핵심 문장
        // 기본 typing 미션과 동일하게 verseShortKo 사용
        verse?.verseShort(lang: UserDefaults.standard.string(forKey: "appLanguage") ?? "ko")
            ?? appLanguageString("wakeMission.typing.fallbackVerse")
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
            TextField(appLanguageString("wakeMission.typing.placeholder"), text: $typedText, axis: .vertical)
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
                TextField(appLanguageString("wakeMission.amen.placeholder"), text: $amenInput)
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
                    Text(appLanguageString("wakeMission.amen.wrong"))
                        .font(.dvCaption)
                        .foregroundColor(.red.opacity(0.8))
                }
            }

            Button(action: checkAmen) {
                Text(appLanguageString("common.confirm"))
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
        let expected = appLanguageString("wakeMission.amen.placeholder")
        let trimmed = amenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare(expected) == .orderedSame || trimmed == "아멘" {
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
