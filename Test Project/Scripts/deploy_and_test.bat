@echo off
REM ============================================================================
REM PGP SupportPac - Complete Deployment and Test Script for ACE 13.0.6.0
REM ============================================================================
REM This script performs a complete setup, deployment, and test of the PGP
REM SupportPac for IBM ACE 13.0.6.0
REM ============================================================================

setlocal enabledelayedexpansion

REM Configuration
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..\..
set TEST_PROJECT=%PROJECT_ROOT%\Test Project
set SOURCES_DIR=%TEST_PROJECT%\Sources
set ACE_VERSION=13.0.6.0
set ACE_HOME=C:\Program Files\IBM\ACE\%ACE_VERSION%
set SERVER_NAME=TEST_SERVER_PGP
set SERVER_WORK_DIR=C:\temp\pgp\%SERVER_NAME%
set TEST_DIR=C:\temp\pgp
set ADMIN_PORT=7600
set HTTP_PORT=7800

echo ============================================================================
echo PGP SupportPac Deployment and Test Script
echo ============================================================================
echo.
echo Configuration:
echo   ACE Version: %ACE_VERSION%
echo   ACE Home: %ACE_HOME%
echo   Server Name: %SERVER_NAME%
echo   Server Work Dir: %SERVER_WORK_DIR%
echo   Admin Port: %ADMIN_PORT%
echo   HTTP Port: %HTTP_PORT%
echo   Sources: %SOURCES_DIR%
echo.

REM ============================================================================
REM Step 1: Setup Test Directories
REM ============================================================================
echo [Step 1/10] Setting up test directories...
if not exist "%TEST_DIR%\keys" mkdir "%TEST_DIR%\keys"
if not exist "%TEST_DIR%\input" mkdir "%TEST_DIR%\input"
if not exist "%TEST_DIR%\output" mkdir "%TEST_DIR%\output"
echo [OK] Test directories created

REM ============================================================================
REM Step 2: Copy PGP Keys to Test Directory
REM ============================================================================
echo.
echo [Step 2/10] Copying PGP keys to test directory...
xcopy /Y /Q "%SOURCES_DIR%\pgp-keys\*.*" "%TEST_DIR%\keys\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy PGP keys
    goto :error_exit
)
echo [OK] PGP keys copied successfully

REM ============================================================================
REM Step 4: Clean Up Old Server Directory
REM ============================================================================
echo.
echo [Step 4/10] Cleaning up old server directory...
if exist "%SERVER_WORK_DIR%" (
    rmdir /S /Q "%SERVER_WORK_DIR%"
    echo [OK] Old server directory removed
) else (
    echo [INFO] No old server directory found
)

mkdir "%SERVER_WORK_DIR%"
mkdir "%SERVER_WORK_DIR%\shared-classes"
echo [OK] Server directory structure created

REM ============================================================================
REM Step 5: Copy Bouncy Castle JARs to Server
REM ============================================================================
echo.
echo [Step 5/10] Copying Bouncy Castle JARs to server...
copy /Y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.78.1.jar" "%SERVER_WORK_DIR%\shared-classes\" >nul
copy /Y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.78.1.jar" "%SERVER_WORK_DIR%\shared-classes\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy Bouncy Castle JARs
    goto :error_exit
)
echo [OK] Bouncy Castle JARs copied


REM ============================================================================
REM Step 6: Deploy Policy Project and Application (MUST BE DONE BEFORE STARTING SERVER)
REM ============================================================================
echo.
echo [Step 6/10] Deploying PGP_Policies and TestPGP_App...

ibmint deploy --input-path "%SOURCES_DIR%" --output-work-directory "%SERVER_WORK_DIR%" --project PGP_Policies
ibmint deploy --input-path "%SOURCES_DIR%" --output-work-directory "%SERVER_WORK_DIR%" --project TestPGP_App
if errorlevel 1 (
    echo [ERROR] Deployment failed
    goto :error_exit
)
echo [OK] Deployment completed


REM ============================================================================
REM Step 7: Start Integration Server
REM ============================================================================
echo.
echo [Step 7/10] Starting integration server...
echo [INFO] Server will start in a new window titled "TEST_SERVER_PGP"
start "TEST_SERVER_PGP" IntegrationServer --work-dir "%SERVER_WORK_DIR%"

