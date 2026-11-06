//
//  HomeView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 06/11/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: CameraViewModel
    let onAddCamera: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                playerSection
                cameraListSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .onAppear(perform: viewModel.startInitialCameraIfNeeded)
        .onChange(of: viewModel.cameras) { _, _ in
            viewModel.startInitialCameraIfNeeded()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "video.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text("Cam Monitor")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                Text("Suas câmeras em tempo real")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            Button(action: onAddCamera) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 42, height: 42)
                    .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 14))
            }
            .accessibilityLabel("Adicionar câmera")
        }
        .padding(.bottom, 2)
    }

    private var playerSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Câmera ativa")
                    .font(.headline)
                Spacer()
                if let camera = viewModel.selectedCamera {
                    Text(camera.name)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                        .lineLimit(1)
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 23)
                    .fill(Color.black)

                if viewModel.selectedCamera != nil {
                    VLCPlayerView(playbackService: viewModel.playbackService)
                        .opacity(viewModel.isLoading || viewModel.hasPlaybackError ? 0 : 1)
                        .animation(.easeIn(duration: 0.25), value: viewModel.isLoading || viewModel.hasPlaybackError)

                    if viewModel.isLoading || viewModel.hasPlaybackError {
                        VStack(spacing: 12) {
                            if viewModel.hasPlaybackError {
                                Image(systemName: "wifi.exclamationmark")
                                    .font(.system(size: 24))
                            } else {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(viewModel.hasPlaybackError ? "Não foi possível conectar" : "Conectando à câmera...")
                                .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.38))
                        .transition(.opacity)
                    }

                    if viewModel.playbackState == .playing {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("AO VIVO")
                                .font(.caption2.weight(.bold))
                                .tracking(0.5)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 9))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(12)
                    }
                } else {
                    ContentUnavailableView(
                        "Nenhuma câmera",
                        systemImage: "video.slash",
                        description: Text("Cadastre uma câmera nos Ajustes para começar.")
                    )
                    .foregroundStyle(.white)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        }
    }

    private var cameraListSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text("Suas câmeras")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.cameras.count) \(viewModel.cameras.count == 1 ? "câmera" : "câmeras")")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }

            LazyVStack(spacing: 9) {
                ForEach(viewModel.cameras) { camera in
                    CameraRow(
                        camera: camera,
                        isSelected: camera.id == viewModel.selectedCameraID,
                        playbackState: viewModel.playbackState
                    ) {
                        viewModel.selectCamera(camera)
                    }
                }
            }
        }
    }
}
