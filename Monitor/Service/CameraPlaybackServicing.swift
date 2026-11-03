//
//  CameraPlaybackServicing.swift
//  Monitor
//
//  Created by Jonattan Sousa on 03/11/26.
//

import Combine
import UIKit

/// Playback operations needed by the camera ViewModels and player view.
protocol CameraPlaybackServicing: AnyObject {
    var state: VLCPlaybackService.State { get }
    var statePublisher: AnyPublisher<VLCPlaybackService.State, Never> { get }

    func attach(to view: UIView)
    func detach(from view: UIView)
    func play(url: String)
    func stop()
}
