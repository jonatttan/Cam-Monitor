//
//  CameraStore.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Combine
import Foundation

/// Shared camera catalog used by the Home and Settings view models.
final class CameraStore: ObservableObject {
    @Published private(set) var cameras: [Camera] = []
    @Published private(set) var isReady = false
    @Published private(set) var errorMessage: String?

    private let repository: CameraRepository
    private var hasLoaded = false

    init(repository: CameraRepository) {
        self.repository = repository
    }

    func load() {
        guard !hasLoaded else { return }
        do {
            cameras = try repository.fetchCameras()
            hasLoaded = true
            isReady = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(_ camera: Camera) throws {
        guard isReady else { throw CameraStoreError.notReady }
        guard !cameras.contains(where: { $0.ipAddress == camera.ipAddress }) else {
            throw CameraStoreError.duplicateAddress
        }
        var updated = cameras
        updated.append(camera)
        try repository.saveCameras(updated)
        cameras = updated
        errorMessage = nil
    }

    func remove(_ camera: Camera) throws {
        guard isReady else { throw CameraStoreError.notReady }
        let updated = cameras.filter { $0.id != camera.id }
        try repository.saveCameras(updated)
        cameras = updated
        errorMessage = nil
    }
}

private enum CameraStoreError: LocalizedError {
    case notReady
    case duplicateAddress

    var errorDescription: String? {
        switch self {
        case .notReady:
            return "O armazenamento seguro ainda não está disponível. Tente novamente."
        case .duplicateAddress:
            return "Já existe uma câmera cadastrada com esse endereço IP."
        }
    }
}
