# Testing Directory Restructure Plan

## Overview

This document outlines the plan to reorganize the PGP SupportPac testing structure into a unified, well-organized hierarchy that supports three testing approaches:
1. **Docker Testing** (containerized)
2. **Standalone Integration Server (SIS) Testing** (local Windows)
3. **Node-managed Integration Server Testing** (future)

**Date:** 2026-02-16  
**Status:** Planning Phase

---

## Current Structure Issues

### Problems Identified
1. ❌ Local testing script buried in `Test Project/Scripts/`
2. ❌ Docker testing has dedicated folder, but SIS testing doesn't
3. ❌ `TEST-SETUP-WALKTHROUGH-ACE-13.md` is in root directory (not organized)
4. ❌ No consistent documentation structure across test types
5. ❌ Test Project sources mixed with testing scripts
6. ❌ No placeholder for future Node-managed testing

### Current Directory Structure
```
PGP-SupportPac-for-IBM-ACE-V12/
├── docker-testing/                    # ✅ Well organized
│   ├── README.md
│   ├── docker-compose.yml
│   ├── test-docker-local.bat
│   ├── docs/
│   ├── scripts/
│   ├── local-ace-install/
│   └── local-aceuser-home/
├── Test Project/                      # ❌ Mixed purposes
│   ├── Scripts/
│   │   └── deploy_and_test.bat       # SIS testing script
│   ├── Sources/                       # Shared test resources
│   └── TestPGP/
├── TEST-SETUP-WALKTHROUGH-ACE-13.md  # ❌ In root
└── [other files]
```

---

## Proposed New Structure

### Target Directory Structure
```
PGP-SupportPac-for-IBM-ACE-V12/
├── testing/                           # 🆕 Unified testing root
│   ├── README.md                      # Main testing guide
│   │
│   ├── test-resources/                # 🆕 Shared test resources
│   │   ├── README.md
│   │   ├── Sources/                   # Moved from Test Project/
│   │   │   ├── TestPGP.bar
│   │   │   ├── Deploymentdescriptors/
│   │   │   ├── PGP_Policies/
│   │   │   ├── pgp-keys/
│   │   │   └── TestPGP_App/
│   │   ├── TestPGP/                   # Moved from Test Project/
│   │   └── TestPgp_ProjectInterchange.zip
│   │
│   ├── docker/                        # 🔄 Moved from docker-testing/
│   │   ├── README.md
│   │   ├── docker-compose.yml
│   │   ├── test-docker-local.bat
│   │   ├── docs/
│   │   │   ├── DOCKER-TESTING-QUICKSTART.md
│   │   │   ├── DOCKER-TESTING-ARCHITECTURE.md
│   │   │   └── DOCKER-TESTING-SUMMARY.md
│   │   ├── scripts/
│   │   │   └── run-tests.sh
│   │   ├── local-ace-install/
│   │   └── local-aceuser-home/
│   │
│   ├── standalone-server/             # 🆕 SIS testing (local Windows)
│   │   ├── README.md
│   │   ├── deploy-and-test.bat        # Moved from Test Project/Scripts/
│   │   ├── TEST-SETUP-WALKTHROUGH.md  # Moved from root
│   │   └── docs/
│   │       ├── SIS-TESTING-QUICKSTART.md
│   │       ├── SIS-TESTING-ARCHITECTURE.md
│   │       └── SIS-TESTING-SUMMARY.md
│   │
│   ├── node-managed-server/           # 🆕 Future: Node-managed testing
│   │   ├── README.md
│   │   ├── docs/
│   │   │   └── NODE-TESTING-PLAN.md
│   │   └── scripts/
│   │       └── .gitkeep
│   │
│   └── docs/                          # 🆕 Unified testing documentation
│       ├── TESTING-OVERVIEW.md        # High-level comparison
│       ├── TESTING-QUICKSTART.md      # Quick start for all types
│       ├── TESTING-ARCHITECTURE.md    # Technical architecture
│       └── TESTING-COMPARISON.md      # Feature comparison matrix
│
├── installation-scripts/              # ✅ Unchanged
├── MQSI_BASE_FILEPATH/                # ✅ Unchanged
├── MQSI_REGISTRY/                     # ✅ Unchanged
├── INSTALLATION.md                    # ✅ Unchanged
├── README.md                          # 🔄 Update references
└── [other files]
```

---

## Detailed Changes

### 1. Create `testing/` Root Directory

**Purpose:** Unified location for all testing approaches

