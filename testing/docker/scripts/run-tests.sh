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
  log_error "Check logs at: /home/aceuser/ace-server/log/"
  exit 1
}

log_info "=========================================="
log_info "PGP SupportPac Docker Test"
log_info "=========================================="

# Find and source ACE environment
ACE_DIR=$(find /opt/ibm -name "ace-*" -type d | head -1)
if [ -z "$ACE_DIR" ]; then
  error_exit "ACE installation directory not found"
fi
log_info "Found ACE at: $ACE_DIR"

# Source ACE environment
if [ -f "$ACE_DIR/server/bin/mqsiprofile" ]; then
  source "$ACE_DIR/server/bin/mqsiprofile"
  log_info "ACE environment loaded"
else
  error_exit "mqsiprofile not found at $ACE_DIR/server/bin/mqsiprofile"
fi

# Step 1: Start the integration server initially to create directory structure
log_step "Step 1: Starting integration server to initialize..."

# Clean up any old overrides that might cause issues
rm -f /home/aceuser/ace-server/overrides/server.conf.yaml 2>/dev/null

IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server &
SERVER_PID=$!
log_info "Server started with PID: $SERVER_PID"

# Wait for server to initialize
log_info "Waiting for server to initialize..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
  if [ -f /home/aceuser/ace-server/server.conf.yaml ]; then
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

# Step 2: Stop the server for installation
log_step "Step 2: Stopping server for installation..."
kill $SERVER_PID || pkill -f IntegrationServer
sleep 5
log_info "Server stopped"

# Step 3: Install PGP SupportPac JARs
log_step "Step 3: Installing PGP SupportPac JARs..."

# Find ACE installation directory
ACE_DIR=$(find /opt/ibm -name "ace-*" -type d | head -1)
if [ -z "$ACE_DIR" ]; then
  error_exit "ACE installation directory not found"
fi
log_info "Found ACE at: $ACE_DIR"

# Install server plugin
if [ ! -d "$ACE_DIR/server/jplugin" ]; then
  mkdir -p "$ACE_DIR/server/jplugin"
fi
cp /tmp/pgp-supportpac/MQSI_BASE_FILEPATH/server/jplugin/PGPSupportPacImpl.jar \
   "$ACE_DIR/server/jplugin/" || error_exit "Failed to copy PGPSupportPacImpl.jar"
chmod 644 "$ACE_DIR/server/jplugin/PGPSupportPacImpl.jar"
log_info "Installed PGPSupportPacImpl.jar"

# Install Bouncy Castle bcpg JAR to ACE's MQ lib directory
# ACE already has bcprov 1.81 in /opt/ibm/ace-13/server/MQ/lib/ but is missing bcpg
# We need to add bcpg to the same location so they're loaded together
log_info "Installing bcpg JAR to ACE MQ lib directory..."
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcpg-jdk18on-1.81.jar \
   /opt/ibm/ace-13/server/MQ/lib/ || error_exit "Failed to copy bcpg JAR to MQ lib"

log_info "Installed bcpg-jdk18on-1.81.jar to /opt/ibm/ace-13/server/MQ/lib/"
log_info "Bouncy Castle JARs in MQ lib:"
ls -la /opt/ibm/ace-13/server/MQ/lib/bc*.jar

# Step 4: Setup test environment
log_step "Step 4: Setting up test environment..."

# Create test directories (matching containerOverrides.properties)
mkdir -p /home/aceuser/pgp-test/keys
mkdir -p /home/aceuser/pgp-test/input
mkdir -p /home/aceuser/pgp-test/output
log_info "Created test directories"

