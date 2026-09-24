$ErrorActionPreference = 'Stop'

Write-Host '==> Windows sudo'

# Built into Windows 11 24H2+, off by default. Enabling it needs admin.
$sudo = "$env:SystemRoot\System32\sudo.exe"
if (-not (Test-Path $sudo)) {
    Write-Warning 'sudo.exe not found (needs Windows 11 24H2 or later), skipping.'
    return
}

# Enabled: 0 = off, 1 = new window, 2 = input disabled, 3 = inline (normal).
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Sudo'
$mode = (Get-ItemProperty $key -Name Enabled -ErrorAction SilentlyContinue).Enabled
if ($mode -eq 3) {
    Write-Host '  sudo already enabled (inline)'
    return
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    & $sudo config --enable normal
    if ($LASTEXITCODE -ne 0) { throw 'Failed to enable sudo' }
} else {
    Write-Host '  Enabling sudo needs admin, approve the UAC prompt'
    $p = Start-Process $sudo -ArgumentList 'config', '--enable', 'normal' -Verb RunAs -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw 'Failed to enable sudo' }
}
