//
//  AppleRandomTests.swift
//  Partout
//
//  Created by Davide De Rosa on 4/9/24.
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

import _PartoutVendorsApple
import Foundation
import XCTest

final class AppleRandomTests: XCTestCase {
    private let sut = AppleRandom()

    func test_givenPRNG_whenGenerateData_thenHasGivenLength() {
        XCTAssertEqual(sut.data(length: 123).count, 123)
    }

    func test_givenPRNG_whenGenerateSuite_thenHasGivenParameters() {
        let length = 52
        let elements = 680
        let suite = sut.suite(withDataLength: 52, numberOfElements: 680)

        XCTAssertEqual(suite.count, elements)
        suite.forEach {
            XCTAssertEqual($0.count, length)
        }
    }
}
