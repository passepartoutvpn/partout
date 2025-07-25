//
//  CryptoCTRTests.swift
//  Partout
//
//  Created by Davide De Rosa on 12/12/23.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Partout.
//
//  Partout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Partout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Partout.  If not, see <http://www.gnu.org/licenses/>.
//

internal import _PartoutCryptoOpenSSL_ObjC
import XCTest

final class CryptoCTRTests: XCTestCase, CryptoFlagsProviding {
    func test_givenData_whenEncrypt_thenDecrypts() throws {
        let sut = try CryptoCTR(
            cipherName: "aes-128-ctr",
            digestName: "sha256",
            tagLength: 32,
            payloadLength: 128
        )

        sut.configureEncryption(withCipherKey: cipherKey, hmacKey: hmacKey)
        sut.configureDecryption(withCipherKey: cipherKey, hmacKey: hmacKey)
        let encryptedData: Data

        do {
            encryptedData = try withCryptoFlags {
                try sut.encryptData(plainData, flags: $0)
            }
        } catch {
            XCTFail("Cannot encrypt: \(error)")
            return
        }
        do {
            let returnedData = try withCryptoFlags {
                try sut.decryptData(encryptedData, flags: $0)
            }
            XCTAssertEqual(returnedData, plainData)
        } catch {
            XCTFail("Cannot decrypt: \(error)")
        }
    }
}

extension CryptoCTRTests {
    var cipherKey: ZeroingData {
        ZeroingData(length: 32)
    }

    var hmacKey: ZeroingData {
        ZeroingData(length: 32)
    }

    var plainData: Data {
        Data(hex: "00112233ffddaa")
    }

    var packetId: [UInt8] {
        [0x56, 0x34, 0x12, 0x00]
    }

    var ad: [UInt8] {
        [0x00, 0x12, 0x34, 0x56]
    }
}
