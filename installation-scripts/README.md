# Installation Scripts

This directory contains an automated installation script for the PGP SupportPac for IBM App Connect Enterprise.

## Available Script

### install-pgp-supportpac.bat (Batch File)
**Recommended installation method**

A batch file script that automates the full PGP SupportPac installation.

#### Requirements
- Windows Command Prompt
- Windows operating system
- Administrator privileges (recommended)

#### Usage

**Basic installation (auto-detect ACE):**
```cmd
install-pgp-supportpac.bat
```

**Specify ACE installation path:**
```cmd
install-pgp-supportpac.bat "C:\Program Files\IBM\ACE\13.0.6.0"
```

**Force installation without confirmation:**
```cmd
install-pgp-supportpac.bat /force
```

**Skip backup creation:**
```cmd
install-pgp-supportpac.bat /skipbackup
```

**Combine options:**
```cmd
install-pgp-supportpac.bat "C:\Program Files\IBM\ACE\13.0.6.0" /force /skipbackup
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| First argument | String | No | Path to ACE installation. Auto-detected if not specified. |
| `/force` or `-force` | Flag | No | Skip confirmation prompt |
| `/skipbackup` or `-skipbackup` | Flag | No | Skip creating backup of existing files |

#### Output

The script creates:
- **Log file**: `install-[timestamp].log` in the scripts directory
- **Backup directory**: `backup\[timestamp]\` (unless `/skipbackup` is used)

---

## What Gets Installed

The script installs the following files:

| Source File | Destination |
|-------------|-------------|
| `PGPSupportPacImpl.jar` | `%MQSI_BASE_FILEPATH%\server\jplugin\` |
| `PGPSupportPac.jar` | `%MQSI_BASE_FILEPATH%\tools\plugins\` |
| `bcpg-jdk18on-1.81.jar` | `%MQSI_REGISTRY%\shared-classes\` |
| `bcprov-jdk18on-1.81.jar` | `%MQSI_REGISTRY%\shared-classes\` |
| `bcutil-jdk18on-1.81.jar` | `%MQSI_REGISTRY%\shared-classes\` |

---

## Installation Process

The script follows this process:

1. **Pre-flight Checks**
   - Check for administrator privileges
   - Verify all source files exist
   - Detect or validate ACE installation

2. **Display Installation Plan**
   - Show target directories
   - List files to be installed
   - Warn about existing files that will be overwritten

3. **User Confirmation**
   - Prompt for confirmation (unless `/force` is used)

4. **Backup Existing Files**
   - Create timestamped backup directory
   - Copy existing files (unless `/skipbackup` is used)

5. **Copy Files**
   - Copy all five JAR files to their destinations
   - Verify each copy operation

6. **Verify Installation**
   - Check all files exist
   - Verify files are not empty
   - Report any issues

7. **Display Completion Message**
   - Show installation summary
   - Provide next steps
   - Display log file location

---

## Troubleshooting

### Access Denied Errors

Run the script as Administrator:
- Right-click PowerShell/Command Prompt
- Select "Run as Administrator"
- Navigate to the scripts directory
- Run the installation script

### ACE Installation Not Found

If auto-detection fails, specify the path explicitly:

```cmd
install-pgp-supportpac.bat "C:\Program Files\IBM\ACE\13.0.6.0"
```

### Script Hangs or Fails

1. Check the log file: `install-[timestamp].log`
2. Ensure no ACE processes are running
3. Verify you have write permissions to target directories
4. Try running with administrator privileges

---

## Log Files

The script creates a detailed log file with a timestamp:
- **Location**: Same directory as the script
- **Format**: `install-[timestamp].log`
- **Content**: All operations, errors, and warnings

Example log file name: `install-20260211-123456.log`

---

## Backup Files

If backup is enabled (default), files are stored in:
- **Location**: `backup\[timestamp]\`
- **Structure**: Mirrors the original directory structure
- **Content**: Only files that existed before installation

Example backup location: `backup\20260211-123456\`

To restore from backup:
```cmd
xcopy /s /y backup\[timestamp]\* "%MQSI_BASE_FILEPATH%\"
xcopy /s /y backup\[timestamp]\shared-classes\* "%MQSI_REGISTRY%\shared-classes\"
```

---

## Post-Installation

After running the script:

1. **Restart ACE Components**
   ```cmd
   mqsistop [IntegrationServerName]
   mqsistart [IntegrationServerName]
   ```

2. **Restart ACE Toolkit**
   - Close completely
   - Reopen
   - Verify PGP nodes appear in the palette

3. **Test Installation**
   - Import test project from `Test Project\TestPGP.zip`
   - Create PGP policy
   - Test encryption/decryption flows

---

## Additional Resources

- **Comprehensive Guide**: See [../INSTALLATION.md](../INSTALLATION.md)
- **Main README**: See [../README.md](../README.md)
- **PGP User Guide**: [PGP SupportPac User Guide PDF](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/docs/PGP%20Security%20Implementation%20in%20IBM%20Integration%20Bus%20v10%20Part-1%20PGP%20SupportPac%20User%20Guide.pdf)

---

## Support

For issues or questions:
1. Check the log file in this directory
2. Review the [Troubleshooting](#troubleshooting) section
3. See [../INSTALLATION.md](../INSTALLATION.md) for detailed guidance
4. Report issues to the project repository

---

**Last Updated**: 2026-04-01  
**Version**: 1.0.0