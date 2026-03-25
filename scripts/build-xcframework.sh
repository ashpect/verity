#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROVEKIT_ROOT="${PROVEKIT_ROOT:-$(cd "$SDK_DIR/../provekit" && pwd)}"
BB_FFI_DIR="${BB_FFI_ROOT:-$(cd "$SDK_DIR/../zk-ffi" && pwd)}"
OUTPUT_DIR="$SDK_DIR/output"

if [ ! -f "$PROVEKIT_ROOT/Cargo.toml" ]; then
    echo "ERROR: Cannot find provekit repo at $PROVEKIT_ROOT"
    echo "Set PROVEKIT_ROOT env var to the provekit repo path."
    exit 1
fi

if [ ! -f "$BB_FFI_DIR/Cargo.toml" ]; then
    echo "ERROR: Cannot find zk-ffi repo at $BB_FFI_DIR"
    echo "Set BB_FFI_ROOT env var to the zk-ffi repo path."
    exit 1
fi

echo "=== Building Verity xcframework ==="
echo "SDK dir:       $SDK_DIR"
echo "ProveKit root: $PROVEKIT_ROOT"
echo "BB FFI dir:    $BB_FFI_DIR"
echo ""

# --- Build provekit-ffi ---
pushd "$PROVEKIT_ROOT" > /dev/null

rustup target add aarch64-apple-ios aarch64-apple-ios-sim 2>/dev/null || true

echo "Building provekit-ffi for aarch64-apple-ios..."
cargo build --release --target aarch64-apple-ios -p provekit-ffi

echo "Building provekit-ffi for aarch64-apple-ios-sim..."
cargo build --release --target aarch64-apple-ios-sim -p provekit-ffi

popd > /dev/null

# --- Build barretenberg-ffi ---
pushd "$BB_FFI_DIR" > /dev/null

echo ""
echo "Building barretenberg-ffi for aarch64-apple-ios..."
cargo build --release --target aarch64-apple-ios

echo "Building barretenberg-ffi for aarch64-apple-ios-sim..."
cargo build --release --target aarch64-apple-ios-sim

popd > /dev/null

# --- Compile dispatch layer ---
echo ""
echo "Compiling verity_dispatch.c..."

DISPATCH_DIR=$(mktemp -d)

xcrun --sdk iphoneos clang -c -target arm64-apple-ios15 \
    -I"$SDK_DIR/include" \
    "$SDK_DIR/src/verity_dispatch.c" \
    -o "$DISPATCH_DIR/verity_dispatch_ios.o"

xcrun --sdk iphonesimulator clang -c -target arm64-apple-ios15-simulator \
    -I"$SDK_DIR/include" \
    "$SDK_DIR/src/verity_dispatch.c" \
    -o "$DISPATCH_DIR/verity_dispatch_sim.o"

# Create static libs from dispatch objects
ar rcs "$DISPATCH_DIR/libverity_dispatch_ios.a" "$DISPATCH_DIR/verity_dispatch_ios.o"
ar rcs "$DISPATCH_DIR/libverity_dispatch_sim.a" "$DISPATCH_DIR/verity_dispatch_sim.o"

# --- Merge static libs ---
echo ""
echo "Merging static libraries..."

MERGED_DIR=$(mktemp -d)
mkdir -p "$MERGED_DIR/ios-arm64" "$MERGED_DIR/ios-arm64-sim"

libtool -static -o "$MERGED_DIR/ios-arm64/libverity.a" \
    "$PROVEKIT_ROOT/target/aarch64-apple-ios/release/libprovekit_ffi.a" \
    "$BB_FFI_DIR/target/aarch64-apple-ios/release/libbarretenberg_ffi.a" \
    "$DISPATCH_DIR/libverity_dispatch_ios.a"

libtool -static -o "$MERGED_DIR/ios-arm64-sim/libverity.a" \
    "$PROVEKIT_ROOT/target/aarch64-apple-ios-sim/release/libprovekit_ffi.a" \
    "$BB_FFI_DIR/target/aarch64-apple-ios-sim/release/libbarretenberg_ffi.a" \
    "$DISPATCH_DIR/libverity_dispatch_sim.a"

# --- Create headers + modulemap ---
HEADERS_DIR=$(mktemp -d)
cp "$SDK_DIR/include/verity_ffi.h" "$HEADERS_DIR/verity_ffi.h"
cat > "$HEADERS_DIR/module.modulemap" <<'MODULEMAP'
module VerityFFI {
    header "verity_ffi.h"
    link "verity"
    export *
}
MODULEMAP

# --- Create xcframework ---
mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR/Verity.xcframework"

echo ""
echo "Creating xcframework..."
xcodebuild -create-xcframework \
    -library "$MERGED_DIR/ios-arm64/libverity.a" \
    -headers "$HEADERS_DIR" \
    -library "$MERGED_DIR/ios-arm64-sim/libverity.a" \
    -headers "$HEADERS_DIR" \
    -output "$OUTPUT_DIR/Verity.xcframework"

# Clean up temp dirs
rm -rf "$HEADERS_DIR" "$MERGED_DIR" "$DISPATCH_DIR"

echo ""
echo "=== Done! ==="
echo "xcframework: $OUTPUT_DIR/Verity.xcframework"
echo ""
echo "To release, run: bash scripts/release.sh <version>"
