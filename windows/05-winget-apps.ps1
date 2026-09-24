# Usage: .\05-winget-apps.ps1 [-Exclude Id1, Id2]
param([string[]]$Exclude = @())
$ErrorActionPreference = 'Stop'

Write-Host '==> winget apps (winget.txt)'

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found. Install "App Installer" from the Microsoft Store, then re-run.'
}

$ids = Get-Content (Join-Path $PSScriptRoot 'winget.txt') |
    ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
    Where-Object { $_ -and $_ -notin $Exclude }

$failed = @()
foreach ($id in $ids) {
    winget list --id $id --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  $id already installed"
        continue
    }
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { $failed += $id }
}

if ($failed) { throw "Failed to install: $($failed -join ', ')" }
