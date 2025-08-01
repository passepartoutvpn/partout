// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import _PartoutVendorsPortable_C
import Foundation

public final class CZeroingData {
    public let ptr: UnsafeMutablePointer<zeroing_data_t>

    public init(ptr: UnsafeMutablePointer<zeroing_data_t>) {
        self.ptr = ptr
    }

    public init(count: Int) {
        ptr = zd_create(count)
    }

    public init(bytes: UnsafePointer<UInt8>, count: Int) {
        ptr = zd_create_from_data(bytes, count)
    }

    public init(uInt8: UInt8) {
        var value = uInt8
        ptr = zd_create_from_data(&value, 1)
    }

    public init(uInt16: UInt16) {
        var value = uInt16
        ptr = withUnsafeBytes(of: &value) {
            guard let bytes = $0.bindMemory(to: UInt8.self).baseAddress else {
                fatalError("Could not bind to memory")
            }
            return zd_create_from_data(bytes, 2)
        }
    }

    public init(data: Data) {
        ptr = data.withUnsafeBytes {
            guard let bytes = $0.bindMemory(to: UInt8.self).baseAddress else {
                fatalError("Could not bind to memory")
            }
            return zd_create_from_data(bytes, data.count)
        }
    }

    public init(data: Data, offset: Int, count: Int) {
        ptr = data.withUnsafeBytes {
            guard let bytes = $0.bindMemory(to: UInt8.self).baseAddress else {
                fatalError("Could not bind to memory")
            }
            return zd_create_from_data_range(bytes, offset, count)
        }
    }

    public init(string: String, nullTerminated: Bool) {
        guard let cstr = string.cString(using: .utf8) else {
            ptr = zd_create(0)
            return
        }
        ptr = zd_create_from_string(cstr, nullTerminated)
    }

    deinit {
        zd_free(ptr)
    }
}

// MARK: Properties

extension CZeroingData {
    public var bytes: UnsafePointer<UInt8>! {
        zd_bytes(ptr)
    }

    public var mutableBytes: UnsafeMutablePointer<UInt8>! {
        zd_mutable_bytes(ptr)
    }

    public var count: Int {
        zd_length(ptr)
    }
}

extension CZeroingData: Equatable {
    public static func == (lhs: CZeroingData, rhs: CZeroingData) -> Bool {
        zd_equals(lhs.ptr, rhs.ptr)
    }

    public func isEqual(to data: Data) -> Bool {
        let length = data.count
        return data.withUnsafeBytes { dataPtr in
            zd_equals_to_data(ptr, dataPtr.bytePointer, length)
        }
    }
}

// MARK: Copy

extension CZeroingData {
    public func copy() -> CZeroingData {
        CZeroingData(ptr: zd_make_copy(ptr))
    }

    public func withOffset(_ offset: Int, length: Int) -> CZeroingData {
        guard let slice = zd_make_slice(ptr, offset, length) else {
            return CZeroingData(count: 0)
        }
        return CZeroingData(ptr: slice)
    }

    public func appending(_ other: CZeroingData) -> CZeroingData {
        let copy = zd_make_copy(ptr)
        zd_append(copy, other.ptr)
        return CZeroingData(ptr: copy)
    }
}

// MARK: Side effect

extension CZeroingData {
    public func zero() {
        zd_zero(ptr)
    }

    public func resize(toSize size: Int) {
        zd_resize(ptr, size)
    }

    public func remove(untilOffset offset: Int) {
        zd_remove_until(ptr, offset)
    }

    public func append(_ other: CZeroingData) {
        zd_append(ptr, other.ptr)
    }
}

// MARK: Accessors

extension CZeroingData {
    public func networkUInt16Value(fromOffset offset: Int) -> UInt16 {
        endian_ntohs(zd_uint16(ptr, offset))
    }

    public func nullTerminatedString(fromOffset offset: Int) -> String? {
        var nullOffset: Int?
        var i = offset
        while i < count {
            if bytes[i] == 0 {
                nullOffset = i
                break
            }
            i += 1
        }
        guard let nullOffset else {
            return nil
        }
        let stringLength = nullOffset - offset
        let data = Data(bytes: bytes, count: stringLength)
        return String(data: data, encoding: .utf8)
    }

    public func toData(until: Int? = nil) -> Data {
        if let until {
            precondition(until <= ptr.pointee.length)
        }
        return Data(bytes: ptr.pointee.bytes, count: until ?? ptr.pointee.length)
    }

    public func toHex() -> String {
        guard let bytes else {
            return ""
        }
        var hexString = ""
        for i in 0..<count {
            hexString += String(format: "%02x", bytes[i])
        }
        return hexString
    }
}
