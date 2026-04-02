@echo off
REM ============================================================================
REM PGP SupportPac Installation Script for IBM App Connect Enterprise
REM ============================================================================
REM 
REM Description:
REM   Automates the installation of PGP SupportPac JAR files into IBM ACE
REM   Performs checks, creates backups, and validates installation
REM
REM Usage:
REM   install-pgp-supportpac.bat [ACE_INSTALL_PATH] [/skipbackup] [/force]
REM
REM Parameters:
REM   ACE_INSTALL_PATH - Optional: Path to ACE installation
REM   /skipbackup      - Skip creating backup of existing files
REM   /force           - Force installation without confirmation
REM
REM Examples:
REM   install-pgp-supportpac.bat
REM   install-pgp-supportpac.bat "C:\Program Files\IBM\ACE\13.0.6.0"
REM   install-pgp-supportpac.bat /force /skipbackup
REM
REM ============================================================================

setlocal enabledelayedexpansion

REM Script configuration
set SCRIPT_VERSION=1.0.0
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
set TIMESTAMP=%date:~-4%%date:~-7,2%%date:~-10,2%-%time:~0,2%%time:~3,2%%time:~6,2%
set TIMESTAMP=%TIMESTAMP: =0%
set LOG_FILE=%SCRIPT_DIR%install-%TIMESTAMP%.log

REM Parse command line arguments
set ACE_INSTALL_PATH=
set SKIP_BACKUP=0
set FORCE_INSTALL=0

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="/skipbackup" (set SKIP_BACKUP=1 & shift & goto parse_args)
if /i "%~1"=="-skipbackup" (set SKIP_BACKUP=1 & shift & goto parse_args)
if /i "%~1"=="/force" (set FORCE_INSTALL=1 & shift & goto parse_args)
if /i "%~1"=="-force" (set FORCE_INSTALL=1 & shift & goto parse_args)
set ACE_INSTALL_PATH=%~1
shift
goto parse_args
:args_done

REM Initialize log file
echo [%date% %time%] Installation started > "%LOG_FILE%"

REM Display header
echo.
echo ============================================================================
echo PGP SupportPac Installation Script v%SCRIPT_VERSION%
echo ============================================================================
echo.
call :log INFO "Installation started"

REM Check prerequisites
call :check_prerequisites
if errorlevel 1 goto error_exit

REM Detect or validate ACE installation
call :detect_ace_installation
if errorlevel 1 goto error_exit

REM Display installation plan
call :show_installation_plan
if errorlevel 1 goto error_exit

REM Confirm installation
if %FORCE_INSTALL%==0 (
    echo.
    set /p CONFIRM="Proceed with installation? (Y/N): "
    if /i not "!CONFIRM!"=="Y" (
        call :log WARNING "Installation cancelled by user"
        echo Installation cancelled.
        goto normal_exit
    )
)

REM Create backup
if %SKIP_BACKUP%==0 (
    call :backup_existing_files
    if errorlevel 1 goto error_exit
)

REM Copy files
call :copy_pgp_files
if errorlevel 1 goto error_exit

REM Verify installation
call :verify_installation
if errorlevel 1 goto error_exit

REM Display completion message
call :show_completion_message

call :log SUCCESS "Installation completed successfully"
goto normal_exit

REM ============================================================================
REM Functions
REM ============================================================================

:check_prerequisites
echo.
echo === Checking Prerequisites ===
echo.

REM Check if running with admin privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    call :log WARNING "Not running as Administrator"
    echo [WARNING] Not running as Administrator. Installation may fail if ACE directories require elevated privileges.
) else (
    call :log INFO "Running with Administrator privileges"
    echo [OK] Running with Administrator privileges
)

