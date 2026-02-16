# Docker Testing Architecture - Revised for ACE Container Behavior

## Critical Understanding: ACE Official Images Auto-Start

**Key Insight**: Official IBM ACE Docker images automatically start a Standalone Integration Server (SIS) on container startup. This requires a specific workflow to install and test the PGP SupportPac.

---

## Revised Container Architecture

### Volume Mappings (Critical)

The docker-compose configuration MUST map these directories to enable JAR installation and runtime access:

```yaml
volumes:
  # ACE Installation Directory - for installing PGP SupportPac JARs
  - ./local-ace-install:/opt/ibm/ace-13/server
  
  # ACE User Home - for integration server runtime and shared-classes
  - ./local-aceuser-home:/home/aceuser
  
  # Source code (read-only)
  - ./:/tmp/pgp-supportpac:ro
```

**Directory Structure After Mapping**:
```
local-ace-install/
└── jplugin/
    └── PGPSupportPacImpl.jar          # Installed here

local-aceuser-home/
├── aceserver/                          # Auto-created SIS
│   ├── shared-classes/
│   │   ├── bcpg-jdk18on-1.78.1.jar   # Installed here
│   │   └── bcprov-jdk18on-1.78.1.jar # Installed here
│   ├── run/                           # Deployed applications
│   └── log/                           # Server logs
└── pgp/                               # Test files
    ├── keys/                          # PGP repositories
    ├── input/                         # Test input
    └── output/                        # Test output
```

---

## Revised Test Workflow

### Phase 1: Container Startup (Automatic)
```
Container Start → ACE SIS Auto-Starts → Wait for Ready
```

The official ACE image automatically:
1. Creates integration server at `/home/aceuser/aceserver`
2. Starts the server
3. Exposes HTTP listener on port 7800
4. Exposes Admin API on port 7600

### Phase 2: Stop Server for Installation
```bash
#!/bin/bash
# Stop the auto-started SIS (Standalone Integration Server)
# Note: mqsistop doesn't work for SIS, must kill the process
pkill -f IntegrationServer

# Wait for clean shutdown
sleep 5
```

**Why Stop?**: Must stop server to:
- Install JARs safely
- Copy shared-classes libraries
- Avoid file locking issues

### Phase 3: Install PGP SupportPac
```bash
#!/bin/bash
# Install PGP SupportPac JARs
cp /tmp/pgp-supportpac/MQSI_BASE_FILEPATH/server/jplugin/PGPSupportPacImpl.jar \
   /opt/ibm/ace-13/server/jplugin/

# Install Bouncy Castle JARs to server shared-classes
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcpg-jdk18on-1.78.1.jar \
   /home/aceuser/aceserver/shared-classes/
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcprov-jdk18on-1.78.1.jar \
   /home/aceuser/aceserver/shared-classes/

# Set proper permissions
chmod 644 /opt/ibm/ace-13/server/jplugin/PGPSupportPacImpl.jar
chmod 644 /home/aceuser/aceserver/shared-classes/*.jar
```

### Phase 4: Setup Test Environment
```bash
#!/bin/bash
# Create test directories (matching containerOverrides.properties paths)
mkdir -p /home/aceuser/pgp-test/keys
mkdir -p /home/aceuser/pgp-test/input
mkdir -p /home/aceuser/pgp-test/output

# Copy PGP keys
cp /tmp/pgp-supportpac/Test\ Project/Sources/pgp-keys/* \
   /home/aceuser/pgp-test/keys/

# Set permissions
chmod 600 /home/aceuser/pgp-test/keys/*-private*.pgp
chmod 644 /home/aceuser/pgp-test/keys/*-public*.pgp
```

### Phase 5: Deploy Applications
```bash
#!/bin/bash
# Deploy using ibmint with existing container deployment descriptor
cd /tmp/pgp-supportpac/Test\ Project/Sources

# Deploy PGP_Policies (no deployment descriptor needed)
ibmint deploy \
  --input-path . \
  --output-work-directory /home/aceuser/aceserver \
  --project PGP_Policies

# Deploy TestPGP_App with existing containerOverrides.properties
ibmint deploy \
  --input-path . \
  --output-work-directory /home/aceuser/aceserver \
  --project TestPGP_App \
  --deployment-descriptor Deploymentdescriptors/containerOverrides.properties
```

**Why Deployment Descriptor for App?**: Container paths differ from Windows:
- Windows: `C:\temp\pgp\`
- Container: `/home/aceuser/pgp-test/`
- Existing file: `Test Project/Sources/Deploymentdescriptors/containerOverrides.properties`

### Phase 6: Restart Server
```bash
#!/bin/bash
# Start the integration server
mqsistart aceserver

