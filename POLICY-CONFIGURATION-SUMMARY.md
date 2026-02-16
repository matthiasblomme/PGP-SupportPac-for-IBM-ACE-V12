# PGP Policy Configuration Summary

## Overview

This document summarizes the corrected PGP policy configuration for IBM ACE 13.0.6.0 testing.

---

## Key Generation Summary

All keys generated with passphrase: **`passw0rd`**

### Generated Files

**Individual Key Files (ASCII armored):**
- `sender-private.asc` - Sender's private key (passphrase: passw0rd)
- `sender-public.asc` - Sender's public key
- `receiver-private.asc` - Receiver's private key (passphrase: passw0rd)
- `receiver-public.asc` - Receiver's public key

**Repository Files (binary - used by ACE):**
- `sender-private-repository.pgp` - Contains sender's private key
- `sender-public-repository.pgp` - Contains receiver's public key (for encryption)
- `receiver-private-repository.pgp` - Contains receiver's private key
- `receiver-public-repository.pgp` - Contains sender's public key (for verification)

---

## Policy Configuration

### Sender Policy (PGP-SDR-CFG-SERVICE)

**Purpose:** Used by encryption flow to encrypt messages for the receiver

**Policy Type:** UserDefined

**Configuration:**
```xml
<?xml version="1.1" encoding="UTF-8" standalone="yes"?>
<policies>
  <policy policyType="UserDefined" policyName="PGP-SDR-CFG-SERVICE">
    <DefaultDecryptionKeyPassphrase>passw0rd</DefaultDecryptionKeyPassphrase>
    <DefaultSignKeyPassphrase>passw0rd</DefaultSignKeyPassphrase>
    <DefaultSignKeyUserId>Sender <sender@testpgp.com></DefaultSignKeyUserId>
    <PrivateKeyRepository>C:/temp/pgp/keys/sender-private-repository.pgp</PrivateKeyRepository>
    <PublicKeyRepository>C:/temp/pgp/keys/sender-public-repository.pgp</PublicKeyRepository>
  </policy>
</policies>
```

**Key Points:**
- Uses sender's private key for signing (DefaultSignKeyPassphrase)
- Uses receiver's public key (from sender-public-repository.pgp) for encryption
- DefaultSignKeyUserId identifies which key to use for signing

---

### Receiver Policy (PGP-RCV-CFG-SERVICE)

**Purpose:** Used by decryption flow to decrypt messages from the sender

**Policy Type:** UserDefined

**Configuration:**
```xml
<?xml version="1.1" encoding="UTF-8" standalone="yes"?>
<policies>
  <policy policyType="UserDefined" policyName="PGP-RCV-CFG-SERVICE">
    <DefaultDecryptionKeyPassphrase>passw0rd</DefaultDecryptionKeyPassphrase>
    <DefaultSignKeyPassphrase>passw0rd</DefaultSignKeyPassphrase>
    <DefaultSignKeyUserId>Receiver <receiver@testpgp.com></DefaultSignKeyUserId>
    <PrivateKeyRepository>C:/temp/pgp/keys/receiver-private-repository.pgp</PrivateKeyRepository>
    <PublicKeyRepository>C:/temp/pgp/keys/receiver-public-repository.pgp</PublicKeyRepository>
  </policy>
</policies>
```

**Key Points:**
- Uses receiver's private key (from receiver-private-repository.pgp) for decryption
- Uses sender's public key (from receiver-public-repository.pgp) for signature verification
- DefaultSignKeyUserId identifies which key to use for verification

---

## Important Clarifications

### Password/Passphrase Model

**What has passwords:**
- ✅ Private keys (.asc files) - Protected with passphrase
- ❌ Public keys (.asc files) - No password
- ❌ Repository files (.pgp files) - No password

**When passphrase is needed:**
- During **decryption** (ACE needs the private key passphrase)
- During **signing** (ACE needs the private key passphrase)
- Configured in the policy's `<privateKeyPassword>` element

**When passphrase is NOT needed:**
- During **encryption** (uses public key, no passphrase)
- During **signature verification** (uses public key, no passphrase)
- During **import operations** (just copying files)

---

## Correct Policy Properties

PGP policies in ACE use **UserDefined** policy type with the following properties:

### Required Properties

| Property | Description | Example Value |
|----------|-------------|---------------|
| `DefaultDecryptionKeyPassphrase` | Passphrase for the private key used in decryption | `passw0rd` |
| `DefaultSignKeyPassphrase` | Passphrase for the private key used in signing | `passw0rd` |
| `DefaultSignKeyUserId` | User ID to identify which key to use | `Sender <sender@testpgp.com>` |
| `PrivateKeyRepository` | Path to private key repository file | `C:/temp/pgp/keys/sender-private-repository.pgp` |
| `PublicKeyRepository` | Path to public key repository file | `C:/temp/pgp/keys/sender-public-repository.pgp` |

