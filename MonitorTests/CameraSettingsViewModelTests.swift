//
//  CameraSettingsViewModelTests.swift
//  MonitorTests
//
//  Created by Jonattan Sousa on 03/11/26.
//

import XCTest
@testable import Monitor

final class CameraSettingsViewModelTests: XCTestCase {
    func testAddCameraRejectsEmptyName() {
        let (viewModel, repository) = makeViewModel()

        let error = viewModel.addCamera(
            name: "  ",
            ipAddress: "192.168.2.10",
            username: "admin",
            password: "example-password"
        )

        XCTAssertNotNil(error)
        XCTAssertTrue(repository.storedCameras.isEmpty)
    }

    func testAddCameraRejectsInvalidIPAddress() {
        let (viewModel, repository) = makeViewModel()

        let error = viewModel.addCamera(
            name: "Sala",
            ipAddress: "192.168.2.256",
            username: "admin",
            password: "example-password"
        )

        XCTAssertNotNil(error)
        XCTAssertTrue(repository.storedCameras.isEmpty)
    }

    func testAddCameraRejectsEmptyUsername() {
        let (viewModel, repository) = makeViewModel()

        let error = viewModel.addCamera(
            name: "Sala",
            ipAddress: "192.168.2.10",
            username: "  ",
            password: "example-password"
        )

        XCTAssertNotNil(error)
        XCTAssertTrue(repository.storedCameras.isEmpty)
    }

    func testAddCameraRejectsEmptyPassword() {
        let (viewModel, repository) = makeViewModel()

        let error = viewModel.addCamera(
            name: "Sala",
            ipAddress: "192.168.2.10",
            username: "admin",
            password: ""
        )

        XCTAssertNotNil(error)
        XCTAssertTrue(repository.storedCameras.isEmpty)
    }

    func testAddCameraTrimsInputsBuildsAddressAndSelectsCamera() throws {
        let (viewModel, repository) = makeViewModel()

        let error = viewModel.addCamera(
            name: "  Sala de estar  ",
            ipAddress: " 192.168.2.10 ",
            username: " admin ",
            password: "example-password"
        )

        XCTAssertNil(error)
        let camera = try XCTUnwrap(repository.storedCameras.first)
        XCTAssertEqual(camera.name, "Sala de estar")
        XCTAssertEqual(camera.ipAddress, "192.168.2.10")
        XCTAssertEqual(camera.rtspAddress, "rtsp://admin:example-password@192.168.2.10:554/onvif1")
        XCTAssertEqual(viewModel.selectedCameraID, camera.id)
    }

    func testAddCameraReturnsErrorWhenIPAddressAlreadyExists() {
        let existingCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, repository) = makeViewModel(cameras: [existingCamera])

        let error = viewModel.addCamera(
            name: "Outra câmera",
            ipAddress: existingCamera.ipAddress,
            username: "admin",
            password: "example-password"
        )

        XCTAssertNotNil(error)
        XCTAssertEqual(repository.storedCameras, [existingCamera])
    }

    func testSelectTogglesCameraSelection() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, _) = makeViewModel(cameras: [camera])

        viewModel.select(camera)
        XCTAssertEqual(viewModel.selectedCameraID, camera.id)
        XCTAssertEqual(viewModel.selectedCamera, camera)

        viewModel.select(camera)
        XCTAssertNil(viewModel.selectedCameraID)
        XCTAssertNil(viewModel.selectedCamera)
    }

    func testRemoveCameraClearsSelectionAndPersistsRemoval() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, repository) = makeViewModel(cameras: [camera])
        viewModel.select(camera)

        let error = viewModel.removeCamera(camera)

        XCTAssertNil(error)
        XCTAssertNil(viewModel.selectedCameraID)
        XCTAssertTrue(repository.storedCameras.isEmpty)
    }

    func testRemoveCameraKeepsSelectionWhenPersistenceFails() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let (viewModel, repository) = makeViewModel(cameras: [camera])
        viewModel.select(camera)
        repository.saveError = RepositoryFailure.save

        let error = viewModel.removeCamera(camera)

        XCTAssertNotNil(error)
        XCTAssertEqual(viewModel.selectedCameraID, camera.id)
        XCTAssertEqual(repository.storedCameras, [camera])
    }

    func testAddCameraReturnsErrorWhenStorageIsNotReady() {
        let repository = SettingsViewModelRepositoryStub()
        let store = CameraStore(repository: repository)
        let viewModel = CameraSettingsViewModel(cameraStore: store)

        let error = viewModel.addCamera(
            name: "Sala",
            ipAddress: "192.168.2.10",
            username: "admin",
            password: "example-password"
        )

        XCTAssertNotNil(error)
        XCTAssertTrue(repository.storedCameras.isEmpty)
    }

    private func makeViewModel(
        cameras: [Camera] = []
    ) -> (CameraSettingsViewModel, SettingsViewModelRepositoryStub) {
        let repository = SettingsViewModelRepositoryStub(cameras: cameras)
        let store = CameraStore(repository: repository)
        store.load()
        return (CameraSettingsViewModel(cameraStore: store), repository)
    }

    private func makeCamera(name: String, ipAddress: String) -> Camera {
        Camera(
            name: name,
            ipAddress: ipAddress,
            rtspAddress: "rtsp://test-user:test-password@\(ipAddress):554/onvif1"
        )
    }
}

private final class SettingsViewModelRepositoryStub: CameraRepository {
    private(set) var storedCameras: [Camera]
    var saveError: Error?

    init(cameras: [Camera] = []) {
        storedCameras = cameras
    }

    func fetchCameras() throws -> [Camera] {
        storedCameras
    }

    func saveCameras(_ cameras: [Camera]) throws {
        if let saveError { throw saveError }
        storedCameras = cameras
    }
}

private enum RepositoryFailure: Error {
    case save
}
