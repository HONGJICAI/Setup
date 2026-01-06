# Setup

Personal use software and scripts for VPS and Windows environments.

## Contents

- **[vps/](vps/)** - Ansible playbooks for VPS setup and maintenance
  - Setup BBR TCP congestion control
  - Install Docker and Docker Compose
  
- **[windows/](windows/)** - Scoop-based setup scripts for Windows
  - Automated Windows environment setup
  - Package management with Scoop

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

## Requirements

- **VPS**: Ansible installed locally, SSH access to VPS
- **Windows**: PowerShell 5.1+, Administrator privileges

See individual README files in each directory for detailed instructions.
