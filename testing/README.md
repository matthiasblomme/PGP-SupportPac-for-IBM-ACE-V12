# PGP SupportPac Testing

Welcome to the unified testing directory for the PGP SupportPac for IBM App Connect Enterprise.

## Overview

This directory contains three different testing approaches, each suited for different use cases and environments:

1. **[Docker Testing](docker/)** - Containerized, automated testing
2. **[Standalone Server Testing](standalone-server/)** - Local Windows testing with ACE installed
3. **[Node-Managed Server Testing](node-managed-server/)** - Multi-server, node-managed testing

## Quick Comparison

| Feature | Docker | Standalone Server | Node-Managed |
|---------|--------|------------------|--------------|
| **Setup Time** | 5 minutes | 10-15 minutes | 20-30 minutes |
| **Prerequisites** | Docker Desktop | ACE installed | ACE + Node |
| **Isolation** | ✅ High | ⚠️ Medium | ❌ Low |
| **Automation** | ✅ Full | ✅ Full | ✅ Full |
| **Production-like** | ⚠️ Medium | ✅ High | ✅✅ Very High |
| **Multi-server** | ❌ No | ❌ No | ✅ Yes |
| **Platform** | Windows/Linux/Mac | Windows | Windows/Linux |
| **Status** | ✅ Ready | ✅ Ready | ✅ Ready |

## Quick Start

### Choose Your Testing Approach

**Use Docker Testing if you:**
- Want fast, automated testing
- Don't have ACE installed locally
- Need isolated test environments
- Want to test on multiple platforms
- Are setting up CI/CD pipelines

**Use Standalone Server Testing if you:**
- Have ACE installed on Windows
- Want to test on actual ACE installation
- Need to debug with ACE Toolkit
- Prefer local file system access
- Want production-like environment

**Use Node-Managed Testing if you:**
- Need multi-server testing
- Want centralized management
- Test node-level features
- Require high availability testing

## Getting Started

### Docker Testing

**Prerequisites:**
- Docker Desktop installed
- IBM Entitlement Key

**Quick Start:**
```cmd
cd testing/docker
docker login cp.icr.io -u cp -p <YOUR_IBM_ENTITLEMENT_KEY>
test-docker-local.bat
```

**Time:** ~5 minutes (first run: ~10 minutes for image download)

📖 [Full Docker Testing Guide](docker/README.md)

### Standalone Server Testing

**Prerequisites:**
- IBM ACE 13.0.6.0 installed
- Windows OS
- Administrator privileges

**Quick Start:**
```cmd
cd testing/standalone-server
deploy_and_test.bat
```

**Time:** ~10-15 minutes

📖 [Full Standalone Server Guide](standalone-server/README.md)  
📖 [Detailed Walkthrough](standalone-server/TEST-SETUP-WALKTHROUGH.md)

### Node-Managed Testing

**Prerequisites:**
- IBM ACE 13.0.6.0 installed
- Windows OS
- Administrator privileges

**Quick Start:**
```cmd
cd testing/node-managed-server/scripts
setup-and-test-node.bat
```

**Time:** ~30-40 minutes (includes node creation, server setup, and testing)

📖 [Full Node-Managed Server Guide](node-managed-server/README.md)
📖 [Implementation Details](node-managed-server/IMPLEMENTATION-COMPLETE.md)

## Directory Structure

```
testing/
├── README.md (this file)
│
├── test-resources/              # Shared test resources
│   ├── Sources/                 # ACE projects and policies
│   ├── TestPGP/                 # Eclipse project
│   └── TestPgp_ProjectInterchange.zip
│
├── docker/                      # Docker-based testing
│   ├── README.md
│   ├── docker-compose.yml
│   ├── test-docker-local.bat
│   ├── docs/                    # Docker-specific docs
│   ├── scripts/                 # Container scripts
│   ├── local-ace-install/       # Volume mount
│   └── local-aceuser-home/      # Volume mount
│
├── standalone-server/           # Local Windows testing
│   ├── README.md
│   ├── deploy_and_test.bat      # Automated test script
│   ├── TEST-SETUP-WALKTHROUGH.md
│   └── docs/                    # SIS-specific docs
│
├── node-managed-server/         # Node-managed testing
│   ├── README.md
│   ├── IMPLEMENTATION-COMPLETE.md
│   └── scripts/
│       └── setup-and-test-node.bat
│   ├── docs/
│   └── scripts/
│
└── docs/                        # Unified documentation
    ├── TESTING-OVERVIEW.md
    ├── TESTING-QUICKSTART.md
    ├── TESTING-ARCHITECTURE.md
    └── TESTING-COMPARISON.md
```

## Test Resources

