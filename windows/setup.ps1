# Windows Environment Setup Script with Scoop
# This script installs Scoop package manager and sets up a Windows development environment

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script should be run as Administrator for best results."
    Write-Host "Some features may not work without administrator privileges." -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') {
        exit
    }
}

Write-Host "=== Windows Environment Setup with Scoop ===" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 5) {
    Write-Error "PowerShell 5.1 or later is required. Current version: $psVersion"
    exit 1
}

Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host ""

# Install Scoop if not already installed
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop package manager..." -ForegroundColor Yellow
    
    # Set execution policy for current user
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    
    # Install Scoop
    try {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Host "Scoop installed successfully!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Scoop: $_"
        exit 1
    }
}
else {
    Write-Host "Scoop is already installed." -ForegroundColor Green
}

Write-Host ""

# Update Scoop
Write-Host "Updating Scoop..." -ForegroundColor Yellow
scoop update

Write-Host ""

# Add useful buckets
Write-Host "Adding useful buckets..." -ForegroundColor Yellow

$buckets = @('extras', 'versions', 'java', 'nerd-fonts')
foreach ($bucket in $buckets) {
    $bucketExists = scoop bucket list | Select-String -Pattern "^$([regex]::Escape($bucket))$"
    if (-not $bucketExists) {
        Write-Host "  Adding bucket: $bucket" -ForegroundColor Cyan
        scoop bucket add $bucket
    }
    else {
        Write-Host "  Bucket '$bucket' already added." -ForegroundColor Gray
    }
}

Write-Host ""

# Install essential packages
Write-Host "Installing essential packages..." -ForegroundColor Yellow

$essentialPackages = @(
    'git',          # Version control
    '7zip',         # File archiver
    'aria2',        # Download manager (speeds up Scoop downloads)
    'curl',         # Data transfer tool
    'wget',         # File downloader
    'sudo',         # Run commands with elevated privileges
    'which',        # Locate commands
    'grep',         # Text search
    'less',         # File pager
    'vim'           # Text editor
)

foreach ($package in $essentialPackages) {
    $installed = scoop list | Select-String -Pattern "^$([regex]::Escape($package)) "
    if (-not $installed) {
        Write-Host "  Installing: $package" -ForegroundColor Cyan
        scoop install $package
    }
    else {
        Write-Host "  Package '$package' already installed." -ForegroundColor Gray
    }
}

Write-Host ""

# Configure Git if installed
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Configuring Git..." -ForegroundColor Yellow
    
    # Enable Git credential manager
    git config --global credential.helper manager-core
    
    # Set default branch name
    git config --global init.defaultBranch main
    
    # Enable color output
    git config --global color.ui auto
    
    Write-Host "Git configured successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Scoop has been installed and configured with essential packages." -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close and reopen your PowerShell terminal to refresh the environment"
Write-Host "  2. Run 'scoop list' to see installed packages"
Write-Host "  3. Run 'scoop search <package>' to find more packages"
Write-Host "  4. Edit packages.txt and run .\install-packages.ps1 to install additional packages"
Write-Host ""
