// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FantKit",
    platforms: [
        .watchOS(.v9),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "FantKit", targets: ["FantKit"]),
        .library(name: "Build", targets: ["Build"]),
        .library(name: "Logging", targets: ["Logging"]),
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "TimeLine", targets: ["TimeLine"]),
        .library(name: "Post", targets: ["Post"]),
        .library(name: "APIClient", targets: ["APIClient"]),
        .library(name: "APIClientLive", targets: ["APIClientLive"]),
        .library(name: "SignIn", targets: ["SignIn"]),
        .library(name: "Defaults", targets: ["Defaults"]),
        .library(name: "Constants", targets: ["Constants"]),
        .library(name: "Settings", targets: ["Settings"]),
        .library(name: "Compose", targets: ["Compose"]),
        .library(name: "ImageCDN", targets: ["ImageCDN"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Swiftodon/Mastodon.swift", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-url-routing", from: "0.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-overture", from: "0.5.0"),
        .package(url: "https://github.com/pointfreeco/swift-gen", from: "0.3.0"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.47.2"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "0.1.0"),
        .package(url: "https://github.com/pointfreeco/swift-case-paths", from: "0.8.1"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/onevcat/Kingfisher", .upToNextMajor(from: "7.0.0")),
        .package(url: "https://gitlab.com/mflint/HTML2Markdown", from: "1.0.0"),
        .package(url: "https://github.com/Nike-Inc/Willow", .upToNextMajor(from: "6.0.0"))
    ],
    targets: [
        .target(
            name: "APIClient",
            dependencies: [
                .product(name: "MastodonSwift", package: "Mastodon.swift"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
                "Post",
                "Defaults",
                "Constants",
            ]
        ),
        .target(
            name: "APIClientLive",
            dependencies: [
                "APIClient",
                .product(name: "Dependencies", package: "swift-composable-architecture"),
            ]
//            , exclude: ["Secrets.swift.example"]
        ),
        .target(
            name: "Logging",
            dependencies: [
                .product(name: "Willow", package: "Willow"),
                .product(name: "CustomDump", package: "swift-custom-dump"),
            ]
        ),
        .target(
            name: "ImageCDN",
            dependencies: [
            ]
        ),
        .target(
            name: "AppFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "SignIn",
                "APIClient",
                "Build",
                "Logging",
                "Constants",
                "Compose",
                "Settings",
                "Defaults",
                "TimeLine",
                "Post"
            ]
        ),
        .target(
            name: "TimeLine",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "APIClient",
                "Defaults",
                "Logging",
                "Post",
            ]
        ),
        .target(
            name: "SignIn",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "APIClient",
                "Logging",
                "Defaults",
                "Post",
            ]
        ),
        .target(
            name: "Post",
            dependencies: [
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "HTML2Markdown", package: "HTML2Markdown"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "Logging",
                "ImageCDN",
            ]
        ),
        .target(
            name: "Compose",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "Logging",
                "APIClient"
            ]
        ),
        .target(
            name: "Settings",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "Logging",
                "Defaults"
            ]
        ),
        .target(
            name: "Constants",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                "Logging",
            ]
        ),
        .target(
            name: "Defaults",
            dependencies: [
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Dependencies", package: "swift-dependencies"),
                "Logging",
                "Constants"
            ]
        ),
        .target(
            name: "Build",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
                .product(name: "Tagged", package: "swift-tagged"),
                .product(name: "XCTestDynamicOverlay", package: "xctest-dynamic-overlay"),
            ]),
        .target(
            name: "FantKit",
            dependencies: [
                "Build",
                "Logging",
                "APIClientLive",
                "AppFeature"
            ]
        ),
        .testTarget(
            name: "FantKitTests",
            dependencies: ["FantKit"]),
    ]
)
