//
//  CryptoUtil.h
//  FireBEE
//
//  Created by Gary Shih on 2020/5/19.
//  Copyright © 2020 Gary Shih. All rights reserved.
//

#ifndef CryptoUtil_h
#define CryptoUtil_h

#include <stdio.h>

void _rijndaelSetKey (unsigned char *k);
void _rijndaelEncrypt(unsigned char *a);
void _rijndaelDecrypt (unsigned char *a);

void aes_att_encryption (unsigned char *key, unsigned char *plaintext, unsigned char *result);
void aes_att_decryption (unsigned char *key, unsigned char *plaintext, unsigned char *result);


int        aes_att_er (unsigned char *pNetworkName, unsigned char *pPassword, unsigned char *prand, unsigned char *presult);

#endif /* CryptoUtil_h */
