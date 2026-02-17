# bcutil Implementation Plan for Docker Testing

## Overview

This document outlines the changes needed to add `bcutil-jdk18on-1.81.jar` to the Docker testing setup to resolve the classloader issue on UBI.

## Files to Modify

### 1. Add bcutil JAR to Repository

**Location:** `MQSI_REGISTRY/shared-classes/`

**Action:** Download and add `bcutil-jdk18on-1.81.jar`

**Download Command:**
```bash
cd MQSI_REGISTRY/shared-classes/
wget https://repo1.maven.org/maven2/org/bouncycastle/bcutil-jdk18on/1.81/bcutil-jdk18on-1.81.jar
```

**Verification:**
```bash
ls -lh MQSI_REGISTRY/shared-classes/bc*.jar
# Should show:
# bcpg-jdk18on-1.81.jar
# bcprov-jdk18on-1.81.jar
# bcutil-jdk18on-1.81.jar
```

### 2. Update Docker Test Script

**File:** `testing/docker/scripts/run-tests.sh`

**Current Code (lines 97-106):**
```bash
# Install Bouncy Castle bcpg JAR to ACE's MQ lib directory
# ACE already has bcprov 1.81 in /opt/ibm/ace-13/server/MQ/lib/ but is missing bcpg
# We need to add bcpg to the same location so they're loaded together
log_info "Installing bcpg JAR to ACE MQ lib directory..."
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcpg-jdk18on-1.81.jar \
   /opt/ibm/ace-13/server/MQ/lib/ || error_exit "Failed to copy bcpg JAR to MQ lib"

log_info "Installed bcpg-jdk18on-1.81.jar to /opt/ibm/ace-13/server/MQ/lib/"
log_info "Bouncy Castle JARs in MQ lib:"
ls -la /opt/ibm/ace-13/server/MQ/lib/bc*.jar
```

**Updated Code:**
```bash
# Install Bouncy Castle JARs to ACE's MQ lib directory
# ACE already has bcprov 1.81 in /opt/ibm/ace-13/server/MQ/lib/ but is missing bcpg and bcutil
# We need to add bcpg and bcutil to the same location so they're loaded together
log_info "Installing BouncyCastle JARs to ACE MQ lib directory..."

# Copy bcpg
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcpg-jdk18on-1.81.jar \
   /opt/ibm/ace-13/server/MQ/lib/ || error_exit "Failed to copy bcpg JAR to MQ lib"
log_info "Installed bcpg-jdk18on-1.81.jar"

# Copy bcutil (provides backward compatibility for relocated classes)
cp /tmp/pgp-supportpac/MQSI_REGISTRY/shared-classes/bcutil-jdk18on-1.81.jar \
   /opt/ibm/ace-13/server/MQ/lib/ || error_exit "Failed to copy bcutil JAR to MQ lib"
log_info "Installed bcutil-jdk18on-1.81.jar"

log_info "All BouncyCastle JARs installed to /opt/ibm/ace-13/server/MQ/lib/"
log_info "Bouncy Castle JARs in MQ lib:"
ls -la /opt/ibm/ace-13/server/MQ/lib/bc*.jar
```

**Explanation of Changes:**
1. Updated comment to mention both bcpg and bcutil
2. Split the copy operations into two separate commands for clarity
3. Added log message for bcutil installation
4. Updated final log message to reflect "All BouncyCastle JARs"

### 3. Update Documentation

**Files to Update:**

#### A. `testing/docker/README.md`

Add note about bcutil requirement in the "How It Works" section:

```markdown
### BouncyCastle Libraries

The PGP SupportPac requires **three** BouncyCastle JARs:

1. **bcprov-jdk18on-1.81.jar** - Core cryptographic provider (bundled with ACE)
2. **bcpg-jdk18on-1.81.jar** - OpenPGP implementation (added by test script)
3. **bcutil-jdk18on-1.81.jar** - Utilities and backward compatibility (added by test script)

**Note:** The `bcutil` JAR is critical for UBI Docker environments as it provides backward compatibility for relocated BouncyCastle classes. Without it, you'll encounter `NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers`.
```

