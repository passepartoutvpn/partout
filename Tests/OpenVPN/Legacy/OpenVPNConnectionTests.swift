// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import PartoutOpenVPN
@testable internal import PartoutOpenVPNLegacy
internal import _PartoutOpenVPNLegacy_ObjC
import Foundation
import PartoutCore
import XCTest

final class OpenVPNConnectionTests: XCTestCase {
    private let constants = Constants()

    func test_givenConnection_whenStart_thenConnects() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus

        let expLink = expectation(description: "Link")
        let expTunnel = expectation(description: "Tunnel")
        session.onSetLink = {
            expLink.fulfill()
        }
        session.onSetTunnel = {
            expTunnel.fulfill()
        }

        let sut = try await constants.newConnection(with: session)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        try await sut.start()
        await fulfillment(of: [expLink, expTunnel], timeout: 0.3)
        status = await sut.backend.status
        XCTAssertEqual(status, .connected)
    }

    func test_givenConnectionFailingLink_whenStart_thenFails() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus
        let controller = MockTunnelController()

        let expLink = expectation(description: "Link")
        session.onSetLink = {
            throw PartoutError(.crypto)
        }
        session.onDidFailToSetLink = {
            expLink.fulfill()
        }

        let sut = try await constants.newConnection(with: session, controller: controller)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        do {
            try await sut.start()
            await fulfillment(of: [expLink], timeout: 0.3)
        } catch {
            XCTAssertEqual((error as? PartoutError)?.code, .crypto)
        }
    }

    func test_givenConnectionFailingTunnelSetup_whenStart_thenFails() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus
        let controller = MockTunnelController()
        controller.onSetTunnelSettings = { _ in
            throw PartoutError(.incompatibleModules)
        }

        session.onStop = {
            XCTAssertEqual(($0 as? PartoutError)?.code, .incompatibleModules)
        }

        let sut = try await constants.newConnection(with: session, controller: controller)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        do {
            try await sut.start()
        } catch {
            XCTAssertEqual((error as? PartoutError)?.code, .incompatibleModules)
        }
    }

    func test_givenConnectionFailingAsynchronously_whenStart_thenCancelsShortlyAfter() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus
        let controller = MockTunnelController()

        let expStop = expectation(description: "Stop tunnel")
        session.onSetLink = {
            Task {
                try? await Task.sleep(milliseconds: 200)
                await session.shutdown(PartoutError(.crypto))
            }
        }
        session.onStop = {
            XCTAssertEqual(($0 as? PartoutError)?.code, .crypto)
            expStop.fulfill()
        }

        let sut = try await constants.newConnection(with: session, controller: controller)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        try await sut.start()
        await fulfillment(of: [expStop], timeout: 1.0)
    }

    func test_givenConnectionFailingWithRecoverableError_whenStart_thenDisconnects() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus
        let controller = MockTunnelController()
        let recoverableError = PartoutError(.timeout)
        assert(recoverableError.isOpenVPNRecoverable)

        let expStart = expectation(description: "Start")
        let expStop = expectation(description: "Stop")
        session.onSetLink = {
            expStart.fulfill()
        }
        session.onStop = {
            XCTAssertEqual(($0 as? PartoutError)?.code, recoverableError.code)
            expStop.fulfill()
        }
        controller.onCancelTunnelConnection = { _ in
            XCTFail("Should not cancel connection")
        }

        let sut = try await constants.newConnection(
            with: session,
            controller: controller
        )
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        try await sut.start()
        await fulfillment(of: [expStart], timeout: 0.3)
        status = await sut.backend.status
        XCTAssertEqual(status, .connected)

        Task {
            await session.shutdown(recoverableError)
        }

        await fulfillment(of: [expStop], timeout: 0.5)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)
    }

    func test_givenStartedConnection_whenStop_thenDisconnects() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus

        let expLink = expectation(description: "Link")
        let expStop = expectation(description: "Stop")
        session.onSetLink = {
            expLink.fulfill()
        }
        session.onStop = {
            XCTAssertNil($0)
            expStop.fulfill()
        }

        let sut = try await constants.newConnection(with: session)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        try await sut.start()
        await fulfillment(of: [expLink], timeout: 0.2)
        status = await sut.backend.status
        XCTAssertEqual(status, .connected)

        await sut.stop(timeout: 100)
        await fulfillment(of: [expStop], timeout: 0.3)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)
    }

    func test_givenStartedConnectionWithHangingLink_whenStop_thenDisconnectsAfterTimeout() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus

        let expLink = expectation(description: "Link")
        let expStop = expectation(description: "Stop")
        session.onSetLink = {
            session.mockHasLink = true
            expLink.fulfill()
        }
        session.onStop = {
            XCTAssertNil($0)
            expStop.fulfill()
        }

        let sut = try await constants.newConnection(with: session)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        try await sut.start()
        await fulfillment(of: [expLink], timeout: 0.2)
        status = await sut.backend.status
        XCTAssertEqual(status, .connected)

        await sut.stop(timeout: 100)
        await fulfillment(of: [expStop], timeout: 0.3)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)
    }

    func test_givenStartedConnection_whenUpgraded_thenDisconnectsWithNetworkChanged() async throws {
        let session = MockOpenVPNSession()
        var status: ConnectionStatus
        let hasBetterPath = PassthroughStream<Void>()
        let factory = MockNetworkInterfaceFactory()
        factory.linkBlock = {
            $0.hasBetterPath = hasBetterPath.subscribe()
        }

        let expInitialLink = expectation(description: "Initial link")
        let expConnected = expectation(description: "Connected")
        let expStop = expectation(description: "Stop")
        session.onSetLink = {
            expInitialLink.fulfill()
        }
        session.onConnected = {
            expConnected.fulfill()
        }
        session.onStop = {
            XCTAssertEqual(($0 as? PartoutError)?.code, .networkChanged)
            expStop.fulfill()
        }

        let sut = try await constants.newConnection(
            with: session,
            factory: factory
        )
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)

        try await sut.start()
        await fulfillment(of: [expInitialLink, expConnected], timeout: 0.5)
        status = await sut.backend.status
        XCTAssertEqual(status, .connected)

        hasBetterPath.send()
        await fulfillment(of: [expStop], timeout: 0.5)
        status = await sut.backend.status
        XCTAssertEqual(status, .disconnected)
    }
}

