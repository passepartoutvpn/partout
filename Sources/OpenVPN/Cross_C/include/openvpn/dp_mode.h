/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#pragma once

#include <stdbool.h>
#include <stdint.h>
#include "crypto/crypto.h"
#include "openvpn/comp.h"
#include "openvpn/dp_framing.h"

// MARK: Outbound

// assemble -> encrypt
typedef struct {
    void *_Nonnull mode;
    uint32_t packet_id;
    zeroing_data_t *_Nonnull dst;
    const uint8_t *_Nonnull src;
    size_t src_len;
} dp_mode_assemble_ctx;

// encrypt -> SEND
typedef struct {
    uint8_t key;
    uint32_t packet_id;
    zeroing_data_t *_Nonnull dst;
    const uint8_t *_Nonnull src;
    size_t src_len;
    dp_error_t *_Nullable error;
} dp_mode_encrypt_ctx;

typedef size_t (*dp_mode_assemble_fn)(void *_Nonnull mode);
typedef size_t (*dp_mode_encrypt_fn)(void *_Nonnull mode);

// MARK: - Inbound

// RECEIVE -> decrypt
typedef struct {
    zeroing_data_t *_Nonnull dst;
    uint32_t *_Nonnull dst_packet_id;
    const uint8_t *_Nonnull src;
    size_t src_len;
    dp_error_t *_Nullable error;
} dp_mode_decrypt_ctx;

// decrypt -> parse
typedef struct {
    zeroing_data_t *_Nonnull dst;
    uint8_t *_Nonnull dst_header;
    uint8_t *_Nonnull src; // allow parse in place
    size_t src_len;
    dp_error_t *_Nullable error;
} dp_mode_parse_ctx;

typedef size_t (*dp_mode_decrypt_fn)(void *_Nonnull mode);
typedef size_t (*dp_mode_parse_fn)(void *_Nonnull mode);

// MARK: - Mode

/*
 A data path mode does the following:

 - Outbound
    - Assembles packet into payload
    - Encrypts payload
    - Sends to network
 - Inbound
    - Receives from network
    - Decrypts payload
    - Parses packet from payload

 The way packets are encrypted and decrypted is delegated to
 the crypto_*_t types in the CryptoOpenSSL target. On the other
 hand, the way payloads are assembled and parsed depends on
 two factors:

 - The encryption mode (AD or HMAC, where AD = associated data)
 - The compression framing (see compression_framing_t)

 Only AEAD (AD) and CBC (HMAC) algorithms are supported for
 data transfer at this time.
 */

#include "openvpn/packet.h"

typedef struct {
    dp_framing_assemble_fn _Nullable framing_assemble;
    dp_mode_assemble_fn _Nonnull assemble;
    crypto_encrypt_fn _Nonnull raw_encrypt;
    dp_mode_encrypt_fn _Nonnull encrypt;
} dp_mode_encrypter_t;

typedef struct {
    dp_framing_parse_fn _Nullable framing_parse;
    dp_mode_parse_fn _Nonnull parse;
    crypto_decrypt_fn _Nonnull raw_decrypt;
    dp_mode_decrypt_fn _Nonnull decrypt;
} dp_mode_decrypter_t;

typedef struct {
    compression_framing_t comp_f;
    uint32_t peer_id;
    uint16_t mss_val;
} dp_mode_options_t;

typedef struct {
    void *_Nonnull crypto;
    crypto_free_fn _Nonnull crypto_free;
    dp_mode_encrypter_t enc;
    dp_mode_decrypter_t dec;
    dp_mode_options_t opt;

    dp_mode_assemble_ctx assemble_ctx;
    dp_mode_encrypt_ctx enc_ctx;
    dp_mode_decrypt_ctx dec_ctx;
    dp_mode_parse_ctx parse_ctx;
} dp_mode_t;

// "crypto" is owned and released on free

dp_mode_t *_Nonnull dp_mode_create_opt(crypto_ctx _Nonnull crypto,
                                       crypto_free_fn _Nonnull crypto_free,
                                       const dp_mode_encrypter_t *_Nonnull enc,
                                       const dp_mode_decrypter_t *_Nonnull dec,
                                       const dp_mode_options_t *_Nullable opt);

static inline
dp_mode_t *_Nonnull dp_mode_create(crypto_ctx _Nonnull crypto,
                                   crypto_free_fn _Nonnull crypto_free,
                                   const dp_mode_encrypter_t *_Nonnull enc,
                                   const dp_mode_decrypter_t *_Nonnull dec) {
    return dp_mode_create_opt(crypto, crypto_free, enc, dec, NULL);
}

void dp_mode_free(dp_mode_t * _Nonnull);

static inline
uint32_t dp_mode_peer_id(dp_mode_t *_Nonnull mode) {
    return mode->opt.peer_id;
}

