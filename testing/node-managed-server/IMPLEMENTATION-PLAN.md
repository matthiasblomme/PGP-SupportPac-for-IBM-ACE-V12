# Node-Managed Integration Server Testing - Implementation Plan

## Overview

This document outlines the step-by-step plan to implement node-managed testing for the PGP SupportPac.

**Date:** 2026-02-16  
**Status:** Planning Phase  
**Estimated Time:** 2-3 hours

---

## Prerequisites Check

Before we start, let's verify what we have:

```cmd
REM Check ACE version
mqsiservice -v

REM Check if any nodes exist
mqsilist

REM Check available commands
mqsi<TAB>
```

---

## Phase 1: Environment Setup (30 minutes)

### Step 1: Source ACE Environment
```cmd
call "C:\Program Files\IBM\ACE\13.0.6.0\server\bin\mqsiprofile.cmd"
```

**Verify:**
```cmd
echo %MQSI_BASE_FILEPATH%
echo %MQSI_REGISTRY%
```

### Step 2: Create Integration Node
```cmd
REM Create a new integration node for testing
mqsicreatebroker TEST_NODE -q QM_TEST_NODE

REM Alternative: Create without queue manager (standalone mode)
mqsicreatebroker TEST_NODE
```

**Expected Output:**
```
BIP8071I: Successful command completion.
```

**Verify:**
```cmd
mqsilist
```

### Step 3: Start Integration Node
```cmd
mqsistart TEST_NODE
```

**Expected Output:**
```
BIP8096I: Integration node 'TEST_NODE' has been started successfully.
```

**Verify:**
```cmd
mqsilist TEST_NODE
```

---

## Phase 2: Integration Server Creation (20 minutes)

### Step 4: Create Integration Servers

**Create Server 1 (for encryption):**
```cmd
mqsicreateexecutiongroup TEST_NODE -e SERVER_ENCRYPT
```

**Create Server 2 (for decryption):**
```cmd
mqsicreateexecutiongroup TEST_NODE -e SERVER_DECRYPT
```

**Verify:**
```cmd
mqsilist TEST_NODE
```

**Expected Output:**
```
BIP1286I: Integration node 'TEST_NODE' with administration URI 'http://localhost:4414' is running.
BIP1325I: Integration server 'SERVER_ENCRYPT' is running.
BIP1325I: Integration server 'SERVER_DECRYPT' is running.
```

---

## Phase 3: Install PGP SupportPac (15 minutes)

### Step 5: Copy Bouncy Castle JARs to Node Level

**Option A: Node-level (shared by all servers):**
```cmd
REM Copy to node's shared-classes
copy /Y "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\shared-classes\"
copy /Y "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\shared-classes\"
```

**Option B: Server-level (per server):**
```cmd
REM For SERVER_ENCRYPT
copy /Y "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\"
copy /Y "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\"

REM For SERVER_DECRYPT
copy /Y "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\"
copy /Y "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\"
```

**Recommended:** Use Option A (node-level) for simplicity.

### Step 6: Restart Integration Servers

```cmd
REM Stop servers
mqsistop TEST_NODE -e SERVER_ENCRYPT
mqsistop TEST_NODE -e SERVER_DECRYPT

REM Start servers
mqsistart TEST_NODE -e SERVER_ENCRYPT
mqsistart TEST_NODE -e SERVER_DECRYPT
```

**Verify:**
```cmd
mqsilist TEST_NODE
```

---

## Phase 4: Deploy PGP Keys (10 minutes)

### Step 7: Create Key Directories

**Option A: Node-level (shared):**
```cmd
mkdir "C:\ProgramData\IBM\MQSI\components\TEST_NODE\pgp-keys"
```

**Option B: Server-level (separate):**
```cmd
mkdir "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_ENCRYPT\pgp-keys"
mkdir "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_DECRYPT\pgp-keys"
```

### Step 8: Copy PGP Keys

**For node-level:**
```cmd
xcopy /Y "testing\test-resources\Sources\pgp-keys\*.*" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\pgp-keys\"
```

