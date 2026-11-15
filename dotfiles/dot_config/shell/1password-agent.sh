# Binarios instalados no perfil minimo, sem repetir entradas no PATH.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
# Agente 1Password para sessoes locais. Preserva agentes SSH encaminhados.
if [ -z "${SSH_CONNECTION:-}" ] && [ -S "$HOME/.1password/agent.sock" ]; then
    export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
fi
