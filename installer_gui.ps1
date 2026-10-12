<#
.SYNOPSIS
    Hermes Agent Portable - Graphical Installer (Nous Portal & Agent Design)
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Hermes Agent — Portable Setup" Height="680" Width="820"
        WindowStartupLocation="CenterScreen" ResizeMode="CanMinimize"
        Background="#0F1714" Foreground="#F3ECDD" FontFamily="Segoe UI, Roboto, sans-serif">
    
    <Window.Resources>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#16211C"/>
            <Setter Property="Foreground" Value="#FFF8EB"/>
            <Setter Property="BorderBrush" Value="#22342C"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#F3ECDD"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Margin" Value="0,6"/>
        </Style>
    </Window.Resources>

    <Grid Margin="28">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Header -->
            <RowDefinition Height="Auto"/> <!-- Target Path -->
            <RowDefinition Height="Auto"/> <!-- Options Cards -->
            <RowDefinition Height="*"/>    <!-- Progress & Terminal Logs -->
            <RowDefinition Height="Auto"/> <!-- Action Buttons -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Border Grid.Row="0" Background="#16211C" BorderBrush="#22342C" BorderThickness="1" CornerRadius="8" Padding="20,16" Margin="0,0,0,18">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="✦ " Foreground="#C89A5A" FontSize="20" FontWeight="Bold"/>
                        <TextBlock Text="NOUS RESEARCH" Foreground="#C89A5A" FontSize="12" FontWeight="Bold"  VerticalAlignment="Center"/>
                        <Border Background="#22342C" CornerRadius="4" Padding="6,2" Margin="10,0,0,0">
                            <TextBlock Text="PORTABLE EDITION" Foreground="#A8B4A5" FontSize="10" FontWeight="Bold"/>
                        </Border>
                    </StackPanel>
                    <TextBlock Text="Hermes Agent Installation" FontSize="22" FontWeight="SemiBold" Foreground="#FFF8EB" Margin="0,4,0,2"/>
                    <TextBlock Text="100% self-contained runtime. Zero admin rights required." FontSize="13" Foreground="#A8B4A5"/>
                </StackPanel>
                <TextBlock Grid.Column="1" Text="v0.21.7" Foreground="#C89A5A" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/>
            </Grid>
        </Border>

        <!-- PATH SELECTION -->
        <Border Grid.Row="1" Background="#16211C" BorderBrush="#22342C" BorderThickness="1" CornerRadius="8" Padding="18,14" Margin="0,0,0,16">
            <StackPanel>
                <TextBlock Text="INSTALLATION DIRECTORY" FontSize="11" FontWeight="Bold" Foreground="#C89A5A" Margin="0,0,0,8" />
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="TxtPath" Grid.Column="0" Text="" Height="38" VerticalContentAlignment="Center"/>
                    <Button Name="BtnBrowse" Grid.Column="1" Content="Browse..." Width="90" Height="38" Margin="10,0,0,0"
                            Background="#22342C" Foreground="#FFF8EB" BorderBrush="#C89A5A" BorderThickness="1" Cursor="Hand" FontWeight="SemiBold"/>
                </Grid>
                <TextBlock Text="All isolated runtimes, Python, memory, tools and packages remain strictly in this directory."
                           FontSize="11" Foreground="#A8B4A5" Margin="0,6,0,0"/>
            </StackPanel>
        </Border>

        <!-- OPTIONS -->
        <Border Grid.Row="2" Background="#16211C" BorderBrush="#22342C" BorderThickness="1" CornerRadius="8" Padding="18,14" Margin="0,0,0,16">
            <StackPanel>
                <TextBlock Text="COMPONENTS &amp; SHORTCUTS" FontSize="11" FontWeight="Bold" Foreground="#C89A5A" Margin="0,0,0,8" />
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0">
                        <CheckBox Name="ChkStartMenu" Content="Add Start Menu shortcut" IsChecked="True"/>
                        <TextBlock Text="User-level shortcuts only (no admin rights)." FontSize="11" Foreground="#A8B4A5" Margin="22,-2,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1">
                        <CheckBox Name="ChkFullGui" Content="Install Full Desktop GUI (Hermes One)" IsChecked="True"/>
                        <TextBlock Text="Electron companion GUI application." FontSize="11" Foreground="#A8B4A5" Margin="22,-2,0,0"/>
                    </StackPanel>
                </Grid>
            </StackPanel>
        </Border>

        <!-- LOG & PROGRESS -->
        <Border Grid.Row="3" Background="#111B17" BorderBrush="#22342C" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,0,0,16">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <TextBlock Name="LblStatus" Grid.Row="0" Text="Ready to initialize environment." FontSize="12" Foreground="#C89A5A" Margin="0,0,0,8"/>
                <ScrollViewer Name="ScrollerLog" Grid.Row="1" VerticalScrollBarVisibility="Auto">
                    <TextBox Name="TxtLog" Background="Transparent" Foreground="#A8B4A5" BorderThickness="0"
                             FontFamily="Consolas, monospace" FontSize="11" IsReadOnly="True" TextWrapping="Wrap"
                             Text="[Nous Portal Setup] Waiting for user confirmation...&#x0a;"/>
                </ScrollViewer>
                <ProgressBar Name="ProgBar" Grid.Row="2" Height="6" Background="#16211C" Foreground="#C89A5A" BorderThickness="0" Margin="0,8,0,0" IsIndeterminate="False"/>
            </Grid>
        </Border>

        <!-- ACTION BUTTONS -->
        <Grid Grid.Row="4">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="Nous Research • Decentralized Autonomous Intelligence" Foreground="#6C7C71" FontSize="11" VerticalAlignment="Center"/>
            <StackPanel Grid.Column="1" Orientation="Horizontal">
                <Button Name="BtnCancel" Content="Close" Width="100" Height="40" Margin="0,0,12,0"
                        Background="#16211C" Foreground="#A8B4A5" BorderBrush="#22342C" BorderThickness="1" Cursor="Hand"/>
                <Button Name="BtnInstall" Content="Begin Installation" Width="170" Height="40"
                        Background="#C89A5A" Foreground="#0F1714" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Element lookups
