//
//  Partout.swift
//  Partout
//
//  Created by Davide De Rosa on 3/29/24.
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

// MARK: Core

@_exported import PartoutCore
@_exported import PartoutProviders

// MARK: - Optional

#if canImport(PartoutOpenVPN)
@_exported import PartoutOpenVPN
#endif

#if canImport(PartoutWireGuard)
@_exported import PartoutWireGuard
#endif

#if canImport(PartoutAPI)
@_exported import PartoutAPI
@_exported import PartoutAPIBundle
#endif

// MARK: - Vendors

@_exported import _PartoutVendorsPortable
#if canImport(_PartoutVendorsApple)
@_exported import _PartoutVendorsApple
@_exported import _PartoutVendorsAppleNE
#endif
