# PGP Keytool Command Syntax Corrections

## Summary of Changes

Both `PGPKEYTOOL-COMMANDS.md` and `TEST-SETUP-WALKTHROUGH-ACE-13.md` have been updated with the **correct command syntax** based on the actual pgpkeytool help output.

## What Was Wrong

### Old (Incorrect) Syntax
The documents previously used incorrect syntax that doesn't exist:

```cmd
# WRONG - This doesn't work!
java com.ibm.broker.supportpac.pgp.PGPKeytool -genkey -alias sender-private -keystore C:\temp\pgp\keys\sender-private.pgp -storepass sender123
```

### New (Correct) Syntax
The correct syntax uses operation names and different parameters:

```cmd
# CORRECT - This works!
java pgpkeytool generatePGPKeyPair -i "Sender <sender@testpgp.com>" -s C:\temp\pgp\keys\sender-private.asc -o C:\temp\pgp\keys\sender-public.asc
```

## Key Differences

| Aspect | Old (Wrong) | New (Correct) |
|--------|-------------|---------------|
| **Command** | `java com.ibm.broker.supportpac.pgp.PGPKeytool` | `java pgpkeytool` |
| **Operation** | `-genkey` flag | `generatePGPKeyPair` operation name |
| **Key Storage** | Single keystore file with aliases | Separate .asc files + repository files |
| **Parameters** | `-alias`, `-keystore`, `-storepass`, `-keypass` | `-i` (identity), `-s` (private file), `-o` (public file) |
| **Repository** | Keystore created directly | Import keys into repository with `importPrivateKey`/`importPublicKey` |

---

## Corrected Workflow for Testing

### Step 1: Set CLASSPATH (in ACE Command Console)

```cmd
SET CLASSPATH=%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar;%CLASSPATH%
```

### Step 2: Create Directories

**IMPORTANT:** Create the directories before generating keys!

```cmd
mkdir C:\temp\pgp\keys
mkdir C:\temp\pgp\input
mkdir C:\temp\pgp\output
```

### Step 3: Generate Sender Key Pair

```cmd
java pgpkeytool generatePGPKeyPair ^
  -i "Sender <sender@testpgp.com>" ^
  -s C:\temp\pgp\keys\sender-private.asc ^
  -o C:\temp\pgp\keys\sender-public.asc
```

**You will be prompted for a passphrase** - enter and remember it (e.g., "passw0rd")

### Step 4: Generate Receiver Key Pair

```cmd
java pgpkeytool generatePGPKeyPair ^
  -i "Receiver <receiver@testpgp.com>" ^
  -s C:\temp\pgp\keys\receiver-private.asc ^
  -o C:\temp\pgp\keys\receiver-public.asc
```

**You will be prompted for a passphrase** - enter and remember it (e.g., "passw0rd")

### Step 5: Import Sender Private Key into Repository

```cmd
java pgpkeytool importPrivateKey ^
  -sr C:\temp\pgp\keys\sender-private-repository.pgp ^
  -i true ^
  -sf C:\temp\pgp\keys\sender-private.asc
```

### Step 6: Import Receiver Public Key into Sender's Public Repository

```cmd
java pgpkeytool importPublicKey ^
  -pr C:\temp\pgp\keys\sender-public-repository.pgp ^
  -i true ^
  -pf C:\temp\pgp\keys\receiver-public.asc
```

### Step 7: Import Receiver Private Key into Repository

```cmd
java pgpkeytool importPrivateKey ^
  -sr C:\temp\pgp\keys\receiver-private-repository.pgp ^
  -i true ^
  -sf C:\temp\pgp\keys\receiver-private.asc
```

### Step 8: Import Sender Public Key into Receiver's Public Repository

```cmd
java pgpkeytool importPublicKey ^
  -pr C:\temp\pgp\keys\receiver-public-repository.pgp ^
  -i true ^
  -pf C:\temp\pgp\keys\sender-public.asc
```

### Step 9: Verify All Keys

```cmd
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\sender-private-repository.pgp
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\sender-public-repository.pgp
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\receiver-private-repository.pgp
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\receiver-public-repository.pgp
```

---

## Expected Files After Completion

### Key Files (ASCII armored - human readable)
- `sender-private.asc` - Sender's private key
- `sender-public.asc` - Sender's public key
- `receiver-private.asc` - Receiver's private key
- `receiver-public.asc` - Receiver's public key

### Repository Files (binary - used by ACE)
- `sender-private-repository.pgp` - Contains sender's private key
- `sender-public-repository.pgp` - Contains receiver's public key (for encryption)
- `receiver-private-repository.pgp` - Contains receiver's private key
- `receiver-public-repository.pgp` - Contains sender's public key (for signature verification)

---

## ✅ Testing Complete

All key generation and import steps have been completed successfully with passphrase: `passw0rd`

**Files Created:**
- ✅ `sender-private.asc` and `sender-public.asc`
- ✅ `receiver-private.asc` and `receiver-public.asc`
- ✅ `sender-private-repository.pgp` and `sender-public-repository.pgp`
- ✅ `receiver-private-repository.pgp` and `receiver-public-repository.pgp`

**Policy Files Updated:**
- ✅ `PGP-SDR-CFG-SERVICE.policyxml` - Uses correct repository paths and `passw0rd`
- ✅ `PGP-RCV-CFG-SERVICE.policyxml` - Uses correct repository paths and `passw0rd`

## What's Next

1. **Configure ACE policies** in the Toolkit (Section 2.3 and 2.4 of walkthrough)
2. **Deploy the TestPGP application** with policies
3. **Test encryption and decryption flows**
4. **Capture screenshots** for the walkthrough
5. **Update README.md** to mark ACE 13.0.6.0 as tested

---

## Documents Updated

1. ✅ **PGPKEYTOOL-COMMANDS.md** - Complete command reference with all operations
2. ✅ **TEST-SETUP-WALKTHROUGH-ACE-13.md** - Step-by-step walkthrough with corrected commands
3. ✅ Both documents now use **identical command syntax**

---

## Next Steps After Key Generation

Once keys are successfully generated and verified:

1. Configure ACE policies (PGP-SDR-CFG-SERVICE and PGP-RCV-CFG-SERVICE)
2. Deploy test flows
3. Test encryption/decryption
4. Update walkthrough with actual screenshots and results
5. Mark ACE 13.0.6.0 as "Tested and validated" in README.md

---

## Getting Help

For any operation, run:
```cmd
java pgpkeytool [operation] -help
```

Example:
```cmd
java pgpkeytool generatePGPKeyPair -help
java pgpkeytool importPrivateKey -help