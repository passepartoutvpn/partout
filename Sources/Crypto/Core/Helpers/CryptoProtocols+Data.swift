//
//  CryptoProtocols+Data.swift
//  Partout
//
//  Created by Davide De Rosa on 6/16/25.
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

import Foundation

extension Encrypter {
    func encryptData(_ data: Data, flags: CryptoFlagsWrapper?) throws -> Data {
        let srcLength = data.count
        var dest: [UInt8] = Array(repeating: 0, count: srcLength + 256)
        var destLength = 0
        _ = try data.withUnsafeBytes {
            try encryptBytes($0.bytePointer, length: srcLength, dest: &dest, destLength: &destLength, flags: flags)
        }
        dest.removeSubrange(destLength..<dest.count)
        return Data(dest)
    }
}

extension Decrypter {
    func decryptData(_ data: Data, flags: CryptoFlagsWrapper?) throws -> Data {
        let srcLength = data.count
        var dest: [UInt8] = Array(repeating: 0, count: srcLength + 256)
        var destLength = 0
        _ = try data.withUnsafeBytes {
            try decryptBytes($0.bytePointer, length: srcLength, dest: &dest, destLength: &destLength, flags: flags)
        }
        dest.removeSubrange(destLength..<dest.count)
        return Data(dest)
    }

    func verifyData(_ data: Data, flags: CryptoFlagsWrapper?) throws {
        let srcLength = data.count
        _ = try data.withUnsafeBytes {
            try verifyBytes($0.bytePointer, length: srcLength, flags: flags)
        }
    }
}
