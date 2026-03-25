# Noir Examples

Reference Noir circuits for testing the Verity SDK.

## basic-2

Simple arithmetic constraint: `a * b + c + d == 10`.

### Compile

```bash
cd noir-examples/basic-2
nargo compile
```

Produces `target/basic.json` — this is the `circuit.json` the SDK's `prepare()` expects.

### Inputs

`Prover.toml` contains the witness values. The SDK's `prove(with:input:)` reads this file, or you can pass values programmatically:

```swift
let proof = try verity.prove(with: scheme.prover, inputs: [
    "a": "1", "b": "2", "c": "3", "d": "5"
])
```

### Use with examples

Copy the compiled circuit and inputs to the example apps:
```bash
cp target/basic.json ../../Examples/BasicProof/BasicProof/circuit.json
cp Prover.toml ../../Examples/BasicProof/BasicProof/Prover.toml
```

Then add both files to the Xcode target's bundle resources.
