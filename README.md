# my-plugins

![Ubuntu](https://img.shields.io/badge/Ubuntu-suportado-E95420?logo=ubuntu&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-suportado-0078D6?logo=windows&logoColor=white)

Um comando instala 9 ferramentas para o Claude Code.
Pula o que já está instalado.

**Nem todas economizam tokens.**
rtk, caveman, ponytail e playwright-cli economizam.
superpowers, code-review, hallmark e design-better melhoram a qualidade e o design (superpowers e code-review até gastam mais).
O graphify depende: ajuda em repositório grande.

## Como usar

![Como usar os 9 itens](docs/img/como-usar.png)

**Ligam sozinhos** (não precisa fazer nada):
* **ponytail**: hook ao abrir a sessão. Comando mais especial `/ponytail-review`, que revisa uma mudança. Para desligar, escreva `stop ponytail`.
* **caveman**: hook ao abrir a sessão. Comando mais especial `/caveman ultra`, que deixa as respostas ainda mais curtas. O script desliga o reforço a cada prompt (`reinforce: false`). Para desligar, escreva `stop caveman`.
* **superpowers**: hook e skills de planejar, testar e depurar. Comando mais especial `/superpowers:brainstorming`, para planejar uma ideia antes de codar.
* **rtk**: hook que comprime a saída dos comandos do terminal. Comando mais especial `rtk gain` (no terminal), que mostra quanto já economizou (no uso real: ~900 mil tokens, 25%). `git diff`, `git show` e `gh pr diff` passam inteiros.
* **hallmark**: o único líder de design visual (temas prontos). Dispara sozinho quando você pede algo novo. Um hook de edição avisa contraste, foco e layout no celular nos arquivos do Hallmark. Comando mais especial `/hallmark:hallmark <pedido>` (e `/hallmark:hallmark audit <pasta>`).
* **design-better**: UX, com 50 heurísticas numeradas e as Laws of UX. O Claude puxa sozinho quando o assunto é tela. Comando mais especial `/design-better`. A linha de design no `CLAUDE.md` global divide o trabalho: Hallmark faz o visual, design-better cuida da UX.
* **playwright-cli**: abre o navegador e confere a tela de verdade. O Claude puxa sozinho quando precisa ver uma página. Gasta menos token que o Playwright MCP. Comando mais especial `playwright-cli open <url>`.

**O Claude chama quando faz sentido (ou você chama):**
* **code-review**: comando mais especial `/code-review:code-review`.
  Use dentro do repo, na branch de um pull request aberto no GitHub (precisa do `gh` logado).
  Com `--comment` no fim, a revisão vira comentário no PR.
  Atenção: `/code-review` sozinho é o revisor que já vem no Claude Code (revisa o diff local), não este plugin.

**Uma vez por projeto:**
* **graphify**: comando mais especial `/graphify .`, que monta o mapa da pasta atual.
  O Claude só consulta o mapa sozinho depois de rodar `graphify claude install` uma vez em cada projeto (grava um bloco no `CLAUDE.md` do projeto).

## O pack

| Item | O que faz | Origem / instalação |
|---|---|---|
| ponytail | código mínimo | plugin `ponytail@ponytail` (marketplace DietrichGebert/ponytail) |
| caveman | respostas curtas | plugin `caveman@caveman` (marketplace JuliusBrussee/caveman) |
| superpowers | método: planejar, testar, depurar | plugin `superpowers@superpowers-marketplace` (marketplace obra/superpowers-marketplace) |
| code-review | revisão de PR com vários agentes | plugin `code-review@claude-plugins-official` |
| rtk | comprime saída de comandos | Ubuntu: script oficial; Windows: `winget` (`rtk-ai.rtk`) |
| graphify | grafo de conhecimento | Ubuntu: `pipx install graphifyy`; Windows: `uv tool install graphifyy` |
| hallmark | design visual (temas prontos) | plugin `hallmark@hallmark` (marketplace Nutlope/hallmark) + hook de edição |
| design-better | UX: heurísticas e Laws of UX | skill do BuilderOS, via `npx skills add` (sem marketplace) |
| playwright-cli | confere a tela no navegador | `npm i -g @playwright/cli` + skill (`playwright-cli install --skills`) |

O superpowers vem do marketplace do autor, porque o oficial fixa a v7.0.0 e o do autor tem a última.

## Plugins

**ponytail**: faz o agente agir como um dev sênior preguiçoso, que escreve o mínimo de código que resolve.
[DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail)

**caveman**: faz o agente responder curto, estilo "homem das cavernas", sem perder o conteúdo técnico.
[JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman)

**superpowers**: conjunto de skills com um método de desenvolvimento (planejar, testar, depurar).
[obra/superpowers](https://github.com/obra/superpowers) (marketplace [obra/superpowers-marketplace](https://github.com/obra/superpowers-marketplace))

**code-review**: comando `/code-review:code-review` que revisa um PR com vários agentes em paralelo e filtra falsos positivos.
[anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-review)

**rtk**: proxy de linha de comando que comprime a saída de comandos comuns antes de chegar ao modelo.
[rtk-ai/rtk](https://github.com/rtk-ai/rtk)

**graphify**: skill `/graphify` que transforma uma pasta (código, docs, PDFs) num grafo de conhecimento consultável.
[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify) (pacote PyPI `graphifyy`)

**hallmark**: único líder de design visual, com temas prontos, hook de edição que avisa contraste, foco e layout no celular, e checagem renderizada opcional (puppeteer-core + Chrome).
[Nutlope/hallmark](https://github.com/Nutlope/hallmark)

**design-better**: skill de UX com 50 heurísticas numeradas e as Laws of UX.
[BuildGreatProducts/builder-os](https://github.com/BuildGreatProducts/builder-os/tree/main/skills/design-better)

**playwright-cli**: CLI + skill que abre o navegador e confere a tela de verdade, com menos token que o Playwright MCP.
[microsoft/playwright-cli](https://github.com/microsoft/playwright-cli)


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
8. **ux-design**

Cada etapa mostra uma barra de progresso e um status: `✔` ok, `↷` já instalado/pulado, `✖` erro.
Uma falha não interrompe as outras etapas. No fim aparece um resumo.

## Como fica

Prints reais do `install.sh` no Ubuntu.

**Máquina nova** (a saída de cada instalador foi omitida, ficam só as linhas do script):

![Instalação numa máquina nova](docs/img/install-fresh.png)

**Rodando de novo** (pula o que já está instalado):

![Tudo já instalado](docs/img/install-skip.png)

**Falta um pré-requisito** (explica, espera o Enter e para sem mudar nada):

![Falta pipx](docs/img/install-missing.png)

O `install.ps1` mostra as mesmas etapas e status no Windows; ainda não há print dele.

## O que muda na máquina

- `~/.claude/settings.json`: hook global `PreToolUse` do rtk.
- `~/.claude/settings.json.bak-AAAAMMDD-HHMMSS`: backup feito logo antes do `rtk init`.
- `~/.claude/RTK.md` e a linha `@RTK.md` no `~/.claude/CLAUDE.md`.
- `~/.claude/skills/graphify/` e um bloco do graphify no `~/.claude/CLAUDE.md`.
- `~/.claude/plugins/`: plugins e marketplaces.
- Binários: Ubuntu em `~/.local/bin` (rtk; graphify via pipx). Windows: links do winget e `%USERPROFILE%\.local\bin`.
- Telemetria do rtk desligada (`rtk telemetry disable`).

No Windows, `~` é `%USERPROFILE%`.

## Desinstalar

**Plugins** (Ubuntu e Windows):
```bash
claude plugin uninstall ponytail@ponytail
claude plugin uninstall caveman@caveman
claude plugin uninstall superpowers@claude-plugins-official
claude plugin uninstall code-review@claude-plugins-official
claude plugin uninstall ux-design@wondelai-skills
claude plugin marketplace remove ponytail
claude plugin marketplace remove caveman
claude plugin marketplace remove wondelai-skills
```
Opcional: `claude plugin marketplace remove claude-plugins-official`.
Cuidado: outros plugins seus podem usar esse marketplace.

**rtk** (opcional antes: `rtk telemetry forget`):
```bash
# Ubuntu
rtk init -g --uninstall
rm -f "$(command -v rtk)"
```
```powershell
# Windows
rtk init -g --uninstall
winget uninstall -e --id rtk-ai.rtk
```

**graphify**:
```bash
# Ubuntu
graphify uninstall
pipx uninstall graphifyy
```
```powershell
# Windows
graphify uninstall
uv tool uninstall graphifyy
```

Opcional: restaurar o backup `settings.json.bak-*` por cima do `settings.json`.
Isso descarta qualquer mudança feita no `settings.json` depois do backup.

## Avisos

- **ponytail no Windows**: tem bug conhecido, trava cada mensagem por alguns segundos.
  Por isso o `install.ps1` pergunta antes, e o padrão é **N** (não instala).
  Sem terminal interativo, ele pula o ponytail.
  Para instalar depois, manualmente:
  ```powershell
  claude plugin install ponytail@ponytail
  ```
- **Símbolos como quadrados** (`✔ ✖ ↷ ⏳ █`): o console antigo do Windows (conhost) não desenha esses caracteres. Use o Windows Terminal.
- **Reinicie o Claude Code** (feche e abra de novo) depois de instalar, para carregar os plugins e o hook do rtk. No Windows, reabra também o terminal.

## Status

- **Ubuntu**: testado.
- **Windows**: a versão anterior foi testada e funcionou; o novo `install.ps1` ainda não foi testado. Testes pendentes.
