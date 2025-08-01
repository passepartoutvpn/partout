// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

internal import _PartoutVendorsCryptoCore_C
internal import _PartoutVendorsPortable

extension CZeroingData {
    static func forHMAC() -> CZeroingData {
        CZeroingData(ptr: key_hmac_create())
    }

    func hmac(
        with digestName: String,
        secret: CZeroingData,
        data: CZeroingData
    ) throws -> CZeroingData {
        let hmacLength = digestName.withCString { cDigest in
            var ctx = key_hmac_ctx(
                dst: ptr,
                digest_name: cDigest,
                secret: secret.ptr,
                data: data.ptr
            )
            return key_hmac_do(&ctx)
        }
        guard hmacLength > 0 else {
            throw CryptoError.hmac
        }
        return CZeroingData(
            bytes: ptr.pointee.bytes,
            count: hmacLength
        )
    }
}
