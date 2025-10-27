#!/bin/bash
# test_build.sh - Script to test/validate the k2pdfopt WebAssembly build
#
# Usage:
#   ./test_build.sh [options]
#
# Options:
#   --validate-only    Only validate configuration without building (default if emcc not available)
#   --build            Attempt to build (requires Emscripten)
#   --help             Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
WARNINGS=0

# Default mode
VALIDATE_ONLY=0
BUILD_MODE=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --validate-only)
            VALIDATE_ONLY=1
            shift
            ;;
        --build)
            BUILD_MODE=1
            shift
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --validate-only    Only validate configuration without building"
            echo "  --build            Attempt to build (requires Emscripten)"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Helper functions
print_header() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    WARNINGS=$((WARNINGS + 1))
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_file_exists() {
    local file=$1
    local description=$2
    print_test "Checking for $description: $file"
    if [ -f "$file" ]; then
        print_pass "$description exists"
        return 0
    else
        print_fail "$description not found"
        return 1
    fi
}

check_dir_exists() {
    local dir=$1
    local description=$2
    print_test "Checking for $description: $dir"
    if [ -d "$dir" ]; then
        print_pass "$description exists"
        return 0
    else
        print_fail "$description not found"
        return 1
    fi
}

# Start testing
print_header "K2pdfopt WebAssembly Build Test"
echo ""

# Check if Emscripten is available
print_test "Checking for Emscripten (emcc)"
if command -v emcc &> /dev/null; then
    EMCC_VERSION=$(emcc --version | head -n 1)
    print_pass "Emscripten found: $EMCC_VERSION"
    EMSCRIPTEN_AVAILABLE=1
else
    print_warning "Emscripten not found (required for building)"
    EMSCRIPTEN_AVAILABLE=0
    if [ $BUILD_MODE -eq 1 ]; then
        print_fail "Build mode requested but Emscripten not available"
        exit 1
    fi
    if [ $VALIDATE_ONLY -eq 0 ]; then
        print_info "Defaulting to validation-only mode"
        VALIDATE_ONLY=1
    fi
fi
echo ""

# Validate repository structure
print_header "Validating Repository Structure"
echo ""

check_file_exists "build_wasm.sh" "Build script"
check_file_exists "CMakeLists.txt" "Root CMakeLists.txt"
check_file_exists "config.h.in" "Config header template"

check_dir_exists "wasm" "WASM directory"
check_dir_exists "willuslib" "Willus library directory"
check_dir_exists "k2pdfoptlib" "K2pdfopt library directory"
echo ""

# Validate WASM directory contents
print_header "Validating WASM Directory"
echo ""

check_file_exists "wasm/CMakeLists.txt" "WASM CMakeLists.txt"
check_file_exists "wasm/k2pdfopt_wasm.c" "WASM wrapper source"
check_file_exists "wasm/README.md" "WASM README"
check_file_exists "wasm/example.html" "WASM example HTML"
echo ""

# Validate CMakeLists.txt configuration
print_header "Validating WASM CMakeLists.txt Configuration"
echo ""

WASM_CMAKE="wasm/CMakeLists.txt"
print_test "Checking for Emscripten requirement check"
if grep -q "if(NOT EMSCRIPTEN)" "$WASM_CMAKE"; then
    print_pass "Emscripten check found"
else
    print_fail "Emscripten check not found"
fi

print_test "Checking for exported functions"
if grep -q "EXPORTED_FUNCTIONS" "$WASM_CMAKE"; then
    print_pass "Exported functions configuration found"
else
    print_fail "Exported functions configuration not found"
fi

print_test "Checking for WASM compilation flags"
if grep -q "WASM=1" "$WASM_CMAKE"; then
    print_pass "WASM flag found"
else
    print_fail "WASM flag not found"
fi

print_test "Checking for memory growth configuration"
if grep -q "ALLOW_MEMORY_GROWTH=1" "$WASM_CMAKE"; then
    print_pass "Memory growth configuration found"
else
    print_fail "Memory growth configuration not found"
fi

print_test "Checking for filesystem support"
if grep -q "FILESYSTEM=1" "$WASM_CMAKE"; then
    print_pass "Filesystem support enabled"
else
    print_fail "Filesystem support not enabled"
fi
echo ""

# Validate source files
print_header "Validating Source Files"
echo ""

print_test "Checking for k2pdfoptlib sources"
K2PDFOPT_SOURCES=$(find k2pdfoptlib -name "*.c" 2>/dev/null | wc -l)
if [ "$K2PDFOPT_SOURCES" -gt 0 ]; then
    print_pass "Found $K2PDFOPT_SOURCES k2pdfoptlib source files"
