//
//  VLCPlaybackService.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Combine
import Foundation
import UIKit
import VLCKit

/// Holds the single VLC player used by the app and publishes playback state to the UI.
final class VLCPlaybackService: NSObject, ObservableObject {
    enum State: Equatable {
        case idle
        case connecting
        case playing
        case failed
    }

    @Published private(set) var state: State = .idle

    let player = VLCMediaPlayer()
    private var firstFrameTask: Task<Void, Never>?
    private var activeURL: String?
    private weak var attachedView: UIView?

    override init() {
        super.init()
        player.delegate = self
    }

    func attach(to view: UIView) {
        attachedView = view
        player.drawable = view
    }

    func detach(from view: UIView) {
        guard attachedView === view else { return }
        attachedView = nil
        player.drawable = nil
    }

    func play(url: String) {
        guard activeURL != url || player.state == .stopped || player.state == .error else { return }
        stop()
        activeURL = url

        guard let mediaURL = URL(string: url), let media = VLCMedia(url: mediaURL) else {
            state = .failed
            return
        }

        media.addOption(":rtsp-tcp")
        media.addOption(":no-audio")
        player.media = media
        state = .connecting
        player.play()
    }

    func stop() {
        firstFrameTask?.cancel()
        firstFrameTask = nil
        if activeURL != nil {
            player.stop()
        }
        activeURL = nil
        state = .idle
    }

    private func waitForFirstDecodedFrame() {
        firstFrameTask?.cancel()
        firstFrameTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                if (self.player.media?.statistics.decodedVideo ?? 0) > 0 {
                    self.state = .playing
                    return
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
        }
    }
}

extension VLCPlaybackService: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        // Ignore a late callback from the previous media after a camera switch.
        guard newState == player.state else { return }

        switch newState {
        case .opening:
            Task { @MainActor [weak self] in self?.state = .connecting }
        case .playing:
            waitForFirstDecodedFrame()
        case .error:
            firstFrameTask?.cancel()
            Task { @MainActor [weak self] in self?.state = .failed }
        case .stopped, .stopping:
            firstFrameTask?.cancel()
            Task { @MainActor [weak self] in self?.state = .idle }
        case .nothingSpecial:
            break
        @unknown default:
            break
        }
    }
}
