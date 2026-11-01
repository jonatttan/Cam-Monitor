
import SwiftUI
//import MobileVLCKit
import VLCKit

struct VLCPlayerView: UIViewRepresentable {
    let url: String
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
        // 0.45 -> 7.74 = 7.29
        // 0.41 -> 2.55 = 2.14
        // 0.39-1.62 = 1,23
//        media.addOption(":network-caching=300")
//        media.addOption(":live-caching=300") // com esses dois, 60s. sem, 35.
        media.addOption(":rtsp-tcp")
//        media.addOption(":avcodec-hw=videotoolbox")
        media.addOption(":no-audio")
        mediaPlayer.media = media
        mediaPlayer.drawable = view
        mediaPlayer.delegate = context.coordinator
        
        context.coordinator.player = mediaPlayer
//        context.coordinator.showLoading = $showLoading
        context.coordinator.view = view
        
//        DispatchQueue.main.async {
        context.coordinator.startTimer()
        mediaPlayer.play()
//        }
        
        return view
    }
    
//    func updadeUIView(_ uiView: UIView, context: Context) {}
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(showLoading: $showLoading)
    }
    
    class Coordinator: NSObject, VLCMediaPlayerDelegate {
        var player: VLCMediaPlayer?
        weak var view: UIView?
        private var showLoading: Binding<Bool>
        private var controlTheVideoOutShowMessage: Bool = false
        
        private var playStartedAt: Date?
        
        init(showLoading: Binding<Bool>) {
            self.showLoading = showLoading
        }
        
        func startTimer() {
            playStartedAt = Date()
        }
        
        func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
            guard let player,
                  let playStartedAt else { return }
            
            let elapsed = Date().timeIntervalSince(playStartedAt)
            print(
                String(format: "[VLC] %.2f s — estado: %@", elapsed, "\(player.state)")
            )
            shouldTheStateChange()
        }
//        func mediaPlayerStateChanged(_ notification: Notification!) {
//            guard let player,
//                  let playStartedAt else { return }
//            
//            let elapsed = Date().timeIntervalSince(playStartedAt)
//            print(
//                String(format: "[VLC] %.2f s — estado: %@", elapsed, "\(player.state)")
//            )
//            shouldTheStateChange()
//        }
//        
//        func shouldTheStateChange() {
//            guard let player else { return }
//            let shouldShowLoading: Bool
//            
//            switch player.state {
//            case .opening, .buffering, .esAdded: //added -> Buffering -> Ended
//                shouldShowLoading = true
//            case .playing, .paused, .stopped, .ended, .error:
//                shouldShowLoading = false
//            @unknown default:
//                shouldShowLoading = false
//            }
//            
//            DispatchQueue.main.async { [weak self] in
//                self?.showLoading.wrappedValue = shouldShowLoading
//            }
//        }
        
        func mediaPlayerTimeChanged(_ aNotification: Notification) {
            guard let player,
                  let playStartedAt else { return }
//            print("[VLC] tempo mudou; hasVideoOut:", player.hasVideoOut as Any)
//            print("[VLC]: ", player?.state as Any)
            
            if player.hasVideoOut == true, controlTheVideoOutShowMessage == false {
                let elapsed = Date().timeIntervalSince(playStartedAt)
                print(
                    String(format: "[VLC] %.2f s — hasVideoOut: %@", elapsed, "\(player.state)")
                )
                
                controlTheVideoOutShowMessage = true
                shouldTheStateChange()
            }
            
        }
        
        func shouldTheStateChange() {
            guard let player else { return }
            let shouldShowLoading: Bool
            
            shouldShowLoading = !player.hasVideoOut
            
            DispatchQueue.main.async { [weak self] in
                self?.showLoading.wrappedValue = shouldShowLoading
            }
        }
    }
}
