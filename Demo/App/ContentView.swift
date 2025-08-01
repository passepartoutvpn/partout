// SPDX-FileCopyrightText: 2025 Davide De Rosa
//
// SPDX-License-Identifier: GPL-3.0

import Partout
import SwiftUI

private enum ButtonAction {
    case connect

    case disconnect
}

struct ContentView: View {
    enum Destination: String, Hashable, Identifiable {
        case serverConfiguration

        case debugLog

        var id: String {
            rawValue
        }
    }

    @State
    private var profile: Profile = .demo

    @StateObject
    private var vpn: Tunnel = .shared

    @State
    private var dataCount: DataCount?

    @State
    private var isLoadingDebugLog = false

    @State
    private var debugLog: [String] = []

    @State
    private var destination: Destination?

    private let timer = Timer.publish(every: 2.0, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        List {
            modulesSection
            vpnSection
            advancedSection
        }
        .navigationTitle("Partout")
        .onReceive(timer) { _ in
            guard vpn.status == .active else {
                dataCount = nil
                return
            }
            let environment = vpn.environment(for: profile.id)
            dataCount = environment?.environmentValue(forKey: TunnelEnvironmentKeys.dataCount)
        }
        .sheet(item: $destination) {
            switch $0 {
            case .debugLog:
                debugLogView
            case .serverConfiguration:
                serverConfigurationView
            }
        }
        .task {
            do {
                try await vpn.prepare(purge: false)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

private extension ContentView {
    var modulesSection: some View {
        Section {
            ForEach(profile.modules, id: \.id) { module in
                HStack {
                    Button(module.moduleHandler.id.rawValue) {
                        onTapModule(module)
                    }
                    if profile.isActiveModule(withId: module.id) {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }
        } header: {
            Text("Modules")
        }
    }

    var vpnSection: some View {
        Section {
            Button(buttonAction.title) {
                onButton()
            }
            HStack {
                Text("Status")
                Spacer()
                Text(vpn.status.localizedDescription)
            }
            dataCountDescription.map(Text.init)
        } header: {
            Text("VPN")
        }
    }

    var advancedSection: some View {
        Section {
            HStack {
                Button("Debug log") {
                    onDebugLog()
                }
                .disabled(isLoadingDebugLog)
                if isLoadingDebugLog {
                    Spacer()
                    ProgressView()
                }
            }
#if !os(tvOS)
            if profile.firstModule(ofType: OpenVPNModule.self, ifActive: true) != nil {
                Button("Server configuration") {
                    destination = .serverConfiguration
                }
            }
#endif
        } header: {
            Text("Advanced")
        }
    }
}

private extension ContentView {
    var debugLogView: some View {
        NavigationStack {
            List {
                ForEach(Array(debugLog.enumerated()), id: \.offset) { entry in
                    Text(entry.element)
                }
            }
            .monospaced()
            .navigationTitle("Debug log")
            .toolbar {
                closeButton
            }
#if os(macOS)
            .frame(minWidth: 600.0, minHeight: 400.0)
#endif
        }
    }

#if !os(tvOS)
    var serverConfigurationView: some View {
        NavigationStack {
            VStack {
                vpn
                    .environment(for: profile.id)?
                    .environmentValue(forKey: TunnelEnvironmentKeys.OpenVPN.serverConfiguration)
                    .map { cfg in
                        TextEditor(text: .constant(String(describing: cfg)))
                            .monospaced()
                            .padding()
                    }
            }
            .navigationTitle("Server configuration")
            .toolbar {
                closeButton
            }
#if os(macOS)
            .frame(minWidth: 600.0, minHeight: 400.0)
#endif
        }
    }
#endif
}

// MARK: - Actions

private extension ContentView {
    var buttonAction: ButtonAction {
        ButtonAction(forStatus: vpn.status)
    }

    var closeButton: some View {
        Button {
            destination = nil
        } label: {
            Image(systemName: "xmark")
        }
    }

    func onTapModule(_ module: Module) {
        var builder = profile.builder()
        if module is ConnectionModule {
            builder.toggleExclusiveModule(withId: module.id) {
                $0 is ConnectionModule
            }
        } else {
            builder.toggleModule(withId: module.id)
        }
        do {
            profile = try builder.tryBuild()
        } catch {
            print("Unable to toggle module: \(error)")
        }
    }

    func onButton() {
        Task {
            do {
                switch buttonAction {
                case .connect:
                    try await vpn.install(profile, connect: true) {
                        "PartoutDemo: \($0.name)"
                    }

                case .disconnect:
                    try await vpn.disconnect(from: profile.id)
                }
            } catch {
                print("Unable to start VPN: \(error.localizedDescription)")
            }
        }
    }

    func onDebugLog() {
        isLoadingDebugLog = true
        Task {
            defer {
                isLoadingDebugLog = false
            }
            do {
                try await fetchDebugLog()
                destination = .debugLog
            } catch {
                print("Unable to fetch debug log: \(error)")
            }
        }
    }

    func fetchDebugLog() async throws {
        guard vpn.status != .inactive else {
            if PartoutLogger.default.hasLocalLogger {
                debugLog = try String(contentsOf: Demo.Log.tunnelURL)
                    .split(separator: "\n")
                    .map(String.init)
            }
            return
        }

        let interval: TimeInterval = 24 * 60 * 60 // 1 day
        let message: Message.Input

        message = .debugLog(sinceLast: interval, maxLevel: Demo.Log.maxLevel)

        guard let output = try await vpn.sendMessage(message, to: profile.id) else {
            return
        }
        guard case .debugLog(let log) = output else {
            debugLog = []
            return
        }
        debugLog = log
            .lines
            .map(Demo.Log.formattedLine)
    }
}

private extension ButtonAction {
    init(forStatus status: TunnelStatus) {
        switch status {
        case .inactive:
            self = .connect

        default:
            self = .disconnect
        }
    }
}

// MARK: - L10n

private extension ButtonAction {
    var title: String {
        switch self {
        case .connect:
            return "Connect"

        case .disconnect:
            return "Disconnect"
        }
    }
}

private extension Tunnel {
    var status: TunnelStatus {
        activeProfiles.first?.value.status ?? .inactive
    }
}

private extension TunnelStatus {
    var localizedDescription: String {
        switch self {
        case .inactive:
            return "Inactive"

        case .activating:
            return "Activating"

        case .active:
            return "Active"

        case .deactivating:
            return "Deactivating"
        }
    }
}

private extension ContentView {
    var dataCountDescription: String? {
        guard vpn.status == .active, let dataCount else {
            return nil
        }
        let down = dataCount.received.descriptionAsDataUnit
        let up = dataCount.sent.descriptionAsDataUnit
        return "↓\(down) ↑\(up)"
    }
}

// MARK: - Previews

#Preview {
    ContentView()
}
