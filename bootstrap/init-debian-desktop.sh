#!/usr/bin/env bash
# Debian 13/Trixie ou Forky, amd64/arm64, usuario normal com sudo e desktop.
# Dependencias iniciais: bash, sudo, apt-get, dpkg e ferramentas basicas Debian.
# Efeitos: instala pacotes/apps, chezmoi minimo e integra o agente ao Bash.
# Nao altera shell padrao, kernel, particoes ou politicas de boot.
# Fontes, efeitos e recuperacao: docs/debian-desktop.md deste repositorio.
set -euo pipefail

usage() {
  printf 'Uso: bash %s [--with-chatgpt] [--skip-apps]\n' "$0"
  printf 'Padrao: base, chezmoi minimo, 1Password nativo e Codex CLI.\n'
}
with_chatgpt=0
skip_apps=0
for arg in "$@"; do
  case "$arg" in
    --with-chatgpt) with_chatgpt=1 ;;
    --skip-apps) skip_apps=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
die() { printf '\nERRO: %s\n' "$*" >&2; exit 1; }
log() { printf '\n==> %s\n' "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

[[ "$(uname -s)" == Linux ]] || die 'Execute no Debian Linux, nao no macOS.'
[[ -r /etc/os-release ]] || die 'Distribuicao nao identificada.'
. /etc/os-release
[[ "${ID:-}" == debian ]] || die 'Este bootstrap aceita somente Debian.'
case "${VERSION_CODENAME:-}" in
  trixie|forky) ;;
  *) die 'Use Debian Trixie ou Forky; confira /etc/os-release.' ;;
esac
[[ "$(id -u)" != 0 ]] || die 'Execute como seu usuario do desktop, sem sudo antes do bash.'
has sudo || die 'Configure acesso sudo para sua conta antes de continuar.'
arch=$(dpkg --print-architecture)
case "$arch" in
  arm64) vendor_arch=aarch64 ;;
  amd64) vendor_arch=x86_64 ;;
  *) die "Arquitetura nao suportada: $arch" ;;
esac

# Mantem prompts de sudo funcionais mesmo quando o script vier por um pipe.
if [[ -r /dev/tty ]]; then exec < /dev/tty; fi
umask 077
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi"
config="$config_dir/chezmoi.toml"
profile=debian-desktop-minimo
repo=https://github.com/fguisso/bashingse.git
ref="${BASHINGSE_REF:-main}"
marker='# Perfil gerenciado por init-debian-desktop.sh do bashingse.'
for other in "$config_dir/chezmoi.json" "$config_dir/chezmoi.yaml" "$config_dir/chezmoi.yml"; do
  [[ ! -e "$other" ]] || die "Ja existe $other; integrar o perfil manualmente, sem sobrescrever."
done
if [[ -e "$config" ]]; then
  grep -Fxq "$marker" "$config" || die "Ja existe $config; integrar o perfil manualmente, sem sobrescrever."
  grep -Fxq 'profile = "debian-desktop-minimo"' "$config" || die 'O perfil existente foi modificado; revisar antes de reaplicar.'
fi

