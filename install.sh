#!/usr/bin/env bash
# my-plugins: instala 9 ferramentas no Claude Code (Ubuntu).
# Uso: curl -fsSL <url>/install.sh | bash   (pode rodar de novo: pula o que já existe)
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

N=11
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

graphify_ok() { has graphify && [[ -f $HOME/.claude/skills/graphify/SKILL.md ]]; }
graphify_install() {
  if ! has graphify; then pipx install graphifyy; hash -r; fi
  graphify install
}

design_ok() { [[ -f $HOME/.claude/skills/design-better/SKILL.md ]]; }
design_install() { DISABLE_TELEMETRY=1 npx -y skills add buildgreatproducts/builder-os --skill design-better -g --agent claude-code -y; }

playwright_ok() { has playwright-cli && [[ -f $HOME/.claude/skills/playwright-cli/SKILL.md ]]; }
playwright_install() {
  if ! has playwright-cli; then npm_g @playwright/cli@latest; hash -r; fi
  playwright-cli install --skills --global
}

ajustes() {  # tudo idempotente; imprime ✔ (mudou) ou ↷ (já estava)
  local id ml pl="$HOME/.config/rtk/pipeline.toml"
  # o que versões antigas do script instalavam
  for id in ux-design@wondelai-skills superpowers@claude-plugins-official; do
    if plugin_installed "$id"; then
      claude plugin uninstall "$id"
      echo "  ✔ $id removido"
    else
      echo "  ↷ $id já estava removido"
    fi
  done
  ml=$(claude plugin marketplace list --json 2>/dev/null || true)
  if [[ $ml == *'"wondelai-skills"'* ]]; then
    claude plugin marketplace remove wondelai-skills
    echo "  ✔ marketplace wondelai-skills removido"
  else
    echo "  ↷ marketplace wondelai-skills já estava removido"
  fi

  # caveman sem reforço a cada prompt, autoUpdate dos plugins e linha de design no CLAUDE.md (JS ASCII: igual no install.ps1)
  node - <<'JS'
const fs = require('fs'), path = require('path'), home = require('os').homedir();
const d = new Date(), z = n => String(n).padStart(2, '0');
const stamp = '' + d.getFullYear() + z(d.getMonth() + 1) + z(d.getDate()) + '-' + z(d.getHours()) + z(d.getMinutes()) + z(d.getSeconds());
const cav = process.platform === 'win32' ? path.join(process.env.APPDATA || path.join(home, 'AppData', 'Roaming'), 'caveman') : path.join(home, '.config', 'caveman');

function edit(file, label, fn) {  // JSON: so grava (com backup) se mudou
  const had = fs.existsSync(file);
  const obj = had ? JSON.parse(fs.readFileSync(file, 'utf8').replace(/^\ufeff/, '')) : {};
  const antes = JSON.stringify(obj);
  fn(obj);
  if (JSON.stringify(obj) === antes) return console.log('  \u21b7 ' + label + ' j\u00e1 estava');
  fs.mkdirSync(path.dirname(file), { recursive: true });
  if (had) fs.copyFileSync(file, file + '.bak-' + stamp);
  fs.writeFileSync(file, JSON.stringify(obj, null, 2) + '\n');
  console.log('  \u2714 ' + label);
}

edit(path.join(cav, 'config.json'), 'caveman sem refor\u00e7o', c => { c.reinforce = false; });
edit(path.join(home, '.claude', 'settings.json'), 'autoUpdate nos marketplaces', s => {
  for (const m of ['ponytail', 'caveman', 'hallmark', 'superpowers-marketplace'])
    if (s.extraKnownMarketplaces && s.extraKnownMarketplaces[m]) s.extraKnownMarketplaces[m].autoUpdate = true;
  s.env = s.env || {};
  s.env.FORCE_AUTOUPDATE_PLUGINS = '1';  // o app desktop liga DISABLE_AUTOUPDATER=1, que pularia o auto-update dos plugins
});

const md = path.join(home, '.claude', 'CLAUDE.md');
const linha = 'Design: o Hallmark \u00e9 o \u00fanico l\u00edder visual (temas prontos); o design-better cuida da UX (heur\u00edsticas numeradas e Laws of UX); n\u00e3o use impeccable, frontend-design nem ui-ux-pro-max.';
const txt = fs.existsSync(md) ? fs.readFileSync(md, 'utf8') : '';
if (txt.includes(linha)) console.log('  \u21b7 linha de design no CLAUDE.md j\u00e1 estava');
else {
  fs.mkdirSync(path.dirname(md), { recursive: true });
  fs.appendFileSync(md, (txt && !txt.endsWith('\n') ? '\n' : '') + linha + '\n');
  console.log('  \u2714 linha de design no CLAUDE.md');
}
JS

  # rtk: git diff / git show / gh pr diff passam inteiros (não sobrescreve um pipeline.toml seu)
  if [[ ! -f $pl ]]; then
    mkdir -p "${pl%/*}"
    cat > "$pl" <<'TOML'
schema_version = 1
[pipeline]
extends = "rtk:default"

[[hook.before_tool.shell]]
name   = "keep-diffs"
when   = { command_matches = "^(git (diff|show)|gh pr diff)\\b" }
action = "passthrough"
TOML
    echo "  ✔ rtk com diffs inteiros (pipeline.toml)"
  elif grep -q keep-diffs "$pl"; then
    echo "  ↷ rtk com diffs inteiros já estava"
  else
    echo "  ⚠ pipeline.toml já existe sem keep-diffs; ajuste à mão"
  fi

  hallmark_hook
  echo "  ✔ hook do Hallmark atualizado"
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
  echo "my-plugins: 9 ferramentas para o Claude Code"
  echo "Etapas: 1 Pré-requisitos · 2 ponytail · 3 caveman · 4 superpowers · 5 code-review · 6 rtk · 7 graphify · 8 hallmark · 9 design-better · 10 playwright-cli · 11 ajustes"

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
  run_step 7 graphify graphify_ok graphify_install
  run_step 8 hallmark    "plugin_installed hallmark@hallmark" "add_plugin hallmark Nutlope/hallmark hallmark@hallmark"
  run_step 9 design-better design_ok design_install
  run_step 10 playwright-cli playwright_ok playwright_install

  # ajustes não contam como instalado/pulado; só a falha aparece no resumo
  bar 11 "ajustes"
  set +e; ( set -e; ajustes ) </dev/null; local rc=$?; set -e
  (( rc == 0 )) || { status fail ajustes; FAIL+=(ajustes); }
  summary
  (( ${#FAIL[@]} == 0 )) || exit 1
}

# main no fim: um download parcial via curl | bash não executa nada
main "$@"
