# Hermes Agent - Portable Installer

100% self-contained, zero-admin installer and runtime for **[Hermes Agent](https://hermes-agent.nousresearch.com/)** by Nous Research.

---

## Features

- **Custom Location Picker**: GUI folder selector pops up on launch (with console fallback).
- **Auto-Fetches Latest**: Clones latest `NousResearch/hermes-agent` (or downloads latest GitHub archive).
- **Zero Admin Rights**: No UAC prompt, no system environment variable alteration, no system registry writes.
- **Strict Isolation**: Everything resides only in the chosen folder:
  - Portable `uv` package & runtime manager
  - Isolated Portable Python 3.12 (managed via uv)
  - Isolated Git / MinGit
  - Local configuration, memory, sqlite db, skills, and logs inside `hermes_data/`
  - Local temporary cache inside `cache/`

---

## How to Install

1. Double-click **`Install-Hermes-Portable.bat`** (or execute `install.ps1` in PowerShell).
2. Choose your desired target folder (e.g. `D:\HermesAgent`, `E:\AI\Hermes`, or on a USB drive).
3. The installer automatically downloads `uv`, portable Python, Git, and Hermes Agent repository and builds the local virtual environment.

---

## How to Run

Once installed, navigate to your installation folder and use:

- **`Hermes.bat`**: Starts the interactive Hermes Agent CLI.
- **`Setup.bat`**: Launches the Hermes configuration wizard & browser onboarding portal (`hermes setup --portal`).
- **`Update.bat`**: Pulls latest upstream changes from GitHub and syncs Python dependencies.
- **`Hermes.ps1`**: PowerShell equivalent launcher for CLI scripts or terminal power users.

---

## Directory Structure in Installed Target

```
<Your Chosen Folder>/
├── .venv/                 # Fully isolated virtual environment
├── tools/
│   ├── uv/               # Portable uv binary
│   ├── python/           # Isolated Python 3.12 installation
│   └── git/              # Isolated MinGit (if system git was missing)
├── hermes-agent/         # Source checkout
├── hermes_data/          # All state (HERMES_HOME: memories, config, sessions, cron)
├── cache/                # Isolated UV & temporary cache
├── Hermes.bat            # Main CLI launcher
├── Setup.bat             # Portal & setup wizard
└── Update.bat            # Auto-updater
```
