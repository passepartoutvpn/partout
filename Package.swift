// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// MARK: Tuning

// action-release-binary-package (PartoutCore)
let binaryFilename = "PartoutCore.xcframework.zip"
let version = "0.99.130"
let checksum = "11afaadc343e0646be9d50ad7b2d6069ecd78105cb297d5daa036eb1207e1022"

// to download the core soruce
let coreSHA1 = "bfac7b7f2831fa0b030e5972864e93754d825c74"

// deployment environment
let environment: Environment = .remoteBinary

// implies included targets (exclude docs until ready)
let areas = Set(Area.allCases)
    .subtracting([.documentation])

// the OpenVPN crypto mode (ObjC -> C)
let openVPNCryptoMode: PartoutOpenVPN.CryptoMode = .fromEnvironment(
    "OPENVPN_CRYPTO_MODE",
    fallback: .legacy
)

// the global settings for C targets
let cSettings: [CSetting] = [
    .unsafeFlags([
        "-Wall", "-Wextra"//, "-Werror"
    ])
]

// MARK: - Structures

enum Environment {
    case remoteBinary

    case remoteSource

    case localBinary

    case localSource
}

enum Area: CaseIterable {
    case api

    case documentation

    case openvpn

    case wireguard
}

enum OS {
    case android

    case apple

    case linux

    case windows

    static var current: Self {
#if os(Android)
        .android
#elseif os(Linux)
        .linux
#elseif os(Windows)
        .windows
#else
        .apple
#endif
    }
}

let applePlatforms: [Platform] = [.iOS, .macOS, .tvOS]
let nonApplePlatforms: [Platform] = [.android, .linux, .windows]

// MARK: - Package

let package = Package(
    name: "partout",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "Partout",
            targets: ["Partout"]
        ),
        .library(
            name: "PartoutCoreWrapper",
            targets: ["PartoutCoreWrapper"]
        ),
        .library(
            name: "PartoutProviders",
            targets: ["PartoutProviders"]
        )
    ]
)

package.targets.append(contentsOf: [
    .target(
        name: "Partout",
        dependencies: {
            var dependencies: [Target.Dependency] = ["PartoutProviders"]
            dependencies.append(contentsOf: OS.current.dependencies)
            if areas.contains(.api) {
                dependencies.append("PartoutAPI")
            }
            if areas.contains(.openvpn) {
                dependencies.append("_PartoutOpenVPN")
            }
            if areas.contains(.wireguard) {
                dependencies.append("_PartoutWireGuard")
            }
            return dependencies
        }(),
        path: "Sources/Partout"
    ),
    .testTarget(
        name: "PartoutTests",
        dependencies: ["Partout"],
        path: "Tests/Partout",
        resources: [
            .copy("Resources")
        ]
    )
])

if areas.contains(.documentation) {
    package.dependencies.append(
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0")
    )
}

// MARK: Core

switch environment {
case .remoteBinary:
    package.targets.append(.binaryTarget(
        name: "PartoutCoreWrapper",
        url: "https://github.com/passepartoutvpn/partout/releases/download/\(version)/\(binaryFilename)",
        checksum: checksum
    ))
case .remoteSource:
    package.dependencies.append(
        .package(url: "git@github.com:passepartoutvpn/partout-core.git", revision: coreSHA1)
    )
    package.targets.append(.target(
        name: "PartoutCoreWrapper",
        dependencies: [
            .product(name: "PartoutCore", package: "partout-core")
        ],
        path: "Sources/Core"
    ))
case .localBinary:
    package.targets.append(.binaryTarget(
        name: "PartoutCoreWrapper",
        path: "../partout-core/PartoutCore.xcframework"
    ))
case .localSource:
    package.dependencies.append(
        .package(path: "../partout-core")
    )
    package.targets.append(.target(
        name: "PartoutCoreWrapper",
        dependencies: [
            .product(name: "PartoutCore", package: "partout-core")
        ],
        path: "Sources/Core"
    ))
}

package.targets.append(
    .testTarget(
        name: "PartoutCoreTests",
        dependencies: ["PartoutCoreWrapper"],
        path: "Tests/Core"
    )
)

// MARK: Platforms

