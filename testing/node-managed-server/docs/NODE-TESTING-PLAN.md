# Node-Managed Integration Server Testing Plan

## Overview

This document outlines the planned implementation for testing PGP SupportPac with IBM ACE Node-managed Integration Servers.

**Status:** 🚧 Planning Phase  
**Target Implementation:** Future Release

---

## Objectives

1. Validate PGP SupportPac functionality in node-managed environments
2. Test centralized policy management
3. Verify multi-server deployment scenarios
4. Ensure compatibility with Integration Node features
5. Test BAR file deployment with PGP components

---

## Architecture

### Components

```
Integration Node (Broker)
├── Integration Server 1 (Encryption)
│   ├── PGP_Policies (deployed from node)
│   └── TestPGP_App (encryption flows)
├── Integration Server 2 (Decryption)
│   ├── PGP_Policies (deployed from node)
│   └── TestPGP_App (decryption flows)
└── Shared Resources
    ├── PGP Keys (node-level)
    └── Bouncy Castle JARs (node-level)
```

### Key Differences from Standalone

| Aspect | Standalone Server | Node-Managed |
|--------|------------------|--------------|
| **Management** | Self-managed | Node-managed |
| **Policy Deployment** | Server-level | Node-level |
| **Resource Sharing** | Per-server | Node-level |
| **Administration** | Direct | Via mqsi commands |
| **Monitoring** | Server logs | Node + Server logs |

---

## Implementation Steps

### Phase 1: Environment Setup
1. Create Integration Node
2. Configure node properties
3. Install Bouncy Castle JARs at node level
4. Create multiple integration servers

### Phase 2: Application Deployment
1. Create BAR file with PGP components
2. Deploy policies to node
3. Deploy BAR file to integration servers
4. Configure server-specific overrides

### Phase 3: Testing
1. Test encryption on Server 1
2. Test decryption on Server 2
3. Test cross-server communication
4. Validate policy inheritance
5. Test node-level administration

### Phase 4: Automation
1. Create setup script
2. Create deployment script
3. Create test execution script
4. Create cleanup script

---

## Required Scripts

### 1. setup-node.bat
```batch
REM Create and configure Integration Node
mqsicreatebroker TEST_NODE
mqsistart TEST_NODE
mqsicreateexecutiongroup TEST_NODE -e SERVER1
mqsicreateexecutiongroup TEST_NODE -e SERVER2
```

### 2. deploy-pgp.bat
```batch
REM Deploy PGP components to node
mqsideploy TEST_NODE -e SERVER1 -a TestPGP.bar
mqsideploy TEST_NODE -e SERVER2 -a TestPGP.bar
```

### 3. run-tests.bat
```batch
REM Execute encryption/decryption tests
curl -X POST http://localhost:7800/pgp/encrypt
curl -X POST http://localhost:7801/pgp/decrypt
```

---

## Test Scenarios

### Scenario 1: Basic Encryption/Decryption
- Deploy to single server
- Test encryption flow
- Test decryption flow
- Verify results

### Scenario 2: Multi-Server Workflow
- Deploy encryption to Server 1
- Deploy decryption to Server 2
- Test cross-server file transfer
- Verify end-to-end workflow

### Scenario 3: Policy Management
- Deploy policies at node level
- Verify policy inheritance
- Test policy updates
- Validate server-specific overrides

### Scenario 4: High Availability
- Deploy to multiple servers
- Test failover scenarios
- Verify load balancing
- Test recovery procedures

---

## Prerequisites

### Software Requirements
- IBM ACE 12.0+ or 13.0+
- Integration Node created
- Administrative privileges
- Network connectivity

### Knowledge Requirements
- Integration Node administration
- mqsi command-line tools
- BAR file creation
- Policy management

---

## Success Criteria

- [ ] Node successfully created and started
- [ ] Multiple integration servers deployed
- [ ] PGP components deployed via BAR file
- [ ] Policies deployed at node level
- [ ] Encryption test passes on Server 1
- [ ] Decryption test passes on Server 2
- [ ] Cross-server workflow succeeds
- [ ] Policy updates propagate correctly
- [ ] All tests automated
- [ ] Documentation complete

---

## Challenges and Considerations

### Technical Challenges
1. **JAR File Placement**: Determine optimal location for Bouncy Castle JARs
2. **Policy Scope**: Node-level vs server-level policy management
3. **Resource Sharing**: Shared vs isolated PGP keys
4. **Port Management**: Multiple servers on same host

### Operational Challenges
1. **Complexity**: Higher setup complexity than standalone
2. **Dependencies**: Requires Integration Node infrastructure
3. **Maintenance**: More components to manage
4. **Troubleshooting**: Multiple log locations

---

## Timeline

### Estimated Effort
- Planning: 1 week
- Implementation: 2-3 weeks
- Testing: 1 week
- Documentation: 1 week
- **Total: 5-6 weeks**

### Milestones
1. ✅ Planning document created
2. ⏳ Environment setup scripts
3. ⏳ Deployment automation
4. ⏳ Test automation
5. ⏳ Documentation complete
6. ⏳ User acceptance testing

---

## Resources

### IBM Documentation
- [Integration Node Administration](https://www.ibm.com/docs/en/app-connect/12.0?topic=administering-integration-nodes)
- [mqsi Commands Reference](https://www.ibm.com/docs/en/app-connect/12.0?topic=reference-mqsi-commands)
- [BAR File Deployment](https://www.ibm.com/docs/en/app-connect/12.0?topic=files-deploying-bar)

### Related Testing
- [Standalone Server Testing](../../standalone-server/README.md)
- [Docker Testing](../../docker/README.md)
- [Testing Comparison](../../docs/TESTING-COMPARISON.md)

---

## Contributing

Interested in implementing node-managed testing? Here's how to help:

1. **Review this plan** - Provide feedback on the approach
2. **Test environment** - Set up a test Integration Node
3. **Prototype** - Create proof-of-concept scripts
4. **Documentation** - Help document the process
5. **Testing** - Validate the implementation

---

## Contact

For questions or to contribute:
- Open an issue on GitHub
- Tag with `enhancement` and `node-managed-testing`
- Reference this planning document

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-16  
**Status:** Planning Phase