# Implementation Complete: bcutil Added to Docker Testing

## Summary

Successfully implemented the fix for the BouncyCastle classloader issue on UBI Docker by adding `bcutil-jdk18on-1.81.jar` to the repository and updating the Docker test script.

## Changes Made

### 1. Downloaded bcutil JAR ✓

**File:** `MQSI_REGISTRY/shared-classes/bcutil-jdk18on-1.81.jar`

**Size:** 705,888 bytes (689 KB)

**Source:** Maven Central Repository

**Command Used:**
```bash
curl -L -o bcutil-jdk18on-1.81.jar https://repo1.maven.org/maven2/org/bouncycastle/bcutil-jdk18on/1.81/bcutil-jdk18on-1.81.jar
```

**Verification:**
```
Directory of MQSI_REGISTRY\shared-classes:
- bcpg-jdk18on-1.81.jar     (728,364 bytes)
- bcprov-jdk18on-1.81.jar   (8,948,201 bytes)
- bcutil-jdk18on-1.81.jar   (705,888 bytes)  ← NEW
```

### 2. Updated Docker Test Script ✓

**File:** `testing/docker/scripts/run-tests.sh`

**Lines Modified:** 97-114

**Changes:**
- Updated comments to mention both bcpg and bcutil
- Split JAR installation into two separate copy operations
- Added bcutil copy command with error handling
- Added log message for bcutil installation
- Updated final log message to reflect "All BouncyCastle JARs"

**Before:**
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

**After:**
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

## What This Fixes

### The Problem
On UBI Docker containers, the PGP SupportPac was failing with:
```
NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers
```

### Root Cause
- BouncyCastle 1.70+ relocated classes from `org.bouncycastle.asn1.cryptlib` to `org.bouncycastle.internal.asn1.cryptlib`
- The `bcpg` library still references the old package location
- Windows works because MQ bundles `bcutil` which provides backward compatibility
- UBI Docker was missing `bcutil`, causing the classloader to fail

### The Solution
Adding `bcutil-jdk18on-1.81.jar` provides the backward compatibility layer, allowing both old and new package references to work.

## Testing

### Expected Behavior After Fix

When running `test-docker-local.bat`, you should see:

```
[INFO] Installing BouncyCastle JARs to ACE MQ lib directory...
[INFO] Installed bcpg-jdk18on-1.81.jar
[INFO] Installed bcutil-jdk18on-1.81.jar
[INFO] All BouncyCastle JARs installed to /opt/ibm/ace-13/server/MQ/lib/
[INFO] Bouncy Castle JARs in MQ lib:
-rw-r--r-- 1 root root  728364 ... bcpg-jdk18on-1.81.jar
-rw-r--r-- 1 root root 8948201 ... bcprov-jdk18on-1.81.jar
-rw-r--r-- 1 root root  705888 ... bcutil-jdk18on-1.81.jar
```

### Verification Steps

1. **Check JARs are present:**
   ```bash
   docker exec -it ace-pgp-test ls -lh /opt/ibm/ace-13/server/MQ/lib/bc*.jar
   ```

2. **Verify no ClassNotFound errors:**
   ```bash
   docker exec -it ace-pgp-test grep -i "NoClassDefFoundError" /home/aceuser/ace-server/log/*.txt
   # Should return no results
   ```

3. **Test encryption/decryption:**
   - Both tests should pass with HTTP 200 responses
   - No errors in server logs

## Files Modified

1. ✓ `MQSI_REGISTRY/shared-classes/bcutil-jdk18on-1.81.jar` (added)
2. ✓ `testing/docker/scripts/run-tests.sh` (modified)

## Documentation Created

1. ✓ `classpath_dif/CLASSLOADER-ISSUE-ANALYSIS.md` - Root cause analysis
2. ✓ `classpath_dif/SOLUTION-IMPLEMENTATION-GUIDE.md` - General solution guide
3. ✓ `classpath_dif/BCUTIL-IMPLEMENTATION-PLAN.md` - Specific implementation plan
4. ✓ `classpath_dif/IMPLEMENTATION-COMPLETE.md` - This file

## Next Steps

### Immediate
1. Test the changes by running `test-docker-local.bat`
2. Verify no `NoClassDefFoundError` in logs
3. Confirm encryption and decryption tests pass

### Future
1. Update main documentation (`INSTALLATION.md`, `README.md`) to mention bcutil requirement
2. Add bcutil to any other deployment scripts (if needed)
3. Consider adding a verification step in installation scripts to check all three JARs are present

## Rollback (if needed)

If issues occur:

```bash
# Remove bcutil
rm MQSI_REGISTRY/shared-classes/bcutil-jdk18on-1.81.jar

# Revert script changes
git checkout testing/docker/scripts/run-tests.sh
```

## Notes

- **Windows installations do NOT need changes** - MQ already bundles bcutil
- **Only Docker/UBI environments** required this fix
- All three BouncyCastle JARs must be version 1.81 (matching)
- The bcutil JAR is approximately 689 KB

## Related Issues

- Resolves: `NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers`
- Platform: UBI Docker containers only
- ACE Version: 12.0.x and 13.0.x
- BouncyCastle Version: 1.81

## Success Criteria Met

- [x] bcutil JAR downloaded and added to repository
- [x] Docker test script updated to copy bcutil
- [x] Changes documented
- [x] Ready for testing

---

**Implementation Date:** 2026-02-17  
**Implemented By:** AI Assistant (Code Mode)  
**Status:** ✅ Complete - Ready for Testing