$txtPath = $window.FindName("TxtPath")
$btnBrowse = $window.FindName("BtnBrowse")
$chkStartMenu = $window.FindName("ChkStartMenu")
$chkFullGui = $window.FindName("ChkFullGui")
$lblStatus = $window.FindName("LblStatus")
$txtLog = $window.FindName("TxtLog")
$scrollerLog = $window.FindName("ScrollerLog")
$progBar = $window.FindName("ProgBar")
$btnInstall = $window.FindName("BtnInstall")
$btnCancel = $window.FindName("BtnCancel")

# Default path
$defaultPath = Join-Path $env:USERPROFILE "HermesAgentPortable"
$txtPath.Text = $defaultPath

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $txtPath.Text
    $dialog.Description = "Select target folder for Hermes Agent Portable"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $txtPath.Text = $dialog.SelectedPath
    }
})

$btnCancel.Add_Click({
    $window.Close()
})

function LogMessage([string]$msg, [string]$color = "#A8B4A5") {
    $time = (Get-Date).ToString("HH:mm:ss")
    $txtLog.AppendText("[$time] $msg`r`n")
    $scrollerLog.ScrollToEnd()
    [System.Windows.Forms.Application]::DoEvents()
}

$btnInstall.Add_Click({
    $target = $txtPath.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.MessageBox]::Show("Please choose an installation path.", "Notice", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $btnInstall.IsEnabled = $false
    $btnBrowse.IsEnabled = $false
    $txtPath.IsEnabled = $false
    $chkStartMenu.IsEnabled = $false
    $chkFullGui.IsEnabled = $false
    $progBar.IsIndeterminate = $true

    $installWithGui = $chkFullGui.IsChecked
    $installWithShortcut = $chkStartMenu.IsChecked

    try {
        LogMessage "Preparing directory: $target"
        $lblStatus.Text = "Creating isolated directory tree..."
        if (-not (Test-Path $target)) {
            New-Item -ItemType Directory -Path $target -Force | Out-Null
        }

        # Setup folders
        $HermesHome = Join-Path $target "hermes_data"
        $HermesAgentDir = Join-Path $target "hermes-agent"
        $ToolsDir = Join-Path $target "tools"
        $UvBinDir = Join-Path $ToolsDir "uv"
        $GitBinDir = Join-Path $ToolsDir "git"
        $CacheDir = Join-Path $target "cache"
        $PythonDir = Join-Path $ToolsDir "python"
        $VenvDir = Join-Path $target ".venv"

        foreach ($p in @($HermesHome, $ToolsDir, $UvBinDir, $CacheDir, $PythonDir)) {
            if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
        }

        $env:HERMES_HOME = $HermesHome
        $env:HERMES_RUNTIME_DIR = $ToolsDir
        $env:UV_CACHE_DIR = Join-Path $CacheDir "uv"
        $env:UV_PYTHON_INSTALL_DIR = $PythonDir
        $env:TEMP = Join-Path $CacheDir "temp"
        $env:TMP = Join-Path $CacheDir "temp"
        New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null

        # Architecture
        $arch = if ([System.Environment]::Is64BitOperatingSystem) {
            if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") { "aarch64" } else { "x86_64" }
        } else {
            throw "Hermes Agent requires a 64-bit Windows environment."
        }

        # 1. uv
        $uvExe = Join-Path $UvBinDir "uv.exe"
        if (-not (Test-Path $uvExe)) {
            $lblStatus.Text = "Downloading portable uv runtime..."
            LogMessage "Downloading standalone uv package manager ($arch)..."
            $uvZipUrl = "https://github.com/astral-sh/uv/releases/latest/download/uv-$arch-pc-windows-msvc.zip"
            $uvZipPath = Join-Path $CacheDir "uv.zip"
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
            Invoke-WebRequest -Uri $uvZipUrl -OutFile $uvZipPath -UseBasicParsing
            Expand-Archive -Path $uvZipPath -DestinationPath $CacheDir -Force
            $foundUv = Get-ChildItem -Path $CacheDir -Filter "uv.exe" -Recurse | Select-Object -First 1
            Copy-Item -Path $foundUv.FullName -Destination $uvExe -Force
            Remove-Item -Path $uvZipPath -Force -ErrorAction SilentlyContinue
            LogMessage "uv provisioned successfully."
        }
        $env:Path = "$UvBinDir;$env:Path"

        # 2. Git
        $gitExe = Join-Path $GitBinDir "cmd\git.exe"
        $hasSystemGit = $false
        try {
            $check = & git --version 2>$null
            if ($LASTEXITCODE -eq 0) { $hasSystemGit = $true }
        } catch {}

        if (-not $hasSystemGit -and -not (Test-Path $gitExe)) {
            $lblStatus.Text = "Downloading isolated MinGit..."
            LogMessage "Fetching MinGit (portable)..."
            $gitZipPath = Join-Path $CacheDir "mingit.zip"
            try {
                Invoke-WebRequest -Uri "https://github.com/git-for-windows/git/releases/download/v2.48.1.windows.1/MinGit-2.48.1-64-bit.zip" -OutFile $gitZipPath -UseBasicParsing
                Expand-Archive -Path $gitZipPath -DestinationPath $GitBinDir -Force
                Remove-Item -Path $gitZipPath -Force -ErrorAction SilentlyContinue
                LogMessage "MinGit provisioned."
            } catch {
                LogMessage "MinGit download skipped. Will use release archive."
            }
        }
        if (Test-Path $gitExe) { $env:Path = "$GitBinDir\cmd;$GitBinDir\usr\bin;$env:Path" }

        # 3. Hermes Agent Source
        $lblStatus.Text = "Fetching Hermes Agent repository..."
        LogMessage "Cloning latest Hermes Agent from GitHub..."
        if (-not (Test-Path (Join-Path $HermesAgentDir ".git"))) {
            try {
                & git clone --depth 1 https://github.com/NousResearch/hermes-agent.git $HermesAgentDir
                if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
                LogMessage "Repository cloned."
            } catch {
                LogMessage "Git clone failed. Downloading zipball archive..."
                $zipUrl = "https://github.com/NousResearch/hermes-agent/archive/refs/heads/main.zip"
                $zipDest = Join-Path $CacheDir "hermes-agent.zip"
                Invoke-WebRequest -Uri $zipUrl -OutFile $zipDest -UseBasicParsing
                $tempExtract = Join-Path $CacheDir "hermes_extract"
                New-Item -ItemType Directory -Path $tempExtract -Force | Out-Null
                Expand-Archive -Path $zipDest -DestinationPath $tempExtract -Force
                $extracted = Get-ChildItem -Path $tempExtract -Directory | Select-Object -First 1
                Move-Item -Path $extracted.FullName -Destination $HermesAgentDir -Force
                Remove-Item -Path $zipDest, $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
                LogMessage "Archive extracted."
            }
        } else {
            LogMessage "Updating existing checkout to latest..."
            Push-Location $HermesAgentDir
            & git pull origin main 2>$null | Out-Null
            Pop-Location
        }

        # 4. Portable Python 3.14
        $lblStatus.Text = "Installing Portable Python 3.14..."
        LogMessage "Provisioning isolated Python 3.14 via uv..."
        Push-Location $HermesAgentDir
        try {
            & $uvExe python install 3.14
            LogMessage "Python 3.14 ready in tools/python."

            $lblStatus.Text = "Creating isolated virtual environment..."
            LogMessage "Initializing .venv with Python 3.14..."
            & $uvExe venv $VenvDir --python 3.14 --clear

            $pythonVenvExe = Join-Path $VenvDir "Scripts\python.exe"
            $lblStatus.Text = "Installing dependencies (ruamel.yaml, openai, etc)..."
            LogMessage "Installing dependencies into local virtual environment..."
            & $uvExe pip install -e . --python $pythonVenvExe
            LogMessage "Dependencies installed and linked."
        } finally {
            Pop-Location
        }

        # 5. Configs
        $lblStatus.Text = "Configuring local storage..."
        foreach ($d in @("cron","sessions","logs","pairing","hooks","image_cache","audio_cache","memories","skills","bin")) {
            New-Item -ItemType Directory -Force -Path (Join-Path $HermesHome $d) | Out-Null
        }
        $envFile = Join-Path $HermesHome ".env"
        if (-not (Test-Path $envFile)) {
            $ex = Join-Path $HermesAgentDir ".env.example"
            if (Test-Path $ex) { Copy-Item $ex $envFile } else { Set-Content -Path $envFile -Value "# Hermes Config`r`n" }
        }
        $cfgFile = Join-Path $HermesHome "config.yaml"
        if (-not (Test-Path $cfgFile)) {
            $cfgEx = Join-Path $HermesAgentDir "cli-config.yaml.example"
            if (Test-Path $cfgEx) { Copy-Item $cfgEx $cfgFile }
        }

        # 6. Launchers
        $lblStatus.Text = "Generating portable launchers..."
        $batchLauncher = Join-Path $target "Hermes.bat"
        $batchContent = @"
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

if not exist "%TEMP%" mkdir "%TEMP%"

if "%~1"=="" (
    echo Starting Hermes Agent...
    "%~dp0.venv\Scripts\hermes.exe"
) else (
    "%~dp0.venv\Scripts\hermes.exe" %*
)

if errorlevel 1 (
    echo.
    echo Hermes Agent exited with error code %errorlevel%.
    pause
)
endlocal
"@
        Set-Content -Path $batchLauncher -Value $batchContent -Encoding ASCII

        $setupLauncher = Join-Path $target "Setup.bat"
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
"%~dp0.venv\Scripts\hermes.exe" setup --portal
pause
endlocal
"@
        Set-Content -Path $setupLauncher -Value $setupContent -Encoding ASCII

        # Copy safe updater
        $safeUpdateSrc = Join-Path $PSScriptRoot "safe_update.ps1"
        $safeUpdateDest = Join-Path $target "safe_update.ps1"
        if (Test-Path $safeUpdateSrc) { Copy-Item $safeUpdateSrc $safeUpdateDest -Force }

        $updateLauncher = Join-Path $target "Update.bat"
        $updateContent = @"
@echo off
title Hermes Agent - Safe Updater
setlocal
cd /d "%~dp0"

echo Launching Hermes Agent Safe Updater...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0safe_update.ps1"

if errorlevel 1 (
    echo.
    echo Update encountered an issue. Check the output above.
    pause
    exit /b %errorlevel%
)
endlocal
"@
        Set-Content -Path $updateLauncher -Value $updateContent -Encoding ASCII

        # 7. Optional Full GUI
        if ($installWithGui) {
            $lblStatus.Text = "Downloading Hermes Desktop GUI..."
            LogMessage "Fetching latest portable Hermes Desktop GUI release..."
            $guiExe = Join-Path $target "HermesDesktop.exe"
            try {
                $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/fathah/hermes-desktop/releases/latest" -Headers @{ "User-Agent" = "Hermes-Installer" }
                $portableAsset = $releaseInfo.assets | Where-Object { $_.name -like "*portable.exe" } | Select-Object -First 1
                if ($portableAsset -and $portableAsset.browser_download_url) {
                    Invoke-WebRequest -Uri $portableAsset.browser_download_url -OutFile $guiExe -UseBasicParsing
                    LogMessage "HermesDesktop.exe downloaded."
                }
            } catch {
                Invoke-WebRequest -Uri "https://github.com/fathah/hermes-desktop/releases/download/v0.7.7/hermes-desktop-0.7.7-portable.exe" -OutFile $guiExe -UseBasicParsing
                LogMessage "HermesDesktop.exe downloaded (fallback)."
            }

            $guiBat = Join-Path $target "Hermes-GUI.bat"
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
        }

        # 8. Start Menu Shortcuts
        if ($installWithShortcut) {
            $lblStatus.Text = "Creating Start Menu shortcuts..."
            $programsDir = [Environment]::GetFolderPath('Programs')
            $startMenuFolder = Join-Path $programsDir "Hermes Agent Portable"
            if (-not (Test-Path $startMenuFolder)) { New-Item -ItemType Directory -Path $startMenuFolder -Force | Out-Null }
            $wsh = New-Object -ComObject WScript.Shell

            $sCli = $wsh.CreateShortcut((Join-Path $startMenuFolder "Hermes Agent.lnk"))
            $sCli.TargetPath = $batchLauncher
            $sCli.WorkingDirectory = $target
            $sCli.Save()

            $sSetup = $wsh.CreateShortcut((Join-Path $startMenuFolder "Hermes Agent Setup.lnk"))
            $sSetup.TargetPath = $setupLauncher
            $sSetup.WorkingDirectory = $target
            $sSetup.Save()

            $sUp = $wsh.CreateShortcut((Join-Path $startMenuFolder "Hermes Agent Update.lnk"))
            $sUp.TargetPath = $updateLauncher
            $sUp.WorkingDirectory = $target
            $sUp.Save()

            if (Test-Path (Join-Path $target "HermesDesktop.exe")) {
                $sGui = $wsh.CreateShortcut((Join-Path $startMenuFolder "Hermes Desktop GUI.lnk"))
                $sGui.TargetPath = (Join-Path $target "Hermes-GUI.bat")
                $sGui.WorkingDirectory = $target
                $sGui.Save()
            }
            LogMessage "Start Menu shortcuts created."
        }

        $progBar.IsIndeterminate = $false
        $progBar.Value = 100
        $lblStatus.Text = "Installation Complete!"
        LogMessage "SUCCESS: Hermes Agent Portable is ready to launch."
        [System.Windows.MessageBox]::Show("Hermes Agent Portable successfully installed to:`n$target`n`nLaunch with Hermes.bat or Setup.bat.", "Setup Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)

    } catch {
        $progBar.IsIndeterminate = $false
        $lblStatus.Text = "Installation encountered an error."
        LogMessage "ERROR: $_"
        [System.Windows.MessageBox]::Show("Installation failed:`n$_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
    } finally {
        $btnInstall.Content = "Finished"
        $btnCancel.Content = "Close"
    }
})

$window.ShowDialog() | Out-Null
