import SwiftUI

// MARK: - WordChallengeView
// #5/6 오늘의 한마디: 유저가 오늘의 한 문장(textKo)을 그대로 타이핑하면 Gallery에 저장

struct WordChallengeView: View {
    let verse: Verse
    let imageId: String?
    let weather: WeatherData?
    let mode: AppMode
    let authManager: AuthManager
    let onDismiss: () -> Void

    @State private var typedText = ""
    @State private var isSaved = false
    @State private var showError = false
    @FocusState private var isFocused: Bool

    private var targetText: String { verse.textKo }

    private var progress: Double {
        guard !targetText.isEmpty else { return 0 }
        let correct = zip(typedText, targetText).filter { $0 == $1 }.count
        return min(Double(correct) / Double(targetText.count), 1.0)
    }

    private var isComplete: Bool {
        typedText.trimmingCharacters(in: .whitespacesAndNewlines) == targetText
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dvPrimaryDeep.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    // 안내
                    VStack(spacing: 12) {
                        Text("✨ 오늘의 한마디")
                            .font(.dvUITitle).foregroundColor(.dvAccentGold)

                        Text("아래 문장을 그대로 따라 적어보세요")
                            .font(.dvUIBody).foregroundColor(.dvTextSecondary)
                    }

                    // 목표 문장
                    Text(targetText)
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(6)
                        .padding(16)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(14)
                        .padding(.horizontal, 24)

                    // 진행 바
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isComplete ? Color.green : Color.dvAccentGold)
                                .frame(width: geo.size.width * progress)
                                .animation(.easeOut, value: progress)
                        }
                    }
                    .frame(height: 6)
                    .padding(.horizontal, 32)

                    // 입력 필드
                    if !isSaved {
                        TextField("여기에 입력하세요", text: $typedText, axis: .vertical)
                            .font(.dvBody).foregroundColor(.white)
                            .padding(14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                            .focused($isFocused)
                            .onChange(of: typedText) { _ in
                                if isComplete { saveToGallery() }
                            }
                    }

                    // 저장 완료 메시지
                    if isSaved {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("Gallery에 저장됐어요!")
                                .font(.dvUITitle).foregroundColor(.white)
                            Text("말씀을 마음에 새겼어요 🌿")
                                .font(.dvBody).foregroundColor(.dvTextSecondary)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    if showError {
                        Text("로그인 후 사용할 수 있어요")
                            .font(.dvCaption).foregroundColor(.red.opacity(0.8))
                    }

                    Spacer()

                    // 닫기 버튼
                    Button(isSaved ? "완료" : "나중에") { onDismiss() }
                        .font(.dvCaption).foregroundColor(.dvTextMuted)
                        .padding(.bottom, 32)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear { isFocused = true }
    }

    // MARK: - Gallery 저장

    private func saveToGallery() {
        guard isComplete else { return }
        guard authManager.isLoggedIn, let userId = authManager.userId else {
            showError = true
            return
        }

        let entry = DailyWordEntry(
            id: UUID().uuidString,
            verseId: verse.id,
            textKo: verse.textKo,
            reference: verse.reference,
            imageId: imageId,
            savedAt: Date(),
            mode: mode.rawValue,
            weatherTemp: weather?.temperature ?? 0,
            weatherCondition: weather?.condition ?? "any",
            locationName: weather?.cityName ?? ""
        )

        Task {
            do {
                try await FirestoreService().saveDailyWord(entry, userId: userId)
                withAnimation(.spring()) { isSaved = true }
            } catch {
                #if DEBUG
                print("⚠️ [WordChallenge] 저장 실패: \(error)")
                #endif
            }
        }
    }
}

// MARK: - DailyWordEntry 모델

struct DailyWordEntry: Identifiable, Codable {
    let id: String
    let verseId: String
    let textKo: String
    let reference: String
    let imageId: String?
    let savedAt: Date
    let mode: String
    let weatherTemp: Int
    let weatherCondition: String
    let locationName: String

    enum CodingKeys: String, CodingKey {
        case id, reference, mode
        case verseId        = "verse_id"
        case textKo         = "text_ko"
        case imageId        = "image_id"
        case savedAt        = "saved_at"
        case weatherTemp    = "weather_temp"
        case weatherCondition = "weather_condition"
        case locationName   = "location_name"
    }
}