extension OS {
    var dependencies: [Target.Dependency] {
        switch self {
        case .android:
            return ["_PartoutPlatformAndroid"]
        case .apple:
            return [
                "_PartoutPlatformApple",
                "_PartoutPlatformAppleNE"
            ]
        case .linux:
            return ["_PartoutPlatformLinux"]
        case .windows:
            return ["_PartoutPlatformWindows"]
        }
    }

    var targets: [Target] {
        switch self {
        case .android:
            return [
                .target(
                    name: "_PartoutPlatformAndroid",
                    dependencies: ["PartoutCoreWrapper"],
                    path: "Sources/Platforms/Android"
                )
            ]
        case .apple:
            return [
                .target(
                    name: "_PartoutPlatformApple",
                    dependencies: ["PartoutCoreWrapper"],
                    path: "Sources/Platforms/Apple"
                ),
                .target(
                    name: "_PartoutPlatformAppleNE",
                    dependencies: ["PartoutCoreWrapper"],
                    path: "Sources/Platforms/AppleNE"
                )
            ]
        case .linux:
            return [
                .target(
                    name: "_PartoutPlatformLinux",
                    dependencies: ["PartoutCoreWrapper"],
                    path: "Sources/Platforms/Linux"
                )
            ]
        case .windows:
            return [
                .target(
                    name: "_PartoutPlatformWindows",
                    dependencies: ["PartoutCoreWrapper"],
                    path: "Sources/Platforms/Windows"
                )
            ]
        }
    }

    var testTargets: [Target] {
        switch self {
        case .apple:
            return [
                .testTarget(
                    name: "_PartoutPlatformAppleNETests",
                    dependencies: ["_PartoutPlatformAppleNE"],
                    path: "Tests/Platforms/AppleNE"
                ),
                .testTarget(
                    name: "_PartoutPlatformAppleTests",
                    dependencies: ["_PartoutPlatformApple"],
                    path: "Tests/Platforms/Apple"
                )
            ]
        default:
            return []
        }
    }
}

package.targets.append(contentsOf: OS.current.targets)
package.targets.append(contentsOf: OS.current.testTargets)

// MARK: Providers

package.targets.append(contentsOf: [
    .target(
        name: "PartoutProviders",
        dependencies: ["PartoutCoreWrapper"],
        path: "Sources/Providers"
    ),
    .testTarget(
        name: "PartoutProvidersTests",
        dependencies: ["PartoutProviders"],
        path: "Tests/Providers"
    )
])

// MARK: - API

if areas.contains(.api) {
    package.products.append(
        .library(
            name: "PartoutAPI",
            targets: ["PartoutAPI"]
        )
    )
    package.dependencies.append(
        .package(url: "https://github.com/iwill/generic-json-swift", from: "2.0.0")
    )
    package.targets.append(contentsOf: [
        .target(
            name: "PartoutAPI",
            dependencies: [
                .product(name: "GenericJSON", package: "generic-json-swift"),
                "PartoutProviders"
            ],
            path: "Sources/API"
        ),
        .testTarget(
            name: "PartoutAPITests",
            dependencies: ["PartoutAPI"],
            path: "Tests/API"
        )
    ])
}

// MARK: - OpenVPN

