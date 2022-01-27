// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "Monitor",
        platforms: [.macOS(.v10_15)],
        products: [
            .library(name: "Monitor", targets: ["Monitor"]),
            .library(name: "Utils", targets: ["Utils"]),
        ],
        dependencies: [
            // Dependencies declare other packages that this package depends on.
            // .package(url: /* package url */, from: "1.0.0"),
        ],
        targets: [
            .target(name: "Monitor"),
            .target(name: "Utils"),
        ]
)
