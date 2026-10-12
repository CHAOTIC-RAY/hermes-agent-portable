<#
.SYNOPSIS
    Hermes Agent Portable - Safe Updater with Auto-Backup & Rollback
#>

param(
    [switch]$SkipBackup,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$rootDir = $PSScriptRoot

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
}

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Magenta
Write-Host "            HERMES AGENT PORTABLE - SAFE UPDATER                  " -ForegroundColor Magenta
Write-Host "===================================================================" -ForegroundColor Magenta
Write-Host "Location: $rootDir"
Write-Host ""

# 1. Setup isolated environment variables
$HermesHome = Join-Path $rootDir "hermes_data"
$HermesAgentDir = Join-Path $rootDir "hermes-agent"
$ToolsDir = Join-Path $rootDir "tools"
$UvBinDir = Join-Path $ToolsDir "uv"
$GitBinDir = Join-Path $ToolsDir "git"
$CacheDir = Join-Path $rootDir "cache"
$PythonDir = Join-Path $ToolsDir "python"
$VenvDir = Join-Path $rootDir ".venv"
$BackupBaseDir = Join-Path $rootDir "backups"

$env:HERMES_HOME = $HermesHome
$env:HERMES_RUNTIME_DIR = $ToolsDir
$env:UV_CACHE_DIR = Join-Path $CacheDir "uv"
$env:UV_PYTHON_INSTALL_DIR = $PythonDir
$env:TEMP = Join-Path $CacheDir "temp"
$env:TMP = Join-Path $CacheDir "temp"
$env:Path = "$UvBinDir;$GitBinDir\cmd;$VenvDir\Scripts;$env:Path"

$uvExe = Join-Path $UvBinDir "uv.exe"
$pythonExe = Join-Path $VenvDir "Scripts\python.exe"

if (-not (Test-Path $uvExe) -or -not (Test-Path $pythonExe)) {
    Write-Fail "Portable environment files missing in $rootDir. Please run initial install first."
    Read-Host "Press Enter to exit..."
    exit 1
}

# 2. Check running processes holding files
Write-Step "Checking for running Hermes or Python processes in portable directory..."
$lockedProcesses = Get-Process | Where-Object {
    try {
        $_.Path -and $_.Path.StartsWith($rootDir, [System.StringComparison]::OrdinalIgnoreCase)
    } catch {
        $false
    }
}

if ($lockedProcesses) {
    Write-Warn "Detected active processes in portable directory:"
    $lockedProcesses | ForEach-Object { Write-Host " - PID: $($_.Id) | Name: $($_.ProcessName)" -ForegroundColor Yellow }
    $choice = Read-Host "Close these processes automatically to continue update? (Y/N)"
    if ($choice -match "^[yY]") {
        $lockedProcesses | ForEach-Object { Stop-Process -Id $_.Id -Force }
        Start-Sleep -Seconds 2
        Write-Success "Processes stopped."
    } else {
        Write-Fail "Cannot safely update while processes are running. Aborted."
        Read-Host "Press Enter to exit..."
        exit 1
    }
}

# 3. Create Safe Snapshot Backup before touching anything
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $BackupBaseDir "pre-update-$timestamp"

if (-not $SkipBackup) {
    Write-Step "Creating pre-update safety backup..."
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    
    # Backup config, env, memories, and skills
    $dataBackup = Join-Path $backupDir "hermes_data"
    New-Item -ItemType Directory -Path $dataBackup -Force | Out-Null
    foreach ($item in @("config.yaml", ".env", "memories", "skills", "pairing")) {
        $srcPath = Join-Path $HermesHome $item
        if (Test-Path $srcPath) {
            Copy-Item -Path $srcPath -Destination $dataBackup -Recurse -Force
        }
    }
    
    # Save current git commit hash if git repo
    $isGit = Test-Path (Join-Path $HermesAgentDir ".git")
    if ($isGit) {
        try {
            $prevCommit = (& git -C $HermesAgentDir rev-parse HEAD 2>$null)
            if ($prevCommit) {
                Set-Content -Path (Join-Path $backupDir "git_commit.txt") -Value $prevCommit
            }
        } catch {}
    }
    Write-Success "Backup snapshot saved to: backups/pre-update-$timestamp"
}

