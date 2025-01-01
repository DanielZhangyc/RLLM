// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LLM-RSS",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LLM-RSS",
            targets: ["LLM-RSS"]
        ),
    ],
    dependencies: [
        // 如果有外部依赖，在这里添加
    ],
    targets: [
        .target(
            name: "LLM-RSS",
            dependencies: [],
            path: "LLM-RSS"
        ),
        .testTarget(
            name: "LLM-RSSTests",
            dependencies: ["LLM-RSS"],
            path: "LLM-RSSTests"
        ),
    ]
)