static inline
void dp_mode_set_peer_id(dp_mode_t *_Nonnull mode, uint32_t peer_id) {
    mode->opt.peer_id = peer_id_masked(peer_id);
}

static inline
compression_framing_t dp_mode_framing(const dp_mode_t *_Nonnull mode) {
    return mode->opt.comp_f;
}

// MARK: - Encryption

//
// AD = assemble_capacity(len)
// HMAC = assemble_capacity(len) + sizeof(uint32_t)
//
static inline
size_t dp_mode_assemble_capacity(const dp_mode_t *_Nonnull mode, size_t len) {
    (void)mode;
    return dp_framing_assemble_capacity(len) + sizeof(uint32_t);
}

//
// AD = PacketOpcodeLength + PacketPeerIdLength + meta.encryption_capacity(len)
// HMAC = PacketOpcodeLength + meta.encryption_capacity(len)
//
static inline
size_t dp_mode_encrypt_capacity(const dp_mode_t *_Nonnull mode, size_t len) {
    const crypto_ctx ctx = mode->crypto;
    const size_t max_prefix_len = PacketOpcodeLength + PacketPeerIdLength;
    const size_t enc_len = crypto_encryption_capacity(ctx, len);
    return max_prefix_len + enc_len;
}

static inline
size_t dp_mode_assemble_and_encrypt_capacity(const dp_mode_t *_Nonnull mode, size_t len) {
    return dp_mode_encrypt_capacity(mode, dp_mode_assemble_capacity(mode, len));
}

size_t dp_mode_assemble(dp_mode_t *_Nonnull mode,
                        uint32_t packet_id,
                        zeroing_data_t *_Nonnull dst,
                        const uint8_t *_Nonnull src,
                        size_t src_len);

size_t dp_mode_encrypt(dp_mode_t *_Nonnull mode,
                       uint8_t key,
                       uint32_t packet_id,
                       zeroing_data_t *_Nonnull dst,
                       const uint8_t *_Nonnull src,
                       size_t src_len,
                       dp_error_t *_Nullable error);

static inline
zeroing_data_t *_Nullable dp_mode_assemble_and_encrypt(dp_mode_t *_Nonnull mode,
                                                       uint8_t key,
                                                       uint32_t packet_id,
                                                       zeroing_data_t *_Nonnull buf,
                                                       const uint8_t *_Nonnull src,
                                                       size_t src_len,
                                                       dp_error_t *_Nullable error) {

    pp_assert(buf->length >= dp_mode_assemble_and_encrypt_capacity(mode, src_len));
    const size_t asm_len = dp_mode_assemble(mode, packet_id, buf,
                                            src, src_len);
    if (!asm_len) {
        return NULL;
    }
    zeroing_data_t *dst = zd_create(dp_mode_encrypt_capacity(mode, asm_len));
    const size_t dst_len = dp_mode_encrypt(mode, key, packet_id, dst,
                                           buf->bytes, asm_len, error);
    if (!dst_len) {
        zd_free(dst);
        return NULL;
    }
    zd_resize(dst, dst_len);
    return dst;
}

// MARK: - Decryption

size_t dp_mode_decrypt(dp_mode_t *_Nonnull mode,
                       zeroing_data_t *_Nonnull dst,
                       uint32_t *_Nonnull dst_packet_id,
                       const uint8_t *_Nonnull src,
                       size_t src_len,
                       dp_error_t *_Nullable error);

size_t dp_mode_parse(dp_mode_t *_Nonnull mode,
                     zeroing_data_t *_Nonnull dst,
                     uint8_t *_Nonnull dst_header,
                     uint8_t *_Nonnull src,
                     size_t src_len,
                     dp_error_t *_Nullable error);

static inline
zeroing_data_t *_Nullable dp_mode_decrypt_and_parse(dp_mode_t *_Nonnull mode,
                                                    zeroing_data_t *_Nonnull buf,
                                                    uint32_t *_Nonnull dst_packet_id,
                                                    uint8_t *_Nonnull dst_header,
                                                    bool *_Nonnull dst_keep_alive,
                                                    const uint8_t *_Nonnull src,
                                                    size_t src_len,
                                                    dp_error_t *_Nullable error) {

    pp_assert(buf->length >= src_len);
    const size_t dec_len = dp_mode_decrypt(mode, buf, dst_packet_id,
                                           src, src_len, error);
    if (!dec_len) {
        return NULL;
    }
    zeroing_data_t *dst = zd_create(dec_len);
    const size_t dst_len = dp_mode_parse(mode, dst, dst_header,
                                         buf->bytes, dec_len, error);
    if (!dst_len) {
        zd_free(dst);
        return NULL;
    }
    zd_resize(dst, dst_len);
    pp_assert(dst->length == dst_len);
    if (packet_is_ping(dst->bytes, dst->length)) {
        *dst_keep_alive = true;
    }
    return dst;
}
