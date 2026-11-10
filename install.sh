#!/usr/bin/env bash
# my-plugins: instala 7 ferramentas no Claude Code (Ubuntu).
# Uso: curl -fsSL <url>/install.sh | bash   (pode rodar de novo: pula o que já existe)
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

N=8
OK=() SKIP=() FAIL=()
PL=""  # cache de `claude plugin list --json` (grep -q num pipe quebra com pipefail)

has() { command -v "$1" >/dev/null 2>&1; }

bar() {  # bar i nome
  local cheio vazio
  printf -v cheio '%*s' $(( $1 * 20 / N )) ''
  printf -v vazio '%*s' $(( 20 - $1 * 20 / N )) ''
  printf '\n[%s%s] Etapa %s/%s  %s\n' "${cheio// /█}" "${vazio// /░}" "$1" "$N" "$2"
}

status() {  # status run|ok|skip|fail nome
  case $1 in
    run)  echo "  ⏳ instalando $2..." ;;
    ok)   echo "  ✔ $2 ok" ;;
    skip) echo "  ↷ $2 já instalado" ;;
    fail) echo "  ✖ $2 erro (veja a saída acima)" ;;
  esac
}

# curl | bash: o stdin é o próprio script, então o teclado vem de /dev/tty
wait_enter() { { : </dev/tty; } 2>/dev/null || return 1; read -r _ </dev/tty; }

need() {  # need cmd "o que é" "como instalar"
  has "$1" && return
  echo "  ✖ falta $1: $2"
  echo "    como instalar: $3"
  echo "    Instale em outro terminal e pressione Enter para continuar..."
  wait_enter || echo "    sem terminal interativo"
  export PATH="$HOME/.local/bin:$PATH"; hash -r
  has "$1" || { echo "  ✖ $1 não encontrado. Instale e rode o script de novo."; exit 1; }
}

refresh() { PL=$(claude plugin list --json 2>/dev/null || true); }
plugin_installed() { [[ $PL == *"\"$1\""* ]]; }

market() {  # market nome repo: adiciona o marketplace só se faltar
  local ml; ml=$(claude plugin marketplace list --json 2>/dev/null || true)
  [[ $ml == *"\"$1\""* ]] || claude plugin marketplace add "$2"
}
add_plugin() { market "$1" "$2"; claude plugin install "$3"; }  # add_plugin market repo id

run_step() {  # run_step i nome "check" "install" (comandos com argumentos, sem aspas)
  bar "$1" "$2"
  if $3; then status skip "$2"; SKIP+=("$2"); return; fi
  status run "$2"
  # errexit é ignorado dentro de if/&&/||: roda isolado num subshell com set -e próprio
  set +e; ( set -e; $4 ) </dev/null; local rc=$?; set -e
  if (( rc == 0 )); then status ok "$2"; OK+=("$2"); else status fail "$2"; FAIL+=("$2"); fi
  refresh
}

backup() {  # cópia com data: já pode existir um settings.json.bak de outra origem
  local f="$HOME/.claude/settings.json"
  if [[ -f $f ]]; then
    local b; b="$f.bak-$(date +%Y%m%d-%H%M%S)"
    cp "$f" "$b" && echo "  backup: $b"
  else
    echo "  settings.json não existe, nada a copiar"
  fi
}

rtk_ok() { has rtk && grep -qs "rtk hook" "$HOME/.claude/settings.json"; }
rtk_install() {
  if ! has rtk; then curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh; hash -r; fi
  backup
  rtk init -g --auto-patch
}

npm_g() { if [[ -w $(npm root -g) ]]; then npm i -g "$@"; else sudo npm i -g "$@"; fi; }  # node do apt precisa de sudo no -g

hallmark_hook() {  # roda sempre: o hook guarda o caminho da versão do plugin, que muda a cada update
  local dir
  dir=$(node -p 'require(process.env.HOME + "/.claude/plugins/installed_plugins.json").plugins["hallmark@hallmark"][0].installPath')
  node "$dir/hallmark/scripts/install-hook.mjs" --global  # sem --global grava em settings do projeto
  [[ -d $(npm root -g)/puppeteer-core ]] || npm_g puppeteer-core ||
    echo "  ⚠ puppeteer-core não instalou (opcional: só a checagem renderizada do Hallmark precisa)"
}
hallmark_install() { add_plugin hallmark Nutlope/hallmark hallmark@hallmark; hallmark_hook; }

