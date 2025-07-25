//
//  WireGuardProviderStorage.swift
//  Partout
//
//  Created by Davide De Rosa on 12/2/24.
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

#if canImport(PartoutWireGuard)

import Foundation
import PartoutCore
import PartoutWireGuard

public struct WireGuardProviderStorage: ProviderOptions {

    // device id -> session
    public var sessions: [String: Session]?

    public init() {
    }
}

extension WireGuardProviderStorage {
    public struct Session: Hashable, Codable, Sendable {
        public let privateKey: String

        public let publicKey: String

        public private(set) var peer: Peer?

        init(privateKey: String, publicKey: String) {
            self.privateKey = privateKey
            self.publicKey = publicKey
        }

        public init(keyGenerator: WireGuardKeyGenerator) throws {
            privateKey = keyGenerator.newPrivateKey()
            publicKey = try keyGenerator.publicKey(for: privateKey)
            peer = nil
        }

        public func renewed(with keyGenerator: WireGuardKeyGenerator) throws -> Self {
            var newSession = try Self(keyGenerator: keyGenerator)
            newSession.peer = peer
            return newSession
        }

        func with(peer: Peer?) -> Self {
            var newSession = self
            newSession.peer = peer
            return newSession
        }
    }

    public struct Peer: Identifiable, Hashable, Codable, Sendable {
        public let id: String

        public let creationDate: Date

        public let addresses: [String]

        public init(id: String, creationDate: Date, addresses: [String]) {
            self.id = id
            self.creationDate = creationDate
            self.addresses = addresses
        }
    }
}

#endif
