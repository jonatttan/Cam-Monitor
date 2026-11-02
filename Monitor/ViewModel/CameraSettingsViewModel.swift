//
//  CameraSettingsViewModel.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Combine
import Foundation

final class CameraSettingsViewModel: ObservableObject {
    @Published private(set) var cameras: [Camera]
    @Published private(set) var isStorageReady: Bool
    @Published private(set) var storageErrorMessage: String?
    @Published private(set) var selectedCameraID: Camera.ID?

    private let cameraStore: CameraStore
    private var cancellables = Set<AnyCancellable>()

    init(cameraStore: CameraStore) {
        self.cameraStore = cameraStore
        self.cameras = cameraStore.cameras
        self.isStorageReady = cameraStore.isReady
        self.storageErrorMessage = cameraStore.errorMessage

        cameraStore.$cameras
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.cameras = $0 }
            .store(in: &cancellables)
        cameraStore.$isReady
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isStorageReady = $0 }
            .store(in: &cancellables)
        cameraStore.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.storageErrorMessage = $0 }
            .store(in: &cancellables)
    }

    var selectedCamera: Camera? {
        cameras.first { $0.id == selectedCameraID }
    }

    func retryStorageAccess() {
        cameraStore.load()
    }

    func select(_ camera: Camera) {
        selectedCameraID = selectedCameraID == camera.id ? nil : camera.id
    }

    func addCamera(name: String, ipAddress: String, username: String, password: String) -> String? {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let ipAddress = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let username = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else { return "Informe um nome para a câmera." }
        guard CameraAddressBuilder.isValidIPv4(ipAddress) else { return "Informe um endereço IPv4 válido." }
        guard !username.isEmpty else { return "Informe o usuário da câmera." }
        guard !password.isEmpty else { return "Informe a senha da câmera." }
        guard let address = CameraAddressBuilder.makeRTSPAddress(
            ipAddress: ipAddress,
            username: username,
            password: password
        ) else {
            return "Não foi possível montar o endereço RTSP."
        }

        let camera = Camera(name: name, ipAddress: ipAddress, rtspAddress: address)
        do {
            try cameraStore.add(camera)
            selectedCameraID = camera.id
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    func removeCamera(_ camera: Camera) -> String? {
        do {
            try cameraStore.remove(camera)
            if selectedCameraID == camera.id { selectedCameraID = nil }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
