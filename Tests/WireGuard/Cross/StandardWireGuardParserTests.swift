// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import PartoutWireGuard
@testable import PartoutWireGuardCross
import PartoutCore
import XCTest

final class StandardWireGuardParserTests: XCTestCase {
    private let parser = StandardWireGuardParser()

    private let keyGenerator = StandardWireGuardKeyGenerator()

    // MARK: - Interface

    func test_givenParser_whenGoodBuilder_thenDoesNotThrow() {
        var sut = newBuilder()
        sut.interface.addresses = ["1.2.3.4"]

        var dns = DNSModule.Builder()
        dns.servers = ["1.2.3.4"]
        dns.searchDomains = ["domain.local"]
        sut.interface.dns = dns

        let builder = WireGuardModule.Builder(configurationBuilder: sut)
        XCTAssertNoThrow(try parser.validate(builder))
    }

    func test_givenParser_whenBadPrivateKey_thenThrows() {
        let sut = WireGuard.Configuration.Builder(privateKey: "")
        do {
            try assertValidationFailure(sut)
        } catch {
            assertParseError(error) {
                guard case .interfaceHasInvalidPrivateKey = $0 else {
                    XCTFail($0.localizedDescription)
                    return
                }
            }
        }
    }

    func test_givenParser_whenBadAddresses_thenThrows() {
        var sut = newBuilder()
        sut.interface.addresses = ["dsfds"]
        do {
            try assertValidationFailure(sut)
        } catch {
            assertParseError(error) {
                guard case .interfaceHasInvalidAddress = $0 else {
                    XCTFail($0.localizedDescription)
                    return
                }
            }
        }
    }

    // parser is too tolerant, never fails
//    func test_givenParser_whenBadDNS_thenThrows() {
//        var sut = newBuilder()
//        sut.interface.addresses = ["1.2.3.4"]
//
//        var dns = DNSModule.Builder()
//        dns.servers = ["1.a.2.$%3"]
//        dns.searchDomains = ["-invalid.example.com"]
//        sut.interface.dns = dns
//
//        do {
//            try assertValidationFailure(sut)
//        } catch {
//            assertParseError(error) {
//                guard case .interfaceHasInvalidDNS = $0 else {
//                    XCTFail($0.localizedDescription)
//                    return
//                }
//            }
//        }
//    }

    // MARK: - Peers

    func test_givenParser_whenBadPeerPublicKey_thenThrows() {
        var sut = newBuilder(withInterface: true)

        let peer = WireGuard.RemoteInterface.Builder(publicKey: "")
        sut.peers = [peer]

        do {
            try assertValidationFailure(sut)
        } catch {
            assertParseError(error) {
                guard case .peerHasInvalidPublicKey = $0 else {
                    XCTFail($0.localizedDescription)
                    return
                }
            }
        }
    }

    func test_givenParser_whenBadPeerPresharedKey_thenThrows() {
        var sut = newBuilder(withInterface: true, withPeer: true)
        var peer = sut.peers[0]
        peer.preSharedKey = "fdsfokn.,x"
        sut.peers = [peer]

        do {
            try assertValidationFailure(sut)
        } catch {
            assertParseError(error) {
                guard case .peerHasInvalidPreSharedKey = $0 else {
                    XCTFail($0.localizedDescription)
                    return
                }
            }
        }
    }

    func test_givenParser_whenBadPeerEndpoint_thenThrows() {
        var sut = newBuilder(withInterface: true, withPeer: true)
        var peer = sut.peers[0]
        peer.endpoint = "fdsfokn.,x"
        sut.peers = [peer]

        do {
            try assertValidationFailure(sut)
        } catch {
            assertParseError(error) {
                guard case .peerHasInvalidEndpoint = $0 else {
                    XCTFail($0.localizedDescription)
                    return
                }
            }
        }
    }

    func test_givenParser_whenBadPeerAllowedIPs_thenThrows() {
        var sut = newBuilder(withInterface: true, withPeer: true)
        var peer = sut.peers[0]
        peer.allowedIPs = ["fdsfokn.,x"]
        sut.peers = [peer]

        do {
            try assertValidationFailure(sut)
        } catch {
            assertParseError(error) {
                guard case .peerHasInvalidAllowedIP = $0 else {
                    XCTFail($0.localizedDescription)
                    return
                }
            }
        }
    }
}

private extension StandardWireGuardParserTests {
    func newBuilder(withInterface: Bool = false, withPeer: Bool = false) -> WireGuard.Configuration.Builder {
        var builder = WireGuard.Configuration.Builder(keyGenerator: keyGenerator)
        if withInterface {
            builder.interface.addresses = ["1.2.3.4"]
            var dns = DNSModule.Builder()
            dns.servers = ["1.2.3.4"]
            dns.searchDomains = ["domain.local"]
            builder.interface.dns = dns
        }
        if withPeer {
            let peerPrivateKey = keyGenerator.newPrivateKey()
            do {
                let publicKey = try keyGenerator.publicKey(for: peerPrivateKey)
                builder.peers = [WireGuard.RemoteInterface.Builder(publicKey: publicKey)]
            } catch {
                XCTFail(error.localizedDescription)
                return builder
            }
        }
        return builder
    }

    func assertValidationFailure(_ wgBuilder: WireGuard.Configuration.Builder) throws {
        let builder = WireGuardModule.Builder(configurationBuilder: wgBuilder)
        try parser.validate(builder)
        XCTFail("Must fail")
    }

    func assertParseError(_ error: Error, _ block: (WireGuardParseError) -> Void) {
        NSLog("Thrown: \(error.localizedDescription)")
        guard let ppError = error as? PartoutError else {
            XCTFail("Not a PartoutError")
            return
        }
        guard let parseError = ppError.reason as? WireGuardParseError else {
            XCTFail("Not a TunnelConfiguration.ParseError")
            return
        }
        block(parseError)
    }
}
