// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeechRecog",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SpeechRecog", targets: ["SpeechRecog"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "SpeechRecog",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit")
            ],
            path: "Sources/SpeechRecog",
            exclude: [
                "Resources/Info.plist",
                "Resources/SpeechRecog.entitlements",
                "Resources/Assets.xcassets"
            ]
        )
    ]
)
