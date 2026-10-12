<#
.SYNOPSIS
    Hermes Agent - Portable All-In-One Installer & Launcher
    Zero-admin rights, 100% self-contained in selected directory.
#>

param(
    [string]$TargetDir = ""
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Msg)
    Write-Host ""
    Write-Host "[+] $Msg" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Msg)
    Write-Host "[OK] $Msg" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Msg)
    Write-Host "[!] $Msg" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Msg)
    Write-Host "[ERROR] $Msg" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    exit 1
}

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Magenta
Write-Host "       HERMES AGENT - PORTABLE INSTALLER (NO ADMIN REQUIRED)       " -ForegroundColor Magenta
Write-Host "===================================================================" -ForegroundColor Magenta
Write-Host "All data, portable Python, Git, packages, and config stay strictly"
Write-Host "inside your chosen directory. No system-wide pollution."
Write-Host "===================================================================" -ForegroundColor Magenta
Write-Host ""

# 1. Select Target Directory
if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderDialog.Description = "Select target folder to install Hermes Agent Portable"
        $folderDialog.ShowNewFolderButton = $true
        $folderDialog.SelectedPath = $env:USERPROFILE
        Write-Host "Opening folder selection dialog..." -ForegroundColor Gray
        $result = $folderDialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK -and -not [string]::IsNullOrWhiteSpace($folderDialog.SelectedPath)) {
            $TargetDir = $folderDialog.SelectedPath
        }
    } catch {
        Write-Warn "GUI folder picker unavailable. Falling back to console input."
    }
}

if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    $defaultPath = Join-Path $env:USERPROFILE "HermesAgentPortable"
    Write-Host "Enter target directory for installation:" -ForegroundColor Yellow
    Write-Host "Default: $defaultPath" -ForegroundColor DarkGray
    $inputPath = Read-Host "Install path (press Enter for default)"
    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        $TargetDir = $defaultPath
    } else {
        $TargetDir = $inputPath.Trim('"')
    }
}

$TargetDir = [System.IO.Path]::GetFullPath($TargetDir)
Write-Step "Target directory selected: $TargetDir"

if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Success "Created target folder"
}

# 2. Setup internal directory structure inside TargetDir
$HermesHome = Join-Path $TargetDir "hermes_data"
$HermesAgentDir = Join-Path $TargetDir "hermes-agent"
$ToolsDir = Join-Path $TargetDir "tools"
$UvBinDir = Join-Path $ToolsDir "uv"
$GitBinDir = Join-Path $ToolsDir "git"
$CacheDir = Join-Path $TargetDir "cache"
$PythonDir = Join-Path $ToolsDir "python"

New-Item -ItemType Directory -Path $HermesHome -Force | Out-Null
New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
New-Item -ItemType Directory -Path $UvBinDir -Force | Out-Null
New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
New-Item -ItemType Directory -Path $PythonDir -Force | Out-Null

# Set Environment Variables strictly isolated to process
$env:HERMES_HOME = $HermesHome
$env:HERMES_RUNTIME_DIR = $ToolsDir
$env:UV_CACHE_DIR = Join-Path $CacheDir "uv"
$env:UV_PYTHON_INSTALL_DIR = $PythonDir
$env:TEMP = Join-Path $CacheDir "temp"
$env:TMP = Join-Path $CacheDir "temp"
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null

# 3. Detect Architecture
$arch = if ([System.Environment]::Is64BitOperatingSystem) {
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
} else {
    Write-Fail "Hermes Agent requires a 64-bit Windows OS."
}

