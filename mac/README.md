# mac setup

Auto-install scripts for a fresh macbook.

## Usage

```sh
cd mac
./install.sh
```

Open a new terminal (or `exec zsh`) after it finishes to pick up shell changes.

## What it installs

- **CLI**: git, gh, pnpm, jq, bat, eza, bitwarden-cli
- **Apps**: VS Code, OrbStack, Chrome, Bitwarden, Ghostty, Windows App
  (Microsoft Remote Desktop), Stats, Bruno, Raycast
- **Font**: JetBrainsMono Nerd Font
- **Runtime**: nvm + Node LTS
- **Shell**: oh-my-zsh + zsh-autosuggestions + zsh-syntax-highlighting
- **Ghostty**: a starter `~/.config/ghostty/config` using JetBrainsMono

## Script order

`install.sh` runs these in sequence:

1. `01-homebrew.sh` — Xcode Command Line Tools + Homebrew + PATH in `~/.zprofile`
2. `02-brew-bundle.sh` — `brew bundle` from `Brewfile`
3. `03-nvm-node.sh` — nvm (official installer) + latest LTS Node
4. `04-oh-my-zsh.sh` — oh-my-zsh + plugin repos cloned into `$ZSH_CUSTOM`
5. `05-shell-config.sh` — edits `~/.zshrc`: enables plugins, adds nvm sourcing, eza aliases
6. `06-ghostty-config.sh` — writes `~/.config/ghostty/config` if missing

Each script is idempotent: safe to re-run. Existing files (Ghostty config,
managed block in `.zshrc`) are left alone on re-runs.

## Removing the shell changes

`05-shell-config.sh` adds one marker-delimited block to `~/.zshrc`:

```
# === mac-setup: managed block (do not edit between markers) ===
...
# === mac-setup: end ===
```

Delete everything between (and including) those markers to remove the nvm
sourcing and eza aliases. Plugins are enabled by editing the `plugins=(...)`
line — remove `zsh-autosuggestions` and `zsh-syntax-highlighting` from it
to disable them.

## CI

`.github/workflows/install-mac.yml` runs the full install on `macos-latest`
for any change under `mac/` and on manual dispatch. `lint.yml` runs
shellcheck on every push and PR.
