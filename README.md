# PGP Support Pac for IBM App Connect Enterprise

## Description
PGP SupportPac for IBM App Connect Enterprise V12.0.10 onwards (ACE 13.x testing in progress). It uses the compiled code from
[MyOpenTech-PGP-SupportPac](https://github.com/matthiasblomme/MyOpenTech-PGP-SupportPac) which on its own is a fork from
[dipakpal/MyOpenTech-PGP-SupportPac](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac)

This project provides all the JAR files you need to enable PGP encryption/decryption capabilities in IBM ACE.

## Quick Start

**For detailed installation instructions, see [INSTALLATION.md](INSTALLATION.md)**

### Automated Installation (Recommended)
```cmd
cd installation-scripts
install-pgp-supportpac.bat
```

## Content

### [MQSI_BASE_FILEPATH](MQSI_BASE_FILEPATH)
Jar files for server and tools

### [MQSI_REGISTRY](MQSI_REGISTRY)
Supported classes for pgp operations

### [Test Project](Test%20Project)
Test project interchange containing an application with an encryption and decryption flow. A policy project needs to be
created in order to be able to use it.

## Installation

### Prerequisites
- IBM App Connect Enterprise 12.0.9.0 or higher
- Administrator privileges (recommended)
- Windows operating system

### Quick Installation

**Automated Installation (Recommended)**
```cmd
cd installation-scripts
install-pgp-supportpac.bat
```

**Manual Installation**

All files are organized by their target location relative to your system's `MQSI_BASE_FILEPATH` and `MQSI_REGISTRY` variables.

For example, if you have:
- `MQSI_BASE_FILEPATH=C:\Program Files\IBM\ACE\13.0.6.0`
- `MQSI_REGISTRY=C:\ProgramData\IBM\MQSI`

Then copy files to:
- `C:\Program Files\IBM\ACE\13.0.6.0\server\jplugin\PGPSupportPacImpl.jar`
- `C:\Program Files\IBM\ACE\13.0.6.0\tools\plugins\PGPSupportPac.jar`
- `C:\ProgramData\IBM\MQSI\shared-classes\bcpg-jdk18on-1.78.1.jar`
- `C:\ProgramData\IBM\MQSI\shared-classes\bcprov-jdk18on-1.78.1.jar`

**For complete installation instructions, troubleshooting, and verification steps, see [INSTALLATION.md](INSTALLATION.md)**

## pgpKeytool Command Line Utility

This deliverable includes a command-line tool for managing PGP keys and keystores (create, import, export, list, etc.).

### Setup

1. Open an ACE Command Console for your ACE version
2. Add the required JARs to your CLASSPATH:

```cmd
SET CLASSPATH=%MQSI_BASE_FILEPATH%\server\jplugin\PGPSupportPacImpl.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcpg-jdk18on-1.78.1.jar;%CLASSPATH%
SET CLASSPATH=%MQSI_REGISTRY%\shared-classes\bcprov-jdk18on-1.78.1.jar;%CLASSPATH%
```

### Example Usage

```cmd
REM List keys in a keystore
java com.ibm.broker.supportpac.pgp.PGPKeytool -list -keystore mykeys.pgp

REM Generate a new key pair
java com.ibm.broker.supportpac.pgp.PGPKeytool -genkey -alias mykey -keystore mykeys.pgp
```

**For detailed pgpKeytool usage, see [INSTALLATION.md](INSTALLATION.md#using-pgpkeytool-command-line) and the resources in [Additional reading](#additional-reading).**

![img.png](img.png)

## Compatibility Status

| ACE Version | Status               | Date        | Notes |
|-------------|----------------------|-------------|-------|
| 12.0.9.0    | ✅ Tested and validated | 2024/05/01  | |
| 12.0.10.0   | ✅ Tested and validated | 2024/05/01  | |
| 12.0.11.3   | ✅ Tested and validated | 2024/05/01  | |
| 12.0.12.5   | ✅ Tested and validated | 2024/10/24   |  |
| 13.0.6.0    | 🧪 Testing in progress | 2026/02/11   | See [INSTALLATION.md](INSTALLATION.md#ace-13x-compatibility-notes) |

**Note**: ACE 13.x has not been officially tested yet. If you're using ACE 13.x, please test thoroughly in a non-production environment first and report your results.

## Project Structure

```
PGP-SupportPac-for-IBM-ACE-V12/
├── README.md                          # This file
├── INSTALLATION.md                    # Comprehensive installation guide
├── installation-scripts/              # Automated installation scripts
│   ├── Install-PGPSupportPac.ps1     # PowerShell installation script
│   └── install-pgp-supportpac.bat    # Batch file installation script
├── MQSI_BASE_FILEPATH/               # Files for ACE installation directory
│   ├── server/jplugin/               # Server-side plugins
│   │   └── PGPSupportPacImpl.jar
│   └── tools/plugins/                # Toolkit plugins
│       └── PGPSupportPac.jar
├── MQSI_REGISTRY/                    # Files for MQSI registry directory
│   └── shared-classes/               # Shared libraries
│       ├── bcpg-jdk18on-1.78.1.jar   # Bouncy Castle PGP library
│       └── bcprov-jdk18on-1.78.1.jar # Bouncy Castle crypto provider
└── Test Project/                     # Sample test project
    └── TestPGP.zip
```

## Authors & Contributors

| Name     | Role                     | Date       |
|----------|--------------------------|------------|
| Matthias | Upgrade PGP support jars | 2024/05/01 |
| Matthias | Updated keytool info     | 2024/09/09 |
| Matthias | Added installation automation | 2026/02/11 |

## Additional reading
[PGP SupportPac v1.0.0.2 IIBv10.ppt](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/PGP%20SupportPac%20v1.0.0.2%20IIBv10.ppt)

[PGP Security Implementation in IBM Integration Bus v10 Part-1 PGP SupportPac User Guide.pdf](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/docs/PGP%20Security%20Implementation%20in%20IBM%20Integration%20Bus%20v10%20Part-1%20PGP%20SupportPac%20User%20Guide.pdf)
