@echo off
REM ============================================================================
REM Node-Managed Integration Server - Setup and Test Script
REM ============================================================================
REM This script creates an integration node with two servers and tests PGP
REM encryption/decryption across the servers.
REM ============================================================================

setlocal enabledelayedexpansion

REM Configuration
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..\..\..
set TEST_RESOURCES=%PROJECT_ROOT%\testing\test-resources
set SOURCES_DIR=%TEST_RESOURCES%\Sources
set NODE_NAME=TEST_NODE
set NODE_WORK_DIR=C:\temp\pgp-node\%NODE_NAME%
set SERVER_ENCRYPT=SERVER_ENCRYPT
set SERVER_DECRYPT=SERVER_DECRYPT
set TEST_DIR=C:\temp\pgp
set PORT_ENCRYPT=7800
set PORT_DECRYPT=7801

echo ============================================================================
echo Node-Managed PGP SupportPac Testing
echo ============================================================================
echo.
echo Configuration:
echo   Node Name: %NODE_NAME%
echo   Node Work Dir: %NODE_WORK_DIR%
echo   Server 1 (Encrypt): %SERVER_ENCRYPT% (port %PORT_ENCRYPT%)
echo   Server 2 (Decrypt): %SERVER_DECRYPT% (port %PORT_DECRYPT%)
echo   Test Resources: %SOURCES_DIR%
echo.

REM ============================================================================
REM Step 1: Source ACE Environment
REM ============================================================================
echo [Step 1/13] Sourcing ACE environment...
call "C:\Program Files\IBM\ACE\13.0.7.0\server\bin\mqsiprofile.cmd"
if errorlevel 1 (
    echo [ERROR] Failed to source ACE environment
    goto :error_exit
)
echo [OK] ACE environment loaded
echo.

REM ============================================================================
REM Step 2: Install PGP SupportPac (force clean install before testing)
REM ============================================================================
echo [Step 2/13] Installing PGP SupportPac...
call "%PROJECT_ROOT%\installation-scripts\install-pgp-supportpac.bat" /force /skipbackup
if errorlevel 1 (
    echo [ERROR] PGP SupportPac installation failed
    goto :error_exit
)
echo [OK] PGP SupportPac installed
echo.

REM ============================================================================
REM Step 3: Clean Up Old Node (if exists) and Create Parent Directory
REM ============================================================================
echo [Step 3/13] Cleaning up old node (if exists)...
echo [INFO] Stopping old node...
ibmint stop node %NODE_NAME% 2>nul
timeout /t 3 /nobreak >nul
echo [INFO] Deleting old node with all files...
ibmint delete node %NODE_NAME% --delete-all-files 2>nul
timeout /t 3 /nobreak >nul
echo [OK] Old node cleaned up

REM Create parent directory
mkdir C:\temp\pgp-node 2>nul
echo [OK] Parent directory ready
echo.

REM ============================================================================
REM Step 4: Create Integration Node
REM ============================================================================
echo [Step 4/13] Creating integration node...
ibmint create node %NODE_NAME% --work-path "%NODE_WORK_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to create integration node
    goto :error_exit
)
echo [OK] Integration node created
echo.

REM ============================================================================
REM Step 5: Start Integration Node
REM ============================================================================
echo [Step 5/13] Starting integration node...
ibmint start node %NODE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to start integration node
    goto :error_exit
)
echo [OK] Integration node started
timeout /t 5 /nobreak >nul
echo.

REM ============================================================================
REM Step 6: Create Integration Servers
REM ============================================================================
echo [Step 6/13] Creating integration servers...
echo [INFO] Creating %SERVER_ENCRYPT%...
ibmint create server %SERVER_ENCRYPT% --integration-node %NODE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to create %SERVER_ENCRYPT%
    goto :error_exit
)
echo [OK] %SERVER_ENCRYPT% created

echo [INFO] Creating %SERVER_DECRYPT%...
ibmint create server %SERVER_DECRYPT% --integration-node %NODE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to create %SERVER_DECRYPT%
    goto :error_exit
)
echo [OK] %SERVER_DECRYPT% created
echo.

