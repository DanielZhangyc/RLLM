// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RLLM",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RLLM",
            targets: ["RLLM"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2"),
    ],
    targets: [
        .target(
            name: "RLLM",
            dependencies: ["FeedKit"],
            path: "RLLM"
        ),
        .testTarget(
            name: "RLLMTests",
            dependencies: ["RLLM"],
            path: "RLLMTests"
        ),
    ]
)