# Wait for server to be ready
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if curl -f http://localhost:7800/ 2>/dev/null; then
    echo "Server is ready"
    break
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done
```

### Phase 7: Run Tests
```bash
#!/bin/bash
# Create test input file (matching containerOverrides.properties paths)
echo "This is a test file for PGP encryption" > /home/aceuser/pgp-test/input/plain.txt

# Test encryption
curl -X POST http://localhost:7800/pgp/encrypt \
  -o /home/aceuser/pgp-test/output/encrypted.txt

# Verify encrypted file created
if [ ! -f /home/aceuser/pgp-test/output/encrypted.txt ]; then
  echo "ERROR: Encryption failed"
  exit 1
fi

# Test decryption
curl -X POST http://localhost:7800/pgp/decrypt \
  -o /home/aceuser/pgp-test/input/plain-decrypted.txt

# Verify decrypted file created
if [ ! -f /home/aceuser/pgp-test/input/plain-decrypted.txt ]; then
  echo "ERROR: Decryption failed"
  exit 1
fi

# Compare files
if diff /home/aceuser/pgp-test/input/plain.txt \
        /home/aceuser/pgp-test/input/plain-decrypted.txt; then
  echo "SUCCESS: Files match!"
  exit 0
else
  echo "ERROR: Files do not match"
  exit 1
fi
```

---

## Deployment Descriptor for Container

### Existing File: `Test Project/Sources/Deploymentdescriptors/containerOverrides.properties`

This file already exists in the repository and contains the container-specific path overrides:

```properties
pgp.decrypt#PGP Decrypter.inputDirectory = /home/aceuser/pgp-test/output
pgp.decrypt#PGP Decrypter.outputDirectory = /home/aceuser/pgp-test/input
pgp.decrypt#PGP Decrypter.pgpPolicy = {PGP_Policies}:PGP-RCV-CFG-SERVICE-CONTAINER
pgp.decrypt#HTTP Input.URLSpecifier = /pgp/decrypt
pgp.decrypt#File Read.inputDirectory = /home/aceuser/pgp-test/

pgp.encrypt#PGP Encrypter.inputDirectory = /home/aceuser/pgp-test/input
pgp.encrypt#PGP Encrypter.outputDirectory = /home/aceuser/pgp-test/output
pgp.encrypt#PGP Encrypter.pgpPolicy = {PGP_Policies}:PGP-SDR-CFG-SERVICE-CONTAINER
pgp.encrypt#File Read.inputDirectory = /home/aceuser/pgp-test/
```

**Note**: The policies referenced are `PGP-SDR-CFG-SERVICE-CONTAINER` and `PGP-RCV-CFG-SERVICE-CONTAINER`. These need to be created in the PGP_Policies project with container-specific paths.

### Required: Container-Specific Policy Files

Create these policy files in `Test Project/Sources/PGP_Policies/`:

**File: `PGP-SDR-CFG-SERVICE-CONTAINER.policyxml`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<policies>
  <policy policyType="UserDefined" policyName="PGP-SDR-CFG-SERVICE-CONTAINER">
    <PrivateKeyRepository>/home/aceuser/pgp-test/keys/sender-private-repository.pgp</PrivateKeyRepository>
    <PublicKeyRepository>/home/aceuser/pgp-test/keys/sender-public-repository.pgp</PublicKeyRepository>
    <DefaultDecryptionKeyPassphrase>passw0rd</DefaultDecryptionKeyPassphrase>
    <DefaultSignKeyPassphrase>passw0rd</DefaultSignKeyPassphrase>
    <DefaultSignKeyUserId>Sender <sender@testpgp.com></DefaultSignKeyUserId>
  </policy>
</policies>
```

**File: `PGP-RCV-CFG-SERVICE-CONTAINER.policyxml`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<policies>
  <policy policyType="UserDefined" policyName="PGP-RCV-CFG-SERVICE-CONTAINER">
    <PrivateKeyRepository>/home/aceuser/pgp-test/keys/receiver-private-repository.pgp</PrivateKeyRepository>
    <PublicKeyRepository>/home/aceuser/pgp-test/keys/receiver-public-repository.pgp</PublicKeyRepository>
    <DefaultDecryptionKeyPassphrase>passw0rd</DefaultDecryptionKeyPassphrase>
    <DefaultSignKeyPassphrase>passw0rd</DefaultSignKeyPassphrase>
    <DefaultSignKeyUserId>Receiver <receiver@testpgp.com></DefaultSignKeyUserId>
  </policy>