else
    print_fail "No k2pdfoptlib source files found"
fi

print_test "Checking for willuslib sources"
WILLUS_SOURCES=$(find willuslib -name "*.c" 2>/dev/null | wc -l)
if [ "$WILLUS_SOURCES" -gt 0 ]; then
    print_pass "Found $WILLUS_SOURCES willuslib source files"
else
    print_fail "No willuslib source files found"
fi

# Check for conditionally excluded files mentioned in CMakeLists.txt
print_test "Checking for conditional source files (may be excluded in minimal build)"
CONDITIONAL_FILES=("willuslib/ocrtess.c" "willuslib/ocrgocr.c" "willuslib/bmpmupdf.c" 
                   "willuslib/wmupdf.c" "willuslib/wmupdfinfo.c" "willuslib/bmpdjvu.c"
                   "willuslib/wleptonica.c" "willuslib/gslpolyfit.c")
for file in "${CONDITIONAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        print_info "Conditional file exists: $file"
    else
        print_warning "Conditional file not found (may be expected): $file"
    fi
done
echo ""

# Validate build script
print_header "Validating Build Script"
echo ""

print_test "Checking build_wasm.sh is executable"
if [ -x "build_wasm.sh" ]; then
    print_pass "build_wasm.sh is executable"
else
    print_warning "build_wasm.sh is not executable (can be fixed with chmod +x)"
fi

print_test "Checking for Emscripten check in build script"
if grep -q "command -v emcc" "build_wasm.sh"; then
    print_pass "Build script checks for Emscripten"
else
    print_fail "Build script doesn't check for Emscripten"
fi

print_test "Checking for build directory creation"
if grep -q "mkdir -p.*BUILD_DIR" "build_wasm.sh"; then
    print_pass "Build script creates build directory"
else
    print_fail "Build script doesn't create build directory"
fi
echo ""

# If Emscripten is available and build mode is requested, attempt build
if [ $EMSCRIPTEN_AVAILABLE -eq 1 ] && [ $BUILD_MODE -eq 1 ]; then
    print_header "Attempting Build"
    echo ""
    
    print_info "Running build_wasm.sh..."
    if ./build_wasm.sh; then
        print_pass "Build completed successfully"
        
        # Verify output files
        print_test "Checking for output WASM file"
        if [ -f "wasm/build/k2pdfopt_wasm.wasm" ]; then
            WASM_SIZE=$(du -h wasm/build/k2pdfopt_wasm.wasm | cut -f1)
            print_pass "WASM file generated (size: $WASM_SIZE)"
        else
            print_fail "WASM file not generated"
        fi
        
        print_test "Checking for output JS file"
        if [ -f "wasm/build/k2pdfopt_wasm.js" ]; then
            JS_SIZE=$(du -h wasm/build/k2pdfopt_wasm.js | cut -f1)
            print_pass "JS file generated (size: $JS_SIZE)"
        else
            print_fail "JS file not generated"
        fi
    else
        print_fail "Build failed"
    fi
    echo ""
fi

# Validate documentation
print_header "Validating Documentation"
echo ""

print_test "Checking for WASM README"
if [ -f "wasm/README.md" ]; then
    print_pass "WASM README exists"
    
    # Check for key sections in README
    print_test "Checking README for prerequisites section"
    if grep -qi "prerequisite" "wasm/README.md"; then
        print_pass "Prerequisites section found"
    else
        print_warning "Prerequisites section not found in README"
    fi
    
    print_test "Checking README for building section"
    if grep -qi "building\|build" "wasm/README.md"; then
        print_pass "Building section found"
    else
        print_warning "Building section not found in README"
    fi
    
    print_test "Checking README for API documentation"
    if grep -qi "api\|function" "wasm/README.md"; then
        print_pass "API documentation found"
    else
        print_warning "API documentation not found in README"
    fi
else
    print_fail "WASM README not found"
fi
echo ""

# Summary
print_header "Test Summary"
echo ""
echo -e "Tests passed:  ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed:  ${RED}$TESTS_FAILED${NC}"
echo -e "Warnings:      ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    if [ $EMSCRIPTEN_AVAILABLE -eq 0 ]; then
        echo -e "${YELLOW}Note: Emscripten not available - build not tested${NC}"
        echo -e "${YELLOW}Install Emscripten and use --build flag to test actual build${NC}"
    fi
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi
