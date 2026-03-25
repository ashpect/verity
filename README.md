# Verity SDK

Zero-knowledge proof SDK for iOS. Supports multiple proving backends with a single API.

## Install

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ashpect/verity", from: "0.2.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "Verity", package: "verity")
    ])
]
```

Or in Xcode: File → Add Package Dependencies → paste the repo URL.

## Usage

```swift
import Verity

let verity = try Verity(backend: .provekit)  // or .barretenberg

// Prepare
let scheme = try verity.prepare(circuit: "circuit.json")

// Prove
let proof = try verity.prove(with: scheme.prover, input: "Prover.toml")
// or with a dictionary:
let proof = try verity.prove(with: scheme.prover, inputs: ["a": "1", "b": "2"])

// Verify
let valid = try verity.verify(with: scheme.verifier, proof: proof)
```

## Save & Load Schemes

```swift
// Save
try scheme.prover.save(to: "prover.pkp")
try scheme.verifier.save(to: "verifier.pkv")

// Load from file
let prover = try verity.loadProver(from: "prover.pkp")

// Load from bytes (e.g., downloaded from server)
let prover = try verity.loadProver(data: downloadedBytes)
```

## Backends

| Backend | Init | Setup | Proof Size |
|---------|------|-------|------------|
| ProveKit (WHIR) | `.provekit` | None (transparent) | Variable (~KBs) |
| Barretenberg (UltraHonk) | `.barretenberg` | Universal (auto-downloaded) | Several KB |

Switching backends changes one line — the rest of your code stays identical.

## Examples

See [`Examples/`](Examples/) for SwiftUI demo apps.

## Docs

- [Building & Testing](docs/building.md) — for SDK maintainers
- [Releasing](docs/release.md) — cutting a new version
- [Contributing](CONTRIBUTING.md) — adding new backends
