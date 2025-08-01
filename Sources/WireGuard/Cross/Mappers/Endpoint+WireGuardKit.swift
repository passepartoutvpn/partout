// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import PartoutCore

extension PartoutCore.Endpoint {
    init?(wg: Endpoint) {
        guard let address = Address(rawValue: wg.host.debugDescription) else {
            return nil
        }
        self.init(address, wg.port.rawValue)
    }

    func toWireGuardEndpoint() throws -> Endpoint {
        let wgAddress: String
        switch address {
        case .ip(let raw, let family):
            wgAddress = family == .v6 ? "[\(raw)]" : raw
        case .hostname(let raw):
            wgAddress = raw
        }
        guard let wg = Endpoint(from: "\(wgAddress):\(port)") else {
            throw PartoutError(.parsing)
        }
        return wg
    }
}

extension Endpoint {
    var toEndpoint: PartoutCore.Endpoint? {
        .init(wg: self)
    }
}
