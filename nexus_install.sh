#!/usr/bin/env bash
# NEXUS SCAN — instalador para OpenCode
# Repositório: https://github.com/castielwallker/nexus
# Uso: bash nexus_install.sh
set -Eeuo pipefail

REPO="castielwallker/nexus"
BRANCH="main"
ZIP_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/nexus_scan.zip"
INSTALL_NAME="nexus"

ok()   { printf '\033[32m[OK]\033[0m %s\n' "$*"; }
info() { printf '\033[36m[INFO]\033[0m %s\n' "$*"; }
die()  { printf '\033[31m[ERRO]\033[0m %s\n' "$*" >&2; exit 1; }

for bin in curl unzip; do
  command -v "$bin" >/dev/null 2>&1 || die "Dependência não encontrada: $bin"
done
PYTHON="$(command -v python3 || command -v python || true)"
[[ -n "$PYTHON" ]] || die "Python 3 não encontrado. Instale Python 3.10+ e tente novamente."

# OpenCode permite definir um diretório de configuração personalizado.
if [[ -n "${OPENCODE_CONFIG_DIR:-}" ]]; then
  CONFIG_DIR="$OPENCODE_CONFIG_DIR"
else
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
fi

AGENTS_DIR="$CONFIG_DIR/agents"
COMMANDS_DIR="$CONFIG_DIR/commands"
NEXUS_DIR="$CONFIG_DIR/$INSTALL_NAME"
mkdir -p "$AGENTS_DIR" "$COMMANDS_DIR" "$CONFIG_DIR"

TMP_DIR="$(mktemp -d)"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

info "Baixando o pacote Nexus do GitHub..."
curl --fail --location --silent --show-error \
  --retry 3 --retry-delay 2 \
  "$ZIP_URL" -o "$TMP_DIR/nexus_scan.zip" \
  || die "Falha ao baixar o ZIP. Verifique sua conexão e se nexus_scan.zip está na branch main."

unzip -tq "$TMP_DIR/nexus_scan.zip" >/dev/null \
  || die "O arquivo baixado não é um ZIP válido."
mkdir "$TMP_DIR/extracted"
unzip -q "$TMP_DIR/nexus_scan.zip" -d "$TMP_DIR/extracted"

# Aceita ZIP com pasta nexus_scan/ ou arquivos diretamente na raiz.
SOURCE_DIR=""
while IFS= read -r -d '' candidate; do
  if [[ -f "$candidate/app.py" && -f "$candidate/requirements.txt" ]]; then
    SOURCE_DIR="$candidate"
    break
  fi
done < <(find "$TMP_DIR/extracted" -type d -print0)

[[ -n "$SOURCE_DIR" ]] || die "ZIP incompatível: não encontrei app.py e requirements.txt."

# Preserva uma instalação anterior até o novo pacote estar validado.
NEW_DIR="$CONFIG_DIR/.nexus-install-new"
OLD_DIR="$CONFIG_DIR/.nexus-install-old"
rm -rf "$NEW_DIR" "$OLD_DIR"
mkdir -p "$NEW_DIR"
cp -a "$SOURCE_DIR/." "$NEW_DIR/"
[[ -f "$NEW_DIR/templates/index.html" ]] || die "Pacote incompleto: templates/index.html não encontrado."
[[ -f "$NEW_DIR/static/app.js" ]] || die "Pacote incompleto: static/app.js não encontrado."

info "Criando ambiente Python isolado..."
"$PYTHON" -m venv "$NEW_DIR/.venv"
if [[ -x "$NEW_DIR/.venv/bin/python" ]]; then
  VENV_PY="$NEW_DIR/.venv/bin/python"
elif [[ -x "$NEW_DIR/.venv/Scripts/python.exe" ]]; then
  VENV_PY="$NEW_DIR/.venv/Scripts/python.exe"
else
  die "Não consegui localizar o Python do ambiente virtual."
fi
"$VENV_PY" -m pip install --disable-pip-version-check --upgrade pip
"$VENV_PY" -m pip install --disable-pip-version-check -r "$NEW_DIR/requirements.txt"

