// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import NetworkExtension
import PartoutCore

/// Delegates behavior of a `NEPacketTunnelProvider`.
public actor NEPTPForwarder {
    private let ctx: PartoutLoggerContext

    private let daemon: SimpleConnectionDaemon

    public nonisolated var profile: Profile {
        daemon.profile
    }

    public let originalProfile: Profile

    public nonisolated var environment: TunnelEnvironment {
        daemon.environment
    }

    public init(
        _ ctx: PartoutLoggerContext,
        controller: NETunnelController,
        factoryOptions: NEInterfaceFactory.Options = .init(),
        connectionOptions: ConnectionParameters.Options = .init(),
        stopDelay: Int = 2000,
        reconnectionDelay: Int = 2000
    ) throws {
        let environment = controller.environment
        let factory = NEInterfaceFactory(ctx, provider: controller.provider, options: factoryOptions)
        let reachability = NEObservablePath(ctx)

        let connectionParameters = ConnectionParameters(
            controller: controller,
            factory: factory,
            environment: environment,
            options: connectionOptions
        )
        let messageHandler = DefaultMessageHandler(ctx, environment: environment)

        let params = SimpleConnectionDaemon.Parameters(
            registry: controller.registry,
            connectionParameters: connectionParameters,
            reachability: reachability,
            messageHandler: messageHandler,
            stopDelay: stopDelay,
            reconnectionDelay: reconnectionDelay
        )

        self.ctx = ctx
        daemon = try SimpleConnectionDaemon(params: params)
        originalProfile = controller.originalProfile
    }

    deinit {
        pp_log(ctx, .ne, .info, "Deinit PTP")
    }

    public func startTunnel(options: [String: NSObject]?) async throws {
        pp_log(ctx, .ne, .notice, "Start PTP")
        try await daemon.start()
    }

    public func holdTunnel() async {
        pp_log(ctx, .ne, .notice, "Hold PTP")
        await daemon.hold()
    }

    public func stopTunnel(with reason: NEProviderStopReason) async {
        pp_log(ctx, .ne, .notice, "Stop PTP, reason: \(String(describing: reason))")
        await daemon.stop()
    }

    public func handleAppMessage(_ messageData: Data) async -> Data? {
        pp_log(ctx, .ne, .debug, "Handle PTP message")
        do {
            let input = try JSONDecoder().decode(Message.Input.self, from: messageData)
            let output = try await daemon.sendMessage(input)
            let encodedOutput = try JSONEncoder().encode(output)
            switch input {
            case .environment:
                break
            default:
                pp_log(ctx, .ne, .info, "Message handled and response encoded (\(encodedOutput.asSensitiveBytes(ctx)))")
            }
            return encodedOutput
        } catch {
            pp_log(ctx, .ne, .error, "Unable to decode message: \(messageData)")
            return nil
        }
    }

    public func sleep() async {
        pp_log(ctx, .ne, .debug, "Device is about to sleep")
    }

    public nonisolated func wake() {
        pp_log(ctx, .ne, .debug, "Device is about to wake up")
    }
}
