# Test Resources

This directory contains shared test resources used by all PGP SupportPac testing approaches.

## Overview

All testing methods (Docker, Standalone Server, Node-managed) use these common resources to ensure consistency across test environments.

## Directory Structure

```
test-resources/
├── Sources/                          # ACE project sources
│   ├── TestPGP.bar                  # Pre-built BAR file
│   ├── Deploymentdescriptors/       # Deployment overrides
│   ├── PGP_Policies/                # Policy project
│   ├── pgp-keys/                    # Test PGP keys
│   └── TestPGP_App/                 # Test application
├── TestPGP/                         # Eclipse project files
└── TestPgp_ProjectInterchange.zip   # Project interchange for import
```

## Contents

### Sources/

Contains the source files for the test application and policies.

#### TestPGP.bar
Pre-built BAR file containing:
- TestPGP_App application
- PGP encryption/decryption flows
- Ready for deployment

#### Deploymentdescriptors/
- `containerOverrides.properties` - Property overrides for Docker deployment

#### PGP_Policies/
Policy project containing:
- `PGP-SDR-CFG-SERVICE.policyxml` - Sender policy (local paths)
- `PGP-RCV-CFG-SERVICE.policyxml` - Receiver policy (local paths)
- `PGP-SDR-CFG-SERVICE-CONTAINER.policyxml` - Sender policy (container paths)
- `PGP-RCV-CFG-SERVICE-CONTAINER.policyxml` - Receiver policy (container paths)

#### pgp-keys/
Test PGP keys for encryption/decryption:
- `sender-private.asc` / `sender-private-repository.pgp`
- `sender-public.asc` / `sender-public-repository.pgp`
- `receiver-private.asc` / `receiver-private-repository.pgp`
- `receiver-public.asc` / `receiver-public-repository.pgp`

**Passphrase:** `passw0rd` (for all test keys)

#### TestPGP_App/
Message flow application containing:
- `pgp/encrypt.msgflow` - Encryption flow
- `pgp/decrypt.msgflow` - Decryption flow
- `pgp/testpgp_Compute.esql` - ESQL compute node

### TestPGP/
Eclipse project files for importing into ACE Toolkit.

### TestPgp_ProjectInterchange.zip
Project interchange file for easy import into ACE Toolkit.

## Usage by Test Type

### Docker Testing
- Uses container-specific policies (`*-CONTAINER.policyxml`)
- Paths: `/home/aceuser/pgp-test/`
- Deployment: Via `ibmint deploy` in container
- Keys copied to: `/home/aceuser/pgp-test/keys/`

### Standalone Server Testing
- Uses local policies (`PGP-SDR-CFG-SERVICE.policyxml`, `PGP-RCV-CFG-SERVICE.policyxml`)
- Paths: `C:\temp\pgp\`
- Deployment: Via `ibmint deploy` or ACE Toolkit
- Keys copied to: `C:\temp\pgp\keys\`

### Node-Managed Testing (Future)
- Will use node-level policies
- Paths: Configurable per environment
- Deployment: Via BAR file to Integration Node
- Keys: Node-level or server-level (TBD)

## Key Configuration

### Sender Configuration
**Purpose:** Encrypt messages for receiver

**Private Key Repository:** `sender-private-repository.pgp`
- Contains: Sender's private key
- Used for: Signing (optional)

**Public Key Repository:** `sender-public-repository.pgp`
- Contains: Receiver's public key
- Used for: Encryption

### Receiver Configuration
**Purpose:** Decrypt messages from sender

**Private Key Repository:** `receiver-private-repository.pgp`
- Contains: Receiver's private key
- Used for: Decryption

**Public Key Repository:** `receiver-public-repository.pgp`
- Contains: Sender's public key
- Used for: Signature verification (optional)

## Policy Configuration

### Local Testing Policies
Used by standalone server testing:
- File paths: `C:/temp/pgp/keys/`
- Passphrase: `passw0rd`
- User IDs: `Sender <sender@testpgp.com>`, `Receiver <receiver@testpgp.com>`

### Container Testing Policies
Used by Docker testing:
- File paths: `/home/aceuser/pgp-test/keys/`
- Passphrase: `passw0rd`
- User IDs: Same as local

## Updating Test Resources

### To Update Test Application
1. Modify flows in `TestPGP_App/`
2. Rebuild BAR file: `mqsipackagebar -a TestPGP.bar -w . -k TestPGP_App`
3. Test with all testing approaches
4. Commit changes

### To Update Policies
1. Modify policy XML files in `PGP_Policies/`
2. Ensure both local and container versions are updated
3. Test with respective testing approaches
4. Commit changes

### To Update PGP Keys
1. Generate new keys using `pgpkeytool`
2. Update all repository files
3. Update policy passphrases if changed
4. Test encryption/decryption
5. Document passphrase changes

## Security Notes

⚠️ **These are test keys only!**

- Keys are committed to repository for testing purposes
- Passphrase is publicly known (`passw0rd`)
- **Never use these keys in production**
- Generate new keys for production environments
- Use secure passphrase management (ACE vault, etc.)

## Troubleshooting

### Issue: Keys not found
**Solution:** Verify paths in policy files match your test environment

### Issue: Wrong passphrase
**Solution:** All test keys use passphrase `passw0rd`

### Issue: Deployment fails
**Solution:** Check that `Sources/` directory structure is intact

### Issue: Flows not working
**Solution:** Verify policies are deployed before application

## Related Documentation

- [Docker Testing](../docker/README.md)
- [Standalone Server Testing](../standalone-server/README.md)
- [Node-Managed Testing](../node-managed-server/README.md)
- [Testing Overview](../docs/TESTING-OVERVIEW.md)

---

**Last Updated:** 2026-02-16  
**Maintained By:** PGP SupportPac Project