#### B. `INSTALLATION.md`

Update the BouncyCastle section to mention bcutil:

```markdown
### BouncyCastle Libraries

The PGP SupportPac requires the following BouncyCastle libraries:

- `bcprov-jdk18on-1.81.jar` - Core cryptographic provider
- `bcpg-jdk18on-1.81.jar` - OpenPGP implementation  
- `bcutil-jdk18on-1.81.jar` - Utilities and backward compatibility

**Important for Docker/Linux:** The `bcutil` JAR is essential for UBI-based containers to provide backward compatibility for relocated BouncyCastle classes.
```

#### C. `testing/docker/docs/DOCKER-TESTING-ARCHITECTURE-REVISED.md`

Update the installation section to include bcutil.

## Implementation Steps

### Step 1: Download bcutil JAR

```bash
# From repository root
cd MQSI_REGISTRY/shared-classes/

# Download bcutil
wget https://repo1.maven.org/maven2/org/bouncycastle/bcutil-jdk18on/1.81/bcutil-jdk18on-1.81.jar

# Verify download
ls -lh bcutil-jdk18on-1.81.jar
# Should show approximately 1.5 MB file

# Verify it's a valid JAR
jar -tf bcutil-jdk18on-1.81.jar | grep "CryptlibObjectIdentifiers"
# Should show: org/bouncycastle/asn1/cryptlib/CryptlibObjectIdentifiers.class
```

### Step 2: Update run-tests.sh

Edit `testing/docker/scripts/run-tests.sh`:

1. Locate lines 97-106 (the bcpg installation section)
2. Replace with the updated code shown above
3. Save the file

### Step 3: Test the Changes

```bash
# From repository root
cd testing/docker

# Run the test
test-docker-local.bat

# Expected result: Tests should pass without NoClassDefFoundError
```

### Step 4: Verify in Container

```bash
# Connect to running container
docker exec -it ace-pgp-test bash

# Check JARs are present
ls -lh /opt/ibm/ace-13/server/MQ/lib/bc*.jar

# Should show:
# bcpg-jdk18on-1.81.jar
# bcprov-jdk18on-1.81.jar
# bcutil-jdk18on-1.81.jar

# Verify class is available
jar -tf /opt/ibm/ace-13/server/MQ/lib/bcutil-jdk18on-1.81.jar | \
  grep "org/bouncycastle/asn1/cryptlib/CryptlibObjectIdentifiers"
```

### Step 5: Update Documentation

Update the three documentation files mentioned above with the bcutil information.

## Rollback Plan

If issues occur:

```bash
# Remove bcutil from repository
rm MQSI_REGISTRY/shared-classes/bcutil-jdk18on-1.81.jar

# Revert run-tests.sh changes
git checkout testing/docker/scripts/run-tests.sh

# Rebuild and test
cd testing/docker
test-docker-local.bat
```

## Success Criteria

- [ ] `bcutil-jdk18on-1.81.jar` present in `MQSI_REGISTRY/shared-classes/`
- [ ] `run-tests.sh` updated to copy bcutil to MQ lib directory
- [ ] Docker tests pass without `NoClassDefFoundError`
- [ ] All three BouncyCastle JARs visible in container at `/opt/ibm/ace-13/server/MQ/lib/`
- [ ] Documentation updated to mention bcutil requirement
- [ ] No errors in server logs related to BouncyCastle classes

## Notes

- **Windows installations do NOT need this change** - MQ already bundles bcutil
- **Only Docker/UBI environments** require the explicit bcutil installation
- The bcutil JAR is approximately 1.5 MB in size
- Version must match bcprov and bcpg (all 1.81)

## Related Documents

- [`CLASSLOADER-ISSUE-ANALYSIS.md`](./CLASSLOADER-ISSUE-ANALYSIS.md) - Root cause analysis
- [`SOLUTION-IMPLEMENTATION-GUIDE.md`](./SOLUTION-IMPLEMENTATION-GUIDE.md) - General solution guide