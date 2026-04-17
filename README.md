# bashingse

Monorepo com scripts de bootstrap, utilitários de terminal e dotfiles (chezmoi).

- `bootstrap/` e `tools/` são publicados em GitHub Pages em `b.guisso.dev`.
- `dotfiles/` é a fonte do [chezmoi](https://www.chezmoi.io/) (apontado por `.chezmoiroot`).

## Bootstrap

### macOS

```sh
curl -fsSL https://b.guisso.dev/init-mac.sh | bash
```

Script single-stage que:
1. Instala Xcode Command Line Tools (re-run uma vez se precisar).
2. Instala Homebrew.
3. Instala `git` + `chezmoi`.
4. Instala Claude Code (native installer da Anthropic).
5. Aplica o chezmoi deste repo (via HTTPS — sem depender de 1Password SSH).
6. Roda `brew bundle` com o Brewfile completo.
7. Imprime passos opcionais de pós-install (1Password SSH agent, login do Claude Code, Apple ID).

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
