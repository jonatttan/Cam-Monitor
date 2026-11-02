//
//  CameraViewModel.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Combine
import Foundation

/// Owns the Home screen state and forwards camera selection to the playback service.
final class CameraViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var hasPlaybackError = false
    @Published private(set) var cameras: [Camera]
    @Published private(set) var selectedCameraID: Camera.ID?

    let playbackService: VLCPlaybackService
    private let cameraStore: CameraStore
    private var cancellables = Set<AnyCancellable>()
    private var hasStartedInitialCamera = false

    init(cameraStore: CameraStore, playbackService: VLCPlaybackService = VLCPlaybackService()) {
        self.cameraStore = cameraStore
        self.playbackService = playbackService
        self.cameras = cameraStore.cameras

        cameraStore.$cameras
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cameras in
                guard let self else { return }
                self.cameras = cameras
                if let selectedID = self.selectedCameraID,
                   !cameras.contains(where: { $0.id == selectedID }) {
                    self.playbackService.stop()
                    self.selectedCameraID = nil
                    self.isLoading = false
                    self.hasPlaybackError = false
                }
            }
            .store(in: &cancellables)

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
           (playbackService.state == .connecting || playbackService.state == .playing) {
            return
        }

        selectedCameraID = camera.id
        isLoading = true
        hasPlaybackError = false
        playbackService.play(url: camera.rtspAddress)
    }
}
