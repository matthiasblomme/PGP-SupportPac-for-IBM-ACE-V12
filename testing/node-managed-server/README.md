# Node-Managed Server Testing for PGP SupportPac

## Overview

This directory contains automated setup and testing scripts for the PGP SupportPac in a **node-managed** IBM ACE environment. In this configuration, multiple integration servers are managed by a single integration node.

## Architecture

```
Integration Node (TEST_NODE)
├── shared-classes/              ← Bouncy Castle JARs (NODE LEVEL)
│   ├── bcpg-jdk18on-1.81.jar
│   └── bcprov-jdk18on-1.81.jar
├── SERVER_ENCRYPT (port 7800)   ← Encryption server
│   ├── run/
│   │   ├── PGP_Policies/
│   │   └── TestPGP_App/
│   └── overrides/
│       └── server.conf.yaml
└── SERVER_DECRYPT (port 7801)   ← Decryption server
    ├── run/
    │   ├── PGP_Policies/
    │   └── TestPGP_App/
    └── overrides/
        └── server.conf.yaml
```

## Key Differences from Standalone Server

| Aspect | Standalone Server | Node-Managed Server |
|--------|------------------|---------------------|
| **Management** | Single independent server | Multiple servers managed by node |
| **JAR Location** | `<work-dir>/shared-classes/` | `<node-work-dir>/shared-classes/` (NODE level) |
| **Deployment** | `--output-work-directory` | `--output-integration-node` + `--output-integration-server` |
| **Start/Stop** | `ibmint start/stop server` | `ibmint start/stop node` (affects all servers) |
| **Port Config** | Direct in server.conf.yaml | Via overrides/server.conf.yaml per server |

## Prerequisites

- IBM ACE 13.0.6.0 installed at `C:\Program Files\IBM\ACE\13.0.6.0`
- PGP SupportPac installed (JARs in `MQSI_REGISTRY/shared-classes/`)
- Test resources available in `testing/test-resources/Sources/`
- Administrative privileges (for creating Windows services)

## Quick Start

### Automated Setup and Test

Run the complete setup and test in one command:

```batch
cd testing\node-managed-server\scripts
setup-and-test-node.bat
```

This script will:
1. ✅ Source ACE environment
2. ✅ Clean up any existing TEST_NODE
3. ✅ Create integration node TEST_NODE
4. ✅ Start the integration node
5. ✅ Create two integration servers (SERVER_ENCRYPT, SERVER_DECRYPT)
6. ✅ Install Bouncy Castle JARs at **node level**
7. ✅ Restart node to load JARs
8. ✅ Configure HTTP ports (7800, 7801)
9. ✅ Restart node to apply port configuration
10. ✅ Deploy PGP policies and TestPGP_App to both servers
11. ✅ Verify HTTP listeners are active
12. ✅ Run encryption and decryption tests

### Manual Testing

After setup, you can manually test the endpoints:

**Encryption Test (SERVER_ENCRYPT on port 7800):**
```batch
curl -X POST http://localhost:7800/pgp/encrypt ^
  -H "Content-Type: text/plain" ^
  -d "Your message to encrypt"
```

**Decryption Test (SERVER_DECRYPT on port 7801):**
```batch
curl -X POST http://localhost:7801/pgp/decrypt ^
  -H "Content-Type: text/plain" ^
  -d "PGP encrypted message"
```

**Note:** The decrypt flow reads from `encrypted.txt` file, not from HTTP input.

## Configuration

### Node and Server Names

Edit `setup-and-test-node.bat` to customize:

```batch
set NODE_NAME=TEST_NODE
set SERVER_ENCRYPT=SERVER_ENCRYPT
set SERVER_DECRYPT=SERVER_DECRYPT
set PORT_ENCRYPT=7800
set PORT_DECRYPT=7801
```

### Work Directory

Default location: `C:\temp\pgp-node\TEST_NODE`

Change by editing:
```batch
set NODE_WORK_DIR=C:\temp\pgp-node\%NODE_NAME%
```

## Important Notes

### 1. JAR Installation Location

