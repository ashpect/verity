// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Verity",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Verity", targets: ["Verity"]),
    ],
    targets: [
        .binaryTarget(
            name: "VerityFFI",
            url: "https://github.com/ashpect/verity/releases/download/v0.1.0/Verity.xcframework.zip",
            checksum: "bbf39ee9cc4f391026cd96e63144287bb37f4b33dd054447464cfccb170bc38d"
        ),
        .target(
            name: "Verity",
            dependencies: ["VerityFFI"],
            path: "Sources/Verity"
        ),
        .testTarget(
            name: "VerityTests",
            dependencies: ["Verity"],
            path: "Tests/VerityTests",
            resources: [.copy("Fixtures")]
        ),
    ]
)
