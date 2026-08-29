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

- **CLI**: `git`, `gh`, `chezmoi`, `mise`, `neovim`, `ripgrep`, `uv`, `hugo`, `gnupg`, `infisical`, `semgrep`, `pulumi`, `ffmpeg`, `colima`, `docker` (+ `buildx`/`compose`), `claude`.
- **Runtimes via mise** (`~/.config/mise/config.toml`): `bun`, `node` (lts), `go`, `rust`, `gcloud` — resolvidos por shims em `~/.local/share/mise/shims`.
- **GUI apps** (casks): 1Password (+ CLI), Rio, Canário, Firefox, Chrome, VS Code, Discord, Slack, Telegram, WhatsApp, Signal, WiFiman, ChatGPT.
- **Shell**: zsh com antidote + powerlevel10k, configs em `~/.config/shell/{common,darwin}.zsh`.
- **Editor**: Neovim com [fguisso/lazyvim-config](https://github.com/fguisso/lazyvim-config) clonado em `~/.config/nvim` (via `.chezmoiexternal.toml`).
- **Defaults do macOS** reaplicados a cada `chezmoi apply` (`run_after_macos_defaults.sh`).

#### Gerenciando novas adições

Tudo vive no monorepo — edite a fonte e re-aplique.

- **Novo app/CLI via brew** → editar `dotfiles/Brewfile` (`brew "..."` ou `cask "..."`) → `brew bundle --file "$(chezmoi source-path)/Brewfile"` (ou rodar o init de novo).
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
├── run_once_install-linux-shell-deps.sh — antidote + p10k + mise no Linux
└── .chezmoiexternal.toml              — puxa fguisso/lazyvim-config em ~/.config/nvim
```

### Como funciona

**chezmoi copia arquivos — não faz symlink.** Não existe symlink nenhum apontando pro
repo: `chezmoi apply` materializa cópias no `$HOME`. Consequência prática: editar
`~/.zshrc` direto vira *drift*, e o próximo `apply` sobrescreve. O caminho certo é
editar `dotfiles/` e aplicar, ou editar o arquivo real e `chezmoi re-add <path>`.

**`.chezmoiroot` é o que permite o monorepo.** O arquivo na raiz contém `dotfiles`, e
é isso que faz o chezmoi tratar `<repo>/dotfiles` como source dir, ignorando
`bootstrap/`, `tools/` e o README.

**Convenções de nome no source state:**

| Prefixo | Efeito |
|---|---|
| `dot_foo` | vira `~/.foo` |
| `private_dot_ssh/` | vira `~/.ssh/` com permissão `0600` |
| `run_once_*.sh` | executa uma única vez, na primeira aplicação |
| `run_after_*.sh` | executa a **cada** `chezmoi apply`, no fim |
| `.chezmoiignore` | fica no source mas nunca vai pro `$HOME` (é o caso do Brewfile) |
| `.chezmoiremove` | apaga o caminho listado do `$HOME` |
| `.chezmoiexternal.toml` | clona repos externos direto no destino |

### Aplicar manualmente

```sh
chezmoi init --apply https://github.com/fguisso/bashingse.git
```

### Atualizar

```sh
chezmoi update    # git pull no source + apply
chezmoi diff      # prévia do que mudaria
chezmoi status    # o que está divergente
```

### Trabalhar direto no clone

Numa máquina de desenvolvimento é prático apontar o chezmoi pro seu clone de
trabalho em vez do clone interno dele (`~/.local/share/chezmoi`), pra que editar o
repo já seja editar o source state:

```sh
# ~/.config/chezmoi/chezmoi.toml
sourceDir = "/Users/<voce>/bashingse"
```

### Avisos

- **`run_after_macos_defaults.sh` roda a cada `chezmoi apply`** e faz
  `defaults delete com.apple.dock persistent-apps` — ou seja, **zera os apps fixados
  no Dock** toda vez. Também reinicia Finder, Dock e SystemUIServer.
- **`commit.gpgsign = true` é incondicional.** Até o 1Password estar aberto e com o
  SSH agent ligado, **todo `git commit` falha**. No Debian LXC não há 1Password:
  a assinatura depende de entrar com agent forwarding (`ssh -A` / mosh), e por isso
  os arquivos de shell só definem `SSH_AUTH_SOCK` quando ele ainda está vazio.
- **Push é sempre SSH.** O `pushInsteadOf` no gitconfig reescreve remotes HTTPS do
  GitHub para `git@github.com:` no push. Clone por HTTPS continua valendo — o
  bootstrap depende disso, já que roda antes do 1Password existir.
- **mise usa shims, não `mise activate`.** Os shims resolvem binários, mas **não**
  injetam variáveis: a seção `[env]` de um `mise.toml` por diretório deixa de
  funcionar. Depois de instalar runtime novo, rode `mise reshim`.
- **Apple Silicon apenas.** `/opt/homebrew` está hardcoded em `darwin.zsh`,
  `dot_p10k.zsh` e `init-mac.sh`. Num Mac Intel (`/usr/local`) o shell quebra calado.
- **`init-debian-lxc.sh` exige root** — roda `apt-get` e `chsh` sem `sudo`. Debian é
  o único alvo testado.
- **`~/.zprofile` não é gerenciado pelo chezmoi**: o `init-mac.sh` faz append
  idempotente do `brew shellenv` nele. É o único arquivo do `$HOME` escrito fora do
  chezmoi.
- **`$HOME/codeql` entra no PATH** via `common.zsh`, mas nada neste repo instala o
  CodeQL — é um diretório que você popula à mão quando precisa.

## Deploy

```
push to main
    └── GitHub Actions
            └── copia bootstrap/*.sh + tools/*.{sh,ps1} para site/ (flattened)
                    └── deploy em GitHub Pages (b.guisso.dev)
```
