# Debian desktop minimo

Revisado em 2026-11-15. Alvos: Debian 13/Trixie e Forky, arm64 ou amd64, usuario normal com sudo. Para Air M1, usar a arquitetura arm64 e manter o kernel/bootstack instalados pelo Bananas. Este bootstrap configura o ambiente de usuario; nao instala Debian.

## Iniciar

No Konsole do Debian, como seu usuario normal:

```sh
curl -fL https://b.guisso.dev/init-debian-desktop.sh -o /tmp/init-debian-desktop.sh
bash /tmp/init-debian-desktop.sh
```

Se curl ainda nao existir, instalar apenas essa ferramenta antes:

```sh
sudo apt-get update
sudo apt-get install curl
```

Nao usar `sudo bash`: o script pede sudo somente nos passos de sistema. A conta precisa ter sudo funcional; ele nao muda grupos ou concede privilegios para contornar isso.

## O que entra

1. Git, curl, certificados, GnuPG, cliente OpenSSH e Python 3 via APT, com `--no-remove`, sem upgrade geral.
2. Chezmoi pelo instalador oficial em `~/.local/bin`, caso ausente.
3. 1Password nativo para a arquitetura detectada, se o comando ainda nao existir. Usa tar oficial, verifica fingerprint e assinatura GPG, extrai com filtro de caminhos e instala em `/opt/1Password` com o pos-instalador do fornecedor.
4. Codex CLI pelo instalador oficial, se ausente. Nao instala Node para isso e nao faz login automaticamente.
5. Chezmoi com `[data] profile = "debian-desktop-minimo"`: Git e assinatura SSH existentes, allowed_signers e uma linha idempotente no `.bashrc` para PATH/agente 1Password. O conteudo anterior do Bash permanece.

O perfil ignora zsh, p10k, mise/runtimes, Rio e LazyVim e nao executa os hooks de instalacao Linux ou defaults macOS/Canario. O comportamento completo anterior e preservado para quem nao seleciona esse perfil. O script LXC permanece separado e nao deve ser usado como bootstrap desktop.

O Git continua exigindo assinatura com a chave publica ja configurada neste repo. O agente precisa estar habilitado e conter essa chave para commits/push. O script nao exporta chaves privadas nem reduz a exigencia de assinatura.

## Depois de concluir

1. Abrir 1Password e fazer login localmente.
2. Em Settings > Developer, habilitar SSH Agent para usar as chaves do cofre.
3. Abrir outro Konsole ou executar `source ~/.bashrc`. A integracao so seleciona o socket 1Password em sessao local e quando ele existe; preserva agente encaminhado em SSH.
4. Executar `~/.local/bin/codex` e escolher **Sign in with ChatGPT**. Concluir o login no navegador, sem colar tokens no chat ou no Git.
5. Abrir https://chatgpt.com/ no navegador para conversar. O uso do Codex no terminal e suficiente para trabalhar no repositorio local.

Para obter o laboratorio na branch de continuidade atual:

```sh
git clone --branch codex/air-m1-kde-perfil-debian https://github.com/fguisso/maclaren.git
cd maclaren
~/.local/bin/codex
```

O maclaren e privado: autenticar o acesso ao GitHub ou usar SSH depois de configurar o agente. Nao colocar token na URL. Ler `AGENTS.md` e `docs/continuar-no-debian.md` antes de retomar verificacoes.

## Opcionais

```sh
bash /tmp/init-debian-desktop.sh --with-chatgpt
bash /tmp/init-debian-desktop.sh --skip-apps
```

`--with-chatgpt` acrescenta o aplicativo oficial em preview. Baixa o `.deb` correspondente, confere nome/arquitetura, salva os scripts de manutencao e simula a instalacao antes de chamar APT com `--no-remove`. O pacote configura seu repositorio de atualizacoes. A documentacao lista Debian 13; Forky ainda precisa de validacao. Na revisao de 2026-11-15, o link oficial foi confirmado, mas o download direto desta assistencia retornou HTTP 403. Se isso ocorrer no Debian, usar navegador/Codex e investigar o download; nao instalar wrappers de terceiros como substituicao automatica.

