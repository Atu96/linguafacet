// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TranslateQuick",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "TranslateQuick",
            path: "Sources/TranslateQuick",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("Carbon"),
                .linkedFramework("NaturalLanguage"),
                .linkedFramework("Translation"),
                .linkedFramework("Security"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("FoundationModels")
            ]
        )
    ]
)
