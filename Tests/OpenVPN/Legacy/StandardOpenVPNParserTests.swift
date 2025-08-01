// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import PartoutOpenVPN
@testable internal import PartoutOpenVPNLegacy
import PartoutCore
import XCTest

final class StandardOpenVPNParserTests: XCTestCase {
    private let parser = StandardOpenVPNParser()

    func test_givenOption_whenEnumerateComponents_thenAreParsedCorrectly() throws {
        let sut = try OpenVPN.Option.remote.regularExpression()
        _ = sut.enumerateSpacedComponents(in: "remote    one.two.com   12345   tcp") {
            XCTAssertEqual($0, ["remote", "one.two.com", "12345", "tcp"])
        }
    }

    // MARK: Lines

    func test_givenLZO_whenParse_thenIsHandled() throws {
        XCTAssertNil(try parser.parsed(fromLines: ["comp-lzo"]).warning)
        XCTAssertNoThrow(try parser.parsed(fromLines: ["comp-lzo no"]))
        XCTAssertNoThrow(try parser.parsed(fromLines: ["comp-lzo yes"]))

        XCTAssertNoThrow(try parser.parsed(fromLines: ["compress"]))
        XCTAssertNoThrow(try parser.parsed(fromLines: ["compress lzo"]))
    }

    func test_givenKeepAlive_whenParse_thenIsHandled() throws {
        let cfg1 = try parser.parsed(fromLines: ["ping 10", "ping-restart 60"])
        let cfg2 = try parser.parsed(fromLines: ["keepalive 10 60"])
        let cfg3 = try parser.parsed(fromLines: ["keepalive 15 600"])
        XCTAssertEqual(cfg1.configuration.keepAliveInterval, cfg2.configuration.keepAliveInterval)
        XCTAssertEqual(cfg1.configuration.keepAliveTimeout, cfg2.configuration.keepAliveTimeout)
        XCTAssertNotEqual(cfg1.configuration.keepAliveInterval, cfg3.configuration.keepAliveInterval)
        XCTAssertNotEqual(cfg1.configuration.keepAliveTimeout, cfg3.configuration.keepAliveTimeout)
    }

    func test_givenDHCPOption_whenParse_thenIsHandled() throws {
        let lines = [
            "dhcp-option DNS 8.8.8.8",
            "dhcp-option DNS6 ffff::1",
            "dhcp-option DOMAIN first-domain.net",
            "dhcp-option DOMAIN second-domain.org",
            "dhcp-option DOMAIN-SEARCH fake-main.net",
            "dhcp-option DOMAIN-SEARCH main.net",
            "dhcp-option DOMAIN-SEARCH one.com",
            "dhcp-option DOMAIN-SEARCH two.com",
            "dhcp-option PROXY_HTTP 1.2.3.4 8081",
            "dhcp-option PROXY_HTTPS 7.8.9.10 8082",
            "dhcp-option PROXY_AUTO_CONFIG_URL https://pac/",
            "dhcp-option PROXY_BYPASS   foo.com   bar.org     net.chat"
        ]
        XCTAssertNoThrow(try parser.parsed(fromLines: lines))

        let parsed = try parser.parsed(fromLines: lines).configuration
        XCTAssertEqual(parsed.dnsServers, ["8.8.8.8", "ffff::1"])
        XCTAssertEqual(parsed.dnsDomain, "second-domain.org")
        XCTAssertEqual(parsed.searchDomains, ["fake-main.net", "main.net", "one.com", "two.com"])
        XCTAssertEqual(parsed.httpProxy?.address.rawValue, "1.2.3.4")
        XCTAssertEqual(parsed.httpProxy?.port, 8081)
        XCTAssertEqual(parsed.httpsProxy?.address.rawValue, "7.8.9.10")
        XCTAssertEqual(parsed.httpsProxy?.port, 8082)
        XCTAssertEqual(parsed.proxyAutoConfigurationURL?.absoluteString, "https://pac/")
        XCTAssertEqual(parsed.proxyBypassDomains, ["foo.com", "bar.org", "net.chat"])
    }

