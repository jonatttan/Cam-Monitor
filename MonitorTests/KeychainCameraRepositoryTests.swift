//
//  KeychainCameraRepositoryTests.swift
//  MonitorTests
//
//  Created by Jonattan Sousa on 03/11/26.
//

import Foundation
import Security
import XCTest
@testable import Monitor

final class KeychainCameraRepositoryTests: XCTestCase {
    func testFetchReturnsEmptyArrayWhenNoRecordExists() throws {
        let (repository, service, account) = makeRepository()
        defer { deleteKeychainItem(service: service, account: account) }

        XCTAssertEqual(try repository.fetchCameras(), [])
    }

    func testSaveAddsAndFetchesCameraRecords() throws {
        let (repository, service, account) = makeRepository()
        defer { deleteKeychainItem(service: service, account: account) }
        let cameras = [
            makeCamera(name: "Sala", ipAddress: "192.168.2.10"),
            makeCamera(name: "Entrada", ipAddress: "192.168.2.11")
        ]

        try repository.saveCameras(cameras)

        XCTAssertEqual(try repository.fetchCameras(), cameras)
    }

    func testSaveUpdatesAnExistingRecord() throws {
        let (repository, service, account) = makeRepository()
        defer { deleteKeychainItem(service: service, account: account) }
        let original = makeCamera(name: "Sala", ipAddress: "192.168.2.10")
        let updated = makeCamera(name: "Sala nova", ipAddress: "192.168.2.10")

        try repository.saveCameras([original])
        try repository.saveCameras([updated])

        XCTAssertEqual(try repository.fetchCameras(), [updated])
    }

    func testSavingEmptyListReturnsEmptyListOnNextRead() throws {
        let (repository, service, account) = makeRepository()
        defer { deleteKeychainItem(service: service, account: account) }

        try repository.saveCameras([makeCamera(name: "Sala", ipAddress: "192.168.2.10")])
        try repository.saveCameras([])

        XCTAssertEqual(try repository.fetchCameras(), [])
    }

    func testFetchThrowsWhenStoredDataIsNotValidCameraJSON() throws {
        let (repository, service, account) = makeRepository()
        defer { deleteKeychainItem(service: service, account: account) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: Data([0xFF, 0x00, 0x01])
        ]
        XCTAssertEqual(SecItemAdd(query as CFDictionary, nil), errSecSuccess)

        XCTAssertThrowsError(try repository.fetchCameras())
    }

    func testSavedItemIsRestrictedToThisDeviceAndAvailableWhenUnlocked() throws {
        let (repository, service, account) = makeRepository()
        defer { deleteKeychainItem(service: service, account: account) }
        try repository.saveCameras([makeCamera(name: "Sala", ipAddress: "192.168.2.10")])

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess)
        let attributes = try XCTUnwrap(result as? [String: Any])
        XCTAssertEqual(
            attributes[kSecAttrAccessible as String] as? String,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String
        )
    }

    private func makeRepository() -> (KeychainCameraRepository, String, String) {
        let service = "com.jonattan.Monitor.tests.\(UUID().uuidString)"
        let account = "camera-records-\(UUID().uuidString)"
        return (KeychainCameraRepository(service: service, account: account), service, account)
    }

    private func deleteKeychainItem(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func makeCamera(name: String, ipAddress: String) -> Camera {
        Camera(
            name: name,
            ipAddress: ipAddress,
            rtspAddress: "rtsp://test-user:test-password@\(ipAddress):554/onvif1"
        )
    }
}
