//
//  endian.h
//  Partout
//
//  Created by Davide De Rosa on 6/23/25.
//  Copyright (c) 2025 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Partout.
//
//  Partout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Partout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Partout.  If not, see <http://www.gnu.org/licenses/>.
//

#pragma once

#include <stdint.h>

#ifdef __APPLE__

#include <CoreFoundation/CoreFoundation.h>

static inline
uint16_t endian_ntohs(uint16_t num) {
    return CFSwapInt16BigToHost(num);
}

static inline
uint16_t endian_htons(uint16_t num) {
    return CFSwapInt16HostToBig(num);
}

static inline
uint32_t endian_ntohl(uint32_t num) {
    return CFSwapInt32BigToHost(num);
}

static inline
uint32_t endian_htonl(uint32_t num) {
    return CFSwapInt32HostToBig(num);
}

#else

#ifdef _WIN32
#include <WinSock2.h>
#else
#include <arpa/inet.h>
#endif

static inline
uint16_t endian_ntohs(uint16_t num) {
    return ntohs(num);
}

static inline
uint16_t endian_htons(uint16_t num) {
    return htons(num);
}

static inline
uint32_t endian_ntohl(uint32_t num) {
    return ntohl(num);
}

static inline
uint32_t endian_htonl(uint32_t num) {
    return htonl(num);
}

#endif
