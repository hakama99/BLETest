//
//  CryptoAction.h
//  FireBEE
//
//  Created by Gary Shih on 2020/5/19.
//  Copyright © 2020 Gary Shih. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CryptoAction : NSObject

+(BOOL)getRandPro:(uint8_t *)prand Len:(int)len;

//prand  16字节随机数
//presult  16字节
+(BOOL)encryptPair:(NSString *)uName Pas:(NSString *)uPas Prand:(uint8_t *)prand PResult:(uint8_t *)presult;

+(BOOL)getSectionKey:(NSString *)uName Pas:(NSString *)uPas Prandm:(uint8_t *)prandm Prands:(uint8_t *)prands PResult:(uint8_t *)presult;

+(BOOL)encryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len;

+(BOOL)decryptionPpacket:(uint8_t *)key Iv:(uint8_t *)iv Mic:(uint8_t *)mic MicLen:(int)mic_len Ps:(uint8_t *)ps Len:(int)len;

+(BOOL)getNetworkInfo:(uint8_t *)pcmd Opcode:(int)opcode Str:(NSString *)str Psk:(uint8_t *)psk;
+(BOOL)getNetworkInfoByte:(uint8_t *)pcmd Opcode:(int)opcode Str:(uint8_t *)str Psk:(uint8_t *)psk;

@end

NS_ASSUME_NONNULL_END
