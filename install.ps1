# my-plugins: instala 9 ferramentas para o Claude Code (Windows PowerShell 5.1 e 7).
# Uso: irm https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.ps1 | iex
# Pode rodar de novo: o que já está instalado é pulado. Só conferir, sem instalar: .\install.ps1 --check
# Tudo dentro de & { }: sob iex, um exit fecharia a janela do usuário.
& {
$ErrorActionPreference = 'Stop'
# $OutputEncoding é a codificação do que vai por pipe para programas nativos (node -): UTF-8 sem BOM
try { $OutputEncoding = [Text.UTF8Encoding]::new($false) } catch {}
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$N = 11
$settings = "$env:USERPROFILE\.claude\settings.json"
$OK = [Collections.Generic.List[string]]::new()
$SKIP = [Collections.Generic.List[string]]::new()
$FAIL = [Collections.Generic.List[string]]::new()
$MISS = [Collections.Generic.List[string]]::new()

function Has($cmd) { [bool](Get-Command $cmd -ErrorAction SilentlyContinue) }

# Comando nativo não lança erro sozinho: confere o código de saída. Nunca redirecionar stderr (lança no PS 5.1).
function Run { & $args[0] $args[1..($args.Count - 1)]; if ($LASTEXITCODE) { throw "$args falhou (código $LASTEXITCODE)" } }

# Recarrega o PATH depois de instalar algo (winget e uv não atualizam o terminal aberto).
function Update-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User') + ";$env:USERPROFILE\.local\bin"
}

function Show-Bar($i, $name) {
  $full = [int][math]::Floor($i * 20 / $N)
  Write-Host ''
  Write-Host ('[' + ([string][char]0x2588) * $full + ([string][char]0x2591) * (20 - $full) + "] Etapa $i/$N  $name")
}

function Write-Status($kind, $text) {
  $icon = @{ wait = 0x23F3; ok = 0x2714; skip = 0x21B7; fail = 0x2716; warn = 0x26A0 }[$kind]
  Write-Host "  $([char]$icon) $text"
}

# Lê uma linha do usuário. Sem terminal interativo devolve $null (Read-Host lança erro nesse caso).
function Read-Line($prompt) {
  if ([Console]::IsInputRedirected) { return $null }
  Write-Host -NoNewline $prompt
  try { Read-Host } catch { $null }
}

# Pré-requisito: explica o que falta, espera o usuário instalar e confere de novo.
function Need($cmd, $what, $how) {
  if (-not (Has $cmd)) {
    Write-Status warn "$cmd não encontrado: $what"
    Write-Host "    Como instalar: $how"
    if ($null -ne (Read-Line '    Instale em outro terminal e pressione Enter para continuar...')) { Update-Path }
  }
  if (Has $cmd) { Write-Status ok "$cmd ok"; return $true }
  Write-Status fail "$cmd não encontrado. Instale e rode o script de novo."
  $false
}

