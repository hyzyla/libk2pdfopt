# K2pdfopt WebAssembly Build

This directory contains the WebAssembly (WASM) build configuration for k2pdfopt, allowing the library to run in web browsers.

## Prerequisites

- Emscripten SDK (https://emscripten.org/)
- CMake 3.10 or later

### Installing Emscripten on Ubuntu/Debian

```bash
sudo apt-get install emscripten
```

Or follow the official Emscripten installation guide at https://emscripten.org/docs/getting_started/downloads.html

## Building

To build the WASM module, run the build script from the repository root:

```bash
./build_wasm.sh
```

This will:
1. Configure the project using emcmake
2. Compile the k2pdfopt library and all dependencies
3. Generate `k2pdfopt_wasm.js` and `k2pdfopt_wasm.wasm` in the `wasm/build/` directory

## Output Files

The build produces two files:

- **k2pdfopt_wasm.wasm**: The WebAssembly binary (~53KB)
- **k2pdfopt_wasm.js**: JavaScript glue code for loading and interfacing with the WASM module (~199KB)

## API Functions

The WASM module exposes the following functions:

### Initialization

```javascript
// Initialize the library (must be called first)
k2pdfopt_wasm_init() -> int (0 on success, non-zero on error)

// Clean up resources
k2pdfopt_wasm_cleanup() -> void

// Get version string
k2pdfopt_wasm_version() -> string
```

### Configuration

```javascript
// Set output device type (e.g., "kindle", "kv", "dx", "k2")
k2pdfopt_wasm_set_device(device: string) -> int

// Set output width in pixels
k2pdfopt_wasm_set_width(width: int) -> int

// Set output height in pixels
k2pdfopt_wasm_set_height(height: int) -> int

// Set quality level (1-3, where 3 is highest)
k2pdfopt_wasm_set_quality(quality: int) -> int

// Set page range to process (e.g., "1-10", "1,3,5")
k2pdfopt_wasm_set_page_range(range: string) -> int

// Enable/disable OCR (returns -1 if OCR not available)
k2pdfopt_wasm_set_ocr(enable: int) -> int

// Set margins (currently placeholder - not fully implemented)
k2pdfopt_wasm_set_margins(left: double, top: double, right: double, bottom: double) -> int
```

### Processing

```javascript
// Process a PDF file from virtual filesystem
k2pdfopt_wasm_process_file(input_file: string, output_file: string) -> int

// Get number of pages in a PDF file
k2pdfopt_wasm_get_page_count(filename: string) -> int
```

## Usage Example

See `example.html` for a complete working example. Basic usage:

```javascript
// Load the WASM module
const Module = await createK2pdfoptModule();

// Initialize
Module.ccall('k2pdfopt_wasm_init', 'number', [], []);

// Configure
Module.ccall('k2pdfopt_wasm_set_device', 'number', ['string'], ['kv']);
Module.ccall('k2pdfopt_wasm_set_width', 'number', ['number'], [600]);
Module.ccall('k2pdfopt_wasm_set_height', 'number', ['number'], [800]);

// Load PDF into virtual filesystem
const pdfData = new Uint8Array(await file.arrayBuffer());
Module.FS.writeFile('/input.pdf', pdfData);

// Process
Module.ccall('k2pdfopt_wasm_process_file', 'number', 
    ['string', 'string'], ['/input.pdf', '/output.pdf']);

// Read output
const outputData = Module.FS.readFile('/output.pdf');

// Clean up
Module.ccall('k2pdfopt_wasm_cleanup', null, [], []);
```

## Limitations

This WASM build has the following limitations compared to the full k2pdfopt:

1. **No external library dependencies**: PDF/DJVU reading, OCR, and image format support from external libraries (MuPDF, Tesseract, etc.) are disabled to reduce size and complexity.
2. **No margin API**: The margin setting API is a placeholder and not fully functional.
3. **Limited PDF features**: Advanced PDF features may not work without MuPDF.
4. **No OCR**: OCR functionality is not available in this build.

## Architecture

The WASM build:
- Compiles the core k2pdfopt library (`k2pdfoptlib`) and willus library (`willuslib`)
- Excludes OCR-specific files (ocrtess.c, ocrgocr.c)
- Excludes PDF/DJVU reader files that require external libraries (bmpmupdf.c, bmpdjvu.c)
- Uses Emscripten's virtual filesystem for file I/O
- Exports functions with `EMSCRIPTEN_KEEPALIVE` to make them accessible from JavaScript

## License

K2pdfopt is licensed under the GNU Affero General Public License v3.0.
See the main repository LICENSE file for details.

## Troubleshooting

### Build fails with "emcc not found"
Install Emscripten as described in Prerequisites.

### Build fails with undefined symbols
Some undefined symbol warnings are expected and can be ignored. The build uses `ERROR_ON_UNDEFINED_SYMBOLS=0` to allow these.

### WASM module fails to load in browser
Ensure you're serving the files over HTTP/HTTPS, not file:// protocol. Use a local web server like:
```bash
python3 -m http.server 8000
```

### Out of memory errors
The WASM module uses `ALLOW_MEMORY_GROWTH=1` which allows it to allocate more memory as needed, up to browser limits. For very large PDFs, this may still be insufficient.
