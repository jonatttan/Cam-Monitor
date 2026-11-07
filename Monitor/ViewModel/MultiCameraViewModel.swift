//
//  MultiCameraViewModel.swift
//  Monitor
//
//  Created by Jonattan Sousa on 06/11/26.
//

import Combine
import Foundation

final class MultiCameraViewModel: ObservableObject {
    static let maximumCameraCount = 4

    @Published private(set) var cameras: [Camera]
    @Published private(set) var selectedCameraIDs: [Camera.ID] = []
    @Published private(set) var playbackStates: [Camera.ID: VLCPlaybackService.State] = [:]

    private let cameraStore: CameraStore
    private let playbackServiceFactory: () -> CameraPlaybackServicing
    private var playbackServices: [Camera.ID: CameraPlaybackServicing] = [:]
    private var stateSubscriptions: [Camera.ID: AnyCancellable] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(
        cameraStore: CameraStore,
        playbackServiceFactory: @escaping () -> CameraPlaybackServicing = { VLCPlaybackService() }
    ) {
        self.cameraStore = cameraStore
        self.cameras = cameraStore.cameras
        self.playbackServiceFactory = playbackServiceFactory

        cameraStore.$cameras
            .receive(on: DispatchQueue.main)
            .sink { [weak self] cameras in self?.updateCameras(cameras) }
            .store(in: &cancellables)
    }

    var availableCameras: [Camera] {
        cameras.filter { !selectedCameraIDs.contains($0.id) }
    }

    func toggle(_ camera: Camera) {
        if selectedCameraIDs.contains(camera.id) {
            remove(camera)
            return
        }
        guard selectedCameraIDs.count < Self.maximumCameraCount else { return }

        let service = playbackServiceFactory()
        playbackServices[camera.id] = service
        selectedCameraIDs.append(camera.id)
        service.play(url: camera.rtspAddress)
        stateSubscriptions[camera.id] = service.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.playbackStates[camera.id] = state }
    }

    func service(for cameraID: Camera.ID) -> CameraPlaybackServicing? {
        playbackServices[cameraID]
    }

    func stopAll() {
        playbackServices.values.forEach { $0.stop() }
    }

    func resumeSelectedCameras() {
        for id in selectedCameraIDs {
            guard let camera = cameras.first(where: { $0.id == id }),
                  let service = playbackServices[id] else { continue }
            service.play(url: camera.rtspAddress)
        }
    }

    private func remove(_ camera: Camera) {
        playbackServices[camera.id]?.stop()
        playbackServices[camera.id] = nil
        stateSubscriptions[camera.id]?.cancel()
        stateSubscriptions[camera.id] = nil
        playbackStates[camera.id] = nil
        selectedCameraIDs.removeAll { $0 == camera.id }
    }

    private func updateCameras(_ cameras: [Camera]) {
        self.cameras = cameras
        let currentIDs = Set(cameras.map(\.id))
        for id in selectedCameraIDs where !currentIDs.contains(id) {
            playbackServices[id]?.stop()
            playbackServices[id] = nil
            stateSubscriptions[id]?.cancel()
            stateSubscriptions[id] = nil
            playbackStates[id] = nil
        }
        selectedCameraIDs.removeAll { !currentIDs.contains($0) }
    }
}
