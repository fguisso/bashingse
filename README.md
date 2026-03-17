# bashingse

Init scripts published via GitHub Pages at `b.guisso.dev`.

Every `.sh` file in this repo is automatically deployed on push to `main`.

## Scripts

### macOS

```sh
curl -fsSL https://b.guisso.dev/init-mac.sh | bash
```

Bootstraps a fresh Mac:
1. Installs Xcode Command Line Tools
2. Installs Homebrew, `git`, `chezmoi`, `1password-cli`, and the 1Password app
3. Pauses for manual 1Password setup (SSH Agent + CLI integration)
4. Applies dotfiles via `chezmoi init --apply`

### Debian LXC

```sh
curl -fsSL https://b.guisso.dev/init-debian-lxc.sh | bash
```

Bootstraps a Debian LXC container accessed via SSH:
1. Installs `git` and `mosh` via apt
2. Installs `chezmoi` via the official installer
3. Verifies SSH agent forwarding is active (`ssh -A`)
4. Applies dotfiles via `chezmoi init --apply`

> Requires connecting with agent forwarding: `ssh -A user@host`

## How it works

```
push to main
    └── GitHub Actions
            └── copies all *.sh → site/
                    └── deploys to GitHub Pages (b.guisso.dev)
```
