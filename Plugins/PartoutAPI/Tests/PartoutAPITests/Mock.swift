//
//  Mock.swift
//  Partout
//
//  Created by Davide De Rosa on 10/7/24.
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

import Combine
import Foundation
@testable import PartoutAPI
import PartoutCore

struct MockModule: Module {
    static let moduleHandler = ModuleHandler(ModuleType("mock-module"), decoder: nil, factory: nil)

    var supportedField = 123
}

struct MockUnsupportedModule: Module {
    static let moduleHandler = ModuleHandler(ModuleType("mock-unsupported-module"), decoder: nil, factory: nil)

    let unsupportedField: Int
}

extension ProviderID {
    static let mock = ProviderID(rawValue: "mock-provider")
}

struct MockAPI: APIMapper {
    func index() async throws -> [Provider] {
        [
            Provider("foo1", description: "bar1"),
            Provider("foo2", description: "bar2", moduleTypes: [MockModule.self]),
            Provider("foo3", description: "bar3")
        ]
    }

    func infrastructure(for providerId: ProviderID, cache: ProviderCache?) async throws -> ProviderInfrastructure {
        ProviderInfrastructure(
            presets: [
                ProviderPreset(
                    providerId: .mock,
                    presetId: "default",
                    description: "MockPreset",
                    moduleType: ModuleType("mock-module"),
                    templateData: Data()
                )
            ],
            servers: [.mock],
            cache: nil
        )
    }
}

final class MockRepository: APIRepository, ObservableObject {

    @Published
    private(set) var providers: [Provider] = []

    @Published
    private(set) var infrastructures: [ProviderID: ProviderInfrastructure] = [:]

    var indexPublisher: AnyPublisher<[Provider], Never> {
        $providers
            .eraseToAnyPublisher()
    }

    var cachePublisher: AnyPublisher<[ProviderID: ProviderCache], Never> {
        $infrastructures
            .map {
                $0.compactMapValues(\.cache)
            }
            .eraseToAnyPublisher()
    }

    func store(_ providers: [Provider]) async throws {
        self.providers = providers
    }

    func store(_ infrastructure: ProviderInfrastructure, for providerId: ProviderID) async throws {
        infrastructures[providerId] = infrastructure
    }

    func presets(for server: ProviderServer, moduleType: ModuleType) async throws -> [ProviderPreset] {
        []
    }

    func providerRepository(for providerId: ProviderID) -> ProviderRepository {
        let infra = infrastructures[providerId]
        let repo = MockVPNRepository(providerId: providerId)
        repo.allServers = infra?.servers ?? []
        repo.allPresets = infra?.presets ?? []
        return repo
    }

    func resetCache(for providerIds: [ProviderID]?) async {
    }
}

final class MockVPNRepository: ProviderRepository {
    let providerId: ProviderID

    var allServers: [ProviderServer] = []

    var allPresets: [ProviderPreset] = []

    init(providerId: ProviderID) {
        self.providerId = providerId
    }

    func availableOptions(for moduleType: ModuleType) async throws -> ProviderFilterOptions {
        let allCategoryNames = Set(allServers.map(\.metadata.categoryName))
        let allCountryCodes = Set(allServers.map(\.metadata.countryCode))
        return ProviderFilterOptions(
            countriesByCategoryName: allCategoryNames.reduce(into: [:]) {
                $0[$1] = allCountryCodes
            },
            countryCodes: allCountryCodes,
            presets: Set(allPresets)
        )
    }

    func filteredServers(with parameters: ProviderServerParameters?) async -> [ProviderServer] {
        if parameters?.filters.categoryName != nil {
            return []
        }
        return allServers
    }
}

extension ProviderServer {
    static var mock: ProviderServer {
        ProviderServer(
            metadata: .init(
                providerId: .mock,
                categoryName: "Default",
                countryCode: "US",
                otherCountryCodes: nil,
                area: nil
            ),
            serverId: "mock",
            hostname: "mock-hostname.com",
            ipAddresses: [Data(hex: "01020304")],
            supportedModuleTypes: [MockModule.moduleHandler.id],
            supportedPresetIds: []
        )
    }
}
