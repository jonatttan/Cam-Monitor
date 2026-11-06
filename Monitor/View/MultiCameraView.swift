//
//  MultiCameraView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 06/11/26.
//

import SwiftUI
import UIKit

struct MultiCameraView: View {
    @StateObject private var viewModel: MultiCameraViewModel

    init(cameraStore: CameraStore) {
        _viewModel = StateObject(wrappedValue: MultiCameraViewModel(cameraStore: cameraStore))
    }

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 10) {
                cameraPicker.frame(height: 40)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(viewModel.selectedCameraIDs, id: \.self) { id in
                        if let camera = viewModel.cameras.first(where: { $0.id == id }),
                           let service = viewModel.service(for: id) {
                            CameraFeedTile(
                                camera: camera,
                                service: service,
                                state: viewModel.playbackStates[id] ?? .connecting,
                                onRemove: { viewModel.toggle(camera) }
                            )
                            .frame(height: max(80, (geometry.size.height - 84) / 2))
                            .id(id)
                        }
                    }

                    ForEach(0..<max(0, MultiCameraViewModel.maximumCameraCount - viewModel.selectedCameraIDs.count), id: \.self) { _ in
                        EmptyFeedTile()
                            .frame(height: max(80, (geometry.size.height - 84) / 2))
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .padding(12)
            .background(AppColors.background.ignoresSafeArea())
        }
        .onAppear {
            OrientationController.request(.landscape)
            viewModel.resumeSelectedCameras()
        }
        .onDisappear {
            viewModel.stopAll()
            OrientationController.request(.portrait)
        }
    }

    private var cameraPicker: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ao vivo")
                    .font(.headline.weight(.bold))
                Text("\(viewModel.selectedCameraIDs.count)/4 câmeras")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .fixedSize()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.cameras) { camera in
                        let isSelected = viewModel.selectedCameraIDs.contains(camera.id)
                        Button {
                            viewModel.toggle(camera)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "video.fill")
                                Text(camera.name).lineLimit(1)
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? .white : AppColors.primary)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 9)
                            .background(isSelected ? AppColors.primary : AppColors.surface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(!isSelected && viewModel.selectedCameraIDs.count == MultiCameraViewModel.maximumCameraCount)
                        .opacity(!isSelected && viewModel.selectedCameraIDs.count == MultiCameraViewModel.maximumCameraCount ? 0.45 : 1)
                        .accessibilityLabel("\(isSelected ? "Remover" : "Reproduzir") \(camera.name)")
                    }
                }
            }
        }
    }
}

private struct CameraFeedTile: View {
    let camera: Camera
    let service: CameraPlaybackServicing
    let state: VLCPlaybackService.State
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            Color.black
            VLCPlayerView(playbackService: service)
                .opacity(state == .playing ? 1 : 0)
                .animation(.easeIn(duration: 0.2), value: state == .playing)
                .allowsHitTesting(false)

            if state != .playing {
                VStack(spacing: 7) {
                    if state == .failed {
                        Image(systemName: "wifi.exclamationmark")
                    } else {
                        ProgressView().tint(.white)
                    }
                    Text(state == .failed ? "Falha na conexão" : "Conectando…")
                        .font(.caption)
                }
                .foregroundStyle(.white)
            }

            HStack(spacing: 6) {
                Text(camera.name)
                    .lineLimit(1)
                    .font(.caption.weight(.semibold))
                Spacer(minLength: 2)
                if state == .playing {
                    Circle().fill(AppColors.primary).frame(width: 6, height: 6)
                    Text("AO VIVO").font(.system(size: 9, weight: .bold))
                }
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .accessibilityLabel("Parar \(camera.name)")
            }
            .foregroundStyle(.white)
            .padding(9)
            .background(.black.opacity(0.55))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

private struct EmptyFeedTile: View {
    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: "plus.viewfinder")
                .font(.title2)
            Text("Escolha uma câmera acima")
                .font(.caption)
        }
        .foregroundStyle(AppColors.secondaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private enum OrientationController {
    static func request(_ orientation: UIInterfaceOrientationMask) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation)) { error in
            print("Falha ao alterar orientação: \(error.localizedDescription)")
        }
    }
}

#Preview {
    Text("Prévia indisponível sem CameraStore")
}