### Important Notes

- **Policy Type:** Must be `UserDefined` (not `PGP`)
- **File Paths:** Use forward slashes (`/`) even on Windows
- **User ID Format:** Must match exactly including angle brackets: `Name <email@domain.com>`
- **XML Encoding:** Use `<` and `>` for `<` and `>` in XML
- **Both Passphrases:** Even if not signing, both passphrase properties should be present

---

## Policy Properties Reference

### Sender Policy Properties

| Property | Value | Required | Description |
|----------|-------|----------|-------------|
| `policyType` | UserDefined | Yes | Policy type |
| `policyName` | PGP-SDR-CFG-SERVICE | Yes | Policy name |
| `DefaultDecryptionKeyPassphrase` | passw0rd | Yes | Passphrase for sender's private key |
| `DefaultSignKeyPassphrase` | passw0rd | Yes | Passphrase for signing |
| `DefaultSignKeyUserId` | Sender <sender@testpgp.com> | Yes | User ID for signing |
| `PrivateKeyRepository` | C:/temp/pgp/keys/sender-private-repository.pgp | Yes | Sender's private key repository |
| `PublicKeyRepository` | C:/temp/pgp/keys/sender-public-repository.pgp | Yes | Contains receiver's public key |

### Receiver Policy Properties

| Property | Value | Required | Description |
|----------|-------|----------|-------------|
| `policyType` | UserDefined | Yes | Policy type |
| `policyName` | PGP-RCV-CFG-SERVICE | Yes | Policy name |
| `DefaultDecryptionKeyPassphrase` | passw0rd | Yes | Passphrase for receiver's private key |
| `DefaultSignKeyPassphrase` | passw0rd | Yes | Passphrase for signing |
| `DefaultSignKeyUserId` | Receiver <receiver@testpgp.com> | Yes | User ID for verification |
| `PrivateKeyRepository` | C:/temp/pgp/keys/receiver-private-repository.pgp | Yes | Receiver's private key repository |
| `PublicKeyRepository` | C:/temp/pgp/keys/receiver-public-repository.pgp | Yes | Contains sender's public key |

---

## Testing Checklist

### ✅ Completed
- [x] Key generation (sender and receiver)
- [x] Key import into repositories
- [x] Repository verification (list commands)
- [x] Policy files created with correct paths
- [x] Policy files use correct passphrase (passw0rd)
- [x] Documentation updated

### 🔄 In Progress
- [ ] Policy deployment to integration server
- [ ] Test encryption flow
- [ ] Test decryption flow
- [ ] Capture screenshots for walkthrough

### 📋 Pending
- [ ] End-to-end encryption/decryption test
- [ ] Error handling verification
- [ ] Performance testing
- [ ] Update README.md with ACE 13.0.6.0 validation

---

## Quick Reference Commands

**List all keys to verify setup:**
```cmd
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\sender-private-repository.pgp
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\sender-public-repository.pgp
java pgpkeytool listPrivateKeys -sr C:\temp\pgp\keys\receiver-private-repository.pgp
java pgpkeytool listPublicKeys -pr C:\temp\pgp\keys\receiver-public-repository.pgp
```

**Expected output:**
- Sender private: "Sender <sender@testpgp.com>"
- Sender public: "Receiver <receiver@testpgp.com>"
- Receiver private: "Receiver <receiver@testpgp.com>"
- Receiver public: "Sender <sender@testpgp.com>"

---

## Files Updated

1. **testing/test-resources/Sources/PGP_Policies/PGP-SDR-CFG-SERVICE.policyxml**
   - Corrected repository paths
   - Removed invalid parameters
   - Updated to use passw0rd

2. **testing/test-resources/Sources/PGP_Policies/PGP-RCV-CFG-SERVICE.policyxml**
   - Corrected repository paths
   - Removed invalid parameters
   - Updated to use passw0rd

3. **TEST-SETUP-WALKTHROUGH-ACE-13.md**
   - Updated policy configuration sections
   - Corrected all command syntax
   - Updated troubleshooting section

4. **PGPKEYTOOL-COMMANDS.md**
   - Complete command reference with correct syntax

5. **COMMAND-SYNTAX-CORRECTIONS.md**
   - Summary of changes and testing workflow

---

## Next Steps

1. **In ACE Toolkit:**
   - Open the PGP_Policies project
   - Verify both policy files show no errors
   - Deploy policies to integration server

2. **Deploy TestPGP Application:**
   - Deploy TestPGP application
   - Deploy PGP_Policies
   - Verify deployment successful

3. **Test Flows:**
   - Test encryption: POST to `/pgp/encrypt`
   - Test decryption: POST to `/pgp/decrypt`
   - Verify encrypted/decrypted files

4. **Document Results:**
   - Capture screenshots
   - Update walkthrough with actual results
   - Mark ACE 13.0.6.0 as validated in README.md