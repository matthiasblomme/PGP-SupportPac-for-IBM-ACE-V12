# PGP Keytool Command Reference

## Important Notes

The pgpKeytool utility uses **operation names** as the first parameter after `java pgpkeytool`.

### Prerequisites

Before running pgpKeytool commands, you must set the CLASSPATH in an ACE Command Console:

```cmd
REM Open ACE Command Console
"C:\Program Files\IBM\ACE\13.0.6.0\ace.cmd"

REM Set CLASSPATH
SET CLASSPATH=%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar;%CLASSPATH%
```

## Supported Operations

```
generatePGPKeyPair:             Generate PGP key pair.
changePrivateKeyPassphrase:     Change passphrase for specified private key.
encrypt:                        PGP Encryption.
signAndEncrypt:                 PGP Encryption with Signature.
decrypt:                        PGP Decryption with Signature validation.
importPrivateKey:               Import specified Private key into Private key Repository file.
importPublicKey:                Import specified Public key into Public key Repository file.
exportPrivateKey:               Export specified Private key from Private key Repository file into separate Private key file.
exportPublicKey:                Export specified Public key from Public key Repository file into separate Public key file.
deletePrivateKey:               Delete specified Private key from Private key Repository file.
deletePublicKey:                Delete specified Public key from Public key Repository file.
listPrivateKeys:                List all Private keys in Private key Repository file.
listPublicKeys:                 List all Public keys in Public key Repository file.
```

---

## Command Examples

### 1. Generate PGP Key Pair

**Syntax:**
```cmd
java pgpkeytool generatePGPKeyPair -sa SignatureAlgorithm -pa PublicKeyAlgorithm -i identity -a asciiArmor -k[r|d|e] keysize -c cipher -s privateKeyFile -o publicKeyFile
```

**Example (with all options):**
```cmd
java pgpkeytool generatePGPKeyPair ^
  -sa RSA ^
  -pa RSA ^
  -i "Sender <sender@testpgp.com>" ^
  -a true ^
  -kr 2048 ^
  -c AES_256 ^
  -s C:\temp\pgp\keys\sender-private.asc ^
  -o C:\temp\pgp\keys\sender-public.asc
```

**Example (with defaults):**
```cmd
java pgpkeytool generatePGPKeyPair ^
  -i "Sender <sender@testpgp.com>" ^
  -s C:\temp\pgp\keys\sender-private.asc ^
  -o C:\temp\pgp\keys\sender-public.asc
```

**Parameters:**
- `-sa` SignatureAlgorithm (Optional): RSA, DSA. Default: RSA
- `-pa` PublicKeyAlgorithm (Optional): RSA, ELG. Default: RSA
- `-i` identity (Required): Key Identity (Key User Id) e.g. "IBM <ibm-pgp-keys@in.ibm.com>"
- `-a` asciiArmor (Optional): ASCII encoding [true|false]. Default: true
- `-kr` RSA Key Size (Optional): Default: 1024 bit
- `-kd` DSA Key Size (Optional): Default: 1024 bit
- `-ke` EL GAMAL Key Size (Optional): Default: 1024 bit
- `-c` cipher (Optional): IDEA, TRIPLE_DES, CAST5, BLOWFISH, DES, AES_128, AES_192, AES_256, TWOFISH. Default: CAST5
- `-s` privateKeyFile (Required): Private Key File Name (Absolute path)
- `-o` publicKeyFile (Required): Public Key File Name (Absolute path)

---

### 2. Import Private Key

**Syntax:**
```cmd
java pgpkeytool importPrivateKey -sr privateKeyRepositoryFile -i asciiArmor -sf privateKeyFile
```

**Example:**
```cmd
java pgpkeytool importPrivateKey ^
  -sr C:\temp\pgp\keys\private-repository.pgp ^
  -i true ^
  -sf C:\temp\pgp\keys\sender-private.asc
```