REM Check if project files exist
set MISSING_FILES=0
for %%F in (
    "MQSI_BASE_FILEPATH\server\jplugin\PGPSupportPacImpl.jar"
    "MQSI_BASE_FILEPATH\tools\plugins\PGPSupportPac.jar"
    "MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar"
    "MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar"
    "MQSI_REGISTRY\shared-classes\bcutil-jdk18on-1.81.jar"
) do (
    if not exist "%PROJECT_ROOT%\%%~F" (
        echo [ERROR] Required file not found: %%~F
        call :log ERROR "Required file not found: %%~F"
        set MISSING_FILES=1
    )
)

if %MISSING_FILES%==1 (
    echo.
    echo [ERROR] Some required files are missing. Cannot proceed with installation.
    exit /b 1
)

echo [OK] All required JAR files found in project directory
call :log INFO "All required JAR files found"
exit /b 0

:detect_ace_installation
echo.
echo === Detecting ACE Installation ===
echo.

REM If ACE_INSTALL_PATH provided, use it
if defined ACE_INSTALL_PATH (
    call :log INFO "Using provided ACE installation path: %ACE_INSTALL_PATH%"
    if not exist "%ACE_INSTALL_PATH%\ace.cmd" (
        echo [ERROR] ace.cmd not found at: %ACE_INSTALL_PATH%\ace.cmd
        call :log ERROR "ace.cmd not found at: %ACE_INSTALL_PATH%\ace.cmd"
        exit /b 1
    )
    set MQSI_BASE_FILEPATH=%ACE_INSTALL_PATH%
) else (
    REM Try to find ACE installation
    echo Searching for ACE installation...
    call :log INFO "Searching for ACE installation"
    
    REM Check common installation paths
    for %%P in (
        "C:\Program Files\IBM\ACE"
        "C:\Program Files (x86)\IBM\ACE"
    ) do (
        if exist %%P (
            for /f "delims=" %%V in ('dir /b /ad /o-n %%P 2^>nul') do (
                if exist "%%~P\%%V\ace.cmd" (
                    set MQSI_BASE_FILEPATH=%%~P\%%V
                    goto ace_found
                )
            )
        )
    )
    
    echo [ERROR] ACE installation not found. Please specify the installation path as first parameter.
    call :log ERROR "ACE installation not found"
    exit /b 1
)

:ace_found
REM Extract version from path
for %%F in ("%MQSI_BASE_FILEPATH%") do set ACE_VERSION=%%~nxF
echo [OK] Found ACE installation: %MQSI_BASE_FILEPATH%
echo [OK] ACE Version: %ACE_VERSION%
call :log INFO "ACE Version: %ACE_VERSION%"

REM Get MQSI_REGISTRY from environment or use default
if not defined MQSI_REGISTRY (
    set MQSI_REGISTRY=C:\ProgramData\IBM\MQSI
    echo [WARNING] MQSI_REGISTRY environment variable not set. Using default: !MQSI_REGISTRY!
    call :log WARNING "MQSI_REGISTRY not set, using default"
)
echo [OK] MQSI_REGISTRY: %MQSI_REGISTRY%

REM Set target directories
set SERVER_JPLUGIN=%MQSI_BASE_FILEPATH%\server\jplugin
set TOOLS_PLUGINS=%MQSI_BASE_FILEPATH%\tools\plugins
set SHARED_CLASSES=%MQSI_REGISTRY%\shared-classes

REM Verify target directories exist
if not exist "%SERVER_JPLUGIN%" (
    echo [ERROR] Target directory not found: %SERVER_JPLUGIN%
    call :log ERROR "Target directory not found: %SERVER_JPLUGIN%"
    exit /b 1
)
if not exist "%TOOLS_PLUGINS%" (
    echo [ERROR] Target directory not found: %TOOLS_PLUGINS%
    call :log ERROR "Target directory not found: %TOOLS_PLUGINS%"
    exit /b 1
)
if not exist "%SHARED_CLASSES%" (
    echo [WARNING] Shared-classes directory not found. Creating: %SHARED_CLASSES%
    call :log WARNING "Creating shared-classes directory"
    mkdir "%SHARED_CLASSES%" 2>nul
)

exit /b 0

