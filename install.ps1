# my-plugins: instala 6 ferramentas de economia de tokens no Claude Code (Windows PowerShell 5.1 e 7).
# Uso: irm https://raw.githubusercontent.com/luiz-nast/my-plugins/main/install.ps1 | iex
# Pode rodar de novo: o que já está instalado é pulado.
# Tudo dentro de & { }: sob iex, um exit fecharia a janela do usuário.
& {
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8; $OutputEncoding = [Text.Encoding]::UTF8 } catch {}

$N = 7
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

Write-Host 'my-plugins: 6 ferramentas de economia de tokens para o Claude Code'
Write-Host ('Etapas: ' + ('1 Pré-requisitos', '2 ponytail', '3 caveman', '4 superpowers', '5 code-review', '6 rtk', '7 graphify' -join " $([char]0x00B7) "))
}
