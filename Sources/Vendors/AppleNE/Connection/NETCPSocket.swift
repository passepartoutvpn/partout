// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import NetworkExtension
import PartoutCore

/// Implementation of a ``/PartoutCore/LinkObserver`` via `NWTCPConnection`.
public final class NETCPObserver: LinkObserver {
    public struct Options: Sendable {
        public let minLength: Int

        public let maxLength: Int
    }

    private let ctx: PartoutLoggerContext

    private nonisolated let nwConnection: NWTCPConnection

    private let options: Options

    private var observer: ValueObserver<NWTCPConnection>?

    public init(_ ctx: PartoutLoggerContext, nwConnection: NWTCPConnection, options: Options) {
        self.ctx = ctx
        self.nwConnection = nwConnection
        self.options = options
    }

    public func waitForActivity(timeout: Int) async throws -> LinkInterface {
        observer = ValueObserver(nwConnection)
        defer {
            observer = nil
        }
        try await observer?.waitForValue(on: \.state, timeout: timeout) { [weak self] state in
            guard let self else {
                return false
            }
            pp_log(ctx, .ne, .info, "Socket state is \(state.debugDescription)")
            switch state {
            case .connected:
                return true
            case .cancelled, .disconnected:
                throw PartoutError(.linkNotActive)
            default:
                return false
            }
        }
        guard let remote = nwConnection.remoteAddress as? NWHostEndpoint,
              let port = UInt16(remote.port) else {
            throw PartoutError(.linkNotActive)
        }
        return NETCPSocket(
            nwConnection: nwConnection,
            options: options,
            remoteAddress: remote.hostname,
            remoteProtocol: EndpointProtocol(.tcp, port)
        )
    }
}

// MARK: - NETCPSocket

private actor NETCPSocket: LinkInterface {
    private nonisolated let nwConnection: NWTCPConnection

    private let options: NETCPObserver.Options

    let remoteAddress: String

    let remoteProtocol: EndpointProtocol

    init(
        nwConnection: NWTCPConnection,
        options: NETCPObserver.Options,
        remoteAddress: String,
        remoteProtocol: EndpointProtocol
    ) {
        self.nwConnection = nwConnection
        self.options = options
        self.remoteAddress = remoteAddress
        self.remoteProtocol = remoteProtocol
    }
}

// MARK: LinkInterface

extension NETCPSocket {
    nonisolated var hasBetterPath: AsyncStream<Void> {
        stream(for: \.hasBetterPath, of: nwConnection) { $0 }
            .map { _ in }
    }

    nonisolated func upgraded() -> LinkInterface {
        Self(
            nwConnection: NWTCPConnection(upgradeFor: nwConnection),
            options: options,
            remoteAddress: remoteAddress,
            remoteProtocol: remoteProtocol
        )
    }

    nonisolated func shutdown() {
        nwConnection.writeClose()
        nwConnection.cancel()
    }
}

// MARK: IOInterface

extension NETCPSocket {
    public nonisolated func setReadHandler(_ handler: @escaping ([Data]?, Error?) -> Void) {
        loopReadPackets(handler)
    }

    public func writePackets(_ packets: [Data]) async throws {
        guard !packets.isEmpty else {
            return
        }
        let joinedPacket = Data(packets.joined())
        try await asyncWritePacket(joinedPacket)
    }
}

private extension NETCPSocket {
    nonisolated func loopReadPackets(_ handler: @escaping ([Data]?, Error?) -> Void) {

        // WARNING: runs in Network.framework queue
        nwConnection.readMinimumLength(options.minLength, maximumLength: options.maxLength) { [weak self] data, error in
            handler(data.map { [$0] }, error)

            // repeat until failure
            if error == nil {
                self?.loopReadPackets(handler)
            }
        }
    }

    func asyncWritePacket(_ packet: Data) async throws {
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                nwConnection.write(packet) { error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume()
                }
            }
        } onCancel: {
            nwConnection.cancel()
        }
    }
}