if areas.contains(.openvpn) {
    package.dependencies.append(contentsOf: [
        .package(url: "https://github.com/passepartoutvpn/openssl-apple", from: "3.4.200")
    ])

    let cfg = PartoutOpenVPN.PackageConfiguration(for: openVPNCryptoMode)

    package.products.append(contentsOf: [
        .library(
            name: "PartoutOpenVPN",
            targets: ["PartoutOpenVPN"]
        ),
        .library(
            name: "_PartoutCryptoOpenSSL_C",
            targets: ["_PartoutCryptoOpenSSL_C"]
        ),
        .library(
            name: "_PartoutOpenVPNOpenSSL",
            targets: ["_PartoutOpenVPNOpenSSL"]
        ),
        .library(
            name: "_PartoutOpenVPNOpenSSL_C",
            targets: ["_PartoutOpenVPNOpenSSL_C"]
        ),
    ])

    package.targets.append(contentsOf: [
        .target(
            name: "PartoutOpenVPN",
            dependencies: ["_PartoutOpenVPNOpenSSL"],
            path: "Sources/OpenVPN/Wrapper"
        ),
        .target(
            name: "_PartoutCryptoOpenSSL_C",
            dependencies: cfg.cryptoDependencies,
            path: "Sources/OpenVPN/CryptoOpenSSL_C",
            cSettings: cSettings
        ),
        .target(
            name: "_PartoutOpenVPN",
            dependencies: ["PartoutCoreWrapper"],
            path: "Sources/OpenVPN/Base"
        ),
        .target(
            name: "_PartoutOpenVPNOpenSSL",
            dependencies: cfg.mainDependencies,
            path: "Sources/OpenVPN/OpenVPNOpenSSL",
            exclude: cfg.mainExclude,
            swiftSettings: cfg.mainDefines.map {
                .define($0)
            }
        ),
        .target(
            name: "_PartoutOpenVPNOpenSSL_C",
            dependencies: ["_PartoutCryptoOpenSSL_C"],
            path: "Sources/OpenVPN/OpenVPNOpenSSL_C",
            exclude: ["include/xor.h"],
            cSettings: cSettings
        ),
        .testTarget(
            name: "_PartoutCryptoOpenSSLTests",
            dependencies: cfg.cryptoTestDependencies,
            path: "Tests/OpenVPN/CryptoOpenSSL",
            exclude: cfg.cryptoTestExclude
        ),
        .testTarget(
            name: "_PartoutOpenVPNTests",
            dependencies: ["_PartoutOpenVPN"],
            path: "Tests/OpenVPN/Base"
        ),
        .testTarget(
            name: "_PartoutOpenVPNOpenSSLTests",
            dependencies: ["_PartoutOpenVPNOpenSSL"],
            path: "Tests/OpenVPN/OpenVPNOpenSSL",
            exclude: cfg.mainTestExclude,
            resources: [
                .process("Resources")
            ]
        )
    ])

    // legacy ObjC crypto
    if openVPNCryptoMode != .native {
        package.products.append(.library(
            name: "_PartoutCryptoOpenSSL_ObjC",
            targets: ["_PartoutCryptoOpenSSL_ObjC"]
        ))
        package.targets.append(.target(
            name: "_PartoutCryptoOpenSSL_ObjC",
            dependencies: cfg.cryptoLegacyDependencies,
            path: "Sources/OpenVPN/CryptoOpenSSL_ObjC",
            exclude: cfg.cryptoLegacyExclude
        ))

        package.products.append(.library(
            name: "_PartoutOpenVPNOpenSSL_ObjC",
            targets: ["_PartoutOpenVPNOpenSSL_ObjC"]
        ))
        package.targets.append(.target(
            name: "_PartoutOpenVPNOpenSSL_ObjC",
            dependencies: cfg.mainLegacyDependencies,
            path: "Sources/OpenVPN/OpenVPNOpenSSL_ObjC",
            exclude: cfg.mainLegacyExclude
        ))
    }
}

// MARK: Structures

enum PartoutOpenVPN {
    enum CryptoMode: Int {
        case legacy = 0

        case bridgedCrypto = 1

        case wrapped = 2

        case wrappedNative = 3

        case native = 4

        static func fromEnvironment(_ key: String, fallback: Self) -> Self {
            guard let envModeString = ProcessInfo.processInfo.environment[key],
                  let envModeInt = Int(envModeString),
                  let envMode = CryptoMode(rawValue: envModeInt) else {
                return fallback
            }
            return envMode
        }
    }

    struct PackageConfiguration {
        let mainDependencies: [Target.Dependency]

        let mainExclude: [String]

        let mainDefines: [String]

        let mainTestExclude: [String]

        let mainLegacyDependencies: [Target.Dependency]

        let mainLegacyExclude: [String]

        let cryptoDependencies: [Target.Dependency]

        let cryptoTestDependencies: [Target.Dependency]

        let cryptoTestExclude: [String]

        let cryptoLegacyDependencies: [Target.Dependency]

        let cryptoLegacyExclude: [String]

