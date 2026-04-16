// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotchDrop",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "NotchDrop",
            path: "Sources"
        )
    ]
)
