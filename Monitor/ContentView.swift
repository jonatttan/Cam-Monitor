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
            VLCPlayerView(url: streamURL)
                .ignoresSafeArea()
            
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Conectando à câmera...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.5))
                .onReceive(Timer.publish(every: 5, on: .main, in: .common).autoconnect()) { _ in
                    isLoading = false
                }
            }
        }
    }
}

//////

//struct ContentView: View {
//    @State private var streamURL = "rtsp://admin:passcode321@192.168.2.107:554/onvif1"
//    @State private var isLoading = false
//    
//    var body: some View {
//        ZStack {
//            VLCPlayerView(url: streamURL)
//                .ignoresSafeArea()
//            
//            if isLoading {
//                VStack {
//                    ProgressView()
//                    Text("Conectando...")
//                        .foregroundColor(.white)
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .background(Color.black.opacity(0.3))
//            }
//        }
//    }
//}

////////

//struct ContentView: View {
//    let rtspURL = "rtsp://admin:passcode321@192.168.2.107:554/onvif1"
//    
//    var body: some View {
//        VStack {
//            VLCPlayerView(url: rtspURL)
//                .frame(height: 300)
//                .cornerRadius(12)
//        }
//        .padding()
//    }
//}

#Preview {
    ContentView()
}
