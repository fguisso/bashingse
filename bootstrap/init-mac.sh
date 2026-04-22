#!/usr/bin/env bash
set -euo pipefail

# Reattach stdin to the controlling TTY so sudo, xcode-select, and other
# interactive prompts work when this script is piped via `curl | bash`.
[[ -r /dev/tty ]] && exec < /dev/tty

# =========================
# Config
# =========================
CHEZMOI_REPO="https://github.com/fguisso/bashingse.git"
XCODE_CLT_WAIT_SECS=1800   # max 30 min waiting on GUI installer

BREW_BIN="/opt/homebrew/bin/brew"
CHEZMOI_BIN="/opt/homebrew/bin/chezmoi"
CLAUDE_BIN="${HOME}/.local/bin/claude"

# =========================
# Helpers
# =========================
log()  { printf "\n\033[1m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[33mWARN:\033[0m %s\n" "$*"; }
die()  { printf "\n\033[31mERROR:\033[0m %s\n" "$*"; exit 1; }

has_brew()    { [[ -x "$BREW_BIN" ]]; }
has_chezmoi() { [[ -x "$CHEZMOI_BIN" ]]; }
has_claude()  { [[ -x "$CLAUDE_BIN" ]]; }
has_xcode()   { xcode-select -p >/dev/null 2>&1; }

brew_shellenv() { eval "$("$BREW_BIN" shellenv)"; }

# =========================
# Bootstrap steps
# =========================
ensure_xcode_clt() {
  if has_xcode; then
    log "Xcode Command Line Tools already installed."
    return
  fi

  log "Installing Xcode Command Line Tools (GUI dialog will open)..."
  xcode-select --install || true

  log "Waiting for Xcode CLT install to finish (click Install in the dialog)..."
  local waited=0
  until has_xcode; do
    if (( waited >= XCODE_CLT_WAIT_SECS )); then
      die "Xcode CLT not installed after ${XCODE_CLT_WAIT_SECS}s. Finish the installer and re-run."
    fi
    sleep 10
    waited=$((waited + 10))
  done
  log "Xcode CLT installed."
}

install_brew() {
  log "Installing Homebrew (sudo may prompt for password)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  has_brew || die "Homebrew not found after install."
  brew_shellenv

  grep -q 'brew shellenv' "${HOME}/.zprofile" 2>/dev/null ||
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"${HOME}/.zprofile"
}

install_bootstrap_tools() {
  log "Installing bootstrap tools (git, chezmoi)..."
  "$BREW_BIN" update
  "$BREW_BIN" install git chezmoi
}

install_claude_code() {
  if has_claude; then
    log "Claude Code already installed."
    return
  fi
  log "Installing Claude Code (native installer)..."
  curl -fsSL https://claude.ai/install.sh | bash
  has_claude || warn "Claude Code not found at $CLAUDE_BIN after install."
}

apply_chezmoi() {
  has_chezmoi || die "chezmoi not found."
  log "Applying chezmoi from: $CHEZMOI_REPO"
  "$CHEZMOI_BIN" init --apply "$CHEZMOI_REPO"
}

brew_bundle() {
  local brewfile="${HOME}/.local/share/chezmoi/dotfiles/Brewfile"
  if [[ ! -f "$brewfile" ]]; then
    warn "Brewfile not found at $brewfile — skipping bundle."
    return
  fi
  log "Installing Brewfile apps (this may take a while)..."
  # Do not let one failing cask kill the whole init; report at the end.
  if ! "$BREW_BIN" bundle --file "$brewfile"; then
    warn "brew bundle reported errors — check output above. Re-run 'brew bundle' later if needed."
  fi
}

print_post_install() {
  cat <<'EOF'

╔════════════════════════════════════════════════════════╗
║  ✓ init-mac.sh complete                                ║
╚════════════════════════════════════════════════════════╝

Optional next steps:

1) 1Password SSH agent (for commits over SSH):
   - Open 1Password.app and sign in
   - Settings → Developer → SSH Agent
   - Settings → Developer → Integrate with 1Password CLI

2) Claude Code login:
   - Run: claude

3) Apple ID:
   - System Settings → Apple ID

4) Open a new terminal so the new shell config takes effect.

EOF
}

# =========================
# Main
# =========================
ensure_xcode_clt

if ! has_brew; then
  install_brew
else
  brew_shellenv
fi

install_bootstrap_tools
install_claude_code
apply_chezmoi
brew_bundle
print_post_install
