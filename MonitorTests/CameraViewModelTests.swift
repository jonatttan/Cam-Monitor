//
//  CameraViewModelTests.swift
//  MonitorTests
//
//  Created by Jonattan Sousa on 03/11/26.
//

import Combine
import UIKit
import XCTest
@testable import Monitor

final class CameraViewModelTests: XCTestCase {
    func testStartInitialCameraIfNeededStartsFirstCameraOnlyOnce() {
        let firstCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let secondCamera = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        let (viewModel, playback) = makeViewModel(cameras: [firstCamera, secondCamera])

        viewModel.startInitialCameraIfNeeded()
        viewModel.startInitialCameraIfNeeded()

        XCTAssertEqual(viewModel.selectedCameraID, firstCamera.id)
        XCTAssertEqual(playback.playedURLs, [firstCamera.rtspAddress])
    }

    func testStartInitialCameraIfNeededDoesNothingWhenThereAreNoCameras() {
        let (viewModel, playback) = makeViewModel()

        viewModel.startInitialCameraIfNeeded()

        XCTAssertNil(viewModel.selectedCameraID)
        XCTAssertTrue(playback.playedURLs.isEmpty)
    }

    func testSelectingAnotherCameraRequestsItsStream() {
        let firstCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let secondCamera = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        let (viewModel, playback) = makeViewModel(cameras: [firstCamera, secondCamera])

        viewModel.selectCamera(firstCamera)
        viewModel.selectCamera(secondCamera)

        XCTAssertEqual(viewModel.selectedCameraID, secondCamera.id)
        XCTAssertEqual(playback.playedURLs, [firstCamera.rtspAddress, secondCamera.rtspAddress])
        XCTAssertEqual(playback.activeURL, secondCamera.rtspAddress)
    }

    func testSelectingSameCameraWhileConnectingDoesNotRestartIt() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, playback) = makeViewModel(cameras: [camera])

        viewModel.selectCamera(camera)
        viewModel.selectCamera(camera)

        XCTAssertEqual(playback.playedURLs, [camera.rtspAddress])
    }

    func testSelectingSameCameraAfterFailureRetriesPlayback() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, playback) = makeViewModel(cameras: [camera])

        viewModel.selectCamera(camera)
        playback.send(.failed)
        viewModel.selectCamera(camera)

        XCTAssertEqual(playback.playedURLs, [camera.rtspAddress, camera.rtspAddress])
    }

    func testRemovingSelectedCameraStopsPlaybackAndClearsSelection() async throws {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, playback, store) = makeViewModelWithStore(cameras: [camera])
        viewModel.selectCamera(camera)

        let selectionCleared = expectation(description: "The removed camera is deselected")
        let cancellable = viewModel.$selectedCameraID
            .dropFirst()
            .sink { selectedID in
                if selectedID == nil {
                    selectionCleared.fulfill()
                }
            }
        try store.remove(camera)

        await fulfillment(of: [selectionCleared], timeout: 1)
        XCTAssertEqual(playback.stopCallCount, 1)
        XCTAssertNil(viewModel.selectedCameraID)
        withExtendedLifetime(cancellable) {}
    }

    private func makeViewModel(
        cameras: [Camera] = []
    ) -> (CameraViewModel, PlaybackServiceStub) {
        let (viewModel, playback, _) = makeViewModelWithStore(cameras: cameras)
        return (viewModel, playback)
    }

    private func makeViewModelWithStore(
        cameras: [Camera] = []
    ) -> (CameraViewModel, PlaybackServiceStub, CameraStore) {
        let repository = CameraViewModelRepositoryStub(cameras: cameras)
        let store = CameraStore(repository: repository)
        store.load()
        let playback = PlaybackServiceStub()
        let viewModel = CameraViewModel(cameraStore: store, playbackService: playback)
        return (viewModel, playback, store)
    }

    private func makeCamera(name: String, ipAddress: String) -> Camera {
        Camera(
            name: name,
            ipAddress: ipAddress,
            rtspAddress: "rtsp://test-user:test-password@\(ipAddress):554/onvif1"
        )
    }
}

private final class PlaybackServiceStub: CameraPlaybackServicing {
    private let stateSubject = CurrentValueSubject<VLCPlaybackService.State, Never>(.idle)
    private(set) var playedURLs: [String] = []
    private(set) var activeURL: String?
    private(set) var stopCallCount = 0

    var state: VLCPlaybackService.State { stateSubject.value }
    var statePublisher: AnyPublisher<VLCPlaybackService.State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    func attach(to view: UIView) {}
    func detach(from view: UIView) {}

    func play(url: String) {
        playedURLs.append(url)
        activeURL = url
        stateSubject.send(.connecting)
    }

    func stop() {
        stopCallCount += 1
        activeURL = nil
        stateSubject.send(.idle)
    }

    func send(_ state: VLCPlaybackService.State) {
        stateSubject.send(state)
    }
}

private final class CameraViewModelRepositoryStub: CameraRepository {
    private(set) var storedCameras: [Camera]

    init(cameras: [Camera]) {
        storedCameras = cameras
    }

    func fetchCameras() throws -> [Camera] { storedCameras }

    func saveCameras(_ cameras: [Camera]) throws {
        storedCameras = cameras
    }
}
