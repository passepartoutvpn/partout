//
//  Timestamp.swift
//  Partout
//
//  Created by Davide De Rosa on 7/15/25.
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

// TODO: ###, move to Core
public typealias Timestamp = UInt32

// seconds since the epoch
extension Timestamp {
    public var date: Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }

    // this can be easily done without Foundation
    public static func now() -> Self {
        UInt32(Date().timeIntervalSince1970)
    }
}

extension Date {
    public var timestamp: Timestamp {
        Timestamp(timeIntervalSince1970)
    }
}