**Parameters:**
- `-sr` privateKeyRepositoryFile (Required): PrivateKey Repository File (Absolute Path)
- `-i` asciiArmor (Optional): Whether Key file is Ascii armored [true|false]. Default: true
- `-sf` privateKeyFile (Required): PrivateKey File (Absolute Path)

---

### 3. Import Public Key

**Syntax:**
```cmd
java pgpkeytool importPublicKey -pr publicKeyRepositoryFile -i asciiArmor -pf publicKeyFile
```

**Example:**
```cmd
java pgpkeytool importPublicKey ^
  -pr C:\temp\pgp\keys\public-repository.pgp ^
  -i true ^
  -pf C:\temp\pgp\keys\receiver-public.asc
```

**Parameters:**
- `-pr` publicKeyRepositoryFile (Required): PublicKey Repository File (Absolute Path)
- `-i` asciiArmor (Optional): Whether Key file is Ascii armored [true|false]. Default: true
- `-pf` publicKeyFile (Required): PublicKey File (Absolute Path)

---

### 4. Export Private Key

**Syntax:**
```cmd
java pgpkeytool exportPrivateKey -sr privateKeyRepositoryFile -su privateKeyUserId -i asciiArmor -sf privateKeyFile
```

**Example:**
```cmd
java pgpkeytool exportPrivateKey ^
  -sr C:\temp\pgp\keys\private-repository.pgp ^
  -su "Sender <sender@testpgp.com>" ^
  -i true ^
  -sf C:\temp\pgp\keys\sender-private-exported.asc
```

**Parameters:**
- `-sr` privateKeyRepositoryFile (Required): PrivateKey Repository File (Absolute Path)
- `-su` privateKeyUserId (Required): PrivateKey User Id
- `-i` asciiArmor (Optional): Whether Key file is Ascii armored [true|false]. Default: true
- `-sf` privateKeyFile (Required): PrivateKey File (Absolute Path)

---

### 5. Export Public Key

**Syntax:**
```cmd
java pgpkeytool exportPublicKey -pr publicKeyRepositoryFile -pu publicKeyUserId -i asciiArmor -pf publicKeyFile
```

**Example:**
```cmd
java pgpkeytool exportPublicKey ^
  -pr C:\temp\pgp\keys\public-repository.pgp ^
  -pu "Receiver <receiver@testpgp.com>" ^
  -i true ^
  -pf C:\temp\pgp\keys\receiver-public-exported.asc
```

**Parameters:**
- `-pr` publicKeyRepositoryFile (Required): PublicKey Repository File (Absolute Path)
- `-pu` publicKeyUserId (Required): PublicKey User Id
- `-i` asciiArmor (Optional): Whether Key file is Ascii armored [true|false]. Default: true
- `-pf` publicKeyFile (Required): PublicKey File (Absolute Path)

---

### 6. List Private Keys

**Syntax:**
```cmd
java pgpkeytool listPrivateKeys -sr privateKeyRepositoryFile
```

**Example:**
```cmd
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\private-repository.pgp
```

**Parameters:**
- `-sr` privateKeyRepositoryFile (Required): PrivateKey Repository File (Absolute Path)

---

### 7. List Public Keys

**Syntax:**
```cmd
java pgpkeytool listPublicKeys -pr publicKeyRepositoryFile
```

**Example:**
```cmd
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\public-repository.pgp
```

**Parameters:**
- `-pr` publicKeyRepositoryFile (Required): PublicKey Repository File (Absolute Path)

---

### 8. Change Private Key Passphrase

**Syntax:**
```cmd
java pgpkeytool changePrivateKeyPassphrase -sr privateKeyRepositoryFile -su privateKeyUserId
```

**Example:**
```cmd
java pgpkeytool changePrivateKeyPassphrase ^
  -sr C:\temp\pgp\keys\private-repository.pgp ^
  -su "Sender <sender@testpgp.com>"
```

**Parameters:**
- `-sr` privateKeyRepositoryFile (Required): PrivateKey Repository File (Absolute Path)
- `-su` privateKeyUserId (Required): PrivateKey User Id