REM ============================================================================
REM Step 7: Install Bouncy Castle JARs
REM ============================================================================
echo [Step 7/13] Installing Bouncy Castle JARs at node level...
echo [INFO] Creating node shared-classes directory...
mkdir "%NODE_WORK_DIR%\shared-classes" 2>nul

echo [INFO] Copying JARs to node shared-classes...
copy /Y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "%NODE_WORK_DIR%\shared-classes\" >nul
copy /Y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "%NODE_WORK_DIR%\shared-classes\" >nul
copy /Y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcutil-jdk18on-1.81.jar" "%NODE_WORK_DIR%\shared-classes\" >nul

if errorlevel 1 (
    echo [ERROR] Failed to copy Bouncy Castle JARs
    goto :error_exit
)
echo [OK] Bouncy Castle JARs installed at node level
echo [INFO] Note: In node-managed environments, JARs must be at NODE level, not server level
echo.

REM ============================================================================
REM Step 8: Restart Node (Required after installing JARs)
REM ============================================================================
echo [Step 8/13] Restarting node to load JARs...
ibmint stop node %NODE_NAME%
timeout /t 3 /nobreak >nul
ibmint start node %NODE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to restart integration node
    goto :error_exit
)
echo [OK] Node restarted
timeout /t 5 /nobreak >nul
echo.

REM ============================================================================
REM Step 9: Configure HTTP Ports
REM ============================================================================
echo [Step 9/13] Configuring HTTP ports...
echo [INFO] Configuring %SERVER_ENCRYPT% port %PORT_ENCRYPT%...
mkdir "%NODE_WORK_DIR%\servers\%SERVER_ENCRYPT%\overrides" 2>nul
(
echo HTTPListener:
echo   port: %PORT_ENCRYPT%
) > "%NODE_WORK_DIR%\servers\%SERVER_ENCRYPT%\overrides\server.conf.yaml"

echo [INFO] Configuring %SERVER_DECRYPT% port %PORT_DECRYPT%...
mkdir "%NODE_WORK_DIR%\servers\%SERVER_DECRYPT%\overrides" 2>nul
(
echo HTTPListener:
echo   port: %PORT_DECRYPT%
) > "%NODE_WORK_DIR%\servers\%SERVER_DECRYPT%\overrides\server.conf.yaml"

echo [OK] HTTP ports configured
echo.

REM ============================================================================
REM Step 10: Restart Node to Apply Port Configuration
REM ============================================================================
echo [Step 10/13] Restarting node to apply port configuration...
ibmint stop node %NODE_NAME%
timeout /t 3 /nobreak >nul
ibmint start node %NODE_NAME%
if errorlevel 1 (
    echo [ERROR] Failed to restart integration node
    goto :error_exit
)
echo [OK] Node restarted
timeout /t 10 /nobreak >nul
echo.

REM ============================================================================
REM Step 11: Deploy Applications
REM ============================================================================
echo [Step 11/13] Deploying applications...
echo [INFO] Deploying to %SERVER_ENCRYPT%...
ibmint deploy --input-path "%SOURCES_DIR%" --output-integration-node %NODE_NAME% --output-integration-server %SERVER_ENCRYPT% --project PGP_Policies
if errorlevel 1 (
    echo [ERROR] Failed to deploy PGP_Policies to %SERVER_ENCRYPT%
    goto :error_exit
)

ibmint deploy --input-path "%SOURCES_DIR%" --output-integration-node %NODE_NAME% --output-integration-server %SERVER_ENCRYPT% --project TestPGP_App
if errorlevel 1 (
    echo [ERROR] Failed to deploy TestPGP_App to %SERVER_ENCRYPT%
    goto :error_exit
)
echo [OK] Deployed to %SERVER_ENCRYPT%

echo [INFO] Deploying to %SERVER_DECRYPT%...
ibmint deploy --input-path "%SOURCES_DIR%" --output-integration-node %NODE_NAME% --output-integration-server %SERVER_DECRYPT% --project PGP_Policies
if errorlevel 1 (
    echo [ERROR] Failed to deploy PGP_Policies to %SERVER_DECRYPT%
    goto :error_exit
)

