# Usage: powershell -ExecutionPolicy Bypass -File .\install.ps1
# Runs every step in order. Safe to re-run.
$ErrorActionPreference = 'Stop'

& "$PSScriptRoot\01-scoop.ps1"
& "$PSScriptRoot\02-scoop-apps.ps1"
& "$PSScriptRoot\03-git-config.ps1"
& "$PSScriptRoot\04-sudo.ps1"
& "$PSScriptRoot\05-winget-apps.ps1"

Write-Host ''
Write-Host 'All done. Open a new terminal to pick up PATH changes.'
