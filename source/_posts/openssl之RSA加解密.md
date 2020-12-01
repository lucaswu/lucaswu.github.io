---
title: openssl之RSA加解密
date: 2020-12-01 10:42:04
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;OpenSSL不多介绍，RSA也不多介绍，这里就贴出公钥加密，私钥解密的分段加解密代码。    
<!--more-->     
&nbsp;&nbsp;&nbsp;&nbsp; 特别说明的一点是RSA公钥和私钥的长度为1024，所以最对可以加密1024/8-11=117字节长度。代码如下：
```C
#include <openssl/pem.h>
#include <openssl/ssl.h>
#include <openssl/rsa.h>
#include <openssl/evp.h>
#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/buffer.h>
#include <stdio.h>

const int PADDING = RSA_PKCS1_PADDING;
RSA *createRSA(unsigned char *key, int public_token)
{
	RSA *rsa = NULL;
	BIO *keybio;
	keybio = BIO_new_mem_buf(key, -1);
	if (keybio == NULL)
	{
		printf("Failed to create key BIO");
		return 0;
	}
	if (public_token)
	{
		rsa = PEM_read_bio_RSA_PUBKEY(keybio, &rsa, NULL, NULL);
	}
	else
	{
		rsa = PEM_read_bio_RSAPrivateKey(keybio, &rsa, NULL, NULL);
	}
	if (rsa == NULL)
	{
		printf("Failed to create RSA");
	}

	return rsa;
}

int public_key_encrypt(unsigned char *data, int data_len, unsigned char *key, unsigned char *encrypted)
{
	RSA *rsa = createRSA(key, 1);
	if (NULL == rsa)
	{
		return -1;
	}
	size_t res = RSA_size(rsa);
	int block_len = res - 11;

	int pos = 0;



	unsigned char* temp = (unsigned char*)malloc(res+1);
	if (temp == NULL) {
		return -1;
	}

	unsigned char* outData = (unsigned char*)malloc(res+1);
	if (outData == NULL) {
		return -1;
	}

	int totalSize = 0; 
	while (pos < data_len) {
		memset(temp, 0, res+1);
		int size = min(block_len, data_len - pos);
		memcpy(temp, data + pos, size);
		
		memset(outData, 0, res+1);
		int result = RSA_public_encrypt(strlen(temp), temp, outData, rsa, PADDING);
		printf("%s\n",temp);
		if (result >  0) {
			memcpy(encrypted + totalSize, outData, result);
			pos += block_len;

			totalSize += result;
		}
		else {

			free(temp);
			free(outData);
			return -1;
		}
		
	}

	free(temp);
	free(outData);
	return totalSize;
}

int private_key_decrypt(unsigned char *enc_data, int data_len, unsigned char *key, unsigned char *decrypted)
{
	RSA *rsa = createRSA(key, 0);
	if (NULL == rsa)
	{
		return -1;
	}
	size_t res = RSA_size(rsa);

	int pos = 0;
	int i = 0;
	int totalSize = 0;

	unsigned char* temp = (unsigned char*)malloc(res + 1);
	if (temp == NULL) {
		return -1;
	}

	unsigned char* outData = (unsigned char*)malloc(res + 1);
	if (outData == NULL) {
		return -1;
	}
	while (pos < data_len) {
		memset(temp, 0, res + 1);
		int size = min(res, data_len - pos);
		memcpy(temp, enc_data + pos, size);

		memset(outData, 0, res + 1);
		int result = RSA_private_decrypt(strlen(temp), temp, outData, rsa, PADDING);

		if (result > 0) {

			memcpy(decrypted + totalSize, outData, result);
			pos += res;

			totalSize += result;

			printf("%s\n", decrypted);
		}
		else {
			return -1;
		}

	

	}
	
	return totalSize;
}

void ras_test()
{
	unsigned char plainText[] = "[oh-my-zsh] For safety, we will not load completions from these directories until[oh-my-zsh] you fix their permissions and ownership and restart zsh.oh-my-zsh] See the above list for directories with group or other writability.";

	unsigned char publicKey[] = "-----BEGIN PUBLIC KEY-----\n"
		"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrPgCMJW17JN2DW7tZFk/FB6pU\n"
		"pLvLOo6G/EuND8XZptffXbyiY2VscMRhP+kKVeaLO9HuEYR3Zl78x8oR6prytstc\n"
		"/MueersWDxh4iGSHsZXGxA41hXrXLRElrSTRc43ea18o0zMxZoVZiR2JFt7QcgM+\n"
		"T6eOrvj59MhXv9O46QIDAQAB\n"
		"-----END PUBLIC KEY-----\n";

	unsigned char privateKey[] = "-----BEGIN RSA PRIVATE KEY-----\n"
		"MIICdgIBADANBgkqhkiG9w0BAQEFAASCAmAwggJcAgEAAoGBAKs+AIwlbXsk3YNb\n"
		"u1kWT8UHqlSku8s6job8S40Pxdmm199dvKJjZWxwxGE/6QpV5os70e4RhHdmXvzH\n"
		"yhHqmvK2y1z8y556uxYPGHiIZIexlcbEDjWFetctESWtJNFzjd5rXyjTMzFmhVmJ\n"
		"HYkW3tByAz5Pp46u+Pn0yFe/07jpAgMBAAECgYBj1YH8MtXhNVzveEuBZMCc3hsv\n"
		"vdq+YSU3DV/+nXN7sQmp77xJ8CjxT80t5VS38dy2z+lUImJYOhamyNPGHkC2y84V\n"
		"7i5+e6ScQve1gnwHqRKGBjtSCaYOqm9rTDECCTT1oMU26sfYznWlJqMrkJp1jWn7\n"
		"aAwr+3FcX2XhD74ZAQJBAN34Y6fmHLRPv21MsdgGqUjKgyFvJfLUmtFFgb6sLEWc\n"
		"k22J3BAFAcNCTLYHFZwMhL/nwaw9/7rIUJD+lcl6n3cCQQDFfrN14qKC3GJfoBZ8\n"
		"k9S6F7Ss514DDPzIuenbafhoUjZDVcjLw9EmYZQjpfsQ3WdNICUKRrDHZay1Pz+s\n"
		"YkKfAkB+OKfaquS5t/t/2LPsxuTuipIEqiKnMjSTOfYsidVnBEFlcZZc2awF76aV\n"
		"f/PO1+OJCO2910ebXBtMSCi++GbDAkEAmc7zNPwsVH4OnyquWJdJNSUBMSd/sCCN\n"
		"PkaMOrVtINHmMMq+dvMqEBoupRS/U4Ma0JYYQsiLJL+qof2AOWDNQQJAcquLGHLT\n"
		"eGDDLluHo+kkIGwZi4aK/fDoylZ0NCEtYyMtShQ3JmllST9kmb9NJX2gMsejsirc\n"
		"H6ObxqZPbka6UA==\n"
		"-----END RSA PRIVATE KEY-----\n";

	unsigned char encrypted_str[1024];
	unsigned char decrypted_str[1024];


	memset(encrypted_str, '\0', sizeof(encrypted_str));
	memset(decrypted_str, '\0', sizeof(decrypted_str));

	size_t len = strlen((const char *)plainText);
	printf("Original string length =%d\n\n", len);

	// 公钥加密
	int encrypted_length = public_key_encrypt(plainText, len, publicKey, encrypted_str);
	if (-1 == encrypted_length)
	{
		printf("Private Encrypt failed\n");
		exit(0);
	}
	encrypted_str[encrypted_length] = '\0';



	// 私钥解密
	int decrypted_length = private_key_decrypt(encrypted_str, encrypted_length, privateKey, decrypted_str);
	if (-1 == decrypted_length)
	{
		printf("Public Decrypt failed\n");
		exit(0);
	}

	printf("Decrypted Text =%s\n\n", decrypted_str);
	printf("Decrypted Length =%d\n", decrypted_length);
}
```    
代码[下载](https://github.com/lucaswu/decrypt_encrypt)
