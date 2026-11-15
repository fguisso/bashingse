#!/usr/bin/env python3
"""Testa reparo do menu em diretorios temporarios, sem sudo real ou instaladores."""
from pathlib import Path
import os
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
script = (root / 'bootstrap/init-debian-desktop.sh').read_text()
helper = script.split('fix_1password_menu() {', 1)[1].split('\ninstall_1password() {', 1)[0]
helper = 'fix_1password_menu() {' + helper
with tempfile.TemporaryDirectory(prefix='bashingse-menu-') as temporary:
    base = Path(temporary)
    opt = base / 'opt/1Password'
    apps = base / 'applications'
    bin_dir = base / 'bin'
    for directory in [opt / 'resources', apps, bin_dir]:
        directory.mkdir(parents=True)
    binary = opt / '1password'
    binary.write_text('#!/bin/sh\nexit 0\n')
    binary.chmod(0o755)
    (bin_dir / '1password').symlink_to(binary)
    (bin_dir / 'sudo').write_text('#!/bin/sh\nexec "$@"\n')
    (bin_dir / 'sudo').chmod(0o755)
    (bin_dir / 'kbuildsycoca6').write_text('#!/bin/sh\nexit 0\n')
    (bin_dir / 'kbuildsycoca6').chmod(0o755)
    helper = helper.replace('/opt/1Password', str(opt)).replace('/usr/share/applications', str(apps))
    program = ('set -euo pipefail\numask 077\n'
               'has() { command -v "$1" >/dev/null 2>&1; }\n'
               'die() { echo "$*" >&2; exit 1; }\n' + helper + '\nfix_1password_menu\n')
    env = dict(os.environ, PATH=str(bin_dir) + os.pathsep + os.environ['PATH'])
    def run():
        return subprocess.run(['bash', '-c', program], env=env, capture_output=True, text=True)
    for name in ['com.onepassword.OnePassword.desktop', '1password.desktop']:
        template = opt / 'resources' / name
        template.write_text('[Desktop Entry]\nName=1Password\nType=Application\n')
        target = apps / name
        assert run().returncode == 0
        assert target.read_bytes() == template.read_bytes()
        assert target.stat().st_mode & 0o777 == 0o644
        target.write_text(template.read_text() + '# Personalizacao local\n')
        target.chmod(0o600)
        original = target.read_bytes()
        assert run().returncode == 0
        assert run().returncode == 0
        assert target.read_bytes() == original
        assert target.stat().st_mode & 0o777 == 0o644
    target.unlink()
    protected = base / 'protected'
    protected.write_text('nao alterar')
    protected.chmod(0o600)
    target.symlink_to(protected)
    assert run().returncode != 0, 'Destino simbolico deveria ser recusado'
    assert protected.stat().st_mode & 0o777 == 0o600
    (bin_dir / '1password').unlink()
    (bin_dir / '1password').write_text('#!/bin/sh\nexit 0\n')
    (bin_dir / '1password').chmod(0o755)
    assert run().returncode == 0, 'Instalacao fora de /opt deveria ser preservada'
    assert protected.stat().st_mode & 0o777 == 0o600
print('OK: menu novo, modo 0600 corrigido, reaplicacao, conteudo preservado e escopo limitado.')