**For server-level:**
```cmd
REM Encrypt server needs sender keys
xcopy /Y "testing\test-resources\Sources\pgp-keys\sender-*.*" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_ENCRYPT\pgp-keys\"
xcopy /Y "testing\test-resources\Sources\pgp-keys\receiver-public*.*" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_ENCRYPT\pgp-keys\"

REM Decrypt server needs receiver keys
xcopy /Y "testing\test-resources\Sources\pgp-keys\receiver-*.*" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_DECRYPT\pgp-keys\"
xcopy /Y "testing\test-resources\Sources\pgp-keys\sender-public*.*" "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_DECRYPT\pgp-keys\"
```

---

## Phase 5: Create and Deploy BAR File (20 minutes)

### Step 9: Create BAR File with mqsipackagebar

```cmd
cd testing\test-resources\Sources

REM Package the application and policies
mqsipackagebar -a TestPGP_Node.bar -w . -k TestPGP_App -k PGP_Policies
```

**Verify BAR contents:**
```cmd
mqsireadbar -b TestPGP_Node.bar
```

### Step 10: Deploy to Integration Servers

**Deploy to SERVER_ENCRYPT:**
```cmd
mqsideploy TEST_NODE -e SERVER_ENCRYPT -a TestPGP_Node.bar
```

**Deploy to SERVER_DECRYPT:**
```cmd
mqsideploy TEST_NODE -e SERVER_DECRYPT -a TestPGP_Node.bar
```

**Verify deployment:**
```cmd
mqsilist TEST_NODE -e SERVER_ENCRYPT -d 2
mqsilist TEST_NODE -e SERVER_DECRYPT -d 2
```

---

## Phase 6: Configure Policies (15 minutes)

### Step 11: Update Policy Properties

**For SERVER_ENCRYPT (sender policy):**
```cmd
mqsichangeproperties TEST_NODE -e SERVER_ENCRYPT -o PGP_Policies -n PGP-SDR-CFG-SERVICE -p PrivateKeyRepository -v "C:/ProgramData/IBM/MQSI/components/TEST_NODE/pgp-keys/sender-private-repository.pgp"
mqsichangeproperties TEST_NODE -e SERVER_ENCRYPT -o PGP_Policies -n PGP-SDR-CFG-SERVICE -p PublicKeyRepository -v "C:/ProgramData/IBM/MQSI/components/TEST_NODE/pgp-keys/sender-public-repository.pgp"
```

**For SERVER_DECRYPT (receiver policy):**
```cmd
mqsichangeproperties TEST_NODE -e SERVER_DECRYPT -o PGP_Policies -n PGP-RCV-CFG-SERVICE -p PrivateKeyRepository -v "C:/ProgramData/IBM/MQSI/components/TEST_NODE/pgp-keys/receiver-private-repository.pgp"
mqsichangeproperties TEST_NODE -e SERVER_DECRYPT -o PGP_Policies -n PGP-RCV-CFG-SERVICE -p PublicKeyRepository -v "C:/ProgramData/IBM/MQSI/components/TEST_NODE/pgp-keys/receiver-public-repository.pgp"
```

**Verify properties:**
```cmd
mqsireportproperties TEST_NODE -e SERVER_ENCRYPT -o PGP_Policies -n PGP-SDR-CFG-SERVICE -a
mqsireportproperties TEST_NODE -e SERVER_DECRYPT -o PGP_Policies -n PGP-RCV-CFG-SERVICE -a
```

---

## Phase 7: Configure HTTP Listeners (10 minutes)

### Step 12: Set HTTP Ports

**SERVER_ENCRYPT (port 7800):**
```cmd
mqsichangeproperties TEST_NODE -e SERVER_ENCRYPT -o HTTPSConnector -n port -v 7800
```

**SERVER_DECRYPT (port 7801):**
```cmd
mqsichangeproperties TEST_NODE -e SERVER_DECRYPT -o HTTPSConnector -n port -v 7801
```

**Restart servers to apply:**
```cmd
mqsistop TEST_NODE -e SERVER_ENCRYPT
mqsistop TEST_NODE -e SERVER_DECRYPT
mqsistart TEST_NODE -e SERVER_ENCRYPT
mqsistart TEST_NODE -e SERVER_DECRYPT
```

