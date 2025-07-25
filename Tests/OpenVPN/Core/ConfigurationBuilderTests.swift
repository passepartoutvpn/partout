//
//  ConfigurationBuilderTests.swift
//  Partout
//
//  Created by Davide De Rosa on 1/18/25.
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

import PartoutOpenVPN
import Foundation
import Testing

struct ConfigurationBuilderTests {
    @Test
    func givenBuilder_whenClient_thenHasFallbackValues() throws {
        var sut = OpenVPN.Configuration.Builder()
        sut.ca = .init(pem: "")
        sut.remotes = [.init(rawValue: "1.2.3.4:UDP:1000")!]
        let cfg = try sut.tryBuild(isClient: true)
        #expect(cfg.cipher == .aes128cbc)
        #expect(cfg.digest == nil)
        #expect(cfg.compressionFraming == nil)
        #expect(cfg.compressionAlgorithm == nil)
    }

    @Test
    func givenBuilder_whenNonClient_thenHasNoFallbackValues() throws {
        let sut = OpenVPN.Configuration.Builder()
        let cfg = try sut.tryBuild(isClient: false)
        #expect(cfg.cipher == nil)
        #expect(cfg.digest == nil)
        #expect(cfg.compressionFraming == nil)
        #expect(cfg.compressionAlgorithm == nil)
    }
}
