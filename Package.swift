// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaylikeClient",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PaylikeClient",
            targets: ["PaylikeClient"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "git@github.com:paylike/swift-request.git", .upToNextMajor(from: "0.2.1")),
        .package(url: "git@github.com:paylike/swift-money.git", .upToNextMajor(from: "0.2.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PaylikeClient",
            dependencies: [
                .product(name: "PaylikeRequest", package: "swift-request"),
                .product(name: "PaylikeMoney", package: "swift-money")
            ]),
        .testTarget(
            name: "PaylikeClientTests",
            dependencies: ["PaylikeClient", .product(name: "PaylikeMoney", package: "swift-money")]),
    ]
)
