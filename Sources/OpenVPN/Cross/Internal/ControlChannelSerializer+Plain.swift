// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

internal import _PartoutOpenVPN_C
internal import _PartoutVendorsPortable
import Foundation
import PartoutCore
import PartoutOpenVPN

extension ControlChannel {
    final class PlainSerializer: ControlChannelSerializer {
        private let ctx: PartoutLoggerContext

        init(_ ctx: PartoutLoggerContext) {
            self.ctx = ctx
        }

        func reset() {
        }

        func serialize(packet: CControlPacket) throws -> Data {
            return packet.serialized()
        }

        func deserialize(data packet: Data, start: Int, end: Int?) throws -> CControlPacket {
            var offset = start
            let end = end ?? packet.count

            guard end >= offset + PacketOpcodeLength else {
                throw OpenVPNSessionError.controlChannel(message: "Missing opcode")
            }
            let codeValue = packet[offset] >> 3
            guard let code = CPacketCode(rawValue: codeValue) else {
                throw OpenVPNSessionError.controlChannel(message: "Unknown code: \(codeValue))")
            }
            let key = packet[offset] & 0b111
            offset += PacketOpcodeLength

            pp_log(ctx, .openvpn, .info, "Control: Try read packet with code \(code.debugDescription) and key \(key)")

            guard end >= offset + PacketSessionIdLength else {
                throw OpenVPNSessionError.controlChannel(message: "Missing sessionId")
            }
            let sessionId = packet.subdata(offset: offset, count: PacketSessionIdLength)
            offset += PacketSessionIdLength

            guard end >= offset + 1 else {
                throw OpenVPNSessionError.controlChannel(message: "Missing ackSize")
            }
            let ackSize = packet[offset]
            offset += 1

            var ackIds: [UInt32]?
            var ackRemoteSessionId: Data?
            if ackSize > 0 {
                guard end >= (offset + Int(ackSize) * PacketIdLength) else {
                    throw OpenVPNSessionError.controlChannel(message: "Missing acks")
                }
                var ids: [UInt32] = []
                for _ in 0..<ackSize {
                    let id = packet.networkUInt32Value(from: offset)
                    ids.append(id)
                    offset += PacketIdLength
                }

                guard end >= offset + PacketSessionIdLength else {
                    throw OpenVPNSessionError.controlChannel(message: "Missing remoteSessionId")
                }
                let remoteSessionId = packet.subdata(offset: offset, count: PacketSessionIdLength)
                offset += PacketSessionIdLength

                ackIds = ids
                ackRemoteSessionId = remoteSessionId
            }

            if code == .ackV1 {
                guard let ackIds = ackIds else {
                    throw OpenVPNSessionError.controlChannel(message: "Ack packet without ids")
                }
                guard let ackRemoteSessionId = ackRemoteSessionId else {
                    throw OpenVPNSessionError.controlChannel(message: "Ack packet without remoteSessionId")
                }
                return CControlPacket(
                    key: key,
                    sessionId: sessionId,
                    ackIds: ackIds,
                    ackRemoteSessionId: ackRemoteSessionId
                )
            }

            guard end >= offset + PacketIdLength else {
                throw OpenVPNSessionError.controlChannel(message: "Missing packetId")
            }
            let packetId = packet.networkUInt32Value(from: offset)
            offset += PacketIdLength

            var payload: Data?
            if offset < end {
                payload = packet.subdata(in: offset..<end)
            }

            return CControlPacket(
                code: code,
                key: key,
                sessionId: sessionId,
                packetId: packetId,
                payload: payload,
                ackIds: ackIds,
                ackRemoteSessionId: ackRemoteSessionId
            )
        }
    }
}
