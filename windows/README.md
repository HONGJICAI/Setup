# windows setup

Auto-install scripts for a fresh Windows PC.

## Usage

Download the repo (zip is fine, no git needed yet), then in PowerShell:

```powershell
cd windows
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

No need to run as Administrator. Some winget installers will show a UAC
prompt on their own. Open a new terminal after it finishes.

## What it installs

Edit the lists, not the scripts:

- `scoop.txt` — CLI tools via [Scoop](https://scoop.sh). Use `bucket/app`
  for non-main buckets (e.g. `extras/vscode`); the bucket is added for you.
- `winget.txt` — GUI apps via winget, by package ID (`winget search <name>`).

## Script order

`install.ps1` runs these in sequence:

1. `01-scoop.ps1` — sets the CurrentUser execution policy to RemoteSigned and
   installs Scoop to `D:\apps\Scoop` (if D: is a local disk) or
   `C:\apps\Scoop`. Set `$env:SCOOP` first to choose another location.
2. `02-scoop-apps.ps1` — installs everything in `scoop.txt`
3. `03-git-config.ps1` — credential manager, `init.defaultBranch main`
4. `04-winget-apps.ps1` — installs everything in `winget.txt`

Each script is idempotent: already-installed apps are skipped. A step that
fails to install something lists it and stops, so fix it and re-run.

## CI

`.github/workflows/install-windows.yml` runs steps 1–3 on `windows-latest`
for any change under `windows/`. The winget step is skipped there: its apps
are GUI installers (Docker Desktop needs WSL and a reboot). `lint.yml` runs
PSScriptAnalyzer on the scripts.
