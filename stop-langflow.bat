@echo off
REM Stop Langflow. Flows and files are kept; start-langflow.bat brings it back.
setlocal
title Langflow

cd /d "%~dp0"

docker compose -f "docker\quickstart\docker-compose.yml" down
if errorlevel 1 (
  echo.
  echo   Could not stop Langflow. Is Docker Desktop running?
  echo.
  pause
  exit /b 1
)

echo.
echo   Langflow stopped. Your flows and files are kept.
echo.
pause
exit /b 0
