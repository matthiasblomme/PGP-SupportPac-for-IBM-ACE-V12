# Docker Testing Quick Start Guide

## Overview

This guide helps you quickly set up and run automated tests for the PGP SupportPac using Docker containers.

**Two Testing Modes**:
1. **Local Testing** - Test on your machine before committing
2. **GitHub Actions** - Automated testing on every push

---

## Prerequisites

### Required Software
- ✅ Docker Desktop for Windows (version 20.10+)
- ✅ Docker Compose (included with Docker Desktop)
- ✅ Git for Windows
- ✅ IBM Entitlement Key (for accessing ACE Docker images)

### Get IBM Entitlement Key
1. Visit [IBM Container Registry](https://myibm.ibm.com/products-services/containerlibrary)
2. Copy your entitlement key
3. Save it securely (you'll need it for Docker login)

---

## Local Testing Setup (5 Minutes)

### Step 1: Clone Repository
```cmd
git clone <repository-url>
cd PGP-SupportPac-for-IBM-ACE-V12
```

### Step 2: Login to IBM Container Registry
```cmd
docker login icr.io -u cp -p <YOUR_IBM_ENTITLEMENT_KEY>
```

### Step 3: Run Tests
```cmd
test-docker-local.bat
```

That's it! The script will:
- Pull the ACE Docker image
- Build the test container
- Install PGP SupportPac
- Run encryption/decryption tests
- Show results

### Expected Output
```
============================================================================
PGP SupportPac Docker Test
============================================================================
[Step 1/8] Checking Docker...
[OK] Docker is running

[Step 2/8] Pulling ACE image...
[OK] Image pulled: icr.io/appc/ace:13.0.6.0-r1

[Step 3/8] Building test container...
[OK] Container built

[Step 4/8] Starting tests...
[OK] Container started

[Step 5/8] Running encryption test...
[OK] Encryption successful

[Step 6/8] Running decryption test...
[OK] Decryption successful

[Step 7/8] Verifying results...
[OK] Files match perfectly!

[Step 8/8] Cleanup...
[OK] Container removed

============================================================================
ALL TESTS PASSED! ✓
============================================================================
```

---

## GitHub Actions Setup (10 Minutes)

### Step 1: Add IBM Entitlement Key to GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `IBM_ENTITLEMENT_KEY`
5. Value: Your IBM entitlement key
6. Click **Add secret**

### Step 2: Enable GitHub Actions

The workflow file is already in `.github/workflows/test-pgp-supportpac.yml`

It will automatically run on:
- Every push to main branch
- Every pull request
- Manual trigger (workflow_dispatch)

### Step 3: Verify Workflow

1. Make a small change and push
2. Go to **Actions** tab in GitHub
3. Watch the workflow run
4. Check for green checkmark ✓

---

## Common Commands

### Local Testing

```cmd
REM Run tests with default settings
test-docker-local.bat

REM Keep container for inspection (even on success)
test-docker-local.bat --keep-container

REM Use specific ACE version
test-docker-local.bat --ace-version 13.0.6.0

REM Clean up all test containers
test-docker-local.bat --cleanup

REM View help
test-docker-local.bat --help
```

### Docker Commands

```cmd
REM View running containers
docker ps

REM View all containers (including stopped)
docker ps -a

REM View container logs
docker logs ace-pgp-test

REM Execute command in container
docker exec -it ace-pgp-test bash

REM Stop and remove container
docker stop ace-pgp-test
docker rm ace-pgp-test

REM Clean up everything
docker-compose -f docker-compose.test.yml down -v
```

---

## Troubleshooting

### Issue: "Docker is not running"
**Solution**: Start Docker Desktop

### Issue: "unauthorized: authentication required"
**Solution**: Login to IBM Container Registry
```cmd
docker login icr.io -u cp -p <YOUR_IBM_ENTITLEMENT_KEY>
```

### Issue: "Port 7800 already in use"
**Solution**: Stop the conflicting service
```cmd
REM Find what's using the port
netstat -ano | findstr :7800

REM Stop your local ACE server if running
```

### Issue: Tests fail
**Solution**: Check container logs
```cmd
REM View logs
docker logs ace-pgp-test

REM Keep container for inspection
test-docker-local.bat --keep-container

REM Then inspect
docker exec -it ace-pgp-test bash
```

### Issue: Slow performance
**Solution**: Increase Docker resources
1. Open Docker Desktop
2. Settings → Resources
3. Increase CPU to 4 cores
4. Increase Memory to 8 GB

---

## What Gets Tested?

### ✅ Installation Tests
- PGP SupportPac JARs installed correctly
- Bouncy Castle libraries accessible
- ACE can load PGP nodes

### ✅ Functional Tests
- Encryption flow works
- Decryption flow works
- Original and decrypted files match

### ✅ Integration Tests
- HTTP endpoints respond
- Policies load correctly
- Server logs show no errors

---

## Test Results

### On Success
- Console shows green checkmarks ✓
- Container automatically removed
- Exit code: 0

### On Failure
- Console shows red X marks
- Container kept for inspection
- Logs saved to `test-results/`
- Exit code: 1

---

## Next Steps

### After Local Tests Pass
1. Commit your changes
2. Push to GitHub
3. Watch GitHub Actions run
4. Verify green checkmark in Actions tab

### For Development
1. Make code changes
2. Run `test-docker-local.bat`
3. Fix any issues
4. Repeat until tests pass
5. Commit and push

### For CI/CD
- Tests run automatically on push
- Pull requests show test status
- Merge only when tests pass

---

## File Structure

```
PGP-SupportPac-for-IBM-ACE-V12/
├── docker/
│   ├── Dockerfile.test           # Test container definition
│   ├── run-tests.sh              # Test execution script
│   └── README.md                 # Docker documentation
├── .github/
│   └── workflows/
│       └── test-pgp-supportpac.yml  # GitHub Actions workflow
├── docker-compose.test.yml       # Docker Compose config
├── test-docker-local.bat         # Local test script
├── DOCKER-TESTING-PLAN.md        # Comprehensive plan
└── DOCKER-TESTING-QUICKSTART.md  # This file
```

---

## Getting Help

### Documentation
- **Comprehensive Plan**: [`DOCKER-TESTING-PLAN.md`](DOCKER-TESTING-PLAN.md)
- **Docker Details**: [`docker/README.md`](docker/README.md)
- **Main README**: [`README.md`](README.md)

### Support
- Check troubleshooting section above
- Review container logs
- Open GitHub issue with logs

---

## Tips for Success

### 💡 Best Practices
1. **Always test locally first** before pushing
2. **Keep Docker Desktop running** during development
3. **Update ACE image regularly** for security patches
4. **Review logs on failure** for quick debugging
5. **Clean up containers** periodically to save disk space

### ⚡ Performance Tips
1. Use Docker layer caching (automatic)
2. Don't rebuild image unnecessarily
3. Increase Docker resources if slow
4. Close other applications during tests

### 🔒 Security Tips
1. Never commit IBM Entitlement Key to Git
2. Use GitHub Secrets for CI/CD
3. Rotate keys periodically
4. Keep Docker Desktop updated

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Run tests | `test-docker-local.bat` |
| View logs | `docker logs ace-pgp-test` |
| Inspect container | `docker exec -it ace-pgp-test bash` |
| Clean up | `test-docker-local.bat --cleanup` |
| Login to registry | `docker login icr.io -u cp -p <KEY>` |
| Check Docker | `docker ps` |

---

## Success Checklist

Before committing changes, verify:
- [ ] Local Docker tests pass
- [ ] No errors in container logs
- [ ] Files encrypt/decrypt correctly
- [ ] Container cleans up properly
- [ ] Ready to push to GitHub

---

**Ready to start? Run `test-docker-local.bat` now!**

For detailed information, see [`DOCKER-TESTING-PLAN.md`](DOCKER-TESTING-PLAN.md)