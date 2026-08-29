# Antidote
source ~/.antidote/antidote.zsh
antidote load ~/.config/shell/plugins.txt

# Powerlevel10k
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme

# 1Password SSH Agent (desktop Linux)
# Why: SSH_CONNECTION vazio significa sessão local, então o agente do
# 1Password manda. Numa sessão remota o sshd já entregou um agente
# encaminhado e sobrescrever mataria a chave. Testar -z SSH_AUTH_SOCK não
# serve: no macOS o launchd sempre pré-popula a variável com o agente do
# sistema, e o guard nunca dispararia.
_op_sock="$HOME/.1password/agent.sock"
[[ -z $SSH_CONNECTION && -S $_op_sock ]] && export SSH_AUTH_SOCK="$_op_sock"
unset _op_sock
