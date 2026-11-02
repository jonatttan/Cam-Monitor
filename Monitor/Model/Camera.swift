//
//  Camera.swift
//  Monitor
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Foundation

struct Camera: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let ipAddress: String
    /// Full RTSP address, including credentials. Persisted in Keychain by CameraRepository.
    let rtspAddress: String

    init(id: UUID = UUID(), name: String, ipAddress: String, rtspAddress: String) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.rtspAddress = rtspAddress
    }
}

enum CameraAddressBuilder {
    static func makeRTSPAddress(ipAddress: String, username: String, password: String) -> String? {
        guard isValidIPv4(ipAddress) else { return nil }

        var components = URLComponents()
        components.scheme = "rtsp"
        components.user = username
        components.password = password
        components.host = ipAddress
        components.port = 554
        components.path = "/onvif1"
        return components.url?.absoluteString
    }

    static func isValidIPv4(_ address: String) -> Bool {
        let octets = address.split(separator: ".", omittingEmptySubsequences: false)
        guard octets.count == 4 else { return false }
        return octets.allSatisfy { octet in
            guard !octet.isEmpty,
                  octet.allSatisfy(\.isNumber),
                  let value = Int(octet) else { return false }
            return (0...255).contains(value)
        }
    }
}