</policies>
```

---

## Revised docker-compose.test.yml

```yaml
version: '3.8'

services:
  ace-pgp-test:
    image: icr.io/appc/ace:13.0.6.0-r1
    container_name: ace-pgp-test
    hostname: ace-pgp-test
    
    environment:
      - LICENSE=accept
      - ACE_SERVER_NAME=aceserver
      - ACE_ENABLE_METRICS=false
      - LOG_FORMAT=basic
    
    ports:
      - "7800:7800"  # HTTP listener
      - "7600:7600"  # Admin REST API
    
    volumes:
      # Map ACE installation for JAR installation
      - ./local-ace-install:/opt/ibm/ace-13/server
      
      # Map aceuser home for runtime access
      - ./local-aceuser-home:/home/aceuser
      
      # Mount source code (read-only)
      - ./:/tmp/pgp-supportpac:ro
      
      # Mount test script
      - ./docker/run-tests.sh:/tmp/run-tests.sh:ro
    
    # Override entrypoint to run our test script
    entrypoint: ["/bin/bash"]
    command: ["/tmp/run-tests.sh"]
    
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7800/"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    
    networks:
      - ace-test-network

networks:
  ace-test-network:
    driver: bridge
```

**Key Changes**:
1. ✅ Maps `/opt/ibm/ace-13/server` to local directory
2. ✅ Maps `/home/aceuser` to local directory
3. ✅ Overrides entrypoint to run custom test script
4. ✅ Uses official ACE image directly (no custom Dockerfile needed)

---

## Complete Test Script: docker/run-tests.sh

```bash
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Error handler
error_exit() {
  log_error "$1"
  log_error "Check logs at: /home/aceuser/aceserver/log/"
  exit 1
}

log_info "=========================================="
log_info "PGP SupportPac Docker Test"
log_info "=========================================="

# Step 1: Wait for auto-started server to be ready
log_step "Step 1: Waiting for auto-started ACE server..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if [ -f /home/aceuser/aceserver/server.conf.yaml ]; then
    log_info "Server configuration found"
    break
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

if [ $elapsed -ge $timeout ]; then
  error_exit "Timeout waiting for server initialization"
fi

# Give server a moment to fully start
sleep 5

# Step 2: Stop the auto-started server
log_step "Step 2: Stopping auto-started server for installation..."
mqsistop aceserver || log_warn "Server may not have been running"
sleep 5
log_info "Server stopped"

# Step 3: Install PGP SupportPac JARs
log_step "Step 3: Installing PGP SupportPac JARs..."

# Install server plugin
if [ ! -d /opt/ibm/ace-13/server/jplugin ]; then
  mkdir -p /opt/ibm/ace-13/server/jplugin
fi
cp /tmp/pgp-supportpac/MQSI_BASE_FILEPATH/server/jplugin/PGPSupportPacImpl.jar \
   /opt/ibm/ace-13/server/jplugin/ || error_exit "Failed to copy PGPSupportPacImpl.jar"
chmod 644 /opt/ibm/ace-13/server/jplugin/PGPSupportPacImpl.jar
log_info "Installed PGPSupportPacImpl.jar"

# Install Bouncy Castle JARs to server shared-classes
if [ ! -d /home/aceuser/aceserver/shared-classes ]; then
  mkdir -p /home/aceuser/aceserver/shared-classes
fi
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcpg-jdk18on-1.78.1.jar \
   /home/aceuser/aceserver/shared-classes/ || error_exit "Failed to copy bcpg JAR"
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcprov-jdk18on-1.78.1.jar \
   /home/aceuser/aceserver/shared-classes/ || error_exit "Failed to copy bcprov JAR"
