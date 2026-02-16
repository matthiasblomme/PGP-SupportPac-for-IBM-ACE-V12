@echo off
REM ============================================================================
REM Run Standalone Server Test with ACE Environment
REM ============================================================================

echo Sourcing ACE environment...
call "C:\Program Files\IBM\ACE\13.0.6.0\server\bin\mqsiprofile.cmd"

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