//
//  DemoApp.swift
//  PassepartoutKit
//
//  Created by Davide De Rosa on 2/22/24.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of PassepartoutKit.
//
//  PassepartoutKit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  PassepartoutKit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with PassepartoutKit.  If not, see <http://www.gnu.org/licenses/>.
//

import PassepartoutKit
import SwiftUI

@main
struct DemoApp: App {
    init() {
        PassepartoutConfiguration.shared.logsModules = true
        PassepartoutConfiguration.shared.setLocalLogger(
            url: Demo.Log.appURL,
            options: .init(
                maxLevel: Demo.Log.maxLevel,
                maxSize: Demo.Log.maxSize,
                maxBufferedLines: Demo.Log.maxBufferedLines
            ),
            mapper: Demo.Log.formattedLine
        )
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
