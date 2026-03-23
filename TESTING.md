# Verity

## 1. Developer usage (consuming the SDK)

No Rust, no build scripts — just add the Swift package.

### Add to your project

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ashpect/verity", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "Verity", package: "verity")
    ])
]
```

Or in Xcode: File → Add Package Dependencies → paste the repo URL.

### Usage

```swift
import Verity

// 1. Initialize with your chosen backend
let verity = try Verity(backend: .provekit)    // or .barretenberg

// 2. Prepare — compile the circuit once, reuse the scheme dir
let schemeDir = FileManager.default.temporaryDirectory.path + "/my_scheme"
try verity.prepare(circuit: "path/to/circuit.json", output: schemeDir)

// 3. Prove — generate proof from witness inputs
let proof = try verity.prove(scheme: schemeDir, input: "path/to/Prover.toml")

// 4. Verify
let valid = try verity.verify(proof: proof, scheme: schemeDir)
```

### Notes

- `prepare()` is slow (compiles circuit). Do it once, then cache the scheme directory.
- `prove()` and `verify()` are fast — they read from the cached scheme.
- Same circuit always produces the same scheme. Prover and verifier can independently `prepare()`, or the scheme dir can be shared.
- Proofs are `Data` bytes. NOT interchangeable between backends.

## 2. Running the tests

```bash
cd ~/Desktop/zk/sdk
xcodebuild test \
  -scheme Verity \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath .build/DerivedData \
  -skipPackagePluginValidation
```

Runs two tests:
- `testProveKitBackendPrepareProveVerify` — ProveKit WHIR
- `testBarretenbergBackendPrepareProveVerify` — Barretenberg UltraHonk

Expected: `** TEST SUCCEEDED **`, `Executed 2 tests, with 0 failures`.

## 3. Rebuilding the xcframework

When you've changed `provekit-ffi` (in provekit repo) or `barretenberg-ffi` (in `../zk-ffi`).

### Prerequisites

- Rust nightly with iOS targets: `rustup target add aarch64-apple-ios aarch64-apple-ios-sim`
- Xcode (for `xcodebuild` and `libtool`)
- Sibling `../provekit` repo (or set `PROVEKIT_ROOT`)
- Sibling `../zk-ffi` repo (or set `BB_FFI_ROOT`)

### Build

```bash
bash scripts/build-xcframework.sh
```

Output: `output/Verity.xcframework`

### Release

```bash
bash scripts/release.sh v0.2.0
```

This zips the xcframework, computes the checksum, uploads to GitHub Releases, and prints the `Package.swift` snippet to update.

Then update `Package.swift` with the new URL + checksum, commit, and push.

### If you only changed Swift code

No rebuild needed — just commit and push.

## 4. Repo layout

```
verity/
├── Package.swift                  SPM manifest (binary target points to GitHub Release)
├── Sources/Verity/                Swift SDK (Verity, VerityError, Backend)
├── Tests/VerityTests/             Swift tests + fixtures
├── Examples/BasicProof/           SwiftUI example app (xcodegen project)
├── include/verity_ffi.h           C header (both pk_* and bb_* declarations)
└── scripts/
    ├── build-xcframework.sh       Build provekit-ffi + barretenberg-ffi → xcframework
    └── release.sh                 Zip + upload + checksum in one command

../zk-ffi/                         Barretenberg UltraHonk Rust FFI (bb_* functions)
../provekit/tooling/provekit-ffi/  ProveKit WHIR Rust FFI (pk_* functions)
```

The build script compiles both FFI crates from sibling repos (`../provekit` and `../zk-ffi`).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| SPM can't download xcframework | Check the release URL in Package.swift matches a real GitHub Release |
| Checksum mismatch | Re-run `swift package compute-checksum` on the exact zip uploaded |
| Build script can't find provekit | Set `PROVEKIT_ROOT=/path/to/provekit` |
| Build script can't find zk-ffi | Set `BB_FFI_ROOT=/path/to/zk-ffi` |
| Tests fail with fixture not found | Check `Tests/VerityTests/Fixtures/` has `circuit.json` and `Prover.toml` |
