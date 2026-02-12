# PGP SupportPac Test Setup Walkthrough for IBM ACE 13.0.6.0

## Document Overview

This document provides a complete step-by-step walkthrough for setting up and testing the PGP SupportPac on IBM App Connect Enterprise 13.0.6.0. It covers:
1. PGP key pair generation and repository setup
2. ACE flow configuration with policy projects
3. End-to-end encryption/decryption testing

**Target ACE Version**: 13.0.6.0
**Test Date**: 2026-02-12
**Status**: ✅ Testing Complete - All Tests Passed

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Part 1: PGP Key Pair Generation and Setup](#part-1-pgp-key-pair-generation-and-setup)
  - [1.1 Generate Key Pairs](#11-create-private-key-repository)
  - [1.2 Create Key Repositories](#12-create-key-repositories)
  - [1.3 Summary of Generated Keys and Repositories](#13-summary-of-generated-keys-and-repositories)
  - [1.4 Verify Key Repositories](#14-verify-key-repositories)
  - [1.5 Validate All Files](#15-validate-all-files)
- [Part 2: ACE Flow Setup and Configuration](#part-2-ace-flow-setup-and-configuration)
  - [2.1 Import Test Flows](#21-import-test-flows)
  - [2.2 Verify Policy Configuration](#22-verify-policy-configuration)
  - [2.3 Understand Encryptor Flow Properties](#23-understand-encryptor-flow-properties)
  - [2.4 Understand Decryptor Flow Properties](#24-understand-decryptor-flow-properties)
- [Part 3: Test Flow Execution](#part-3-test-flow-execution)
  - [3.1 Deploy Application and Policies](#31-deploy-application-and-policies)
  - [3.2 Test Encryption Flow](#32-test-encryption-flow)
  - [3.3 Test Decryption Flow](#33-test-decryption-flow)
  - [3.4 Verify Results](#34-verify-results)
- [Troubleshooting](#troubleshooting)
- [Appendix](#appendix)

## Quick Command Reference

For detailed command syntax and all available operations, see [PGPKEYTOOL-COMMANDS.md](PGPKEYTOOL-COMMANDS.md).

### Essential Commands Used in This Walkthrough

**Generate Key Pair:**
```cmd
java pgpkeytool generatePGPKeyPair -i "Name <email@domain.com>" -s C:\path\to\private.asc -o C:\path\to\public.asc
```

**Import Private Key into Repository:**
```cmd
java pgpkeytool importPrivateKey -sr C:\path\to\private-repository.pgp -i true -sf C:\path\to\private.asc
```

**Import Public Key into Repository:**
```cmd
java pgpkeytool importPublicKey -pr C:\path\to\public-repository.pgp -i true -pf C:\path\to\public.asc
```

**List Private Keys:**
```cmd
java pgpkeytool listPrivateKeys -sr C:\path\to\private-repository.pgp
```

**List Public Keys:**
```cmd
java pgpkeytool listPublicKeys -pr C:\path\to\public-repository.pgp
```

---

---

## Prerequisites

Before starting this walkthrough, ensure you have:

- ✅ IBM ACE 13.0.6.0 installed and configured
- ✅ PGP SupportPac installed (see [INSTALLATION.md](INSTALLATION.md))
- ✅ ACE Toolkit open and connected to your workspace
- ✅ ACE Command Console available
- ✅ Administrator privileges for file system operations
- ✅ Test directories created:
  - `C:\temp\pgp\` (or your preferred location)
  - `C:\temp\pgp\keys\` (for key repositories)
  - `C:\temp\pgp\input\` (for test files)
  - `C:\temp\pgp\output\` (for encrypted/decrypted files)

---

## Part 1: PGP Key Pair Generation and Setup

This section covers creating PGP key repositories and generating key pairs for both sender and receiver parties.

### 1.1 Generate Key Pairs

This section covers generating PGP key pairs for both sender and receiver parties.

#### Step 1: Open ACE Command Console

Open the actual ACE console, or open a generic CMD session and 

1. Navigate to your ACE installation directory
2. Run `ace.cmd` to open the ACE Command Console

```cmd
cd "C:\Program Files\IBM\ACE\13.0.6.0"
ace.cmd
```

![console](/.TEST-SETUP-WALKTHROUGH-ACE-13/image.png)

#### Step 2: Set CLASSPATH for pgpKeytool

Add the required JAR files to your CLASSPATH:

```cmd
SET CLASSPATH=%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar;%CLASSPATH%
```

![classpath](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-1.png)

#### Step 3: Create Key Storage Directories

Create the directories where keys will be stored:

```cmd
mkdir C:\temp\pgp\keys
mkdir C:\temp\pgp\input
mkdir C:\temp\pgp\output
```

**Note:** If directories already exist, you'll see "A subdirectory or file already exists" - this is normal and can be ignored.

![dirs](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-2.png)

#### Step 4: Generate Sender Key Pair

Generate a PGP key pair for the sender. This creates both a private key file and a public key file:

```cmd
java pgpkeytool generatePGPKeyPair ^
  -i "Sender <sender@testpgp.com>" ^
  -s C:\temp\pgp\keys\sender-private.asc ^
  -o C:\temp\pgp\keys\sender-public.asc
```


**Parameters explained:**
- `generatePGPKeyPair`: Operation to generate a new PGP key pair
- `-i`: Identity (Key User Id) - name and email in format "Name <email@domain.com>"
- `-s`: Private Key File Name (Absolute path) - where to save the private key
- `-o`: Public Key File Name (Absolute path) - where to save the public key

**Optional parameters (using defaults):**
- Signature Algorithm: RSA (default)
- Public Key Algorithm: RSA (default)
- Key Size: 1024 bit (default) - can specify `-kr 2048` for 2048-bit RSA key
- Cipher: CAST5 (default) - can specify `-c AES_256` for AES-256 encryption
- ASCII Armor: true (default) - creates human-readable .asc files

![sender](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-3.png)

#### Step 5: Generate Receiver Key Pair

Generate a PGP key pair for the receiver:

```cmd
java pgpkeytool generatePGPKeyPair ^
  -i "Receiver <receiver@testpgp.com>" ^
  -s C:\temp\pgp\keys\receiver-private.asc ^
  -o C:\temp\pgp\keys\receiver-public.asc
```


![receiver](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-4.png)

**Note:** You will be prompted to enter a passphrase for each private key. Remember these passphrases as they will be needed for decryption operations. I'll be using `passw0rd` as the PGP Passphrase.

---

### 1.2 Create Key Repositories

Now we need to import the generated keys into repository files that ACE can use.

#### Step 1: Import Sender Private Key into Repository

Import the sender's private key into a private key repository:

```cmd
java pgpkeytool importPrivateKey ^
  -sr C:\temp\pgp\keys\sender-private-repository.pgp ^
  -i true ^
  -sf C:\temp\pgp\keys\sender-private.asc
```

**Parameters explained:**
- `importPrivateKey`: Operation to import a private key into a repository
- `-sr`: Private Key Repository File (Absolute Path) - will be created if it doesn't exist
- `-i`: ASCII armor flag [true|false] - true for .asc files (default)
- `-sf`: Private Key File (Absolute Path) - the key file to import

![import sender private](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-5.png)

#### Step 2: Import Receiver Public Key into Sender's Public Repository

The sender needs the receiver's public key to encrypt messages:

```cmd
java pgpkeytool importPublicKey ^
  -pr C:\temp\pgp\keys\sender-public-repository.pgp ^
  -i true ^
  -pf C:\temp\pgp\keys\receiver-public.asc
```

**Parameters explained:**
- `importPublicKey`: Operation to import a public key into a repository
- `-pr`: Public Key Repository File (Absolute Path) - will be created if it doesn't exist
- `-i`: ASCII armor flag [true|false] - true for .asc files (default)
- `-pf`: Public Key File (Absolute Path) - the key file to import

![import receiver public](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-6.png)

#### Step 3: Import Receiver Private Key into Repository

Import the receiver's private key into a private key repository:

```cmd
java pgpkeytool importPrivateKey ^
  -sr C:\temp\pgp\keys\receiver-private-repository.pgp ^
  -i true ^
  -sf C:\temp\pgp\keys\receiver-private.asc
```

![import receiver private](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-7.png)
#### Step 4: Import Sender Public Key into Receiver's Public Repository

The receiver needs the sender's public key to verify signatures (if used):

```cmd
java pgpkeytool importPublicKey ^
  -pr C:\temp\pgp\keys\receiver-public-repository.pgp ^
  -i true ^
  -pf C:\temp\pgp\keys\sender-public.asc
```

![import sender public](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-8.png)

---

### 1.3 Summary of Generated Keys and Repositories

**Generated Key Files:**

| Party | Private Key File | Public Key File |
|-------|-----------------|-----------------|
| **Sender** | `sender-private.asc` | `sender-public.asc` |
| **Receiver** | `receiver-private.asc` | `receiver-public.asc` |

**Created Repository Files:**

| Party | Private Key Repository | Public Key Repository | Purpose |
|-------|----------------------|---------------------|---------|
| **Sender** | `sender-private-repository.pgp` | `sender-public-repository.pgp` | Encrypt messages for receiver |
| **Receiver** | `receiver-private-repository.pgp` | `receiver-public-repository.pgp` | Decrypt messages from sender |

**Key Relationships:**
- Sender uses **receiver's public key** (from `sender-public-repository.pgp`) to encrypt
- Receiver uses **receiver's private key** (from `receiver-private-repository.pgp`) to decrypt
- Sender uses **sender's private key** (from `sender-private-repository.pgp`) to sign
- Receiver uses **sender's public key** (from `receiver-public-repository.pgp`) to verify signature

---

### 1.4 Verify Key Repositories

Verify that the keys have been imported correctly into the repositories.

#### List Sender's Private Keys

```cmd
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\sender-private-repository.pgp
```

Expected output should show the sender's private key with user ID "Sender <sender@testpgp.com>".

![sender private key check](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-9.png)

#### List Sender's Public Keys

```cmd
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\sender-public-repository.pgp
```

Expected output should show the receiver's public key with user ID "Receiver <receiver@testpgp.com>".

![receivers public key check](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-10.png)

#### List Receiver's Private Keys

```cmd
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\receiver-private-repository.pgp
```

Expected output should show the receiver's private key with user ID "Receiver <receiver@testpgp.com>".

![receivers private key check](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-11.png)

#### List Receiver's Public Keys

```cmd
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\receiver-public-repository.pgp
```

Expected output should show the sender's public key with user ID "Sender <sender@testpgp.com>".

![receiver public key check](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-12.png)

---

### 1.5 Validate All Files

#### Validation Checklist

Verify the following files exist and are not empty:

```cmd
dir C:\temp\pgp\keys\*.pgp
dir C:\temp\pgp\keys\*.asc
```

**Expected files:**

**Key Files (ASCII armored):**
- ✅ `sender-private.asc` - Sender's private key (generated)
- ✅ `sender-public.asc` - Sender's public key (generated)
- ✅ `receiver-private.asc` - Receiver's private key (generated)
- ✅ `receiver-public.asc` - Receiver's public key (generated)

**Repository Files (binary):**
- ✅ `sender-private-repository.pgp` - Sender's private key repository
- ✅ `sender-public-repository.pgp` - Sender's public key repository (contains receiver's public key)
- ✅ `receiver-private-repository.pgp` - Receiver's private key repository
- ✅ `receiver-public-repository.pgp` - Receiver's public key repository (contains sender's public key)

![dir check](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-13.png)

#### Final Verification

All four list commands should complete successfully without errors. If any command fails, review the import steps and ensure:
- File paths are correct
- User IDs match exactly (including email format)
- Repository files were created during import
- No typos in file names

**You are now ready to configure ACE policies and test encryption/decryption!**

---

## Part 2: ACE Flow Setup and Configuration

This section covers importing the test flows and configuring the required policies.

### 2.1 Import Test Flows

#### Step 1: Open ACE Toolkit

Launch the IBM App Connect Enterprise Toolkit (version 13.0.6.0).

![ace welcome](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-14.png)

#### Step 2: Import the TestPGP Application and Policy Project

1. In the ACE Toolkit, go to **File** → **Import**
2. Select **IBM Integration** → **Project Interchange**
3. Click **Next**

![pi_1](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-15.png)
![pi_2](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-16.png)

4. Browse to the TestPGP.zip file location:
   ```
   <project-root>\Test Project\TestPGP.zip
   ```
5. Select the zip file and click **Open**
6. Ensure both **TestPGP** application and **PGP_Policies** policy project are checked
7. Click **Finish**

![import](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-17.png)

#### Step 3: Verify Imported Projects

After import, you should see both projects in the Application Development view:

**TestPGP Application Structure:**
```
TestPGP/
├── pgp/
│   ├── encrypt.msgflow
│   ├── decrypt.msgflow
│   └── testpgp_Compute.esql
├── application.descriptor
├── plain.txt
└── testpgp_inputMessage.xml
```

**PGP_Policies Policy Project Structure:**
```
PGP_Policies/
├── PGP-SDR-CFG-SERVICE.policyxml
└── PGP-RCV-CFG-SERVICE.policyxml
```

![project view](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-18.png)

**Important:** The policy files are pre-configured with:
- Correct repository file paths (`*-repository.pgp`)
- Passphrase: `passw0rd` (matching the keys you generated)
- Sender policy for encryption
- Receiver policy for decryption

#### Step 4: Review the Message Flows

**Encrypt Flow (`pgp/encrypt.msgflow`):**
- **HTTP Input** → Receives trigger via HTTP POST to `/pgp/encrypt`
- **PGP Encrypter** → Encrypts the file using PGP
- **File Read** → Reads the encrypted file
- **HTTP Reply** → Returns response

![encrypt flow](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-19.png)

**Decrypt Flow (`pgp/decrypt.msgflow`):**
- **HTTP Input** → Receives trigger via HTTP POST to `/pgp/decrypt`
- **PGP Decrypter** → Decrypts the file using PGP
- **File Read** → Reads the decrypted file
- **HTTP Reply** → Returns response

![decrypt flow](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-20.png)

---

### 2.2 Verify Policy Configuration

Before testing, verify that the imported policy files are correctly configured.

#### Step 1: Open Sender Policy

1. In Application Development view, expand **PGP_Policies** project
2. Double-click **PGP-SDR-CFG-SERVICE.policyxml**

**Verify the following settings:**

| Property | Expected Value | Description |
|----------|----------------|-------------|
| **Type** | `UserDefined` | Policy type for PGP configuration |
| **DefaultDecryptionKeyPassphrase** | `passw0rd` | Passphrase for decryption (sender's private key) |
| **DefaultSignKeyPassphrase** | `passw0rd` | Passphrase for signing (sender's private key) |
| **DefaultSignKeyUserId** | `Sender <sender@testpgp.com>` | User ID for signing operations |
| **PrivateKeyRepository** | `C:/temp/pgp/keys/sender-private-repository.pgp` | Sender's private key repository |
| **PublicKeyRepository** | `C:/temp/pgp/keys/sender-public-repository.pgp` | Contains receiver's public key for encryption |

**[SCREENSHOT PLACEHOLDER: Sender policy configuration]**

#### Step 2: Open Receiver Policy

1. Double-click **PGP-RCV-CFG-SERVICE.policyxml**

**Verify the following settings:**

| Property | Expected Value | Description |
|----------|----------------|-------------|
| **Type** | `UserDefined` | Policy type for PGP configuration |
| **DefaultDecryptionKeyPassphrase** | `passw0rd` | Passphrase for decryption (receiver's private key) |
| **DefaultSignKeyPassphrase** | `passw0rd` | Passphrase for signing (receiver's private key) |
| **DefaultSignKeyUserId** | `Receiver <receiver@testpgp.com>` | User ID for signing operations |
| **PrivateKeyRepository** | `C:/temp/pgp/keys/receiver-private-repository.pgp` | Receiver's private key repository for decryption |
| **PublicKeyRepository** | `C:/temp/pgp/keys/receiver-public-repository.pgp` | Contains sender's public key for signature verification |

**[SCREENSHOT PLACEHOLDER: Receiver policy configuration]**

**Note:** If you used a different passphrase when generating keys, update the `<DefaultDecryptionKeyPassphrase>` and `<DefaultSignKeyPassphrase>` values in both policy files to match.

---

### 2.3 Understand Encryptor Flow Properties

The **encrypt.msgflow** uses the PGP Encrypter node with the following configuration:

#### PGP Encrypter Node Properties

Open `pgp/encrypt.msgflow` and select the **PGP Encrypter** node to view its properties:

**Basic Properties:**

| Property | Value | Description |
|----------|-------|-------------|
| **Node Name** | `PGP Encrypter` | Display name of the node |
| **File Encryption** | `Yes` | Encrypt file content |
| **Input Directory** | `C:\temp\pgp\input` | Directory containing file to encrypt |
| **Input File Name** | `plain.txt` | Name of file to encrypt |
| **Output Directory** | `C:\temp\pgp\output` | Directory for encrypted file |
| **Output File Name** | `encrypted.txt` | Name of encrypted file |

![encrypt properties](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-21.png)

**Policy Configuration:**

| Property | Value | Description |
|----------|-------|-------------|
| **PGP Policy** | `{PGP_Policies}:PGP_SDR_CFG_SERVICE` | Reference to sender policy |
| **Encryption Key User ID** | `Receiver <receiver@testpgp.com>` | Recipient's user ID (from public key) |

![encrypt policy](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-22.png)

**Important Notes:**
- The **Encryption Key User ID** must match the user ID of the receiver's public key in the sender's public keystore
- The policy reference format is `{PolicyProjectName}:PolicyName`
- The node reads from the input directory, encrypts the file, and writes to the output directory

---

### 2.4 Understand Decryptor Flow Properties

The **decrypt.msgflow** uses the PGP Decrypter node with the following configuration:

#### PGP Decrypter Node Properties

Open `pgp/decrypt.msgflow` and select the **PGP Decrypter** node to view its properties:

**Basic Properties:**

| Property | Value | Description |
|----------|-------|-------------|
| **Node Name** | `PGP Decrypter` | Display name of the node |
| **File Encryption** | `Yes` | Decrypt file content |
| **Input Directory** | `C:\temp\pgp\output` | Directory containing encrypted file |
| **Input File Name** | `encrypted.txt` | Name of file to decrypt |
| **Output Directory** | `C:\temp\pgp\input` | Directory for decrypted file |
| **Output File Name** | `plain-decrypted.txt` | Name of decrypted file |

![decrypt properties](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-23.png)

**Policy Configuration:**

| Property | Value | Description |
|----------|-------|-------------|
| **PGP Policy** | `{PGP_Policies}:PGP_RCV_CFG_SERVICE` | Reference to receiver policy |

![decrypt policy](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-24.png)

**Important Notes:**
- The decrypter automatically identifies which private key to use based on the encryption metadata
- The policy provides access to the receiver's private key for decryption
- The node reads from the input directory, decrypts the file, and writes to the output directory

---

## Part 3: Test Flow Execution

This section covers deploying the application and testing the encryption/decryption flows.

### 3.1 Deploy Application and Policies

#### Step 1: Create Integration Server

If you don't have an integration server, create one:

Use the toolkit

![toolkit is](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-25.png)

Or via the command line 

```cmd
IntegrationServer --work-dir C:\temp\pgp\TEST_SERVER_PGP
```

Or use an existing integration server.

![integration server create](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-26.png)

![integration server started](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-27.png)

#### Step 2: Copy Bouncy Castle JARs to Integration Server

**IMPORTANT:** The integration server needs the Bouncy Castle libraries in its shared-classes directory.

```cmd
REM Copy Bouncy Castle JARs to your integration server's shared-classes
copy "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar" "C:\temp\pgp\TEST_SERVER_PGP\shared-classes\"
copy "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar" "C:\temp\pgp\TEST_SERVER_PGP\shared-classes\"
```

**Note:** Replace `C:\temp\pgp\TEST_SERVER_PGP` with your actual integration server work directory path.

**[SCREENSHOT PLACEHOLDER: Bouncy Castle JARs copied to integration server]**

#### Step 3: Restart Integration Server

After copying the JARs, restart the integration server:

**Using Toolkit:**
1. Right-click on the integration server
2. Select **Stop**
3. Wait for it to stop
4. Right-click again and select **Start**

**Using Command Line:**
```cmd
mqsistop TEST_SERVER_PGP
mqsistart TEST_SERVER_PGP
```

**[SCREENSHOT PLACEHOLDER: Integration server restarted]**

#### Step 4: Deploy Policy Project

1. In ACE Toolkit, right-click on **PGP_Policies** project
2. Select **Deploy**
3. Select your integration server: `TestPGPServer`
4. Click **Finish**

Or drag and drop

![deployed policy](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-28.png)

#### Step 5: Deploy TestPGP Application

1. Right-click on **TestPGP** application
2. Select **Deploy**
3. Select your integration server: `TestPGPServer`
4. Click **Finish**

![deployed app](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-29.png)

---

### 3.2 Test Encryption Flow

#### Step 1: Prepare Test File

Create a test file to encrypt:

```cmd
echo This is a test file for PGP encryption > C:\temp\pgp\input\plain.txt
```

**[SCREENSHOT PLACEHOLDER: Test file created in input directory]**

#### Step 2: Trigger Encryption Flow

Use a REST client (Postman, curl, or browser) to trigger the encryption flow:

**Using curl:**
```cmd
curl -X POST http://localhost:7800/pgp/encrypt
```

**Using PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:7800/pgp/encrypt" -Method POST
```

The reply will give you the encrypted PGP message. Save this message as C:\temp\pgp\output\encrypted.txt, it will be used as the input message for the decryption test

![success](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-30.png)

---

### 3.3 Test Decryption Flow

#### Step 1: Trigger Decryption Flow

Use a REST client to trigger the decryption flow:

**Using curl:**
```cmd
curl -X POST http://localhost:7800/pgp/decrypt
```

**Using PowerShell:**
```powershell
Invoke-WebRequest -Uri "http://localhost:7800/pgp/decrypt" -Method POST
```

![decryption result](/.TEST-SETUP-WALKTHROUGH-ACE-13/image-31.png)

---

### 3.4 Verify Results

#### Verification Checklist

- ✅ **Encryption successful**: `encrypted.txt` created in output directory
- ✅ **Encrypted file is binary**: Cannot read content as plain text
- ✅ **Decryption successful**: `plain-decrypted.txt` created in input directory
- ✅ **Content matches**: Original and decrypted files are identical
- ✅ **No errors in logs**: Check integration server logs for any errors


#### Test Summary

| Test Case | Status | Notes |
|-----------|--------|-------|
| Key generation | ✅ Pass | All keys created successfully |
| Key import | ✅ Pass | Keys imported into repositories |
| Policy configuration | ✅ Pass | Both policies configured correctly |
| Application deployment | ✅ Pass | TestPGP deployed successfully |
| Encryption flow | ✅ Pass | File encrypted successfully |
| Decryption flow | ✅ Pass | File decrypted successfully |
| Content verification | ✅ Pass | Original and decrypted files match |

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: "Keystore not found" Error

**Symptom:**
```
Error: Keystore file not found: C:\temp\pgp\keys\sender-private.pgp
```

**Solution:**
1. Verify the keystore file exists:
   ```cmd
   dir C:\temp\pgp\keys\*.pgp
   ```
2. Check the path in the policy configuration matches the actual file location
3. Ensure the integration server has read access to the keystore directory

#### Issue 2: "Invalid password" Error

**Symptom:**
```
Error: Invalid keystore password
```

**Solution:**
1. Verify the password in the policy matches the password used when creating the keystore
2. Check for typos in the policy configuration
3. Re-create the keystore if the password is forgotten

#### Issue 3: "Encryption key not found" Error

**Symptom:**
```
Error: Cannot find encryption key for user ID: Receiver <receiver@testpgp.com>
```

**Solution:**
1. Verify the receiver's public key is imported into the sender's public repository:
   ```cmd
   java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\sender-public-repository.pgp
   ```
2. Check that the **Encryption Key User ID** in the PGP Encrypter node matches the user ID in the public key (should be "Receiver <receiver@testpgp.com>")
3. Re-import the receiver's public key if necessary:
   ```cmd
   java pgpkeytool importPublicKey -pr C:\temp\pgp\keys\sender-public-repository.pgp -i true -pf C:\temp\pgp\keys\receiver-public.asc
   ```

#### Issue 4: "Decryption failed" Error

**Symptom:**
```
Error: No suitable private key found for decryption
```

**Solution:**
1. Verify the receiver's private key is in the private repository:
   ```cmd
   java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\receiver-private-repository.pgp
   ```
2. Ensure the policy references the correct private repository (`receiver-private-repository.pgp`)
3. Verify the private key passphrase in the policy is correct (`passw0rd`)
4. Verify the encrypted file was encrypted with the receiver's public key

#### Issue 5: HTTP 404 Error

**Symptom:**
```
HTTP 404 Not Found when calling /pgp/encrypt or /pgp/decrypt
```

**Solution:**
1. Verify the application is deployed:
   ```cmd
   mqsilist TestPGPServer
   ```
2. Check the integration server is running:
   ```cmd
   mqsireportproperties TestPGPServer -o HTTPSConnector -r
   ```
3. Verify the HTTP port (default 7800) is correct
4. Check the URL path matches the flow configuration

#### Issue 6: NoClassDefFoundError - Bouncy Castle Libraries Not Found

**Symptom:**
```
BIP4367E: The method 'evaluate' in Java node 'PGP Encrypter' has thrown the following exception: java.lang.NoClassDefFoundError: org.bouncycastle.openpgp.operator.KeyFingerPrintCalculator
```

**Solution:**
The Bouncy Castle JAR files are not accessible to the integration server at runtime.

1. Copy the Bouncy Castle JARs to your integration server's shared-classes directory:
   ```cmd
   copy "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar" "<integration-server-work-dir>\shared-classes\"
   copy "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar" "<integration-server-work-dir>\shared-classes\"
   ```

2. Restart the integration server:
   ```cmd
   mqsistop <server-name>
   mqsistart <server-name>
   ```

3. Verify the JARs are in the correct location:
   ```cmd
   dir "<integration-server-work-dir>\shared-classes\*.jar"
   ```

**Note:** This step is documented in Section 3.1, Step 2 of this walkthrough.

#### Issue 7: File Permission Errors

**Symptom:**
```
Error: Access denied to file: C:\temp\pgp\input\plain.txt
```

**Solution:**
1. Verify the integration server user has read/write access to the directories
2. Check Windows file permissions on the directories
3. Run the integration server with appropriate privileges

---

## Appendix

### A. Directory Structure

Complete directory structure for this test setup:

```
C:\temp\pgp\
├── keys\
│   ├── sender-private.asc                  # Sender's private key (ASCII armored)
│   ├── sender-public.asc                   # Sender's public key (ASCII armored)
│   ├── sender-private-repository.pgp       # Sender's private key repository
│   ├── sender-public-repository.pgp        # Sender's public key repository (contains receiver's public key)
│   ├── receiver-private.asc                # Receiver's private key (ASCII armored)
│   ├── receiver-public.asc                 # Receiver's public key (ASCII armored)
│   ├── receiver-private-repository.pgp     # Receiver's private key repository
│   └── receiver-public-repository.pgp      # Receiver's public key repository (contains sender's public key)
├── input\
│   ├── plain.txt                           # Original test file
│   └── plain-decrypted.txt                 # Decrypted file (after test)
└── output\
    └── encrypted.txt                       # Encrypted file (after test)
```

### B. Policy Reference Format

The policy reference format used in the message flows:

```
{PolicyProjectName}:PolicyName
```

Examples:
- `{PGP_Policies}:PGP-SDR-CFG-SERVICE` - Sender policy
- `{PGP_Policies}:PGP-RCV-CFG-SERVICE` - Receiver policy

### C. Key Management Best Practices

1. **Password Security**
   - Use strong passwords for keystores and private keys
   - Store passwords securely (consider using ACE vault for production)
   - Never commit passwords to source control

2. **Key Rotation**
   - Rotate keys periodically (e.g., annually)
   - Maintain old keys for decrypting historical data
   - Document key rotation procedures

3. **Backup**
   - Regularly backup keystore files
   - Store backups securely and encrypted
   - Test backup restoration procedures

4. **Access Control**
   - Restrict file system access to keystore directories
   - Use appropriate Windows ACLs
   - Audit access to private keys

### D. Command Reference

Quick reference for common pgpKeytool commands used in this walkthrough:

```cmd
REM Generate key pair
java pgpkeytool generatePGPKeyPair -i "Name <email@domain.com>" -s C:\path\to\private.asc -o C:\path\to\public.asc

REM Import private key into repository
java pgpkeytool importPrivateKey -sr C:\path\to\private-repository.pgp -i true -sf C:\path\to\private.asc

REM Import public key into repository
java pgpkeytool importPublicKey -pr C:\path\to\public-repository.pgp -i true -pf C:\path\to\public.asc

REM List private keys
java pgpkeytool listPrivateKeys -sr C:\path\to\private-repository.pgp

REM List public keys
java pgpkeytool listPublicKeys -pr C:\path\to\public-repository.pgp

REM Export private key from repository
java pgpkeytool exportPrivateKey -sr C:\path\to\private-repository.pgp -su "Name <email@domain.com>" -i true -sf C:\path\to\exported-private.asc

REM Export public key from repository
java pgpkeytool exportPublicKey -pr C:\path\to\public-repository.pgp -pu "Name <email@domain.com>" -i true -pf C:\path\to\exported-public.asc

REM Delete private key from repository
java pgpkeytool deletePrivateKey -sr C:\path\to\private-repository.pgp -su "Name <email@domain.com>"

REM Delete public key from repository
java pgpkeytool deletePublicKey -pr C:\path\to\public-repository.pgp -pu "Name <email@domain.com>"

REM Change private key passphrase
java pgpkeytool changePrivateKeyPassphrase -sr C:\path\to\private-repository.pgp -su "Name <email@domain.com>"
```

For complete command syntax and all available operations, see [PGPKEYTOOL-COMMANDS.md](PGPKEYTOOL-COMMANDS.md).

### E. Additional Resources

- **PGP SupportPac User Guide**: [Link to PDF](D:\GIT\MyOpenTech-PGP-SupportPac\docs\PGP Security Implementation in IBM Integration Bus v10 Part-1 PGP SupportPac User Guide.pdf)
- **PGP Command-line Tool Manual**: [Link to PDF](D:\GIT\MyOpenTech-PGP-SupportPac\docs\PGP Security Implementation in IBM Integration Bus v9 Part-4 PGP Command-line tool User Manual.pdf)
- **Installation Guide**: [INSTALLATION.md](INSTALLATION.md)
- **Main README**: [README.md](README.md)

### F. ACE 13.0.6.0 Compatibility Notes

**Testing Status**: ✅ Complete - All Tests Passed

**Test Results:**
- ✅ Installation of JAR files - Success
- ✅ PGP nodes visible in Toolkit palette - Success
- ✅ Policy configuration (UserDefined type) - Success
- ✅ Bouncy Castle libraries integration - Success (requires copy to integration server)
- ✅ Encryption flow execution - Success
- ✅ Decryption flow execution - Success
- ✅ Error handling and logging - Success

**Key Findings:**
1. **Bouncy Castle JARs**: Must be copied to integration server's `shared-classes` directory (not just `%MQSI_REGISTRY%\shared-classes\`)
2. **Policy Type**: Policies must use `UserDefined` type (not `PGP` type)
3. **Policy Properties**: Use `DefaultDecryptionKeyPassphrase`, `DefaultSignKeyPassphrase`, `DefaultSignKeyUserId`, `PrivateKeyRepository`, `PublicKeyRepository`
4. **Command Syntax**: pgpKeytool uses operation names (e.g., `generatePGPKeyPair`) not flags (e.g., `-genkey`)
5. **Repository Files**: Keys are stored in `-repository.pgp` files, separate from the `.asc` key files

**Compatibility Confirmed:**
PGP SupportPac is fully compatible with IBM ACE 13.0.6.0 with the configuration documented in this walkthrough.

**Next Steps:**
Update the compatibility table in [README.md](README.md) to mark ACE 13.0.6.0 as validated.

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | 2026-02-11 | Auto-generated | Initial test walkthrough for ACE 13.0.6.0 |

---

**End of Document**