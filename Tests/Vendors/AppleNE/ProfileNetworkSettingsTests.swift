// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import _PartoutVendorsAppleNE
import Foundation
import NetworkExtension
import PartoutCore
import XCTest

final class ProfileNetworkSettingsTests: XCTestCase {

    // MARK: Plain

    func test_givenProfileWithDefaultGateway_whenGetNetworkSettings_thenDoesNothingAboutDNS() throws {
        let connModule = BogusConnectionModule()
        let ipModule = IPModule.Builder(
            ipv4: IPSettings(subnet: Subnet(rawValue: "1.2.3.4/32")!)
                .including(routes: [
                    Route(defaultWithGateway: Address(rawValue: "10.20.30.40")!)
                ]),
            ipv6: IPSettings(subnet: Subnet(rawValue: "::1/32")!)
                .including(routes: [
                    Route(defaultWithGateway: Address(rawValue: "10:20::30:40")!)
                ])
        ).tryBuild()
        let dnsModule = try DNSModule.Builder(
            servers: ["1.1.1.1", "2.2.2.2", "::100"]
        ).tryBuild()
        let profile = try Profile.Builder(
            modules: [connModule, ipModule, dnsModule],
            activatingModules: true
        ).tryBuild()

        let sut = profile.networkSettings(with: nil)

        let ipV4Settings = try XCTUnwrap(sut.ipv4Settings)
        let ipV6Settings = try XCTUnwrap(sut.ipv6Settings)
        let expRoutesV4: [NEIPv4Route] = {
            let route = NEIPv4Route.default()
            route.gatewayAddress = "10.20.30.40"
            return [route]
        }()
        let expRoutesV6: [NEIPv6Route] = {
            let route = NEIPv6Route.default()
            route.gatewayAddress = "10:20::30:40"
            return [route]
        }()
        XCTAssertEqual(Set(ipV4Settings.includedRoutes ?? []), Set(expRoutesV4))
        XCTAssertEqual(Set(ipV6Settings.includedRoutes ?? []), Set(expRoutesV6))

        let dnsSettings = try XCTUnwrap(sut.dnsSettings)
        XCTAssertEqual(dnsSettings.matchDomains, [""])
    }

    func test_givenProfileWithoutDefaultGateway_whenGetNetworkSettings_thenAddsBogusMatchDomains() throws {
        let connectionModule = BogusConnectionModule()
        let ipModule = IPModule.Builder(
            ipv4: IPSettings(subnet: Subnet(rawValue: "1.2.3.4/32")!),
            ipv6: IPSettings(subnet: Subnet(rawValue: "::1/32")!)
        ).tryBuild()
        var dnsModuleBuilder = DNSModule.Builder(
            servers: ["1.1.1.1", "2.2.2.2", "::100"]
        )
        var sut: NEPacketTunnelNetworkSettings

        //

        let profile = try Profile.Builder(
            modules: [connectionModule, ipModule, try dnsModuleBuilder.tryBuild()],
            activatingModules: true
        ).tryBuild()
        sut = profile.networkSettings(with: nil)

        let ipV4Settings = try XCTUnwrap(sut.ipv4Settings)
        let ipV6Settings = try XCTUnwrap(sut.ipv6Settings)
        let expRoutesV4: [NEIPv4Route] = []
        let expRoutesV6: [NEIPv6Route] = []
        XCTAssertEqual(Set(ipV4Settings.includedRoutes ?? []), Set(expRoutesV4))
        XCTAssertEqual(Set(ipV6Settings.includedRoutes ?? []), Set(expRoutesV6))

        XCTAssertEqual(sut.dnsSettings?.matchDomains, [""])

        //

        dnsModuleBuilder.searchDomains = ["domain.com"]
        sut = try Profile.Builder(
            modules: [connectionModule, ipModule, try dnsModuleBuilder.tryBuild()],
            activatingModules: true
        ).tryBuild().networkSettings(with: nil)

        XCTAssertEqual(sut.dnsSettings?.matchDomains, [""])
    }

    // MARK: With remote info

    func test_givenProfile_whenGetNetworkSettingsWithInfo_thenAppliesInfo() throws {
        let bogusModule = try DNSModule.Builder().tryBuild()
        let profile = try Profile.Builder(
            modules: [bogusModule],
            activeModulesIds: [bogusModule.id]
        ).tryBuild()

        let sut = profile.networkSettings(with: .init(
            originalModuleId: bogusModule.id,
            address: Address(rawValue: "5.6.7.8")!,
            modules: [try DNSModule.Builder(servers: ["1.1.1.1"]).tryBuild()]
        ))

        XCTAssertEqual(sut.tunnelRemoteAddress, "5.6.7.8")
        XCTAssertEqual(sut.dnsSettings?.servers, ["1.1.1.1"])
        XCTAssertNil(sut.mtu)
    }

    func test_givenProfileWithRemoteDefaultGateway_whenExcludeDefaultRoute_thenHasNoRoutes() throws {
        let connectionModule = BogusConnectionModule()
        let remoteInfo = TunnelRemoteInfo(
            originalModuleId: UUID(),
            address: nil,
            modules: [
                IPModule.Builder(
                    ipv4: IPSettings(subnet: Subnet(rawValue: "1.2.3.4/32")!)
                        .including(routes: [
                            Route(defaultWithGateway: nil)
                        ]),
                    ipv6: IPSettings(subnet: Subnet(rawValue: "::1/32")!)
                        .including(routes: [
                            Route(defaultWithGateway: nil)
                        ])
                ).tryBuild()
            ]
        )
        let ipModule = IPModule.Builder(
            ipv4: IPSettings(subnet: Subnet(rawValue: "1.2.3.4/32")!)
                .excluding(routes: [
                    Route(defaultWithGateway: nil)
                ]),
            ipv6: IPSettings(subnet: Subnet(rawValue: "::1/32")!)
                .excluding(routes: [
                    Route(defaultWithGateway: nil)
                ])
        ).tryBuild()
        let profile = try Profile.Builder(
            modules: [connectionModule, ipModule],
            activatingModules: true
        ).tryBuild()

        let sut = profile.networkSettings(with: remoteInfo)

        let ipV4Settings = try XCTUnwrap(sut.ipv4Settings)
        let ipV6Settings = try XCTUnwrap(sut.ipv6Settings)
        XCTAssertEqual(ipV4Settings.includedRoutes, [])
        XCTAssertEqual(ipV6Settings.includedRoutes, [])
    }
}

private struct BogusConnectionModule: ConnectionModule {
    func newConnection(with impl: (any ModuleImplementation)?, parameters: ConnectionParameters) throws -> Connection {
        fatalError()
    }
}
