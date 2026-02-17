# Solution Implementation Guide: Adding bcutil to Fix UBI Classloader Issue

## Quick Summary

**Problem:** `NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers` on UBI Docker

**Root Cause:** Missing `bcutil-jdk18on.jar` which provides backward compatibility for relocated BouncyCastle classes

**Solution:** Add `bcutil-jdk18on-1.81.jar` to the shared-classes directory on UBI Docker

## Implementation Steps

### Step 1: Obtain bcutil JAR

Download `bcutil-jdk18on-1.81.jar` from Maven Central:

```bash
# Using wget
wget https://repo1.maven.org/maven2/org/bouncycastle/bcutil-jdk18on/1.81/bcutil-jdk18on-1.81.jar

# Using curl
curl -O https://repo1.maven.org/maven2/org/bouncycastle/bcutil-jdk18on/1.81/bcutil-jdk18on-1.81.jar
```

**Maven Coordinates:**
```xml
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcutil-jdk18on</artifactId>
    <version>1.81</version>
</dependency>
```

### Step 2: Update Docker Configuration

#### Option A: Add to Dockerfile

```dockerfile
# In your ACE Dockerfile
FROM cp.icr.io/cp/appc/ace-server:12.0.x.x-r1

# Copy BouncyCastle JARs including bcutil
COPY bcprov-jdk18on-1.81.jar /home/aceuser/ace-server/shared-classes/
COPY bcpg-jdk18on-1.81.jar /home/aceuser/ace-server/shared-classes/
COPY bcutil-jdk18on-1.81.jar /home/aceuser/ace-server/shared-classes/

# Set ownership
RUN chown aceuser:aceuser /home/aceuser/ace-server/shared-classes/*.jar
```

#### Option B: Add to docker-compose.yml Volume Mount

```yaml
services:
  ace-server:
    image: cp.icr.io/cp/appc/ace-server:12.0.x.x-r1
    volumes:
      - ./local-aceuser-home/ace-server/shared-classes:/home/aceuser/ace-server/shared-classes
```

Then copy the JAR to the local directory:
```bash
cp bcutil-jdk18on-1.81.jar ./local-aceuser-home/ace-server/shared-classes/
```

#### Option C: Runtime Copy (for testing)

```bash
# Copy into running container
docker cp bcutil-jdk18on-1.81.jar ace-container:/home/aceuser/ace-server/shared-classes/

# Restart the integration server
docker exec ace-container bash -c "mqsistop ace-server && mqsistart ace-server"
```

### Step 3: Update Installation Scripts

#### For Windows (install-pgp-supportpac.bat)

Add bcutil to the installation:

```batch
@echo off
REM ... existing code ...

echo Copying BouncyCastle libraries to shared-classes...
copy /Y bcprov-jdk18on-1.81.jar "%MQSI_REGISTRY%\shared-classes\"
copy /Y bcpg-jdk18on-1.81.jar "%MQSI_REGISTRY%\shared-classes\"
copy /Y bcutil-jdk18on-1.81.jar "%MQSI_REGISTRY%\shared-classes\"

echo Installation complete!
```

#### For Linux/Docker (install-pgp-supportpac.sh)

Create a new installation script:

```bash
#!/bin/bash

# Installation script for PGP SupportPac on ACE UBI Docker

SHARED_CLASSES_DIR="/home/aceuser/ace-server/shared-classes"
JPLUGIN_DIR="/opt/ibm/ace-12/server/jplugin"
TOOLS_PLUGINS_DIR="/opt/ibm/ace-12/tools/plugins"

echo "Installing PGP SupportPac for IBM ACE..."

# Create directories if they don't exist
mkdir -p "$SHARED_CLASSES_DIR"

# Copy BouncyCastle libraries (ALL THREE)
echo "Copying BouncyCastle libraries..."
cp bcprov-jdk18on-1.81.jar "$SHARED_CLASSES_DIR/"
cp bcpg-jdk18on-1.81.jar "$SHARED_CLASSES_DIR/"
cp bcutil-jdk18on-1.81.jar "$SHARED_CLASSES_DIR/"

# Copy PGP SupportPac JARs
echo "Copying PGP SupportPac JARs..."
cp PGPSupportPacImpl.jar "$JPLUGIN_DIR/"
cp PGPSupportPac.jar "$TOOLS_PLUGINS_DIR/"

# Set permissions
chmod 644 "$SHARED_CLASSES_DIR"/*.jar
chmod 644 "$JPLUGIN_DIR/PGPSupportPacImpl.jar"
chmod 644 "$TOOLS_PLUGINS_DIR/PGPSupportPac.jar"

echo "Installation complete!"
echo "Please restart the integration server for changes to take effect."
```

### Step 4: Verification

#### Verify JAR is Present

