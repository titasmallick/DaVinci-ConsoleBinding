@echo off
title DaVinci Resolve Gamepad Hub
color 0b
cd /d "C:\Users\Titas\Downloads\DaVinciGamepad"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Titas\Downloads\DaVinciGamepad\DaVinciGamepad.ps1"
echo.
echo Controller hub has stopped.
pause
