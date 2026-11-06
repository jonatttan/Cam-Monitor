//
//  CameraRow.swift
//  Monitor
//
//  Created by Jonattan Sousa on 06/11/26.
//

import SwiftUI

struct CameraRow: View {
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
