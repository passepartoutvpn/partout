// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable internal import _PartoutVendorsPortable
import XCTest

final class CZeroingDataTests: XCTestCase {
    func test_givenInput_whenInit_thenReturnsExpected() {
        XCTAssertEqual(CZeroingData(count: 123).count, 123)
        XCTAssertEqual(CZeroingData(bytes: [0x11, 0x22, 0x33, 0x44, 0x55], count: 3).count, 3)
        XCTAssertEqual(CZeroingData(uInt8: UInt8(78)).count, 1)
        XCTAssertEqual(CZeroingData(uInt16: UInt16(4756)).count, 2)
        XCTAssertEqual(CZeroingData(data: Data(count: 12)).count, 12)
        XCTAssertEqual(CZeroingData(data: Data(count: 12), offset: 3, count: 7).count, 7)
        XCTAssertEqual(CZeroingData(string: "hello", nullTerminated: false).count, 5)
        XCTAssertEqual(CZeroingData(string: "hello", nullTerminated: true).count, 6)
    }

    func test_givenData_whenOffset_thenReturnsExpected() {
        let sut = CZeroingData(string: "Hello", nullTerminated: true)
        XCTAssertEqual(sut.networkUInt16Value(fromOffset: 3), 0x6c6f)
        XCTAssertEqual(sut.nullTerminatedString(fromOffset: 0), "Hello")
        XCTAssertEqual(sut.withOffset(3, length: 2), CZeroingData(string: "lo", nullTerminated: false))
    }

    func test_givenData_whenAppend_thenIsAppended() {
        let sut = CZeroingData(string: "this_data", nullTerminated: false)
        let other = CZeroingData(string: "that_data", nullTerminated: false)

        let merged = sut.copy()
        merged.append(other)
        XCTAssertEqual(merged, CZeroingData(string: "this_datathat_data", nullTerminated: false))
        XCTAssertEqual(merged, sut.appending(other))
    }

    func test_givenData_whenTruncate_thenIsTruncated() {
        let data = Data(hex: "438ac4729847fb3975345983")
        let sut = CZeroingData(data: data)

        sut.resize(toSize: 5)
        XCTAssertEqual(sut.count, 5)
        XCTAssertEqual(sut.toData(), data.subdata(in: 0..<5))
    }

    func test_givenData_whenRemove_thenIsRemoved() {
        let data = Data(hex: "438ac4729847fb3975345983")
        let sut = CZeroingData(data: data)

        sut.remove(untilOffset: 5)
        XCTAssertEqual(sut.count, data.count - 5)
        XCTAssertEqual(sut.toData(), data.subdata(in: 5..<data.count))
    }

    func test_givenData_whenZero_thenIsZeroedOut() {
        let data = Data(hex: "438ac4729847fb3975345983")
        let sut = CZeroingData(data: data)

        sut.zero()
        XCTAssertEqual(sut.count, data.count)
        XCTAssertEqual(sut.toData(), Data(repeating: 0, count: data.count))
    }

    func test_givenData_whenCompareEqual_thenIsEqual() {
        let data = Data(hex: "438ac4729847fb3975345983")
        let sut = CZeroingData(data: data)
        let other = CZeroingData(data: data)

        XCTAssertEqual(sut, other)
        XCTAssertEqual(sut, sut.copy())
        XCTAssertEqual(other, other.copy())
        XCTAssertEqual(sut.copy(), other.copy())

        sut.append(CZeroingData(count: 1))
        XCTAssertNotEqual(sut, other)
        other.append(CZeroingData(count: 1))
        XCTAssertEqual(sut, other)
    }

    func test_givenData_whenManipulate_thenDataIsExpected() {
        let z1 = CZeroingData(count: 0)
        z1.append(CZeroingData(data: Data(hex: "12345678")))
        z1.append(CZeroingData(data: Data(hex: "abcdef")))
        let z2 = z1.withOffset(2, length: 3) // 5678ab
        let z3 = z2.appending(CZeroingData(data: Data(hex: "aaddcc"))) // 5678abaaddcc

        XCTAssertEqual(z1.toData(), Data(hex: "12345678abcdef"))
        XCTAssertEqual(z2.toData(), Data(hex: "5678ab"))
        XCTAssertEqual(z3.toData(), Data(hex: "5678abaaddcc"))
    }
}
