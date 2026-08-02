@echo off
REM Start Langflow in Docker and open it in the browser.
REM Double-click this file, or run it from PowerShell as .\start-langflow.bat
setlocal
title Langflow

cd /d "%~dp0"

set COMPOSE=docker\quickstart\docker-compose.yml

echo Checking Docker...
docker info >nul 2>&1
if errorlevel 1 (
  echo.
  echo   Docker Desktop is not running.
  echo   Start Docker Desktop, wait until it reports "Engine running", then run this again.
  echo.
  pause
  exit /b 1
)

echo Starting Langflow...
docker compose -f "%COMPOSE%" up -d
if errorlevel 1 (
  echo.
  echo   Langflow failed to start. The Docker output above explains why.
  echo.
  pause
  exit /b 1
)

echo.
echo Waiting for Langflow to be ready...
echo (The first run downloads the image and can take several minutes.)

set /a TRIES=0
:waitloop
set /a TRIES+=1
curl -sf -o nul http://localhost:7860/health && goto :ready
if %TRIES% geq 150 goto :timeout
timeout /t 4 /nobreak >nul
goto :waitloop

:timeout
echo.
echo   Langflow did not come up in time. To see what it is doing:
echo       docker compose -f %COMPOSE% logs -f
echo.
pause
exit /b 1

:ready
echo.
echo   Langflow is ready at http://localhost:7860
echo.
echo   It stays running in the background and restarts with Docker Desktop,
echo   so from now on you can just open that address.
echo   To stop it, run stop-langflow.bat
echo.
start "" http://localhost:7860
exit /b 0
