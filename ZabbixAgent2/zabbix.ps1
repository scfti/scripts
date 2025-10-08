<# 
  Zabbix Agent 2 - Installer Orchestrator
  Autor: SCF Ti
  Requisitos: PowerShell 5+, permissão de Administrador, acesso HTTP/HTTPS
#>

# --- Guardrails de execução ---
# Exigir elevação
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: Execute o PowerShell como Administrador." -ForegroundColor Red
    exit 1
}

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- Parâmetros padrão (baseline) ---
$DefaultServer   = "192.0.0.203"
$DefaultHostname = $env:COMPUTERNAME
$MsiUrl          = "https://cdn.zabbix.com/zabbix/binaries/stable/7.4/7.4.3/zabbix_agent2-7.4.3-windows-amd64-openssl.msi"
$MsiLocalPath    = Join-Path $env:TEMP "zabbix_agent2-7.4.3-windows-amd64-openssl.msi"
$LogPath         = Join-Path $env:TEMP "zabbix_agent2_install_$(Get-Date -Format yyyyMMdd_HHmmss).log"

function Read-WithDefault {
    param(
        [Parameter(Mandatory=$true)] [string] $Prompt,
        [Parameter(Mandatory=$true)] [string] $Default
    )
    $answer = Read-Host "$Prompt (Enter para usar: $Default)"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default } else { return $answer }
}

# --- Menu de confirmação/edição (com valores pré-preenchidos) ---
Write-Host "===== Parametrização do Zabbix Agent 2 =====" -ForegroundColor Cyan
$ServerInput   = Read-WithDefault -Prompt "Endereço do Servidor" -Default $DefaultServer
$HostnameInput = Read-WithDefault -Prompt "Hostname"             -Default $DefaultHostname

Write-Host ""
Write-Host "Resumo das entradas:" -ForegroundColor Yellow
Write-Host "  SERVER / SERVERACTIVE : $ServerInput"
Write-Host "  HOSTNAME              : $HostnameInput"
Write-Host ""

# --- Download idempotente do MSI ---
if (-not (Test-Path $MsiLocalPath)) {
    Write-Host "Baixando pacote MSI..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $MsiUrl -OutFile $MsiLocalPath
    } catch {
        Write-Host "ERRO no download do MSI: $($_.Exception.Message)" -ForegroundColor Red
        exit 2
    }
} else {
    Write-Host "MSI já presente em: $MsiLocalPath (reutilizando)" -ForegroundColor DarkYellow
}

# --- Execução da instalação silenciosa ---
# Observação: propriedades aceitas pelo MSI do Zabbix: SERVER, SERVERACTIVE, HOSTNAME (entre outras).
$msiArgs = @(
    "/i `"$MsiLocalPath`"",
    "/qn",
    "/norestart",
    "SERVER=`"$ServerInput`"",
    "SERVERACTIVE=`"$ServerInput`"",
    "HOSTNAME=`"$HostnameInput`"",
    "/L*v `"$LogPath`""
) -join ' '

Write-Host "Instalando Zabbix Agent 2 via msiexec..." -ForegroundColor Cyan
Write-Host "Log de instalação: $LogPath" -ForegroundColor DarkGray

$proc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) {
    Write-Host "ERRO: msiexec retornou código $($proc.ExitCode). Consulte o log." -ForegroundColor Red
    exit $proc.ExitCode
}

# --- Pós-instalação: validação de serviço e *hardening* básico de firewall (inbound 10050) ---
$svcName = "Zabbix Agent 2"
try {
    $svc = Get-Service -Name $svcName -ErrorAction Stop
    if ($svc.Status -ne 'Running') {
        Start-Service -Name $svcName
    }
    Write-Host "Serviço '$svcName' operacional: $((Get-Service $svcName).Status)" -ForegroundColor Green
} catch {
    Write-Host "ATENÇÃO: Serviço '$svcName' não localizado. Verifique o log de instalação." -ForegroundColor Yellow
}

# Abrir porta 10050/TCP para coleta passiva (opcional; mantenha se você usa SERVER também)
try {
    if (-not (Get-NetFirewallRule -DisplayName "Zabbix Agent 2 (TCP 10050)" -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName "Zabbix Agent 2 (TCP 10050)" `
            -Direction Inbound -Action Allow -Protocol TCP -LocalPort 10050 `
            -Program "$env:ProgramFiles\Zabbix Agent 2\zabbix_agent2.exe" | Out-Null
        Write-Host "Regra de firewall (10050/TCP) provisionada." -ForegroundColor Green
    } else {
        Write-Host "Regra de firewall já existente." -ForegroundColor DarkYellow
    }
} catch {
    Write-Host "AVISO: Falha ao criar regra de firewall: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Instalação concluída com sucesso. *Time-to-value* garantido." -ForegroundColor Green
Write-Host "Servidor: $ServerInput | Hostname: $HostnameInput"
Write-Host "Log: $LogPath"

