//
//  Demo+Profile.swift
//  Partout
//
//  Created by Davide De Rosa on 2/22/24.
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
import Partout

extension Profile {
    static let demo: Profile = {
        do {
            guard let uuid = UUID(uuidString: "B316870C-4970-4981-8CE7-95700B2C33EC") else {
                fatalError("No UUID")
            }

            var profile = Profile.Builder(id: uuid)
            profile.name = "PartoutDemo"

            if let ovpn = OpenVPN.demoModule {
                profile.modules.append(ovpn)
            }
            if let wg = WireGuard.demoModule {
                profile.modules.append(wg)
            }

            var dns = DNSModule.Builder()
            dns.protocolType = .https
            dns.servers = ["1.1.1.1"]
            dns.dohURL = "https://1.1.1.1/dns-query"
            profile.modules.append(try dns.tryBuild())

            var ip = IPModule.Builder()
            ip.ipv4 = IPSettings(subnet: nil)
                .including(routes: [.init(defaultWithGateway: nil)])
//            ip.ipv4 = IPSettings(subnet: nil)
//                .excluding(routes: [
//                    .init(Subnet(rawValue: "192.168.43.0/24"), nil)
//                ])
            profile.modules.append(ip.tryBuild())
//
//            var onDemand = OnDemandModule.Builder()
//            onDemand.policy = .excluding
//            onDemand.withSSIDs = ["iPhonx": true]
//            profile.modules.append(onDemand.tryBuild())
//
//            var filterModule = FilterModule.Builder()
//            filterModule.disabledMask = [.dns]
//            profile.modules.append(filterModule.tryBuild())

            profile.activeModulesIds = [dns.id]

            let vpnModule = profile.modules.first {
                $0 is OpenVPNModule || $0 is WireGuardModule
            }
            if let vpnModule {
                profile.activeModulesIds.insert(vpnModule.id)
            }

            return try profile.tryBuild()
        } catch {
            fatalError("Cannot build: \(error)")
        }
    }()
}
