//
//  CameraRepository.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Foundation
import Security

protocol CameraRepository {
    func fetchCameras() throws -> [Camera]
    func saveCameras(_ cameras: [Camera]) throws
}

final class KeychainCameraRepository: CameraRepository {
    private let service: String
    private let account: String

    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.jonattan.Monitor",
        account: String = "registered-cameras.v1"
    ) {
        self.service = service
        self.account = account
    }

    func fetchCameras() throws -> [Camera] {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw KeychainCameraRepositoryError.status(status) }
        guard let data = result as? Data else { throw KeychainCameraRepositoryError.invalidData }

        do {
            return try JSONDecoder().decode([Camera].self, from: data)
        } catch {
            throw KeychainCameraRepositoryError.invalidData
        }
    }

    func saveCameras(_ cameras: [Camera]) throws {
        let data = try JSONEncoder().encode(cameras)
        let update = [kSecValueData as String: data] as CFDictionary
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, update)

        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw KeychainCameraRepositoryError.status(updateStatus)
        }

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw KeychainCameraRepositoryError.status(addStatus) }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

private enum KeychainCameraRepositoryError: LocalizedError {
    case status(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .status:
            return "Não foi possível acessar o armazenamento seguro do iPhone."
        case .invalidData:
            return "Os dados das câmeras no armazenamento seguro não puderam ser lidos."
        }
    }
}
