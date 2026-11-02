import Foundation

struct Camera: Identifiable, Equatable {
    let id: String
    let name: String
    let ipAddress: String
    let streamURL: String

    static let previewCamera = Camera(
        id: "yoosee-main",
        name: "Sala de estar",
        ipAddress: "192.168.2.112",
        streamURL: "rtsp://admin:passcode321@192.168.2.112:554/onvif1"
    )
}