chmod 644 /home/aceuser/aceserver/shared-classes/*.jar
log_info "Installed Bouncy Castle JARs"

# Step 4: Setup test environment
log_step "Step 4: Setting up test environment..."

# Create test directories (matching containerOverrides.properties)
mkdir -p /home/aceuser/pgp-test/keys
mkdir -p /home/aceuser/pgp-test/input
mkdir -p /home/aceuser/pgp-test/output
log_info "Created test directories"

# Copy PGP keys
cp /tmp/pgp-supportpac/Test\ Project/Sources/pgp-keys/* \
   /home/aceuser/pgp-test/keys/ || error_exit "Failed to copy PGP keys"
chmod 600 /home/aceuser/pgp-test/keys/*-private*.pgp
chmod 600 /home/aceuser/pgp-test/keys/*-private*.asc
chmod 644 /home/aceuser/pgp-test/keys/*-public*.pgp
chmod 644 /home/aceuser/pgp-test/keys/*-public*.asc
log_info "Copied PGP keys"

# Step 5: Deploy applications
log_step "Step 5: Deploying applications..."

cd /tmp/pgp-supportpac/Test\ Project/Sources

# Deploy PGP_Policies (no deployment descriptor needed)
log_info "Deploying PGP_Policies..."
ibmint deploy \
  --input-path . \
  --output-work-directory /home/aceuser/aceserver \
  --project PGP_Policies \
  || error_exit "Failed to deploy PGP_Policies"
log_info "Deployed PGP_Policies"

# Deploy TestPGP_App with existing containerOverrides.properties
log_info "Deploying TestPGP_App with containerOverrides.properties..."
ibmint deploy \
  --input-path . \
  --output-work-directory /home/aceuser/aceserver \
  --project TestPGP_App \
  --deployment-descriptor Deploymentdescriptors/containerOverrides.properties \
  || error_exit "Failed to deploy TestPGP_App"
log_info "Deployed TestPGP_App"

# Step 6: Start the server
log_step "Step 6: Starting integration server..."
mqsistart aceserver || error_exit "Failed to start server"

# Wait for server to be ready
log_info "Waiting for server to be ready..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if curl -f http://localhost:7800/ 2>/dev/null; then
    log_info "Server is ready"
    break
  fi
  sleep 2
  elapsed=$((elapsed + 2))
done

if [ $elapsed -ge $timeout ]; then
  error_exit "Timeout waiting for server to start"
fi

# Give flows time to initialize
sleep 5

# Step 7: Run encryption test
log_step "Step 7: Testing encryption..."

# Create test input file (matching containerOverrides.properties paths)
echo "This is a test file for PGP encryption" > /home/aceuser/pgp-test/input/plain.txt
log_info "Created test input file"

# Test encryption
curl -X POST http://localhost:7800/pgp/encrypt \
  -o /home/aceuser/pgp-test/output/encrypted.txt \
  -w "\nHTTP Status: %{http_code}\n" \
  || error_exit "Encryption request failed"

# Verify encrypted file created
if [ ! -f /home/aceuser/pgp-test/output/encrypted.txt ]; then
  error_exit "Encrypted file not created"
fi

# Check if file is not empty
if [ ! -s /home/aceuser/pgp-test/output/encrypted.txt ]; then
  error_exit "Encrypted file is empty"
fi

log_info "Encryption test passed"

# Step 8: Run decryption test
log_step "Step 8: Testing decryption..."

# Test decryption
curl -X POST http://localhost:7800/pgp/decrypt \
  -o /home/aceuser/pgp-test/input/plain-decrypted.txt \
  -w "\nHTTP Status: %{http_code}\n" \
  || error_exit "Decryption request failed"

# Verify decrypted file created
if [ ! -f /home/aceuser/pgp-test/input/plain-decrypted.txt ]; then
  error_exit "Decrypted file not created"
fi

# Check if file is not empty
if [ ! -s /home/aceuser/pgp-test/input/plain-decrypted.txt ]; then
  error_exit "Decrypted file is empty"
fi

log_info "Decryption test passed"

# Step 9: Verify results
log_step "Step 9: Verifying results..."

# Compare files
if diff /home/aceuser/pgp-test/input/plain.txt \
        /home/aceuser/pgp-test/input/plain-decrypted.txt > /dev/null 2>&1; then
  log_info "Files match perfectly!"
else
  error_exit "Original and decrypted files do not match"
fi

# Step 10: Display results
log_step "Step 10: Test Results"
echo ""
echo "Original file:"
cat /home/aceuser/pgp-test/input/plain.txt
echo ""
echo "Decrypted file:"
cat /home/aceuser/pgp-test/input/plain-decrypted.txt
echo ""

# Check server logs for errors
if grep -i "BIP.*E:" /home/aceuser/aceserver/log/*.txt > /dev/null 2>&1; then
  log_warn "Errors found in server logs:"
  grep -i "BIP.*E:" /home/aceuser/aceserver/log/*.txt | tail -10
else
  log_info "No errors in server logs"
fi

log_info "=========================================="
log_info "ALL TESTS PASSED! ✓"
log_info "=========================================="

# Keep server running for inspection if needed
log_info "Server is still running. Container will stay alive."
log_info "To inspect: docker exec -it ace-pgp-test bash"
log_info "To stop: docker stop ace-pgp-test"

# Keep container alive
tail -f /dev/null
```

---

## Windows Test Script: test-docker-local.bat

```batch
@echo off
setlocal enabledelayedexpansion

echo ============================================================================
echo PGP SupportPac Docker Test - Local Execution
echo ============================================================================
echo.

REM Check if Docker is running
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop.
    exit /b 1
)
echo [OK] Docker is running

REM Create local directories for volume mapping
echo.
echo [INFO] Creating local directories for volume mapping...
if not exist "local-ace-install\server\jplugin" mkdir "local-ace-install\server\jplugin"
if not exist "local-aceuser-home" mkdir "local-aceuser-home"
echo [OK] Directories created

REM Check if IBM Container Registry login is needed
echo.
echo [INFO] Checking IBM Container Registry access...
docker pull icr.io/appc/ace:13.0.6.0-r1 >nul 2>&1
if errorlevel 1 (
    echo [WARN] Cannot pull ACE image. You may need to login:
    echo   docker login icr.io -u cp -p YOUR_IBM_ENTITLEMENT_KEY
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" exit /b 1
)

REM Start docker-compose
echo.
echo [INFO] Starting Docker container...
docker-compose -f docker-compose.test.yml up --abort-on-container-exit

REM Check exit code
if errorlevel 1 (
    echo.
    echo [ERROR] Tests failed!
    echo [INFO] Container is still running for inspection.
    echo [INFO] To inspect: docker exec -it ace-pgp-test bash
    echo [INFO] To view logs: docker logs ace-pgp-test
    echo [INFO] To stop: docker stop ace-pgp-test
    echo.
    set /p cleanup="Remove container? (y/n): "
    if /i "!cleanup!"=="y" (
        docker-compose -f docker-compose.test.yml down -v
    )
    exit /b 1
) else (
    echo.
    echo [SUCCESS] All tests passed!
    echo.
    set /p cleanup="Remove container? (y/n): "
    if /i "!cleanup!"=="y" (
        docker-compose -f docker-compose.test.yml down -v
        echo [OK] Container removed
    ) else (
        echo [INFO] Container kept for inspection
        echo [INFO] To remove: docker-compose -f docker-compose.test.yml down -v
    )
)

endlocal
```

---

## Key Changes Summary

### ✅ Volume Mappings
- Map `/opt/ibm/ace-13/server` for JAR installation
- Map `/home/aceuser` for runtime and shared-classes access
- Enables installation from host machine

### ✅ Server Lifecycle Management
1. Wait for auto-started server
2. Stop server for installation
3. Install JARs and libraries
4. Deploy with container deployment descriptors
5. Restart server
6. Run tests

### ✅ Deployment Descriptors
- Container-specific paths (`/home/aceuser/pgp/`)
- Override policy properties for Linux paths
- Override flow properties for Linux directories

### ✅ Test Script
- Handles ACE auto-start behavior
- Proper error handling
- Detailed logging
- Keeps container alive for inspection

---

## Files to Create

### New Files
1. `docker-compose.test.yml` - Revised with volume mappings
2. `docker/run-tests.sh` - Complete test script
3. `test-docker-local.bat` - Windows test runner
4. `Test Project/Sources/PGP_Policies/PGP-SDR-CFG-SERVICE-CONTAINER.policyxml` - Container-specific sender policy
5. `Test Project/Sources/PGP_Policies/PGP-RCV-CFG-SERVICE-CONTAINER.policyxml` - Container-specific receiver policy

### Existing Files (Already Present)
1. `Test Project/Sources/Deploymentdescriptors/containerOverrides.properties` - Application deployment descriptor

### Updated Files
1. `DOCKER-TESTING-PLAN.md` - Update with revised architecture
2. `DOCKER-TESTING-QUICKSTART.md` - Update with new workflow
3. `DOCKER-TESTING-SUMMARY.md` - Update with corrections

---

## Testing Checklist

### Pre-Test
- [ ] Docker Desktop running
- [ ] IBM Container Registry access configured
- [ ] Local directories created (`local-ace-install`, `local-aceuser-home`)
- [ ] Deployment descriptors created

### During Test
- [ ] Container starts successfully
- [ ] Auto-started server detected
- [ ] Server stops cleanly
- [ ] JARs install successfully
- [ ] PGP keys copied
- [ ] Applications deploy with descriptors
- [ ] Server restarts successfully
- [ ] HTTP endpoints respond
- [ ] Encryption test passes
- [ ] Decryption test passes
- [ ] Files match

### Post-Test
- [ ] No errors in server logs
- [ ] Container accessible for inspection
- [ ] Cleanup works correctly

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 2.0.0 | 2026-02-13 | IBM Bob | Revised for ACE auto-start behavior |

---

**End of Revised Architecture**