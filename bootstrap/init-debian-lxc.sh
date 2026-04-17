#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
CHEZMOI_REPO="https://github.com/fguisso/bashingse.git"

CHEZMOI_BIN="/usr/local/bin/chezmoi"

# =========================
# Helpers
# =========================
log()  { printf "\n\033[1m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[33mWARN:\033[0m %s\n" "$*"; }
die()  { printf "\n\033[31mERROR:\033[0m %s\n" "$*"; exit 1; }

has_cmd()     { command -v "$1" >/dev/null 2>&1; }
has_chezmoi() { [[ -x "$CHEZMOI_BIN" ]]; }

# =========================
# Bootstrap steps
# =========================
install_core_packages() {
  log "Updating apt and installing core packages..."
  apt-get update -qq
  apt-get install -y --no-install-recommends \
    git \
    mosh \
    zsh \
    locales
}

fix_locale() {
  log "Configuring locale..."
  sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  export LANG=en_US.UTF-8
  export LC_ALL=en_US.UTF-8
}

set_default_shell_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [[ -z "$zsh_path" ]]; then
    warn "zsh not found, skipping shell change."
    return
  fi
  grep -qF "$zsh_path" /etc/shells || echo "$zsh_path" >> /etc/shells
  log "Setting default shell to zsh for $(whoami)..."
  chsh -s "$zsh_path"
}

install_chezmoi() {
  log "Installing chezmoi to ${CHEZMOI_BIN}..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
  has_chezmoi || die "chezmoi not found after install."
}

apply_chezmoi() {
  log "Applying chezmoi from: ${CHEZMOI_REPO}"
  "$CHEZMOI_BIN" init --apply "$CHEZMOI_REPO"
}

# =========================
# Main
# =========================
install_core_packages
fix_locale

if ! has_chezmoi; then
  install_chezmoi
fi

apply_chezmoi
set_default_shell_zsh

log "Done."
