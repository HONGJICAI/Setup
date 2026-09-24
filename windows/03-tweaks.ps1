$ErrorActionPreference = 'Stop'

# Runs every tweaks\*.ps1. Tweaks are independent, so one failing doesn't stop the rest.
$failed = @()
foreach ($tweak in Get-ChildItem (Join-Path $PSScriptRoot 'tweaks') -Filter *.ps1 | Sort-Object Name) {
    Write-Host "==> Tweak: $($tweak.BaseName)"
    try {
        & $tweak.FullName
    } catch {
        Write-Warning "$($tweak.BaseName) failed: $_"
        $failed += $tweak.BaseName
    }
}

if ($failed) { throw "Tweaks failed: $($failed -join ', ')" }
