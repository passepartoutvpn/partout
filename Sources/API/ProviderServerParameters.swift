// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import PartoutCore
import PartoutProviders

public struct ProviderServerParameters {
    public var filters: ProviderFilters

    public var sorting: [ProviderSortField]

    public init(filters: ProviderFilters = ProviderFilters(), sorting: [ProviderSortField] = []) {
        self.filters = filters
        self.sorting = sorting
    }
}

public struct ProviderFilters: Equatable {
    public var moduleType: ModuleType?

    public var categoryName: String?

    public var countryCode: String?

    public var area: String?

    public var presetId: String?

    public var serverIds: Set<String>?

    public init() {
    }
}

public enum ProviderSortField {
    case localizedCountry

    case area

    case serverId
}

public struct ProviderFilterOptions {
    public let countriesByCategoryName: [String: Set<String>]

    public let countryCodes: Set<String>

    public let presets: Set<ProviderPreset>

    public init(countriesByCategoryName: [String: Set<String>] = [:], countryCodes: Set<String> = [], presets: Set<ProviderPreset> = []) {
        self.countriesByCategoryName = countriesByCategoryName
        self.countryCodes = countryCodes
        self.presets = presets
    }
}
