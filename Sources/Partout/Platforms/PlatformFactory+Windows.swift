//
//  PlatformFactory+Windows.swift
//  Partout
//
//  Created by Davide De Rosa on 4/16/25.
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

#if canImport(_PartoutPlatformWindows)

import _PartoutPlatformWindows
import Foundation
import PartoutCore

public struct WindowsPlatformFactory: PlatformFactory {
    init() {
    }

    public func newPRNG(_ ctx: PartoutLoggerContext) -> PRNGProtocol {
        SimplePRNG()
    }

    public func newDNSResolver(_ ctx: PartoutLoggerContext) -> DNSResolver {
        UnsupportedPlatformFactory.shared.newDNSResolver()
    }

    public func newScriptingEngine(_ ctx: PartoutLoggerContext) -> ScriptingEngine {
        UnsupportedPlatformFactory.shared.newScriptingEngine()
    }
}

#if canImport(PartoutAPI)

extension WindowsPlatformFactory {
    public func newAPIScriptingEngine(_ ctx: PartoutLoggerContext) -> APIScriptingEngine {
        UnsupportedPlatformFactory.shared.newAPIScriptingEngine()
    }
}

#endif

#endif