    func test_givenRedirectGateway_whenParse_thenIsHandled() throws {
        let parsed = try parser.parsed(fromLines: ["redirect-gateway   def1   block-local"]).configuration
        let routingPolicies = try XCTUnwrap(parsed.routingPolicies)
        XCTAssertEqual(Set(routingPolicies), Set([.IPv4, .blockLocal]))
    }

    func test_givenConnectionBlock_whenParse_thenFails() throws {
        let lines = ["<connection>", "</connection>"]
        XCTAssertThrowsError(try parser.parsed(fromLines: lines))
    }

    func test_givenTLSCryptV2_whenParse_thenFails() throws {
        let lines = ["tls-crypt-v2-client"]
        XCTAssertThrowsError(try parser.parsed(fromLines: lines))
    }

    // MARK: URL

    func test_givenPIA_whenParse_thenIsParsedCorrectly() throws {
        let file = try parser.parsed(fromURL: url(withName: "pia-hungary"))

        XCTAssertEqual(file.configuration.remotes, [
            try? ExtendedEndpoint("hungary.privateinternetaccess.com", .init(.udp, 1198)),
            try? ExtendedEndpoint("hungary.privateinternetaccess.com", .init(.tcp, 502))
        ].compactMap { $0 })

        XCTAssertEqual(file.configuration.cipher, .aes128cbc)
        XCTAssertEqual(file.configuration.digest, .sha1)
        XCTAssertEqual(file.configuration.authUserPass, true)
        XCTAssertEqual(file.configuration.compressionAlgorithm, .disabled)
        XCTAssertEqual(file.configuration.renegotiatesAfter, .zero)

        XCTAssertTrue(file.configuration.ca?.pem.hasPrefix("-----BEGIN CERTIFICATE-----") ?? false)
    }

    func test_givenProtonVPN_whenParse_thenIsParsedCorrectly() throws {
        let file = try parser.parsed(fromURL: url(withName: "protonvpn"))

        XCTAssertEqual(file.configuration.remotes, [
            try? ExtendedEndpoint("103.212.227.123", .init(.udp, 5060)),
            try? ExtendedEndpoint("103.212.227.123", .init(.udp, 1194)),
            try? ExtendedEndpoint("103.212.227.123", .init(.udp, 443)),
            try? ExtendedEndpoint("103.212.227.123", .init(.udp, 4569)),
            try? ExtendedEndpoint("103.212.227.123", .init(.udp, 80))
        ].compactMap { $0 })

        XCTAssertEqual(file.configuration.randomizeEndpoint, true)
        XCTAssertEqual(file.configuration.cipher, .aes256cbc)
        XCTAssertEqual(file.configuration.digest, .sha512)
        XCTAssertEqual(file.configuration.renegotiatesAfter, .zero)
        XCTAssertEqual(file.configuration.authUserPass, true)

        let mask = Data("this-is-a-mask".utf8)
        XCTAssertEqual(file.configuration.xorMethod, .obfuscate(mask: SecureData(mask)))

        XCTAssertTrue(file.configuration.ca?.pem.hasPrefix("-----BEGIN CERTIFICATE-----") ?? false)
        XCTAssertEqual(file.configuration.tlsWrap?.strategy, .auth)
        XCTAssertEqual(file.configuration.tlsWrap?.key.direction, .client)
        XCTAssertTrue(file.configuration.tlsWrap?.key.hexString.hasPrefix("6acef03f62675b4b1bbd03e53b187727") ?? false)
    }

