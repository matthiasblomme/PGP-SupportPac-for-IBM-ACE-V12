# Testing Directory Cleanup Plan

## Overview

After successfully restructuring the testing directories and verifying all functionality works, the old directories should be removed to avoid confusion and maintain a clean repository structure.

## Current Status

### ✅ New Structure (Complete and Verified)
```
testing/
├── docker/                    # Moved from docker-testing/
├── standalone-server/         # Moved from Test Project/Scripts/
├── node-managed-server/       # New implementation
└── test-resources/            # Moved from Test Project/Sources/
```

### ❌ Old Structure (Redundant)
```
docker-testing/                # Should be removed
Test Project/                  # Should be removed
```

## Directories to Remove

### 1. `docker-testing/` Directory
**Status:** Complete duplicate of `testing/docker/`

**Contents:**
- docker-compose.yml
- README.md
- IMPLEMENTATION-COMPLETE.md
- test-docker-local.bat
- scripts/run-tests.sh
- docs/ (4 markdown files)
- local-ace-install/
- local-aceuser-home/

**Action:** Delete entire directory

### 2. `Test Project/` Directory
**Status:** Contents moved to `testing/test-resources/` and `testing/standalone-server/`

**Contents:**
- Sources/ → Moved to `testing/test-resources/Sources/`
- TestPGP/ → Moved to `testing/test-resources/TestPGP/`
- TestPgp_ProjectInterchange.zip → Moved to `testing/test-resources/`
- Scripts/deploy_and_test.bat → Moved to `testing/standalone-server/`

**Action:** Delete entire directory

## Documentation Updates Required

### Files Referencing `docker-testing/`
1. `docker-testing/README.md` (will be deleted)
2. `docker-testing/IMPLEMENTATION-COMPLETE.md` (will be deleted)
3. `TESTING-RESTRUCTURE-PLAN.md` (historical, can keep as-is)
4. `testing/RESTRUCTURE-COMPLETE.md` (historical, can keep as-is)
5. `testing/MIGRATION-GUIDE.md` (update to reflect cleanup)
6. `testing/docker/IMPLEMENTATION-COMPLETE.md` (update references)
7. `testing/docker/README.md` (update directory structure example)

### Files Referencing `Test Project/`
1. `TESTING-RESTRUCTURE-PLAN.md` (historical, can keep as-is)
2. `testing/RESTRUCTURE-COMPLETE.md` (historical, can keep as-is)
3. `testing/MIGRATION-GUIDE.md` (update to reflect cleanup)
4. `testing/docker/README.md` (update policy file locations)
5. `testing/docker/IMPLEMENTATION-COMPLETE.md` (update file locations)
6. `testing/docker/docs/*.md` (update references)
7. `README.md` (update project structure)
8. `POLICY-CONFIGURATION-SUMMARY.md` (update file paths)

## Cleanup Steps

### Step 1: Verify New Structure Works
- [x] Docker testing verified
- [x] Standalone server testing verified
- [x] Node-managed server testing verified
- [x] All scripts use new paths

### Step 2: Update Documentation
1. Update `testing/MIGRATION-GUIDE.md` to note cleanup is complete
2. Update `README.md` project structure
3. Update `testing/docker/README.md` and `testing/docker/IMPLEMENTATION-COMPLETE.md`
4. Update `POLICY-CONFIGURATION-SUMMARY.md` file paths

### Step 3: Remove Old Directories
```batch
rmdir /s /q "docker-testing"
rmdir /s /q "Test Project"
```

### Step 4: Verify Repository
1. Check all scripts still work
2. Verify no broken links in documentation
3. Test git status to ensure no unintended deletions

## Impact Analysis

### ✅ Safe to Remove
- All functionality has been moved and verified
- New structure is more organized and maintainable
- Documentation clearly guides users to new locations

### ⚠️ Considerations
- Users with bookmarks to old documentation will need to update
- Any external scripts referencing old paths will break
- Git history will show the move (but that's expected)

### 📝 Migration Path for Users
The `testing/MIGRATION-GUIDE.md` already documents:
- Where everything moved
- How to update scripts
- What changed and why

## Recommendation

**Proceed with cleanup:**
1. The new structure is complete and verified
2. All tests pass in new locations
3. Documentation exists to guide users
4. Keeping old directories causes confusion

**Timeline:**
- Immediate: Safe to remove after final verification
- The restructure was completed and tested successfully

## Rollback Plan

If issues are discovered after cleanup:
1. Git history preserves all files
2. Can restore from previous commit
3. All content exists in new locations

## Post-Cleanup Verification

After cleanup, verify:
- [ ] `testing/docker/` works
- [ ] `testing/standalone-server/` works
- [ ] `testing/node-managed-server/` works
- [ ] All documentation links are valid
- [ ] No broken references in scripts

---

**Created:** 2026-02-16  
**Status:** Ready for execution  
**Risk Level:** Low (all content backed up in new structure)