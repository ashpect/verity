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
            checksum: "a259f8ca5295942b7b167772b38efea1f0104dfc5c1fe5e7336178190b089c0c"
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
