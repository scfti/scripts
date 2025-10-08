<#
  Zabbix Agent 2 � Config Orchestrator (ANSI-safe / unified Server-ServerActive)
  Autor: SCF Ti
  Uso:
    .\Set-ZbxAgent2Conf.ps1
    .\Set-ZbxAgent2Conf.ps1 -Path "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
#>

[CmdletBinding()]
param(
  [string]$Path
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Read-WithDefault {
  param(
    [Parameter(Mandatory)][string]$Prompt,
    [Parameter(Mandatory)][string]$Default
  )
  $ans = Read-Host "$Prompt (Enter para manter: $Default)"
  if ([string]::IsNullOrWhiteSpace($ans)) { return $Default }
  return $ans.Trim().Trim('"')
}

function Detect-ConfPath {
  param([string]$Hint)
  if ($Hint -and (Test-Path -LiteralPath $Hint)) { return (Resolve-Path -LiteralPath $Hint).Path }
  $candidates = @(
    "$env:ProgramFiles\Zabbix Agent 2\zabbix_agent2.conf",
    "${env:ProgramFiles(x86)}\Zabbix Agent 2\zabbix_agent2.conf",
    "$env:ProgramData\Zabbix\zabbix_agent2.conf"
  )
  foreach ($p in $candidates) {
    if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
  }
  throw "zabbix_agent2.conf n�o encontrado. Informe via par�metro -Path."
}

function Get-CurrentValue {
  param([string[]]$Lines,[string]$Key)
  $pat = "^\s*$Key\s*=\s*([^#`r`n]*)"
  $val = $null
  for ($i=0; $i -lt $Lines.Count; $i++) {
    if ($Lines[$i] -imatch $pat) {
      $m = [regex]::Match($Lines[$i], $pat, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      if ($m.Success) { $val = $m.Groups[1].Value.Trim() }
    }
  }
  return $val
}

function Update-ConfigKey {
  param([string[]]$Lines,[string]$Key,[string]$NewValue)
  # 1) Atualiza linhas ativas preservando espa�os e coment�rios � direita
  $pattern = "^(?<pre>\s*$Key\s*=\s*)(?<val>[^#`r`n]*)(?<ws>\s*)(?<cmt>#.*)?$"
  $updated = $false
  for ($i=0; $i -lt $Lines.Count; $i++) {
    $m = [regex]::Match($Lines[$i], $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    if ($m.Success) {
      $pre = $m.Groups['pre'].Value
      $ws  = $m.Groups['ws'].Value
      $cmt = $m.Groups['cmt'].Value
      $Lines[$i] = "$pre$NewValue$ws$cmt"
      $updated = $true
    }
  }
  # 2) Se n�o encontrou ativo, tenta �descomentar� preservando layout
  if (-not $updated) {
    $cp = "^(?<hash>\s*#\s*)?(?<pre>\s*$Key\s*=\s*)(?<val>[^#`r`n]*)(?<ws>\s*)(?<cmt>#.*)?$"
    for ($i=0; $i -lt $Lines.Count; $i++) {
      $m2 = [regex]::Match($Lines[$i], $cp, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      if ($m2.Success) {
        $pre = $m2.Groups['pre'].Value
        $ws  = $m2.Groups['ws'].Value
        $cmt = $m2.Groups['cmt'].Value
        $Lines[$i] = "$pre$NewValue$ws$cmt"
        $updated = $true
        break
      }
    }
  }
  # 3) Se n�o existir nem comentado, adiciona ao final no padr�o �key=value�
  if (-not $updated) {
    $Lines += "$Key=$NewValue"
  }
  return ,$Lines
}

# --- Execu��o ---
$confPath = Detect-ConfPath -Hint $Path
Write-Host "Alvo: $confPath" -ForegroundColor Cyan

# Backup transacional
$bak = "$confPath.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
Copy-Item -LiteralPath $confPath -Destination $bak -Force
Write-Host "Backup gerado: $bak" -ForegroundColor DarkGray

# Carregar linhas preservando layout
$lines = Get-Content -LiteralPath $confPath

# Ler valores atuais
$curServer       = Get-CurrentValue -Lines $lines -Key 'Server'
$curServerActive = Get-CurrentValue -Lines $lines -Key 'ServerActive'
$curHostname     = Get-CurrentValue -Lines $lines -Key 'Hostname'

if (-not $curHostname)     { $curHostname = $env:COMPUTERNAME }
# Default consolidado para uma �nica pergunta
$defaultServerUnified = if ($curServerActive) { $curServerActive } elseif ($curServer) { $curServer } else { '10.0.0.1' }

# Prompt �nico para Server/ServerActive + Hostname
$inServerUnified = Read-WithDefault -Prompt 'Endere�o do Server/ServerActive (mesmo valor)' -Default $defaultServerUnified
$inHostname      = Read-WithDefault -Prompt 'Hostname'                                   -Default $curHostname

# Normaliza��o
$inServerUnified = $inServerUnified.Trim().Trim('"')
$inHostname      = $inHostname.Trim().Trim('"')

# Aplicar mudan�as
$lines = Update-ConfigKey -Lines $lines -Key 'Server'       -NewValue $inServerUnified
$lines = Update-ConfigKey -Lines $lines -Key 'ServerActive' -NewValue $inServerUnified
$lines = Update-ConfigKey -Lines $lines -Key 'Hostname'     -NewValue $inHostname

# Persist�ncia em ANSI (sem BOM) � compat�vel com o parser do agente
$ansiCodePage = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ANSICodePage
try {
  $enc = [System.Text.Encoding]::GetEncoding($ansiCodePage)
} catch {
  $enc = [System.Text.Encoding]::GetEncoding(1252)  # fallback pragm�tico
}
[System.IO.File]::WriteAllLines($confPath, $lines, $enc)

Write-Host "`nResumo aplicado:" -ForegroundColor Yellow
Write-Host ("  Server/ServerActive : {0}" -f $inServerUnified)
Write-Host ("  Hostname            : {0}" -f $inHostname)

# Restart opcional do servi�o (tenta por Name, depois por DisplayName)
$svc = Get-Service -Name 'Zabbix Agent 2' -ErrorAction SilentlyContinue
if (-not $svc) { $svc = Get-Service -DisplayName 'Zabbix Agent 2' -ErrorAction SilentlyContinue }

if ($svc) {
  $ans = Read-Host "Reiniciar o servi�o '$($svc.DisplayName)' agora? (S/n)"
  if ([string]::IsNullOrWhiteSpace($ans) -or $ans.Trim().ToLower() -eq 's') {
    try {
      Restart-Service -Name $svc.Name -Force -ErrorAction Stop
      Write-Host "Servi�o reiniciado com sucesso." -ForegroundColor Green
    } catch {
      Write-Host "Falha ao reiniciar o servi�o: $($_.Exception.Message)" -ForegroundColor Red
      Write-Host "Reinicie manualmente para aplicar as mudan�as." -ForegroundColor DarkGray
    }
  } else {
    Write-Host "Sem restart. Mudan�as efetivas ap�s rein�cio do servi�o." -ForegroundColor DarkGray
  }
} else {
  Write-Host "Servi�o do Zabbix Agent 2 n�o localizado. Apenas arquivo atualizado." -ForegroundColor DarkGray
}
