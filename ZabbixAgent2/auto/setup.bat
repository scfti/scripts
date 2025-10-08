@echo off
setlocal enableextensions
set "PS_BOOT=%~dp0bootstrap.ps1"

if not exist "%PS_BOOT%" (
  echo [ERRO] bootstrap.ps1 nao encontrado em %~dp0
  pause
  exit /b 1
)

REM Sem -Action => o bootstrap exibe o MENU (instalar|alterar_conf)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%PS_BOOT%""' -Verb RunAs -Wait"

set rc=%errorlevel%
echo Retorno bootstrap: %rc%
exit /b %rc%
