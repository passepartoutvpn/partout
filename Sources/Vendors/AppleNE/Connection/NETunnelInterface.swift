// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import NetworkExtension
import PartoutCore

/// Implementation of a ``/PartoutCore/TunnelInterface`` via `NEPacketTunnelFlow`.
public final class NETunnelInterface: TunnelInterface {
    private let ctx: PartoutLoggerContext

    private weak var impl: NEPacketTunnelFlow?

    public init(_ ctx: PartoutLoggerContext, impl: NEPacketTunnelFlow) {
        self.ctx = ctx
        self.impl = impl
    }

    // MARK: TunnelInterface

    public func readPackets() async throws -> [Data] {
        guard let impl else {
            pp_log(ctx, .ne, .error, "NEPacketTunnelFlow released prematurely")
            throw PartoutError(.unhandled)
        }
        let pair = await impl.readPackets()
        return pair.0
    }

    public func writePackets(_ packets: [Data]) {
        let protocols = packets.map(IPHeader.protocolNumber(inPacket:))
        impl?.writePackets(packets, withProtocols: protocols)
    }
}
