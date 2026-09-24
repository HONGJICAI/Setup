$ErrorActionPreference = 'Stop'

Write-Host '==> Scoop'

# Scoop's shims are PowerShell scripts, so the user needs a policy that runs them.
# Setting it errors when a narrower scope (e.g. -ExecutionPolicy Bypass) overrides it,
# even though the CurrentUser value is saved, so ignore that.
try { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch { Write-Verbose $_ }

if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "Scoop already installed at $(scoop prefix scoop)"
    return
}

# Install to D:\apps\Scoop when D: is a local disk, otherwise C:\apps\Scoop.
# An already-set SCOOP variable wins.
if (-not $env:SCOOP) {
    $d = [System.IO.DriveInfo]::new('D')
    $root = if ($d.IsReady -and $d.DriveType -eq 'Fixed') { 'D:' } else { 'C:' }
    $env:SCOOP = "$root\apps\Scoop"
}
Write-Host "Installing Scoop to $env:SCOOP"

$installer = Join-Path $env:TEMP 'install-scoop.ps1'
Invoke-RestMethod -Uri 'https://get.scoop.sh' -OutFile $installer

# The installer refuses to run elevated unless told to.
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if ($isAdmin) {
    & $installer -ScoopDir $env:SCOOP -RunAsAdmin
} else {
    & $installer -ScoopDir $env:SCOOP
}
Remove-Item $installer

# Make scoop usable in this session without reopening the terminal.
$env:PATH = "$env:SCOOP\shims;$env:PATH"