```bash
# In Docker container
ls -lh /home/aceuser/ace-server/shared-classes/

# Expected output:
# bcprov-jdk18on-1.81.jar
# bcpg-jdk18on-1.81.jar
# bcutil-jdk18on-1.81.jar
```

#### Verify Class is Available

```bash
# Check if the old package location exists in bcutil
jar -tf /home/aceuser/ace-server/shared-classes/bcutil-jdk18on-1.81.jar | \
  grep "org/bouncycastle/asn1/cryptlib/CryptlibObjectIdentifiers"

# Expected output:
# org/bouncycastle/asn1/cryptlib/CryptlibObjectIdentifiers.class
```

#### Test PGP Encryption

```bash
# Deploy test application
mqsideploy ace-server -a TestPGP.bar

# Send test message
# (use your existing test procedure)
```

### Step 5: Update Documentation

Update the following files to document the bcutil requirement:

1. **INSTALLATION.md** - Add bcutil to prerequisites
2. **README.md** - Mention all three BouncyCastle JARs are required
3. **Docker README** - Update deployment instructions

## Complete BouncyCastle JAR Set

Always deploy **all three** BouncyCastle JARs together:

| JAR | Purpose | Required |
|-----|---------|----------|
| `bcprov-jdk18on-1.81.jar` | Core cryptographic provider | ✓ Yes |
| `bcpg-jdk18on-1.81.jar` | OpenPGP implementation | ✓ Yes |
| `bcutil-jdk18on-1.81.jar` | Utilities & backward compatibility | ✓ Yes |

## Version Compatibility Matrix

| ACE Version | Java Version | BouncyCastle Version | bcutil Required |
|-------------|--------------|---------------------|-----------------|
| ACE 12.0.x | Java 17 | 1.78.1+ | Yes (for UBI) |
| ACE 12.0.x | Java 17 | 1.81 | Yes (for UBI) |
| ACE 13.0.x | Java 21 | 1.81+ | Yes (for UBI) |

## Troubleshooting

### Issue: Still Getting NoClassDefFoundError

**Check:**
1. Verify bcutil JAR is in shared-classes directory
2. Verify JAR version matches bcprov and bcpg versions
3. Restart integration server after adding JAR
4. Check file permissions (should be readable by aceuser)

```bash
# Check permissions
ls -l /home/aceuser/ace-server/shared-classes/bcutil-jdk18on-1.81.jar

# Should show: -rw-r--r-- aceuser aceuser
```

### Issue: Wrong Version of bcutil

**Symptoms:** Different NoClassDefFoundError or version conflicts

**Solution:** Ensure all three JARs are the **same version**:

```bash
# Check versions
ls -1 /home/aceuser/ace-server/shared-classes/bc*.jar
# All should end with same version number (e.g., 1.81.jar)
```

### Issue: JAR Not Being Loaded

**Check classloader output:**

```bash
# Enable verbose class loading
export MQSI_JVMENV_EXTRA_OPTIONS="-verbose:class"

# Restart and check logs
grep "bcutil" /home/aceuser/ace-server/log/*.txt
```

## Alternative: Use Older BouncyCastle Version

If bcutil is not available, you can use an older BouncyCastle version (1.70 or earlier) that still has the old package structure:

```bash
# Use version 1.70 (last version before package relocation)
bcprov-jdk18on-1.70.jar
bcpg-jdk18on-1.70.jar
# bcutil not needed for 1.70
```

**Note:** This is not recommended as you lose security updates and bug fixes.

## Testing Checklist

- [ ] bcutil-jdk18on-1.81.jar copied to shared-classes
- [ ] File permissions set correctly (readable by aceuser)
- [ ] Integration server restarted
- [ ] PGP encryption test successful
- [ ] PGP decryption test successful
- [ ] No NoClassDefFoundError in logs
- [ ] Classloader trace shows bcutil classes being loaded

## Rollback Procedure

If issues occur after adding bcutil:

```bash
# Remove bcutil
rm /home/aceuser/ace-server/shared-classes/bcutil-jdk18on-1.81.jar

# Restart integration server
mqsistop ace-server
mqsistart ace-server
```

## Next Steps

1. Update all deployment scripts to include bcutil
2. Update CI/CD pipelines to include bcutil in Docker builds
3. Document the requirement in team knowledge base
4. Test on all environments (dev, test, prod)
5. Create monitoring alerts for NoClassDefFoundError

## References

- [BouncyCastle Downloads](https://www.bouncycastle.org/latest_releases.html)
- [Maven Central - bcutil](https://mvnrepository.com/artifact/org.bouncycastle/bcutil-jdk18on)
- [CLASSLOADER-ISSUE-ANALYSIS.md](./CLASSLOADER-ISSUE-ANALYSIS.md) - Detailed root cause analysis