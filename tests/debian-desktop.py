#!/usr/bin/env python3
"""Valida o perfil em HOME isolado, sem instalar pacotes nem executar hooks completos."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
chezmoi = shutil.which('chezmoi')
assert chezmoi, 'chezmoi precisa estar no PATH'
with tempfile.TemporaryDirectory(prefix='bashingse-test-') as temporary:
    base = Path(temporary)
    home = base / 'home'
    home.mkdir()
    config = base / 'chezmoi.toml'
    config.write_text('[data]\nprofile = "debian-desktop-minimo"\n')
    original = '# Configuracao preexistente\nexport EXEMPLO_LOCAL=preservado\n'
    (home / '.bashrc').write_text(original)
    command = [chezmoi, '--config', str(config), '--source', str(root),
               '--destination', str(home), '--cache', str(base / 'cache'),
               '--persistent-state', str(base / 'state.db'), '--no-tty']
    hooks = ['run_once_install-linux-shell-deps.sh.tmpl',
             'run_after_macos_defaults.sh.tmpl',
             'run_onchange_after_canario_defaults.sh.tmpl']
    for name in hooks + ['.chezmoiexternal.toml.tmpl', '.chezmoiremove.tmpl']:
        result = subprocess.check_output(command + ['execute-template', '--file',
                                         str(root / 'dotfiles' / name)], text=True)
        assert not result.strip(), f'Perfil minimo ativou {name}'
    subprocess.run(command + ['apply', '--force'], check=True, capture_output=True, text=True)
    subprocess.run(command + ['apply', '--force'], check=True, capture_output=True, text=True)
    bashrc = (home / '.bashrc').read_text()
    assert bashrc.startswith(original), 'Conteudo preexistente do Bash foi perdido'
    assert bashrc.count('1password-agent.sh') == 2, 'Linha de integracao duplicada'
    assert (home / '.gitconfig').is_file()
    assert 'gpgsign = true' in (home / '.gitconfig').read_text()
    assert (home / '.ssh/allowed_signers').is_file()
    for name in ['.zshrc', '.p10k.zsh', '.config/mise', '.config/nvim', '.config/rio']:
        assert not (home / name).exists(), f'Perfil minimo criou {name}'
    assert not (home / '.antidote').exists()
    assert (home / '.config/shell/1password-agent.sh').is_file()
    # Perfil antigo sem dados continua incluindo os recursos completos.
    config.write_text('')
    expectations = {
        hooks[0]: 'mise install',
        hooks[1]: 'defaults write',
        hooks[2]: 'com.raphaelamorim.canario',
        '.chezmoiexternal.toml.tmpl': 'fguisso/lazyvim-config',
        '.chezmoiremove.tmpl': '.zsh_plugins.txt',
    }
    for name, expected in expectations.items():
        result = subprocess.check_output(command + ['execute-template', '--file',
                                         str(root / 'dotfiles' / name)], text=True)
        assert expected in result, f'Perfil completo perdeu {name}'
    # Falha de plataforma deve acontecer antes de sudo, downloads ou gravacoes.
    mockbin = base / 'bin'
    mockbin.mkdir()
    (mockbin / 'uname').write_text('#!/bin/sh\nprintf "Darwin\\n"\n')
    (mockbin / 'uname').chmod(0o755)
    env = dict(os.environ, PATH=str(mockbin) + os.pathsep + os.environ['PATH'], HOME=str(home))
    result = subprocess.run(['bash', str(root / 'bootstrap/init-debian-desktop.sh')],
                            env=env, capture_output=True, text=True)
    assert result.returncode != 0 and 'nao no macOS' in result.stderr
    assert not (home / '.local/state/bashingse').exists()
print('OK: perfil minimo isolado, reaplicacao, assinatura Git, perfil completo e guarda de plataforma.')
