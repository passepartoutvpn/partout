// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import PartoutOpenVPN
internal import _PartoutOpenVPNLegacy_ObjC
import XCTest

final class StandardOpenVPNOpenSSLParserTests: XCTestCase {
    func test_givenPKCS1_whenParse_thenFails() {
        let sut = newParser()
        let cfgURL = url(withName: "tunnelbear.enc.1")
        XCTAssertThrowsError(try sut.parsed(fromURL: cfgURL))
    }

    func test_givenPKCS1_whenParseWithPassphrase_thenSucceeds() {
        let sut = newParser()
        let cfgURL = url(withName: "tunnelbear.enc.1")
        XCTAssertNoThrow(try sut.parsed(fromURL: cfgURL, passphrase: "foobar"))
    }

    func test_givenPKCS8_whenParse_thenFails() {
        let sut = newParser()
        let cfgURL = url(withName: "tunnelbear.enc.8")
        XCTAssertThrowsError(try sut.parsed(fromURL: cfgURL))
    }

    func test_givenPKCS8_whenParseWithPassphrase_thenSucceeds() {
        let sut = newParser()
        let cfgURL = url(withName: "tunnelbear.enc.8")
        XCTAssertThrowsError(try sut.parsed(fromURL: cfgURL))
        XCTAssertNoThrow(try sut.parsed(fromURL: cfgURL, passphrase: "foobar"))
    }
}

private extension StandardOpenVPNOpenSSLParserTests {
    func newParser() -> StandardOpenVPNParser {
        StandardOpenVPNParser(decrypter: OSSLTLSBox())
    }

    func url(withName name: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: "ovpn")!
    }
}
