/*
** k2pdfopt_wasm.c - WASM wrapper for k2pdfopt library
**
** This file provides a simple C API that can be compiled to WebAssembly
** using Emscripten. It exposes key functions from k2pdfopt for web usage.
**
** Copyright (C) 2024
**
** This program is free software: you can redistribute it and/or modify
** it under the terms of the GNU Affero General Public License as
** published by the Free Software Foundation, either version 3 of the
** License, or (at your option) any later version.
*/

#include <k2pdfopt.h>
#include <emscripten.h>
#include <string.h>
#include <stdlib.h>

/* External version string from k2version.c */
extern char *k2pdfopt_version;

static K2PDFOPT_CONVERSION k2conv;
static K2PDFOPT_SETTINGS *k2settings = NULL;
static int initialized = 0;

/**
 * Initialize k2pdfopt library
 * Must be called before any other functions
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_init(void) {
    if (initialized) {
        return 1;
    }
    
    k2pdfopt_conversion_init(&k2conv);
    k2settings = &k2conv.k2settings;
    k2sys_init();
    k2pdfopt_settings_init(k2settings);
    k2pdfopt_files_clear(&k2conv.k2files);
    
    initialized = 1;
    return 0;
}

/**
 * Clean up k2pdfopt library resources
 */
EMSCRIPTEN_KEEPALIVE
void k2pdfopt_wasm_cleanup(void) {
    if (!initialized) {
        return;
    }
    
    k2sys_close(k2settings);
    k2pdfopt_conversion_close(&k2conv);
    initialized = 0;
}

/**
 * Get the version string
 */
EMSCRIPTEN_KEEPALIVE
const char* k2pdfopt_wasm_version(void) {
    return k2pdfopt_version;
}

/**
 * Set output device type using device profile
 * device: device name string (e.g., "kindle", "kv", "dx", "k2")
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_device(const char* device) {
    DEVPROFILE *dp;
    
    if (!initialized || !device) {
        return -1;
    }
    
    dp = devprofile_get(device);
    if (dp == NULL) {
        return -1;
    }
    
    if (!k2pdfopt_settings_set_to_device(k2settings, dp)) {
        return -1;
    }
    
    return 0;
}

/**
 * Set output width in pixels
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_width(int width) {
    if (!initialized || width <= 0) {
        return -1;
    }
    
    k2settings->dst_userwidth = width;
    k2settings->dst_userwidth_units = UNITS_PIXELS;
    k2settings->dst_width = width;
    return 0;
}

/**
 * Set output height in pixels
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_height(int height) {
    if (!initialized || height <= 0) {
        return -1;
    }
    
    k2settings->dst_userheight = height;
    k2settings->dst_userheight_units = UNITS_PIXELS;
    k2settings->dst_height = height;
    return 0;
}

/**
 * Set margin values (in inches) - Note: margin API is not currently exposed by k2pdfopt
 * This function is a placeholder for future implementation
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_margins(double left, double top, double right, double bottom) {
    if (!initialized) {
        return -1;
    }
    
    /* Margins are handled differently in the current k2pdfopt API  */
    /* For now, use autocrop or manual cropping settings */
    return -1; /* Not implemented */
}

/**
 * Process a PDF file
 * input_file: path to input PDF file
 * output_file: path to output PDF file
 * Returns 0 on success, non-zero on error
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_process_file(const char* input_file, const char* output_file) {
    K2PDFOPT_FILELIST_PROCESS k2listproc;
    
    if (!initialized || !input_file || !output_file) {
        return -1;
    }
    
    k2listproc.outname = NULL;
    k2listproc.bmp = NULL;
    k2listproc.filecount = 0;
    k2listproc.mode = K2PDFOPT_FILELIST_PROCESS_MODE_CONVERT_FILES;
    
    /* Set output filename */
    k2settings->dst_opname_format[0] = '\0';
    strncat(k2settings->dst_opname_format, output_file, 255);
    
    /* Process the file */
    k2pdfopt_proc_wildarg(k2settings, (char*)input_file, &k2listproc);
    
    if (k2listproc.outname != NULL) {
        free(k2listproc.outname);
    }
    
    return 0;
}

/**
 * Get number of pages in a PDF file
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_get_page_count(const char* filename) {
    if (!initialized || !filename) {
        return -1;
    }
    
    return k2file_get_num_pages((char*)filename);
}

/**
 * Set quality level (1-3, where 3 is highest quality)
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_quality(int quality) {
    if (!initialized || quality < 1 || quality > 3) {
        return -1;
    }
    
    k2settings->jpeg_quality = 50 + (quality - 1) * 25;
    return 0;
}

/**
 * Enable or disable OCR
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_ocr(int enable) {
    if (!initialized) {
        return -1;
    }
    
#ifdef HAVE_TESSERACT_LIB
    if (enable) {
        strcpy(k2settings->dst_ocr, "t");
    } else {
        k2settings->dst_ocr[0] = '\0';
    }
    return 0;
#else
    return -1; /* OCR not available */
#endif
}

/**
 * Set page range to process
 * Example: "1-10", "1,3,5", "1-10,15-20"
 */
EMSCRIPTEN_KEEPALIVE
int k2pdfopt_wasm_set_page_range(const char* range) {
    if (!initialized || !range) {
        return -1;
    }
    
    strncpy(k2settings->pagelist, range, 1023);
    k2settings->pagelist[1023] = '\0';
    return 0;
}
