// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let environment: Environment
// environment = .localDevelopment
// environment = .onlineDevelopment
environment = .production

let binaryFilename = "PartoutCore.xcframework.zip"
let version = "0.99.81"
let checksum = "ae1222ccc1503b1835d67f6ea7f6f6778adcfd3a29f28024b1339f9573d2bd36"

enum Environment {
    case localDevelopment

    case onlineDevelopment

    case production

    var dependencies: [Package.Dependency] {
        switch self {
        case .localDevelopment:
            return []
        case .onlineDevelopment:
            return []
        case .production:
            return [
                .package(path: "../CoreSource")
            ]
        }
    }

    var coreTargetName: String {
        switch self {
        case .localDevelopment:
            return "LocalDevelopment"
        case .onlineDevelopment:
            return "OnlineDevelopment"
        case .production:
            return "PartoutCore"
        }
    }

    var targets: [Target] {
        var targets: [Target] = []
        switch self {
        case .localDevelopment:
            targets.append(.binaryTarget(
                name: coreTargetName,
                path: binaryFilename
            ))
        case .onlineDevelopment:
            targets.append(.binaryTarget(
                name: coreTargetName,
                url: "https://github.com/passepartoutvpn/partout/releases/download/\(version)/\(binaryFilename)",
                checksum: checksum
            ))
        case .production:
            targets.append(.target(
                name: coreTargetName,
                dependencies: [
                    .product(name: "PartoutCoreSource", package: "CoreSource")
                ]
            ))
        }
        targets.append(.testTarget(
            name: "PartoutCoreTests",
            dependencies: [.byName(name: coreTargetName)]
        ))
        return targets
    }
}

let package = Package(
    name: "PartoutCoreWrapper",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v17)
    ],
    products: [
        .library(
            name: "PartoutCore",
            targets: [environment.coreTargetName]
        )
    ],
    dependencies: environment.dependencies,
    targets: environment.targets
)
