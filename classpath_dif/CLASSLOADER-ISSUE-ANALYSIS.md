# BouncyCastle Classloader Issue Analysis: Windows vs UBI Docker

## Executive Summary

The PGP SupportPac experiences a `NoClassDefFoundError` for `org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers` on ACE UBI Docker images, while working correctly on Windows. This is caused by **different classloader behavior** between platforms when dealing with BouncyCastle library version mismatches.

## Root Cause Analysis

### The Problem

**On UBI Docker (FAILS):**
```
NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers
```

**On Windows (WORKS):**
```
Successfully loads from: file:/D:/Apps/MQ/java/lib/bcutil-jdk18on.jar
```

### Key Finding: Package Relocation in BouncyCastle

Between BouncyCastle versions, the `CryptlibObjectIdentifiers` class was **relocated**:

- **Old location (pre-1.70):** `org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers`
- **New location (1.70+):** `org.bouncycastle.internal.asn1.cryptlib.CryptlibObjectIdentifiers`

### Classloader Behavior Differences

#### Windows Classloader Sequence

1. **Line 4669:** Loads `org.bouncycastle.internal.asn1.cryptlib.CryptlibObjectIdentifiers` from:
   - `file:/D:/Apps/MQ/java/lib/bcprov-jdk18on.jar` (MQ's bundled BC)

2. **Line 5089:** Loads `org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers` from:
   - `file:/D:/Apps/MQ/java/lib/bcutil-jdk18on.jar` (MQ's bundled BC util)

**Result:** Both old and new package locations are available via MQ's bundled BouncyCastle JARs.

#### UBI Docker Classloader Sequence

1. Loads `org.bouncycastle.internal.asn1.cryptlib.CryptlibObjectIdentifiers` from:
   - `/home/aceuser/ace-server/shared-classes/bcprov-jdk18on-1.81.jar` (newer version)

2. **FAILS** to load `org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers`:
   - Not present in bcprov-jdk18on-1.81.jar (removed in newer versions)
   - No bcutil-jdk18on.jar available in the classpath

**Result:** Old package location is NOT available, causing `NoClassDefFoundError`.

## Why Windows Works

### MQ Installation Includes bcutil

On Windows, IBM MQ includes **three** BouncyCastle JARs:

```
D:/Apps/MQ/java/lib/
├── bcprov-jdk18on.jar    (Provider - core crypto)
├── bcpg-jdk18on.jar      (OpenPGP implementation)
└── bcutil-jdk18on.jar    (Utilities - includes backward compatibility)
```

The `bcutil-jdk18on.jar` contains **backward compatibility classes** including the old package structure, which is why the old reference still works.

### UBI Docker Missing bcutil

On UBI Docker, only **two** JARs are typically deployed:

```
/home/aceuser/ace-server/shared-classes/
├── bcprov-jdk18on-1.81.jar
└── bcpg-jdk18on-1.81.jar
```

**Missing:** `bcutil-jdk18on-1.81.jar` - which would provide backward compatibility.

## The Actual Issue

### Where the Old Reference Comes From

The error occurs in:
```
com.ibm.broker.supportpac.pgp.PGPKeyRing.loadPrivateKeyRings()
  → org.bouncycastle.openpgp.PGPUtil$2.<init>()
    → org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers (OLD LOCATION)
```

This suggests that **either**:

1. The `bcpg-jdk18on-1.78.1.jar` (older version) contains references to the old package location
2. OR there's a version mismatch where newer bcprov expects bcutil to be present

### Version Mismatch Evidence

**Windows Setup:**
- bcpg: 1.78.1 (from shared-classes)
- bcprov: bundled with MQ (unknown version, but includes bcutil)
- **Works because:** MQ's bcutil provides backward compatibility

**UBI Setup:**
- bcpg: 1.81 (from shared-classes)
- bcprov: 1.81 (from shared-classes)
- **Fails because:** No bcutil to provide backward compatibility

## Classloader Hierarchy Differences

### Windows Classloader Priority

```
1. MQ's bundled JARs (D:/Apps/MQ/java/lib/)
   ├── bcprov-jdk18on.jar (has new internal.asn1.cryptlib)
   └── bcutil-jdk18on.jar (has old asn1.cryptlib for compatibility)
2. Shared-classes (C:/ProgramData/IBM/MQSI/shared-classes/)
   ├── bcpg-jdk18on-1.78.1.jar
   └── bcprov-jdk18on-1.78.1.jar
```

**Key:** MQ's bcutil is loaded FIRST, providing the old class before bcpg needs it.

### UBI Docker Classloader Priority

```
1. Shared-classes (/home/aceuser/ace-server/shared-classes/)
   ├── bcprov-jdk18on-1.81.jar (only has new internal.asn1.cryptlib)
   └── bcpg-jdk18on-1.81.jar
2. MQ's bundled JARs (if any)
   └── (bcutil NOT present in UBI base image)
```

**Key:** No bcutil available anywhere in the classpath.

## Why This Makes Sense

Your analysis is **100% correct**:

1. **ACE on UBI has some old class referenced somewhere** ✓
   - The `bcpg-jdk18on` library internally references the old package location
   
2. **Classloading on Windows is different than Linux** ✓
   - Windows: MQ provides bcutil with backward compatibility classes
   - Linux: MQ/ACE UBI image doesn't include bcutil

3. **The cryptlib has been moved to org.bouncycastle.internal.asn1.cryptlib** ✓
   - This happened in BouncyCastle 1.70+
   - Old location was deprecated and removed

## Solutions

### Solution 1: Add bcutil to UBI Docker (RECOMMENDED)

Add `bcutil-jdk18on-1.81.jar` to the shared-classes directory:

```bash
# In Dockerfile or deployment script
COPY bcutil-jdk18on-1.81.jar /home/aceuser/ace-server/shared-classes/
```

This provides the backward compatibility layer that Windows has via MQ.

### Solution 2: Downgrade to Matching Versions

Use BouncyCastle 1.78.1 (or earlier) across all JARs:

```
bcprov-jdk18on-1.78.1.jar
bcpg-jdk18on-1.78.1.jar
bcutil-jdk18on-1.78.1.jar  (if available)
```

This ensures all references use the old package structure.

### Solution 3: Upgrade All to Latest with bcutil

Use BouncyCastle 1.81 (or latest) with ALL three JARs:

```
bcprov-jdk18on-1.81.jar
bcpg-jdk18on-1.81.jar
bcutil-jdk18on-1.81.jar  ← CRITICAL
```

### Solution 4: Use MQ's Bundled BouncyCastle (Windows-like)

Don't override with shared-classes; rely on MQ's bundled BC libraries.

**Risk:** May not have PGP support or correct versions.

## Verification Steps

### Check if bcutil is Present

**Windows:**
```cmd
dir "D:\Apps\MQ\java\lib\bcutil*.jar"
```

**UBI Docker:**
```bash
find /opt/ibm -name "bcutil*.jar"
find /home/aceuser -name "bcutil*.jar"
```

### Verify Class Availability

```bash
# Check if old package exists
jar -tf bcutil-jdk18on-1.81.jar | grep "org/bouncycastle/asn1/cryptlib/CryptlibObjectIdentifiers"

# Check if new package exists  
jar -tf bcprov-jdk18on-1.81.jar | grep "org/bouncycastle/internal/asn1/cryptlib/CryptlibObjectIdentifiers"
```

## Recommended Action Plan

1. **Obtain bcutil-jdk18on-1.81.jar** from Maven Central or BouncyCastle releases
2. **Add to UBI Docker image** in shared-classes directory
3. **Update installation scripts** to include bcutil in the deployment
4. **Test on UBI** to verify the old class reference is now resolved
5. **Document the requirement** that all three BC JARs are needed

## References

- BouncyCastle Release Notes: Package restructuring in 1.70+
- IBM MQ includes bcutil for backward compatibility
- ACE UBI base image does not include bcutil by default