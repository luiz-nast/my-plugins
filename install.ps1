# my-plugins: instala 6 ferramentas de economia de tokens no Claude Code (Windows PowerShell 5.1 e 7).
# Uso: irm https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.ps1 | iex
# Pode rodar de novo: o que já está instalado é pulado.
# Tudo dentro de & { }: sob iex, um exit fecharia a janela do usuário.
& {
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8; $OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$N = 7
$settings = "$env:USERPROFILE\.claude\settings.json"
$OK = [Collections.Generic.List[string]]::new()
$SKIP = [Collections.Generic.List[string]]::new()
$FAIL = [Collections.Generic.List[string]]::new()

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

function Add-Market($name, $repo) {
  if (-not (claude plugin marketplace list --json | Out-String).Contains("`"$name`"")) { Run claude plugin marketplace add $repo }
}

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

function Test-Rtk { (Has rtk) -and (Test-Path $settings) -and ((Get-Content $settings -Raw) -match 'rtk(\.exe)? hook') }

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
  Run rtk telemetry disable
}

Write-Host 'my-plugins: 6 ferramentas de economia de tokens para o Claude Code'
Write-Host ('Etapas: ' + ('1 Pré-requisitos', '2 ponytail', '3 caveman', '4 superpowers', '5 code-review', '6 rtk', '7 graphify' -join " $([char]0x00B7) "))

Show-Bar 1 'Pré-requisitos'
if (-not (Need claude 'o Claude Code' 'irm https://claude.ai/install.ps1 | iex')) { return }
if (-not (Need winget 'o gerenciador de pacotes do Windows' 'instale o "App Installer" da Microsoft Store')) { return }
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
Install-Plugin 4 superpowers claude-plugins-official anthropics/claude-plugins-official
Install-Plugin 5 code-review claude-plugins-official anthropics/claude-plugins-official

Invoke-Step 6 rtk { Test-Rtk } { Install-Rtk }
if ($SKIP.Contains('rtk')) { $null = rtk telemetry disable }
}
