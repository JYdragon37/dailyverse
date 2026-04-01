import SwiftUI
import Combine

struct OnboardingLocationView: View {
    var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "location.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.dvAccent)
                    .accessibilityLabel("위치 아이콘")

                Text("날씨에 맞는 말씀을\n전해드릴게요")
                    .font(.dvTitle)
                    .multilineTextAlignment(.center)

                Text("위치 정보는 날씨 확인에만 사용되며\n다른 용도로 활용되지 않습니다")
                    .font(.dvBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button("위치 허용하기") {
                    Task {
                        await viewModel.requestLocation()
                        viewModel.next()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("위치 권한 허용하기")

                Button("나중에") {
                    viewModel.skip()
                }
                .font(.dvBody)
                .foregroundColor(.secondary)
                .accessibilityLabel("위치 권한 나중에 설정하기")
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingLocationView(viewModel: OnboardingViewModel())
}
