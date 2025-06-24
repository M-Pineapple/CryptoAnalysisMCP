// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CryptoAnalysisMCP",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "CryptoAnalysisMCP", targets: ["CryptoAnalysisMCP"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "CryptoAnalysisMCP",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "CryptoAnalysisMCPTests",
            dependencies: ["CryptoAnalysisMCP"]
        )
    ]
)
