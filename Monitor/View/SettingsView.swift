//
//  SettingsView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @ObservedObject var viewModel: CameraSettingsViewModel
    @State private var isAddingCamera = false
    @State private var cameraToRemove: Camera?
    @State private var alertMessage: String?
    @State private var copiedCameraID: Camera.ID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Câmeras cadastradas")
                        .font(.headline)
                        .padding(.top, 4)

                    if let message = viewModel.storageErrorMessage {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(message, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.red)
                            Button("Tentar novamente") {
                                viewModel.retryStorageAccess()
                            }
                            .font(.subheadline.weight(.semibold))
                            .tint(AppColors.primary)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    } else if viewModel.cameras.isEmpty {
                        ContentUnavailableView(
                            "Nenhuma câmera cadastrada",
                            systemImage: "video.badge.plus",
                            description: Text("Adicione uma câmera para começar a visualizar o stream.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    } else {
                        LazyVStack(spacing: 9) {
                            ForEach(viewModel.cameras) { camera in
                                cameraRow(camera)
                            }
                        }

                        if let camera = viewModel.selectedCamera {
                            cameraDetails(camera)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(AppColors.background.ignoresSafeArea())
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddingCamera = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .tint(AppColors.primary)
                    .disabled(!viewModel.isStorageReady)
                    .accessibilityLabel("Adicionar câmera")
                }
            }
            .sheet(isPresented: $isAddingCamera) {
                AddCameraSheet(viewModel: viewModel)
            }
            .confirmationDialog(
                "Remover \(cameraToRemove?.name ?? "câmera")?",
                isPresented: Binding(
                    get: { cameraToRemove != nil },
                    set: { if !$0 { cameraToRemove = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remover câmera", role: .destructive) {
                    guard let camera = cameraToRemove else { return }
                    alertMessage = viewModel.removeCamera(camera)
                    cameraToRemove = nil
                }
                Button("Cancelar", role: .cancel) { cameraToRemove = nil }
            } message: {
                Text("O nome e o endereço salvo no armazenamento seguro serão removidos.")
            }
            .alert("Não foi possível concluir", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func cameraRow(_ camera: Camera) -> some View {
        let isSelected = viewModel.selectedCameraID == camera.id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.select(camera)
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "video.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 42, height: 42)
                    .background(AppColors.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))

                VStack(alignment: .leading, spacing: 4) {
                    Text(camera.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(camera.ipAddress)
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()
                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(12)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppColors.primary, lineWidth: 1.5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func cameraDetails(_ camera: Camera) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Endereço RTSP")
                .font(.subheadline.weight(.semibold))

            Text(camera.rtspAddress)
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColors.background, in: RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = camera.rtspAddress
                    copiedCameraID = camera.id
                } label: {
                    Label(copiedCameraID == camera.id ? "Copiado" : "Copiar endereço", systemImage: copiedCameraID == camera.id ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.primary)

                Button(role: .destructive) {
                    cameraToRemove = camera
                } label: {
                    Label("Remover", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

private struct AddCameraSheet: View {
    @ObservedObject var viewModel: CameraSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var ipAddress = ""
    @State private var username = ""
    @State private var password = ""
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Identificação") {
                    TextField("Nome da câmera", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    TextField("Endereço IP", text: $ipAddress)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Acesso RTSP") {
                    TextField("Usuário", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Senha", text: $password)
                }

                Section {
                    Label("A URL completa e as credenciais serão guardadas no Keychain deste iPhone.", systemImage: "lock.shield")
                        .font(.footnote)
                        .foregroundStyle(AppColors.secondaryText)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Nova câmera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { saveCamera() }
                        .fontWeight(.semibold)
                        .tint(AppColors.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveCamera() {
        if let message = viewModel.addCamera(
            name: name,
            ipAddress: ipAddress,
            username: username,
            password: password
        ) {
            validationMessage = message
        } else {
            dismiss()
        }
    }
}

#Preview {
    SettingsView(viewModel: CameraSettingsViewModel(cameraStore: CameraStore(repository: KeychainCameraRepository())))
}
