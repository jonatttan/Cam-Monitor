//
//  VLCPlayerView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import SwiftUI
import VLCKit

struct VLCPlayerView: UIViewRepresentable {
    let playbackService: CameraPlaybackServicing

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        playbackService.attach(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        playbackService.attach(to: uiView)
    }

    func makeCoordinator() -> PlayerViewCoordinator {
        PlayerViewCoordinator(playbackService: playbackService)
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: PlayerViewCoordinator) {
        coordinator.playbackService.detach(from: uiView)
    }
}

final class PlayerViewCoordinator {
    let playbackService: CameraPlaybackServicing

    init(playbackService: CameraPlaybackServicing) {
        self.playbackService = playbackService
    }
}
