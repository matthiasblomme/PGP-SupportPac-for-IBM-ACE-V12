# Node-Managed Integration Server Testing - Revised Implementation Plan

## Overview

This document outlines the step-by-step plan using **ibmint commands** for node-managed testing.

**Date:** 2026-02-16  
**Status:** Planning Phase  
**Estimated Time:** 1-2 hours  
**Approach:** Use ibmint commands (consistent with standalone testing)

---

## Prerequisites Check

```cmd
REM Source ACE environment
call "C:\Program Files\IBM\ACE\13.0.6.0\server\bin\mqsiprofile.cmd"

REM Verify ibmint is available
ibmint --version

REM Check if any nodes exist
ibmint list nodes
```

---

## Phase 1: Create Integration Node (5 minutes)

### Step 1: Create Integration Node

```cmd
ibmint create node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

**Expected Output:**
```
Integration node 'TEST_NODE' created successfully.
```

**Verify:**
```cmd
ibmint list nodes
```

### Step 2: Start Integration Node

```cmd
ibmint start node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

**Expected Output:**
```
Integration node 'TEST_NODE' started successfully.
```

**Verify:**
```cmd
ibmint list nodes
```

---

## Phase 2: Create Integration Servers (10 minutes)

### Step 3: Create SERVER_ENCRYPT

```cmd
ibmint create server SERVER_ENCRYPT --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

**Expected Output:**
```
Integration server 'SERVER_ENCRYPT' created successfully.
```

### Step 4: Create SERVER_DECRYPT

```cmd
ibmint create server SERVER_DECRYPT --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

**Expected Output:**
```
Integration server 'SERVER_DECRYPT' created successfully.
```

**Verify:**
```cmd
ibmint list servers --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

---

## Phase 3: Install PGP SupportPac (10 minutes)

### Step 5: Copy Bouncy Castle JARs to Each Server

**For SERVER_ENCRYPT:**
```cmd
mkdir C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes
copy /Y "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\"
copy /Y "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\"
```

**For SERVER_DECRYPT:**
```cmd
mkdir C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes
copy /Y "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\"
copy /Y "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\"
```

### Step 6: Restart Integration Node

**Important:** Must restart node after installing JARs

```cmd
ibmint stop node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
ibmint start node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

**Verify servers are running:**
```cmd
ibmint list servers --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

---

## Phase 4: Setup Test Directories and Keys (5 minutes)

### Step 7: Use Same Directories as Standalone

We'll use the same test directories that standalone testing uses:
- Keys: `C:\temp\pgp\keys\`
- Input: `C:\temp\pgp\input\`
- Output: `C:\temp\pgp\output\`

**These should already exist from standalone testing. If not:**
```cmd
mkdir C:\temp\pgp\keys
mkdir C:\temp\pgp\input
mkdir C:\temp\pgp\output

REM Copy keys
xcopy /Y "testing\test-resources\Sources\pgp-keys\*.*" "C:\temp\pgp\keys\"
```

---

## Phase 5: Configure HTTP Ports (10 minutes)

### Step 8: Configure SERVER_ENCRYPT Port (7800)

```cmd
REM Create server.conf.yaml for SERVER_ENCRYPT
echo HTTPListener: > C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\overrides\server.conf.yaml
echo   port: 7800 >> C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\overrides\server.conf.yaml
```

### Step 9: Configure SERVER_DECRYPT Port (7801)

```cmd
REM Create server.conf.yaml for SERVER_DECRYPT
echo HTTPListener: > C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\overrides\server.conf.yaml
echo   port: 7801 >> C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\overrides\server.conf.yaml
```

### Step 10: Restart Node to Apply Port Configuration

```cmd
ibmint stop node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
ibmint start node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

**Verify ports:**
```cmd
netstat -ano | findstr ":7800"
netstat -ano | findstr ":7801"
```

---

## Phase 6: Deploy Applications (15 minutes)

### Step 11: Deploy to SERVER_ENCRYPT

```cmd
ibmint deploy ^
  --input-path testing\test-resources\Sources ^
  --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT ^
  --project PGP_Policies ^
  --integration-node TEST_NODE

ibmint deploy ^
  --input-path testing\test-resources\Sources ^
  --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT ^
  --project TestPGP_App ^
  --integration-node TEST_NODE
```

### Step 12: Deploy to SERVER_DECRYPT

```cmd
ibmint deploy ^
  --input-path testing\test-resources\Sources ^
  --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT ^
  --project PGP_Policies ^
  --integration-node TEST_NODE

ibmint deploy ^
  --input-path testing\test-resources\Sources ^
  --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT ^
  --project TestPGP_App ^
  --integration-node TEST_NODE
```

**Verify deployment:**
```cmd
dir C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\run
dir C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\run
```

---

## Phase 7: Testing (15 minutes)

### Step 13: Create Test File

```cmd
echo This is a test file for node-managed PGP encryption > C:\temp\pgp\input\plain.txt
```

### Step 14: Test Encryption on SERVER_ENCRYPT (Port 7800)

```cmd
curl -X POST http://localhost:7800/pgp/encrypt -o C:\temp\pgp\output\encrypted.txt
```

**Expected:** Encrypted PGP message saved to `C:\temp\pgp\output\encrypted.txt`

