//
//  CryptoFlagsProviding.swift
//  Partout
//
//  Created by Davide De Rosa on 1/14/25.
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

@testable internal import _PartoutCryptoCore

struct CryptoFlags {
    var iv: [UInt8] = []

    var ad: [UInt8] = []
    
    var forTesting = true
}

extension CryptoFlags {
    func withUnsafeFlags( _ block: @escaping (CryptoFlagsWrapper) throws -> Void) rethrows {
        try iv.withUnsafeBufferPointer { iv in
            try ad.withUnsafeBufferPointer { ad in
                let flags = CryptoFlagsWrapper(
                    iv: iv.baseAddress,
                    ivLength: iv.count,
                    ad: ad.baseAddress,
                    adLength: ad.count,
                    forTesting: forTesting
                )
                try block(flags)
            }
        }
    }
}