:show_installation_plan
echo.
echo === Installation Plan ===
echo.
echo The following files will be installed:
echo.
echo   1. PGPSupportPacImpl.jar
echo      -^> %SERVER_JPLUGIN%
echo.
echo   2. PGPSupportPac.jar
echo      -^> %TOOLS_PLUGINS%
echo.
echo   3. bcpg-jdk18on-1.81.jar
echo      -^> %SHARED_CLASSES%
echo.
echo   4. bcprov-jdk18on-1.81.jar
echo      -^> %SHARED_CLASSES%
echo.
echo   5. bcutil-jdk18on-1.81.jar
echo      -^> %SHARED_CLASSES%
echo.

REM Check for existing files
set EXISTING_COUNT=0
for %%F in (
    "%SERVER_JPLUGIN%\PGPSupportPacImpl.jar"
    "%TOOLS_PLUGINS%\PGPSupportPac.jar"
    "%SHARED_CLASSES%\bcpg-jdk18on-1.81.jar"
    "%SHARED_CLASSES%\bcprov-jdk18on-1.81.jar"
    "%SHARED_CLASSES%\bcutil-jdk18on-1.81.jar"
) do (
    if exist %%F (
        if !EXISTING_COUNT!==0 (
            echo [WARNING] The following files already exist and will be overwritten:
        )
        echo   - %%F
        set /a EXISTING_COUNT+=1
    )
)

if %EXISTING_COUNT% gtr 0 echo.

exit /b 0

:backup_existing_files
echo.
echo === Creating Backup ===
echo.

set BACKUP_PATH=%SCRIPT_DIR%backup\%TIMESTAMP%
mkdir "%BACKUP_PATH%" 2>nul
echo Backup location: %BACKUP_PATH%
call :log INFO "Backup location: %BACKUP_PATH%"

set BACKED_UP=0

REM Backup server jplugin file
if exist "%SERVER_JPLUGIN%\PGPSupportPacImpl.jar" (
    mkdir "%BACKUP_PATH%\server\jplugin" 2>nul
    copy /y "%SERVER_JPLUGIN%\PGPSupportPacImpl.jar" "%BACKUP_PATH%\server\jplugin\" >nul
    echo [OK] Backed up: PGPSupportPacImpl.jar
    set /a BACKED_UP+=1
)

REM Backup tools plugins file
if exist "%TOOLS_PLUGINS%\PGPSupportPac.jar" (
    mkdir "%BACKUP_PATH%\tools\plugins" 2>nul
    copy /y "%TOOLS_PLUGINS%\PGPSupportPac.jar" "%BACKUP_PATH%\tools\plugins\" >nul
    echo [OK] Backed up: PGPSupportPac.jar
    set /a BACKED_UP+=1
)

REM Backup shared-classes files
if exist "%SHARED_CLASSES%\bcpg-jdk18on-1.81.jar" (
    mkdir "%BACKUP_PATH%\shared-classes" 2>nul
    copy /y "%SHARED_CLASSES%\bcpg-jdk18on-1.81.jar" "%BACKUP_PATH%\shared-classes\" >nul
    echo [OK] Backed up: bcpg-jdk18on-1.81.jar
    set /a BACKED_UP+=1
)

if exist "%SHARED_CLASSES%\bcprov-jdk18on-1.81.jar" (
    mkdir "%BACKUP_PATH%\shared-classes" 2>nul
    copy /y "%SHARED_CLASSES%\bcprov-jdk18on-1.81.jar" "%BACKUP_PATH%\shared-classes\" >nul
    echo [OK] Backed up: bcprov-jdk18on-1.81.jar
    set /a BACKED_UP+=1
)

if exist "%SHARED_CLASSES%\bcutil-jdk18on-1.81.jar" (
    mkdir "%BACKUP_PATH%\shared-classes" 2>nul
    copy /y "%SHARED_CLASSES%\bcutil-jdk18on-1.81.jar" "%BACKUP_PATH%\shared-classes\" >nul
    echo [OK] Backed up: bcutil-jdk18on-1.81.jar
    set /a BACKED_UP+=1
)

