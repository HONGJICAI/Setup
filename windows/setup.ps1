# Windows Environment Setup Script with Scoop and Winget
# This script installs Scoop package manager with custom path and essential applications

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

Write-Host "=== Windows Environment Setup with Scoop and Winget ===" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion.Major
if ($psVersion -lt 5) {
    Write-Error "PowerShell 5.1 or later is required. Current version: $psVersion"
    exit 1
}

Write-Host "PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host ""

# Determine Scoop installation path
Write-Host "Determining Scoop installation path..." -ForegroundColor Yellow
$scoopPath = $null

# Check if D: drive exists
if (Test-Path "D:\") {
    $scoopPath = "D:\apps\Scoop"
    Write-Host "  D: drive found. Will use: $scoopPath" -ForegroundColor Green
}
else {
    $scoopPath = "C:\apps\Scoop"
    Write-Host "  D: drive not found. Will use: $scoopPath" -ForegroundColor Yellow
}

# Set Scoop environment variables
$env:SCOOP = $scoopPath
[System.Environment]::SetEnvironmentVariable('SCOOP', $scoopPath, 'User')

Write-Host ""

# Install Scoop if not already installed
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop package manager to $scoopPath..." -ForegroundColor Yellow
    
    # Set execution policy for current user
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    
    # Install Scoop with custom path
    try {
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Host "Scoop installed successfully at $scoopPath!" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install Scoop: $_"
        exit 1
    }
}
else {
    Write-Host "Scoop is already installed." -ForegroundColor Green
    $currentScoopPath = scoop prefix scoop
    Write-Host "  Current location: $currentScoopPath" -ForegroundColor Gray
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

# Install applications via winget
Write-Host "Installing applications via winget..." -ForegroundColor Yellow

if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wingetApps = @(
        @{ Name = "Google Chrome"; Id = "Google.Chrome" },
        @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode" },
        @{ Name = "Honeyview"; Id = "Bandisoft.Honeyview" },
        @{ Name = "Docker Desktop"; Id = "Docker.DockerDesktop" }
    )
    
    foreach ($app in $wingetApps) {
        Write-Host "  Checking $($app.Name)..." -ForegroundColor Cyan
        $installed = winget list --id $app.Id --exact 2>&1 | Out-String
        
        if ($installed -match $app.Id) {
            Write-Host "    $($app.Name) is already installed." -ForegroundColor Gray
        }
        else {
            Write-Host "    Installing $($app.Name)..." -ForegroundColor Cyan
            try {
                winget install --id $app.Id --exact --silent --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "    $($app.Name) installed successfully!" -ForegroundColor Green
                }
                else {
                    Write-Host "    Failed to install $($app.Name)" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "    Error installing $($app.Name): $_" -ForegroundColor Red
            }
        }
    }
}
else {
    Write-Warning "winget is not available on this system."
    Write-Host "  Please install App Installer from Microsoft Store to use winget." -ForegroundColor Yellow
}

Write-Host ""

# Install essential packages via Scoop
Write-Host "Installing essential packages via Scoop..." -ForegroundColor Yellow

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
    git config --global credential.helper manager
    
    # Set default branch name
    git config --global init.defaultBranch main
    
    # Enable color output
    git config --global color.ui auto
    
    Write-Host "Git configured successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Scoop installed at: $scoopPath" -ForegroundColor Gray
Write-Host "  - Winget applications: Chrome, VSCode, Honeyview, Docker Desktop" -ForegroundColor Gray
Write-Host "  - Scoop essentials: git, 7zip, curl, wget, and more" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close and reopen your PowerShell terminal to refresh the environment"
Write-Host "  2. Run 'scoop list' to see installed packages"
Write-Host "  3. Run 'scoop search <package>' to find more packages"
Write-Host "  4. Edit packages.txt and run .\install-packages.ps1 to install additional packages"
Write-Host ""
