#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
CHEZMOI_REPO_SSH="git@github.com:fguisso/dotfiles.git"

STATE_DIR="${HOME}/.local/state/guisso-init"
MARK_BOOTSTRAP_DONE="${STATE_DIR}/bootstrap_done"

BREW_BIN="/opt/homebrew/bin/brew"
OP_BIN="/opt/homebrew/bin/op"
CHEZMOI_BIN="/opt/homebrew/bin/chezmoi"

# =========================
# Helpers
# =========================
log() { printf "\n\033[1m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[33mWARN:\033[0m %s\n" "$*"; }
die() {
  printf "\n\033[31mERROR:\033[0m %s\n" "$*"
  exit 1
}

ensure_dir() { mkdir -p "$STATE_DIR"; }

is_apple_silicon() { [[ "$(uname -m)" == "arm64" ]]; }
has_brew() { [[ -x "$BREW_BIN" ]]; }
has_op() { [[ -x "$OP_BIN" ]]; }
has_chezmoi() { [[ -x "$CHEZMOI_BIN" ]]; }

brew_shellenv() { eval "$("$BREW_BIN" shellenv)"; }

# =========================
# macOS Defaults (safe subset)
# =========================
apply_macos_defaults() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  log "Applying macOS defaults (safe subset)"

  osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true
  osascript -e 'tell application "System Preferences" to quit' >/dev/null 2>&1 || true

  sudo -v
  (while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" >/dev/null 2>&1 || exit
  done) 2>/dev/null &

  # Panels
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

  # Coding-friendly text
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Finder
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

  # Dock
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock show-recents -bool false
  defaults delete com.apple.dock persistent-apps 2>/dev/null || true
  defaults delete com.apple.dock persistent-others 2>/dev/null || true

  # Screenshots
  mkdir -p "${HOME}/Screenshots"
  defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

  killall Finder Dock SystemUIServer >/dev/null 2>&1 || true
}

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

  warn "Finish the installer, then re-run:"
  warn "  curl -fsSL https://init.guisso.dev | bash"
  exit 0
}

install_brew_or_die() {
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  has_brew || die "Homebrew not found."
  brew_shellenv

  grep -q 'brew shellenv' "${HOME}/.zprofile" 2>/dev/null ||
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>"${HOME}/.zprofile"
}

brew_install_core() {
  log "Installing core tools + apps..."
  "$BREW_BIN" update
  "$BREW_BIN" install git chezmoi 1password-cli

  "$BREW_BIN" install --cask \
    1password \
    rio

  touch "$MARK_BOOTSTRAP_DONE"
}

print_manual_steps_and_exit() {
  cat <<'EOF'

────────────────────────────────────────────────────────
MANUAL STEP REQUIRED
────────────────────────────────────────────────────────

1) Open 1Password.app and sign in
2) Enable:
   - Settings → Developer → SSH Agent
   - Settings → Developer → Integrate with 1Password CLI

(Optional) Sign into Apple ID:
  System Settings → Apple ID

Then run again:

  curl -fsSL https://init.guisso.dev | bash

EOF
}

op_is_ready() {
  has_op || return 1
  "$OP_BIN" whoami >/dev/null 2>&1
}

apply_chezmoi_or_die() {
  has_chezmoi || die "chezmoi not found."
  log "Applying chezmoi: ${CHEZMOI_REPO_SSH}"
  "$CHEZMOI_BIN" init --apply "$CHEZMOI_REPO_SSH"
}

# =========================
# Main
# =========================
ensure_dir
apply_macos_defaults

# Stage 1
if ! has_brew; then
  log "Fresh Mac detected. Bootstrapping..."
  ensure_xcode_clt_or_exit
  install_brew_or_die
  brew_install_core
  print_manual_steps_and_exit
  exit 0
fi

# Stage 2
brew_shellenv

if ! has_op || ! has_chezmoi; then
  brew_install_core
fi

if ! op_is_ready; then
  print_manual_steps_and_exit
  exit 0
fi

log "1Password CLI authenticated. Applying dotfiles."
apply_chezmoi_or_die

log "Done. Stage 1 + 2 complete."