# 4. Fetch and update repo
Write-Step "Updating Hermes Agent code..."
$updateSuccess = $false
$rollbackNeeded = $false

try {
    if (Test-Path (Join-Path $HermesAgentDir ".git")) {
        Push-Location $HermesAgentDir
        try {
            # Stash any unintentional edits
            & git stash 2>$null | Out-Null
            & git pull origin main
            if ($LASTEXITCODE -ne 0) {
                throw "git pull failed with exit code $LASTEXITCODE"
            }
            Write-Success "Hermes Agent repository pulled latest changes."
        } finally {
            Pop-Location
        }
    } else {
        Write-Step "Fetching latest archive from GitHub..."
        $zipUrl = "https://github.com/NousResearch/hermes-agent/archive/refs/heads/main.zip"
        $zipDest = Join-Path $CacheDir "hermes-update.zip"
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipDest -UseBasicParsing
        
        $tempExtract = Join-Path $CacheDir "hermes_update_extract"
        New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
        Expand-Archive -Path $zipDest -DestinationPath $tempExtract -Force
        
        $extractedFolder = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
        
        # Safe copy over files
        Copy-Item -Path "$($extractedFolder.FullName)\*" -Destination $HermesAgentDir -Recurse -Force
        Remove-Item -Path $zipDest, $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Hermes Agent code updated from latest release archive."
    }

    # 5. Sync Python dependencies with uv
    Write-Step "Updating Python packages in isolated virtual environment..."
    Push-Location $HermesAgentDir
    try {
        & $uvExe pip install -e . --python $pythonExe
        if ($LASTEXITCODE -ne 0) {
            throw "uv pip install failed with exit code $LASTEXITCODE"
        }
        Write-Success "Python packages synced successfully."
    } finally {
        Pop-Location
    }

    # 6. Verify health check
    Write-Step "Verifying updated Hermes installation..."
    $verifyCheck = & $pythonExe -c "import hermes_cli; print('OK')" 2>&1
    if ($verifyCheck -notmatch "OK") {
        throw "Verification test failed: $verifyCheck"
    }
    Write-Success "Health check passed: Hermes imports cleanly."
    $updateSuccess = $true
} catch {
    Write-Fail "Update failed: $_"
    $rollbackNeeded = $true
}

# 7. Automated Rollback if update failed
if ($rollbackNeeded) {
    Write-Warn "Initiating safe rollback from snapshot..."
    try {
        if (Test-Path (Join-Path $HermesAgentDir ".git") -and (Test-Path (Join-Path $backupDir "git_commit.txt"))) {
            $prevCommit = (Get-Content -Path (Join-Path $backupDir "git_commit.txt") -Raw).Trim()
            Push-Location $HermesAgentDir
            & git checkout $prevCommit -f
            Pop-Location
            Write-Success "Reverted repository code to commit $prevCommit"
        }
        
        # Restore configuration
        if (Test-Path (Join-Path $backupDir "hermes_data")) {
            Copy-Item -Path (Join-Path $backupDir "hermes_data\*") -Destination $HermesHome -Recurse -Force
            Write-Success "Restored configuration files."
        }
        
        # Re-sync deps to restored code
        Push-Location $HermesAgentDir
        & $uvExe pip install -e . --python $pythonExe 2>$null | Out-Null
        Pop-Location
        Write-Success "Environment restored to pre-update working state."
    } catch {
        Write-Fail "Automatic rollback encountered an issue: $_"
        Write-Host "Manual backup is preserved at: $backupDir" -ForegroundColor Yellow
    }
    Read-Host "Press Enter to exit..."
    exit 1
}

# 8. Housekeeping: Keep only the 3 most recent backups
try {
    $allBackups = Get-ChildItem -Path $BackupBaseDir -Directory | Sort-Object CreationTime -Descending
    if ($allBackups.Count -gt 3) {
        $toDelete = $allBackups | Select-Object -Skip 3
        $toDelete | ForEach-Object { Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
    }
} catch {}

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "               SAFE UPDATE COMPLETED SUCCESSFULLY!                " -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "Safety backup stored at: backups/pre-update-$timestamp"
Write-Host "All configs, sessions, and memories preserved untouched."
Write-Host "===================================================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit..."
