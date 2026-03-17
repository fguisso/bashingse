#!/usr/bin/env bash
set -euo pipefail

# =========================
# Config
# =========================
CHEZMOI_REPO_SSH="git@github.com:fguisso/dotfiles.git"

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
    mosh
}

install_chezmoi() {
  log "Installing chezmoi to ${CHEZMOI_BIN}..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
  has_chezmoi || die "chezmoi not found after install."
}

check_ssh_agent() {
  if [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    die "SSH_AUTH_SOCK not set. Connect with agent forwarding (ssh -A) and try again."
  fi

  if ! ssh-add -l >/dev/null 2>&1; then
    die "SSH agent has no loaded keys. Make sure your key is added on the host (ssh-add) and connect with -A."
  fi

  log "SSH agent ready."
}

apply_chezmoi() {
  log "Applying chezmoi: ${CHEZMOI_REPO_SSH}"
  "$CHEZMOI_BIN" init --apply "$CHEZMOI_REPO_SSH"
}

# =========================
# Main
# =========================
install_core_packages

if ! has_chezmoi; then
  install_chezmoi
fi

check_ssh_agent
apply_chezmoi

log "Done."
