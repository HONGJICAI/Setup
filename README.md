# Setup

Personal use software and scripts for VPS and Windows environments.

[![Validate Setup Scripts](https://github.com/HONGJICAI/Setup/actions/workflows/validate.yml/badge.svg)](https://github.com/HONGJICAI/Setup/actions/workflows/validate.yml)

## Contents

- **[vps/](vps/)** - Ansible playbooks for VPS setup and maintenance
  - Setup BBR TCP congestion control
  - Install Docker and Docker Compose
  
- **[windows/](windows/)** - Scoop-based setup scripts for Windows
  - Automated Windows environment setup
  - Package management with Scoop
  - Run Ansible on Windows via Docker (for VPS management)

## Quick Start

### VPS Setup

```bash
cd vps
# Edit inventory.ini with your VPS details
ansible-playbook -i inventory.ini setup.yml
```

### Windows Setup

```powershell
cd windows
.\setup.ps1
```

### Run Ansible from Windows (VPS Management)

Windows users can manage their VPS using Ansible via Docker:

```powershell
cd windows
.\run-ansible.ps1
```

This runs the VPS Ansible playbooks from Windows without installing Ansible natively. Requires Docker Desktop.

## Requirements

- **VPS**: Ansible installed locally, SSH access to VPS
- **Windows**: PowerShell 5.1+, Administrator privileges

See individual README files in each directory for detailed instructions.

## Validation

All scripts are automatically validated on push using GitHub Actions:
- **Ansible playbooks**: YAML syntax, Ansible syntax check, ansible-lint
- **PowerShell scripts**: PowerShell syntax check, PSScriptAnalyzer

You can run validation locally:
```bash
# Install validation tools
pip install ansible ansible-lint yamllint

# Validate Ansible playbooks
cd vps
ansible-playbook --syntax-check setup.yml
ansible-lint setup.yml tasks/*.yml
```

