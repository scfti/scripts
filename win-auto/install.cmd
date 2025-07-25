@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: Diretório temporário para arquivos de trabalho
set ODT_DIR=%TEMP%\ODT
mkdir "%ODT_DIR%" >nul 2>&1

:: Log de execução
set LOG_FILE=%TEMP%\win-install.log

:: ================================
:: INSTALAÇÃO DO CHOCOLATEY
:: ================================
echo Instalando Chocolatey...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; iex ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
if errorlevel 1 (
    echo [ERRO] Falha ao instalar Chocolatey. >> "%LOG_FILE%"
    exit /b 1
)

:: Atualiza PATH para uso imediato do choco
SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:: ================================
:: INSTALAÇÃO DOS APLICATIVOS
:: ================================
echo Instalando aplicativos via Chocolatey...
choco install googlechrome jre8 firefox pdfcreator anydesk nanazip --ignore-checksums --no-progress -y
if errorlevel 1 (
    echo [ERRO] Falha na instalação de pacotes Chocolatey. >> "%LOG_FILE%"
    exit /b 2
)

:: ================================
:: DOWNLOAD DO SUPORTE SCF TI
:: ================================
echo Baixando Suporte SCF Ti...
powershell -NoProfile -ExecutionPolicy Bypass -Command "(New-Object Net.WebClient).DownloadFile('https://scfti.com.br/arquivos/Suporte SCF Ti.exe', '$env:USERPROFILE\Desktop\Suporte SCF Ti.exe')"
if errorlevel 1 (
    echo [ERRO] Falha ao baixar Suporte SCF Ti. >> "%LOG_FILE%"
)

:: ================================
:: DOWNLOAD E INSTALAÇÃO DO OFFICE ODT
:: ================================
echo Baixando instalador do Office...
set ODT_SETUP_URL=https://github.com/scfti/scripts/raw/refs/heads/main/win-auto/office/setup.exe
set ODT_XML_URL=https://github.com/scfti/scripts/raw/refs/heads/main/win-auto/office/configuration.xml

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%ODT_SETUP_URL%' -OutFile '%ODT_DIR%\Setup.exe' -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '%ODT_XML_URL%' -OutFile '%ODT_DIR%\configuration.xml' -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }"

if not exist "%ODT_DIR%\Setup.exe" (
    echo [ERRO] O arquivo Setup.exe nao foi baixado. >> "%LOG_FILE%"
    exit /b 3
)
if not exist "%ODT_DIR%\configuration.xml" (
    echo [ERRO] O arquivo configuration.xml nao foi baixado. >> "%LOG_FILE%"
    exit /b 4
)

:: Instala o Office
start /wait "" "%ODT_DIR%\Setup.exe" /configure "%ODT_DIR%\configuration.xml"
if errorlevel 1 (
    echo [ERRO] Falha na instalacao do Office. >> "%LOG_FILE%"
    exit /b 5
)

:: ================================
:: ATIVADOR (USO CRÍTICO)
:: ================================
echo Executando ativador...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"
if errorlevel 1 (
    echo [ALERTA] Ativador pode ter falhado. >> "%LOG_FILE%"
)

:: ================================
:: FINALIZAÇÃO
:: ================================
echo [%DATE% %TIME%] Script concluido com sucesso. >> "%LOG_FILE%"
echo.
echo Instalação automatizada finalizada.
endlocal
exit /b 0
