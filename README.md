<div align="center">

# 🛡️ NEXUS SCAN

### Análise defensiva de segurança integrada ao OpenCode

Verifique o workspace do seu projeto, consulte reputação de hashes SHA-256 e acompanhe os resultados em um dashboard local.

**Um instalador. Um agente. Uma verificação focada no seu projeto.**

[🚀 Instalação](#-instalação) · [⚙️ Como usar](#️-como-usar) · [🔎 Integrações](#-integrações) · [🛡️ Segurança](#-segurança-e-privacidade)

</div>

---

## ✦ Sobre o Nexus

O **Nexus Scan** é uma ferramenta de triagem defensiva que integra um agente ao [OpenCode](https://opencode.ai/). O agente foi configurado para analisar somente a pasta do workspace atualmente aberto, sem iniciar uma varredura geral do computador.

O instalador baixa o motor `nexus_scan.zip` diretamente deste repositório, prepara um ambiente Python isolado e registra o agente e o comando `/nexus` na configuração do OpenCode.

### Destaques

- Agente **Nexus** disponível no OpenCode.
- Comando `/nexus` para iniciar a verificação do workspace.
- Dashboard web local com tema Dark e Light.
- Hash SHA-256 por arquivo.
- Consultas opcionais ao VirusTotal e Kaspersky OpenTIP.
- Microsoft Defender no Windows, quando disponível.
- Relatório `Verification.MD` na raiz do projeto analisado.

> O Nexus é uma ferramenta de triagem. Não substitui um antivírus, EDR ou análise profissional e não garante a detecção de todas as ameaças.

---

## 🚀 Instalação

### Requisitos

- OpenCode instalado.
- Python 3.10 ou superior.
- Bash, `curl` e `unzip`.
- Conexão com a internet durante a instalação.

**Windows:** o instalador é um script Bash. Use Git Bash ou WSL com Python, `curl` e `unzip` disponíveis. A integração com Microsoft Defender depende de Windows e de `MpCmdRun.exe`.

### Instalar com um comando

Abra o terminal e execute:

```bash
curl -fsSL https://raw.githubusercontent.com/castielwallker/nexus/main/nexus_install.sh -o nexus_install.sh
bash nexus_install.sh
```

O instalador fará automaticamente:

1. Download do `nexus_scan.zip` hospedado neste repositório.
2. Extração e validação dos arquivos do motor.
3. Instalação em `~/.config/opencode/nexus`.
4. Criação de um ambiente virtual Python isolado.
5. Instalação das dependências de `requirements.txt`.
6. Registro do agente global `Nexus`.
7. Registro do comando `/nexus`.

Não é necessário baixar ou extrair `nexus_scan.zip` manualmente.

### Instalar manualmente

Também é possível baixar o instalador pela página do repositório:

- [Abrir nexus_install.sh](https://github.com/castielwallker/nexus/blob/main/nexus_install.sh)
- [Baixar nexus_install.sh diretamente](https://raw.githubusercontent.com/castielwallker/nexus/main/nexus_install.sh)
- [Ver nexus_scan.zip](https://github.com/castielwallker/nexus/blob/main/nexus_scan.zip)

---

## ⚙️ Como usar

### 1. Abra seu projeto no OpenCode

Entre normalmente na pasta que deseja verificar e abra essa pasta como workspace no OpenCode.

### 2. Selecione o agente Nexus

Use o seletor de agentes do OpenCode e escolha **Nexus**.

Você também pode iniciar a verificação com:

```text
/nexus
```

> Selecionar o agente não inicia ferramentas automaticamente. Envie uma mensagem ao agente ou execute `/nexus` para começar.

### 3. Acompanhe a varredura

Durante a verificação, o agente apresenta:

```text
[ Nexus Scaneando ]
֎ Aguarde está sendo feito a verificação da pasta "MeuProjeto" . . .
```

O Nexus inicia o motor local, solicita a análise da raiz do workspace e acompanha o progresso.

### 4. Veja o resultado

Depois de confirmar que a verificação terminou, a resposta será:

```text
[ Nexus ]
֎ Scan foi efetuado com sucesso.
Clique Aqui para verificar os dados.
```

Dashboard:

**http://127.0.0.1:5050**

Relatório gerado:

```text
Verification.MD
```

O relatório é salvo na raiz do projeto analisado.

Se houver falha ao iniciar o motor, consultar a API ou concluir a varredura, o agente deverá informar o erro em vez de afirmar que houve sucesso.

---

## 🔎 Integrações

| Motor | Função |
|---|---|
| Microsoft Defender | Solicita scan personalizado da pasta no Windows |
| VirusTotal | Consulta reputação do SHA-256 pela API v3 |
| Kaspersky OpenTIP | Consulta reputação do SHA-256 |
| Nexus Risk Score | Pontuação heurística para priorizar resultados |

### Microsoft Defender

O Nexus procura `MpCmdRun.exe` e solicita uma verificação personalizada da pasta. O resultado é geral da pasta e não deve ser apresentado como veredito individual de cada arquivo.

O MRT (`mrt.exe`) não é iniciado automaticamente: ele é voltado à verificação do sistema e não oferece uma interface flexível suportada para verificar uma pasta arbitrária.

### VirusTotal

O motor calcula o SHA-256 dos arquivos e consulta a API v3 pelo hash. O fluxo de consulta por hash não envia o conteúdo do arquivo.

Um hash sem registro no serviço aparece como desconhecido/não encontrado — não como limpo.

### Kaspersky OpenTIP

A integração consulta a reputação do hash SHA-256. Isso não equivale a executar uma varredura local com o antivírus Kaspersky.

### Pontuação de risco

O score é uma heurística de triagem de 0 a 100 baseada nos indicadores retornados pelas integrações. Não é uma probabilidade estatística de infecção.

- **Risco suave:** poucos indicadores positivos conhecidos.
- **Risco médio:** sinais que merecem revisão.
- **Risco grave:** indicadores mais fortes ou múltiplos sinais.

Serviços indisponíveis, APIs sem chave e hashes sem resultado devem permanecer como desconhecidos/não consultados; nunca devem ser convertidos automaticamente em “limpo”.

---

## 🔑 Configuração das APIs (opcional)

O Nexus pode executar as etapas locais disponíveis sem as chaves. Para habilitar consultas externas, configure as variáveis antes de iniciar o OpenCode.

### Linux / macOS / WSL

```bash
export VT_API_KEY="SUA_CHAVE_VIRUSTOTAL"
export OPENTIP_API_KEY="SUA_CHAVE_KASPERSKY"
opencode
```

### PowerShell

```powershell
$env:VT_API_KEY = "SUA_CHAVE_VIRUSTOTAL"
$env:OPENTIP_API_KEY = "SUA_CHAVE_KASPERSKY"
opencode
```

**Nunca** coloque chaves reais no README, no código-fonte ou em arquivos versionados. Se uma chave for exposta, revogue-a no provedor e gere outra.

---

## 🛡️ Segurança e privacidade

O agente Nexus foi instruído a:

- Analisar somente a raiz do workspace atual.
- Não varrer o computador inteiro, HOME ou pastas vizinhas.
- Não incluir automaticamente a pasta global de instalação do Nexus.
- Não seguir links simbólicos que apontem para fora do workspace.
- Não executar arquivos encontrados.
- Não apagar, mover ou colocar arquivos em quarentena.
- Não enviar o conteúdo dos arquivos para os serviços de reputação.

**Atenção às consultas por hash:** embora o arquivo não seja enviado, o serviço externo recebe o hash consultado e pode registrar a pesquisa. Não habilite consultas externas para projetos confidenciais se isso não for apropriado.

O dashboard deve ficar acessível somente no endereço local `127.0.0.1`.

---

## 📁 Estrutura do repositório

```text
nexus/
├── nexus_install.sh
├── nexus_scan.zip
└── README.md
```

O ZIP contém o motor web Python, templates, CSS, JavaScript e `requirements.txt`. O instalador valida a presença de `app.py`, `requirements.txt`, `templates/index.html` e `static/app.js` antes de concluir.

---

## 🧹 Desinstalação

No Linux / macOS / WSL:

```bash
rm -rf ~/.config/opencode/nexus
rm -f ~/.config/opencode/agents/nexus.md
rm -f ~/.config/opencode/commands/nexus.md
```

Se você utiliza `OPENCODE_CONFIG_DIR` ou `XDG_CONFIG_HOME`, remova os mesmos caminhos dentro do diretório de configuração correspondente.

---

## 🧰 Solução de problemas

**O comando `/nexus` não aparece**
- Confirme se `~/.config/opencode/commands/nexus.md` foi criado.
- Reinicie ou reabra o OpenCode.

**O agente Nexus não aparece**
- Confirme se `~/.config/opencode/agents/nexus.md` existe.
- Verifique o diretório de configuração personalizado, se houver.

**O dashboard não abre**
- Confirme se o agente iniciou o motor.
- Verifique se a porta `5050` está disponível.
- Acesse `http://127.0.0.1:5050`.

**VirusTotal ou Kaspersky não retornam dados**
- Confira se as variáveis de ambiente foram configuradas antes de iniciar o OpenCode.
- Verifique a validade da chave e os limites de uso.
- Hash não encontrado não significa arquivo seguro.

**Microsoft Defender indisponível**
- A integração depende de Windows e `MpCmdRun.exe`.
- Em outros sistemas operacionais, essa etapa será ignorada/indicada como indisponível.

---

## ⚖️ Aviso

Use o Nexus somente em arquivos, pastas e projetos que você tem autorização para verificar. Respeite os termos e limites das APIs de terceiros. O projeto não oferece garantia de detecção integral, ausência de falsos positivos ou ausência de falsos negativos.

---

<div align="center">

### 🛡️ NEXUS SCAN

**Segurança começa com visibilidade.**

Feito para integrar uma triagem defensiva ao seu fluxo de desenvolvimento.

</div>
