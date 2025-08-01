// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import PartoutOpenVPN

extension Notification.Name {
    static let tlsDidFailVerificationNotification = Notification.Name("TLSDidFailVerificationNotification")
}

final class TLSWrapper {
    struct Parameters {
        let cachesURL: URL

        let cfg: OpenVPN.Configuration

        let onVerificationFailure: () -> Void
    }

    let tls: TLSProtocol

    init(tls: TLSProtocol) {
        self.tls = tls
    }
}