# 4. Fetch Portable uv (Standalone Python & Package Manager)
$uvExe = Join-Path $UvBinDir "uv.exe"
if (-not (Test-Path $uvExe)) {
    Write-Step "Downloading portable uv package & runtime manager..."
    $uvZipUrl = "https://github.com/astral-sh/uv/releases/latest/download/uv-$arch-pc-windows-msvc.zip"
    $uvZipPath = Join-Path $CacheDir "uv.zip"
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        Invoke-WebRequest -Uri $uvZipUrl -OutFile $uvZipPath -UseBasicParsing
        Expand-Archive -Path $uvZipPath -DestinationPath $CacheDir -Force
        $foundUv = Get-ChildItem -Path $CacheDir -Filter "uv.exe" -Recurse | Select-Object -First 1
        if (-not $foundUv) { Write-Fail "Failed to extract uv.exe" }
        Copy-Item -Path $foundUv.FullName -Destination $uvExe -Force
        $foundUvx = Get-ChildItem -Path $CacheDir -Filter "uvx.exe" -Recurse | Select-Object -First 1
        if ($foundUvx) { Copy-Item -Path $foundUvx.FullName -Destination (Join-Path $UvBinDir "uvx.exe") -Force }
        Remove-Item -Path $uvZipPath -Force -ErrorAction SilentlyContinue
        Write-Success "uv installed in portable tools folder."
    } catch {
        Write-Fail "Error downloading uv: $_"
    }
} else {
    Write-Success "Portable uv already exists."
}

# Add uv to current process PATH
$env:Path = "$UvBinDir;$env:Path"

# 5. Fetch Portable Git if system git is not present
$gitExe = Join-Path $GitBinDir "cmd\git.exe"
$hasSystemGit = $false
try {
    $sysGitCheck = & git --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasSystemGit = $true
        Write-Success "System git found: $sysGitCheck"
    }
} catch {
    $hasSystemGit = $false
}

if (-not $hasSystemGit -and -not (Test-Path $gitExe)) {
    Write-Step "Downloading MinGit / Portable Git (isolated)..."
    $gitZipPath = Join-Path $CacheDir "mingit.zip"
    try {
        Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/MinGit-2.48.1-64-bit.zip" -OutFile $gitZipPath -UseBasicParsing
        Expand-Archive -Path $gitZipPath -DestinationPath $GitBinDir -Force
        Remove-Item -Path $gitZipPath -Force -ErrorAction SilentlyContinue
        Write-Success "Portable MinGit installed."
    } catch {
        Write-Warn "Could not download MinGit automatically. Continuing..."
    }
}

if (Test-Path $gitExe) {
    $env:Path = "$GitBinDir\cmd;$GitBinDir\usr\bin;$env:Path"
}

# 6. Fetch Latest Hermes Agent Source/Release
Write-Step "Fetching latest Hermes Agent repository..."
$repoUrl = "https://github.com/NousResearch/hermes-agent.git"

if (-not (Test-Path (Join-Path $HermesAgentDir ".git"))) {
    try {
        & git clone --depth 1 $repoUrl $HermesAgentDir
        if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
        Write-Success "Hermes Agent cloned successfully."
    } catch {
        Write-Warn "Git clone failed. Downloading zip archive from GitHub..."
        $zipUrl = "https://github.com/NousResearch/hermes-agent/archive/refs/heads/main.zip"
        $zipDest = Join-Path $CacheDir "hermes-agent.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipDest -UseBasicParsing
        $tempExtract = Join-Path $CacheDir "hermes_extract"
        New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
        Expand-Archive -Path $zipDest -DestinationPath $tempExtract -Force
        $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        Move-Item -Path $extractedFolder.FullName -Destination $HermesAgentDir -Force
        Remove-Item -Path $zipDest, $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Hermes Agent downloaded & extracted."
    }
} else {
    Write-Step "Existing Hermes Agent repo found, updating to latest..."
    try {
        Push-Location $HermesAgentDir
        & git pull origin main
        Pop-Location
        Write-Success "Updated to latest."
    } catch {
        Write-Warn "Could not pull updates. Continuing with existing files."
        Pop-Location
    }
}

# 7. Provision Isolated Python using uv
Write-Step "Installing isolated Portable Python (3.14)..."
Push-Location $HermesAgentDir
try {
    & $uvExe python install 3.14
    Write-Success "Portable Python installed in $PythonDir"

    Write-Step "Creating isolated virtual environment and installing Hermes Agent..."
    $venvDir = Join-Path $TargetDir ".venv"
    & $uvExe venv $venvDir --python 3.14
    $pythonVenvExe = Join-Path $venvDir "Scripts\python.exe"

    Write-Step "Syncing Hermes Agent dependencies into local portable venv..."
    & $uvExe pip install -e . --python $pythonVenvExe
    Write-Success "Dependencies installed successfully!"
} catch {
    Write-Fail "Error setting up Python environment: $_"
} finally {
    Pop-Location
}

