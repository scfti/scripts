[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=Instalar o Zabbix Agent neste computador?
DisplayLicense=
FinishMessage=
TargetName=C:\Users\salat\OneDrive\Área de Trabalho\SCF Ti - Agent2.EXE
FriendlyName=SCF Ti - Zabbix Agent 2
AppLaunched=cmd /c setup.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="setup.bat"
FILE1="zabbix.ps1"
[SourceFiles]
SourceFiles0=C:\Users\salat\OneDrive\Área de Trabalho\ZabbixAgent2\
[SourceFiles0]
%FILE0%=
%FILE1%=