    func test_givenXOR_whenParse_thenIsHandled() throws {
        let asciiData = "F"
        let singleMask = try XCTUnwrap(SecureData(String(repeating: asciiData, count: 1)))
        let multiMask = try XCTUnwrap(SecureData(String(repeating: asciiData, count: 4)))

        let cfg = try parser.parsed(fromLines: ["scramble xormask F"])
        XCTAssertNil(cfg.warning)
        XCTAssertEqual(cfg.configuration.xorMethod, .xormask(mask: singleMask))

        let cfg2 = try parser.parsed(fromLines: ["scramble reverse"])
        XCTAssertNil(cfg.warning)
        XCTAssertEqual(cfg2.configuration.xorMethod, .reverse)

        let cfg3 = try parser.parsed(fromLines: ["scramble xorptrpos"])
        XCTAssertNil(cfg.warning)
        XCTAssertEqual(cfg3.configuration.xorMethod, .xorptrpos)

        let cfg4 = try parser.parsed(fromLines: ["scramble obfuscate FFFF"])
        XCTAssertNil(cfg.warning)
        XCTAssertEqual(cfg4.configuration.xorMethod, .obfuscate(mask: multiMask))
    }

    func test_givenMessage_whenParse_thenIsFastEnough() throws {
        let msg = "PUSH_REPLY,route 87.233.192.218,route 87.233.192.219,route 87.233.192.220,route 87.248.186.252,route 92.241.171.245,route 103.246.200.0 255.255.252.0,route 109.239.140.0 255.255.255.0,route 128.199.0.0 255.255.0.0,route 13.125.0.0 255.255.0.0,route 13.230.0.0 255.254.0.0,route 13.56.0.0 255.252.0.0,route 149.154.160.0 255.255.252.0,route 149.154.164.0 255.255.252.0,route 149.154.168.0 255.255.252.0,route 149.154.172.0 255.255.252.0,route 159.122.128.0 255.255.192.0,route 159.203.0.0 255.255.0.0,route 159.65.0.0 255.255.0.0,route 159.89.0.0 255.255.0.0,route 165.227.0.0 255.255.0.0,route 167.99.0.0 255.255.0.0,route 174.138.0.0 255.255.128.0,route 176.67.169.0 255.255.255.0,route 178.239.88.0 255.255.248.0,route 178.63.0.0 255.255.0.0,route 18.130.0.0 255.255.0.0,route 18.144.0.0 255.255.0.0,route 18.184.0.0 255.254.0.0,route 18.194.0.0 255.254.0.0,route 18.196.0.0 255.254.0.0,route 18.204.0.0 255.252.0.0,push-continuation 2"

        let parser = StandardOpenVPNParser()
        let lines = msg.components(separatedBy: ",")
        measure {
            _ = try? parser.parsed(fromLines: lines)
        }
    }

    // MARK: Routes

    func test_givenIfconfig_whenParse_thenIncludesNetworkRoutes() throws {
        let line = "PUSH_REPLY,route-gateway 172.31.2.1,route-gateway 172.31.2.1,topology subnet,ping 10,ping-restart 120,route 192.168.41.0 255.255.255.0,route 192.168.50.0 255.255.255.0,route 192.168.42.0 255.255.255.0,route 192.168.43.0 255.255.255.0,route 192.168.44.0 255.255.255.0,route 192.168.45.0 255.255.255.0,route 192.168.70.0 255.255.255.0,route 192.168.31.0 255.255.255.0,dhcp-option DNS 192.168.41.2,dhcp-option DNS 192.168.44.11,ifconfig 172.31.2.6 255.255.255.0,ifconfig-ipv6 1234::12/10 1234::1,"

        let pushReply = try XCTUnwrap(parser.pushReply(with: line))

        XCTAssertEqual(pushReply.options.ipv4?.subnet, Subnet(rawValue: "172.31.2.6/24"))
        XCTAssertEqual(pushReply.options.ipv4?.includedRoutes, [
            Route(Subnet(rawValue: "172.31.2.0/24"), nil)
        ])

        XCTAssertEqual(pushReply.options.ipv6?.subnet, Subnet(rawValue: "1234::12/10"))
        XCTAssertEqual(pushReply.options.ipv6?.includedRoutes, [
            Route(Subnet(rawValue: "1200::/10"), nil)
        ])
    }
}

// MARK: - Helpers

private extension StandardOpenVPNParserTests {
    func url(withName name: String) -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: "ovpn") else {
            fatalError("Cannot find URL in bundle")
        }
        return url
    }
}