**CRITICAL:** In node-managed environments, Bouncy Castle JARs **MUST** be installed at the **NODE level**, not at individual server levels.

✅ **Correct:**
```
C:\temp\pgp-node\TEST_NODE\shared-classes\
├── bcpg-jdk18on-1.81.jar
└── bcprov-jdk18on-1.81.jar
```

❌ **Incorrect:**
```
C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\
C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\
```

If JARs are at server level, you'll get:
```
java.lang.NoClassDefFoundError: org.bouncycastle.openpgp.operator.KeyFingerPrintCalculator
```

### 2. Node Restart Required

After installing JARs or changing configuration, restart the entire node:

```batch
ibmint stop node TEST_NODE
ibmint start node TEST_NODE
```

This restarts **all** servers managed by the node.

### 3. Deployment Commands

Use node-managed deployment syntax:

```batch
ibmint deploy --input-path <sources> ^
  --output-integration-node TEST_NODE ^
  --output-integration-server SERVER_ENCRYPT ^
  --project PGP_Policies
```

**Do NOT use** `--output-work-directory` with `--integration-node` - they are mutually exclusive.

### 4. Node Deletion

To completely remove a node:

```batch
ibmint stop node TEST_NODE
ibmint delete node TEST_NODE --delete-all-files
```

The `--delete-all-files` flag is required to remove all associated files and Windows services.

## Troubleshooting

### Port Already in Use

Check what's using the ports:
```batch
netstat -ano | findstr ":7800"
netstat -ano | findstr ":7801"
```

### Node Won't Start

Check the node logs:
```
C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\log\
C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\log\
```

### JARs Not Loading

1. Verify JARs are at node level:
   ```batch
   dir C:\temp\pgp-node\TEST_NODE\shared-classes
   ```

2. Restart the node:
   ```batch
   ibmint stop node TEST_NODE
   ibmint start node TEST_NODE
   ```

3. Wait 10 seconds for full startup

### Deployment Fails

Ensure you're using the correct syntax:
- ✅ `--output-integration-node` + `--output-integration-server`
- ❌ NOT `--output-work-directory` with node-managed servers

## Test Results

### Successful Test Output

**Encryption (port 7800):**
```
-----BEGIN PGP MESSAGE-----
Version: BCPG v1.81

wYwD/OaiZSq80gUBBADFPtoTkoggLq9OcZHxfv2ffM26WGorjdUzIsdDNSaEsLH1
FNiXXi6sIiYiRHDebMCDWEYrIbdDY4cEYXWgpH+tJR3D7CFd3wKXVvDRVnVttMrp
K0bH8v0plF2DxpH8oVys2et6cKqDWDeCn+w5TQ/I+PMBVzRpFoPoNv326FMj+dJi
AWhV5mL4/UTgMl5pknlfSr4OwIWOq7cfb8neFj95z4XUfXozoQg1hwfc143P/BAA
NuOtLqUDzudV2TAZUZzq+L+vJU7eHMynN2b3/qMNh6uzsQQOLs41XtySwsa/dn76
K1o=
=OkJe
-----END PGP MESSAGE-----
```

**Decryption (port 7801):**
```
This is a test file for PGP encryption
```

## Cleanup

To remove the test environment:

```batch
cd testing\node-managed-server\scripts
call "C:\Program Files\IBM\ACE\13.0.6.0\server\bin\mqsiprofile.cmd"
ibmint stop node TEST_NODE
ibmint delete node TEST_NODE --delete-all-files
rmdir /s /q C:\temp\pgp-node
```

## Related Documentation

- [Standalone Server Testing](../standalone-server/README.md) - Single server configuration
- [Docker Testing](../docker/README.md) - Containerized testing
- [Test Resources](../test-resources/README.md) - Shared test files
- [Main Testing Guide](../README.md) - Overview of all testing approaches

## Version History

- **2026-02-16**: Initial implementation with automated setup and testing
  - Fixed JAR installation location (node level vs server level)
  - Fixed ibmint command syntax for node-managed environments
  - Verified encryption and decryption workflows