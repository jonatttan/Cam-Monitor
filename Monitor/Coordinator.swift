class Coordinator: NSObject, VLCMediaPlayerDelegate {
        var player: VLCMediaPlayer?
        weak var view: UIView?
        private var showLoading: Binding<Bool>
        
        init(showLoading: Binding<Bool>) {
            self.showLoading = showLoading
        }
        
        func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
            guard showLoading.wrappedValue else { return }
                shouldTheStateChange()
        }
        
        func shouldTheStateChange() {
            guard let player else { return }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.showLoading.wrappedValue = !player.hasVideoOut
            }
        }
    }