function Test-Plugin($id) { (claude plugin list --json | Out-String).Contains("`"$id`"") }

function Test-Market($name) { (claude plugin marketplace list --json | Out-String).Contains("`"$name`"") }

function Add-Market($name, $repo) { if (-not (Test-Market $name)) { Run claude plugin marketplace add $repo } }

# Uma etapa: pula se $check passa; senão instala. Erro numa ferramenta é anotado e o script segue.
function Invoke-Step($i, $name, $check, $install) {
  Show-Bar $i $name
  if (& $check) { Write-Status skip "$name já instalado"; $SKIP.Add($name); return }
  Write-Status wait "instalando $name..."
  try { & $install; Write-Status ok "$name ok"; $OK.Add($name) }
  catch { Write-Host "  $_"; Write-Status fail "$name erro (veja a saída acima)"; $FAIL.Add($name) }
}

function Install-Plugin($i, $name, $market, $repo) {
  $id = "$name@$market"
  Invoke-Step $i $name { Test-Plugin $id } { Add-Market $market $repo; Run claude plugin install $id }
}

function Test-Settings($pattern) { (Test-Path $settings) -and ((Get-Content $settings -Raw -Encoding UTF8) -match $pattern) }

function Test-Rtk { (Has rtk) -and (Test-Settings 'rtk(\.exe)? hook') }

# Cópia com data e hora: settings.json.bak pode já existir com outra origem.
function Backup-Settings {
  if (-not (Test-Path $settings)) { Write-Host '  settings.json não existe, nada a copiar'; return }
  $backup = "$settings.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $settings $backup
  Write-Host "  backup: $backup"
}

function Install-Rtk {
  if (-not (Has rtk)) {
    Run winget install -e --id rtk-ai.rtk --accept-source-agreements --accept-package-agreements
    Update-Path
  }
  Backup-Settings
  Run rtk init -g --auto-patch
}

function Test-Graphify { (Has graphify) -and (Test-Path "$env:USERPROFILE\.claude\skills\graphify\SKILL.md") }

function Install-Graphify {
  if (-not (Has graphify)) { Run uv tool install graphifyy; Update-Path }
  Run graphify install
}

# Hook de edição do Hallmark no settings.json global (sem --global ele escreve no projeto). Idempotente:
# roda sempre, porque atualiza o caminho do hook, que leva a versão do plugin.
function Install-HallmarkHook {
  $f = "$env:USERPROFILE\.claude\plugins\installed_plugins.json"
  $entry = $null
  if (Test-Path $f) { $entry = (Get-Content $f -Raw -Encoding UTF8 | ConvertFrom-Json).plugins.'hallmark@hallmark' }
  if (-not $entry) { Write-Status warn 'hallmark não instalado: hook de edição pulado'; return }
  $dir = @($entry)[0].installPath
  Run node (Join-Path $dir 'hallmark\scripts\install-hook.mjs') --global
  Write-Status ok 'hook do Hallmark atualizado'
  # opcional: só a checagem renderizada do Hallmark usa o puppeteer-core
  try {
    if (Test-Path (Join-Path (npm.cmd root -g) 'puppeteer-core')) { Write-Status skip 'puppeteer-core já estava' } else {
      Run npm.cmd i -g puppeteer-core
      Write-Status ok 'puppeteer-core'
    }
  } catch { Write-Status warn 'puppeteer-core não instalou (opcional: só a checagem renderizada do Hallmark precisa)' }
}

# Precisa de Node 22.20+ e git. O CLI skills manda telemetria: desligada só durante esta chamada.
function Install-DesignBetter {
  $before = $env:DISABLE_TELEMETRY
  $env:DISABLE_TELEMETRY = '1'
  try { Run npx.cmd -y skills add buildgreatproducts/builder-os --skill design-better -g --agent claude-code -y }
  finally { $env:DISABLE_TELEMETRY = $before }
}

function Test-Playwright { (Has playwright-cli) -and (Test-Path "$env:USERPROFILE\.claude\skills\playwright-cli\SKILL.md") }

# npm.cmd/npx.cmd: os atalhos .ps1 do npm são bloqueados pela política de execução padrão do Windows
function Install-Playwright {
  if (-not (Has playwright-cli)) { Run npm.cmd i -g '@playwright/cli@latest'; Update-Path }
  Run playwright-cli.cmd install --skills --global
}

# JS em ASCII puro (acentos em \u escapes), igual ao do install.sh. Os terminadores '@ ficam na coluna 0.
$ajustesJs = @'
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
'@

$pipelineToml = @'
schema_version = 1
[pipeline]
extends = "rtk:default"

[[hook.before_tool.shell]]
name   = "keep-diffs"
when   = { command_matches = "^(git (diff|show)|gh pr diff)\\b" }
action = "passthrough"
'@

# Ajustes: tudo idempotente, imprime se mudou algo ou se já estava. Não contam como instalado/pulado.
function Invoke-Ajustes {
  # o que versões antigas do script instalavam
  foreach ($id in 'ux-design@wondelai-skills', 'superpowers@claude-plugins-official') {
    if (Test-Plugin $id) {
      Run claude plugin uninstall $id
      Write-Status ok "$id removido"
    } else { Write-Status skip "$id já estava removido" }
  }
  if (Test-Market 'wondelai-skills') {
    Run claude plugin marketplace remove wondelai-skills
    Write-Status ok 'marketplace wondelai-skills removido'
  } else { Write-Status skip 'marketplace wondelai-skills já estava removido' }

  # caveman sem reforço a cada prompt, autoUpdate dos plugins e linha de design no CLAUDE.md
  $ajustesJs | node -
  if ($LASTEXITCODE) { throw "node falhou (código $LASTEXITCODE)" }

  # rtk: git diff / git show / gh pr diff passam inteiros (não sobrescreve um pipeline.toml seu)
  $toml = "$env:APPDATA\rtk\pipeline.toml"
  if (-not (Test-Path $toml)) {
    $null = New-Item -ItemType Directory -Force (Split-Path $toml)
    [IO.File]::WriteAllText($toml, $pipelineToml + "`n", [Text.UTF8Encoding]::new($false))
    Write-Status ok 'rtk com diffs inteiros (pipeline.toml)'
  } elseif ((Get-Content $toml -Raw) -match 'keep-diffs') {
    Write-Status skip 'rtk com diffs inteiros já estava'
  } else { Write-Status warn 'pipeline.toml já existe sem keep-diffs; ajuste à mão' }

  Install-HallmarkHook
}

# Verificador: só lê. Roda no fim da instalação e sozinho com .\install.ps1 --check
function Check($name, $pass) {
  if ($pass) { Write-Host "  OK     $name" } else { Write-Host "  FALTA  $name"; $MISS.Add($name) }
}

# id -> ligado, de `claude plugin list --json` (ConvertFrom-Json devolve o array inteiro no PS 5.1: por isso foreach, sem pipe)
function Get-Plugins {
  $h = @{}
  try {
    $list = (claude plugin list --json | Out-String) | ConvertFrom-Json
    foreach ($p in $list) { $h[$p.id] = [bool]$p.enabled }
  } catch {}
  $h
}

function Read-Json($file) { try { Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $null } }

function Test-Caveman { $c = Read-Json "$env:APPDATA\caveman\config.json"; $c -and ($c.reinforce -eq $false) }

function Test-AutoUpdate {
  $mk = (Read-Json $settings).extraKnownMarketplaces
  $names = 'caveman', 'hallmark', 'superpowers-marketplace'
  if ($ponytail) { $names = @('ponytail') + $names }
  foreach ($m in $names) { if ($mk.$m.autoUpdate -ne $true) { return $false } }
  $true
}

# o pipeline.toml dos ajustes faz git diff e gh pr diff passarem inteiros ("action passthrough" na saída)
function Test-RtkDiffs {
  if (-not (Has rtk)) { return $false }
  foreach ($c in 'git diff', 'gh pr diff 1') {
    if (-not ((rtk pipeline explain --agent claude-code --tool Bash --command $c | Out-String) -match 'action passthrough')) { return $false }
  }
  $true
}

function Test-DesignLine {
  $md = "$env:USERPROFILE\.claude\CLAUDE.md"
  $line = [regex]::Unescape('Design: o Hallmark \u00e9 o \u00fanico l\u00edder visual (temas prontos); o design-better cuida da UX (heur\u00edsticas numeradas e Laws of UX); n\u00e3o use impeccable, frontend-design nem ui-ux-pro-max.')
  (Test-Path $md) -and ((Get-Content $md -Raw -Encoding UTF8) -match [regex]::Escape($line))
}

function Verificar {
  $MISS.Clear()
  Write-Host ''
  Write-Host 'Verificação'
  $plugins = Get-Plugins
  if ($ponytail) { Check 'plugin ponytail@ponytail' ($plugins['ponytail@ponytail'] -eq $true) } else {
    Write-Host '  PULADO  ponytail@ponytail (escolha do usuário)'
  }
  foreach ($id in 'caveman@caveman', 'superpowers@superpowers-marketplace', 'code-review@claude-plugins-official', 'hallmark@hallmark') {
    Check "plugin $id" ($plugins[$id] -eq $true)
  }
  Check 'ux-design (wondelai) removido' (-not $plugins.ContainsKey('ux-design@wondelai-skills'))
  Check 'superpowers antigo removido' (-not $plugins.ContainsKey('superpowers@claude-plugins-official'))
  Check 'hook do rtk no settings.json' (Test-Settings 'rtk(\.exe)? hook')
  Check 'rtk diffs inteiros' (Test-RtkDiffs)
  Check 'hook do Hallmark no settings.json' (Test-Settings 'lint-hook\.mjs')
  Check 'design-better' (Test-Path "$env:USERPROFILE\.claude\skills\design-better\SKILL.md")
  Check 'skill playwright-cli' (Test-Path "$env:USERPROFILE\.claude\skills\playwright-cli\SKILL.md")
  Check 'caveman sem reforço' (Test-Caveman)
  Check 'autoUpdate nos marketplaces' (Test-AutoUpdate)
  Check 'linha de design no CLAUDE.md' (Test-DesignLine)
  foreach ($c in 'node', 'git', 'graphify', 'playwright-cli', 'rtk') { Check "no PATH: $c" (Has $c) }
  Write-Host ''
  if ($MISS.Count) {
    Write-Status fail "verificador: $($MISS.Count) itens faltando"
    $global:LASTEXITCODE = 1
  } else { Write-Status ok 'Tudo OK' }
}

function Show-Summary {
  Write-Host ''
  Write-Host "Resumo: $($OK.Count) instalados, $($SKIP.Count) pulados, $($FAIL.Count) falhas"
  if ($OK.Count) { Write-Status ok "instalados: $($OK -join ', ')" }
  if ($SKIP.Count) { Write-Status skip "pulados: $($SKIP -join ', ')" }
  if ($FAIL.Count) { Write-Status fail "falhas: $($FAIL -join ', ')" }
  Write-Status warn 'Reinicie o Claude Code (feche e abra de novo) e reabra o terminal para carregar plugins e o hook do rtk.'
}

# --check (só rodando como arquivo; sob iex $args vem vazio): confere sem instalar nada
if ($args -contains '--check') {
  $ponytail = (Has claude) -and (Test-Plugin 'ponytail@ponytail')  # sem prompt: ponytail ausente conta como pulado
  Verificar
  return
}

Write-Host 'my-plugins: 9 ferramentas para o Claude Code'
Write-Host ('Etapas: ' + ('1 Pré-requisitos', '2 ponytail', '3 caveman', '4 superpowers', '5 code-review', '6 rtk', '7 graphify', '8 hallmark', '9 design-better', '10 playwright-cli', '11 ajustes' -join " $([char]0x00B7) "))

Show-Bar 1 'Pré-requisitos'
if (-not (Need claude 'o Claude Code' 'irm https://claude.ai/install.ps1 | iex')) { return }
if (-not (Need winget 'o gerenciador de pacotes do Windows' 'instale o "App Installer" da Microsoft Store')) { return }
if (-not (Need git 'os marketplaces de plugins são repositórios git' 'winget install -e --id Git.Git')) { return }
if (-not (Need node 'roda os hooks e o instalador de skills' 'winget install -e --id OpenJS.NodeJS.LTS')) { return }
$nodeVer = (node -v) -replace '^v', ''
if ([int]($nodeVer.Split('.')[0]) -lt 22) {
  Write-Status fail "node $nodeVer é antigo; instale o Node 22+ (winget install -e --id OpenJS.NodeJS.LTS) e rode de novo"
  return
}
if (-not (Need uv 'o gerenciador Python que instala o graphify' 'winget install -e --id astral-sh.uv')) { return }

$ponytail = Test-Plugin 'ponytail@ponytail'
if (-not $ponytail) {
  $answer = Read-Line "  $([char]0x26A0) ponytail tem bug conhecido no Windows: trava cada mensagem por alguns segundos. Instalar mesmo assim? [s/N] "
  if ($null -eq $answer) { Write-Host '    sem terminal interativo: ponytail pulado' }
  $ponytail = $answer -match '^s'
}

if ($ponytail) { Install-Plugin 2 ponytail ponytail DietrichGebert/ponytail } else {
  Show-Bar 2 ponytail; Write-Status skip 'ponytail pulado (escolha do usuário)'; $SKIP.Add('ponytail')
}
Install-Plugin 3 caveman caveman JuliusBrussee/caveman
# o marketplace oficial fixa o superpowers na v7.0.0 por sha; o do autor não fixa (última versão)
Install-Plugin 4 superpowers superpowers-marketplace obra/superpowers-marketplace
Install-Plugin 5 code-review claude-plugins-official anthropics/claude-plugins-official

Invoke-Step 6 rtk { Test-Rtk } { Install-Rtk }
Invoke-Step 7 graphify { Test-Graphify } { Install-Graphify }
Install-Plugin 8 hallmark hallmark Nutlope/hallmark
Invoke-Step 9 design-better { Test-Path "$env:USERPROFILE\.claude\skills\design-better\SKILL.md" } { Install-DesignBetter }
Invoke-Step 10 playwright-cli { Test-Playwright } { Install-Playwright }

Show-Bar 11 'ajustes'
try { Invoke-Ajustes } catch { Write-Host "  $_"; Write-Status fail 'ajustes erro (veja a saída acima)'; $FAIL.Add('ajustes') }

Show-Summary
Verificar
} @args
