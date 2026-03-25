# Contributing

## Adding a New Backend

The Verity SDK uses a vtable dispatcher hence adding a backend requires **zero Swift code changes**.

### What you need to do

1. **Implement your FFI crate** in the [zk-ffi](https://github.com/worldfnd/zk-ffi) repo under `backends/your-backend/`. See [zk-ffi/CONTRIBUTING.md](https://github.com/worldfnd/zk-ffi/blob/main/CONTRIBUTING.md) for the full guide (16 functions to implement).

2. **Add a vtable registration file** to this repo at `Sources/VerityDispatch/xx_backend.c`. Copy from `pk_backend.c` or `bb_backend.c` and replace the prefix.

3. **Add an enum value** in `Sources/VerityDispatch/include/verity_ffi.h`:
   ```c
   VERITY_BACKEND_YOUR_BACKEND = 2,
   ```

4. **Add extern declarations** to `include/verity_ffi_raw.h` for your `xx_*` functions.

5. **Update `scripts/build-xcframework.sh`** if your backend lives outside the zk-ffi repo.

6. **Add `case .yourBackend`** to the `Backend` enum in `Sources/Verity/Verity.swift`.

### What you DON'T need to change

- Verity.swift methods (no switch cases — vtable handles dispatch)
- ProverScheme.swift / VerifierScheme.swift
- Tests (existing tests are unaffected)
- Other backends

### Testing

```bash
bash scripts/build-xcframework.sh
xcodebuild test -scheme Verity -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Bug Fixes & Improvements

PRs welcome. Run tests before submitting:

```bash
xcodebuild test -scheme Verity \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipPackagePluginValidation
```
