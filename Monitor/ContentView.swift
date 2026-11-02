import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CameraViewModel()
    let streamURL = "rtsp://admin:passcode321@192.168.2.112:554/onvif1"

    var body: some View {
        ZStack {
            VLCPlayerView(playbackService: viewModel.playbackService)
                .opacity(viewModel.isLoading || viewModel.hasPlaybackError ? 0 : 1)
                .animation(.easeIn(duration: 0.25), value: viewModel.isLoading || viewModel.hasPlaybackError)
                .ignoresSafeArea()
                .overlay {
                    if viewModel.isLoading || viewModel.hasPlaybackError {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text(viewModel.hasPlaybackError ? "Não foi possível conectar" : "Conectando à câmera...")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.35))
                        .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.5), value: viewModel.isLoading || viewModel.hasPlaybackError)
        }
        .onAppear { viewModel.start(url: streamURL) }
    }
}

#Preview {
    ContentView()
}
