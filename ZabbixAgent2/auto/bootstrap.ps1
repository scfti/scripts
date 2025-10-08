<#
  SCF Ti � Zabbix Bootstrap (GitHub-driven + Menu)
  Fonte: https://github.com/scfti/scripts/tree/main/ZabbixAgent2
  Fluxo: Eleva (UAC) ? baixa scripts do GitHub ? cacheia ? menu (instalar|alterar_conf) ? executa
#>

[CmdletBinding()]
param(
  [ValidateSet('install','config')]
  [string]$Action,  # se omitido, exibe menu
  [string]$CacheDir = "$env:ProgramData\SCFTi\ZabbixAgent\scripts"
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Eleva��o autom�tica (UAC) com bloqueio ---
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSCommandPath`"")
  if ($PSBoundParameters.ContainsKey('Action')) { $args += @('-Action', $Action) }
  $args += @('-CacheDir', "`"$CacheDir`"")
  Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Verb RunAs -Wait
  exit $LASTEXITCODE
}

# --- Endpoints GitHub (fixos ao seu reposit�rio/pasta) ---
$BaseRaw = 'https://raw.githubusercontent.com/scfti/scripts/main/ZabbixAgent2'
$Files = @{
  install = 'zabbix.ps1'
  config  = 'Alterar_conf.ps1'
}

# --- Infra de cache idempotente ---
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null

function Get-And-Cache {
  param([Parameter(Mandatory)][string]$RemoteName)
  $url  = "$BaseRaw/$RemoteName"
  $dest = Join-Path $CacheDir $RemoteName
  $tmp  = "$dest.download"

  try {
    Write-Host "Baixando $RemoteName..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing -TimeoutSec 60
    Move-Item -Force $tmp $dest
    Write-Host "Atualizado: $dest" -ForegroundColor Green
  } catch {
    if (Test-Path $dest) {
      Write-Host "Falha no download; usando cache local: $dest" -ForegroundColor Yellow
    } else {
      throw "Sem internet e sem cache para $RemoteName. Erro: $($_.Exception.Message)"
    }
  }
  return $dest
}

# --- Menu (se -Action n�o for passado) ---
function Show-Menu {
  Write-Host ""
  Write-Host "===== SCF Ti � Zabbix Agent 2 Bootstrap =====" -ForegroundColor Cyan
  Write-Host "[1] Instalar agente (zabbix.ps1 - GitHub)"
  Write-Host "[2] Alterar configura��o (Alterar_conf.ps1 - GitHub)"
  do {
    $sel = Read-Host "Selecione (1/2) [1]"
    if ([string]::IsNullOrWhiteSpace($sel)) { $sel = '1' }
  } until ($sel -in @('1','2'))
  switch ($sel) {
    '1' { return 'install' }
    '2' { return 'config'  }
  }
}

if (-not $Action) { $Action = Show-Menu }

# --- Pr�-aquecimento de cache (sempre atualiza os dois) ---
$installPath = Get-And-Cache -RemoteName $Files.install
$configPath  = Get-And-Cache -RemoteName $Files.config

# --- Sele��o do alvo + execu��o ---
$target = if ($Action -eq 'install') { $installPath } else { $configPath }
if (-not (Test-Path $target)) { throw "Script alvo n�o encontrado: $target" }

Write-Host "`nExecutando: $target" -ForegroundColor Yellow
& $target
exit $LASTEXITCODE
