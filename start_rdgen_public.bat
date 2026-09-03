@echo off
REM ============================================================
REM  RDGen public mode: waitress + Cloudflare quick tunnel
REM
REM  Exposes http://localhost:8000 as https://xxx.trycloudflare.com
REM  so GitHub Actions can reach it and pull secrets.zip.
REM
REM  After it starts, copy the https URL into:
REM    1) secrets.local.bat -> GENURL=https://xxx.trycloudflare.com
REM                            PROTOCOL=https
REM    2) GitHub -> weststreetboy/rdgen -> Settings -> Secrets -> GENURL
REM ============================================================

setlocal

REM ---- 1. Locate cloudflared in several common places ----
set "CF="
if exist "%~dp0cloudflared.exe" set "CF=%~dp0cloudflared.exe"
if not defined CF if exist "%USERPROFILE%\cloudflared.exe" set "CF=%USERPROFILE%\cloudflared.exe"
if not defined CF if exist "%SystemRoot%\System32\cloudflared.exe" set "CF=%SystemRoot%\System32\cloudflared.exe"
if not defined CF (
  where cloudflared >nul 2>nul
  if not errorlevel 1 set "CF=cloudflared"
)

if not defined CF (
  echo [X] cloudflared.exe not found.
  echo.
  echo Download it first.
  echo.
  echo   In PowerShell:
  echo     Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "$env:USERPROFILE\cloudflared.exe"
  echo.
  echo   Or in cmd:
  echo     curl -L -o "%%USERPROFILE%%\cloudflared.exe" https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe
  echo.
  echo   It goes to your user folder - no admin rights needed.
  echo   NOTE: PowerShell's built-in "curl" is an alias for Invoke-WebRequest
  echo         and does NOT support -L / -o. Use "curl.exe" or the commands above.
  echo.
  pause
  exit /b 1
)

echo Found cloudflared: %CF%
echo.

REM ---- 2. Start waitress only if port 8000 is free ----
netstat -ano | findstr ":8000 " | findstr /i "LISTENING" >nul 2>nul
set PORT_BUSY=%errorlevel%

if "%PORT_BUSY%"=="0" (
  echo [1/2] Port 8000 already in use - reusing the running waitress.
) else (
  echo [1/2] Starting waitress on port 8000...
  start "RDGen-waitress" cmd /k "%~dp0start_rdgen.bat"
  timeout /t 6 /nobreak >nul
)

echo [2/2] Starting Cloudflare quick tunnel...
start "RDGen-cloudflared" cmd /k ""%CF%" tunnel --url http://localhost:8000 --no-autoupdate"

echo.
echo ============================================================
echo  In the cloudflared window, wait for:
echo      "Your quick Tunnel has been created!"
echo  then copy the https://*.trycloudflare.com URL below it.
echo.
echo  Put that URL in two places:
echo    A^) secrets.local.bat
echo         set GENURL=https://xxx.trycloudflare.com
echo         set PROTOCOL=https
echo    B^) GitHub -^> weststreetboy/rdgen -^> Settings
echo       -^> Secrets and variables -^> Actions -^> GENURL = same URL
echo.
echo  Then restart RDGen (start_rdgen.bat) so GENURL takes effect.
echo  NOTE: quick tunnel URLs change on every restart. For a fixed
echo        URL use a named tunnel - see docs\DEPLOY_PUBLIC.md
echo ============================================================
pause
endlocal
