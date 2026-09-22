// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SpeechRecog",
    platforms: [.macOS("15.0")],
    products: [
        .executable(name: "SpeechRecog", targets: ["SpeechRecog"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.2.0"),
        .package(url: "https://github.com/soniqo/speech-swift.git", revision: "c4c2fabbe825a9290c19e2f45d54ca3eae96b003")
    ],
    targets: [
        .executableTarget(
            name: "SpeechRecog",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
                .product(name: "Atomics", package: "swift-atomics"),
                .product(name: "Qwen3ASR", package: "speech-swift"),
                .product(name: "MossTranscribe", package: "speech-swift"),
                .product(name: "SpeechVAD", package: "speech-swift"),
                .product(name: "AudioCommon", package: "speech-swift")
            ],
            path: "Sources/SpeechRecog",
            exclude: [
                "Resources/Info.plist",
                "Resources/SpeechRecog.entitlements",
                "Resources/Assets.xcassets",
                "Resources/AppIcon.icns",
                "Resources/AppIcon.iconset"
            ]
        ),
        .testTarget(name: "SpeechRecogTests", dependencies: ["SpeechRecog"])
    ]
)
