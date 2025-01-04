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
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.2"),
    ],
    targets: [
        .target(
            name: "RLLM",
            dependencies: ["FeedKit", "Alamofire"],
            path: "RLLM"
        ),
        .testTarget(
            name: "RLLMTests",
            dependencies: ["RLLM"],
            path: "RLLMTests"
        ),
    ]
)