        init(for mode: CryptoMode) {
            let mainDependenciesBase: [Target.Dependency] = [
                "_PartoutOpenVPN"
            ]
            let nativeDataPathDefine = "OPENVPN_WRAPPED_NATIVE"

            // main legacy does not change
            mainLegacyDependencies = [
                "_PartoutCryptoOpenSSL_ObjC"
            ]
            mainLegacyExclude = [
                "include/XOR.h",
                "lib/COPYING",
                "lib/Makefile",
                "lib/README.LZO",
                "lib/testmini.c"
            ]

            // native crypto has no dependencies beyond OpenSSL
            cryptoDependencies = [
                "openssl-apple"
            ]

            switch mode {
            case .legacy:
                mainDependencies = mainDependenciesBase + [
                    "_PartoutOpenVPNOpenSSL_ObjC"
                ]
                mainExclude = ["Wrappers"]
                mainDefines = []
                mainTestExclude = ["Wrappers"]
                cryptoTestDependencies = ["_PartoutCryptoOpenSSL_ObjC"]
                cryptoTestExclude = ["Native"]

                cryptoLegacyDependencies = cryptoDependencies
                cryptoLegacyExclude = ["bridged"]

            case .bridgedCrypto:
                mainDependencies = mainDependenciesBase + [
                    "_PartoutOpenVPNOpenSSL_ObjC"
                ]
                mainExclude = ["Wrappers"]
                mainDefines = []
                mainTestExclude = ["Wrappers"]
                cryptoTestDependencies = ["_PartoutCryptoOpenSSL_ObjC"]
                cryptoTestExclude = ["Native"]

                cryptoLegacyDependencies = cryptoDependencies + [
                    "_PartoutCryptoOpenSSL_C"
                ]
                cryptoLegacyExclude = ["legacy"]

            case .wrapped, .wrappedNative:
                mainDependencies = mainDependenciesBase + [
                    "_PartoutOpenVPNOpenSSL_C",
                    "_PartoutOpenVPNOpenSSL_ObjC"
                ]
                mainExclude = []
                let baseDefines = ["OPENVPN_WRAPPED"]
                if mode == .wrappedNative {
                    mainDefines = baseDefines + [nativeDataPathDefine]
                } else {
                    mainDefines = baseDefines
                }
                mainTestExclude = ["Legacy"]
                cryptoTestDependencies = ["_PartoutCryptoOpenSSL_ObjC"]
                cryptoTestExclude = ["Legacy"]

                cryptoLegacyDependencies = cryptoDependencies + [
                    "_PartoutCryptoOpenSSL_C"
                ]
                cryptoLegacyExclude = ["bridged"]

            case .native:
                mainDependencies = mainDependenciesBase + [
                    "_PartoutOpenVPNOpenSSL_C"
                ]
                mainExclude = ["Wrappers/Legacy"]
                mainDefines = [nativeDataPathDefine]
                mainTestExclude = ["Legacy"]
                cryptoTestDependencies = ["_PartoutCryptoOpenSSL_C"]
                cryptoTestExclude = ["Legacy"]

                // legacy targets not included, these don't matter
                cryptoLegacyDependencies = []
                cryptoLegacyExclude = []
            }
        }
    }
}

// MARK: - WireGuard

if areas.contains(.wireguard) {
    package.dependencies.append(contentsOf: [
        .package(url: "https://github.com/passepartoutvpn/wireguard-apple", from: "1.1.2")
    ])
    package.products.append(contentsOf: [
        .library(
            name: "PartoutWireGuard",
            targets: ["PartoutWireGuard"]
        )
    ])
    package.targets.append(contentsOf: [
        .target(
            name: "PartoutWireGuard",
            dependencies: ["_PartoutWireGuardGo"],
            path: "Sources/WireGuard/Wrapper"
        ),
        .target(
            name: "_PartoutWireGuard",
            dependencies: ["PartoutCoreWrapper"],
            path: "Sources/WireGuard/Base"
        ),
        .target(
            name: "_PartoutWireGuardGo",
            dependencies: [
                "_PartoutWireGuard",
                .product(name: "WireGuardKit", package: "wireguard-apple")
            ],
            path: "Sources/WireGuard/WireGuardGo",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "_PartoutWireGuardTests",
            dependencies: ["_PartoutWireGuard"],
            path: "Tests/WireGuard/Base"
        ),
        .testTarget(
            name: "_PartoutWireGuardGoTests",
            dependencies: ["_PartoutWireGuardGo"],
            path: "Tests/WireGuard/WireGuardGo"
        )
    ])
}
