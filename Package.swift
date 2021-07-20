// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NepTunes",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "AppCore", targets: ["AppCore"]),
        .library(name: "Shared", targets: ["Shared"]),
        .library(name: "LastFm", targets: ["LastFm"]),
        .library(name: "Scrobbler", targets: ["Scrobbler"]),
        .library(name: "PlayersBridge", targets: ["PlayersBridge"]),
        .library(name: "Player", targets: ["Player"]),
        .library(name: "Onboarding", targets: ["Onboarding"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", .upToNextMajor(from: "0.2.0")),
        .package(path: "../LastFmKit"),
        .package(path: "../DeezerClient")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Shared",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ]),
        .target(
            name: "PlayersBridge",
            dependencies: [
                "Shared"
            ],
            exclude: ["Scripts"],
            resources: [.copy("MusicScript.scpt"), .copy("SpotifyScript.scpt")]),
        .target(
            name: "LastFm",
            dependencies: [
                "Shared",
                .product(name: "LastFmKit", package: "LastFmKit"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]),
        .testTarget(
            name: "LastFmTests",
            dependencies: ["LastFm"],
            resources: [.process("Resources/")]),
        .target(
            name: "Scrobbler",
            dependencies: [
                "Shared",
                "PlayersBridge"
            ]
        ),
        .testTarget(
            name: "ScrobblerTests",
            dependencies: [
                "Shared",
                "Scrobbler"]),
        .target(
            name: "Player",
            dependencies: [
                "Shared",
                "PlayersBridge",
                .product(name: "DeezerClient", package: "DeezerClient"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]),
        .testTarget(name: "PlayerTests", dependencies: ["Player"]),
        .target(
            name: "AppCore",
            dependencies: [
                "Shared",
                "PlayersBridge",
                "Scrobbler",
                "LastFm",
                "Player",
                "Onboarding",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "DeezerClient", package: "DeezerClient")
            ]),
        // test target for the AppCoreTests isn't needed for now
//        .testTarget(name: "AppCoreTests", dependencies: ["AppCore"]),
        .target(
            name: "Onboarding",
            dependencies: [
                "Shared",
                "LastFm",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
            ])
    ]
)
