// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

@testable import PartoutOpenVPN
import Foundation
import PartoutCore
import Testing

struct StaticKeyTests {
    @Test
    func givenHex_whenBidirectional_thenSameSendReceiveKey() {
        let expected = Data(hex: "cf55d863fcbe314df5f0b45dbe974d9bde33ef5b4803c3985531c6c23ca6906d6cd028efc8585d1b9e71003566bd7891b9cc9212bcba510109922eed87f5c8e6")
        let key = OpenVPN.StaticKey(file: content, direction: nil)
        #expect(key != nil)

        #expect(key?.hmacSendKey == SecureData(expected))
        #expect(key?.hmacReceiveKey == SecureData(expected))
    }

    @Test
    func givenHex_whenClient_thenKeysAreExpected() {
        let send = Data(hex: "778a6b35a124e700920879f1d003ba93dccdb953cdf32bea03f365760b0ed8002098d4ce20d045b45a83a8432cc737677aed27125592a7148d25c87fdbe0a3f6")
        let receive = Data(hex: "cf55d863fcbe314df5f0b45dbe974d9bde33ef5b4803c3985531c6c23ca6906d6cd028efc8585d1b9e71003566bd7891b9cc9212bcba510109922eed87f5c8e6")
        let key = OpenVPN.StaticKey(file: content, direction: .client)
        #expect(key != nil)

        #expect(key?.hmacSendKey == SecureData(send))
        #expect(key?.hmacReceiveKey == SecureData(receive))
    }
}

// MARK: - Helpers

private extension StaticKeyTests {
    var content: String {
"""
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
48d9999bd71095b10649c7cb471c1051
b1afdece597cea06909b99303a18c674
01597b12c04a787e98cdb619ee960d90
a0165529dc650f3a5c6fbe77c91c137d
cf55d863fcbe314df5f0b45dbe974d9b
de33ef5b4803c3985531c6c23ca6906d
6cd028efc8585d1b9e71003566bd7891
b9cc9212bcba510109922eed87f5c8e6
6d8e59cbd82575261f02777372b2cd4c
a5214c4a6513ff26dd568f574fd40d6c
d450fc788160ff68434ce2bf6afb00e7
10a3198538f14c4d45d84ab42637872e
778a6b35a124e700920879f1d003ba93
dccdb953cdf32bea03f365760b0ed800
2098d4ce20d045b45a83a8432cc73767
7aed27125592a7148d25c87fdbe0a3f6
-----END OpenVPN Static key V1-----
"""
    }
}
