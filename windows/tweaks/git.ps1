$ErrorActionPreference = 'Stop'

# Scoop's git ships Git Credential Manager.
git config --global credential.helper manager
git config --global init.defaultBranch main
