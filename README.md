# PGP-Support-Pac-for-IBM-AppConnect-Enterprise-V12

## Description
PGP SupportPac for IBM App Connect Enterprise V12.0.10 onwards. It uses the compiled code from 
[MyOpenTech-PGP-SupportPac](https://github.com/matthiasblomme/MyOpenTech-PGP-SupportPac) which on its own is a fork from
[dipakpal/MyOpenTech-PGP-SupportPac](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac)

This project gives you all the jars you need to place on your system to get the PGP encryption/decryption up and running

## Content

### [MQSI_BASE_FILEPATH](MQSI_BASE_FILEPATH)
Jar files for server and tools

### [MQSI_REGISTRY](MQSI_REGISTRY)
Supported classes for pgp operations

### [Test Project](Test%20Project)
Test project interchange containing an aplication with an encryption and decryption flow. A policy project needs to be 
created in order to be able to use it.

## Installation
All the files are bundled per location you need to create them. The folder structure is relative to yor system's 
MQSI_BASE_FILEPATH and MQSI_REGISTRY variable. For instance, if you have

`MQSI_BASE_FILEPATH=C:\Program Files\IBM\ACE\12.0.11.3`

`MQSI_REGISTRY=C:\ProgramData\IBM\MQSI`

Then the full paths to cpy the files to will become

`C:\Program Files\IBM\ACE\12.0.11.3\server\jplugin`

`C:\Program Files\IBM\ACE\12.0.11.3\tools\plugins`

`C:\ProgramData\IBM\MQSI\shared-classes`

## Status
| ACE Version | Status               | Date        |
|-------------|----------------------|-------------|
| 12.0.9.0    | Tested and validated | 2024/05/01  |
| 12.0.10.0   | Tested and validated | 2024/05/01  |
| 12.0.11.3   | Tested and validated | 2024/05/01  |

## Authors
| Name     | Role                     | Date       |
|----------|--------------------------|------------|
| Matthias | Upgrade pgp support jars | 2024/05/01 |

## Additional reading
[PGP SupportPac v1.0.0.2 IIBv10.ppt](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/PGP%20SupportPac%20v1.0.0.2%20IIBv10.ppt)

[PGP Security Implementation in IBM Integration Bus v10 Part-1 PGP SupportPac User Guide.pdf](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac/blob/master/docs/PGP%20Security%20Implementation%20in%20IBM%20Integration%20Bus%20v10%20Part-1%20PGP%20SupportPac%20User%20Guide.pdf)
