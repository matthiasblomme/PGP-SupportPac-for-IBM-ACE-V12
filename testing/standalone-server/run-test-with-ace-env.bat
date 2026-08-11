@echo off
REM ============================================================================
REM Run Standalone Server Test with ACE Environment
REM ============================================================================

REM ACE version can be overridden: set ACE_VERSION=13.0.7.0 before calling
if not defined ACE_VERSION set ACE_VERSION=13.0.8.1

echo Sourcing ACE environment (%ACE_VERSION%)...
call "C:\Program Files\IBM\ACE\%ACE_VERSION%\server\bin\mqsiprofile.cmd"

if errorlevel 1 (
    echo [ERROR] Failed to source ACE environment
    exit /b 1
)

echo.
echo ACE environment loaded successfully
echo.
echo Running deploy_and_test.bat...
echo.

call "%~dp0deploy_and_test.bat"

exit /b %ERRORLEVEL%