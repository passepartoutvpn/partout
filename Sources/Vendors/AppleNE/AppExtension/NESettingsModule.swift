//
//  NESettingsModule.swift
//  Partout
//
//  Created by Davide De Rosa on 3/26/24.
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
import NetworkExtension
import PartoutCore

/// A transient ``/PartoutCore/Module`` that embeds a full set of `NEPacketTunnelNetworkSettings`.
public struct NESettingsModule: Module, @unchecked Sendable {
    public let id: UUID

    public var checksum: Int {
        fullSettings.hashValue
    }

    private let fullSettings: NEPacketTunnelNetworkSettings

    public init(fullSettings: NEPacketTunnelNetworkSettings) {
        id = UUID()
        self.fullSettings = fullSettings
    }
}

extension NESettingsModule: NESettingsApplying {
    public func apply(_ ctx: PartoutLoggerContext, to settings: inout NEPacketTunnelNetworkSettings) {
        settings = fullSettings
    }
}

extension NESettingsModule: SensitiveDebugStringConvertible {
    public func debugDescription(withSensitiveData: Bool) -> String {
        withSensitiveData ? fullSettings.debugDescription : "NEPacketTunnelNetworkSettings"
    }
}
