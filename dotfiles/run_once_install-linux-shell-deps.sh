#!/usr/bin/env bash
[[ "$(uname -s)" == "Linux" ]] || exit 0
set -euo pipefail

# Antidote
if [[ ! -d ~/.antidote ]]; then
  git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote
fi

# Powerlevel10k
mkdir -p ~/.local/share
if [[ ! -d ~/.local/share/powerlevel10k ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.local/share/powerlevel10k
fi

# mise
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$PATH"
mise install
