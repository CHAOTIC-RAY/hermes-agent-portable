@echo off
title Hermes Agent - Portable Installer
setlocal EnableDelayedExpansion

if exist "%~dp0Hermes-Agent-Installer.exe" (
    start "" "%~dp0Hermes-Agent-Installer.exe"
    exit /b 0
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer_gui.ps1"

if errorlevel 1 (
    echo.
    echo Falling back to command-line installer...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
)

endlocal
