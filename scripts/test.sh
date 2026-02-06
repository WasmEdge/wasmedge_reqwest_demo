#!/bin/bash
set -e

echo "=== WasmEdge Reqwest Demo - Local Test Script ==="
echo ""

# Check prerequisites
echo "--- Checking prerequisites ---"

if ! command -v rustup &> /dev/null; then
    echo "ERROR: rustup not found. Install Rust first:"
    echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi
echo "Updating to latest stable Rust..."
rustup update stable
rustup target add wasm32-wasip1
echo "rustc: $(rustc --version)"
echo "cargo: $(cargo --version)"

if ! command -v wasmedge &> /dev/null; then
    echo "WasmEdge not found. Installing latest WasmEdge..."
    curl -sSf https://raw.githubusercontent.com/WasmEdge/WasmEdge/master/utils/install.sh | bash
    source "$HOME/.wasmedge/env"
fi
echo "wasmedge: $(wasmedge --version)"

# Detect wasi-sdk for C dependency compilation (ring crate)
# The system clang (especially on macOS) does not support the wasm32-wasip1
# target, so we need the clang bundled with wasi-sdk.
if [ -z "$CC_wasm32_wasip1" ]; then
    # Try common install locations
    for candidate in \
        "$WASI_SDK_PATH/bin/clang" \
        /opt/wasi-sdk/bin/clang \
        /opt/wasi-sdk-*/bin/clang \
        "$HOME/wasi-sdk/bin/clang" \
        "$HOME/wasi-sdk-*/bin/clang"; do
        # candidate may be a glob, expand it
        for f in $candidate; do
            if [ -x "$f" ]; then
                export CC_wasm32_wasip1="$f"
                break 2
            fi
        done
    done
fi

if [ -n "$CC_wasm32_wasip1" ]; then
    echo "CC_wasm32_wasip1: $CC_wasm32_wasip1"
else
    echo ""
    echo "WARNING: CC_wasm32_wasip1 is not set and wasi-sdk was not found."
    echo "The build will fail when compiling C dependencies (e.g. ring)."
    echo ""
    echo "Install wasi-sdk and either:"
    echo "  1. Set WASI_SDK_PATH to the install directory, or"
    echo "  2. Set CC_wasm32_wasip1 to the wasi-sdk clang binary path"
    echo ""
    echo "Example:"
    echo "  export CC_wasm32_wasip1=/path/to/wasi-sdk/bin/clang"
    echo ""
    echo "See README.md for full wasi-sdk install instructions."
    exit 1
fi
echo ""

# Resolve target directory (respect CARGO_TARGET_DIR if set)
TARGET_DIR="${CARGO_TARGET_DIR:-target}"
WASM_DIR="${TARGET_DIR}/wasm32-wasip1/release"

# Build
echo "--- Building project ---"
cargo build --target wasm32-wasip1 --release
echo "Build succeeded."
echo ""

# AOT compile (optional — skip with SKIP_AOT=1)
if [ "${SKIP_AOT:-0}" != "1" ]; then
    echo "--- AOT compiling WASM binaries ---"
    wasmedge compile "${WASM_DIR}/http.wasm" http_aot.wasm
    wasmedge compile "${WASM_DIR}/https.wasm" https_aot.wasm
    echo "AOT compilation succeeded."
    echo ""
    HTTP_WASM=http_aot.wasm
    HTTPS_WASM=https_aot.wasm
else
    echo "--- Skipping AOT compilation (SKIP_AOT=1) ---"
    echo ""
    HTTP_WASM="${WASM_DIR}/http.wasm"
    HTTPS_WASM="${WASM_DIR}/https.wasm"
fi

# Test HTTP
echo "--- Testing HTTP client ---"
PASS=0
FAIL=0

# Timeout per test (seconds); override with TEST_TIMEOUT env var
TIMEOUT="${TEST_TIMEOUT:-30}"

resp=$(timeout -s KILL "$TIMEOUT" wasmedge "$HTTP_WASM" 2>&1) || true
echo "$resp"
if [[ $resp == *"WasmEdge"* ]]; then
    echo "HTTP test: PASSED"
    PASS=$((PASS + 1))
else
    echo "HTTP test: FAILED"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test HTTPS
echo "--- Testing HTTPS client ---"
resp=$(timeout -s KILL "$TIMEOUT" wasmedge "$HTTPS_WASM" 2>&1) || true
echo "$resp"
if [[ $resp == *"WasmEdge"* ]]; then
    echo "HTTPS test: PASSED"
    PASS=$((PASS + 1))
else
    echo "HTTPS test: FAILED"
    FAIL=$((FAIL + 1))
fi
echo ""

# Cleanup AOT artifacts
rm -f http_aot.wasm https_aot.wasm

# Summary
echo "=== Results: $PASS passed, $FAIL failed ==="
if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
