// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HonchoPlugin",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HonchoPlugin", type: .dynamic, targets: ["HonchoPlugin"])
    ],
    targets: [
        .target(name: "HonchoPlugin", path: "Sources/HonchoPlugin"),
        .testTarget(name: "HonchoPluginTests", dependencies: ["HonchoPlugin"], path: "Tests/HonchoPluginTests")
    ]
)
