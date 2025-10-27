# Testing the WebAssembly Build

This document describes how to test the k2pdfopt WebAssembly build.

## Overview

The repository includes comprehensive testing infrastructure for the WebAssembly build, allowing validation of the build configuration even when Emscripten is not available.

## Test Script

The `test_build.sh` script provides automated validation of:
- Repository structure and required files
- WASM CMakeLists.txt configuration
- Source file availability  
- Build script correctness
- Documentation completeness

### Usage

#### Validate without Emscripten

To validate the build configuration without requiring Emscripten (useful for development environments where Emscripten is not installed):

```bash
./test_build.sh --validate-only
```

Or simply:

```bash
./test_build.sh
```

The script will automatically detect that Emscripten is not available and run in validation-only mode.

#### Build and Test with Emscripten

If Emscripten is installed, you can test the actual build process:

```bash
./test_build.sh --build
```

This will:
1. Run all validation tests
2. Execute the build_wasm.sh script
3. Verify that WASM and JS files are generated
4. Report build artifacts

### Exit Codes

- `0`: All tests passed
- `1`: One or more tests failed

## Continuous Integration

The repository includes a GitHub Actions workflow (`.github/workflows/test-wasm-build.yml`) that automatically tests the build on every push and pull request.

### Workflow Jobs

1. **validate**: Validates build configuration without Emscripten
   - Runs on every push/PR
   - Fast (< 1 minute)
   - Catches configuration issues early

2. **build**: Builds the WASM module with Emscripten
   - Runs after validation passes
   - Requires Emscripten setup (takes ~5-10 minutes)
   - Generates build artifacts
   - Uploads WASM and JS files for inspection

### Triggering the Workflow

The workflow automatically triggers on:
- Pushes to `main` or `master` branches
- Pull requests to `main` or `master` branches
- Changes to relevant files:
  - `wasm/**`
  - `willuslib/**`
  - `k2pdfoptlib/**`
  - `build_wasm.sh`
  - `test_build.sh`
  - `.github/workflows/test-wasm-build.yml`

You can also manually trigger the workflow from the GitHub Actions tab.

## What Gets Tested

### Repository Structure
- Presence of build script (`build_wasm.sh`)
- Root CMakeLists.txt file
- Config header template
- Required directories (wasm, willuslib, k2pdfoptlib)

### WASM Directory
- CMakeLists.txt configuration
- Wrapper source code (k2pdfopt_wasm.c)
- Documentation (README.md)
- Example HTML file

### CMakeLists.txt Configuration
- Emscripten requirement check
- Exported functions configuration
- WASM compilation flags
- Memory growth settings
- Filesystem support

### Source Files
- k2pdfoptlib sources (28 files expected)
- willuslib sources (43 files expected)
- Conditionally excluded files based on disabled dependencies

### Build Script
- Executable permissions
- Emscripten availability check
- Build directory creation
- Error handling

### Documentation
- README completeness
- Prerequisites section
- Building instructions
- API documentation

## Local Development

When developing changes to the WASM build:

1. **Before making changes**: Run `./test_build.sh` to establish a baseline
2. **After making changes**: Run `./test_build.sh` to verify nothing broke
3. **Before committing**: Ensure all tests pass
4. **When adding new features**: Update the test script to validate them

## Debugging Build Issues

If the build fails:

1. Run validation first: `./test_build.sh --validate-only`
   - This checks if the configuration is correct
   
2. Check individual components:
   - Build script: `./build_wasm.sh`
   - CMake configuration: `cd wasm/build && emcmake cmake ..`
   - Compilation: `cd wasm/build && emmake make VERBOSE=1`

3. Review test output for specific failures:
   - Red `[FAIL]` messages indicate critical issues
   - Yellow `[WARN]` messages indicate potential problems
   - Green `[PASS]` messages indicate successful validations

## Adding New Tests

To add new validation tests to `test_build.sh`:

1. Add test in appropriate section (Repository Structure, WASM Directory, etc.)
2. Use helper functions:
   - `check_file_exists <file> <description>`
   - `check_dir_exists <dir> <description>`
   - `print_test <message>`
   - `print_pass <message>`
   - `print_fail <message>`
   - `print_warning <message>`

3. Update test counters automatically (helpers do this)
4. Test your new validation to ensure it works correctly

Example:

```bash
print_test "Checking for new config file"
if [ -f "wasm/new_config.json" ]; then
    print_pass "New config file exists"
else
    print_fail "New config file not found"
fi
```

## Environment Requirements

### For Validation Only
- Bash shell
- Unix utilities: `find`, `grep`, `wc`, `cut`, `du`, `head`, `mkdir`, `ls`

### For Building
- Emscripten SDK (latest version recommended)
- CMake 3.10 or later
- All validation requirements

## Troubleshooting

### Test script not executable
```bash
chmod +x test_build.sh
```

### Expected warnings vs. problems
The test script distinguishes between warnings and failures:

**Expected warnings** (don't indicate problems):
- `Emscripten not found` when running validation-only mode
- `build_wasm.sh is not executable` (can be fixed with chmod +x)
- Conditional source files not found when they're excluded by design

**Actual failures** (indicate problems):
- Required files missing (CMakeLists.txt, source files, etc.)
- Configuration errors in CMakeLists.txt
- Build script missing critical checks

If you see a warning, check if it's in the expected list above. If not, it may indicate a real issue.

### CI workflow not triggering
Check that your changes affect files listed in the workflow's `paths` configuration.

## Future Improvements

Potential enhancements to the test infrastructure:
- Add performance benchmarks for build time
- Test WASM module loading in browser environment
- Validate WASM binary size against thresholds
- Test with different Emscripten versions
- Add integration tests for API functions
