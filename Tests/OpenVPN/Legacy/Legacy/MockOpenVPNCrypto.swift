// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

internal import _PartoutOpenVPNLegacy_ObjC
import Foundation

final class MockOpenVPNCrypto: OpenVPNCryptoProtocol {
    func configure(with options: OpenVPNCryptoOptions) throws {
    }

    func options() -> OpenVPNCryptoOptions? {
        nil
    }

    func version() -> String {
        ""
    }

    func digestLength() -> Int {
        0
    }

    func tagLength() -> Int {
        0
    }

    func hmac(withDigestName digestName: String, secret: UnsafePointer<UInt8>, secretLength: Int, data: UnsafePointer<UInt8>, dataLength: Int, hmac: UnsafeMutablePointer<UInt8>, hmacLength: UnsafeMutablePointer<Int>) throws {
    }

    func encrypter() -> any Encrypter & DataPathEncrypterProvider {
        MockEncrypter()
    }

    func decrypter() -> any Decrypter & DataPathDecrypterProvider {
        MockDecrypter()
    }
}

private final class MockEncrypter: Encrypter, DataPathEncrypterProvider {
    func configureEncryption(withCipherKey cipherKey: ZeroingData?, hmacKey: ZeroingData?) {
    }

    func encryptBytes(_ bytes: UnsafePointer<UInt8>, length: Int, dest: UnsafeMutablePointer<UInt8>, destLength: UnsafeMutablePointer<Int>, flags: UnsafePointer<CryptoFlags>?) throws {
    }

    func dataPathEncrypter() -> any DataPathEncrypter {
        MockDataPathEncrypter()
    }

    func digestLength() -> Int32 {
        0
    }

    func tagLength() -> Int32 {
        0
    }

    func encryptionCapacity(withLength length: Int) -> Int {
        0
    }
}

private final class MockDataPathEncrypter: DataPathEncrypter {
    func assembleDataPacket(_ block: DataPathAssembleBlock?, packetId: UInt32, payload: Data, into packetBytes: UnsafeMutablePointer<UInt8>, length packetLength: UnsafeMutablePointer<Int>) {
    }

    func encryptedDataPacket(withKey key: UInt8, packetId: UInt32, packetBytes: UnsafePointer<UInt8>, packetLength: Int) throws -> Data {
        Data()
    }

    func peerId() -> UInt32 {
        0
    }

    func setPeerId(_ peerId: UInt32) {
    }

    func encryptionCapacity(withLength length: Int) -> Int {
        0
    }
}

private final class MockDecrypter: Decrypter, DataPathDecrypterProvider {
    func configureDecryption(withCipherKey cipherKey: ZeroingData?, hmacKey: ZeroingData?) {
    }

    func decryptBytes(_ bytes: UnsafePointer<UInt8>, length: Int, dest: UnsafeMutablePointer<UInt8>, destLength: UnsafeMutablePointer<Int>, flags: UnsafePointer<CryptoFlags>?) throws {
    }

    func verifyBytes(_ bytes: UnsafePointer<UInt8>, length: Int, flags: UnsafePointer<CryptoFlags>?) throws {
    }

    func dataPathDecrypter() -> any DataPathDecrypter {
        MockDataPathDecrypter()
    }

    func digestLength() -> Int32 {
        0
    }

    func tagLength() -> Int32 {
        0
    }

    func encryptionCapacity(withLength length: Int) -> Int {
        0
    }
}

private final class MockDataPathDecrypter: DataPathDecrypter {
    func decryptDataPacket(_ packet: Data, into packetBytes: UnsafeMutablePointer<UInt8>, length packetLength: UnsafeMutablePointer<Int>, packetId: UnsafeMutablePointer<UInt32>) throws {
    }

    func parsePayload(_ block: DataPathParseBlock?, compressionHeader: UnsafeMutablePointer<UInt8>, packetBytes: UnsafeMutablePointer<UInt8>, packetLength: Int) throws -> Data {
        Data()
    }

    func peerId() -> UInt32 {
        0
    }

    func setPeerId(_ peerId: UInt32) {
    }

    func encryptionCapacity(withLength length: Int) -> Int {
        0
    }
}
