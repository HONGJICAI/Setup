# Windows Setup with Scoop

This folder contains scripts to set up and maintain a Windows environment using Scoop package manager.

## Prerequisites

- Windows 10/11 or Windows Server
- PowerShell 5.1 or later
- Internet connection

## Installation

1. Open PowerShell as Administrator

2. Run the setup script:
   ```powershell
   .\setup.ps1
   ```

## What's Included

The setup script will:
- Install Scoop package manager if not already installed
- Configure Scoop with recommended settings
- Install essential packages and tools

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