**Verify:**
```cmd
mqsireportproperties TEST_NODE -e SERVER_ENCRYPT -o HTTPSConnector -r
mqsireportproperties TEST_NODE -e SERVER_DECRYPT -o HTTPSConnector -r
```

---

## Phase 8: Testing (20 minutes)

### Step 13: Create Test Files

```cmd
mkdir C:\temp\pgp-node-test\input
mkdir C:\temp\pgp-node-test\output

echo This is a test file for node-managed PGP encryption > C:\temp\pgp-node-test\input\plain.txt
```

### Step 14: Test Encryption (SERVER_ENCRYPT)

```cmd
curl -X POST http://localhost:7800/pgp/encrypt -o C:\temp\pgp-node-test\output\encrypted.txt
```

**Expected:** Encrypted PGP message

### Step 15: Test Decryption (SERVER_DECRYPT)

```cmd
curl -X POST http://localhost:7801/pgp/decrypt -o C:\temp\pgp-node-test\input\plain-decrypted.txt
```

**Expected:** Decrypted plain text

### Step 16: Verify Results

```cmd
fc /B C:\temp\pgp-node-test\input\plain.txt C:\temp\pgp-node-test\input\plain-decrypted.txt
```

**Expected:** Files are identical

---

## Phase 9: Cleanup (Optional)

### Step 17: Stop and Remove Test Environment

```cmd
REM Stop integration node
mqsistop TEST_NODE

REM Delete integration node
mqsideletebroker TEST_NODE

REM Clean up test files
rmdir /S /Q C:\temp\pgp-node-test
```

---

## Troubleshooting Commands

### Check Node Status
```cmd
mqsilist
mqsilist TEST_NODE
mqsilist TEST_NODE -e SERVER_ENCRYPT -d 2
```

### Check Logs
```cmd
REM Node logs
type "C:\ProgramData\IBM\MQSI\components\TEST_NODE\logs\*.txt"

REM Server logs
type "C:\ProgramData\IBM\MQSI\components\TEST_NODE\servers\SERVER_ENCRYPT\logs\*.txt"
```

### Check Deployed Applications
```cmd
mqsilist TEST_NODE -e SERVER_ENCRYPT -d 2
```

### Check Properties
```cmd
mqsireportproperties TEST_NODE -e SERVER_ENCRYPT -a
```

---

## Key Differences from Standalone

| Aspect | Standalone Server | Node-Managed |
|--------|------------------|--------------|
| **Creation** | `IntegrationServer --work-dir` | `mqsicreateexecutiongroup` |
| **Management** | Direct file access | mqsi commands |
| **Deployment** | `ibmint deploy` | `mqsideploy` with BAR |
| **Configuration** | Direct file edit | `mqsichangeproperties` |
| **Monitoring** | Server logs only | Node + Server logs |
| **Shared Resources** | Per-server | Node-level possible |

---

## Decision Points

### 1. Key Storage Location
- **Node-level:** Simpler, shared by all servers
- **Server-level:** More isolated, better for production

**Recommendation:** Start with node-level for testing

### 2. Bouncy Castle JAR Location
- **Node-level:** One copy, shared
- **Server-level:** Per-server copies

**Recommendation:** Node-level

### 3. Number of Servers
- **Single server:** Simpler, like standalone
- **Multiple servers:** Tests node management features

**Recommendation:** Two servers (encrypt/decrypt) to demonstrate node capabilities

---

## Next Steps

1. **Review this plan** - Confirm approach
2. **Execute Phase 1-2** - Create node and servers
3. **Execute Phase 3-4** - Install PGP components
4. **Execute Phase 5-6** - Deploy and configure
5. **Execute Phase 7-8** - Test functionality
6. **Document results** - Update documentation

---

## Questions to Answer

1. ✅ Do you want node-level or server-level key storage?
2. ✅ Single server or multiple servers?
3. ✅ Should we create a queue manager or use standalone mode?
4. ✅ What ports should we use? (7800/7801 suggested)
5. ✅ Should we automate this in a script?

---

**Ready to proceed?** Let me know and I'll start implementing!