#!/usr/bin/env bash
# my-plugins: instala 6 ferramentas de economia de tokens no Claude Code (Ubuntu).
# Uso: curl -fsSL <url>/install.sh | bash   (pode rodar de novo: pula o que já existe)
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

N=7
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

main() {
  echo "my-plugins: 6 ferramentas de economia de tokens para o Claude Code"
  echo "Etapas: 1 Pré-requisitos · 2 ponytail · 3 caveman · 4 superpowers · 5 code-review · 6 rtk · 7 graphify"

  bar 1 "Pré-requisitos"
  need claude "o Claude Code (CLI)" "curl -fsSL https://claude.ai/install.sh | bash"
  need curl "baixa arquivos da internet" "sudo apt install -y curl"
  need git "os marketplaces de plugins são repositórios git" "sudo apt install -y git"
  need pipx "instala o graphify (Python) isolado" "sudo apt install -y pipx && pipx ensurepath"
  echo "  ✔ pré-requisitos ok"

  local official="claude-plugins-official anthropics/claude-plugins-official"
  refresh
  run_step 2 ponytail    "plugin_installed ponytail@ponytail" "add_plugin ponytail DietrichGebert/ponytail ponytail@ponytail"
  run_step 3 caveman     "plugin_installed caveman@caveman"   "add_plugin caveman JuliusBrussee/caveman caveman@caveman"
  run_step 4 superpowers "plugin_installed superpowers@claude-plugins-official" "add_plugin $official superpowers@claude-plugins-official"
  run_step 5 code-review "plugin_installed code-review@claude-plugins-official" "add_plugin $official code-review@claude-plugins-official"
}

# main no fim: um download parcial via curl | bash não executa nada
main "$@"
