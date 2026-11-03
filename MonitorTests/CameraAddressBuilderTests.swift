//
//  CameraAddressBuilderTests.swift
//  MonitorTests
//
//  Created by Jonattan Sousa on 02/11/26.
//

import Foundation
import XCTest
@testable import Monitor

final class CameraAddressBuilderTests: XCTestCase {
    func testIsValidIPv4AcceptsTypicalAddress() {
        XCTAssertTrue(CameraAddressBuilder.isValidIPv4("192.168.2.112"))
    }

    func testIsValidIPv4AcceptsOctetBoundaries() {
        XCTAssertTrue(CameraAddressBuilder.isValidIPv4("0.0.0.0"))
        XCTAssertTrue(CameraAddressBuilder.isValidIPv4("255.255.255.255"))
    }

    func testIsValidIPv4RejectsIncorrectOctetCount() {
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4("192.168.2"))
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4("192.168.2.112.5"))
    }

    func testIsValidIPv4RejectsOctetsOutsideRange() {
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4("256.168.2.112"))
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4("192.168.-1.112"))
    }

    func testIsValidIPv4RejectsNonnumericAndEmptyOctets() {
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4("192.168.a.112"))
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4("192..2.112"))
        XCTAssertFalse(CameraAddressBuilder.isValidIPv4(""))
    }

    func testMakeRTSPAddressBuildsExpectedCameraAddress() {
        let address = CameraAddressBuilder.makeRTSPAddress(
            ipAddress: "192.168.2.112",
            username: "admin",
            password: "example-password"
        )

        XCTAssertEqual(address, "rtsp://admin:example-password@192.168.2.112:554/onvif1")
    }

    func testMakeRTSPAddressPreservesReservedCharactersInCredentials() throws {
        let username = "operator@local"
        let password = "secret:/@%?#"
        let address = try XCTUnwrap(
            CameraAddressBuilder.makeRTSPAddress(
                ipAddress: "192.168.2.112",
                username: username,
                password: password
            )
        )
        let components = try XCTUnwrap(URLComponents(string: address))

        XCTAssertEqual(components.scheme, "rtsp")
        XCTAssertEqual(components.user, username)
        XCTAssertEqual(components.password, password)
        XCTAssertEqual(components.host, "192.168.2.112")
        XCTAssertEqual(components.port, 554)
        XCTAssertEqual(components.path, "/onvif1")
    }

    func testMakeRTSPAddressReturnsNilForInvalidIPv4() {
        XCTAssertNil(
            CameraAddressBuilder.makeRTSPAddress(
                ipAddress: "192.168.2.256",
                username: "admin",
                password: "example-password"
            )
        )
    }
}
