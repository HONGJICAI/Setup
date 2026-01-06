# Install packages from packages.txt
# This script reads package names from packages.txt and installs them using Scoop

Write-Host "=== Installing Packages from packages.txt ===" -ForegroundColor Cyan
Write-Host ""

# Check if Scoop is installed
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Error "Scoop is not installed. Please run setup.ps1 first."
    exit 1
}

# Check if packages.txt exists
$packagesFile = Join-Path $PSScriptRoot "packages.txt"
if (!(Test-Path $packagesFile)) {
    Write-Error "packages.txt file not found in the script directory."
    exit 1
}

# Read packages from file
$packages = Get-Content $packagesFile | Where-Object { 
    $_ -match '\S' -and $_ -notmatch '^\s*#' 
}

if ($packages.Count -eq 0) {
    Write-Warning "No packages found in packages.txt"
    exit 0
}

Write-Host "Found $($packages.Count) package(s) to install:" -ForegroundColor Yellow
$packages | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

# Install each package
$successful = 0
$failed = 0
$skipped = 0

foreach ($package in $packages) {
    $package = $package.Trim()
    
    # Check if already installed
    $installed = scoop list | Select-String -Pattern "^$([regex]::Escape($package)) "
    if ($installed) {
        Write-Host "[ SKIP ] $package (already installed)" -ForegroundColor Gray
        $skipped++
        continue
    }
    
    # Install package
    Write-Host "[ .... ] Installing $package..." -ForegroundColor Cyan
    try {
        $output = scoop install $package 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[ OK ] $package installed successfully" -ForegroundColor Green
            $successful++
        }
        else {
            Write-Host "[ FAIL ] Failed to install $package" -ForegroundColor Red
            Write-Host $output -ForegroundColor DarkRed
            $failed++
        }
    }
    catch {
        Write-Host "[ FAIL ] Error installing $package : $_" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
Write-Host "=== Installation Summary ===" -ForegroundColor Cyan
Write-Host "  Successful: $successful" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor Red
Write-Host "  Skipped: $skipped" -ForegroundColor Gray
Write-Host ""

if ($failed -gt 0) {
    Write-Host "Some packages failed to install. Check the output above for details." -ForegroundColor Yellow
}
