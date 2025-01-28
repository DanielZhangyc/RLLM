// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RLLM",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.1"),
        .package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2"),
        .package(url: "https://github.com/BastiaanJansen/toast-swift", from: "2.1.3")
    ],
    targets: [
        .target(
            name: "RLLM",
            dependencies: [
                "Alamofire",
                "FeedKit",
                "Toast"
            ],
            path: "RLLM"
        )
    ]
)