# Testing Directory Migration Guide

## Overview

The PGP SupportPac testing structure has been reorganized to provide better organization and support multiple testing approaches.

**Migration Date:** 2026-02-16  
**Impact:** Medium - Path changes required

---

## What Changed

### Directory Structure

**Before:**
```
PGP-SupportPac-for-IBM-ACE-V12/
├── docker-testing/              # Docker tests
├── Test Project/                # Mixed: sources + scripts
│   ├── Scripts/
│   │   └── deploy_and_test.bat
│   └── Sources/
└── TEST-SETUP-WALKTHROUGH-ACE-13.md
```

**After:**
```
PGP-SupportPac-for-IBM-ACE-V12/
├── testing/                     # Unified testing root
│   ├── README.md               # Main testing guide
│   ├── test-resources/         # Shared resources
│   │   └── Sources/
│   ├── docker/                 # Docker testing
│   ├── standalone-server/      # SIS testing
│   │   ├── deploy_and_test.bat
│   │   └── TEST-SETUP-WALKTHROUGH.md
│   └── node-managed-server/    # Future
└── [other files unchanged]
```

### Key Changes

1. ✅ **New `testing/` root directory** - All testing in one place
2. ✅ **Shared `test-resources/`** - Common test files
3. ✅ **Organized by test type** - Docker, Standalone, Node-managed
4. ✅ **Consistent documentation** - Each type has README + docs
5. ✅ **Updated paths** - Scripts reference new locations

---

## Migration Steps

### For Users

#### If You Use Docker Testing

**Old command:**
```cmd
cd docker-testing
test-docker-local.bat
```

**New command:**
```cmd
cd testing\docker
test-docker-local.bat
```

**Changes:**
- Directory moved from `docker-testing/` to `testing/docker/`
- All functionality remains the same
- Scripts automatically updated

#### If You Use Standalone Server Testing

**Old command:**
```cmd
cd "Test Project\Scripts"
deploy_and_test.bat
```

**New command:**
```cmd
cd testing\standalone-server
deploy_and_test.bat
```

**Changes:**
- Script moved from `Test Project/Scripts/` to `testing/standalone-server/`
- Script updated to use `testing/test-resources/Sources/`
- All functionality remains the same

#### If You Reference Test Files

**Old paths:**
```
Test Project/Sources/
Test Project/TestPGP/
```

**New paths:**
```
testing/test-resources/Sources/
testing/test-resources/TestPGP/
```

**Action Required:**
- Update any custom scripts that reference these paths
- Update documentation that links to test files

### For Developers

#### If You Have Custom Scripts

**Update path references:**

```batch
REM Old
set SOURCES_DIR=%PROJECT_ROOT%\Test Project\Sources

REM New
set SOURCES_DIR=%PROJECT_ROOT%\testing\test-resources\Sources
```

#### If You Import Test Projects

**Old:**
```
Import from: Test Project/TestPgp_ProjectInterchange.zip
```

**New:**
```
Import from: testing/test-resources/TestPgp_ProjectInterchange.zip
```

#### If You Reference Documentation

**Old links:**
- `docker-testing/README.md`
- `TEST-SETUP-WALKTHROUGH-ACE-13.md`

**New links:**
- `testing/docker/README.md`
- `testing/standalone-server/TEST-SETUP-WALKTHROUGH.md`

---

## Detailed Path Mappings

### Files Moved

| Old Location | New Location | Notes |
|--------------|--------------|-------|
| `docker-testing/` | `testing/docker/` | Entire directory moved |
| `Test Project/Scripts/deploy_and_test.bat` | `testing/standalone-server/deploy_and_test.bat` | Script updated |
| `Test Project/Sources/` | `testing/test-resources/Sources/` | Copied (original kept temporarily) |
| `Test Project/TestPGP/` | `testing/test-resources/TestPGP/` | Copied (original kept temporarily) |
| `TEST-SETUP-WALKTHROUGH-ACE-13.md` | `testing/standalone-server/TEST-SETUP-WALKTHROUGH.md` | Moved from root |

### Files Created

| New File | Purpose |
|----------|---------|
| `testing/README.md` | Main testing guide |
| `testing/test-resources/README.md` | Test resources documentation |
| `testing/standalone-server/README.md` | SIS testing guide |
| `testing/node-managed-server/README.md` | Future testing placeholder |
| `testing/docs/*.md` | Unified documentation |
| `TESTING-RESTRUCTURE-PLAN.md` | This migration plan |

### Files Updated

| File | Changes |
|------|---------|
| `testing/standalone-server/deploy_and_test.bat` | Updated paths to test-resources |
| `testing/docker/docker-compose.yml` | Updated volume mount path |
| `testing/docker/scripts/run-tests.sh` | Updated test-resources paths |