graphify_ok() { has graphify && [[ -f $HOME/.claude/skills/graphify/SKILL.md ]]; }
graphify_install() {
  if ! has graphify; then pipx install graphifyy; hash -r; fi
  graphify install
}

line() {  # line "rótulo" itens...: só imprime se houver itens
  (( $# > 1 )) || return 0
  local s; printf -v s '%s, ' "${@:2}"
  echo "  $1 ${s%, }"
}

summary() {
  echo
  echo "Resumo: ${#OK[@]} instalados, ${#SKIP[@]} pulados, ${#FAIL[@]} falhas"
  line "✔ instalados:" "${OK[@]}"
  line "↷ pulados:" "${SKIP[@]}"
  line "✖ falhas:" "${FAIL[@]}"
  echo "⚠ Reinicie o Claude Code (feche e abra de novo) para carregar plugins e o hook do rtk."
}

main() {
  echo "my-plugins: 7 ferramentas para o Claude Code"
  echo "Etapas: 1 Pré-requisitos · 2 ponytail · 3 caveman · 4 superpowers · 5 code-review · 6 rtk · 7 graphify · 8 hallmark"

  bar 1 "Pré-requisitos"
  local pk=() novo_pipx=0 c v
  has git     || pk+=(git)
  has curl    || pk+=(curl)
  has node    || pk+=(nodejs npm)
  has python3 || pk+=(python3)
  has pipx    || { pk+=(pipx); novo_pipx=1; }
  if (( ${#pk[@]} )); then
    echo "  ⏳ instalando com apt: ${pk[*]} (o sudo pede a senha)..."
    sudo apt-get install -y "${pk[@]}" </dev/null || true  # a checagem abaixo diz o que faltou
    hash -r
    if (( novo_pipx )) && has pipx; then pipx ensurepath; fi
  fi
  for c in git curl node python3 pipx; do
    has "$c" || { echo "  ✖ $c não encontrado (o apt não conseguiu instalar). Instale à mão e rode o script de novo."; exit 1; }
  done
  v=$(node -v); v=${v#v}
  (( ${v%%.*} >= 22 )) || { echo "  ✖ node $v é antigo; instale o Node 22+ (ex.: nvm: https://github.com/nvm-sh/nvm, depois \`nvm install --lts\`) e rode de novo"; exit 1; }
  need claude "o Claude Code (CLI)" "curl -fsSL https://claude.ai/install.sh | bash"
  echo "  ✔ pré-requisitos ok"

  local official="claude-plugins-official anthropics/claude-plugins-official"
  refresh
  run_step 2 ponytail    "plugin_installed ponytail@ponytail" "add_plugin ponytail DietrichGebert/ponytail ponytail@ponytail"
  run_step 3 caveman     "plugin_installed caveman@caveman"   "add_plugin caveman JuliusBrussee/caveman caveman@caveman"
  # o marketplace oficial fixa a v7.0.0 por sha; o do autor não tem pin (pega a última)
  run_step 4 superpowers "plugin_installed superpowers@superpowers-marketplace" "add_plugin superpowers-marketplace obra/superpowers-marketplace superpowers@superpowers-marketplace"
  run_step 5 code-review "plugin_installed code-review@claude-plugins-official" "add_plugin $official code-review@claude-plugins-official"

  run_step 6 rtk rtk_ok rtk_install
  # telemetria off mesmo quando o rtk já existia
  if has rtk; then rtk telemetry disable </dev/null >/dev/null 2>&1 || true; fi

  run_step 7 graphify graphify_ok graphify_install
  run_step 8 hallmark    "plugin_installed hallmark@hallmark" hallmark_install
  summary
  (( ${#FAIL[@]} == 0 )) || exit 1
}

# main no fim: um download parcial via curl | bash não executa nada
main "$@"
