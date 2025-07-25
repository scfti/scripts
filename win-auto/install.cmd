@echo off

:: Instala Chocolatey
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

:: Instala aplicativos via Chocolatey
choco install googlechrome jre8 firefox pdfcreator anydesk nanazip --ignore-checksums -y

:: Baixa executável de suporte técnico
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "(New-Object System.Net.WebClient).DownloadFile('https://scfti.com.br/arquivos/Suporte SCF Ti.exe', '%userprofile%\desktop\Suporte SCF Ti.exe')"

:: Baixa e instala Office ODT usando configuration.xml personalizado
set ODT_DIR=%TEMP%\ODT
mkdir "%ODT_DIR%" >nul 2>&1

:: URLs dos arquivos (substitua pelos seus após subir no GitHub)
set ODT_SETUP_URL=https://github.com/scfti/scripts/raw/refs/heads/main/win-auto/office/setup.exe
set ODT_XML_URL=https://github.com/scfti/scripts/raw/refs/heads/main/win-auto/office/configuration.xml

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "Invoke-WebRequest -Uri '%ODT_SETUP_URL%' -OutFile '%ODT_DIR%\Setup.exe' -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "Invoke-WebRequest -Uri '%ODT_XML_URL%' -OutFile '%ODT_DIR%\configuration.xml' -UseBasicParsing -Headers @{ 'User-Agent' = 'Mozilla/5.0' }"

:: Executa instalação do Office com o XML
start /wait "" "%ODT_DIR%\Setup.exe" /configure "%ODT_DIR%\configuration.xml"

:: Ativador (use com cautela, depende do seu ambiente)
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "irm https://get.activated.win | iex"

:: Fim
exit /b 0
