//
//  ProviderTemplateCompiler.swift
//  Partout
//
//  Created by Davide De Rosa on 10/8/24.
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
import PartoutCore

public protocol ProviderTemplateCompiler {
    associatedtype CompiledModule: Module

    associatedtype Options: ProviderOptions

    static func compiled(with id: UUID, entity: ProviderEntity, options: Options?) throws -> CompiledModule
}

extension ProviderTemplateCompiler {
    public var moduleType: ModuleType {
        CompiledModule.moduleHandler.id
    }
}

extension ProviderModule {
    public func compiled<T>(withTemplate templateType: T.Type) throws -> Module where T: ProviderTemplateCompiler {
        guard let entity else {
            throw PartoutError(.API.missingProviderEntity)
        }
        let options: T.Options? = options(for: providerModuleType)
        return try T.compiled(with: id, entity: entity, options: options)
    }
}
