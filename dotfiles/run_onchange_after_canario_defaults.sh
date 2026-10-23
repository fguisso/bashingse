#!/usr/bin/env bash
# Preferências do Canario. Ele não lê o config.toml do Rio: guarda tudo em
# UserDefaults (com.raphaelamorim.canario). Roda quando este arquivo muda.
set -euo pipefail

[[ "$(uname -s)" == "Darwin" ]] || exit 0

d=com.raphaelamorim.canario

defaults write "$d" fontFamily  -string "0xProto Nerd Font Mono"
defaults write "$d" fontSize    -int    14
defaults write "$d" cursorBlink -bool   true
defaults write "$d" chromeColor -string "#E2B8AB"
