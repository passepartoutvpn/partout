//
//  CryptoCTR.h
//  Partout
//
//  Created by Davide De Rosa on 9/18/18.
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

#import <Foundation/Foundation.h>
#import "CryptoMacros.h"
#import "CryptoProtocols.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CryptoCTRError) {
    CryptoCTRErrorGeneric,
    CryptoCTRErrorHMAC
};

@interface CryptoCTR : NSObject <Encrypter, Decrypter>

- (nullable instancetype)initWithCipherName:(NSString *)cipherName
                                 digestName:(NSString *)digestName
                                  tagLength:(NSInteger)tagLength
                              payloadLength:(NSInteger)payloadLength
                                      error:(NSError **)error;

@property (nonatomic, copy) NSError * (^mappedError)(CryptoCTRError);

@end

NS_ASSUME_NONNULL_END
