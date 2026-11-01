//
//  Coordinator.swift
//  Monitor
//
//  Created by Jonattan Sousa on 25/10/26.
//

import VLCKit
import SwiftUI

class Coordinator: NSObject, VLCMediaPlayerDelegate {
    var player: VLCMediaPlayer?
    weak var view: UIView?
    private var showLoading: Binding<Bool>
    private var firstFrameTask: Task<Void, Never>?
    
    init(showLoading: Binding<Bool>) {
        self.showLoading = showLoading
    }
    
    func mediaPlayerStateChanged(_ newState: VLCMediaPlayerState) {
        guard let player else { return }
        
        switch player.state {
        case .nothingSpecial, .opening:
            break
                  
        case .playing:
            waitForFirstDecodedFrame()
            print("[VLC] is playing")
            
        case .stopped, .stopping, .error:
            firstFrameTask?.cancel()
            print("[VLC] stopped, .error")
                  
        @unknown default:
            break
        }
    }

    private func waitForFirstDecodedFrame() {
        firstFrameTask?.cancel()
        
        firstFrameTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                if (self.player?.media?.statistics.decodedVideo ?? 0) > 0 {
                    self.showLoading.wrappedValue = false
                    return
                }
                
                try? await Task.sleep(nanoseconds: 16_000_000)
            }
        }
    }
}
