# BouncyCastle Classloader Issue - UBI Docker Fix

## Quick Summary

**Issue:** `NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers` on ACE UBI Docker

**Root Cause:** Missing `bcutil-jdk18on.jar` which provides backward compatibility for relocated BouncyCastle classes

**Solution:** Added `bcutil-jdk18on-1.81.jar` to repository and updated Docker test script

**Status:** ✅ Fixed - Implementation Complete

## Files in This Directory

### Core Documentation
- **IMPLEMENTATION-COMPLETE.md** - Summary of changes made and testing instructions
- **CLASSLOADER-ISSUE-ANALYSIS.md** - Detailed root cause analysis with classloader traces

### Reference Files
- **classloader_trace_windows.txt** - Classloader output from Windows (working)
- **classloader_trace_ubi.txt** - Classloader output from UBI Docker (failing)
- **CAPTURE-ALL-OUTPUT-GUIDE.md** - Guide for capturing Java verbose output

### Archive (Planning Documents)
- **SOLUTION-IMPLEMENTATION-GUIDE.md** - Original solution guide (superseded by IMPLEMENTATION-COMPLETE.md)
- **BCUTIL-IMPLEMENTATION-PLAN.md** - Original implementation plan (completed)

## Quick Reference

### The Problem
```
NoClassDefFoundError: org.bouncycastle.asn1.cryptlib.CryptlibObjectIdentifiers
```

### Why It Happened
- BouncyCastle 1.70+ moved classes: `org.bouncycastle.asn1.cryptlib` → `org.bouncycastle.internal.asn1.cryptlib`
- Windows: MQ bundles `bcutil` with backward compatibility ✓
- UBI Docker: Missing `bcutil` ✗

### The Fix
Added all three BouncyCastle JARs to `MQSI_REGISTRY/shared-classes/`:
- bcprov-jdk18on-1.81.jar (core provider)
- bcpg-jdk18on-1.81.jar (OpenPGP)
- bcutil-jdk18on-1.81.jar (utilities + backward compatibility) ← NEW

### Testing
```bash
cd testing/docker
test-docker-local.bat
```

## Key Insights

1. **Platform Difference:** Windows works because MQ bundles bcutil; UBI Docker doesn't
2. **Classloader Behavior:** Different classloader hierarchies between platforms
3. **Backward Compatibility:** bcutil provides old package structure for compatibility
4. **Version Matching:** All three JARs must be the same version (1.81)

## For More Details

- See **IMPLEMENTATION-COMPLETE.md** for full implementation details
- See **CLASSLOADER-ISSUE-ANALYSIS.md** for technical deep-dive
- See classloader trace files for raw debugging data