`--skip-apps` aplica somente a base e o perfil chezmoi, sem 1Password, Codex ou ChatGPT. Aplicativos que ja existem sao preservados; reexecutar nao e um atualizador geral deles.

Para testar uma branch publicada antes de ela chegar a main, usar `BASHINGSE_REF=nome-da-branch bash arquivo-do-bootstrap.sh`. Isso tambem seleciona a branch dos dotfiles; baixar o proprio bootstrap dessa mesma revisao.

## Estado, efeitos e recuperacao

Cada execucao cria uma pasta privada em `~/.local/state/bashingse/debian-desktop/`, ou no XDG_STATE_HOME configurado. Ela guarda downloads, SHA256, versoes e copias dos arquivos existentes que o perfil vai alterar. Nao versionar essa pasta.

Uma configuracao chezmoi preexistente nao gerenciada por este bootstrap interrompe a execucao antes de instalar pacotes. Integrar o dado `profile` manualmente apos revisar a configuracao, em vez de sobrescreve-la. Reexecucoes do bootstrap aceitam sua propria configuracao e recusam source Git com alteracoes locais ou branch diferente.

O instalador tar 1Password revisado (8.12.44) cria integracoes em `/usr/share/applications`, icones, politica polkit, configuracao em `/etc/1password`, grupos auxiliares, links em `/usr/bin` e permissoes setuid/setgid nos helpers do fornecedor. Nao habilita login, agente SSH ou MCP na conta automaticamente. A variante tar nao configura repositorio APT; atualizacoes precisam seguir o metodo oficial tar. O arquivo e a assinatura precisam coincidir; uma publicacao concorrente pode exigir repetir o download.

Se uma instalacao parcial deixar `/opt/1Password` sem o comando correspondente, o bootstrap para para revisao e nao apaga o diretorio. Para desfazer configuracoes de usuario, restaurar os arquivos da pasta `backup/` registrada no final, revisando diferencas feitas depois. Interromper o gerenciamento chezmoi desses alvos antes de restaurar para nao reaplica-los sem querer. Nao apagar chaves/cofres.

A remocao de aplicativos e uma operacao separada: ChatGPT instalado por APT e removido como pacote e sua fonte deve ser revisada; Codex nativo guarda binarios em `~/.local/bin` e pacotes em `~/.codex/packages`, separados do login/configuracao; 1Password tar exige revisar os caminhos criados pelo pos-instalador. Preservar dados da conta e backups ao planejar remocao. Este script nao executa desinstalacao automatica.

Nao muda locale, shell padrao, KDE, kernel, particoes ou politica de boot. APT pode atualizar dependencias dos pacotes solicitados; `--no-remove` impede resolver conflitos apagando pacotes. Se o sistema exigir troca de componentes, diagnosticar antes de prosseguir.

## Fontes e verificacao

- [1Password Linux e ARM](https://support.1password.com/install-linux/): tar ARM64 e assinatura, chave `3FEF9748469ADBE15DA7CA80AC2D62742012EA22`.
- [Agente SSH 1Password](https://www.1password.dev/ssh/agent): exige instalacao nativa para esta integracao.
- [Codex oficial](https://github.com/openai/codex): instalador `https://chatgpt.com/codex/install.sh`, com Linux ARM64.
- [ChatGPT Linux](https://learn.chatgpt.com/docs/linux/linux-app?translationFallback=es-419): preview ARM64, suporte listado para Debian 13 e limites Wayland/Computer Use.
- [Chezmoi](https://www.chezmoi.io/user-guide/manage-machine-to-machine-differences/): configuracao por maquina e templates.

Testes do repo: `python3 tests/debian-desktop.py`, com chezmoi no PATH, e `bash -n bootstrap/init-debian-desktop.sh`. O teste usa HOME/destino temporarios, verifica reaplicacao e preservacao do Bash, assinatura Git, isolamento dos perfis e bloqueio fora do Linux. Nao testa instalacao real dos aplicativos ou autenticacao no Air; esses resultados devem ser registrados no maclaren apos executar no Debian.