if %BACKED_UP%==0 (
    echo No existing files to backup
) else (
    echo [OK] Backed up %BACKED_UP% file(s)
    call :log INFO "Backed up %BACKED_UP% file(s)"
)

exit /b 0

:copy_pgp_files
echo.
echo === Installing PGP SupportPac Files ===
echo.

REM Copy PGPSupportPacImpl.jar
echo Installing PGPSupportPacImpl.jar...
copy /y "%PROJECT_ROOT%\MQSI_BASE_FILEPATH\server\jplugin\PGPSupportPacImpl.jar" "%SERVER_JPLUGIN%\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy PGPSupportPacImpl.jar
    call :log ERROR "Failed to copy PGPSupportPacImpl.jar"
    exit /b 1
)
echo [OK] Installed: PGPSupportPacImpl.jar
call :log INFO "Installed PGPSupportPacImpl.jar"

REM Copy PGPSupportPac.jar
echo Installing PGPSupportPac.jar...
copy /y "%PROJECT_ROOT%\MQSI_BASE_FILEPATH\tools\plugins\PGPSupportPac.jar" "%TOOLS_PLUGINS%\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy PGPSupportPac.jar
    call :log ERROR "Failed to copy PGPSupportPac.jar"
    exit /b 1
)
echo [OK] Installed: PGPSupportPac.jar
call :log INFO "Installed PGPSupportPac.jar"

REM Copy bcpg-jdk18on-1.81.jar
echo Installing bcpg-jdk18on-1.81.jar...
copy /y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcpg-jdk18on-1.81.jar" "%SHARED_CLASSES%\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy bcpg-jdk18on-1.81.jar
    call :log ERROR "Failed to copy bcpg-jdk18on-1.81.jar"
    exit /b 1
)
echo [OK] Installed: bcpg-jdk18on-1.81.jar
call :log INFO "Installed bcpg-jdk18on-1.81.jar"

REM Copy bcprov-jdk18on-1.81.jar
echo Installing bcprov-jdk18on-1.81.jar...
copy /y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcprov-jdk18on-1.81.jar" "%SHARED_CLASSES%\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy bcprov-jdk18on-1.81.jar
    call :log ERROR "Failed to copy bcprov-jdk18on-1.81.jar"
    exit /b 1
)
echo [OK] Installed: bcprov-jdk18on-1.81.jar
call :log INFO "Installed bcprov-jdk18on-1.81.jar"

REM Copy bcutil-jdk18on-1.81.jar
echo Installing bcutil-jdk18on-1.81.jar...
copy /y "%PROJECT_ROOT%\MQSI_REGISTRY\shared-classes\bcutil-jdk18on-1.81.jar" "%SHARED_CLASSES%\" >nul
if errorlevel 1 (
    echo [ERROR] Failed to copy bcutil-jdk18on-1.81.jar
    call :log ERROR "Failed to copy bcutil-jdk18on-1.81.jar"
    exit /b 1
)
echo [OK] Installed: bcutil-jdk18on-1.81.jar
call :log INFO "Installed bcutil-jdk18on-1.81.jar"

exit /b 0

:verify_installation
echo.
echo === Verifying Installation ===
echo.

set VERIFY_FAILED=0

REM Verify server jplugin file
if exist "%SERVER_JPLUGIN%\PGPSupportPacImpl.jar" (
    for %%S in ("%SERVER_JPLUGIN%\PGPSupportPacImpl.jar") do (
        if %%~zS gtr 0 (
            echo [OK] PGPSupportPacImpl.jar - OK
        ) else (
            echo [ERROR] PGPSupportPacImpl.jar - File is empty!
            set VERIFY_FAILED=1
        )
    )
) else (
    echo [ERROR] PGPSupportPacImpl.jar - Not found!
    set VERIFY_FAILED=1
)

