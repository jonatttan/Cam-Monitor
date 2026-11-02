import Combine
import Foundation

/// Owns the Home screen state and forwards camera selection to the playback service.
final class CameraViewModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var hasPlaybackError = false
    @Published private(set) var cameras: [Camera]
    @Published private(set) var selectedCameraID: Camera.ID?

    let playbackService: VLCPlaybackService
    private var cancellables = Set<AnyCancellable>()
    private var hasStartedInitialCamera = false

    init(
        playbackService: VLCPlaybackService = VLCPlaybackService(),
        cameras: [Camera] = [.previewCamera]
    ) {
        self.playbackService = playbackService
        self.cameras = cameras

        playbackService.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.isLoading = state == .connecting
                self?.hasPlaybackError = state == .failed
            }
            .store(in: &cancellables)
    }

    var selectedCamera: Camera? {
        cameras.first { $0.id == selectedCameraID }
    }

    var playbackState: VLCPlaybackService.State {
        playbackService.state
    }

    func startInitialCameraIfNeeded() {
        guard !hasStartedInitialCamera, let firstCamera = cameras.first else { return }
        hasStartedInitialCamera = true
        selectCamera(firstCamera)
    }

    func selectCamera(_ camera: Camera) {
        if selectedCameraID == camera.id,
           playbackService.state == .connecting || playbackService.state == .playing {
            return
        }

        selectedCameraID = camera.id
        isLoading = true
        hasPlaybackError = false
        playbackService.play(url: camera.streamURL)
    }
}