// MARK: - Helpers

private struct Constants {
    private let prng = SimplePRNG()

    private let dns = MockDNSResolver()

    private let hostname = "hostname"

    private let module: OpenVPNModule

    init() {
        dns.setResolvedIPv4(["1.2.3.4"], for: hostname)

        var cfg = OpenVPN.Configuration.Builder()
        cfg.ca = OpenVPN.CryptoContainer(pem: "")
        cfg.cipher = .aes128cbc
        cfg.remotes = [ExtendedEndpoint(rawValue: "\(hostname):UDP:1194")!]
        do {
            module = try OpenVPNModule.Builder(configurationBuilder: cfg).tryBuild()
        } catch {
            fatalError("Cannot build OpenVPNModule: \(error)")
        }
    }

    func newConnection(
        with session: OpenVPNSessionProtocol,
        controller: TunnelController = MockTunnelController(),
        factory: NetworkInterfaceFactory = MockNetworkInterfaceFactory(),
        environment: TunnelEnvironment = SharedTunnelEnvironment(profileId: nil)
    ) async throws -> LegacyOpenVPNConnection {
        let impl = OpenVPNModule.Implementation(
            importer: StandardOpenVPNParser(),
            connectionBlock: {
                try LegacyOpenVPNConnection(
                    .global,
                    parameters: $0,
                    module: $1,
                    prng: prng,
                    dns: dns,
                    sessionFactory: { session }
                )
            }
        )
        let options = ConnectionParameters.Options()
        let conn = try module.newConnection(with: impl, parameters: .init(
            controller: controller,
            factory: factory,
            environment: environment,
            options: options
        ))
        return try XCTUnwrap(conn as? LegacyOpenVPNConnection)
    }
}

private final class MockOpenVPNSession: OpenVPNSessionProtocol {
    private let options: OpenVPN.Configuration = {
        do {
            return try OpenVPN.Configuration.Builder().tryBuild(isClient: false)
        } catch {
            fatalError("Cannot build remote options: \(error)")
        }
    }()

    var onSetLink: () throws -> Void = {}

    var onConnected: () -> Void = {}

    var onDidFailToSetLink: () -> Void = {}

    var onSetTunnel: () -> Void = {}

    var onStop: (Error?) -> Void = { _ in }

    var mockHasLink = false

    // MARK: OpenVPNSessionProtocol

    weak var delegate: OpenVPNSessionDelegate?

    func setDelegate(_ delegate: OpenVPNSessionDelegate) async {
        self.delegate = delegate
    }

    func setLink(_ link: LinkInterface) async throws {
        do {
            try onSetLink()
            await delegate?.sessionDidStart(
                self,
                remoteAddress: "100.200.100.200",
                remoteProtocol: .init(.udp, 1234),
                remoteOptions: options
            )
            onConnected()
        } catch {
            await delegate?.sessionDidStop(self, withError: error)
            onDidFailToSetLink()
        }
    }

    func hasLink() async -> Bool {
        mockHasLink
    }

    func setTunnel(_ tunnel: TunnelInterface) async {
        onSetTunnel()
    }

    func shutdown(_ error: (any Error)?, timeout: TimeInterval?) async {
        await delegate?.sessionDidStop(self, withError: error)
        onStop(error)
    }
}