**Structure:**
- Main README.md with overview of all testing types
- Subdirectories for each testing approach
- Shared test-resources directory
- Unified documentation in docs/

### 2. Move Docker Testing

**From:** `docker-testing/`  
**To:** `testing/docker/`

**Changes:**
- Move entire `docker-testing/` directory
- Update all internal path references
- Update documentation references
- Keep all existing functionality

**Files to Update:**
- `docker-compose.yml` - Update volume mount paths
- `test-docker-local.bat` - Update relative paths
- `scripts/run-tests.sh` - Update repository mount path
- All documentation files - Update cross-references

### 3. Create Standalone Server Testing

**New Directory:** `testing/standalone-server/`

**Contents:**
- Move `Test Project/Scripts/deploy_and_test.bat`
- Move `TEST-SETUP-WALKTHROUGH-ACE-13.md` from root
- Create comprehensive README.md
- Create docs/ subdirectory with:
  - SIS-TESTING-QUICKSTART.md
  - SIS-TESTING-ARCHITECTURE.md
  - SIS-TESTING-SUMMARY.md

**Files to Update:**
- `deploy_and_test.bat` - Update paths to test-resources
- `TEST-SETUP-WALKTHROUGH-ACE-13.md` - Update cross-references

### 4. Create Shared Test Resources

**New Directory:** `testing/test-resources/`

**Contents:**
- Move `Test Project/Sources/` → `testing/test-resources/Sources/`
- Move `Test Project/TestPGP/` → `testing/test-resources/TestPGP/`
- Move `Test Project/TestPgp_ProjectInterchange.zip` → `testing/test-resources/`
- Create README.md explaining shared resources

**Purpose:**
- Single source of truth for test projects
- Shared by all testing approaches
- Easier to maintain and update

### 5. Create Node-Managed Server Testing (Placeholder)

**New Directory:** `testing/node-managed-server/`

**Contents:**
- README.md (placeholder with future plans)
- docs/NODE-TESTING-PLAN.md
- scripts/.gitkeep

**Purpose:**
- Reserve structure for future implementation
- Document planned approach
- Maintain consistency with other test types

### 6. Create Unified Documentation

**New Directory:** `testing/docs/`

**Contents:**
- `TESTING-OVERVIEW.md` - High-level overview of all testing approaches
- `TESTING-QUICKSTART.md` - Quick start guide for choosing and running tests
- `TESTING-ARCHITECTURE.md` - Technical architecture across all approaches
- `TESTING-COMPARISON.md` - Feature comparison matrix

**Purpose:**
- Single entry point for testing documentation
- Compare and contrast different approaches
- Help users choose the right testing method

---

## Migration Steps

### Phase 1: Create New Structure (No Breaking Changes)
1. Create `testing/` directory
2. Create `testing/test-resources/` and copy files
3. Create `testing/standalone-server/` and copy files
4. Create `testing/node-managed-server/` placeholder
5. Create `testing/docs/` with new documentation
6. Copy `docker-testing/` to `testing/docker/`

### Phase 2: Update References
1. Update all path references in scripts
2. Update all documentation cross-references
3. Update main README.md
4. Create migration guide

### Phase 3: Cleanup (After Verification)
1. Remove old `Test Project/Scripts/` directory
2. Remove old `docker-testing/` directory
3. Remove `TEST-SETUP-WALKTHROUGH-ACE-13.md` from root
4. Update .gitignore if needed

---

## Documentation to Create

### Main Testing README (`testing/README.md`)
- Overview of all testing approaches
- Quick comparison table
- Links to specific test type documentation
- Prerequisites for each approach
- Getting started guide

### Standalone Server README (`testing/standalone-server/README.md`)
- Overview of SIS testing
- Prerequisites (ACE installation required)
- Quick start guide
- Directory structure
- Troubleshooting
- Links to detailed documentation

### Test Resources README (`testing/test-resources/README.md`)
- Explanation of shared resources
- Directory structure
- How each test type uses these resources
- How to update test projects
- Policy configuration details

### Unified Documentation
1. **TESTING-OVERVIEW.md**
   - What is PGP SupportPac testing
   - Why multiple testing approaches
   - When to use each approach

2. **TESTING-QUICKSTART.md**
   - 5-minute quick start for each approach
   - Decision tree for choosing test type
   - Common troubleshooting

3. **TESTING-ARCHITECTURE.md**
   - Technical architecture of each approach
   - How they differ
   - Shared components
   - Integration points

4. **TESTING-COMPARISON.md**
   - Feature comparison matrix
   - Performance comparison
   - Pros and cons of each approach
   - Use case recommendations

