# PGP_Policies - Policy Project

This policy project contains PGP configuration policies for the TestPGP application.

## Policies

### PGP-SDR-CFG-SERVICE
**Purpose**: Sender policy for encryption operations

**Configuration**:
- Private Key Store: `C:\temp\pgp\keys\sender-private.pgp`
- Public Key Store: `C:\temp\pgp\keys\sender-public.pgp` (contains receiver's public key)
- Encryption Algorithm: AES_256
- Compression: ZIP
- Used by: `encrypt.msgflow`

### PGP-RCV-CFG-SERVICE
**Purpose**: Receiver policy for decryption operations

**Configuration**:
- Private Key Store: `C:\temp\pgp\keys\receiver-private.pgp`
- Public Key Store: `C:\temp\pgp\keys\receiver-public.pgp` (contains sender's public key)
- Signature Verification: Optional
- Used by: `decrypt.msgflow`

## Setup Instructions

1. **Create Key Repositories**: Follow the instructions in [TEST-SETUP-WALKTHROUGH-ACE-13.md](../../TEST-SETUP-WALKTHROUGH-ACE-13.md) to create the required key repositories.

2. **Update Paths**: If you use different paths for your key repositories, update the paths in both policy files:
   - `PGP-SDR-CFG-SERVICE.policyxml`
   - `PGP-RCV-CFG-SERVICE.policyxml`

3. **Update Passwords**: If you use different passwords, update them in the policy files (or use ACE vault in production).

4. **Import to Toolkit**: Import this policy project into ACE Toolkit alongside the TestPGP application.

5. **Deploy**: Deploy this policy project to your integration server before deploying the TestPGP application.

## Security Notes

⚠️ **Important**: The passwords in these policy files are for testing purposes only. In production:
- Use ACE vault to store sensitive credentials
- Never commit passwords to source control
- Implement proper key management procedures
- Rotate keys regularly

## Related Documentation

- [Test Setup Walkthrough](../../TEST-SETUP-WALKTHROUGH-ACE-13.md) - Complete testing guide
- [Installation Guide](../../INSTALLATION.md) - PGP SupportPac installation
- [Main README](../../README.md) - Project overview