# Verity SDK

Zero-knowledge proof SDK for iOS. Supports multiple proving backends with a single API.

## Install

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/atheonxyz/verity", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "Verity", package: "verity")
    ])
]
```

Or in Xcode: File → Add Package Dependencies → paste the repo URL.

## Quick Start

```swift
import Verity

let verity = try Verity(backend: .provekit)  // or .barretenberg

// 1. Prepare — compile circuit into prover + verifier schemes
let scheme = try verity.prepare(circuit: "circuit.json")

// 2. Prove
let proof = try verity.prove(with: scheme.prover, input: "Prover.toml")

// 3. Verify
let valid = try verity.verify(with: scheme.verifier, proof: proof)
```
`proof` is `Data` (bytes) : save it, send it, verify it anywhere.

---

## Usage Patterns

### Prove with dictionary inputs (no TOML file)

```swift
let proof = try verity.prove(with: scheme.prover, inputs: [
    "a": "1",
    "b": "2",
    "c": "3",
    "d": "5"
])
```

### Save schemes to disk (prepare once, reuse forever)

```swift
// Prepare is slow (~seconds). Do it once.
let scheme = try verity.prepare(circuit: "circuit.json")

// Save for later
try scheme.prover.save(to: "prover.pkp")
try scheme.verifier.save(to: "verifier.pkv")
```

### Load schemes from file

```swift
// Next app launch — skip prepare, load instantly
let prover = try verity.loadProver(from: "prover.pkp")
let verifier = try verity.loadVerifier(from: "verifier.pkv")

let proof = try verity.prove(with: prover, input: "Prover.toml")
let valid = try verity.verify(with: verifier, proof: proof)
```

### Load from downloaded bytes (no temp file needed)

```swift
// Download .pkp from your server
let pkpData = try Data(contentsOf: serverURL)

// Load directly from bytes
let prover = try verity.loadProver(data: pkpData)
let proof = try verity.prove(with: prover, inputs: ["a": "1", "b": "2"])
```

### Serialize schemes to bytes (for network transfer, database, etc.)

```swift
// Sender
let proverBytes = try scheme.prover.serialize()
let verifierBytes = try scheme.verifier.serialize()
// Send over network, store in CoreData, cache in UserDefaults...

// Receiver
let prover = try verity.loadProver(data: proverBytes)
let verifier = try verity.loadVerifier(data: verifierBytes)
```

### Reuse schemes for multiple proofs

```swift
// Schemes are reusable — prove as many times as you want
let scheme = try verity.prepare(circuit: "circuit.json")

let proof1 = try verity.prove(with: scheme.prover, inputs: ["a": "1", "b": "2", "c": "3", "d": "5"])
let proof2 = try verity.prove(with: scheme.prover, inputs: ["a": "2", "b": "1", "c": "3", "d": "5"])

let valid1 = try verity.verify(with: scheme.verifier, proof: proof1)  // true
let valid2 = try verity.verify(with: scheme.verifier, proof: proof2)  // true
```

### Switch backends (one line change)

```swift
// ProveKit — transparent, no trusted setup
let pk = try Verity(backend: .provekit)
let scheme = try pk.prepare(circuit: "circuit.json")
let proof = try pk.prove(with: scheme.prover, input: "Prover.toml")

// Barretenberg — same API, different backend
let bb = try Verity(backend: .barretenberg)
let scheme = try bb.prepare(circuit: "circuit.json")
let proof = try bb.prove(with: scheme.prover, input: "Prover.toml")
```

---

## Typical App Integration

```swift
class ZKProofManager {
    private let verity: Verity
    private var prover: ProverScheme?
    private var verifier: VerifierScheme?

    init() throws {
        verity = try Verity(backend: .provekit)
    }

    /// Call once at app startup.
    func loadSchemes(proverPath: String, verifierPath: String) throws {
        prover = try verity.loadProver(from: proverPath)
        verifier = try verity.loadVerifier(from: verifierPath)
    }

    /// Generate a proof on a background thread.
    func prove(inputs: [String: Any]) async throws -> Data {
        guard let prover else { throw AppError.notReady }
        return try await Task.detached {
            try self.verity.prove(with: prover, inputs: inputs)
        }.value
    }

    /// Verify a received proof.
    func verify(proof: Data) throws -> Bool {
        guard let verifier else { throw AppError.notReady }
        return try verity.verify(with: verifier, proof: proof)
    }
}
```

---

## Backends

| Backend | Init | Trusted Setup | Proof Size |
|---------|------|---------------|------------|
| ProveKit (WHIR) | `.provekit` | None (transparent) | Variable (~KBs) |
| Barretenberg (UltraHonk) | `.barretenberg` | Universal (auto-downloaded) | Several KB |

Switching backends changes one line. The rest of your code stays identical.

## API Summary

| Method | What it does |
|--------|-------------|
| `Verity(backend:)` | Initialize with a backend |
| `prepare(circuit:)` | Compile circuit → `PreparedScheme` (prover + verifier) |
| `prove(with:input:)` | Prove with TOML file → `Data` |
| `prove(with:inputs:)` | Prove with dictionary → `Data` |
| `verify(with:proof:)` | Verify proof → `Bool` |
| `loadProver(from:)` | Load prover from file → `ProverScheme` |
| `loadProver(data:)` | Load prover from bytes → `ProverScheme` |
| `loadVerifier(from:)` | Load verifier from file → `VerifierScheme` |
| `loadVerifier(data:)` | Load verifier from bytes → `VerifierScheme` |
| `prover.save(to:)` | Save prover to file |
| `prover.serialize()` | Serialize prover to bytes → `Data` |
| `verifier.save(to:)` | Save verifier to file |
| `verifier.serialize()` | Serialize verifier to bytes → `Data` |

## Examples

See [`Examples/`](Examples/) for SwiftUI demo apps with circuits included.

## Docs

- [Building & Testing](docs/building.md) — for SDK maintainers
- [Releasing](docs/release.md) — cutting a new version
- [Roadmap](docs/roadmap.md) — what's next, production hardening, multi-platform
- [Contributing](CONTRIBUTING.md) — adding new backends
