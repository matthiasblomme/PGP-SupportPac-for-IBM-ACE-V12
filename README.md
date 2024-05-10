# PGP-Support-Pac-for-IBM-AppConnect-Enterprise-V12

## Description
PGP SupportPac for IBM App Connect Enterprise V12.0.10 onwards. It uses the compiled code from 
[MyOpenTech-PGP-SupportPac](https://github.com/matthiasblomme/MyOpenTech-PGP-SupportPac) which on its own is a fork from
[dipakpal/MyOpenTech-PGP-SupportPac](https://github.com/dipakpal/MyOpenTech-PGP-SupportPac)

This project gives you all the jars you need to place on your system to get the PGP encryption/decryption up and running

## Installation
All the files are bundled per location you need to create them. The folder structure is relative to yor system's MQSI_BASE_FILEPATH
 and ... variable. For instance, if you have

`
MQSI_BASE_FILEPATH=C:\Program Files\IBM\ACE\12.0.11.3
MQSI_REGISTRY=C:\ProgramData\IBM\MQSI
`
Then the full paths to cpy the files to will become
`
C:\Program Files\IBM\ACE\12.0.11.3\server\jplugin
C:\Program Files\IBM\ACE\12.0.11.3\tools\plugins
C:\ProgramData\IBM\MQSI\shared-classes
`
## Status
| ACE Version | Status | Date |
|-------------|--------|------|
| 12.0.9.0    |        |      |
| 12.0.10.0   |        |      |
| 12.0.11.3   | Tested, validated and live| 2024/05/01|

## Authors
| Name     | Role                     | Date       |
|----------|--------------------------|------------|
| Matthias | Upgrade pgp support jars | 2024/05/01 |