# Antidote
source ~/.antidote/antidote.zsh
antidote load ~/.config/shell/plugins.txt

# Powerlevel10k
source ~/.local/share/powerlevel10k/powerlevel10k.zsh-theme

# 1Password SSH Agent (desktop Linux)
# Why: o guard é obrigatório aqui — no LXC entramos por ssh/mosh com agent
# forwarding, e sobrescrever SSH_AUTH_SOCK mataria a chave encaminhada.
_op_sock="$HOME/.1password/agent.sock"
[[ -z $SSH_AUTH_SOCK && -S $_op_sock ]] && export SSH_AUTH_SOCK="$_op_sock"
unset _op_sock
