//
//  MultiCameraViewModelTests.swift
//  MonitorTests
//
//  Created by Jonattan Sousa on 06/11/26.
//

import Combine
import UIKit
import XCTest
@testable import Monitor

final class MultiCameraViewModelTests: XCTestCase {
    func testSelectingCameraStartsItsStreamWithAnIndependentService() {
        let firstCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let secondCamera = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        let (viewModel, playbackFactory) = makeViewModel(cameras: [firstCamera, secondCamera])

        viewModel.toggle(firstCamera)
        viewModel.toggle(secondCamera)

        XCTAssertEqual(viewModel.selectedCameraIDs, [firstCamera.id, secondCamera.id])
        XCTAssertEqual(playbackFactory.services.count, 2)
        XCTAssertFalse(playbackFactory.services[0] === playbackFactory.services[1])
        XCTAssertEqual(playbackFactory.services[0].playedURLs, [firstCamera.rtspAddress])
        XCTAssertEqual(playbackFactory.services[1].playedURLs, [secondCamera.rtspAddress])
    }

    func testDoesNotAllowMoreThanFourCamerasAtOnce() {
        let cameras = (1...5).map { index in
            makeCamera(name: "Câmera \(index)", ipAddress: "192.168.2.\(index)")
        }
        let (viewModel, playbackFactory) = makeViewModel(cameras: cameras)

        cameras.forEach(viewModel.toggle)

        XCTAssertEqual(viewModel.selectedCameraIDs, Array(cameras.prefix(4).map(\.id)))
        XCTAssertEqual(playbackFactory.services.count, MultiCameraViewModel.maximumCameraCount)
        XCTAssertEqual(viewModel.availableCameras, [cameras[4]])
    }

    func testTogglingSelectedCameraStopsAndRemovesItsStream() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, playbackFactory) = makeViewModel(cameras: [camera])

        viewModel.toggle(camera)
        viewModel.toggle(camera)

        XCTAssertTrue(viewModel.selectedCameraIDs.isEmpty)
        XCTAssertNil(viewModel.service(for: camera.id))
        XCTAssertEqual(playbackFactory.services[0].stopCallCount, 1)
    }

    func testStopAllStopsStreamsAndResumeRestartsSelectedCameras() {
        let firstCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let secondCamera = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        let (viewModel, playbackFactory) = makeViewModel(cameras: [firstCamera, secondCamera])
        viewModel.toggle(firstCamera)
        viewModel.toggle(secondCamera)

        viewModel.stopAll()

        XCTAssertEqual(playbackFactory.services.map(\.stopCallCount), [1, 1])
        XCTAssertEqual(viewModel.selectedCameraIDs, [firstCamera.id, secondCamera.id])

        viewModel.resumeSelectedCameras()

        XCTAssertEqual(playbackFactory.services[0].playedURLs, [firstCamera.rtspAddress, firstCamera.rtspAddress])
        XCTAssertEqual(playbackFactory.services[1].playedURLs, [secondCamera.rtspAddress, secondCamera.rtspAddress])
    }

    func testRemovingCameraFromStoreStopsAndRemovesItsStream() async throws {
        let cameraToKeep = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let cameraToRemove = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        let (viewModel, playbackFactory, store) = makeViewModelWithStore(cameras: [cameraToKeep, cameraToRemove])
        viewModel.toggle(cameraToRemove)

        let selectionUpdated = expectation(description: "Removed camera is no longer selected")
        let cancellable = viewModel.$selectedCameraIDs
            .dropFirst()
            .sink { selectedIDs in
                if selectedIDs.isEmpty {
                    selectionUpdated.fulfill()
                }
            }

        try store.remove(cameraToRemove)

        await fulfillment(of: [selectionUpdated], timeout: 1)
        XCTAssertEqual(viewModel.cameras, [cameraToKeep])
        XCTAssertNil(viewModel.service(for: cameraToRemove.id))
        XCTAssertEqual(playbackFactory.services[0].stopCallCount, 1)
        withExtendedLifetime(cancellable) {}
    }

    private func makeViewModel(
        cameras: [Camera] = []
    ) -> (MultiCameraViewModel, MultiCameraPlaybackFactorySpy) {
        let (viewModel, playbackFactory, _) = makeViewModelWithStore(cameras: cameras)
        return (viewModel, playbackFactory)
    }

    private func makeViewModelWithStore(
        cameras: [Camera] = []
    ) -> (MultiCameraViewModel, MultiCameraPlaybackFactorySpy, CameraStore) {
        let store = CameraStore(repository: MultiCameraRepositoryStub(cameras: cameras))
        store.load()
        let playbackFactory = MultiCameraPlaybackFactorySpy()
        let viewModel = MultiCameraViewModel(cameraStore: store) {
            playbackFactory.makeService()
        }
        return (viewModel, playbackFactory, store)
    }

    private func makeCamera(name: String, ipAddress: String) -> Camera {
        Camera(
            name: name,
            ipAddress: ipAddress,
            rtspAddress: "rtsp://test-user:test-password@\(ipAddress):554/onvif1"
        )
    }
}

private final class MultiCameraPlaybackFactorySpy {
    private(set) var services: [MultiCameraPlaybackStub] = []

    func makeService() -> MultiCameraPlaybackStub {
        let service = MultiCameraPlaybackStub()
        services.append(service)
        return service
    }
}

private final class MultiCameraPlaybackStub: CameraPlaybackServicing {
    private let stateSubject = CurrentValueSubject<VLCPlaybackService.State, Never>(.idle)
    private(set) var playedURLs: [String] = []
    private(set) var stopCallCount = 0

    var state: VLCPlaybackService.State { stateSubject.value }
    var statePublisher: AnyPublisher<VLCPlaybackService.State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func attach(to view: UIView) {}
    func detach(from view: UIView) {}

    func play(url: String) {
        playedURLs.append(url)
        stateSubject.send(.connecting)
    }

    func stop() {
        stopCallCount += 1
        stateSubject.send(.idle)
    }
}

private final class MultiCameraRepositoryStub: CameraRepository {
    private var storedCameras: [Camera]

    init(cameras: [Camera]) {
        storedCameras = cameras
    }

    func fetchCameras() throws -> [Camera] { storedCameras }

    func saveCameras(_ cameras: [Camera]) throws {
        storedCameras = cameras
    }
}
