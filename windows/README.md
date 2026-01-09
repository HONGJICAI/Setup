# Windows Setup with Scoop and Winget

This folder contains scripts to set up and maintain a Windows environment using Scoop package manager and Winget.

## Scripts

### setup.ps1
Main setup script that:
- Installs Scoop package manager with custom installation path
- Installs applications via winget (Chrome, VSCode, Honeyview, Docker Desktop)
- Installs essential development tools via Scoop
- Configures Git with recommended settings

**Scoop Installation Path:**
- Prefers `D:\apps\Scoop` if D: drive exists
- Falls back to `C:\apps\Scoop` if D: drive is not available

### install-packages.ps1
Installs additional packages from `packages.txt` file using Scoop.

### run-ansible.ps1
Runs Ansible playbooks on Windows using Docker, allowing you to manage VPS from Windows without installing Ansible natively.

## Prerequisites

- Windows 10/11 or Windows Server
- PowerShell 5.1 or later
- Internet connection
- Administrator privileges (recommended)

## Installation

1. Open PowerShell as Administrator

2. Run the setup script:
   ```powershell
   .\setup.ps1
   ```

The script will:
- Determine the best installation path for Scoop (D:\apps\Scoop or C:\apps\Scoop)
- Install Scoop package manager
- Install winget applications: Chrome, VSCode, Honeyview, Docker Desktop
- Install Scoop essentials: git, 7zip, curl, wget, and more
- Configure Git with recommended settings

## What's Installed

### Via Winget
- **Google Chrome** - Web browser
- **Visual Studio Code** - Code editor
- **Honeyview** - Image viewer
- **Docker Desktop** - Container platform

### Via Scoop
- **git** - Version control system
- **7zip** - File archiver
- **aria2** - Download manager (speeds up Scoop downloads)
- **curl** - Data transfer tool
- **wget** - File downloader
- **sudo** - Run commands with elevated privileges
- **which** - Locate commands
- **grep** - Text search utility
- **less** - File pager
- **vim** - Text editor

## Custom Scoop Installation Path

The script automatically chooses the installation path:
- **If D: drive exists**: Installs to `D:\apps\Scoop`
- **If D: drive doesn't exist**: Installs to `C:\apps\Scoop`

This allows you to keep applications on a separate drive if available, saving space on your system drive.

## Scoop Overview

Scoop is a command-line installer for Windows that makes it easy to install and manage applications. It:
- Installs programs in your user directory (no UAC prompts)
- Keeps applications up to date
- Manages dependencies automatically
- Allows easy uninstallation

## Usage

After installation, you can use Scoop to manage packages:

```powershell
# Search for packages
scoop search <package-name>

# Install a package
scoop install <package-name>

# Update all packages
scoop update *

# List installed packages
scoop list

# Uninstall a package
scoop uninstall <package-name>
```

## Adding More Packages

To install additional packages, edit the `packages.txt` file and add package names (one per line), then run:

```powershell
.\install-packages.ps1
```

## Common Buckets

Scoop organizes packages into "buckets". Common buckets include:
- `main` - Default bucket with essential utilities
- `extras` - Additional applications
- `versions` - Alternative versions of programs
- `java` - Java development tools
- `nerd-fonts` - Programming fonts

To add a bucket:
```powershell
scoop bucket add <bucket-name>
```

## Running Ansible on Windows

The `run-ansible.ps1` script allows you to run Ansible playbooks from Windows using Docker, without needing to install Ansible natively.

### Prerequisites for Ansible

- Docker Desktop for Windows installed and running
- SSH access configured to your VPS
- Ansible playbook files (usually in `../vps/` directory)

### Usage

Navigate to the windows directory and run:

```powershell
# Run with defaults (uses setup.yml and inventory.ini from vps folder)
.\run-ansible.ps1

# Run with custom playbook and inventory
.\run-ansible.ps1 -PlaybookPath custom.yml -InventoryPath hosts.ini

# Run with specific SSH key
.\run-ansible.ps1 -SSHKeyPath C:\Users\YourName\.ssh\id_rsa

# Show help
.\run-ansible.ps1 -Help
```

### How It Works

1. The script checks if Docker is installed and running
2. Pulls the latest Ansible Docker image (cytopia/ansible)
3. Mounts your playbook files and SSH keys into the container
4. Runs the Ansible playbook inside the container
5. Automatically cleans up the container when done

### SSH Key Configuration

The script will automatically look for SSH keys in these locations:
- `~\.ssh\id_rsa`
- `~\.ssh\id_ed25519`

Or you can specify a custom path with `-SSHKeyPath`.

### Example Workflow

```powershell
# 1. Navigate to the repository
cd C:\Path\To\Setup

# 2. Ensure Docker Desktop is running

# 3. Run the Ansible playbook to setup your VPS
cd windows
.\run-ansible.ps1

# The script will automatically find and use files from ../vps/
```

### Troubleshooting

**Docker not found:**
- Install Docker Desktop from https://www.docker.com/products/docker-desktop
- Make sure Docker Desktop is running

**SSH connection failed:**
- Verify your SSH key path is correct
- Check that your inventory.ini has the correct VPS IP and user
- Ensure your VPS firewall allows SSH connections

**Playbook not found:**
- Make sure you're running the script from the `windows` directory
- Verify the VPS files exist in `../vps/`

