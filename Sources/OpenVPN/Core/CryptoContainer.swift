//
//  CryptoContainer.swift
//  Partout
//
//  Created by Davide De Rosa on 8/22/18.
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
//  This file incorporates work covered by the following copyright and
//  permission notice:
//
//      Copyright (c) 2018-Present Private Internet Access
//
//      Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//      The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import PartoutCore

extension OpenVPN {

    /// Represents a cryptographic container in PEM format.
    public struct CryptoContainer: Hashable, Sendable {
        private static let begin = "-----BEGIN "

        private static let end = "-----END "

        /// The content in PEM format (ASCII).
        public let pem: String

        public var isEncrypted: Bool {
            return pem.contains("ENCRYPTED")
        }

        public init(pem: String) {
            guard let beginRange = pem.range(of: CryptoContainer.begin) else {
                self.pem = ""
                return
            }
            self.pem = String(pem[beginRange.lowerBound...])
        }

        public func write(to url: URL) throws {
            try pem.write(to: url, atomically: true, encoding: .ascii)
        }

        public func decrypted(with decrypter: KeyDecrypter, passphrase: String) throws -> CryptoContainer {
            let decryptedPEM = try decrypter.decryptedKey(fromPEM: pem, passphrase: passphrase)
            return CryptoContainer(pem: decryptedPEM)
        }
    }
}

// MARK: - Codable

extension OpenVPN.CryptoContainer: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let pem = try container.decode(String.self)
        self.init(pem: pem)
    }

    public func encode(to encoder: Encoder) throws {
        try encodeSensitiveDescription(to: encoder)
    }
}

// MARK: - SensitiveDebugStringConvertible

extension OpenVPN.CryptoContainer: SensitiveDebugStringConvertible {
    public func debugDescription(withSensitiveData: Bool) -> String {
        withSensitiveData ? pem : JSONEncoder.redactedValue
    }
}
