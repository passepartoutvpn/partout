// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

internal import _PartoutVendorsCryptoCore_C
@testable internal import _PartoutVendorsPortable
import Foundation

final class CryptoWrapper {
    private let ptr: crypto_ctx

    private let free_fn: crypto_free_fn

    init(
        withAEADCipherName cipherName: String,
        tagLength: Int,
        idLength: Int
    ) throws {
        guard let ptr = crypto_aead_create(cipherName, tagLength, idLength, nil) else {
            throw CryptoError()
        }
        NSLog("PartoutOpenVPN: Using CryptoAEAD (native Swift/C)")
        self.ptr = ptr
        free_fn = crypto_aead_free
    }

    init(
        withCBCCipherName cipherName: String?,
        digestName: String
    ) throws {
        guard let ptr = crypto_cbc_create(cipherName, digestName, nil) else {
            throw CryptoError()
        }
        NSLog("PartoutOpenVPN: Using CryptoCBC (native Swift/C)")
        self.ptr = ptr
        free_fn = crypto_cbc_free
    }

    init(
        withCTRCipherName cipherName: String,
        digestName: String,
        tagLength: Int,
        payloadLength: Int
    ) throws {
        guard let ptr = crypto_ctr_create(cipherName, digestName, tagLength, payloadLength, nil) else {
            throw CryptoError()
        }
        NSLog("PartoutOpenVPN: Using CryptoCTR (native Swift/C)")
        self.ptr = ptr
        free_fn = crypto_ctr_free
    }

    deinit {
        free_fn(ptr)
    }

    func encryptionCapacity(for length: Int) -> Int {
        crypto_encryption_capacity(ptr, length)
    }

    func configureEncryption(withCipherKey cipherKey: CZeroingData?, hmacKey: CZeroingData?) {
        crypto_configure_encrypt(ptr, cipherKey?.ptr, hmacKey?.ptr)
    }

    func encryptBytes(_ bytes: UnsafePointer<UInt8>, length: Int, dest: CZeroingData, flags: UnsafePointer<crypto_flags_t>?) throws -> Int {
        var code = CryptoErrorNone
        let destLength = crypto_encrypt(ptr, dest.mutableBytes, dest.count, bytes, length, flags, &code)
        guard destLength > 0 else {
            throw CryptoError(code)
        }
        return destLength
    }

    func configureDecryption(withCipherKey cipherKey: CZeroingData?, hmacKey: CZeroingData?) {
        crypto_configure_decrypt(ptr, cipherKey?.ptr, hmacKey?.ptr)
    }

    func decryptBytes(_ bytes: UnsafePointer<UInt8>, length: Int, dest: CZeroingData, flags: UnsafePointer<crypto_flags_t>?) throws -> Int {
        var code = CryptoErrorNone
        let destLength = crypto_decrypt(ptr, dest.mutableBytes, dest.count, bytes, length, flags, &code)
        guard destLength > 0 else {
            throw CryptoError(code)
        }
        return destLength
    }

    func verifyBytes(_ bytes: UnsafePointer<UInt8>, length: Int, flags: UnsafePointer<crypto_flags_t>?) throws -> Bool {
        var code = CryptoErrorNone
        guard crypto_verify(ptr, bytes, length, &code) else {
            throw CryptoError(code)
        }
        return true
    }
}
