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

### Matrix screensaver

**macOS / Linux:**
```sh
curl -fsSL https://b.guisso.dev/matrix.sh | bash
```

With options (spacing=50, auto-exit after 30s):
```sh
curl -fsSL https://b.guisso.dev/matrix.sh | bash -s -- 50 30
```

**Windows (PowerShell 7+):**
```powershell
irm https://b.guisso.dev/matrix.ps1 | iex
```

With options via env vars:
```powershell
$env:MATRIX_SPACING=50; $env:MATRIX_TIMEOUT=30; irm https://b.guisso.dev/matrix.ps1 | iex
```

- Press any key or `Ctrl+C` to exit — terminal content is fully restored
- `MATRIX_SPACING` — density (1–200, lower = denser, default 80)
- `MATRIX_TIMEOUT` — auto-exit after N seconds (0 = forever)

## How it works

```
push to main
    └── GitHub Actions
            └── copies all *.sh → site/
                    └── deploys to GitHub Pages (b.guisso.dev)
```
