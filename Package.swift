// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "PaylikeClient",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "PaylikeClient", targets: ["PaylikeClient"])
    ],
    dependencies: [
        .package(url: "https://github.com/paylike/swift-request", .upToNextMajor(from: "0.3.0")),
        .package(url: "https://github.com/Flight-School/AnyCodable", .upToNextMajor(from: "0.6.0")),
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0"))
    ],
    targets: [
        .target(
            name: "PaylikeClient",
            dependencies: [
                .product(name: "PaylikeRequest", package: "swift-request"),
                .product(name: "AnyCodable", package: "AnyCodable")
                          ]),
        .testTarget(
            name: "PaylikeClientTests",
            dependencies: [
                "PaylikeClient",
                .product(name: "Swifter", package: "swifter")
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
