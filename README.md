# libk2pdfopt

K2pdfopt library for PDF optimization and reflow.

## WebAssembly Build

This repository includes a WebAssembly build that allows k2pdfopt to run in web browsers. See the [wasm/README.md](wasm/README.md) for details.

### Building

To build the WASM version:

```bash
./build_wasm.sh
```

### Testing

To test the build configuration and validate the setup:

```bash
./test_build.sh
```

This will validate the build configuration without requiring Emscripten. If Emscripten is installed, you can test the actual build with:

```bash
./test_build.sh --build
```

For more information, see the [upstream k2pdfopt documentation](http://willus.com/k2pdfopt/).
