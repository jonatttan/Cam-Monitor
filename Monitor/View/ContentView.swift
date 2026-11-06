//
//  ContentView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import SwiftUI

private enum AppTab: Hashable {
    case home
    case multiCamera
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

            MultiCameraView(cameraStore: cameraStore)
                .tabItem {
                    Label("Ao vivo", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.multiCamera)

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

#Preview {
    ContentView()
}