**Note:** The command will prompt for the old and new passphrases interactively.

---

### 9. Delete Private Key

**Syntax:**
```cmd
java pgpkeytool deletePrivateKey -sr privateKeyRepositoryFile -su privateKeyUserId
```

**Example:**
```cmd
java pgpkeytool deletePrivateKey ^
  -sr C:\temp\pgp\keys\private-repository.pgp ^
  -su "Sender <sender@testpgp.com>"
```

**Parameters:**
- `-sr` privateKeyRepositoryFile (Required): PrivateKey Repository File (Absolute Path)
- `-su` privateKeyUserId (Required): PrivateKey User Id

---

### 10. Delete Public Key

**Syntax:**
```cmd
java pgpkeytool deletePublicKey -pr publicKeyRepositoryFile -pu publicKeyUserId
```

**Example:**
```cmd
java pgpkeytool deletePublicKey ^
  -pr C:\temp\pgp\keys\public-repository.pgp ^
  -pu "Receiver <receiver@testpgp.com>"
```

**Parameters:**
- `-pr` publicKeyRepositoryFile (Required): PublicKey Repository File (Absolute Path)
- `-pu` publicKeyUserId (Required): PublicKey User Id

---

## Getting Help

For detailed help on any operation:

```cmd
java pgpkeytool [operation] -help
```

Examples:
```cmd
java pgpkeytool generatePGPKeyPair -help
java pgpkeytool listPrivateKeys -help
java pgpkeytool exportPublicKey -help
java pgpkeytool importPublicKey -help
```

---

## Important Notes

1. **Operation names are case-sensitive** (use exact names as shown)
2. **Always run from ACE Command Console** with CLASSPATH set
3. **Use `-help` flag** to see exact parameters for each operation
4. **Repository files are created automatically** when importing the first key
5. **User IDs must match exactly** when exporting or deleting keys (including email format)
6. **ASCII armor is the default** for all key files (human-readable format)

---

## Common Workflow

### Typical Setup for Sender/Receiver Scenario:

1. **Generate Sender Key Pair:**
   ```cmd
   java pgpkeytool generatePGPKeyPair -i "Sender <sender@testpgp.com>" -s C:\temp\pgp\keys\sender-private.asc -o C:\temp\pgp\keys\sender-public.asc
   ```

2. **Generate Receiver Key Pair:**
   ```cmd
   java pgpkeytool generatePGPKeyPair -i "Receiver <receiver@testpgp.com>" -s C:\temp\pgp\keys\receiver-private.asc -o C:\temp\pgp\keys\receiver-public.asc
   ```

3. **Import Sender Private Key into Repository:**
   ```cmd
   java pgpkeytool importPrivateKey -sr C:\temp\pgp\keys\sender-private-repository.pgp -sf C:\temp\pgp\keys\sender-private.asc
   ```

4. **Import Receiver Public Key into Sender's Public Repository:**
   ```cmd
   java pgpkeytool importPublicKey -pr C:\temp\pgp\keys\sender-public-repository.pgp -pf C:\temp\pgp\keys\receiver-public.asc
   ```

5. **Import Receiver Private Key into Repository:**
   ```cmd
   java pgpkeytool importPrivateKey -sr C:\temp\pgp\keys\receiver-private-repository.pgp -sf C:\temp\pgp\keys\receiver-private.asc
   ```

6. **Import Sender Public Key into Receiver's Public Repository:**
   ```cmd
   java pgpkeytool importPublicKey -pr C:\temp\pgp\keys\receiver-public-repository.pgp -pf C:\temp\pgp\keys\sender-public.asc
   ```

7. **Verify Keys:**
   ```cmd
   java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\sender-private-repository.pgp
   java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\sender-public-repository.pgp
   java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\receiver-private-repository.pgp
   java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\receiver-public-repository.pgp
   ```

---

## References

- Run `java pgpkeytool` (without parameters) to see the list of supported operations
- Run `java pgpkeytool [operation] -help` for operation-specific help
- All commands verified against IBM ACE 13.0.6.0