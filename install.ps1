# Instala 8 ferramentas do Claude Code (Windows, PowerShell). Pula o que já existe.
# AVISO: ponytail tem bug conhecido no Windows (trava cada mensagem por alguns segundos).
$ErrorActionPreference = 'Stop'
function Has($c) { [bool](Get-Command $c -ErrorAction SilentlyContinue) }
function Plug($p, $m) { if (-not ((claude plugin list) -match "$p@")) { claude plugin install "$p@$m" } }

if (-not (Has claude)) { throw 'instale o Claude Code antes' }
if (-not (Has uv)) { winget install -e --id astral-sh.uv --accept-source-agreements --accept-package-agreements; $env:Path += ";$env:USERPROFILE\.local\bin" }

# plugins de marketplace
claude plugin marketplace add DietrichGebert/ponytail
claude plugin marketplace add JuliusBrussee/caveman
claude plugin marketplace add anthropics/claude-plugins-official
Plug ponytail ponytail
Plug caveman caveman
foreach ($p in 'superpowers','code-review','context7') { Plug $p claude-plugins-official }

# rtk: winget + hook global, sem perguntas, telemetria off
if (-not (Has rtk)) { winget install -e --id rtk-ai.rtk --accept-source-agreements --accept-package-agreements }
rtk init -g --auto-patch
rtk telemetry disable

# headroom e graphify (uv)
if (-not (Has headroom)) { uv tool install --python 3.13 "headroom-ai[all]"; headroom mcp install --agent claude }
if (-not (Has graphify)) { uv tool install graphifyy; graphify install }

Write-Host 'ok. reabra o terminal e o Claude Code.'
