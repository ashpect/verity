// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Verity",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Verity", targets: ["Verity"]),
    ],
    targets: [
        // Pre-built static library containing pk_* and bb_* symbols.
        .binaryTarget(
            name: "VerityFFI",
            url: "https://github.com/ashpect/verity/releases/download/v0.2.0/Verity.xcframework.zip",
            checksum: "b173ccde86f33b46c54455b8aa4a8b2d613c9232fa808fa2ae58958066fbb889"
        ),

        // C dispatcher — routes unified verity_* calls to the correct backend
        // via vtable. Contains pk_backend.c and bb_backend.c registrations.
        .target(
            name: "VerityDispatch",
            dependencies: ["VerityFFI"],
            path: "Sources/VerityDispatch",
            publicHeadersPath: "include"
        ),

        // Swift SDK — calls verity_* functions only (no backend-specific code).
        .target(
            name: "Verity",
            dependencies: ["VerityDispatch"],
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