if [[ -d "$NEXUS_DIR" ]]; then mv "$NEXUS_DIR" "$OLD_DIR"; fi
if ! mv "$NEW_DIR" "$NEXUS_DIR"; then
  [[ -d "$OLD_DIR" ]] && mv "$OLD_DIR" "$NEXUS_DIR"
  die "Não foi possível ativar a nova instalação."
fi
rm -rf "$OLD_DIR"

cat > "$AGENTS_DIR/nexus.md" <<'AGENT'
---
description: Nexus — análise defensiva de segurança do workspace atual
mode: primary
---

# NEXUS SCAN — agente de segurança do projeto

Você é o agente Nexus. Quando o usuário iniciar você ou executar `/nexus`,
faça uma verificação defensiva da pasta do workspace atual.

## Escopo e segurança
- Identifique a raiz do workspace atual com `pwd`.
- Analise somente essa pasta. Não examine HOME, discos inteiros, pastas vizinhas
  ou a pasta global de instalação `~/.config/opencode/nexus`.
- Não siga links simbólicos que apontem para fora do workspace.
- Não execute arquivos encontrados, não os abra como programas e não altere,
  apague, mova ou coloque arquivos em quarentena.
- A análise de reputação externa usa somente hashes SHA-256; não envie arquivos.
- Resultado desconhecido, serviço indisponível ou ausência de chave não significa limpo.
- A varredura do Microsoft Defender é um resultado geral da pasta, não um
  veredito individual de cada arquivo.

## Procedimento
1. Mostre:
   [ Nexus Scaneando ]
   ֎ Aguarde está sendo feito a verificação da pasta "<nome da pasta>" . . .
2. Use o backend instalado em `~/.config/opencode/nexus`. Se
   `OPENCODE_CONFIG_DIR` estiver definido, use `<OPENCODE_CONFIG_DIR>/nexus`.
3. Use o Python em `.venv` dentro dessa pasta. Inicie `app.py` em background
   somente se `http://127.0.0.1:5050/api/state` não responder. Não crie
   instâncias duplicadas.
4. Envie POST para `http://127.0.0.1:5050/api/scan` com:
   `{"folder":"<caminho absoluto da raiz do workspace>","cloud":true}`
5. Consulte `/api/state` até `running` ficar false. Se ocorrer erro, informe a
   falha; nunca declare sucesso sem confirmar a conclusão.
6. Gere `Verification.MD` na raiz do workspace com data, pasta, resumo, total
   de arquivos e resultados por arquivo (nome, SHA-256, score, VirusTotal e
   Kaspersky). Inclua Defender somente como resultado geral da pasta.
7. Ao concluir com sucesso, responda:
   [ Nexus ]
   ֎ Scan foi efetuado com sucesso. [Clique Aqui](http://127.0.0.1:5050)
   para verificar os dados.
   Informe também um resumo breve e o caminho de `Verification.MD`.

## Limites
- O dashboard deve permanecer vinculado a `127.0.0.1`.
- Respeite a opção de desativar consultas externas.
- Não prometa detecção completa nem trate ausência de detecção como garantia
  de segurança.
AGENT

cat > "$COMMANDS_DIR/nexus.md" <<'COMMAND'
---
description: Verifica a segurança do workspace atual com o Nexus
agent: nexus
---
Inicie agora a verificação defensiva do workspace atual. Siga as regras de
escopo do agente Nexus, acompanhe a execução até o término e gere
Verification.MD na raiz do projeto. Informe o link do dashboard somente
depois de confirmar que a varredura terminou com sucesso.
COMMAND

ok "Motor instalado em: $NEXUS_DIR"
ok "Agente instalado em: $AGENTS_DIR/nexus.md"
ok "Comando instalado em: $COMMANDS_DIR/nexus.md"
printf '\n'
printf 'NEXUS SCAN instalado!\n'
printf 'Abra/reinicie o OpenCode e selecione o agente Nexus.\n'
printf 'Ou execute /nexus dentro de um projeto.\n'
printf 'Dashboard: http://127.0.0.1:5050 (iniciado pelo agente quando necessário)\n'
printf '\n'
printf 'APIs opcionais: configure VT_API_KEY e OPENTIP_API_KEY no ambiente\n'
printf 'antes de iniciar o OpenCode. Nunca publique suas chaves no GitHub.\n'
