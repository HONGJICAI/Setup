# VPS Setup with sing-box Proxy (Ubuntu)

This folder contains Ansible playbooks to set up a sing-box proxy server with vless + reality protocol on Ubuntu VPS.

## Structure

The setup is organized into modular task files for better maintainability:

```
vps/
├── setup.yml              # Main playbook
├── inventory.ini          # Server inventory
├── requirements.yml       # Ansible dependencies
├── tasks/                 # Task modules
│   ├── bbr.yml           # BBR TCP congestion control setup
│   ├── docker.yml        # Docker and Docker Compose installation
│   └── singbox.yml       # sing-box proxy deployment
└── templates/             # Configuration templates
    ├── singbox-config.json.j2
    └── docker-compose.yml.j2
```

## Features

- **BBR TCP Congestion Control**: Optimizes network performance
- **Docker & Docker Compose**: Container runtime for sing-box
- **sing-box Proxy**: Universal proxy platform with vless + reality
- **Automatic Key Generation**: UUID, private/public keys generated during setup
- **Connection Link Export**: Vless link displayed and saved for easy client configuration

## Prerequisites

- Ubuntu VPS (20.04 or later recommended)
- Ansible installed on your local machine
- SSH access to your VPS with sudo privileges
- Port 443 open on your VPS firewall

**Server Requirements:**
The playbook will automatically install the following on your VPS:
- Python 3 (required by Ansible for remote execution)
- Docker and Docker Compose
- System packages for HTTPS, cryptography, and key generation
- sing-box proxy software

## Installation

1. Install Ansible on your local machine:
   ```bash
   pip install ansible
   ```

2. Update the inventory file `inventory.ini` with your VPS details:
   ```ini
   [vps]
   my-vps ansible_host=YOUR_VPS_IP ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa
   ```

3. Run the setup playbook:
   ```bash
   ansible-playbook -i inventory.ini setup.yml
   ```

## Connection Parameter Persistence

The playbook automatically preserves connection parameters (UUID, keys, short_id) once generated:

- **First run**: Generates new connection parameters and saves them
- **Subsequent runs**: Reuses existing parameters from `/opt/singbox/connection_info.txt`
- **Force regeneration**: Add `-e force_regenerate=true` to generate new parameters

```bash
# Normal run - reuses existing parameters
ansible-playbook -i inventory.ini setup.yml

# Force regenerate parameters (creates new connection link)
ansible-playbook -i inventory.ini setup.yml -e force_regenerate=true
```

**Note**: Forcing regeneration will create a new vless connection link. You'll need to update all your client devices with the new link.

## What Gets Installed

The playbook will:
1. Enable BBR TCP congestion control
2. Install Docker and Docker Compose
3. Generate UUID and Reality keypair
4. Deploy sing-box in a Docker container
5. Configure vless + reality protocol
6. Display the vless connection link

**System Packages Installed:**
- `python3` & `python3-pip` - Required by Ansible for remote execution and package management
- `apt-transport-https` - Enables APT to download packages over HTTPS
- `ca-certificates` - Common Certificate Authority certificates for SSL/TLS verification
- `curl` - Tool for transferring data, used to download Docker GPG keys
- `gnupg` - GNU Privacy Guard for verifying package signatures
- `lsb-release` - Reports Linux distribution version info (needed for Docker repo setup)
- `software-properties-common` - Provides `add-apt-repository` command for managing repos
- `openssl` - Cryptographic toolkit for generating Reality keys and short IDs
- `qrencode` - Generates QR codes for easy vless link import on mobile devices

## Connection Information

After successful deployment, the playbook will display:
- Server IP and port
- UUID
- Public key
- Short ID
- Complete vless connection link

The connection information is also saved to `/opt/singbox/connection_info.txt` on the VPS.

## Configuration

You can customize the setup by editing variables in `setup.yml`:
- `singbox_port`: Default is 443
- `server_name`: SNI for reality (default: www.microsoft.com)
- `dest_server`: Reality destination server (default: www.microsoft.com:443)

## Using the vless Link

Copy the vless link from the output and import it into your client:
- **v2rayN** (Windows): Import from clipboard
- **v2rayNG** (Android): Import from clipboard
- **Shadowrocket** (iOS): Scan QR code or import link
- **Qv2ray** (Cross-platform): Import from clipboard

## Security Notes

- All keys and UUIDs are generated randomly during setup
- Connection information is saved securely on the VPS (600 permissions)
- Keep your private key and connection info secure
- The public key is safe to share with clients

## Troubleshooting

Check sing-box logs:
```bash
docker logs sing-box
```

Restart sing-box:
```bash
cd /opt/singbox
docker-compose restart
```

Check if sing-box is running:
```bash
docker ps | grep sing-box
```

## Advanced

To regenerate keys or reconfigure:
```bash
ansible-playbook -i inventory.ini setup.yml
```

The playbook is idempotent and can be run multiple times safely.
