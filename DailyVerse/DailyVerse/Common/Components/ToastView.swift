import SwiftUI
import Combine

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.dvBody)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.75))
            )
            .padding(.bottom, 32)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityLabel(message)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        VStack {
            Spacer()
            ToastView(message: "내일 06:00, 말씀이 함께 울릴 거예요")
        }
    }
}