# 8. Setup Config & Data Folders in hermes_data
Write-Step "Setting up local configuration in hermes_data..."
foreach ($d in @("cron","sessions","logs","pairing","hooks","image_cache","audio_cache","memories","skills","bin")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $HermesHome $d) | Out-Null
}

$envFile = Join-Path $HermesHome ".env"
if (-not (Test-Path $envFile)) {
    $exampleEnv = Join-Path $HermesAgentDir ".env.example"
    if (Test-Path $exampleEnv) {
        Copy-Item $exampleEnv $envFile
    } else {
        Set-Content -Path $envFile -Value "# Hermes Agent Environment Variables`r`n"
    }
    Write-Success "Created $envFile"
}

$cfgFile = Join-Path $HermesHome "config.yaml"
if (-not (Test-Path $cfgFile)) {
    $exampleCfg = Join-Path $HermesAgentDir "cli-config.yaml.example"
    if (Test-Path $exampleCfg) {
        Copy-Item $exampleCfg $cfgFile
        Write-Success "Created $cfgFile"
    }
}


# 8.5 Optional: Download Full Portable GUI (Hermes Desktop)
Write-Step "GUI Desktop App Option..."
$installGui = $false
try {
    Add-Type -AssemblyName System.Windows.Forms
    $guiChoice = [System.Windows.Forms.MessageBox]::Show(
        "Do you want to install the full Hermes Desktop GUI (Hermes One)?",
        "Hermes Agent Portable - Desktop GUI Option",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($guiChoice -eq [System.Windows.Forms.DialogResult]::Yes) {
        $installGui = $true
    }
} catch {
    $cliGuiChoice = Read-Host "Install full Hermes Desktop GUI (Hermes One)? (Y/N)"
    if ($cliGuiChoice -match "^[yY]") {
        $installGui = $true
    }
}

$guiExe = Join-Path $TargetDir "HermesDesktop.exe"
if ($installGui) {
    Write-Step "Fetching latest portable Hermes Desktop GUI release..."
    $guiApiUrl = "https://api.github.com/repos/fathah/hermes-desktop/releases/latest"
    $guiDownloaded = $false
    try {
        $releaseInfo = Invoke-RestMethod -Uri $guiApiUrl -Headers @{ "User-Agent" = "Hermes-Installer" }
        $portableAsset = $releaseInfo.assets | Where-Object { $_.name -like "*portable.exe" } | Select-Object -First 1
        if ($portableAsset -and $portableAsset.browser_download_url) {
            Write-Host "Downloading $($portableAsset.name) ($([math]::Round($portableAsset.size/1MB, 1)) MB)..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $portableAsset.browser_download_url -OutFile $guiExe -UseBasicParsing
            $guiDownloaded = $true
            Write-Success "Full Portable Desktop GUI installed at: $guiExe"
        }
    } catch {
        Write-Warn "GitHub API lookup failed: $_. Trying fallback direct URL..."
    }

    if (-not $guiDownloaded) {
        try {
            $fallbackUrl = "https://github.com/fathah/hermes-desktop/releases/download/v0.7.7/hermes-desktop-0.7.7-portable.exe"
            Write-Host "Downloading fallback release ($fallbackUrl)..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $fallbackUrl -OutFile $guiExe -UseBasicParsing
            Write-Success "Full Portable Desktop GUI installed at: $guiExe"
            $guiDownloaded = $true
        } catch {
            Write-Warn "Could not download portable GUI automatically: $_"
        }
    }

    if ($guiDownloaded) {
        # Create Hermes-GUI.bat
        $guiBat = Join-Path $TargetDir "Hermes-GUI.bat"
        $guiBatContent = @"
@echo off
setlocal
cd /d "%~dp0"

set "HERMES_HOME=%~dp0hermes_data"
set "HERMES_RUNTIME_DIR=%~dp0tools"
set "UV_CACHE_DIR=%~dp0cache\uv"
set "UV_PYTHON_INSTALL_DIR=%~dp0tools\python"
set "TEMP=%~dp0cache\temp"
set "TMP=%~dp0cache\temp"
set "PATH=%~dp0tools\uv;%~dp0tools\git\cmd;%~dp0.venv\Scripts;%PATH%"

start "" "%~dp0HermesDesktop.exe"
endlocal
"@
        Set-Content -Path $guiBat -Value $guiBatContent -Encoding ASCII
        Write-Success "Generated GUI launcher: $guiBat"
    }
}

# 9. Create Portable Launcher Scripts (.bat and .ps1)
Write-Step "Generating standalone portable launchers..."

# Batch launcher (Hermes.bat)
$batchLauncher = Join-Path $TargetDir "Hermes.bat"
$batchContent = @"
@echo off
setlocal
cd /d "%~dp0"

:: Set 100% portable environment variables
set "HERMES_HOME=%~dp0hermes_data"
set "HERMES_RUNTIME_DIR=%~dp0tools"
set "UV_CACHE_DIR=%~dp0cache\uv"
set "UV_PYTHON_INSTALL_DIR=%~dp0tools\python"
set "TEMP=%~dp0cache\temp"
set "TMP=%~dp0cache\temp"
set "PATH=%~dp0tools\uv;%~dp0tools\git\cmd;%~dp0.venv\Scripts;%PATH%"

if not exist "%TEMP%" mkdir "%TEMP%"

if "%~1"=="" (
    echo Starting Hermes Agent...
    python -m hermes_cli
) else (
    python -m hermes_cli %*
)

if errorlevel 1 (
    echo.
    echo Hermes Agent exited with error code %errorlevel%.
    pause
)
endlocal
"@
Set-Content -Path $batchLauncher -Value $batchContent -Encoding ASCII
Write-Success "Generated launcher: $batchLauncher"

# Setup / Config Launcher (Setup.bat)
$setupLauncher = Join-Path $TargetDir "Setup.bat"
$setupContent = @"
@echo off
setlocal
cd /d "%~dp0"

set "HERMES_HOME=%~dp0hermes_data"
set "HERMES_RUNTIME_DIR=%~dp0tools"
set "UV_CACHE_DIR=%~dp0cache\uv"
set "UV_PYTHON_INSTALL_DIR=%~dp0tools\python"
set "TEMP=%~dp0cache\temp"
set "TMP=%~dp0cache\temp"
set "PATH=%~dp0tools\uv;%~dp0tools\git\cmd;%~dp0.venv\Scripts;%PATH%"

echo Running Hermes Agent Setup Wizard...
python -m hermes_cli setup --portal
pause
endlocal
"@
Set-Content -Path $setupLauncher -Value $setupContent -Encoding ASCII
Write-Success "Generated setup launcher: $setupLauncher"

# Update Launcher (Update.bat)
$updateLauncher = Join-Path $TargetDir "Update.bat"
$updateContent = @"
@echo off
setlocal
cd /d "%~dp0"

set "HERMES_HOME=%~dp0hermes_data"
set "HERMES_RUNTIME_DIR=%~dp0tools"
set "UV_CACHE_DIR=%~dp0cache\uv"
set "UV_PYTHON_INSTALL_DIR=%~dp0tools\python"
set "PATH=%~dp0tools\uv;%~dp0tools\git\cmd;%~dp0.venv\Scripts;%PATH%"

echo Updating Hermes Agent repository...
cd hermes-agent
git pull origin main
cd ..

echo Updating Python dependencies...
uv pip install -e ./hermes-agent --python "%~dp0.venv\Scripts\python.exe"

echo Update complete!
pause
endlocal
"@
Set-Content -Path $updateLauncher -Value $updateContent -Encoding ASCII
Write-Success "Generated updater: $updateLauncher"

# Portable PowerShell Launcher (Hermes.ps1)
$psLauncher = Join-Path $TargetDir "Hermes.ps1"
$psContent = @'
$rootDir = $PSScriptRoot
$env:HERMES_HOME = Join-Path $rootDir "hermes_data"
$env:HERMES_RUNTIME_DIR = Join-Path $rootDir "tools"
$env:UV_CACHE_DIR = Join-Path $rootDir "cache\uv"
$env:UV_PYTHON_INSTALL_DIR = Join-Path $rootDir "tools\python"
$env:TEMP = Join-Path $rootDir "cache\temp"
$env:TMP = Join-Path $rootDir "cache\temp"
$env:Path = "$rootDir\tools\uv;$rootDir\tools\git\cmd;$rootDir\.venv\Scripts;$env:Path"

if ($args.Count -eq 0) {
    & python -m hermes_cli
} else {
    & python -m hermes_cli @args
}
'@
Set-Content -Path $psLauncher -Value $psContent -Encoding UTF8
Write-Success "Generated PowerShell launcher: $psLauncher"


# 10. Optional: Add Start Menu Shortcuts (User-level, No Admin Required)
Write-Step "Shortcut Options..."
$createShortcut = $false
try {
    Add-Type -AssemblyName System.Windows.Forms
    $msgResult = [System.Windows.Forms.MessageBox]::Show(
        "Would you like to add Hermes Agent to your Start Menu?",
        "Hermes Agent Portable - Start Menu Shortcut",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($msgResult -eq [System.Windows.Forms.DialogResult]::Yes) {
        $createShortcut = $true
    }
} catch {
    $cliChoice = Read-Host "Add Hermes Agent to Start Menu? (Y/N)"
    if ($cliChoice -match "^[yY]") {
        $createShortcut = $true
    }
}

if ($createShortcut) {
    try {
        $programsDir = [Environment]::GetFolderPath('Programs')
        $startMenuFolder = Join-Path $programsDir "Hermes Agent Portable"
        if (-not (Test-Path $startMenuFolder)) {
            New-Item -ItemType Directory -Path $startMenuFolder -Force | Out-Null
        }
        
        $wshShell = New-Object -ComObject WScript.Shell
        
        # 1. Hermes Agent CLI shortcut
        
        if (Test-Path (Join-Path $TargetDir "HermesDesktop.exe")) {
            $shortcutGui = $wshShell.CreateShortcut((Join-Path $startMenuFolder "Hermes Desktop GUI.lnk"))
            $shortcutGui.TargetPath = (Join-Path $TargetDir "Hermes-GUI.bat")
            $shortcutGui.WorkingDirectory = $TargetDir
            $shortcutGui.Description = "Hermes Agent Full Desktop GUI"
            $shortcutGui.Save()
        }
        $shortcutCli = $wshShell.CreateShortcut((Join-Path $startMenuFolder "Hermes Agent.lnk"))
        $shortcutCli.TargetPath = $batchLauncher
        $shortcutCli.WorkingDirectory = $TargetDir
        $shortcutCli.Description = "Hermes Agent Portable CLI"
        $shortcutCli.Save()
        
        # 2. Setup Portal shortcut
        $shortcutSetup = $wshShell.CreateShortcut((Join-Path $startMenuFolder "Hermes Agent Setup.lnk"))
        $shortcutSetup.TargetPath = $setupLauncher
        $shortcutSetup.WorkingDirectory = $TargetDir
        $shortcutSetup.Description = "Hermes Agent Setup Wizard & Browser Portal"
        $shortcutSetup.Save()

        # 3. Safe Updater shortcut
        $shortcutUpdate = $wshShell.CreateShortcut((Join-Path $startMenuFolder "Hermes Agent Update.lnk"))
        $shortcutUpdate.TargetPath = $updateLauncher
        $shortcutUpdate.WorkingDirectory = $TargetDir
        $shortcutUpdate.Description = "Hermes Agent Safe Updater"
        $shortcutUpdate.Save()

        Write-Success "Start Menu shortcuts created in: $startMenuFolder"
    } catch {
        Write-Warn "Could not create Start Menu shortcuts: $_"
    }
}

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "                  INSTALLATION COMPLETE!                          " -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "Location: $TargetDir"
Write-Host ""
Write-Host "Portable Launchers Created:"
Write-Host "  1. Hermes.bat   -> Double-click to start Hermes Agent CLI"
Write-Host "  2. Setup.bat    -> Interactive setup / browser portal"
Write-Host "  3. Update.bat   -> Fetch latest Hermes Agent updates anytime"
Write-Host "  4. Hermes.ps1   -> PowerShell launcher"
Write-Host ""
Write-Host "Everything is self-contained in: $TargetDir"
Write-Host "Zero system registry changes, zero admin rights needed."
Write-Host "===================================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to finish..."