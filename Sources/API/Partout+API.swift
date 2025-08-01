// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Foundation
import PartoutCore

extension LoggerCategory {
    public static let api = Self(rawValue: "api")
}

extension PartoutError.Code {
    public enum API {

        /// The API engine encountered an error.
        public static let engineError = PartoutError.Code("API.engineError")
    }
}
