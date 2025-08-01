// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

internal import _PartoutVendorsPortable

struct Handshake {
    let preMaster: CZeroingData

    let random1: CZeroingData

    let random2: CZeroingData

    let serverRandom1: CZeroingData

    let serverRandom2: CZeroingData
}
