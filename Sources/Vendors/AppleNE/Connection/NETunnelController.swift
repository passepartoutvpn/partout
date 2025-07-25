//
//  NETunnelController.swift
//  Partout
//
//  Created by Davide De Rosa on 3/28/24.
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
@preconcurrency import NetworkExtension
import PartoutCore

/// Implementation of a ``/PartoutCore/TunnelController`` via `NEPacketTunnelProvider`.
public final class NETunnelController: TunnelController {
    public struct Options: Sendable {
        public var dnsFallbackServers: [String]

        public init() {
            dnsFallbackServers = []
        }
    }

    public private(set) weak var provider: NEPacketTunnelProvider?

    public let registry: Registry

    private let options: Options

    public let profile: Profile

    public let originalProfile: Profile

    public let environment: TunnelEnvironment

    public init(
        provider: NEPacketTunnelProvider,
        decoder: NEProtocolDecoder,
        registry: Registry,
        options: Options,
        environmentFactory: @escaping (Profile.ID) -> TunnelEnvironment,
        willProcess: ((Profile) async throws -> Profile)? = nil
    ) async throws {
        guard let tunnelConfiguration = provider.protocolConfiguration as? NETunnelProviderProtocol else {
            throw PartoutError(.decoding)
        }
        self.provider = provider
        self.registry = registry
        self.options = options
        originalProfile = try decoder.profile(from: tunnelConfiguration)
        let resolvedProfile = try registry.resolvedProfile(originalProfile)
        profile = try await willProcess?(resolvedProfile) ?? resolvedProfile
        environment = environmentFactory(profile.id)
    }

    public func setTunnelSettings(with info: TunnelRemoteInfo?) async throws {
        guard let provider else {
            logReleasedProvider()
            return
        }
        let tunnelSettings = profile.networkSettings(with: info, options: options)
        pp_log_id(profile.id, .ne, .info, "Commit tunnel settings: \(tunnelSettings)")
        try await provider.setTunnelNetworkSettings(tunnelSettings)
    }

    public func clearTunnelSettings() async {
        do {
            pp_log_id(profile.id, .ne, .info, "Clear tunnel settings")
            try await provider?.setTunnelNetworkSettings(nil)
        } catch {
            pp_log_id(profile.id, .ne, .error, "Unable to clear tunnel settings: \(error)")
        }
    }

    public func setReasserting(_ reasserting: Bool) {
        guard let provider else {
            logReleasedProvider()
            return
        }
        guard reasserting != provider.reasserting else {
            return
        }
        provider.reasserting = reasserting
    }

    public func cancelTunnelConnection(with error: Error?) {
        guard let provider else {
            logReleasedProvider()
            return
        }
        if let error {
            pp_log_id(profile.id, .ne, .fault, "Dispose tunnel: \(error)")
        } else {
            pp_log_id(profile.id, .ne, .notice, "Dispose tunnel")
        }
        provider.cancelTunnelWithError(error)
    }
}

private extension NETunnelController {
    func logReleasedProvider() {
        pp_log_id(profile.id, .ne, .info, "NETunnelController: NEPacketTunnelProvider released")
    }
}
