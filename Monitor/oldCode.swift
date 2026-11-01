//
//  oldCode.swift
//  Monitor
//
//  Created by Jonattan Sousa on 14/10/26.
//

//
//  VLCPlayerView.swift
//  Monitor
//
//  Created by Jonattan Sousa on 07/04/26.
//

//import SwiftUI
//import MobileVLCKit
//import Foundation
//import Darwin.net
//
//struct VLCPlayerView: UIViewRepresentable {
//    let url: String
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: .zero)
//        view.backgroundColor = .black
//
//        // Opções RADICALMENTE diferentes - focadas em BAIXA LATÊNCIA
//        let options = [
//            // ===== CACHING MÍNIMO (problema principal!) =====
//            ":network-caching=100",         // 100ms em vez de 2000ms ⚡
//            ":live-caching=100",            // Mínimo possível
//            ":file-caching=100",
//
//            // ===== RTSP OTIMIZADO =====
//            ":rtsp-tcp",                    // TCP confiável
//            ":rtsp-user-agent=VLC/3.0.0",
//            ":rtsp-timeout=10000",          // Timeout maior para evitar retry
//
//            // ===== HARDWARE ACCELERATION =====
//            ":avcodec-hw=videotoolbox",     // Crítico para iPhone
//
//            // ===== LATÊNCIA =====
//            ":clock-jitter=0",
//            ":no-audio",
//
//            // ===== REMOVE PROBLEMAS =====
//            ":access-filter=http",
//            ":http-reconnect",              // Não reconectar automaticamente
//            ":drop-late-frames",            // DROP frames atrasados
//
//            // ===== BUFFER FRAME =====
//            ":vout-drop-late-frames",       // Descartar frames atrasados
//
//            // ===== NÃO pular frames (contra-intuitivo mas ajuda) =====
//            // REMOVER: ":skip-frames=4"
//        ]
//
//        guard let mediaPlayer = VLCMediaPlayer(options: options) else {
//            return view
//        }
//
//        mediaPlayer.delegate = context.coordinator
//
//        guard let urlObj = URL(string: url) else { return view }
//
//        let media = VLCMedia(url: urlObj)
//        mediaPlayer.media = media
//        mediaPlayer.drawable = view
//
//        // Velocidade normal (não mudar)
//        mediaPlayer.rate = 1.0
//
//        context.coordinator.player = mediaPlayer
//        context.coordinator.view = view
//
//        // Play imediato
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            mediaPlayer.play()
//        }
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        if let player = context.coordinator.player,
//           let currentURL = player.media?.url.absoluteString,
//           currentURL != url {
//            player.stop()
//            guard let newURL = URL(string: url) else { return }
//            player.media = VLCMedia(url: newURL)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                player.play()
//            }
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, VLCMediaPlayerDelegate {
//        var player: VLCMediaPlayer?
//        weak var view: UIView?
//        private var retryCount = 0
//        private let maxRetries = 1  // Reduzir para 1 retry
//
//        func mediaPlayerStateChanged(_ notification: Notification!) {
//            guard let player = player else { return }
//
//            switch player.state {
//            case .playing:
//                print("✅ Reproduzindo (latência reduzida)")
//                retryCount = 0
//
//            case .paused:
//                print("⏸ Pausado")
//
//            case .stopped:
//                print("⏹ Parado")
//
//            case .ended:
//                print("✓ Finalizado")
//
//            case .error:
//                print("❌ Erro na reprodução - \(String(describing: player.media?.url))")
//                handleConnectionError(player)
//
//            case .esAdded:
//                print("📡 ES adicionado")
//
//            @unknown default:
//                break
//            }
//        }
//
//        private func handleConnectionError(_ player: VLCMediaPlayer) {
//            if retryCount < maxRetries {
//                retryCount += 1
//                print("🔄 Tentando reconectar... (\(retryCount)/\(maxRetries))")
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                    player.stop()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        player.play()
//                    }
//                }
//            } else {
//                print("❌ Falha ao conectar")
//                retryCount = 0
//            }
//        }
//    }
//}

////////
///
//import SwiftUI
//import MobileVLCKit
//
//import Network
//import Foundation
////import Darwin.net.if_var
//
//struct VLCPlayerView: UIViewRepresentable {
//    let url: String
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: .zero)
//        view.backgroundColor = .black
//
//        // Obter o IP local do iPhone
//        let localIP = getLocalIPAddress()
//        print("📱 IP Local detectado: \(localIP ?? "não encontrado")")
//
//        // Opções otimizadas com força de interface de rede
//        var options = [
//            ":network-caching=300",
//            ":rtsp-tcp",
//            ":no-audio"
////            ":network-caching=2000",
////            ":live-caching=2000",
////            ":file-caching=2000",
////            ":rtsp-tcp",
////            ":rtsp-user-agent=VLC/3.0.0",
////            ":rtsp-timeout=5000",
////            ":avcodec-hw=videotoolbox",
////            ":clock-jitter=0",
////            ":no-audio",
////            ":skip-frames=4",
////            ":access-filter=http",
////            ":http-reconnect",
////            ":mms-timeout=5000",
//        ]
//
//        // Forçar interface de rede se conseguir o IP local
//        if let ip = localIP {
//            options.append(":miface=\(ip)")
//            print("🔗 Interface de rede forçada: \(ip)")
//        }
//
//        guard let mediaPlayer = VLCMediaPlayer(options: options) else {
//            return view
//        }
//        mediaPlayer.delegate = context.coordinator
//
//        guard let urlObj = URL(string: url) else { return view }
//
//        let media = VLCMedia(url: urlObj)
//        mediaPlayer.media = media
//        mediaPlayer.drawable = view
//
//        context.coordinator.player = mediaPlayer
//        context.coordinator.view = view
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            mediaPlayer.play()
//        }
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        if let player = context.coordinator.player,
//           let currentURL = player.media?.url.absoluteString,
//           currentURL != url {
//            player.stop()
//            guard let newURL = URL(string: url) else { return }
//            player.media = VLCMedia(url: newURL)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                player.play()
//            }
//        }
//    }
//
//    // FUNÇÃO ESSENCIAL: Obter IP local do iPhone
//    private func getLocalIPAddress() -> String? {
//        var address: String?
//        var ifaddr: UnsafeMutablePointer<ifaddrs>?
//
//        if getifaddrs(&ifaddr) == 0 {
//            var ptr = ifaddr
//
//            while ptr != nil {
//                defer { ptr = ptr?.pointee.ifa_next }
//
//                let interface = ptr!.pointee
//                let addrFamily = interface.ifa_addr.pointee.sa_family
//
//                // Procurar por IPv4 (AF_INET)
//                if addrFamily == sa_family_t(AF_INET) {
//                    // Converter flags para UInt32 para evitar erro de tipo
//                    let flags = UInt32(interface.ifa_flags)
//
//                    // Verificar se é uma interface válida (não loopback)
//                    if (flags & UInt32(IFF_UP)) != 0 &&
//                       (flags & UInt32(IFF_RUNNING)) != 0 &&
//                       (flags & UInt32(IFF_LOOPBACK)) == 0 {
//
//                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
//                        getnameinfo(
//                            interface.ifa_addr,
//                            socklen_t(interface.ifa_addr.pointee.sa_len),
//                            &hostname,
//                            socklen_t(hostname.count),
//                            nil,
//                            0,
//                            NI_NUMERICHOST
//                        )
//
//                        address = String(cString: hostname)
//                        let interfaceName = String(cString: interface.ifa_name)
//                        print("✅ Interface encontrada: \(interfaceName) -> \(address ?? "?")")
//
//                        // Preferir WiFi (en0) em vez de cellular
//                        if interfaceName == "en0" {
//                            break
//                        }
//                    }
//                }
//            }
//
//            freeifaddrs(ifaddr)
//        }
//
//        return address
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, VLCMediaPlayerDelegate {
//        var player: VLCMediaPlayer?
//        weak var view: UIView?
//        private var retryCount = 0
//        private let maxRetries = 3
//
//        func mediaPlayerStateChanged(_ notification: Notification!) {
//            guard let player = player else { return }
//
//            switch player.state {
//            case .playing:
//                print("✅ Reproduzindo com sucesso!")
//                retryCount = 0
//
//            case .paused:
//                print("⏸ Pausado")
//
//            case .stopped:
//                print("⏹ Parado")
//
//            case .ended:
//                print("✓ Finalizado")
//
//            case .error:
//                print("❌ Erro na reprodução")
//                handleConnectionError(player)
//
//            case .esAdded:
//                print("📡 ES adicionado")
//
//            @unknown default:
//                break
//            }
//        }
//
//        private func handleConnectionError(_ player: VLCMediaPlayer) {
//            if retryCount < maxRetries {
//                retryCount += 1
//                print("🔄 Tentando reconectar... (\(retryCount)/\(maxRetries))")
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                    player.stop()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        player.play()
//                    }
//                }
//            } else {
//                print("❌ Falha ao conectar após \(maxRetries) tentativas")
//                retryCount = 0
//            }
//        }
//    }
//}

//////

//struct VLCPlayerView: UIViewRepresentable {
//    let url: String
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView(frame: .zero)
//        view.backgroundColor = .black
//
//        // Opções otimizadas especificamente para ONVIF/RTSP em iPhone
//        let options = [
//            // Caching
//            ":network-caching=2000",        // 2 segundos (RTSP é lento)
//            ":live-caching=2000",           // Reduz latência
//            ":file-caching=2000",
//
//            // RTSP específico
//            ":rtsp-tcp",                    // TCP é mais confiável que UDP
//            ":rtsp-user-agent=VLC/3.0.0",  // Evita bloqueios de user-agent
//            ":rtsp-timeout=5000",           // 5 segundos de timeout
//
//            // Decodificação otimizada
//            ":avcodec-hw=videotoolbox",     // Aceleração de hardware (importante!)
//            ":codec=h264,hevc",             // Suporte H.264 e H.265
//
//            // Performance
//            ":clock-jitter=0",              // Remove jitter
//            ":audio-resampler=native",      // Desabilita resampling
//
//            // Desabilitar áudio
//            ":no-audio",
//
//            // Buffer otimizado para low-latency
//            ":demux=adaptive",
//            ":skip-frames=4",               // Pula frames se necessário
//        ]
//
//        guard let mediaPlayer = VLCMediaPlayer(options: options) else {
//            return view
//        }
//        mediaPlayer.delegate = context.coordinator
//
//        guard let urlObj = URL(string: url) else { return view }
//
//        // Importante: não duplicar opções aqui
//        let media = VLCMedia(url: urlObj)
//        mediaPlayer.media = media
//        mediaPlayer.drawable = view
//
//        // Configurar scaling e rendering
//        mediaPlayer.scaleFactor = 0.0  // Auto-scale
////        mediaPlayer.videoAspectRatio = "16:9"
//        let aspectRatio = "16:9"
//        aspectRatio.withCString { cString in
//            mediaPlayer.videoAspectRatio = UnsafeMutablePointer(mutating: cString)
//        }
//
//        context.coordinator.player = mediaPlayer
//        context.coordinator.view = view
//
//        // Pequeno delay antes de play
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            mediaPlayer.play()
//        }
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {
//        // Se a URL muda, recarregar
//        if let player = context.coordinator.player,
//           let currentURL = player.media?.url.absoluteString,
//           currentURL != url {
//            player.stop()
//            guard let newURL = URL(string: url) else { return }
//            player.media = VLCMedia(url: newURL)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                player.play()
//            }
//        }
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, VLCMediaPlayerDelegate {
//        var player: VLCMediaPlayer?
//        weak var view: UIView?
//        private var retryCount = 0
//        private let maxRetries = 3
//
//        func mediaPlayerStateChanged(_ notification: Notification!) {
//            guard let player = player else { return }
//
//            switch player.state {
//            case .playing:
//                print("✅ Reproduzindo - FPS: \(player.framesPerSecond)")
//                retryCount = 0
//
//            case .paused:
//                print("⏸ Pausado")
//
//            case .stopped:
//                print("⏹ Parado")
//
//            case .ended:
//                print("✓ Finalizado")
//
//            case .error:
//                print("❌ Erro na reprodução")
//                handleConnectionError(player)
//
//            case .esAdded:
//                print("📡 ES adicionado")
//
//            @unknown default:
//                break
//            }
//        }
//
//        private func handleConnectionError(_ player: VLCMediaPlayer) {
//            if retryCount < maxRetries {
//                retryCount += 1
//                print("🔄 Tentando reconectar... (\(retryCount)/\(maxRetries))")
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                    player.stop()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        player.play()
//                    }
//                }
//            } else {
//                print("❌ Falha ao conectar após \(maxRetries) tentativas")
//                retryCount = 0
//            }
//        }
//    }
//}

//////////

//struct VLCPlayerView: UIViewRepresentable {
//    let url: String
//
//    func makeUIView(context: Context) -> some UIView {
//        let view = UIView(frame: .zero)
//        view.backgroundColor = .black
//
//        guard let mediaPlayer = VLCMediaPlayer(options: [
////            ":network-caching=1000",      // Aumentado para RTSP
//            ":rtsp-tcp",                   // TCP é mais confiável
//            ":no-audio",                   // Sem áudio como pedido
//            ":clock-jitter=0",             // Reduz jitter
//            ":file-caching=1000",
//            ":live-caching=1000",
//            ":rtsp-user-agent=VLC/3.0.0 (LIVE555 Streaming Media v2021.02.26)", //
//            ":network-caching=1500",
//            ":access-filter=http",
//            ":video-x264-preset=ultrafast",  // Se usar H.264
//            ":avcodec-hw=videotoolbox"      // Usar hardware acceleration
//        ]) else {
//            return view
//        }
//
//        // Configurar delegate ANTES de criar a media
//        mediaPlayer.delegate = context.coordinator
//
//        guard let url = URL(string: url) else { return view }
//
//        // Usar VLCMedia sem opções duplicadas
//        let media = VLCMedia(url: url)
//        mediaPlayer.media = media
//
//        // Importante: drawable DEVE ser a view criada aqui
//        mediaPlayer.drawable = view
//
//        // Armazenar referências fortes
//        context.coordinator.player = mediaPlayer
//        context.coordinator.view = view
//
//        // Iniciar com pequeno delay para garantir setup correto
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            mediaPlayer.play()
//        }
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIViewType, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject, VLCMediaPlayerDelegate {
//        var player: VLCMediaPlayer?
//        weak var view: UIView?
//
//        func mediaPlayerStateChanged(_ notification: Notification!) {
//            guard let player = player else { return }
//
//            switch player.state {
//            case .playing:
//                print("✅ Reproduzindo")
//            case .paused:
//                print("⏸ Pausado")
//            case .stopped:
//                print("⏹ Parado")
//            case .ended:
//                print("✓ Finalizado")
//            case .error:
//                print("❌ Erro: \(player.media?.description ?? "desconhecido")")
//                // Tentar reconectar
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    player.play()
//                }
//            case .esAdded:
//                print("ES selecionado")
//            case .opening:
//                print("Opening")
//            case .buffering:
//                print("buffering")
//            @unknown default:
//                break
//            }
//        }
//    }
//}

////////////


////////////

//import SwiftUI
//import MobileVLCKit
//
//struct VLCPlayerView: UIViewRepresentable {
//    let url: String
//
//    func makeUIView(context: Context) -> some UIView {
//        let view = UIView(frame: .zero)
//
//        let mediaPlayer = VLCMediaPlayer()
//        #warning("Solve force unwrap")
//        let media = VLCMedia(url: URL(string: url)!)
//
//        media.addOption(":network-caching=100")
//        media.addOption(":rtsp-tcp")
//        media.addOption(":no-audio")
//        mediaPlayer.media = media
//        mediaPlayer.drawable = view
//
//        mediaPlayer.play()
//
//        context.coordinator.player = mediaPlayer
//        context.coordinator.view = view
//
//        return view
//    }
//
////    func updadeUIView(_ uiView: UIView, context: Context) {}
//    func updateUIView(_ uiView: UIViewType, context: Context) {}
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
//
//    class Coordinator: NSObject {
//        var player: VLCMediaPlayer?
//        weak var view: UIView?
//    }
//}