state_root="${XDG_STATE_HOME:-$HOME/.local/state}/bashingse/debian-desktop"
mkdir -p "$state_root" "$HOME/.local/bin"
state=$(mktemp -d "$state_root/$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
export PATH="$HOME/.local/bin:$PATH"
trap 'printf "\nBootstrap interrompido. Artefatos e backups: %s\n" "$state" >&2' ERR
printf 'Debian: %s; arquitetura: %s; perfil: %s\n' "$VERSION_CODENAME" "$arch" "$profile"
printf 'Artefatos privados: %s\n' "$state"

download() {
  curl --proto '=https' --tlsv1.2 -fLsS --retry 3 --connect-timeout 15 "$1" -o "$2"
  sha256sum "$2" >> "$state/SHA256SUMS"
}

log 'Instalando ferramentas basicas, sem upgrade geral ou remocao de pacotes'
sudo -v
sudo apt-get update
sudo apt-get install -y --no-install-recommends --no-remove git curl ca-certificates gnupg openssh-client python3

if ! has chezmoi; then
  log 'Instalando chezmoi em ~/.local/bin pelo instalador oficial'
  download https://get.chezmoi.io "$state/chezmoi-install.sh"
  sh "$state/chezmoi-install.sh" -b "$HOME/.local/bin"
fi

install_1password() {
  if has 1password; then log '1Password ja disponivel; instalacao existente preservada'; return; fi
  [[ ! -e /opt/1Password ]] || die '/opt/1Password ja existe sem comando 1password; revisar a instalacao parcial.'
  log "Instalando 1Password nativo para $arch, com assinatura verificada"
  sudo apt-get install -y --no-install-recommends --no-remove libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libcurl4t64 libdrm2 libgbm1 libgtk-3-0t64 libnotify4 libnss3 libxcb-shape0 libxcb-xfixes0 libxshmfence1 libudev1 xdg-utils
  local base="$state/1password"
  mkdir -p "$base/gnupg" "$base/unpack"
  download https://downloads.1password.com/linux/keys/1password.asc "$base/key.asc"
  local fingerprint
  fingerprint=$(gpg --homedir "$base/gnupg" --batch --with-colons --show-keys "$base/key.asc" | awk -F: '$1 == "fpr" {print $10; exit}')
  [[ "$fingerprint" == 3FEF9748469ADBE15DA7CA80AC2D62742012EA22 ]] || die 'Fingerprint 1Password diferente do publicado; revisar a chave.'
  gpg --homedir "$base/gnupg" --batch --import "$base/key.asc"
  local url="https://downloads.1password.com/linux/tar/stable/$vendor_arch/1password-latest.tar.gz"
  download "$url" "$base/1password.tar.gz"
  download "$url.sig" "$base/1password.tar.gz.sig"
  gpg --homedir "$base/gnupg" --batch --verify "$base/1password.tar.gz.sig" "$base/1password.tar.gz"
  local extracted
  extracted=$(python3 - "$base/1password.tar.gz" "$base/unpack" <<'PY'
from pathlib import Path
import sys, tarfile
target = Path(sys.argv[2]).resolve()
with tarfile.open(sys.argv[1]) as archive:
    members = archive.getmembers()
    roots = {Path(m.name).parts[0] for m in members if Path(m.name).parts}
    if len(roots) != 1 or any(Path(m.name).is_absolute() or '..' in Path(m.name).parts for m in members):
        raise SystemExit('Layout inesperado no arquivo 1Password')
    archive.extractall(target, filter='data')
root = target / next(iter(roots))
if not (root / 'after-install.sh').is_file():
    raise SystemExit('after-install.sh ausente')
print(root)
PY
)
  printf '1Password extraido: %s\n' "${extracted##*/}" >> "$state/versions.txt"
  sudo install -d -m 0755 /opt/1Password
  sudo cp -R "$extracted/." /opt/1Password/
  sudo chown -R root:root /opt/1Password
  sudo /opt/1Password/after-install.sh
}

install_codex() {
  if has codex; then log 'Codex CLI ja disponivel; versao existente preservada'; return; fi
  log 'Instalando Codex CLI nativo pelo instalador oficial'
  download https://chatgpt.com/codex/install.sh "$state/codex-install.sh"
  CODEX_NON_INTERACTIVE=true sh "$state/codex-install.sh"
  has codex || die 'Codex nao foi encontrado depois da instalacao.'
}

install_chatgpt() {
  if dpkg-query -W -f='${Status}' chatgpt 2>/dev/null | grep -q 'install ok installed'; then
    log 'ChatGPT ja instalado; pacote existente preservado'; return
  fi
  log 'Baixando ChatGPT Desktop oficial em preview e conferindo pacote'
  local package="$state/chatgpt_${arch}.deb"
  download "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_${arch}.deb" "$package"
  [[ "$(dpkg-deb -f "$package" Architecture)" == "$arch" ]] || die 'Arquitetura inesperada no pacote ChatGPT.'
  [[ "$(dpkg-deb -f "$package" Package)" == chatgpt ]] || die 'Nome inesperado no pacote ChatGPT.'
  dpkg-deb --info "$package" > "$state/chatgpt-package.txt"
  dpkg-deb --control "$package" "$state/chatgpt-control"
  apt-get --simulate --no-remove install "$package" > "$state/chatgpt-apt-simulation.txt"
  sudo apt-get install -y --no-remove "$package"
}

if [[ "$skip_apps" == 0 ]]; then
  install_1password
  install_codex
  if [[ "$with_chatgpt" == 1 ]]; then install_chatgpt; fi
fi

log 'Inicializando chezmoi com o perfil desktop minimo, como usuario normal'
mkdir -p "$config_dir"
if [[ ! -e "$config" ]]; then
  printf '%s\n\n[data]\nprofile = "%s"\n' "$marker" "$profile" > "$config"
fi
chezmoi --config "$config" init --branch "$ref" "$repo"
source_dir=$(chezmoi --config "$config" source-path)
[[ -z "$(git -C "$source_dir" status --porcelain)" ]] || die 'O source do chezmoi tem alteracoes locais; revisar antes de atualizar.'
[[ "$(git -C "$source_dir" branch --show-current)" == "$ref" ]] || die 'Branch do chezmoi diferente da solicitada; revisar antes de atualizar.'
git -C "$source_dir" pull --ff-only
for target in .bashrc .gitconfig .ssh/allowed_signers .config/shell/1password-agent.sh; do
  if [[ -f "$HOME/$target" ]]; then
    mkdir -p "$state/backup/$(dirname "$target")"
    cp -p "$HOME/$target" "$state/backup/$target"
  fi
done
chezmoi --config "$config" diff
chezmoi --config "$config" apply
chezmoi --version >> "$state/versions.txt"
git -C "$source_dir" rev-parse HEAD >> "$state/versions.txt"
if has codex; then codex --version >> "$state/versions.txt"; fi

cat <<EOF

Perfil Debian desktop minimo aplicado. Backups e versoes: $state

1. Abra 1Password e entre na sua conta, se foi instalado.
2. Em Settings > Developer, habilite SSH Agent quando estiver pronto para Git.
3. Abra outro Konsole, ou execute: source ~/.bashrc
4. Para trabalhar no repo: ~/.local/bin/codex
   Escolha Sign in with ChatGPT e conclua o login localmente.
5. ChatGPT no navegador continua disponivel em https://chatgpt.com/.

Git continua exigindo assinatura SSH; commits dependem do agente habilitado
e da chave configurada. Nenhuma senha ou chave privada deve ir para o repo.
EOF
