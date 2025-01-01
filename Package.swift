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
        // 如果有外部依赖，在这里添加
    ],
    targets: [
        .target(
            name: "RLLM",
            dependencies: [],
            path: "RLLM"
        ),
        .testTarget(
            name: "RLLMTests",
            dependencies: ["RLLM"],
            path: "RLLMTests"
        ),
    ]
)