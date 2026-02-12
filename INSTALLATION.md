# PGP SupportPac Installation Guide

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Pre-Installation Steps](#pre-installation-steps)
- [Installation Methods](#installation-methods)
  - [Automated Installation (Recommended)](#automated-installation-recommended)
  - [Manual Installation](#manual-installation)
- [Post-Installation](#post-installation)
- [Verification](#verification)
- [Using pgpKeytool Command Line](#using-pgpkeytool-command-line)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [ACE 13.x Compatibility Notes](#ace-13x-compatibility-notes)

---

## Overview

This guide provides detailed instructions for installing the PGP SupportPac for IBM App Connect Enterprise (ACE). The PGP SupportPac enables encryption and decryption capabilities using PGP (Pretty Good Privacy) within ACE message flows.

### What Gets Installed

The installation process copies four JAR files to your ACE installation:

| File | Purpose | Destination |
|------|---------|-------------|
| `PGPSupportPacImpl.jar` | Server-side PGP implementation | `%MQSI_BASE_FILEPATH%\server\jplugin\` |
| `PGPSupportPac.jar` | Toolkit plugin for PGP nodes | `%MQSI_BASE_FILEPATH%\tools\plugins\` |
| `bcpg-jdk18on-1.78.1.jar` | Bouncy Castle PGP library | `%MQSI_REGISTRY%\shared-classes\` |
| `bcprov-jdk18on-1.78.1.jar` | Bouncy Castle cryptography provider | `%MQSI_REGISTRY%\shared-classes\` |

---

## Prerequisites

### System Requirements
- **Operating System**: Windows (tested on Windows Server 2016+, Windows 10+)
- **IBM ACE Version**: 12.0.9.0 or higher (ACE 13.x testing in progress)
- **Java**: JDK 8 or higher (included with ACE)
- **PowerShell**: Version 5.1 or higher (for automated installation)

### Required Permissions
- **Administrator privileges** are recommended for installation
- Write access to ACE installation directory (typically `C:\Program Files\IBM\ACE\`)
- Write access to MQSI registry directory (typically `C:\ProgramData\IBM\MQSI`)

### Before You Begin
1. **Identify your ACE installation path**
   - Default location: `C:\Program Files\IBM\ACE\[version]`
   - To find it, look for the `ace.cmd` file

2. **Determine your environment variables**
   - Open a command prompt and run:
     ```cmd
     "C:\Program Files\IBM\ACE\[version]\ace.cmd"
     echo %MQSI_BASE_FILEPATH%
     echo %MQSI_REGISTRY%
     ```
   - Note these values for manual installation

3. **Check for existing installations**
   - If you have a previous version of PGP SupportPac installed, the installation scripts will create backups automatically

---

## Pre-Installation Steps

### 1. Stop ACE Services
Before installation, stop all running ACE components:

```cmd
REM Stop Integration Servers by terminating the process

REM Stop Integration Nodes (if applicable)
mqsistop [IntegrationNodeName]
```

### 2. Close ACE Toolkit
If the ACE Toolkit is open, close it completely before proceeding.

### 3. Backup (Optional but Recommended)
The automated scripts create backups automatically. For manual installation, consider backing up:
- `%MQSI_BASE_FILEPATH%\server\jplugin\`
- `%MQSI_BASE_FILEPATH%\tools\plugins\`
- `%MQSI_REGISTRY%\shared-classes\`a

---

## Installation Methods

### Automated Installation (Recommended)

#### Option 1: PowerShell Script

**Basic Installation:**
```powershell
cd installation-scripts
.\Install-PGPSupportPac.ps1
```

**With Custom ACE Path:**
```powershell
.\Install-PGPSupportPac.ps1 -ACEInstallPath "C:\Program Files\IBM\ACE\13.0.6.0"
```

**Force Installation (No Confirmation):**
```powershell
.\Install-PGPSupportPac.ps1 -Force
```

**Skip Backup:**
```powershell
.\Install-PGPSupportPac.ps1 -SkipBackup
```

**PowerShell Script Features:**
- ✅ Automatic ACE installation detection
- ✅ Pre-flight checks (admin rights, file existence)
- ✅ Automatic backup of existing files
- ✅ Detailed logging
- ✅ Post-installation verification
- ✅ Color-coded output
- ✅ Rollback capability on failure

#### Option 2: Batch File Script

For environments where PowerShell execution is restricted:

**Basic Installation:**
```cmd
cd installation-scripts
install-pgp-supportpac.bat
```

**With Custom ACE Path:**
```cmd
install-pgp-supportpac.bat "C:\Program Files\IBM\ACE\13.0.6.0"
```

**Force Installation:**
```cmd
install-pgp-supportpac.bat /force /skipbackup
```

---

### Manual Installation

If you prefer to install manually or the automated scripts don't work in your environment:

#### Step 1: Determine Installation Paths

Run the ACE command console to get environment variables:
```cmd
"C:\Program Files\IBM\ACE\[version]\ace.cmd"
echo %MQSI_BASE_FILEPATH%
echo %MQSI_REGISTRY%
```

Example output:
```
MQSI_BASE_FILEPATH=C:\Program Files\IBM\ACE\13.0.6.0
MQSI_REGISTRY=C:\ProgramData\IBM\MQSI
```

#### Step 2: Copy Server Plugin

Copy `PGPSupportPacImpl.jar` to the server jplugin directory:
```cmd
copy "MQSI_BASE_FILEPATH\server\jplugin\PGPSupportPacImpl.jar" "%MQSI_BASE_FILEPATH%\server\jplugin\"
```

#### Step 3: Copy Toolkit Plugin

Copy `PGPSupportPac.jar` to the tools plugins directory:
```cmd
copy "MQSI_BASE_FILEPATH\tools\plugins\PGPSupportPac.jar" "%MQSI_BASE_FILEPATH%\tools\plugins\"
```

#### Step 4: Copy Bouncy Castle Libraries

Copy both Bouncy Castle JAR files to the shared-classes directory:
```cmd
REM Create directory if it doesn't exist
if not exist "%MQSI_REGISTRY%\shared-classes" mkdir "%MQSI_REGISTRY%\shared-classes"

REM Copy libraries
copy "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.78.1.jar" "%MQSI_REGISTRY%\shared-classes\"
copy "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.78.1.jar" "%MQSI_REGISTRY%\shared-classes\"
```

#### Step 5: Verify Files

Verify all files were copied successfully:
```cmd
dir "%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar"
dir "%MQSI_BASE_FILEPATH%\tools\plugins\PGPSupportPac.jar"
dir "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar"
dir "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar"
```

---

## Post-Installation

### 1. Restart ACE Components

After installation, restart all ACE components:

```cmd
REM Start Integration Nodes (if applicable)
mqsistart [IntegrationNodeName]

REM Start Integration Servers
mqsistart [IntegrationServerName]
```

### 2. Restart ACE Toolkit

If you use the ACE Toolkit:
1. Close the Toolkit completely
2. Reopen it
3. The PGP nodes should now be available in the palette

### 3. Verify PGP Nodes Available

In the ACE Toolkit:
1. Open the **Palette** view
2. Look for **PGP** nodes under the **Security** or **Transformation** section
3. You should see:
   - PGPEncrypt
   - PGPDecrypt
   - PGPSign
   - PGPVerify

---

## Verification

### Verify Installation Files

Run this command to check all files are present:

```cmd
dir "%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar" && ^
dir "%MQSI_BASE_FILEPATH%\tools\plugins\PGPSupportPac.jar" && ^
dir "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar" && ^
dir "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar" && ^
echo All files verified successfully!
```

### Test with Sample Flow

1. Import the test project from `Test Project\TestPGP.zip`
2. Create a policy project with PGP configuration
3. Deploy and test the encryption/decryption flows

---

## Using pgpKeytool Command Line

The PGP SupportPac includes a command-line tool for managing PGP keys and keystores.

### Setup

1. Open an **ACE Command Console**:
   ```cmd
   "C:\Program Files\IBM\ACE\[version]\ace.cmd"
   ```

2. Add the required JARs to your CLASSPATH:
   ```cmd
   SET CLASSPATH=%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar;%CLASSPATH%
   SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar;%CLASSPATH%
   SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar;%CLASSPATH%
   ```

### Common Commands

**List keys in a keystore:**
```cmd
java com.ibm.broker.supportpac.pgp.PGPKeytool -list -keystore mykeys.pgp
```

**Generate a new key pair:**
```cmd
java com.ibm.broker.supportpac.pgp.PGPKeytool -genkey -alias mykey -keystore mykeys.pgp
```

**Export a public key:**
```cmd
java com.ibm.broker.supportpac.pgp.PGPKeytool -export -alias mykey -keystore mykeys.pgp -file publickey.asc
```

**Import a public key:**
```cmd
java com.ibm.broker.supportpac.pgp.PGPKeytool -import -alias theirkey -keystore mykeys.pgp -file theirpublickey.asc
```

For detailed pgpKeytool usage, refer to:
- [PGP SupportPac User Guide](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/docs/PGP%20Security%20Implementation%20in%20IBM%20Integration%20Bus%20v10%20Part-1%20PGP%20SupportPac%20User%20Guide.pdf)

---

## Troubleshooting

### Installation Issues

#### Problem: "Access Denied" Error
**Solution:**
- Run the installation script as Administrator
- Right-click PowerShell/Command Prompt → "Run as Administrator"

#### Problem: ACE Installation Not Found
**Solution:**
- Verify ACE is installed: Check for `ace.cmd` in `C:\Program Files\IBM\ACE\[version]\`
- Specify the path explicitly:
  ```powershell
  .\Install-PGPSupportPac.ps1 -ACEInstallPath "C:\Program Files\IBM\ACE\13.0.6.0"
  ```

#### Problem: MQSI_REGISTRY Not Set
**Solution:**
- The default location is `C:\ProgramData\IBM\MQSI`
- Set it manually if needed:
  ```cmd
  set MQSI_REGISTRY=C:\ProgramData\IBM\MQSI
  ```

### Runtime Issues

#### Problem: PGP Nodes Not Visible in Toolkit
**Solution:**
1. Verify `PGPSupportPac.jar` is in `%MQSI_BASE_FILEPATH%\tools\plugins\`
2. Completely close and restart the ACE Toolkit
3. Check Toolkit logs: `%USERPROFILE%\.eclipse\[workspace]\.metadata\.log`

#### Problem: ClassNotFoundException at Runtime
**Solution:**
1. Verify all four JAR files are installed correctly
2. Restart the Integration Server
3. Check Integration Server logs for detailed error messages

#### Problem: "Algorithm Not Found" Error
**Solution:**
- Ensure both Bouncy Castle JARs are in `%MQSI_REGISTRY%\shared-classes\`:
  - `bcpg-jdk18on-1.78.1.jar`
  - `bcprov-jdk18on-1.78.1.jar`

### Verification Commands

**Check if files exist:**
```cmd
dir "%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar"
dir "%MQSI_BASE_FILEPATH%\tools\plugins\PGPSupportPac.jar"
dir "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar"
dir "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar"
```

**Check Integration Server logs:**
```cmd
type "%MQSI_WORKPATH%\[IntegrationServerName]\stdout"
type "%MQSI_WORKPATH%\[IntegrationServerName]\stderr"
```

---

## Uninstallation

To remove the PGP SupportPac:

### Automated Uninstallation

If you used the automated installation and have a backup:

1. Stop ACE components
2. Restore from backup:
   ```cmd
   cd installation-scripts\backup\[timestamp]
   xcopy /s /y * "%MQSI_BASE_FILEPATH%\"
   xcopy /s /y shared-classes\* "%MQSI_REGISTRY%\shared-classes\"
   ```

### Manual Uninstallation

1. Stop all ACE components
2. Delete the installed files:
   ```cmd
   del "%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar"
   del "%MQSI_BASE_FILEPATH%\tools\plugins\PGPSupportPac.jar"
   del "%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar"
   del "%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar"
   ```
3. Restart ACE components

---

## ACE 13.x Compatibility Notes

### Current Status
- **Officially Tested**: ACE 12.0.9.0 through 12.0.12.5
- **ACE 13.x**: Testing in progress

### Known Considerations for ACE 13.x

1. **Java Version**: ACE 13.x may use a different Java version. The Bouncy Castle libraries (1.78.1) are compatible with JDK 8+.

2. **Installation Paths**: ACE 13.x follows the same directory structure as ACE 12.x, so installation should work identically.

3. **API Changes**: If IBM made breaking changes to the plugin API in ACE 13.x, the PGP nodes may not function correctly.

### Testing Recommendations

If you're installing on ACE 13.x:

1. **Test in a non-production environment first**
2. **Verify basic functionality**:
   - PGP nodes appear in Toolkit
   - Simple encryption/decryption flows work
   - Key management operations function correctly

3. **Report Results**:
   - If successful, please report to the project maintainers
   - If issues occur, provide:
     - ACE version (exact build number)
     - Error messages from logs
     - Steps to reproduce

### Rollback Plan

Keep your backup accessible in case you need to rollback:
- Automated installation creates backups in `installation-scripts\backup\[timestamp]\`
- Test thoroughly before deploying to production

---

## Additional Resources

- **Original Project**: [MyOpenTech-PGP-SupportPac](https://github.com/matthiasblomme/MyOpenTech-PGP-SupportPac)
- **User Guide**: [PGP SupportPac User Guide PDF](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/docs/PGP%20Security%20Implementation%20in%20IBM%20Integration%20Bus%20v10%20Part-1%20PGP%20SupportPac%20User%20Guide.pdf)
- **Presentation**: [PGP SupportPac v1.0.0.2 IIBv10.ppt](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/PGP%20SupportPac%20v1.0.0.2%20IIBv10.ppt)

---

## Support

For issues or questions:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review the installation logs in `installation-scripts\`
3. Consult the additional resources above
4. Report issues to the project repository

---

**Last Updated**: 2026-02-11  
**Version**: 1.0.0