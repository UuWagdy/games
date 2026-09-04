; Inno Setup Script for Games Platform Desktop Application
#define MyAppName "منصة الألعاب"
#define MyAppEnglishName "GamesPlatform"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Games Team"
#define MyAppExeName "games.exe"
#define MySourceDir "build\windows\x64\runner\Release"

[Setup]
AppId={{D9A3B5C7-5E2F-4F12-887B-7362E90D41E8}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppEnglishName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=build\installer
OutputBaseFilename=GamesPlatform_Setup
SetupIconFile=windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
DisableProgramGroupPage=yes

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "installer_prerequisites\VC_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "installer_prerequisites\VC_redist.x86.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{tmp}\VC_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "جاري تثبيت حزمة Visual C++ Runtime (x64)..."; Flags: waituntilterminated
Filename: "{tmp}\VC_redist.x86.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "جاري تثبيت حزمة Visual C++ Runtime (x86)..."; Flags: waituntilterminated
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
