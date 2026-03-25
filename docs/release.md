# Release Process

How to cut a new release of the Verity SDK.

## Prerequisites

- `gh` CLI installed and authenticated (`brew install gh`)
- xcframework already built (`bash scripts/build-xcframework.sh <provekit-path> <zk-ffi-path>`)
- All tests passing

## Steps

### 1. Build the xcframework

```bash
bash scripts/build-xcframework.sh ../provekit ../zk-ffi
```

### 2. Run tests

```bash
xcodebuild test \
  -scheme Verity \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -skipPackagePluginValidation
```

### 3. Release

```bash
bash scripts/release.sh v0.2.0
```

This will:
- Zip `output/Verity.xcframework`
- Compute SHA256 checksum
- Create a GitHub Release and upload the zip
- Print the `Package.swift` snippet

Output looks like:
```
Checksum: a259f8ca5295942b7b167772b38efea1f0104dfc5c1fe5e7336178190b089c0c

Update Package.swift with:

  .binaryTarget(
      name: "VerityFFI",
      url: "https://github.com/ashpect/verity/releases/download/v0.2.0/Verity.xcframework.zip",
      checksum: "a259f8ca..."
  )
```

### 4. Update Package.swift

Replace the local path with the release URL:

```swift
// Before (local dev):
.binaryTarget(name: "VerityFFI", path: "output/Verity.xcframework")

// After (release):
.binaryTarget(
    name: "VerityFFI",
    url: "https://github.com/ashpect/verity/releases/download/v0.2.0/Verity.xcframework.zip",
    checksum: "a259f8ca..."
)
```

### 5. Commit, tag, push

```bash
git add Package.swift
git commit -m "release: v0.2.0"
git tag v0.2.0
git push origin main --tags
```

---

## How users consume a release

### New project

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ashpect/verity", from: "0.2.0")
]
```

Or in Xcode: File → Add Package Dependencies → paste repo URL → select version.

### Existing project

SPM resolves the new version automatically on next build. To force update:

```bash
swift package update
```

Or in Xcode: File → Packages → Update to Latest Package Versions.

---

## How examples use the released SDK

The examples in `Examples/` use a local package reference (`path: ../..`) for development. To point them at a released version instead:

### Option A: Local (development)

`project.yml` already has:
```yaml
packages:
  Verity:
    path: ../..
```

This uses whatever is on disk. No release needed.

### Option B: Released version

Change `project.yml` to:
```yaml
packages:
  Verity:
    url: https://github.com/ashpect/verity
    from: 0.2.0
```

Then `xcodegen generate` and the example will pull the released SDK via SPM.

---

## Versioning

Follow [semver](https://semver.org/):

| Change | Version bump | Example |
|--------|-------------|---------|
| New FFI functions, new Swift API | Minor (`0.2.0` → `0.3.0`) | Added `prove_json`, dictionary inputs |
| Bug fix, no API change | Patch (`0.2.0` → `0.2.1`) | Fixed zstd decompression overflow |
| Breaking API change | Major (`0.x` → `1.0.0`) | Renamed `prove()` parameters |

While on `0.x`, minor bumps can include breaking changes. Target `1.0.0` when the API stabilizes.