### Step 15: Test Decryption on SERVER_DECRYPT (Port 7801)

```cmd
curl -X POST http://localhost:7801/pgp/decrypt -o C:\temp\pgp\input\plain-decrypted.txt
```

**Expected:** Decrypted plain text saved to `C:\temp\pgp\input\plain-decrypted.txt`

### Step 16: Verify Results

```cmd
REM Compare files
fc /B C:\temp\pgp\input\plain.txt C:\temp\pgp\input\plain-decrypted.txt
```

**Expected Output:**
```
FC: no differences encountered
```

**Display results:**
```cmd
echo Original file:
type C:\temp\pgp\input\plain.txt

echo.
echo Decrypted file:
type C:\temp\pgp\input\plain-decrypted.txt
```

---

## Phase 8: Verify Node Management (5 minutes)

### Step 17: Check Node Status

```cmd
ibmint list nodes
ibmint list servers --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
```

### Step 18: Check Server Logs

```cmd
REM SERVER_ENCRYPT logs
type C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\log\integration_server.SERVER_ENCRYPT.events.txt

REM SERVER_DECRYPT logs
type C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\log\integration_server.SERVER_DECRYPT.events.txt
```

---

## Phase 9: Cleanup (Optional)

### Step 19: Stop and Remove Test Environment

```cmd
REM Stop integration node (stops all servers)
ibmint stop node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE

REM Remove node directory
rmdir /S /Q C:\temp\pgp-node\TEST_NODE

REM Clean up test files (optional - shared with standalone)
REM rmdir /S /Q C:\temp\pgp
```

---

## Complete Command Summary

### Setup Commands (in order):
```cmd
REM 1. Source ACE environment
call "C:\Program Files\IBM\ACE\13.0.6.0\server\bin\mqsiprofile.cmd"

REM 2. Create and start node
ibmint create node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
ibmint start node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE

REM 3. Create servers
ibmint create server SERVER_ENCRYPT --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
ibmint create server SERVER_DECRYPT --integration-node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE

REM 4. Install Bouncy Castle JARs
mkdir C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes
mkdir C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes
copy /Y "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\"
copy /Y "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\shared-classes\"
copy /Y "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\"
copy /Y "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.81.jar" "C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\shared-classes\"

REM 5. Restart node
ibmint stop node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
ibmint start node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE

REM 6. Configure ports
echo HTTPListener: > C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\overrides\server.conf.yaml
echo   port: 7800 >> C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT\overrides\server.conf.yaml
echo HTTPListener: > C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\overrides\server.conf.yaml
echo   port: 7801 >> C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT\overrides\server.conf.yaml

REM 7. Restart node to apply ports
ibmint stop node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE
ibmint start node TEST_NODE --work-dir C:\temp\pgp-node\TEST_NODE

REM 8. Deploy applications
ibmint deploy --input-path testing\test-resources\Sources --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT --project PGP_Policies --integration-node TEST_NODE
ibmint deploy --input-path testing\test-resources\Sources --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_ENCRYPT --project TestPGP_App --integration-node TEST_NODE
ibmint deploy --input-path testing\test-resources\Sources --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT --project PGP_Policies --integration-node TEST_NODE
ibmint deploy --input-path testing\test-resources\Sources --output-work-directory C:\temp\pgp-node\TEST_NODE\servers\SERVER_DECRYPT --project TestPGP_App --integration-node TEST_NODE
```

### Test Commands:
```cmd
REM Create test file
echo This is a test file for node-managed PGP encryption > C:\temp\pgp\input\plain.txt

REM Test encryption
curl -X POST http://localhost:7800/pgp/encrypt -o C:\temp\pgp\output\encrypted.txt

REM Test decryption
curl -X POST http://localhost:7801/pgp/decrypt -o C:\temp\pgp\input\plain-decrypted.txt

REM Verify
fc /B C:\temp\pgp\input\plain.txt C:\temp\pgp\input\plain-decrypted.txt
```

---

## Key Differences from Standalone

| Aspect | Standalone Server | Node-Managed |
|--------|------------------|--------------|
| **Creation** | `IntegrationServer --work-dir` | `ibmint create node` + `ibmint create server` |
| **Management** | Single server | Node manages multiple servers |
| **Deployment** | Deploy to server work-dir | Deploy to each server under node |
| **Configuration** | Direct server.conf.yaml | server.conf.yaml in overrides/ |
| **Ports** | Single port (7800) | Multiple ports (7800, 7801) |
| **Shared Resources** | N/A | Shared keys/directories |
| **Restart** | Restart server | Restart entire node |

---

## Advantages of Node-Managed Approach

1. ✅ **Centralized Management** - One node manages multiple servers
2. ✅ **Consistent Commands** - All use `ibmint` commands
3. ✅ **Shared Resources** - Keys and directories shared across servers
4. ✅ **Production-like** - Mirrors production node-managed deployments
5. ✅ **Multi-server Testing** - Test encryption and decryption separately

---

## Next Steps

1. **Review this revised plan** - Confirm approach
2. **Create automated script** - `setup-and-test-node.bat`
3. **Execute setup** - Create node and servers
4. **Deploy and test** - Run encryption/decryption tests
5. **Document results** - Update documentation

---

**Ready to implement?** This approach is much simpler and consistent with standalone testing!