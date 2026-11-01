
import SwiftUI
import VLCKit

struct VLCPlayerView: UIViewRepresentable {
    let url: String
    
    // TODO: - must be an enum with options like connectionError, isPlaying, waiting
    @Binding var showLoading: Bool
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        let mediaPlayer = VLCMediaPlayer()
        
        guard let urlMedia = URL(string: url),
              let media = VLCMedia(url: urlMedia)
              else {
            view.largeContentTitle = "Ops!"
            return view
        }
        
        media.addOption(":rtsp-tcp")
        media.addOption(":no-audio")
        
        mediaPlayer.media = media
        mediaPlayer.drawable = view
        mediaPlayer.delegate = context.coordinator
        
        context.coordinator.player = mediaPlayer
        context.coordinator.view = view
        
        mediaPlayer.play()
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(showLoading: $showLoading)
    }
}
