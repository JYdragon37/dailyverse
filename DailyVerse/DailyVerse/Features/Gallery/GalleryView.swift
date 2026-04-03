import SwiftUI

// v5.1 — Gallery 탭 (신규)
// - 전체 배경 이미지 탐색 (Firestore images 컬렉션)
// - 모드별 필터 탭: 전체 / 아침 / 낮 / 저녁 / 새벽
// - 이미지 핀 기능 → 홈 배경 우선 적용
// - is_sacred_safe: false 이미지는 흐림 처리, 홈 핀 불가

struct GalleryView: View {
    @StateObject private var viewModel = GalleryViewModel()
    @EnvironmentObject private var authManager: AuthManager
    @State private var selectedImage: VerseImage?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 모드 필터 탭
                modeFilterBar
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // 이미지 그리드
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredImages.isEmpty {
                    emptyView
                } else {
                    imageGrid
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await viewModel.loadImages() }
        .sheet(item: $selectedImage) { image in
            GalleryImageDetailSheet(
                image: image,
                pinnedImages: viewModel.pinnedImages,
                onPin: { mode in
                    Task { await viewModel.pinImage(image, forMode: mode, userId: authManager.userId) }
                },
                onUnpin: { mode in
                    Task { await viewModel.unpinImage(forMode: mode, userId: authManager.userId) }
                }
            )
        }
    }

    // MARK: - Mode Filter

    private var modeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GalleryViewModel.ModeFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        label: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Image Grid

    private var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(viewModel.filteredImages) { image in
                    GalleryImageCard(
                        image: image,
                        isPinned: viewModel.isPinned(image)
                    ) {
                        selectedImage = image
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Loading / Empty

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.2)
            Text("이미지를 불러오는 중이에요").font(.dvBody).foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 48)).foregroundColor(.secondary)
            Text("이미지가 없어요").font(.dvTitle)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - GalleryImageCard

private struct GalleryImageCard: View {
    let image: VerseImage
    let isPinned: Bool
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: image.storageUrl)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable()
                        .scaledToFill()
                        .blur(radius: image.isHomeSafe ? 0 : 6)
                default:
                    modeColorBlock
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(2/3, contentMode: .fit)
            .clipped()

            // 모드 배지
            modesBadge

            // 핀 아이콘
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.dvAccentGold)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.5)))
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { onTap() }
    }

    private var modesBadge: some View {
        HStack(spacing: 2) {
            ForEach(image.mode.prefix(2), id: \.self) { mode in
                Text(modeEmoji(mode))
                    .font(.system(size: 11))
            }
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(Capsule().fill(Color.black.opacity(0.5)))
        .padding(6)
    }

    private var modeColorBlock: some View {
        Rectangle()
            .fill(Color.dvPrimaryMid.opacity(0.5))
            .aspectRatio(2/3, contentMode: .fit)
    }

    private func modeEmoji(_ mode: String) -> String {
        switch mode {
        case "morning":   return "☀️"
        case "afternoon": return "🌤"
        case "evening":   return "🌙"
        case "dawn":      return "✨"
        default:          return ""
        }
    }
}

// MARK: - FilterChip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
            .foregroundColor(isSelected ? .dvPrimaryDeep : .primary)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected ? Color.dvAccentGold : Color(UIColor.secondarySystemBackground))
            .clipShape(Capsule())
            .onTapGesture { onTap() }
    }
}

// MARK: - GalleryImageDetailSheet

struct GalleryImageDetailSheet: View {
    let image: VerseImage
    let pinnedImages: DVUser.PinnedImages
    let onPin: (AppMode) -> Void
    let onUnpin: (AppMode) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 이미지 미리보기
                    AsyncImage(url: URL(string: image.storageUrl)) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFit()
                                .blur(radius: image.isHomeSafe ? 0 : 8)
                        } else {
                            Rectangle().fill(Color.dvPrimaryMid.opacity(0.3))
                                .aspectRatio(4/3, contentMode: .fit)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                    // 메타 정보
                    VStack(alignment: .leading, spacing: 8) {
                        infoRow(label: "출처", value: image.source)
                        infoRow(label: "라이선스", value: image.license)
                        infoRow(label: "테마", value: image.theme.joined(separator: ", "))
                        infoRow(label: "분위기", value: image.mood.joined(separator: ", "))
                        if !image.isHomeSafe {
                            Label("홈 배경 설정 불가 (큐레이션 검토 중)", systemImage: "exclamationmark.triangle.fill")
                                .font(.dvCaption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 16)

                    // 모드별 배경 설정 (is_sacred_safe: true만 핀 가능)
                    if image.isHomeSafe {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("홈 배경으로 설정")
                                .font(.dvUITitle).padding(.horizontal, 16)

                            ForEach(AppMode.allCases, id: \.self) { mode in
                                let isPinned = pinnedImages.pinnedImageId(for: mode) == image.id
                                HStack {
                                    Text("\(modeEmoji(mode)) \(mode.rawValue.capitalized)")
                                        .font(.dvBody)
                                    Spacer()
                                    Button(isPinned ? "해제" : "설정") {
                                        if isPinned { onUnpin(mode) } else { onPin(mode) }
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(isPinned ? .red.opacity(0.8) : .dvAccentGold)
                                    .padding(.horizontal, 16).padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(isPinned ? Color.red.opacity(0.5) : Color.dvAccentGold.opacity(0.5))
                                    )
                                }
                                .padding(.horizontal, 16)
                                .dvButtonEffect()
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("이미지 상세")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label).font(.dvCaption).foregroundColor(.secondary).frame(width: 60, alignment: .leading)
            Text(value).font(.dvCaption).foregroundColor(.primary)
        }
    }

    private func modeEmoji(_ mode: AppMode) -> String {
        switch mode {
        case .morning:   return "☀️"
        case .afternoon: return "🌤"
        case .evening:   return "🌙"
        case .dawn:      return "✨"
        }
    }
}

#Preview {
    GalleryView()
        .environmentObject(AuthManager())
}
