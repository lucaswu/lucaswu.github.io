---
title: wincrypt之RSA解密
date: 2020-12-01 11:07:54
tags:
---
&nbsp;&nbsp;&nbsp;&nbsp;项目中遇到一个问题，需要进行RSA解密。但是因为不想在SDK中集成OpenSSL的库，所以研究了下window下的wincrypt。    
<!--more-->    
 &nbsp;&nbsp;&nbsp;&nbsp;直接贴代码了，但需要说明的是：用openSSL公钥生成密文，wincrypt用私钥进行解密。明文长度可能超过RSA加密限制，会进行分段加密。
 ```C
#ifdef _WIN32
#include <Windows.h>
#include <wincrypt.h>

#pragma comment(lib,"crypt32.lib")
#endif


unsigned char* pri_key = "-----BEGIN RSA PRIVATE KEY-----\n"
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

#ifdef _WIN32

static BOOL rsa_init(HCRYPTPROV** hProv, HCRYPTKEY* hKey)
{
    DWORD dwBufferLen = 0, cbKeyBlob = 0, cbSignature = 0, i;
    LPBYTE pbBuffer = NULL, pbKeyBlob = NULL, pbSignature = NULL;
    if (!CryptStringToBinaryA(pri_key, 0, CRYPT_STRING_BASE64HEADER, NULL, &dwBufferLen, NULL, NULL))
    {
#if ENBALE_LOG
        printf("Failed to convert BASE64 private key. Error 0x%.8X\n", GetLastError());
#endif
        goto main_exit;
    }

    pbBuffer = (LPBYTE)LocalAlloc(0, dwBufferLen);
    if (pbBuffer == NULL) {
        goto main_exit;
    }
    if (!CryptStringToBinaryA(pri_key, 0, CRYPT_STRING_BASE64HEADER, pbBuffer, &dwBufferLen, NULL, NULL))
    {
#if ENBALE_LOG
        printf("Failed to convert BASE64 private key. Error 0x%.8X\n", GetLastError());
#endif
        goto main_exit;
    }

    if (!CryptDecodeObjectEx(X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, PKCS_RSA_PRIVATE_KEY, pbBuffer, dwBufferLen, 0, NULL, NULL, &cbKeyBlob))
    {
#if ENBALE_LOG
        printf("Failed to parse private key. Error 0x%.8X\n", GetLastError());
#endif
        goto main_exit;
    }

    pbKeyBlob = (LPBYTE)LocalAlloc(0, cbKeyBlob);
    if (pbKeyBlob == NULL) {
        goto main_exit;
    }
    if (!CryptDecodeObjectEx(X509_ASN_ENCODING | PKCS_7_ASN_ENCODING, PKCS_RSA_PRIVATE_KEY, pbBuffer, dwBufferLen, 0, NULL, pbKeyBlob, &cbKeyBlob))
    {
#if ENBALE_LOG
        printf("Failed to parse private key. Error 0x%.8X\n", GetLastError());
#endif
        goto main_exit;
    }


    if (!CryptAcquireContext(hProv, "BenTestKeyContainer", MS_ENHANCED_PROV, PROV_RSA_FULL, 0))
    {
        if (!CryptAcquireContext(hProv, "BenTestKeyContainer", MS_ENHANCED_PROV, PROV_RSA_FULL, CRYPT_NEWKEYSET))
        {
#if ENBALE_LOG
            printf("CryptAcquireContext failed with error 0x%.8X\n", GetLastError());
            goto main_exit;
#endif
        }

    }

    if (!CryptImportKey(*hProv, pbKeyBlob, cbKeyBlob, NULL, 0, hKey))
    {
#if ENBALE_LOG
        printf("CryptImportKey for private key failed with error 0x%.8X\n", GetLastError());
#endif
        goto main_exit;
    }

    if (pbBuffer) LocalFree(pbBuffer);
    if (pbKeyBlob) LocalFree(pbKeyBlob);

    return TRUE;

main_exit:
    if (pbBuffer) LocalFree(pbBuffer);
    if (pbKeyBlob) LocalFree(pbKeyBlob);

    return FALSE;

}

BOOL private_decrypt(const unsigned char* data, int data_len,
    const unsigned char* pri_key, int key_len,
    unsigned char** dst, int* dst_len)
{
    HCRYPTPROV hProv = NULL;

    HCRYPTKEY hKey = NULL;

    BOOL ret = rsa_init(&hProv, &hKey);
    if (!ret) {
        return ret;
    }

    DWORD dwBlockLen,dwDataLen = 4;
    if (!CryptGetKeyParam(hKey, KP_BLOCKLEN, (BYTE *)&dwBlockLen, &dwDataLen, 0))
    {  
        return FALSE;
    }

    dwBlockLen /= 8;

    unsigned char *temp = (unsigned char *)malloc((size_t)dwBlockLen + 1);
    if (temp == NULL)
    {
        LocalFree(base64Out);
        return FALSE;
    }

	for (int j = 0; j < base64OutLen; j += dwBlockLen){
        unsigned char *p = base64Out + j;
		int ilen = dwBlockLen;
		char* pTemp = p + ilen - 1;
		int itemp = 0;
		while (p < pTemp){
			itemp = *pTemp;
			*pTemp = *p;
			*p = itemp;
			pTemp--;
			p++;
		}
       
    }


    unsigned char* outputData = (unsigned char*)malloc(data_len);
    if (outputData == NULL) {
        return FALSE;
    }
    memset(outputData, 0, data_len);

    *dst = outputData;
    *dst_len = data_len;

    int blockSize = dwBlockLen;
    int pos = 0;

    while (pos < data_len) {
        memset(temp, 0, (size_t)dwBlockLen + 1);
		int size = min((int)dwBlockLen, data_len - pos);
        memcpy(temp, base64Out + pos, size);
        ret = CryptDecrypt(hKey, NULL, flag, 0, tempData, &size);
        if (ret > 0) {
            memcpy(outputData + pos, tempData, size);
            pos += blockSize;

            printf("%s\n", outputData);
        }
        else {

            printf("CryptDecrypt error!,%d\n", GetLastError());

            CryptDestroyKey(hKey);
            CryptReleaseContext(hProv, 0);

            return FALSE;
        }

    }

    printf("outputData=%s\n", outputData);

    CryptDestroyKey(hKey);
    CryptReleaseContext(hProv, 0);
    return TRUE;

}
#endif

int rsa_encrypt(const unsigned char* data, int data_len, unsigned char** dstData, int* dst_len)
{

    BOOL ret = private_decrypt(data, data_len, pri_key, strlen(pri_key), dstData, dst_len);

    return ret;
}
 
 ```
&nbsp;&nbsp;&nbsp;&nbsp;**特别强调**：因为OpenSSL加密后的密文与wincrypt的密文刚好反转了。所以OpenSSL生成的密文需要反转再送进去。    
代码[下载](https://github.com/lucaswu/decrypt_encrypt)