REM Wait for server to initialize
echo [INFO] Waiting for server to initialize (20 seconds)...
ping 127.0.0.1 -n 21 >nul

REM Check if server started
:wait_for_server
if not exist "%SERVER_WORK_DIR%\log\integration_server.%SERVER_NAME%.events.txt" (
    echo [INFO] Waiting for log file to be created...
    ping 127.0.0.1 -n 6 >nul
    goto :wait_for_server
)

findstr /C:"BIP1991I" "%SERVER_WORK_DIR%\log\integration_server.%SERVER_NAME%.events.txt" >nul 2>&1
if errorlevel 1 (
    echo [INFO] Server still initializing, waiting...
    ping 127.0.0.1 -n 6 >nul
    goto :wait_for_server
)
echo [OK] Integration server initialized

REM ============================================================================
REM Step 8: Verify HTTP Listener is Active
REM ============================================================================
echo.
echo [Step 8/10] Verifying HTTP listener on port %HTTP_PORT%...
netstat -ano | findstr ":%HTTP_PORT%" | findstr "LISTENING" >nul
if errorlevel 1 (
    echo [WARNING] HTTP listener not found on port %HTTP_PORT%
    echo [INFO] Checking server log for errors...
    findstr /C:"BIP" "%SERVER_WORK_DIR%\log\integration_server.%SERVER_NAME%.events.txt" | findstr /C:"ERROR"
    echo.
    echo [INFO] You may need to check the TEST_SERVER_PGP console window for details
    echo [ACTION] Press any key to continue with testing anyway...
    pause >nul
) else (
    echo [OK] HTTP listener is active on port %HTTP_PORT%
)

REM ============================================================================
REM Step 9: Create Test Input File
REM ============================================================================
echo.
echo [Step 9/10] Creating test input file...
echo This is a test file for PGP encryption > "%TEST_DIR%\input\plain.txt"
echo [OK] Test file created: %TEST_DIR%\input\plain.txt

REM ============================================================================
REM Step 10: Test Encryption and Decryption
REM ============================================================================
echo.
echo [Step 10/10] Testing PGP encryption and decryption...
echo.
echo [TEST 1] Testing encryption flow...
curl -X POST http://localhost:%HTTP_PORT%/pgp/encrypt -o "%TEST_DIR%\output\encrypted.txt"
if errorlevel 1 (
    echo [ERROR] Encryption test failed
    echo [INFO] Check if the server is running and the application is deployed
    echo [INFO] Check the TEST_SERVER_PGP console window for errors
    goto :error_exit
)
echo [OK] Encryption test completed

echo.
echo [TEST 2] Testing decryption flow...
curl -X POST http://localhost:%HTTP_PORT%/pgp/decrypt -o "%TEST_DIR%\input\plain-decrypted.txt"
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
echo Encrypted file (first 100 bytes):
powershell -Command "Get-Content '%TEST_DIR%\output\encrypted.txt' "
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
echo Deployment and Testing Complete!
echo ============================================================================
echo.
echo Server Information:
echo   Server Name: %SERVER_NAME%
echo   Work Directory: %SERVER_WORK_DIR%
echo   Admin REST API: http://localhost:%ADMIN_PORT%
echo   HTTP Listener: http://localhost:%HTTP_PORT%
echo   Console Window: TEST_SERVER_PGP
echo.
echo Test Files:
echo   Input: %TEST_DIR%\input\plain.txt
echo   Encrypted: %TEST_DIR%\output\encrypted.txt
echo   Decrypted: %TEST_DIR%\input\plain-decrypted.txt
echo.
echo To stop the TEST_SERVER_PGP server:
echo   Close the "TEST_SERVER_PGP" console window
echo   OR run: taskkill /F /FI "WINDOWTITLE eq TEST_SERVER_PGP*"
echo.
goto :normal_exit

:error_exit
echo.
echo ============================================================================
echo [ERROR] Script failed!
echo ============================================================================
echo.
echo Check the server log for details:
echo   %SERVER_WORK_DIR%\log\integration_server.%SERVER_NAME%.events.txt
echo.
echo Check the TEST_SERVER_PGP console window for errors
echo.
endlocal
exit /b 1

:normal_exit
endlocal
exit /b 0