ibmint deploy --input-path "%SOURCES_DIR%" --output-integration-node %NODE_NAME% --output-integration-server %SERVER_DECRYPT% --project TestPGP_App
if errorlevel 1 (
    echo [ERROR] Failed to deploy TestPGP_App to %SERVER_DECRYPT%
    goto :error_exit
)
echo [OK] Deployed to %SERVER_DECRYPT%
echo.

REM Wait for deployments to complete
echo [INFO] Waiting for deployments to complete...
timeout /t 10 /nobreak >nul

REM ============================================================================
REM Step 12: Verify HTTP Listeners
REM ============================================================================
echo [Step 12/13] Verifying HTTP listeners...
netstat -ano | findstr ":%PORT_ENCRYPT%" | findstr "LISTENING" >nul
if errorlevel 1 (
    echo [WARNING] HTTP listener not found on port %PORT_ENCRYPT%
) else (
    echo [OK] HTTP listener active on port %PORT_ENCRYPT%
)

netstat -ano | findstr ":%PORT_DECRYPT%" | findstr "LISTENING" >nul
if errorlevel 1 (
    echo [WARNING] HTTP listener not found on port %PORT_DECRYPT%
) else (
    echo [OK] HTTP listener active on port %PORT_DECRYPT%
)
echo.

REM ============================================================================
REM Step 13: Run Tests
REM ============================================================================
echo [Step 13/13] Running PGP encryption/decryption tests...
echo.

REM Create test directories and file
if not exist "%TEST_DIR%\input" mkdir "%TEST_DIR%\input"
if not exist "%TEST_DIR%\output" mkdir "%TEST_DIR%\output"
echo This is a test file for node-managed PGP encryption > "%TEST_DIR%\input\plain.txt"
echo [OK] Test file created

echo.
echo [TEST 1] Testing encryption on %SERVER_ENCRYPT% (port %PORT_ENCRYPT%)...
curl -X POST http://localhost:%PORT_ENCRYPT%/pgp/encrypt -o "%TEST_DIR%\output\encrypted.txt"
if errorlevel 1 (
    echo [ERROR] Encryption test failed
    goto :error_exit
)
echo.
echo [OK] Encryption test completed

echo.
echo [TEST 2] Testing decryption on %SERVER_DECRYPT% (port %PORT_DECRYPT%)...
curl -X POST http://localhost:%PORT_DECRYPT%/pgp/decrypt -o "%TEST_DIR%\input\plain-decrypted.txt"
if errorlevel 1 (
    echo [ERROR] Decryption test failed
    goto :error_exit
)
echo [OK] Decryption test completed

REM ============================================================================
REM Verify Results
REM ============================================================================
echo.
echo ============================================================================
echo Test Results
echo ============================================================================
echo.
echo Original file:
type "%TEST_DIR%\input\plain.txt"
echo.
echo Decrypted file:
type "%TEST_DIR%\input\plain-decrypted.txt"
echo.

REM Compare files
fc /B "%TEST_DIR%\input\plain.txt" "%TEST_DIR%\input\plain-decrypted.txt" >nul
if errorlevel 1 (
    echo [WARNING] Original and decrypted files do not match!
) else (
    echo [SUCCESS] Original and decrypted files match perfectly!
)

echo.
echo ============================================================================
echo Node-Managed Testing Complete!
echo ============================================================================
echo.
echo Node Information:
echo   Node Name: %NODE_NAME%
echo   Work Directory: %NODE_WORK_DIR%
echo   Server 1: %SERVER_ENCRYPT% (http://localhost:%PORT_ENCRYPT%)
echo   Server 2: %SERVER_DECRYPT% (http://localhost:%PORT_DECRYPT%)
echo.
echo To stop the node:
echo   ibmint stop node %NODE_NAME% --work-dir "%NODE_WORK_DIR%"
echo.
echo To remove the node:
echo   rmdir /S /Q "%NODE_WORK_DIR%"
echo.
goto :normal_exit

:error_exit
echo.
echo ============================================================================
echo [ERROR] Script failed!
echo ============================================================================
echo.
echo Check the logs:
echo   %NODE_WORK_DIR%\servers\%SERVER_ENCRYPT%\log\
echo   %NODE_WORK_DIR%\servers\%SERVER_DECRYPT%\log\
echo.
endlocal
exit /b 1

:normal_exit
endlocal
exit /b 0