@echo off
setlocal
set "PROJECT_DIR=%~dp0.."
for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"
if "%GODOT_BIN%"=="" set "GODOT_BIN=godot.exe"

if exist "%GODOT_BIN%" goto godot_found
where "%GODOT_BIN%" >nul 2>nul
if errorlevel 1 (
  echo ERROR: Godot was not found. Install Godot 4.7.2, add it to PATH, or set GODOT_BIN.
  exit /b 127
)

:godot_found
if not exist "%PROJECT_DIR%\build\windows" mkdir "%PROJECT_DIR%\build\windows"
if not exist "%PROJECT_DIR%\build\linux" mkdir "%PROJECT_DIR%\build\linux"

for /f "delims=" %%V in ('"%GODOT_BIN%" --version') do set "GODOT_VERSION=%%V"
echo Using: %GODOT_VERSION%
echo %GODOT_VERSION% | findstr /b "4.7.2" >nul
if errorlevel 1 (
  echo ERROR: this release candidate targets Godot 4.7.2; found %GODOT_VERSION%.
  exit /b 2
)
"%GODOT_BIN%" --headless --editor --path "%PROJECT_DIR%" --quit
if errorlevel 1 goto failed
"%GODOT_BIN%" --headless --path "%PROJECT_DIR%" --export-release "Windows Desktop" "%PROJECT_DIR%\build\windows\GRAVITY_BREAKER.exe"
if errorlevel 1 goto failed
"%GODOT_BIN%" --headless --path "%PROJECT_DIR%" --export-release "Linux/X11" "%PROJECT_DIR%\build\linux\GRAVITY_BREAKER.x86_64"
if errorlevel 1 goto failed
if not exist "%PROJECT_DIR%\build\windows\GRAVITY_BREAKER.exe" goto failed
if not exist "%PROJECT_DIR%\build\linux\GRAVITY_BREAKER.x86_64" goto failed

echo Both exports were created. Launch and test each build outside the editor before distribution.
exit /b 0

:failed
echo ERROR: Godot import/export failed. Check the output above and confirm matching export templates are installed.
exit /b 1