All testing approaches share common resources located in [`test-resources/`](test-resources/):

- **Test Application:** TestPGP_App with encryption/decryption flows
- **Policies:** PGP configuration policies (local and container versions)
- **PGP Keys:** Test keys with passphrase `passw0rd`
- **BAR File:** Pre-built TestPGP.bar for deployment

📖 [Test Resources Documentation](test-resources/README.md)

## What Gets Tested

All testing approaches validate:

1. ✅ **PGP Key Management**
   - Key generation
   - Key import/export
   - Repository management

2. ✅ **Encryption**
   - File encryption
   - Policy configuration
   - Public key usage

3. ✅ **Decryption**
   - File decryption
   - Private key usage
   - Passphrase handling

4. ✅ **Integration**
   - ACE flow execution
   - HTTP endpoints
   - File I/O operations

5. ✅ **End-to-End**
   - Original vs decrypted file comparison
   - Complete workflow validation

## Test Results

### Docker Testing
- **Status:** ✅ All tests passing
- **Last Tested:** 2026-02-13
- **ACE Version:** 13.0.6.0-r1
- **Platform:** Docker (Linux containers)

### Standalone Server Testing
- **Status:** ✅ All tests passing
- **Last Tested:** 2026-02-12
- **ACE Version:** 13.0.6.0
- **Platform:** Windows 10/11

### Node-Managed Testing
- **Status:** 🚧 Not yet implemented

## Documentation

### Quick References
- 📖 [Testing Overview](docs/TESTING-OVERVIEW.md) - High-level overview
- 📖 [Quick Start Guide](docs/TESTING-QUICKSTART.md) - 5-minute guide
- 📖 [Architecture](docs/TESTING-ARCHITECTURE.md) - Technical details
- 📖 [Comparison Matrix](docs/TESTING-COMPARISON.md) - Feature comparison

### Test-Specific Guides
- 📖 [Docker Testing](docker/README.md)
- 📖 [Standalone Server Testing](standalone-server/README.md)
- 📖 [Node-Managed Testing](node-managed-server/README.md)

### Additional Resources
- 📖 [Test Resources](test-resources/README.md)
- 📖 [Installation Guide](../INSTALLATION.md)
- 📖 [Main README](../README.md)

## Troubleshooting

### Common Issues

**Docker: "unauthorized: authentication required"**
```cmd
docker login cp.icr.io -u cp -p <YOUR_IBM_ENTITLEMENT_KEY>
```

**Standalone: "ACE not found"**
- Verify ACE is installed at `C:\Program Files\IBM\ACE\13.0.6.0`
- Or specify path: `deploy_and_test.bat "C:\path\to\ACE"`

**All: "Keys not found"**
- Verify test-resources directory is intact
- Check paths in policy files

**All: "Decryption failed"**
- Verify passphrase is `passw0rd`
- Check that encryption completed successfully

### Getting Help

1. Check test-specific README files
2. Review troubleshooting sections
3. Check server logs
4. Open GitHub issue with:
   - Test type (Docker/Standalone/Node)
   - Error messages
   - Log files
   - Environment details

## Contributing

### Adding New Tests

1. Add test scenarios to appropriate test type
2. Update documentation
3. Ensure all test types remain consistent
4. Test on clean environment
5. Submit pull request

### Improving Documentation

1. Identify gaps or unclear sections
2. Update relevant README files
3. Add examples or screenshots
4. Submit pull request

### Reporting Issues

1. Use GitHub Issues
2. Tag with appropriate label (docker/standalone/node)
3. Include reproduction steps
4. Attach relevant logs

## CI/CD Integration

### GitHub Actions (Planned)

Docker testing is designed for CI/CD integration:

```yaml
# .github/workflows/test-pgp-supportpac.yml
name: Test PGP SupportPac
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Docker Tests
        run: |
          cd testing/docker
          docker-compose up --abort-on-container-exit
```

## Version Compatibility

| ACE Version | Docker | Standalone | Node-Managed |
|-------------|--------|------------|--------------|
| 12.0.x | ✅ | ✅ | 🚧 |
| 13.0.x | ✅ | ✅ | 🚧 |

## Support

For questions or issues:
- 📖 Check documentation in `docs/` directory
- 🐛 Open GitHub issue
- 💬 Tag with appropriate test type

---

## Quick Links

- [Docker Testing →](docker/README.md)
- [Standalone Server Testing →](standalone-server/README.md)
- [Node-Managed Testing →](node-managed-server/README.md)
- [Test Resources →](test-resources/README.md)
- [Main Project README →](../README.md)

---

**Last Updated:** 2026-02-16  
**Maintained By:** PGP SupportPac Project Team