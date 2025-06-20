//
//  DataPath.h
//  Partout
//
//  Created by Davide De Rosa on 3/2/17.
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
//  This file incorporates work covered by the following copyright and
//  permission notice:
//
//      Copyright (c) 2018-Present Private Internet Access
//
//      Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//      The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

@protocol DataPathEncrypter;
@protocol DataPathDecrypter;

#import "CompressionAlgorithm.h"
#import "CompressionFraming.h"
#import "DataPathCrypto.h"

NS_ASSUME_NONNULL_BEGIN

// send/receive should be mutually thread-safe

@interface DataPath : NSObject

@property (nonatomic, assign) uint32_t maxPacketId;

- (instancetype)initWithEncrypter:(id<DataPathEncrypter>)encrypter
                        decrypter:(id<DataPathDecrypter>)decrypter
                           peerId:(uint32_t)peerId // 24-bit, discard most significant byte
               compressionFraming:(CompressionFraming)compressionFraming
             compressionAlgorithm:(CompressionAlgorithm)compressionAlgorithm
                       maxPackets:(NSInteger)maxPackets
             usesReplayProtection:(BOOL)usesReplayProtection;

- (nullable NSArray<NSData *> *)encryptPackets:(NSArray<NSData *> *)packets key:(uint8_t)key error:(NSError **)error;
- (nullable NSArray<NSData *> *)decryptPackets:(NSArray<NSData *> *)packets keepAlive:(nullable bool *)keepAlive error:(NSError **)error;

// MARK: Testing

- (id<DataPathEncrypter>)encrypter;
- (id<DataPathDecrypter>)decrypter;
- (DataPathAssembleBlock)assemblePayloadBlock;
- (DataPathParseBlock)parsePayloadBlock;

@end

NS_ASSUME_NONNULL_END
