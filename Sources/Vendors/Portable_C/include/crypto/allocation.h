/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once

#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static inline
void pp_assert(bool condition) {
    assert(condition);
}

static inline
void *_Nonnull pp_alloc_crypto(size_t size) {
    void *memory = calloc(1, size);
    if (!memory) {
        fputs("pp_alloc_crypto: malloc() call failed", stderr);
        abort();
    }
    return memory;
}

/// - Parameters:
///   - size: The base number of bytes.
///   - overhead: The extra number of bytes.
/// - Returns: The number of bytes to store a crypto buffer safely.
static inline
size_t pp_alloc_crypto_capacity(size_t size, size_t overhead) {

#define MAX_BLOCK_SIZE 16  // AES only, block is 128-bit

    // encryption, byte-alignment, overhead (e.g. IV, digest)
    return 2 * size + MAX_BLOCK_SIZE + overhead;
}

static inline
void pp_zero(void *_Nonnull ptr, size_t count) {
#ifdef bzero
    bzero(ptr, count);
#else
    memset(ptr, 0, count);
#endif
}

static inline
char *_Nonnull pp_dup(const char *_Nonnull str) {
#ifdef _WIN32
    char *ptr = _strdup(str);
#else
    char *ptr = strdup(str);
#endif
    if (!ptr) {
        fputs("pp_dup: strdup() call failed", stderr);
        abort();
    }
    return ptr;
}
