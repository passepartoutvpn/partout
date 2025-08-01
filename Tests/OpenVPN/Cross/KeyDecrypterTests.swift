// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable internal import PartoutOpenVPNCross
import Foundation
import Testing

struct KeyDecrypterTests {
    @Test
    func givenPKCS1_whenParse_thenFails() throws {
        let sut = newDecrypter()
        let path = try path(withName: "tunnelbear.enc.1.key")
        do {
            _ = try sut.decryptedKey(fromPath: path, passphrase: "")
            #expect(Bool(false))
        } catch {
            //
        }
    }

    @Test
    func givenPKCS1_whenParseWithPassphrase_thenSucceeds() throws {
        let sut = newDecrypter()
        let expected = try String(contentsOfFile: path(withName: "tunnelbear.key"))
        let path = try path(withName: "tunnelbear.enc.1.key")
        let pem = try sut.decryptedKey(fromPath: path, passphrase: "foobar")
        #expect(pem == expected)
    }

    @Test
    func givenPKCS8_whenParse_thenFails() throws {
        let sut = newDecrypter()
        let path = try path(withName: "tunnelbear.enc.8.key")
        do {
            _ = try sut.decryptedKey(fromPath: path, passphrase: "")
            #expect(Bool(false))
        } catch {
            //
        }
    }

    @Test
    func givenPKCS8_whenParseWithPassphrase_thenSucceeds() throws {
        let sut = newDecrypter()
        let expected = try String(contentsOfFile: path(withName: "tunnelbear.key"))
        let path = try path(withName: "tunnelbear.enc.8.key")
        let pem = try sut.decryptedKey(fromPath: path, passphrase: "foobar")
        #expect(pem == expected)
    }
}

private extension KeyDecrypterTests {
    func newDecrypter() -> OSSLKeyDecrypter {
        OSSLKeyDecrypter()
    }

    func path(withName name: String) throws -> String {
        try #require(Bundle.module.path(forResource: name, ofType: nil))
    }
}