REM Verify tools plugins file
if exist "%TOOLS_PLUGINS%\PGPSupportPac.jar" (
    for %%S in ("%TOOLS_PLUGINS%\PGPSupportPac.jar") do (
        if %%~zS gtr 0 (
            echo [OK] PGPSupportPac.jar - OK
        ) else (
            echo [ERROR] PGPSupportPac.jar - File is empty!
            set VERIFY_FAILED=1
        )
    )
) else (
    echo [ERROR] PGPSupportPac.jar - Not found!
    set VERIFY_FAILED=1
)

REM Verify bcpg library
if exist "%SHARED_CLASSES%\bcpg-jdk18on-1.81.jar" (
    for %%S in ("%SHARED_CLASSES%\bcpg-jdk18on-1.81.jar") do (
        if %%~zS gtr 0 (
            echo [OK] bcpg-jdk18on-1.81.jar - OK
        ) else (
            echo [ERROR] bcpg-jdk18on-1.81.jar - File is empty!
            set VERIFY_FAILED=1
        )
    )
) else (
    echo [ERROR] bcpg-jdk18on-1.81.jar - Not found!
    set VERIFY_FAILED=1
)

REM Verify bcprov library
if exist "%SHARED_CLASSES%\bcprov-jdk18on-1.81.jar" (
    for %%S in ("%SHARED_CLASSES%\bcprov-jdk18on-1.81.jar") do (
        if %%~zS gtr 0 (
            echo [OK] bcprov-jdk18on-1.81.jar - OK
        ) else (
            echo [ERROR] bcprov-jdk18on-1.81.jar - File is empty!
            set VERIFY_FAILED=1
        )
    )
) else (
    echo [ERROR] bcprov-jdk18on-1.81.jar - Not found!
    set VERIFY_FAILED=1
)

if exist "%SHARED_CLASSES%\bcutil-jdk18on-1.81.jar" (
    for %%S in ("%SHARED_CLASSES%\bcutil-jdk18on-1.81.jar") do (
        if %%~zS gtr 0 (
            echo [OK] bcutil-jdk18on-1.81.jar - OK
        ) else (
            echo [ERROR] bcutil-jdk18on-1.81.jar - File is empty!
            set VERIFY_FAILED=1
        )
    )
) else (
    echo [ERROR] bcutil-jdk18on-1.81.jar - Not found!
    set VERIFY_FAILED=1
)

if %VERIFY_FAILED%==1 (
    echo.
    echo [ERROR] Installation verification failed. Some files are missing or invalid.
    call :log ERROR "Installation verification failed"
    exit /b 1
)

echo [OK] All files verified successfully
call :log INFO "All files verified successfully"
exit /b 0

:show_completion_message
echo.
echo ============================================================================
echo Installation Complete
echo ============================================================================
echo.
echo [OK] PGP SupportPac has been successfully installed!
echo.
echo Installation Details:
echo   ACE Version: %ACE_VERSION%
echo   Installation Path: %MQSI_BASE_FILEPATH%
echo   Log File: %LOG_FILE%
echo.
echo [WARNING] IMPORTANT: Next Steps
echo   1. Restart any running ACE Integration Servers
echo   2. Restart ACE Toolkit if it's currently open
echo   3. Test the PGP nodes in your message flows
echo.
echo ACE 13.0.6.0 has been tested and validated.
echo.
echo To use the pgpKeytool command line utility:
echo   1. Open ACE Command Console
echo   2. Set CLASSPATH to include the installed JAR files
echo   3. See INSTALLATION.md for detailed instructions
echo.
exit /b 0

:log
REM Log function: :log LEVEL MESSAGE
set LOG_LEVEL=%~1
set LOG_MESSAGE=%~2
echo [%date% %time%] [%LOG_LEVEL%] %LOG_MESSAGE% >> "%LOG_FILE%"
exit /b 0

:error_exit
echo.
echo [ERROR] Installation failed. Check log file: %LOG_FILE%
call :log ERROR "Installation failed"
endlocal
exit /b 1

:normal_exit
endlocal
exit /b 0