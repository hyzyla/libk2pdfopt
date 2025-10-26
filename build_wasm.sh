#!/bin/bash
# build_wasm.sh - Script to build k2pdfopt as WebAssembly

set -e

echo "Building k2pdfopt WebAssembly module..."

# Check if emscripten is available
if ! command -v emcc &> /dev/null; then
    echo "Error: Emscripten is not installed or not in PATH"
    echo "Please install Emscripten: https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi

# Create build directory
BUILD_DIR="wasm/build"
mkdir -p "$BUILD_DIR"

# Navigate to build directory
cd "$BUILD_DIR"

# Configure with emscripten
echo "Configuring..."
emcmake cmake ..

# Build
echo "Building..."
emmake make

# Check if build was successful
if [ -f "k2pdfopt_wasm.wasm" ] && [ -f "k2pdfopt_wasm.js" ]; then
    echo ""
    echo "✓ Build successful!"
    echo ""
    echo "Output files:"
    echo "  - k2pdfopt_wasm.wasm"
    echo "  - k2pdfopt_wasm.js"
    echo ""
    echo "These files can be used in a web application."
    echo "See wasm/example.html for usage example."
else
    echo "Error: Build failed - WASM files not generated"
    exit 1
fi
