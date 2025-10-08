@echo off
setlocal enableextensions

REM Caminho do script PS1 extraido
set "PS1=%~dp0zabbix.ps1"
if not exist "%PS1%" (
  echo [ERRO] Nao encontrei "%PS1%".
  pause
  exit /b 1
)

REM Eleva (UAC) e BLOQUEIA ate terminar (-Wait). Nao use START sem /WAIT aqui.
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PS1%""' -Verb RunAs -Wait"

set "rc=%errorlevel%"
echo Retorno PowerShell: %rc%
exit /b %rc%
