import SwiftUI

struct SplashView: View {

    @State private var opacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            Image("SplashBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .opacity(opacity)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.55)) { opacity = 1 }
            }
        }
    }
}

#Preview { SplashView() }