### Standalone Server Documentation
1. **SIS-TESTING-QUICKSTART.md**
   - 5-minute quick start
   - Prerequisites checklist
   - Common issues

2. **SIS-TESTING-ARCHITECTURE.md**
   - How SIS testing works
   - Directory structure
   - Script workflow
   - Integration with ACE

3. **SIS-TESTING-SUMMARY.md**
   - Executive summary
   - Key features
   - Test results
   - Compatibility matrix

---

## Path Updates Required

### Scripts to Update

1. **`testing/standalone-server/deploy_and_test.bat`**
   ```batch
   # OLD: set SOURCES_DIR=%TEST_PROJECT%\Sources
   # NEW: set SOURCES_DIR=%PROJECT_ROOT%\testing\test-resources\Sources
   ```

2. **`testing/docker/docker-compose.yml`**
   ```yaml
   # OLD: - ../:tmp/pgp-supportpac:ro
   # NEW: - ../../:/tmp/pgp-supportpac:ro
   ```

3. **`testing/docker/test-docker-local.bat`**
   ```batch
   # Update relative paths to testing/docker/
   ```

4. **`testing/docker/scripts/run-tests.sh`**
   ```bash
   # OLD: /tmp/pgp-supportpac/Test Project/Sources
   # NEW: /tmp/pgp-supportpac/testing/test-resources/Sources
   ```

### Documentation to Update

1. **Main `README.md`**
   - Update testing section to point to `testing/README.md`
   - Update quick start links

2. **`INSTALLATION.md`**
   - Update test project references
   - Update paths to test resources

3. **All existing documentation**
   - Search and replace old paths
   - Update cross-references

---

## Benefits of New Structure

### ✅ Consistency
- All testing approaches follow same organizational pattern
- Consistent documentation structure
- Easier to navigate

### ✅ Scalability
- Easy to add new testing approaches (Node-managed, Cloud, etc.)
- Clear separation of concerns
- Modular structure

### ✅ Maintainability
- Shared resources in one location
- Easier to update test projects
- Clear ownership of files

### ✅ Discoverability
- Single entry point for testing (`testing/README.md`)
- Clear hierarchy
- Better documentation organization

### ✅ Professional
- Mirrors industry best practices
- Similar to other open-source projects
- Easier for contributors to understand

---

## Risks and Mitigation

### Risk 1: Breaking Existing Workflows
**Mitigation:**
- Create migration guide
- Keep old structure temporarily
- Update all documentation with new paths
- Provide backward compatibility notes

### Risk 2: Path Reference Errors
**Mitigation:**
- Comprehensive testing after migration
- Update all scripts before removing old structure
- Document all path changes
- Create verification checklist

### Risk 3: User Confusion
**Mitigation:**
- Clear migration guide
- Update main README prominently
- Provide side-by-side comparison
- Include "What Changed" section

---

## Success Criteria

- [ ] All testing approaches work with new structure
- [ ] All documentation updated and accurate
- [ ] No broken links or references
- [ ] Migration guide created and tested
- [ ] Old structure can be safely removed
- [ ] Users can easily find and run tests
- [ ] New structure supports future test types

---

## Timeline Estimate

| Phase | Tasks | Estimated Time |
|-------|-------|----------------|
| **Phase 1: Planning** | This document, review, approval | 1 day |
| **Phase 2: Structure Creation** | Create directories, copy files | 2 hours |
| **Phase 3: Script Updates** | Update all path references | 3 hours |
| **Phase 4: Documentation** | Create new docs, update existing | 1 day |
| **Phase 5: Testing** | Verify all tests work | 3 hours |
| **Phase 6: Cleanup** | Remove old structure, final review | 1 hour |
| **Total** | | ~2-3 days |

---

## Next Steps

1. **Review this plan** - Get approval for proposed structure
2. **Create backup** - Ensure current state is backed up
3. **Execute Phase 1** - Create new directory structure
4. **Test incrementally** - Verify each change works
5. **Update documentation** - Keep docs in sync with changes
6. **Final verification** - Run all tests in new structure
7. **Cleanup** - Remove old structure after verification

---

## Questions for Review

1. ✅ Is the `testing/` root directory name appropriate?
2. ✅ Should Docker testing be `testing/docker/` or `testing/docker-testing/`?
3. ✅ Is `standalone-server/` a clear name for SIS testing?
4. ✅ Should we keep `Test Project/` directory name or rename to `test-resources/`?
5. ✅ Any other testing approaches to plan for?

---

**End of Restructure Plan**