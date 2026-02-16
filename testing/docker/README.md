# Docker Testing for PGP SupportPac

This directory contains everything needed to test the PGP SupportPac in Docker containers.

## Quick Start

### Prerequisites
- Docker Desktop for Windows (20.10+)
- IBM Entitlement Key for accessing ACE images

### Setup (One-time)

1. **Login to IBM Container Registry:**
   ```cmd
   docker login cp.icr.io -u cp -p <YOUR_IBM_ENTITLEMENT_KEY>
   ```

2. **Run the tests:**
   ```cmd
   cd docker-testing
   test-docker-local.bat
   ```

That's it! The script will:
- Pull the ACE Docker image
- Start the container
- Install PGP SupportPac
- Run encryption/decryption tests
- Show results

## Directory Structure

```
docker-testing/
├── docker-compose.yml              # Container orchestration
├── test-docker-local.bat           # Windows test runner
├── scripts/
│   └── run-tests.sh                # Container test script
├── docs/
│   ├── DOCKER-TESTING-ARCHITECTURE-REVISED.md  # Complete architecture
│   ├── DOCKER-TESTING-PLAN.md                  # Detailed plan
│   ├── DOCKER-TESTING-QUICKSTART.md            # Quick start guide
│   └── DOCKER-TESTING-SUMMARY.md               # Executive summary
├── local-ace-install/              # Volume mount for ACE installation
└── local-aceuser-home/             # Volume mount for ACE runtime
```

## How It Works

### Volume Mappings

The docker-compose configuration maps these directories:

1. **`local-ace-install` → `/opt/ibm/ace-13/server`**
   - Allows installation of PGP SupportPac JARs
   - Persists across container restarts

2. **`local-aceuser-home` → `/home/aceuser`**
   - Contains integration server runtime
   - Contains shared-classes for Bouncy Castle JARs
   - Contains test files and results

3. **`../` → `/tmp/pgp-supportpac` (read-only)**
   - Mounts entire repository
   - Provides access to source files, JARs, and test resources

### Test Workflow

1. **Container starts** - ACE auto-starts a Standalone Integration Server (SIS)
2. **Stop SIS** - Kill the process to install JARs
3. **Install JARs** - Copy PGP SupportPac and Bouncy Castle JARs
4. **Setup environment** - Create test directories and copy PGP keys
5. **Deploy applications** - Deploy policies and flows with container overrides
6. **Restart server** - Start the integration server
7. **Run tests** - Execute encryption and decryption tests
8. **Verify results** - Compare original and decrypted files

## Test Results

### On Success
- ✅ Green checkmarks in console
- ✅ Container automatically removed (optional)
- ✅ Exit code: 0

### On Failure
- ❌ Red error messages
- ❌ Container kept for inspection
- ❌ Logs available for debugging
- ❌ Exit code: 1

## Debugging

### View Container Logs
```cmd
docker logs ace-pgp-test
```

### Inspect Running Container
```cmd
docker exec -it ace-pgp-test bash
```

### Check Server Logs
```cmd
docker exec ace-pgp-test cat /home/aceuser/aceserver/log/integration_server.aceserver.txt
```

### View Test Files
```cmd
docker exec ace-pgp-test ls -la /home/aceuser/pgp-test/
```

## Cleanup

### Remove Container and Volumes
```cmd
docker-compose down -v
```

### Remove ACE Image (to save space)
```cmd
docker rmi icr.io/appc/ace:13.0.6.0-r1
```

### Clean Local Directories
```cmd
rmdir /s /q local-ace-install
rmdir /s /q local-aceuser-home
```

## Configuration Files

### Container-Specific Policies
Located in `Test Project/Sources/PGP_Policies/`:
- `PGP-SDR-CFG-SERVICE-CONTAINER.policyxml` - Sender policy with container paths
- `PGP-RCV-CFG-SERVICE-CONTAINER.policyxml` - Receiver policy with container paths

### Deployment Descriptor
Located in `Test Project/Sources/Deploymentdescriptors/`:
- `containerOverrides.properties` - Overrides flow properties for container paths

## Known Issues

### ⚠️ UBI Image Classloader Issue (Work in Progress)

**Status:** Under investigation

**Issue:** When using IBM ACE UBI (Universal Base Image) containers, the Java classloader behaves differently and may load older encryption JARs from the base image instead of the Bouncy Castle 1.81 JARs we provide.

**Symptoms:**
- Encryption/decryption may fail with classloader errors
- Wrong version of Bouncy Castle libraries being used
- Inconsistent behavior between local and container environments

**Current Workaround:**
- Use non-UBI ACE images if available
- Manually verify JAR versions in container: `docker exec ace-pgp-test ls -la /home/aceuser/ace-server/shared-classes/`

**Investigation Status:**
- Classloader hierarchy differences in UBI images
- Potential conflicts with base image encryption libraries
- Testing alternative JAR placement strategies

This issue does not affect standalone server or node-managed server deployments.

## Troubleshooting

### Issue: "Docker is not running"
**Solution:** Start Docker Desktop

### Issue: "unauthorized: authentication required"
**Solution:** Login to IBM Container Registry
```cmd
docker login icr.io -u cp -p <YOUR_IBM_ENTITLEMENT_KEY>
```

### Issue: "Port 7800 already in use"
**Solution:** Stop conflicting service
```cmd
netstat -ano | findstr :7800
```

### Issue: Tests fail
**Solution:** Check container logs
```cmd
docker logs ace-pgp-test
docker exec -it ace-pgp-test bash
```

## Advanced Usage

### Keep Container on Success
Edit `test-docker-local.bat` and change the cleanup prompt behavior.

### Use Different ACE Version
Edit `docker-compose.yml` and change the image tag:
```yaml
image: icr.io/appc/ace:12.0.12.5-r1
```

### Run Tests Manually
```cmd
docker-compose up
```

### Run in Background
```cmd
docker-compose up -d
docker logs -f ace-pgp-test
```

## Documentation

For detailed information, see the `docs/` directory:
- **Architecture**: `DOCKER-TESTING-ARCHITECTURE-REVISED.md`
- **Complete Plan**: `DOCKER-TESTING-PLAN.md`
- **Quick Start**: `DOCKER-TESTING-QUICKSTART.md`
- **Summary**: `DOCKER-TESTING-SUMMARY.md`

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review documentation in `docs/` directory
3. Check container logs
4. Open GitHub issue with logs and details

---

**Last Updated:** 2026-02-13  
**Version:** 1.0.0