//
//  CameraStoreTests.swift
//  MonitorTests
//
//  Created by Jonattan Sousa on 03/11/26.
//

import XCTest
@testable import Monitor

final class CameraStoreTests: XCTestCase {
    func testLoadReadsCamerasAndMarksStoreReady() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let repository = InMemoryCameraRepository(cameras: [camera])
        let store = CameraStore(repository: repository)

        store.load()

        XCTAssertEqual(store.cameras, [camera])
        XCTAssertTrue(store.isReady)
        XCTAssertNil(store.errorMessage)
    }

    func testLoadCanBeRetriedAfterRepositoryFailure() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let repository = InMemoryCameraRepository(cameras: [camera])
        repository.fetchError = RepositoryFailure.fetch
        let store = CameraStore(repository: repository)

        store.load()

        XCTAssertFalse(store.isReady)
        XCTAssertNotNil(store.errorMessage)

        repository.fetchError = nil
        store.load()

        XCTAssertTrue(store.isReady)
        XCTAssertEqual(store.cameras, [camera])
        XCTAssertNil(store.errorMessage)
        XCTAssertEqual(repository.fetchCallCount, 2)
    }

    func testLoadFetchesOnlyOnceAfterSuccess() {
        let repository = InMemoryCameraRepository()
        let store = CameraStore(repository: repository)

        store.load()
        store.load()

        XCTAssertEqual(repository.fetchCallCount, 1)
    }

    func testAddPersistsCameraAndUpdatesStore() throws {
        let repository = InMemoryCameraRepository()
        let store = CameraStore(repository: repository)
        store.load()
        let camera = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")

        try store.add(camera)

        XCTAssertEqual(store.cameras, [camera])
        XCTAssertEqual(repository.storedCameras, [camera])
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testAddRejectsDuplicateIPAddress() throws {
        let existingCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let repository = InMemoryCameraRepository(cameras: [existingCamera])
        let store = CameraStore(repository: repository)
        store.load()
        let duplicate = makeCamera(name: "Outra câmera", ipAddress: existingCamera.ipAddress)

        XCTAssertThrowsError(try store.add(duplicate))

        XCTAssertEqual(store.cameras, [existingCamera])
        XCTAssertEqual(repository.storedCameras, [existingCamera])
        XCTAssertEqual(repository.saveCallCount, 0)
    }

    func testAddRejectsOperationBeforeStoreIsReady() {
        let repository = InMemoryCameraRepository()
        let store = CameraStore(repository: repository)
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")

        XCTAssertThrowsError(try store.add(camera))

        XCTAssertTrue(store.cameras.isEmpty)
        XCTAssertEqual(repository.saveCallCount, 0)
    }

    func testAddLeavesStoreUnchangedWhenRepositorySaveFails() {
        let existingCamera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let repository = InMemoryCameraRepository(cameras: [existingCamera])
        let store = CameraStore(repository: repository)
        store.load()
        repository.saveError = RepositoryFailure.save
        let newCamera = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")

        XCTAssertThrowsError(try store.add(newCamera))

        XCTAssertEqual(store.cameras, [existingCamera])
        XCTAssertEqual(repository.storedCameras, [existingCamera])
    }

    func testRemovePersistsUpdatedListAndUpdatesStore() throws {
        let cameraToKeep = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let cameraToRemove = makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        let repository = InMemoryCameraRepository(cameras: [cameraToKeep, cameraToRemove])
        let store = CameraStore(repository: repository)
        store.load()

        try store.remove(cameraToRemove)

        XCTAssertEqual(store.cameras, [cameraToKeep])
        XCTAssertEqual(repository.storedCameras, [cameraToKeep])
        XCTAssertEqual(repository.saveCallCount, 1)
    }

    func testRemoveLeavesStoreUnchangedWhenRepositorySaveFails() {
        let camera = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let repository = InMemoryCameraRepository(cameras: [camera])
        let store = CameraStore(repository: repository)
        store.load()
        repository.saveError = RepositoryFailure.save

        XCTAssertThrowsError(try store.remove(camera))

        XCTAssertEqual(store.cameras, [camera])
        XCTAssertEqual(repository.storedCameras, [camera])
    }

    private func makeCamera(name: String, ipAddress: String) -> Camera {
        Camera(
            name: name,
            ipAddress: ipAddress,
            rtspAddress: "rtsp://test-user:test-password@\(ipAddress):554/onvif1"
        )
    }
}

private final class InMemoryCameraRepository: CameraRepository {
    private(set) var storedCameras: [Camera]
    private(set) var fetchCallCount = 0
    private(set) var saveCallCount = 0
    var fetchError: Error?
    var saveError: Error?

    init(cameras: [Camera] = []) {
        storedCameras = cameras
    }

    func fetchCameras() throws -> [Camera] {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return storedCameras
    }

    func saveCameras(_ cameras: [Camera]) throws {
        saveCallCount += 1
        if let saveError { throw saveError }
        storedCameras = cameras
    }
}

private enum RepositoryFailure: Error {
    case fetch
    case save
}
