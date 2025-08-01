/*
 * SPDX-FileCopyrightText: 2025 Davide De Rosa
 *
 * SPDX-License-Identifier: GPL-3.0
 */

#include "crypto/allocation.h"
#include "crypto/tls.h"

tls_channel_options *_Nonnull tls_channel_options_create(int sec_level,
                                                         size_t buf_len,
                                                         bool eku,
                                                         bool san_host,
                                                         const char *_Nonnull ca_path,
                                                         const char *_Nullable cert_pem,
                                                         const char *_Nullable key_pem,
                                                         const char *_Nullable hostname,
                                                         void (*_Nonnull on_verify_failure)()) {

    pp_assert(ca_path && on_verify_failure);

    tls_channel_options *opt = pp_alloc_crypto(sizeof(tls_channel_options));
    opt->sec_level = sec_level;
    opt->buf_len = buf_len;
    opt->eku = eku;
    opt->san_host = san_host;
    opt->ca_path = pp_dup(ca_path);
    opt->cert_pem = cert_pem ? pp_dup(cert_pem) : NULL;
    opt->key_pem = key_pem ? pp_dup(key_pem) : NULL;
    opt->hostname = hostname ? pp_dup(hostname) : NULL;
    opt->on_verify_failure = on_verify_failure;
    return opt;
}

void tls_channel_options_free(tls_channel_options *_Nonnull opt) {
    free((char *)opt->ca_path);
    free((char *)opt->cert_pem);
    free((char *)opt->key_pem);
    free((char *)opt->hostname);
    free(opt);
}
