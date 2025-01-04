// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RLLM",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
        .package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2")
    ],
    targets: [
        .target(
            name: "RLLM",
            dependencies: [
                "Alamofire",
                "FeedKit"
            ],
            path: "RLLM"
        )
    ]
)