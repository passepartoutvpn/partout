// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import NetworkExtension

extension NEIPv6Route {
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Self else {
            return false
        }
        return equalitySubject == other.equalitySubject
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(equalitySubject)
        return hasher.finalize()
    }

    open override var debugDescription: String {
        "\(destinationAddress)/\(destinationNetworkPrefixLength) -> \(gatewayAddress ?? "*")"
    }
}

private extension NEIPv6Route {
    var equalitySubject: [String?] {
        [
            destinationAddress,
            destinationNetworkPrefixLength.stringValue,
            gatewayAddress
        ]
    }
}
