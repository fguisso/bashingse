# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Antidote
# Why: zsh-autosuggestions re-binds ZLE widgets on every prompt (~5ms) because
# fast-syntax-highlighting wraps them. MANUAL_REBIND disables that loop.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load ~/.config/shell/plugins.txt

# Powerlevel10k
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# 1Password SSH Agent
# Why: SSH_CONNECTION vazio significa sessão local, então o agente do 1Password
# manda. Numa sessão remota o sshd já entregou um agente encaminhado e
# sobrescrever mataria a chave. Testar -z SSH_AUTH_SOCK não serve: no macOS o
# launchd sempre pré-popula a variável com o agente do sistema.
_op_sock="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
[[ -z $SSH_CONNECTION && -S $_op_sock ]] && export SSH_AUTH_SOCK="$_op_sock"
unset _op_sock
