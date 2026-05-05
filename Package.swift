// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LidMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LidMonitor",
            path: "Sources/LidMonitor"
        )
    ]
)
