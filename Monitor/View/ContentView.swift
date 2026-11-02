//
//  ContentView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import SwiftUI

private enum AppTab: Hashable {
    case home
    case settings
}

struct ContentView: View {
    @StateObject private var cameraStore: CameraStore
    @StateObject private var homeViewModel: CameraViewModel
    @StateObject private var settingsViewModel: CameraSettingsViewModel
    @State private var selectedTab: AppTab = .home

    init() {
        let store = CameraStore(repository: KeychainCameraRepository())
        _cameraStore = StateObject(wrappedValue: store)
        _homeViewModel = StateObject(wrappedValue: CameraViewModel(cameraStore: store))
        _settingsViewModel = StateObject(wrappedValue: CameraSettingsViewModel(cameraStore: store))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel) {
                selectedTab = .settings
            }
            .tabItem {
                Label("Início", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(AppColors.primary)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.regularMaterial, for: .tabBar)
        .task { cameraStore.load() }
    }
}

private struct HomeView: View {
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

private struct CameraRow: View {
    let camera: Camera
    let isSelected: Bool
    let playbackState: VLCPlaybackService.State
    let action: () -> Void

    private var status: (title: String, isLive: Bool, isError: Bool) {
        guard isSelected else { return ("Parada", false, false) }
        switch playbackState {
        case .connecting: return ("Conectando", false, false)
        case .playing: return ("Ao vivo", true, false)
        case .failed: return ("Falha", false, true)
        case .idle: return ("Pronta", false, false)
        }
    }

    var body: some View {
        Button(action: action) {
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

                Spacer(minLength: 5)

                HStack(spacing: 5) {
                    if status.isLive {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 6, height: 6)
                    }
                    Text(status.title)
                        .font(.caption2.weight(status.isLive ? .semibold : .regular))
                }
                .foregroundStyle(status.isError ? Color.red : (status.isLive ? AppColors.primary : AppColors.secondaryText))

                if !isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.secondaryText.opacity(0.65))
                }
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
        .accessibilityLabel("\(camera.name), \(camera.ipAddress), \(status.title)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    ContentView()
}
