@echo off
REM ============================================================================
REM Path Verification Script - Tests that all paths are correct
REM ============================================================================

setlocal enabledelayedexpansion

echo ============================================================================
echo Path Verification for Standalone Server Testing
echo ============================================================================
echo.

REM Configuration (same as deploy_and_test.bat)
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..\..
set TEST_RESOURCES=%PROJECT_ROOT%\testing\test-resources
set SOURCES_DIR=%TEST_RESOURCES%\Sources

echo Configuration:
echo   Script Dir: %SCRIPT_DIR%
echo   Project Root: %PROJECT_ROOT%
echo   Test Resources: %TEST_RESOURCES%
echo   Sources Dir: %SOURCES_DIR%
echo.

REM Test 1: Check test-resources directory
echo [Test 1] Checking test-resources directory...
if exist "%TEST_RESOURCES%" (
    echo [OK] test-resources directory exists
) else (
    echo [ERROR] test-resources directory NOT found: %TEST_RESOURCES%
    goto :error_exit
)

REM Test 2: Check Sources directory
echo.
echo [Test 2] Checking Sources directory...
if exist "%SOURCES_DIR%" (
    echo [OK] Sources directory exists
) else (
    echo [ERROR] Sources directory NOT found: %SOURCES_DIR%
    goto :error_exit
)

REM Test 3: Check PGP keys
echo.
echo [Test 3] Checking PGP keys directory...
if exist "%SOURCES_DIR%\pgp-keys" (
    echo [OK] pgp-keys directory exists
    dir /B "%SOURCES_DIR%\pgp-keys\*.pgp" >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] No .pgp files found in pgp-keys directory
        goto :error_exit
    ) else (
        echo [OK] PGP repository files found
    )
) else (
    echo [ERROR] pgp-keys directory NOT found
    goto :error_exit
)

REM Test 4: Check PGP_Policies
echo.
echo [Test 4] Checking PGP_Policies directory...
if exist "%SOURCES_DIR%\PGP_Policies" (
    echo [OK] PGP_Policies directory exists
    if exist "%SOURCES_DIR%\PGP_Policies\PGP-SDR-CFG-SERVICE.policyxml" (
        echo [OK] Sender policy found
    ) else (
        echo [ERROR] Sender policy NOT found
        goto :error_exit
    )
    if exist "%SOURCES_DIR%\PGP_Policies\PGP-RCV-CFG-SERVICE.policyxml" (
        echo [OK] Receiver policy found
    ) else (
        echo [ERROR] Receiver policy NOT found
        goto :error_exit
    )
) else (
    echo [ERROR] PGP_Policies directory NOT found
    goto :error_exit
)

REM Test 5: Check TestPGP_App
echo.
echo [Test 5] Checking TestPGP_App directory...
if exist "%SOURCES_DIR%\TestPGP_App" (
    echo [OK] TestPGP_App directory exists
    if exist "%SOURCES_DIR%\TestPGP_App\pgp\encrypt.msgflow" (
        echo [OK] Encryption flow found
    ) else (
        echo [ERROR] Encryption flow NOT found
        goto :error_exit
    )
    if exist "%SOURCES_DIR%\TestPGP_App\pgp\decrypt.msgflow" (
        echo [OK] Decryption flow found
    ) else (
        echo [ERROR] Decryption flow NOT found
        goto :error_exit
    )
) else (
    echo [ERROR] TestPGP_App directory NOT found
    goto :error_exit
)

REM Test 6: Check Bouncy Castle JARs
echo.
echo [Test 6] Checking Bouncy Castle JARs...
if exist "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.78.1.jar" (
    echo [OK] bcpg JAR found
) else (
    echo [WARNING] bcpg JAR NOT found (may need to update path for newer version)
)
if exist "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.78.1.jar" (
    echo [OK] bcprov JAR found
) else (
    echo [WARNING] bcprov JAR NOT found (may need to update path for newer version)
)

echo.
echo ============================================================================
echo [SUCCESS] All path verifications passed!
echo ============================================================================
echo.
echo The standalone server testing structure is correctly configured.
echo You can now run: deploy_and_test.bat
echo.
goto :normal_exit

:error_exit
echo.
echo ============================================================================
echo [ERROR] Path verification failed!
echo ============================================================================
echo.
echo Please check the error messages above and verify:
echo 1. You are in the correct directory
echo 2. The restructure was completed successfully
echo 3. All files were copied correctly
echo.
endlocal
exit /b 1

:normal_exit
endlocal
exit /b 0