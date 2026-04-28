# bashingse

Monorepo com scripts de bootstrap, utilitários de terminal e dotfiles (chezmoi).

- `bootstrap/` e `tools/` são publicados em GitHub Pages em `b.guisso.dev`.
- `dotfiles/` é a fonte do [chezmoi](https://www.chezmoi.io/) (apontado por `.chezmoiroot`).

## Bootstrap

### macOS

```sh
curl -fsSL https://b.guisso.dev/init-mac.sh | bash
```

Pré-requisitos: Mac com macOS recente, conexão com a internet, senha de admin (Homebrew pede `sudo`). O script reata `stdin` ao TTY, então o GUI do Xcode CLT e o prompt de senha funcionam mesmo via `curl | bash`.

Script single-stage que:
1. Instala Xcode Command Line Tools (espera o instalador GUI; falha após 30 min).
2. Instala Homebrew e adiciona `brew shellenv` ao `~/.zprofile`.
3. Instala `git` + `chezmoi`.
4. Instala Claude Code (native installer da Anthropic) em `~/.local/bin/claude`.
5. Aplica o chezmoi deste repo via HTTPS (sem depender de 1Password SSH).
6. Roda `brew bundle` com o `dotfiles/Brewfile`.
7. Imprime passos opcionais de pós-install (1Password SSH agent, login do Claude Code, Apple ID).

Re-rodar é seguro: cada passo é idempotente (checa se já tem antes de instalar).

#### O que fica disponível depois

- **CLI**: `git`, `gh`, `chezmoi`, `mise`, `neovim`, `ripgrep`, `uv`, `hugo`, `gnupg`, `infisical`, `semgrep`, `ffmpeg`, `colima`, `docker` (+ `buildx`/`compose`), `claude`.
- **Runtimes via mise** (`~/.config/mise/config.toml`): `bun`, `node` (lts), `go`, `rust`, `gcloud` — instalam no primeiro shell ou via `mise install`.
- **GUI apps** (casks): 1Password (+ CLI), Rio, Firefox, Chrome, VS Code, Discord, Slack, Telegram, WhatsApp, Zoom, Logseq, WiFiman, Syncthing, Codex.
- **Shell**: zsh com antidote + powerlevel10k, configs em `~/.config/shell/{common,darwin}.zsh`.
- **Editor**: Neovim com [fguisso/lazyvim-config](https://github.com/fguisso/lazyvim-config) clonado em `~/.config/nvim` (via `.chezmoiexternal.toml`).
- **Defaults do macOS** reaplicados a cada `chezmoi apply` (`run_after_macos_defaults.sh`).

#### Gerenciando novas adições

Tudo vive no monorepo — edite a fonte e re-aplique.

- **Novo app/CLI via brew** → editar `dotfiles/Brewfile` (`brew "..."` ou `cask "..."`) → `brew bundle --file ~/.local/share/chezmoi/dotfiles/Brewfile` (ou rodar o init de novo).
- **Novo runtime via mise** → editar `dotfiles/dot_config/mise/config.toml` → `chezmoi apply` → `mise install`.
- **Mudança em dotfile já gerenciado** → editar direto em `dotfiles/` e `chezmoi apply`, ou editar o arquivo real e `chezmoi re-add <path>`.
- **Novo dotfile** → `chezmoi add ~/.config/foo` traz pra dentro do source state; commitar em `dotfiles/`.
- **Plugin de shell** → `dotfiles/dot_config/shell/plugins.txt` (antidote).
- **Sync com upstream** numa máquina já provisionada → `chezmoi update` (faz `git pull` no source + `apply`).
- **Ver o que vai mudar antes de aplicar** → `chezmoi diff`.

### Debian LXC

```sh
curl -fsSL https://b.guisso.dev/init-debian-lxc.sh | bash
```

1. Instala `git`, `mosh`, `zsh`, `locales` via apt.
2. Ajusta locale pra `en_US.UTF-8`.
3. Instala `chezmoi` via installer oficial.
4. Aplica o chezmoi deste repo via HTTPS.
5. Define `zsh` como shell padrão.

## Tools

### Matrix screensaver

```sh
curl -fsSL https://b.guisso.dev/matrix.sh | bash
```

Com opções (densidade=50, timeout=30s):
```sh
curl -fsSL https://b.guisso.dev/matrix.sh | bash -s -- 50 30
```

Windows (PowerShell 7+):
```powershell
irm https://b.guisso.dev/matrix.ps1 | iex
```

Variáveis: `MATRIX_DENSITY`, `MATRIX_TIMEOUT`. Qualquer tecla ou `Ctrl+C` sai.

## Dotfiles (chezmoi)

Gerenciados em `dotfiles/`. Estrutura:

```
dotfiles/
├── Brewfile                           — brew bundle completo
├── dot_gitconfig                      — git config
├── dot_p10k.zsh                       — powerlevel10k theme
├── dot_zshrc                          — loader (sem template)
├── dot_config/
│   ├── mise/config.toml               — runtimes via mise
│   ├── rio/config.toml                — terminal
│   └── shell/
│       ├── common.zsh                 — cross-OS (EDITOR, PATH, mise)
│       ├── darwin.zsh                 — macOS (brew, antidote, 1Password SSH)
│       ├── linux.zsh                  — Linux (antidote, p10k paths)
│       └── plugins.txt                — antidote plugin list
├── private_dot_ssh/allowed_signers    — SSH allowed signers pra gpg ssh
├── run_after_macos_defaults.sh        — reaplica defaults do macOS a cada apply
├── run_once_install-linux-shell-deps.sh.tmpl — antidote + p10k + mise no Linux
└── .chezmoiexternal.toml              — puxa fguisso/lazyvim-config em ~/.config/nvim
```

### Aplicar manualmente

```sh
chezmoi init --apply https://github.com/fguisso/bashingse.git
```

### Atualizar

```sh
chezmoi update
```

## Deploy

```
push to main
    └── GitHub Actions
            └── copia bootstrap/*.sh + tools/*.{sh,ps1} para site/ (flattened)
                    └── deploy em GitHub Pages (b.guisso.dev)
```
