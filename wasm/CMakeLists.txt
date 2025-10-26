# CMakeLists.txt for k2pdfopt WebAssembly build
# This builds k2pdfopt as a WebAssembly module using Emscripten

project(k2pdfopt-wasm C)
cmake_minimum_required(VERSION 3.10)

# Set compiler to emscripten
if(NOT EMSCRIPTEN)
    message(FATAL_ERROR "This CMakeLists.txt must be built with Emscripten. Use: emcmake cmake ..")
endif()

# Simplified build - no external dependencies for minimal WASM build
# This creates a minimal k2pdfopt that can work with basic PDFs

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSE_CMAKE -DK2PDFOPT_KINDLEPDFVIEWER")

# Disable third-party libraries for minimal build
# This reduces WASM size and avoids dependency issues
# Don't define these - let config.h handle it based on CMake variables

include_directories(.. ../willuslib ../k2pdfoptlib "${PROJECT_BINARY_DIR}")

# Set all HAVE_* variables to OFF for minimal build
set(HAVE_Z_LIB OFF)
set(HAVE_PNG_LIB OFF)
set(HAVE_JPEG_LIB OFF)
set(HAVE_JASPER_LIB OFF)
set(HAVE_GSL_LIB OFF)
set(HAVE_MUPDF_LIB OFF)
set(HAVE_GHOSTSCRIPT OFF)
set(HAVE_DJVU_LIB OFF)
set(HAVE_GOCR_LIB OFF)
set(HAVE_LEPTONICA_LIB OFF)
set(HAVE_TESSERACT_LIB OFF)

configure_file(
  "${CMAKE_SOURCE_DIR}/../config.h.in"
  "${PROJECT_BINARY_DIR}/config.h"
)

# Build willus library
file(GLOB WILLUS_SOURCES "../willuslib/*.c")
add_library(willuslib ${WILLUS_SOURCES})

# Build k2pdfopt library
file(GLOB K2PDFOPT_SOURCES "../k2pdfoptlib/*.c")
add_library(k2pdfoptlib ${K2PDFOPT_SOURCES})

# Build WASM wrapper
add_executable(k2pdfopt_wasm k2pdfopt_wasm.c)
target_link_libraries(k2pdfopt_wasm k2pdfoptlib willuslib)

# Emscripten-specific settings
set_target_properties(k2pdfopt_wasm PROPERTIES
    LINK_FLAGS "\
        -s WASM=1 \
        -s EXPORTED_FUNCTIONS='[\"_k2pdfopt_wasm_init\",\"_k2pdfopt_wasm_cleanup\",\"_k2pdfopt_wasm_version\",\"_k2pdfopt_wasm_set_device\",\"_k2pdfopt_wasm_set_width\",\"_k2pdfopt_wasm_set_height\",\"_k2pdfopt_wasm_set_margins\",\"_k2pdfopt_wasm_process_file\",\"_k2pdfopt_wasm_get_page_count\",\"_k2pdfopt_wasm_set_quality\",\"_k2pdfopt_wasm_set_ocr\",\"_k2pdfopt_wasm_set_page_range\"]' \
        -s EXPORTED_RUNTIME_METHODS='[\"ccall\",\"cwrap\",\"FS\"]' \
        -s ALLOW_MEMORY_GROWTH=1 \
        -s MODULARIZE=1 \
        -s EXPORT_NAME='createK2pdfoptModule' \
        -s FILESYSTEM=1 \
        -s INITIAL_MEMORY=67108864 \
        -s STACK_SIZE=5242880 \
        -s ENVIRONMENT='web,worker' \
        -s ERROR_ON_UNDEFINED_SYMBOLS=0 \
        --no-entry"
)
