import SwiftUI
import AVFoundation

// MARK: - AlarmSound 모델

struct AlarmSound: Identifiable, Equatable {
    let id: String          // "s01" ~ "s06"
    let name: String        // 한국어 표시명
    let nameEn: String      // 영어 표시명
    let filename: String    // 번들 파일명 (확장자 제외)
    let category: AlarmSoundCategory

    var displayName: String {
        UserDefaults.standard.string(forKey: "appLanguage") == "en" ? nameEn : name
    }
}

enum AlarmSoundCategory: String, CaseIterable {
    case instrumental = "연주"
    case ccm          = "CCM"
    case nature       = "자연"

    var displayName: String {
        switch self {
        case .instrumental: return appLanguageString("soundPicker.category.instrumental")
        case .ccm:           return appLanguageString("soundPicker.category.ccm")
        case .nature:        return appLanguageString("soundPicker.category.nature")
        }
    }
}

extension AlarmSound {
    static let all: [AlarmSound] = [
        // 연주
        .init(id: "s01", name: "새벽이슬",           nameEn: "Morning Dew",         filename: "01_새벽이슬_Morning_Dew_30sec",                      category: .instrumental),
        .init(id: "s02", name: "기쁨의 행진",         nameEn: "Joyful March",        filename: "02_기쁨의_행진_Joyful_March_30sec",                  category: .instrumental),
        // CCM
        .init(id: "s03", name: "아침 은혜",           nameEn: "Grace Awake",         filename: "03_아침_은혜_Grace_Awake_30sec",                     category: .ccm),
        .init(id: "s04", name: "일어나라 빛을 발하라", nameEn: "Arise and Shine",     filename: "04_일어나라_빛을_발하라_Arise_and_Shine_30sec",       category: .ccm),
        // 자연
        .init(id: "s05", name: "샬롬의 아침",         nameEn: "Shalom Morning",      filename: "05_샬롬의_아침_Shalom_Morning_30sec",                category: .nature),
        .init(id: "s06", name: "은혜의 빛",           nameEn: "Light of Grace",      filename: "06_은혜의_빛_Light_of_Grace_30sec",                  category: .nature),
    ]

    static func sound(for id: String) -> AlarmSound {
        all.first(where: { $0.id == id }) ?? all[0]
    }

    static func sounds(for category: AlarmSoundCategory) -> [AlarmSound] {
        all.filter { $0.category == category }
    }
}

// MARK: - SoundPickerSheet

struct SoundPickerSheet: View {
    @Binding var selectedSoundId: String
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: AlarmSoundCategory = .instrumental
    @State private var playingSoundId: String? = nil

    var body: some View {
        VStack(spacing: 0) {

            // ── 드래그 인디케이터 ──
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 16)

            // ── 헤더 ──
            Text(appLanguageString("soundPicker.title"))
                .font(.dvTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

            // ── 카테고리 탭 ──
            categoryTabBar
                .padding(.horizontal, 24)
                .padding(.bottom, 8)

            Divider().padding(.horizontal, 24)

            // ── 소리 목록 ──
            soundList
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden) // 직접 그린 인디케이터 사용
        .onDisappear {
            SoundPreviewPlayer.shared.stop()
            playingSoundId = nil
        }
    }

    // MARK: - Category Tab Bar

    private var categoryTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AlarmSoundCategory.allCases, id: \.self) { category in
                let isSelected = selectedCategory == category
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = category
                    }
                    SoundPreviewPlayer.shared.stop()
                    playingSoundId = nil
                } label: {
                    Text(category.displayName)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .dvAccentGold : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if isSelected {
                                Rectangle()
                                    .fill(Color.dvAccentGold)
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "tab", in: tabNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    @Namespace private var tabNamespace

    // MARK: - Sound List

    private var soundList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(AlarmSound.sounds(for: selectedCategory)) { sound in
                    SoundRow(
                        sound: sound,
                        isSelected: selectedSoundId == sound.id,
                        isPlaying: playingSoundId == sound.id
                    ) {
                        handleTap(sound)
                    }

                    if sound != AlarmSound.sounds(for: selectedCategory).last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Tap Logic
    // 탭 → 재생 (끝까지). 다른 소리 탭하면 즉시 교체.
    // 시트를 닫을 때 마지막으로 탭한 소리가 selectedSoundId로 저장됨.

    private func handleTap(_ sound: AlarmSound) {
        // 같은 소리를 다시 탭하면 재생 재시작
        SoundPreviewPlayer.shared.stop()
        selectedSoundId = sound.id
        playingSoundId = sound.id

        SoundPreviewPlayer.shared.play(soundId: sound.id) {
            DispatchQueue.main.async { playingSoundId = nil }
        }
    }
}

// MARK: - SoundRow

private struct SoundRow: View {
    let sound: AlarmSound
    let isSelected: Bool
    let isPlaying: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 재생 중 웨이브 / 기본 아이콘
                ZStack {
                    if isPlaying {
                        WaveformIcon()
                    } else {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(isSelected ? .dvAccentGold : .secondary.opacity(0.4))
                    }
                }
                .frame(width: 28, height: 28)

                Text(sound.displayName)
                    .font(.dvBody)
                    .foregroundColor(isSelected ? .primary : .secondary.opacity(0.85))

                Spacer()

                if isSelected && !isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.dvAccentGold.opacity(0.6))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - WaveformIcon (재생 중 애니메이션)

private struct WaveformIcon: View {
    @State private var animating = false

    private let heights: [CGFloat] = [6, 10, 14, 10, 6]
    private let delays: [Double]   = [0, 0.1, 0.2, 0.1, 0]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.dvAccentGold)
                    .frame(width: 3, height: animating ? heights[i] : 4)
                    .animation(
                        .easeInOut(duration: 0.45)
                        .repeatForever(autoreverses: true)
                        .delay(delays[i]),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Preview

#Preview {
    Color.black.ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            SoundPickerSheet(selectedSoundId: .constant("s01"))
        }
}
