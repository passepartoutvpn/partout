// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

internal import _PartoutOpenVPNLegacy_ObjC
import XCTest

final class PacketStreamTests: XCTestCase {
    func test_givenStream_whenHandlePackets_thenIsReassembled() {
        var bytes: [UInt8] = []
        var until: Int = 0
        var packets: [Data]

        bytes.append(contentsOf: [0x00, 0x04])
        bytes.append(contentsOf: [0x10, 0x20, 0x30, 0x40])
        bytes.append(contentsOf: [0x00, 0x07])
        bytes.append(contentsOf: [0x10, 0x20, 0x30, 0x40, 0x50, 0x66, 0x77])
        bytes.append(contentsOf: [0x00, 0x01])
        bytes.append(contentsOf: [0xff])
        bytes.append(contentsOf: [0x00, 0x03])
        bytes.append(contentsOf: [0xaa])
        XCTAssertEqual(bytes.count, 21)

        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 18)
        XCTAssertEqual(packets.count, 3)

        bytes.append(contentsOf: [0xbb, 0xcc])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 23)
        XCTAssertEqual(packets.count, 4)

        bytes.append(contentsOf: [0x00, 0x05])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 23)
        XCTAssertEqual(packets.count, 4)

        bytes.append(contentsOf: [0x11, 0x22, 0x33, 0x44])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 23)
        XCTAssertEqual(packets.count, 4)

        bytes.append(contentsOf: [0x55])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 30)
        XCTAssertEqual(packets.count, 5)

        //

        bytes.removeSubrange(0..<until)
        XCTAssertEqual(bytes.count, 0)

        bytes.append(contentsOf: [0x00, 0x04])
        bytes.append(contentsOf: [0x10, 0x20])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 0)
        XCTAssertEqual(packets.count, 0)
        bytes.removeSubrange(0..<until)
        XCTAssertEqual(bytes.count, 4)

        bytes.append(contentsOf: [0x30, 0x40])
        bytes.append(contentsOf: [0x00, 0x07])
        bytes.append(contentsOf: [0x10, 0x20, 0x30, 0x40])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 6)
        XCTAssertEqual(packets.count, 1)
        bytes.removeSubrange(0..<until)
        XCTAssertEqual(bytes.count, 6)

        bytes.append(contentsOf: [0x50, 0x66, 0x77])
        bytes.append(contentsOf: [0x00, 0x01])
        bytes.append(contentsOf: [0xff])
        bytes.append(contentsOf: [0x00, 0x03])
        bytes.append(contentsOf: [0xaa])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 12)
        XCTAssertEqual(packets.count, 2)
        bytes.removeSubrange(0..<until)
        XCTAssertEqual(bytes.count, 3)

        bytes.append(contentsOf: [0xbb, 0xcc])
        packets = stream(from: bytes, until: &until)
        XCTAssertEqual(until, 5)
        XCTAssertEqual(packets.count, 1)
        bytes.removeSubrange(0..<until)
        XCTAssertEqual(bytes.count, 0)
    }
}

// MARK: - Helpers

private extension PacketStreamTests {
    func stream(from bytes: [UInt8], until: inout Int) -> [Data] {
        PacketStream.packets(fromInboundStream: Data(bytes), until: &until, xorMethod: .none, xorMask: nil)
    }
}
