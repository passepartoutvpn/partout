//
//  CFDNSStrategy.swift
//  Partout
//
//  Created by Davide De Rosa on 3/15/24.
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

/// `CoreFoundation` implementation of ``SimpleDNSStrategy``.
public actor CFDNSStrategy: SimpleDNSStrategy {
    private let host: CFHost

    private var resolutionTask: Task<[DNSRecord], Error>?

    public init(hostname: String) {
        let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
        var context = CFHostClientContext()
        CFHostSetClient(host, cfHostCallback, &context)
        CFHostScheduleWithRunLoop(host, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        self.host = host
    }

    public func startResolution() async throws {
        guard resolutionTask == nil else {
            assertionFailure("Calling startResolution() multiple times?")
            return
        }
        resolutionTask = Task {
            let sequence = NotificationCenter.default.notifications(named: Self.didComplete, object: host)
            for await notification in sequence {
                if let records = notification.userInfo?[CFDNSStrategy.recordsKey] as? [DNSRecord] {
                    return records
                }
                if let error = notification.userInfo?[CFDNSStrategy.errorKey] as? Error {
                    throw error
                }
                break
            }
            throw PartoutError(.dnsFailure)
        }
        guard CFHostStartInfoResolution(host, .addresses, nil) else {
            resolutionTask?.cancel()
            resolutionTask = nil
            throw PartoutError(.operationCancelled)
        }
    }

    public func waitForResolution() async throws -> [DNSRecord] {
        guard let resolutionTask else {
            return []
        }
        defer {
            self.resolutionTask = nil
        }
        return try await resolutionTask.value
    }

    public func cancelResolution() {
        CFHostCancelInfoResolution(host, .addresses)
        resolutionTask?.cancel()
        resolutionTask = nil
    }
}

private extension CFDNSStrategy {
    static nonisolated let didComplete = Notification.Name("CFDNSStrategy.didComplete")

    static nonisolated let recordsKey = "Records"

    static nonisolated let errorKey = "Error"
}

// MARK: - CoreFoundation

private func cfHostCallback(
    host: CFHost,
    typeInfo: CFHostInfoType,
    error: UnsafePointer<CFStreamError>?,
    info: UnsafeMutableRawPointer?
) {
    do {
        let records = try host.resolvedRecords()
        NotificationCenter.default.post(name: CFDNSStrategy.didComplete, object: host, userInfo: [
            CFDNSStrategy.recordsKey: records
        ])
    } catch {
        NotificationCenter.default.post(name: CFDNSStrategy.didComplete, object: host, userInfo: [
            CFDNSStrategy.errorKey: error
        ])
    }
}

// MARK: - Translation

private extension CFHost {
    func resolvedRecords() throws -> [DNSRecord] {
        var success: DarwinBoolean = false
        guard let rawAddresses = CFHostGetAddressing(self, &success)?.takeUnretainedValue() as Array? else {
            throw PartoutError(.dnsFailure)
        }

        let records = rawAddresses
            .compactMap { $0 as? Data }
            .compactMap(\.asDNSRecord)

        guard !records.isEmpty else {
            throw PartoutError(.dnsFailure)
        }
        return records
    }
}

private extension Data {
    var asDNSRecord: DNSRecord? {
        var ipAddress = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let result: Int32 = withUnsafeBytes {
            guard let addr = $0.bindMemory(to: sockaddr.self).baseAddress else {
                return .zero
            }
            return getnameinfo(
                addr,
                socklen_t(count),
                &ipAddress,
                socklen_t(ipAddress.count),
                nil,
                0,
                NI_NUMERICHOST
            )
        }
        guard result == 0 else {
            return nil
        }
        let address = String(cString: ipAddress)
        return DNSRecord(address: address, isIPv6: address.contains(":"))
    }
}
