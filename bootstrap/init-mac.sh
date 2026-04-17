#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
CHEZMOI_REPO="https://github.com/fguisso/bashingse.git"

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

brew_shellenv() { eval "$("$BREW_BIN" shellenv)"; }

# =========================
# Bootstrap steps
# =========================
ensure_xcode_clt_or_exit() {
  if xcode-select -p >/dev/null 2>&1; then
    log "Xcode Command Line Tools already installed."
    return
  fi

  log "Installing Xcode Command Line Tools..."
  xcode-select --install || true

  warn "Finish the Xcode CLT installer, then re-run:"
  warn "  curl -fsSL https://b.guisso.dev/init-mac.sh | bash"
  exit 0
}

install_brew() {
  log "Installing Homebrew..."
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
  "$BREW_BIN" bundle --file "$brewfile"
}

print_post_install() {
  cat <<'EOF'

────────────────────────────────────────────────────────
Done. Optional post-install steps
────────────────────────────────────────────────────────

1) 1Password SSH agent (for commits over SSH):
   - Open 1Password.app and sign in
   - Settings → Developer → SSH Agent
   - Settings → Developer → Integrate with 1Password CLI

2) Claude Code login:
   - Run: claude

3) Apple ID:
   - System Settings → Apple ID

EOF
}

# =========================
# Main
# =========================
ensure_xcode_clt_or_exit

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
