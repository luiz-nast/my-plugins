# my-plugins

![Ubuntu](https://img.shields.io/badge/Ubuntu-suportado-E95420?logo=ubuntu&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-suportado-0078D6?logo=windows&logoColor=white)

Um comando instala 6 ferramentas que economizam tokens no Claude Code.
Pula o que já está instalado e desliga a telemetria do rtk.

## Plugins

**ponytail**: faz o agente agir como um dev sênior preguiçoso, que escreve o mínimo de código que resolve.
[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)

**caveman**: faz o agente responder curto, estilo "homem das cavernas", sem perder o conteúdo técnico.
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)

**superpowers**: conjunto de skills com um método de desenvolvimento (planejar, testar, revisar).
[obra/superpowers](https://github.com/obra/superpowers)

**code-review**: comando `/code-review` que revisa um PR com vários agentes em paralelo e filtra falsos positivos.
[anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review)

**rtk**: proxy de linha de comando que comprime a saída de comandos comuns antes de chegar ao modelo.
[rtk-ai/rtk](https://github.com/rtk-ai/rtk)

**graphify**: skill `/graphify` que transforma uma pasta (código, docs, PDFs) num grafo de conhecimento consultável.
[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (pacote PyPI `graphifyy`)

## Resumo

| Nome | O que faz | Como instala / origem |
|---|---|---|
| ponytail | código mínimo | plugin `ponytail@ponytail` (marketplace DietrichGebert/ponytail) |
| caveman | respostas curtas | plugin `caveman@caveman` (marketplace JuliusBrussee/caveman) |
| superpowers | método de desenvolvimento | plugin `superpowers@claude-plugins-official` |
| code-review | revisão de PR | plugin `code-review@claude-plugins-official` |
| rtk | comprime saída de comandos | Ubuntu: script oficial; Windows: `winget` (`rtk-ai.rtk`) |
| graphify | grafo de conhecimento | Ubuntu: `pipx install graphifyy`; Windows: `uv tool install graphifyy` |

## Instalação

**Ubuntu**
```bash
curl -fsSL https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.sh | bash
```

**Windows (PowerShell)**
```powershell
irm https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.ps1 | iex
```

### Requisitos

| Ubuntu | Windows |
|---|---|
| Claude Code (`claude`) | Claude Code (`claude`) |
| `curl` | `winget` (App Installer, Microsoft Store) |
| `git` | `uv` (`winget install -e --id astral-sh.uv`) |
| `pipx` (`sudo apt install -y pipx && pipx ensurepath`) | |

Se faltar algo, o script mostra como instalar e espera você apertar Enter.
Se ainda faltar, ele para sem mudar nada.

### Etapas

1. **Pré-requisitos**: confere os requisitos acima (no Windows, pergunta sobre o ponytail).
2. **ponytail**
3. **caveman**
4. **superpowers**
5. **code-review**
6. **rtk**: instala, faz backup do `settings.json`, liga o hook global e desliga a telemetria.
7. **graphify**: instala e roda `graphify install`.

Cada etapa mostra uma barra de progresso e um status: `✔` ok, `↷` já instalado/pulado, `✖` erro.
Uma falha não interrompe as outras etapas. No fim aparece um resumo.
