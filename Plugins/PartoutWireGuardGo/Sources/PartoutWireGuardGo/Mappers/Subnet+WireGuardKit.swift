//
//  Subnet+WireGuardKit.swift
//  Partout
//
//  Created by Davide De Rosa on 3/25/24.
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
import Network
import PartoutCore
internal import WireGuardKit

extension Subnet {
    init?(wg: IPAddressRange) {
        guard let ipAddress = wg.address.rawValue.asIPAddress,
              let address = Address(rawValue: ipAddress) else {
            return nil
        }
        self.init(address, Int(wg.networkPrefixLength))
    }

    func toWireGuardRange() throws -> IPAddressRange {
        guard let wg = IPAddressRange(from: "\(address)/\(prefixLength)") else {
            throw PartoutError(.parsing)
        }
        return wg
    }
}

extension IPAddressRange {
    var toSubnet: Subnet? {
        .init(wg: self)
    }
}
