@echo off
title DaVinci Resolve Gamepad Hub
color 0b

rem %~dp0 is this .bat file's own folder, so the hub still works if the
rem folder is renamed, moved, or synced to a different PC/drive letter.
cd /d "%~dp0"

if not exist "DaVinciGamepad.ps1" (
    echo ERROR: DaVinciGamepad.ps1 was not found in:
    echo   %~dp0
    echo Make sure this .bat file sits in the same folder as the script.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0DaVinciGamepad.ps1"

echo.
echo Controller hub has stopped.
pause
