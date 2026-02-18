@echo off
setlocal enabledelayedexpansion

echo ============================================================================
echo PGP SupportPac Docker Test - Local Execution
echo ============================================================================
echo.

REM Check if Docker is running
docker ps >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop.
    exit /b 1
)
echo [OK] Docker is running

REM Check if IBM Container Registry login is needed
echo.
echo [INFO] Checking IBM Container Registry access...
docker pull cp.icr.io/cp/appc/ace:13.0.6.0-r1 >nul 2>&1
if errorlevel 1 (
    echo [WARN] Cannot pull ACE image. You may need to login:
    echo   docker login icr.io -u cp -p YOUR_IBM_ENTITLEMENT_KEY
    echo.
    set /p continue="Continue anyway? (y/n): "
    if /i not "!continue!"=="y" exit /b 1
)

REM Start docker-compose
echo.
echo [INFO] Starting Docker container...
echo [INFO] This will take a few minutes on first run...
echo.
docker-compose up --abort-on-container-exit

REM Check exit code
if errorlevel 1 (
    echo.
    echo ============================================================================
    echo [ERROR] Tests failed!
    echo ============================================================================
    echo.
    echo [INFO] Container is still running for inspection.
    echo [INFO] To inspect: docker exec -it ace-pgp-test bash
    echo [INFO] To view logs: docker logs ace-pgp-test
    echo [INFO] To stop: docker stop ace-pgp-test
    echo.
    set /p cleanup="Remove container? (y/n): "
    if /i "!cleanup!"=="y" (
        docker-compose down -v
        echo [OK] Container removed
    )
    exit /b 1
) else (
    echo.
    echo ============================================================================
    echo [SUCCESS] All tests passed!
    echo ============================================================================
    echo.
    set /p cleanup="Remove container? (y/n): "
    if /i "!cleanup!"=="y" (
        docker-compose down -v
        echo [OK] Container removed
    ) else (
        echo [INFO] Container kept for inspection
        echo [INFO] To remove: docker-compose down -v
    )
)

endlocal