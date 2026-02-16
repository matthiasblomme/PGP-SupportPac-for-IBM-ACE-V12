# Standalone Integration Server Testing

Test the PGP SupportPac on a local Windows system with IBM ACE installed.

## Overview

This testing approach uses a Standalone Integration Server (SIS) running directly on Windows. It provides the most production-like testing environment for Windows deployments.

**Status:** ✅ Fully Implemented and Tested  
**Last Tested:** 2026-02-12  
**ACE Version:** 13.0.6.0

## Quick Start

### Prerequisites

- ✅ IBM ACE 13.0.6.0 installed on Windows
- ✅ PGP SupportPac installed (see [Installation Guide](../../INSTALLATION.md))
- ✅ Administrator privileges (recommended)
- ✅ Command Prompt or PowerShell

### Run Tests (Automated)

```cmd
cd testing\standalone-server
deploy_and_test.bat
```

**Time:** ~10-15 minutes

The script will:
1. Create test directories
2. Copy PGP keys
3. Copy Bouncy Castle JARs
4. Deploy policies and application
5. Start integration server
6. Run encryption/decryption tests
7. Verify results

## What Gets Tested

### 1. Environment Setup
- Test directory creation (`C:\temp\pgp\`)
- PGP key deployment
- Bouncy Castle JAR installation

### 2. Server Deployment
- Integration server creation
- Policy deployment
- Application deployment
- Server startup and initialization

### 3. Encryption Test
- HTTP endpoint: `POST http://localhost:7800/pgp/encrypt`
- Reads: `C:\temp\pgp\input\plain.txt`
- Writes: `C:\temp\pgp\output\encrypted.txt`
- Uses: Receiver's public key

### 4. Decryption Test
- HTTP endpoint: `POST http://localhost:7801/pgp/decrypt`
- Reads: `C:\temp\pgp\output\encrypted.txt`
- Writes: `C:\temp\pgp\input\plain-decrypted.txt`
- Uses: Receiver's private key

### 5. Verification
- Compares original and decrypted files
- Checks for errors in server logs
- Validates HTTP endpoints

## Directory Structure

```
standalone-server/
├── README.md (this file)
├── deploy_and_test.bat           # Automated test script
├── TEST-SETUP-WALKTHROUGH.md     # Detailed manual walkthrough
└── docs/                         # Additional documentation
    ├── SIS-TESTING-QUICKSTART.md
    ├── SIS-TESTING-ARCHITECTURE.md
    └── SIS-TESTING-SUMMARY.md
```

## Test Configuration

### Server Configuration
- **Server Name:** TEST_SERVER_PGP
- **Work Directory:** `C:\temp\pgp\TEST_SERVER_PGP`
- **HTTP Port:** 7800
- **Admin Port:** 7600

### File Locations
- **Test Files:** `C:\temp\pgp\`
- **PGP Keys:** `C:\temp\pgp\keys\`
- **Input Files:** `C:\temp\pgp\input\`
- **Output Files:** `C:\temp\pgp\output\`

### Policy Configuration
- **Sender Policy:** `PGP-SDR-CFG-SERVICE`
- **Receiver Policy:** `PGP-RCV-CFG-SERVICE`
- **Passphrase:** `passw0rd`
- **Key Repositories:** Local file system paths

## Manual Testing

For step-by-step manual testing, see:
📖 [TEST-SETUP-WALKTHROUGH.md](TEST-SETUP-WALKTHROUGH.md)

The walkthrough includes:
- Detailed explanations of each step
- Screenshots and examples
- Troubleshooting guidance
- ACE Toolkit integration
- Manual deployment procedures

## Script Details

### deploy_and_test.bat

**What it does:**
1. Sets up test environment
2. Copies required files
3. Deploys ACE components
4. Starts integration server
5. Runs tests
6. Reports results

**Configuration Variables:**
```batch
ACE_VERSION=13.0.6.0
SERVER_NAME=TEST_SERVER_PGP
SERVER_WORK_DIR=C:\temp\pgp\TEST_SERVER_PGP
HTTP_PORT=7800
ADMIN_PORT=7600
```

**Customization:**
Edit the script to change:
- ACE version
- Server name
- Port numbers
- Directory locations

## Test Results

### Expected Output

```
============================================================================
PGP SupportPac Deployment and Test Script
============================================================================

[Step 1/10] Setting up test directories...
[OK] Test directories created

[Step 2/10] Copying PGP keys to test directory...
[OK] PGP keys copied successfully

...

[Step 10/10] Testing PGP encryption and decryption...
[TEST 1] Testing encryption flow...
[OK] Encryption test completed

[TEST 2] Testing decryption flow...
[OK] Decryption test completed

============================================================================
Test Results
============================================================================

Original file:
This is a test file for PGP encryption

Decrypted file:
This is a test file for PGP encryption

[SUCCESS] Original and decrypted files match perfectly!

============================================================================
Deployment and Testing Complete!
============================================================================
```

## Troubleshooting

### Issue: "ACE not found"

**Symptom:**
```
ACE installation not found at: C:\Program Files\IBM\ACE\13.0.6.0
```

**Solution:**
Specify ACE path explicitly:
```cmd
set ACE_HOME=C:\path\to\your\ACE
deploy_and_test.bat
```

### Issue: "Port already in use"

**Symptom:**
```
[WARNING] HTTP listener not found on port 7800
```

**Solution:**
1. Check what's using the port:
   ```cmd
   netstat -ano | findstr :7800
   ```
2. Stop the conflicting service
3. Or edit script to use different port

### Issue: "Deployment failed"

**Symptom:**
```
[ERROR] Deployment failed
```

**Solution:**
1. Check ACE environment is set up:
   ```cmd
   mqsilist
   ```
2. Verify test-resources directory exists
3. Check server logs:
   ```cmd
   type C:\temp\pgp\TEST_SERVER_PGP\log\integration_server.TEST_SERVER_PGP.events.txt
   ```

### Issue: "Encryption/Decryption failed"

**Symptom:**
```
[ERROR] Encryption test failed
```

**Solution:**
1. Verify server is running (check console window)
2. Check application is deployed:
   ```cmd
   curl http://localhost:7800/
   ```
3. Review server logs for errors
4. Verify PGP keys are in correct location

### Issue: "Files don't match"

**Symptom:**
```
[WARNING] Original and decrypted files do not match!
```

**Solution:**
1. Check encryption completed successfully
2. Verify correct keys are being used
3. Check passphrase in policies
4. Review server logs for PGP errors

## Advanced Usage

### Custom Test Files

To test with your own files:

1. Place file in `C:\temp\pgp\input\plain.txt`
2. Run encryption test:
   ```cmd
   curl -X POST http://localhost:7800/pgp/encrypt
   ```
3. Run decryption test:
   ```cmd
   curl -X POST http://localhost:7800/pgp/decrypt
   ```

### Using ACE Toolkit

1. Import project from `testing/test-resources/TestPgp_ProjectInterchange.zip`
2. Deploy to your integration server
3. Test using Flow Exerciser or HTTP client

### Different ACE Versions

To test with different ACE versions:

1. Edit `deploy_and_test.bat`
2. Change `ACE_VERSION` variable
3. Ensure PGP SupportPac is installed for that version

## Comparison with Other Testing

| Feature | Standalone Server | Docker | Node-Managed |
|---------|------------------|--------|--------------|
| **Setup** | Medium | Easy | Complex |
| **Speed** | Fast | Medium | Slow |
| **Isolation** | Medium | High | Low |
| **Production-like** | High | Medium | Very High |
| **Debugging** | Easy | Medium | Easy |
| **ACE Toolkit** | Yes | No | Yes |

**Use Standalone Server when:**
- You have ACE installed locally
- You need to debug with ACE Toolkit
- You want production-like testing
- You prefer local file system access

## Integration with Development

### Pre-Commit Testing

Add to your development workflow:

```cmd
REM Before committing changes
cd testing\standalone-server
deploy_and_test.bat
if errorlevel 1 (
    echo Tests failed! Fix before committing.
    exit /b 1
)
```

### Continuous Testing

Run tests after code changes:

```cmd
REM Watch for changes and test
cd testing\standalone-server
:loop
deploy_and_test.bat
timeout /t 300
goto loop
```

## Cleanup

### Stop Server

```cmd
REM Close the TEST_SERVER_PGP console window
REM Or:
taskkill /F /FI "WINDOWTITLE eq TEST_SERVER_PGP*"
```

### Remove Test Files

```cmd
rmdir /S /Q C:\temp\pgp
```

### Remove Server

```cmd
rmdir /S /Q C:\temp\pgp\TEST_SERVER_PGP
```

## Related Documentation

- 📖 [Detailed Walkthrough](TEST-SETUP-WALKTHROUGH.md) - Step-by-step manual guide
- 📖 [Test Resources](../test-resources/README.md) - Shared test files
- 📖 [Docker Testing](../docker/README.md) - Alternative approach
- 📖 [Testing Overview](../docs/TESTING-OVERVIEW.md) - All testing approaches
- 📖 [Installation Guide](../../INSTALLATION.md) - PGP SupportPac installation

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [TEST-SETUP-WALKTHROUGH.md](TEST-SETUP-WALKTHROUGH.md)
3. Check server logs
4. Open GitHub issue with:
   - Script output
   - Server logs
   - Environment details

---

**Last Updated:** 2026-02-16  
**Status:** ✅ Production Ready