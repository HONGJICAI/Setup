# VPS Setup with Ansible

This folder contains Ansible playbooks to set up and maintain a VPS environment.

## Prerequisites

- Ansible installed on your local machine
- SSH access to your VPS
- Python 3 installed on the VPS

## Installation

1. Install Ansible on your local machine:
   ```bash
   pip install ansible
   ```

2. Update the inventory file `inventory.ini` with your VPS details

3. Run the setup playbook:
   ```bash
   ansible-playbook -i inventory.ini setup.yml
   ```

## What's Included

- **BBR TCP Congestion Control**: Optimizes network performance
- **Docker**: Container runtime
- **Docker Compose**: Multi-container Docker applications

## Configuration

Edit `inventory.ini` to configure your VPS connection:
- Update `ansible_host` with your VPS IP address
- Update `ansible_user` with your SSH user
- Update `ansible_ssh_private_key_file` if using key-based authentication
