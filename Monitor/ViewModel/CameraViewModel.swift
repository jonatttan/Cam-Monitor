import Combine
import Foundation

/// View state and user actions for the camera playback screen.
final class CameraViewModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var hasPlaybackError = false

    let playbackService: VLCPlaybackService
    private var cancellables = Set<AnyCancellable>()

    init(playbackService: VLCPlaybackService = VLCPlaybackService()) {
        self.playbackService = playbackService
        playbackService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isLoading = state == .connecting
                self?.hasPlaybackError = state == .failed
            }
            .store(in: &cancellables)
    }

    func start(url: String) {
        isLoading = true
        hasPlaybackError = false
        playbackService.play(url: url)
    }
}
