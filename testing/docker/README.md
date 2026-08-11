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
   cd testing\docker
   docker compose up -d
   docker logs -f ace-pgp-test
   ```

   `test-docker-local.bat` runs the same thing with `--abort-on-container-exit`.
   Note that `run-tests.sh` ends with `tail -f /dev/null` to keep the container
   alive for inspection, so on success that command streams logs indefinitely
   instead of returning - watch for `ALL TESTS PASSED` and press Ctrl+C.

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

### Call-home placeholder blocks startup on ACE 13.0.8 images

**Issue:** On `13.0.8.x` images the integration server refuses to start:

```
BIP2203E: An integration server has encountered a problem whilst starting.
BIP15366W: Unable to start integration server. The integration server requires a company name supplied to start.
```

The cause is call-home (anonymous usage statistics), which the image ships **enabled
with an unreplaced placeholder** in `/var/mqsi/registry.13.0.conf.yaml`:

```yaml
---
CallHome:
  companyName: 'REPLACE_ME_COMPANY_NAME'
  enabled: true
```

The company name is only used for that anonymous feedback. Since this test harness does
not send usage statistics, `run-tests.sh` turns call-home off rather than inventing a
company name:

```yaml
CallHome:
  enabled: false
```

This is the same setting a configured Windows install carries in
`C:\ProgramData\IBM\MQSI\registry.13.0.conf.yaml`, which is why standalone and
node-managed testing never hits this. Images 13.0.6 and 13.0.7 have no such check, so
the step is harmless on older tags.

**Note:** `ibmint modify installation --disable-usage-statistics` exits 0 but does *not*
clear the requirement on its own - verified on `13.0.8.1-r1`. Only the `enabled: false`
config above let the server reach `BIP1991I`.

### Shell script line endings on Windows clones

`scripts/run-tests.sh` is mounted straight from the working tree into the container.
With `core.autocrlf=true` a Windows checkout rewrites it to CRLF and bash fails with:

```
/tmp/run-tests.sh: line 3: $'\r': command not found
/tmp/run-tests.sh: line 17: syntax error near unexpected token `$'{\r''
```

The repository `.gitattributes` pins `*.sh` to `eol=lf` to prevent this. If you cloned
before that file existed, refresh the working copy:

```cmd
git rm --cached -r . & git reset --hard
```

### ⚠️ UBI Image Classloader Issue

**Status:** Not reproduced on `13.0.8.1-r1` (2026-08-11).

**Issue:** When using IBM ACE UBI (Universal Base Image) containers, the Java classloader behaves differently and may load older encryption JARs from the base image instead of the Bouncy Castle 1.81 JARs we provide.

**Symptoms:**
- Encryption/decryption may fail with classloader errors
- Wrong version of Bouncy Castle libraries being used
- Inconsistent behavior between local and container environments

**13.0.8.1-r1 observation:** the base image ships Bouncy Castle 1.84
(`server/webservices/prereqs/bcprov-jdk18on-1.84.jar`, `bcutil`, `bcpkix`) and
unversioned copies under `server/MQ/lib`, but no `bcpg`. The JARs in the integration
server `shared-classes` directory won the classpath: the encrypted output reported
`Version: BCPG v1.81`, the round trip matched, and the server log contained no errors.

**Verification:**
```cmd
docker exec ace-pgp-test ls -la /home/aceuser/ace-server/shared-classes/
docker logs ace-pgp-test | findstr "BCPG"
```

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
The image tag comes from `ACE_IMAGE_TAG` and defaults to `13.0.8.1-r1`:
```cmd
set ACE_IMAGE_TAG=13.0.7.0-r1
docker compose up -d
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

**Last Updated:** 2026-08-11  
**Last Tested:** ACE 13.0.8.1-r1 - all tests passing  
**Version:** 1.0.0