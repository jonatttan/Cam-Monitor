//
//  ContentView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 07/04/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    let streamURL = "rtsp://admin:passcode321@192.168.2.112:554/onvif1"
    
    var body: some View {
        ZStack {
            VLCPlayerView(url: streamURL, showLoading: $isLoading)
                .opacity(isLoading ? 0 : 1)
                .animation(.easeIn(duration: 0.25), value: isLoading)
                .ignoresSafeArea()
                .overlay {
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Conectando à câmera...")
                                .font(.title)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.35))
                        .transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.5), value: isLoading)
        }
    }
}

#Preview {
    ContentView()
}
