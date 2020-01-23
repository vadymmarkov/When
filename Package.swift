// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "When",
    platforms: [
        .macOS(.v10_10),
        .iOS(.v8),
        .tvOS(.v9)
    ],
    products: [
        .library(name: "When",
                 targets: ["When"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Quick.git",
                 .upToNextMinor(from: "2.2.0")),
        .package(url: "https://github.com/Quick/Nimble.git",
                 .upToNextMinor(from: "8.0.5"))
    ],
    targets: [
        .target(name: "When",
                path: "Sources"),
        .testTarget(name: "WhenTests",
                    dependencies: ["When", "Quick", "Nimble"],
                    path: "WhenTests"),
    ],
    swiftLanguageVersions: [.v5]
)
