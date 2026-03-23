# Examples

## BasicProof

Minimal SwiftUI app demonstrating the prepare → prove → verify flow.

### Prerequisites

- Xcode 16+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- A compiled Noir circuit (`circuit.json`) and input file (`Prover.toml`)

### Run

```bash
cd Examples/BasicProof
xcodegen generate
open BasicProof.xcodeproj
```

Then in Xcode:
1. Add `circuit.json` and `Prover.toml` to the app's bundle resources.
2. Select an iOS Simulator destination and run.
