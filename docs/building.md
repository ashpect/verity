# Building & Testing

For SDK maintainers. iOS developers don't need any of this — SPM downloads the pre-built xcframework automatically.

## Prerequisites

| Requirement | Install |
|-------------|---------|
| Rust nightly + iOS targets | `rustup target add aarch64-apple-ios aarch64-apple-ios-sim` |
| Xcode 16+ | Mac App Store |
| provekit repo | Pass path as argument to build script |

The zk-ffi backends are bundled in the `zkffi/` directory of this repo.

## Build xcframework

```bash
bash scripts/build-xcframework.sh <provekit-path>

# Example:
bash scripts/build-xcframework.sh ../provekit
```

Compiles provekit-ffi + all zkffi backends for iOS device + simulator, merges into `output/Verity.xcframework`.

## Run tests

```bash
xcodebuild test \
  -scheme Verity \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipPackagePluginValidation
```

Note: `swift test` won't work as the xcframework only has iOS slices. Must use `xcodebuild` with a simulator.

## Run examples

`circuit.json` and `Prover.toml` are already included in each example directory. Just generate and run:

```bash
cd Examples/Showcase
xcodegen generate          # needs: brew install xcodegen
open Showcase.xcodeproj
# Select an iOS Simulator and Run
```

If the fixtures are missing for some reason, recompile from the reference circuit:

```bash
cd noir-examples/basic-2
nargo compile
cp target/basic.json ../../Examples/Showcase/Showcase/circuit.json
cp Prover.toml ../../Examples/Showcase/Showcase/Prover.toml
```

## Release

```bash
bash scripts/release.sh v0.2.0
```

This:
1. Zips the xcframework
2. Uploads to GitHub Releases
3. Prints the `Package.swift` snippet with url + checksum

Then update `Package.swift` (switch `path:` to `url:` + `checksum:`), commit, push.

## Local dev vs release

`Package.swift` has two modes:

```swift
// Local dev (needs build-xcframework.sh first):
.binaryTarget(name: "VerityFFI", path: "output/Verity.xcframework")

// Release
.binaryTarget(name: "VerityFFI", url: "https://...", checksum: "...")
```

## If you only changed Swift code

No xcframework rebuild needed. Just commit and push.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `swift test` linker errors | Use `xcodebuild test` with simulator destination instead |
| Build script can't find provekit | Check the first argument path is correct |
| Build script can't find zkffi | Check that `zkffi/Cargo.toml` exists in the repo root |
| Tests fail with fixture not found | Check `Tests/VerityTests/Fixtures/` has `circuit.json` + `Prover.toml` |
| Checksum mismatch after release | Re-run `swift package compute-checksum` on the exact zip uploaded |