# Copy PGP keys
cp /tmp/pgp-supportpac/testing/test-resources/Sources/pgp-keys/* \
   /home/aceuser/pgp-test/keys/ || error_exit "Failed to copy PGP keys"
chmod 600 /home/aceuser/pgp-test/keys/*-private*.pgp
chmod 600 /home/aceuser/pgp-test/keys/*-private*.asc
chmod 644 /home/aceuser/pgp-test/keys/*-public*.pgp
chmod 644 /home/aceuser/pgp-test/keys/*-public*.asc
log_info "Copied PGP keys"

# Note: server.conf.yaml is no longer needed as Bouncy Castle JARs are in shared-classes
log_info "Bouncy Castle JARs will be loaded from shared-classes directory"

# Step 5: Deploy applications
log_step "Step 5: Deploying applications..."

cd /tmp/pgp-supportpac/testing/test-resources/Sources

# Deploy PGP_Policies (no deployment descriptor needed)
log_info "Deploying PGP_Policies..."
ibmint deploy \
  --input-path . \
  --output-work-directory /home/aceuser/ace-server \
  --project PGP_Policies \
  || error_exit "Failed to deploy PGP_Policies"
log_info "Deployed PGP_Policies"

# Deploy TestPGP_App with existing containerOverrides.properties
log_info "Deploying TestPGP_App with containerOverrides.properties..."
ibmint deploy \
  --input-path . \
  --output-work-directory /home/aceuser/ace-server \
  --project TestPGP_App \
  --overrides-file Deploymentdescriptors/containerOverrides.properties \
  || error_exit "Failed to deploy TestPGP_App"
log_info "Deployed TestPGP_App"

# Step 6: Start the server
log_step "Step 6: Starting integration server..."

# Clean up any stale lock files from previous runs
rm -f /home/aceuser/ace-server/config/.lock 2>/dev/null
log_info "Cleaned up lock files"

# Start server and capture output to a log file
mkdir -p /tmp/server-logs
IntegrationServer --work-dir /home/aceuser/ace-server --name ace-server > /tmp/server-logs/server-startup.log 2>&1 &
SERVER_PID=$!
log_info "Server restarted with PID: $SERVER_PID"

# Wait for server to be ready
log_info "Waiting for server to be ready..."
timeout=60
elapsed=0
while [ $elapsed -lt $timeout ]; do
  # Check if the server initialization message appears in the captured log
  if grep -q "BIP1991I: Integration server has finished initialization" /tmp/server-logs/server-startup.log 2>/dev/null; then
    log_info "Server is ready (initialization complete)"
    break
  fi
  sleep 2
  elapsed=$((elapsed + 2))
  if [ $((elapsed % 10)) -eq 0 ]; then
    log_info "Still waiting... ($elapsed seconds elapsed)"
  fi
done

if [ $elapsed -ge $timeout ]; then
  log_error "Timeout waiting for server to start"
  log_error "Last 20 lines of server log:"
  tail -20 /tmp/server-logs/server-startup.log
  error_exit "Server failed to start"
fi

# Give flows time to initialize
sleep 5

# Step 7: Run encryption test
log_step "Step 7: Testing encryption..."

# Create test input file (matching containerOverrides.properties paths)
echo "This is a test file for PGP encryption" > /home/aceuser/pgp-test/input/plain.txt
log_info "Created test input file"

# Test encryption
HTTP_CODE=$(curl -X POST http://localhost:7800/pgp/encrypt \
  -o /home/aceuser/pgp-test/output/encrypted.txt \
  -w "%{http_code}" \
  -s)

echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
  log_error "Encryption failed with HTTP $HTTP_CODE"
  log_error "Response content:"
  cat /home/aceuser/pgp-test/output/encrypted.txt
  log_error "Server logs:"
  tail -50 /tmp/server-logs/server-startup.log
  error_exit "Encryption test failed"
fi

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
HTTP_CODE=$(curl -X POST http://localhost:7800/pgp/decrypt \
  -o /home/aceuser/pgp-test/input/plain-decrypted.txt \
  -w "%{http_code}" \
  -s)

echo "HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" != "200" ]; then
  log_error "Decryption failed with HTTP $HTTP_CODE"
  log_error "Response content:"
  cat /home/aceuser/pgp-test/input/plain-decrypted.txt
  log_error "Server logs:"
  tail -50 /tmp/server-logs/server-startup.log
  error_exit "Decryption test failed"
fi

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
if grep -i "BIP.*E:" /home/aceuser/ace-server/log/*.txt > /dev/null 2>&1; then
  log_warn "Errors found in server logs:"
  grep -i "BIP.*E:" /home/aceuser/ace-server/log/*.txt | tail -10
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