---

## Backward Compatibility

### Cleanup Complete (2026-02-16)

The old directories have been **removed** to maintain a clean repository:

- ❌ `docker-testing/` - Removed (use `testing/docker/`)
- ❌ `Test Project/` - Removed (use `testing/test-resources/` and `testing/standalone-server/`)
- ✅ `TEST-SETUP-WALKTHROUGH-ACE-13.md` still in root (historical reference)

**All users must now use the new `testing/` structure.**

### Breaking Changes

None - old structure remains functional during transition.

### Deprecation Timeline

1. **Now (2026-02-16):** New structure available, old structure works
2. **Future release:** Old structure marked deprecated
3. **Later release:** Old structure removed

---

## Testing Your Migration

### Verify Docker Testing

```cmd
cd testing\docker
test-docker-local.bat
```

**Expected:** Tests run successfully

### Verify Standalone Testing

```cmd
cd testing\standalone-server
deploy_and_test.bat
```

**Expected:** Tests run successfully

### Verify Test Resources

```cmd
dir testing\test-resources\Sources
```

**Expected:** See PGP_Policies, TestPGP_App, pgp-keys, etc.

---

## Troubleshooting Migration

### Issue: "Directory not found"

**Symptom:**
```
The system cannot find the path specified.
```

**Solution:**
1. Verify you're in the repository root
2. Check directory exists: `dir testing`
3. Pull latest changes: `git pull`

### Issue: "Test resources not found"

**Symptom:**
```
[ERROR] Failed to copy PGP keys
```

**Solution:**
1. Verify test-resources exists: `dir testing\test-resources`
2. Check Sources directory: `dir testing\test-resources\Sources`
3. Re-run setup if needed

### Issue: "Old paths in custom scripts"

**Symptom:**
Custom scripts fail with path errors

**Solution:**
Update your scripts:
```batch
REM Find and replace
Test Project\Sources → testing\test-resources\Sources
docker-testing → testing\docker
```

---

## Benefits of New Structure

### ✅ Better Organization
- All testing in one place
- Clear separation by test type
- Consistent structure

### ✅ Easier to Find
- Single entry point: `testing/README.md`
- Logical hierarchy
- Better documentation

### ✅ Scalable
- Easy to add new test types
- Room for future enhancements
- Modular design

### ✅ Professional
- Industry best practices
- Similar to other projects
- Easier for contributors

---

## Getting Help

### Documentation

- 📖 [Testing Overview](testing/README.md)
- 📖 [Docker Testing](testing/docker/README.md)
- 📖 [Standalone Testing](testing/standalone-server/README.md)
- 📖 [Test Resources](testing/test-resources/README.md)

### Support

1. Check this migration guide
2. Review test-specific README files
3. Open GitHub issue if problems persist

### Reporting Issues

When reporting migration issues, include:
- What you were trying to do
- Old path you were using
- Error messages
- Your environment (Windows version, ACE version)

---

## FAQ

### Q: Do I need to reinstall PGP SupportPac?

**A:** No, installation is unchanged. Only testing structure changed.

### Q: Will my existing tests break?

**A:** No, old structure still works. Update paths when convenient.

### Q: Can I use both old and new paths?

**A:** Yes, during transition period. Recommend switching to new paths.

### Q: What about CI/CD pipelines?

**A:** Update paths in your pipeline configuration:
- `docker-testing/` → `testing/docker/`

### Q: Are test results different?

**A:** No, same tests, same results. Only organization changed.

### Q: When will old structure be removed?

**A:** Not yet decided. Will be announced in advance.

---

## Checklist

Use this checklist to verify your migration:

- [ ] Can run Docker tests from `testing/docker/`
- [ ] Can run Standalone tests from `testing/standalone-server/`
- [ ] Test resources accessible at `testing/test-resources/`
- [ ] Updated any custom scripts with new paths
- [ ] Updated any documentation with new links
- [ ] Verified tests still pass
- [ ] Team members informed of changes

---

## Rollback

If you need to rollback to old structure:

```cmd
REM Use old paths
cd docker-testing
cd "Test Project\Scripts"
```

Old structure remains functional during transition.

---

## Summary

**What to do:**
1. ✅ Use `testing/docker/` instead of `docker-testing/`
2. ✅ Use `testing/standalone-server/` instead of `Test Project/Scripts/`
3. ✅ Update custom scripts if any
4. ✅ Update documentation links

**What stays the same:**
- ✅ Test functionality
- ✅ Test results
- ✅ PGP SupportPac installation
- ✅ ACE configuration

**Questions?**
- Check [testing/README.md](testing/README.md)
- Open GitHub issue

---

**Migration Guide Version:** 1.0  
**Last Updated:** 2026-02-16  
**Status:** Active