# Examples

Both examples include `circuit.json` and `Prover.toml` — no manual file copying needed.

## BasicProof

Minimal SwiftUI app — pick ProveKit or Barretenberg, tap a button, see prepare → prove → verify.

```bash
cd Examples/BasicProof
xcodegen generate
open BasicProof.xcodeproj
# Select an iOS Simulator and Run
```

## Showcase

Comprehensive demo exercising every SDK capability:

- In-memory prepare (no files written)
- Prove with TOML file
- Scheme reuse (prove twice with same handle)
- Save + Load round-trip
- Serialize + Load bytes round-trip
- Side-by-side ProveKit vs Barretenberg comparison

```bash
cd Examples/Showcase
xcodegen generate
open Showcase.xcodeproj
# Select an iOS Simulator and Run
```

> **Note:** Each example has its own `project.yml` and must be generated separately. Run `xcodegen generate` and `open *.xcodeproj` from within the example's directory.

## Updating fixtures

If you need to recompile the circuit:

```bash
cd noir-examples/basic-2
nargo compile
cp target/basic.json ../../Examples/BasicProof/BasicProof/circuit.json
cp target/basic.json ../../Examples/Showcase/Showcase/circuit.json
```
