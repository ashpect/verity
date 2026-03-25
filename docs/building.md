# Building & Testing

For SDK maintainers. iOS developers don't need any of this — SPM downloads the pre-built xcframework automatically.

## Prerequisites

| Requirement | Install |
|-------------|---------|
| Rust nightly + iOS targets | `rustup target add aarch64-apple-ios aarch64-apple-ios-sim` |
| Xcode 16+ | Mac App Store |
| provekit repo | Pass path as first argument to build script |
| zk-ffi repo | Pass path as second argument to build script |

Expected directory layout:

```
~/Desktop/zk/
├── provekit/    ProveKit core + pk_* FFI
├── zk-ffi/      Backend FFI crates (bb_*, etc.)
└── sdk/          This repo
```

## Build xcframework

```bash
bash scripts/build-xcframework.sh <provekit-path> <zk-ffi-path>

# Example:
bash scripts/build-xcframework.sh ../provekit ../zk-ffi
```

Compiles provekit-ffi + all zk-ffi backends for iOS device + simulator, merges into `output/Verity.xcframework`. Takes ~7 minutes first time.

## Run tests

```bash
xcodebuild test \
  -scheme Verity \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipPackagePluginValidation
```

Note: `swift test` won't work as the xcframework only has iOS slices. Must use `xcodebuild` with a simulator.

## Run examples

```bash
cd Examples/BasicProof
xcodegen generate          # needs: brew install xcodegen
open BasicProof.xcodeproj
```

Add `circuit.json` + `Prover.toml` to bundle resources in Xcode, then Run.

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

// Release (what users see — SPM downloads automatically):
.binaryTarget(name: "VerityFFI", url: "https://...", checksum: "...")
```

## If you only changed Swift code

No xcframework rebuild needed. Just commit and push.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `swift test` linker errors | Use `xcodebuild test` with simulator destination instead |
| Build script can't find provekit | Check the first argument path is correct |
| Build script can't find zk-ffi | Check the second argument path is correct |
| Tests fail with fixture not found | Check `Tests/VerityTests/Fixtures/` has `circuit.json` + `Prover.toml` |
| Checksum mismatch after release | Re-run `swift package compute-checksum` on the exact zip uploaded |
