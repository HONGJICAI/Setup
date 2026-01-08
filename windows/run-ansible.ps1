# Run Ansible on Windows using Docker
# This script allows you to run Ansible playbooks from Windows without installing Ansible natively

param(
    [Parameter(Mandatory=$false)]
    [string]$PlaybookPath = "setup.yml",
    
    [Parameter(Mandatory=$false)]
    [string]$InventoryPath = "inventory.ini",
    
    [Parameter(Mandatory=$false)]
    [string]$SSHKeyPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

function Show-Help {
    Write-Host @"
Run Ansible on Windows using Docker

USAGE:
    .\run-ansible.ps1 [-PlaybookPath <path>] [-InventoryPath <path>] [-SSHKeyPath <path>] [-Help]

PARAMETERS:
    -PlaybookPath    Path to the Ansible playbook (default: setup.yml)
    -InventoryPath   Path to the inventory file (default: inventory.ini)
    -SSHKeyPath      Path to SSH private key file (optional)
    -Help            Show this help message

EXAMPLES:
    # Run the default playbook
    .\run-ansible.ps1

    # Run with custom playbook and inventory
    .\run-ansible.ps1 -PlaybookPath custom.yml -InventoryPath hosts.ini

    # Run with SSH key
    .\run-ansible.ps1 -SSHKeyPath C:\Users\YourName\.ssh\id_rsa

PREREQUISITES:
    - Docker Desktop for Windows must be installed and running
    - VPS files should be in the current directory or vps/ subdirectory

NOTES:
    - This script uses the official Ansible Docker image
    - SSH keys and playbook files are mounted into the container
    - The container is automatically removed after execution
"@
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host "=== Ansible on Windows via Docker ===" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed and running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker command failed"
    }
    Write-Host "✓ Docker is installed: $dockerVersion" -ForegroundColor Green
}
catch {
    Write-Error "Docker is not installed or not running. Please install Docker Desktop for Windows."
    Write-Host "Download from: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Check if Docker is running
Write-Host "Checking if Docker is running..." -ForegroundColor Yellow
try {
    docker ps > $null 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker daemon not running"
    }
    Write-Host "✓ Docker is running" -ForegroundColor Green
}
catch {
    Write-Error "Docker is not running. Please start Docker Desktop."
    exit 1
}

Write-Host ""

# Determine working directory
$vpsDir = $PWD.Path
if (Test-Path "vps") {
    $vpsDir = Join-Path $PWD.Path "vps"
    Write-Host "Using VPS directory: $vpsDir" -ForegroundColor Cyan
}

# Check if playbook exists
$playbookFullPath = Join-Path $vpsDir $PlaybookPath
if (-not (Test-Path $playbookFullPath)) {
    Write-Error "Playbook not found: $playbookFullPath"
    Write-Host "Make sure you're in the correct directory or specify the correct path." -ForegroundColor Yellow
    exit 1
}

# Check if inventory exists
$inventoryFullPath = Join-Path $vpsDir $InventoryPath
if (-not (Test-Path $inventoryFullPath)) {
    Write-Error "Inventory file not found: $inventoryFullPath"
    Write-Host "Make sure your inventory.ini file exists and is configured." -ForegroundColor Yellow
    exit 1
}

Write-Host "Playbook: $playbookFullPath" -ForegroundColor Gray
Write-Host "Inventory: $inventoryFullPath" -ForegroundColor Gray

# Prepare Docker volume mounts
$volumeMounts = @(
    "-v", "`"${vpsDir}:/ansible`""
)

# Add SSH key mount if specified
if ($SSHKeyPath -and (Test-Path $SSHKeyPath)) {
    Write-Host "SSH Key: $SSHKeyPath" -ForegroundColor Gray
    $volumeMounts += "-v", "`"${SSHKeyPath}:/root/.ssh/id_rsa:ro`""
}
elseif ($SSHKeyPath) {
    Write-Warning "SSH key not found: $SSHKeyPath"
    Write-Host "Continuing without SSH key..." -ForegroundColor Yellow
}

# Check for default SSH key locations if none specified
if (-not $SSHKeyPath) {
    $defaultKeyPaths = @(
        "$env:USERPROFILE\.ssh\id_rsa",
        "$env:USERPROFILE\.ssh\id_ed25519"
    )
    
    foreach ($keyPath in $defaultKeyPaths) {
        if (Test-Path $keyPath) {
            Write-Host "Found SSH key: $keyPath" -ForegroundColor Gray
            $volumeMounts += "-v", "`"${keyPath}:/root/.ssh/id_rsa:ro`""
            break
        }
    }
}

Write-Host ""
Write-Host "Pulling Ansible Docker image..." -ForegroundColor Yellow
docker pull cytopia/ansible:latest

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to pull Ansible Docker image"
    exit 1
}

Write-Host ""
Write-Host "Running Ansible playbook..." -ForegroundColor Yellow
Write-Host "Command: ansible-playbook -i $InventoryPath $PlaybookPath" -ForegroundColor Gray
Write-Host ""

# Build the docker run command
$dockerCmd = @(
    "run",
    "--rm",
    "-it"
) + $volumeMounts + @(
    "-w", "/ansible",
    "cytopia/ansible:latest",
    "ansible-playbook",
    "-i", $InventoryPath,
    $PlaybookPath
)

# Execute docker command
& docker $dockerCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✓ Ansible playbook execution completed successfully!" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Error "Ansible playbook execution failed with exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "=== Done ===" -ForegroundColor Cyan
