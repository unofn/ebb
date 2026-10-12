; Ebb 的 Windows 安装程序（Inno Setup 6）。由 tool/packaging/windows/package.ps1 调用：
;   ISCC.exe /DAppVersion=0.1.0 /DBuildDir=<Release 目录> /DOutputDir=<输出目录> ebb.iss
; ChineseSimplified.isl 取自 Inno Setup 6.7.1 的非官方翻译，安装器本身不带，随仓库保存。

#ifndef AppVersion
  #error 需要 /DAppVersion=<版本>
#endif
#ifndef BuildDir
  #define BuildDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\build\dist"
#endif

[Setup]
; AppId 定了不能改：Windows 靠它认出同一个 App，升级时覆盖旧版而不是另装一份。
AppId={{DB0F467B-7F98-4C4C-B915-3A48867E211D}
AppName=Ebb
AppVersion={#AppVersion}
AppVerName=Ebb {#AppVersion}
AppPublisher=unofn
AppPublisherURL=https://github.com/unofn/ebb
AppSupportURL=https://github.com/unofn/ebb/issues
AppUpdatesURL=https://github.com/unofn/ebb/releases
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\Ebb
DisableProgramGroupPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
PrivilegesRequired=admin
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\ebb.exe
UninstallDisplayName=Ebb
OutputDir={#OutputDir}
OutputBaseFilename=ebb-{#AppVersion}-windows-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ShowLanguageDialog=auto

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "zh"; MessagesFile: "ChineseSimplified.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; AppUserModelID 和 lib/features/reminders/platform/notification_settings.dart 的
; appUserModelId 一致，CLSID 对应那里的 guid，否则通知认不出这个 App。
Name: "{autoprograms}\Ebb"; Filename: "{app}\ebb.exe"; AppUserModelID: "Unofn.Ebb"; AppUserModelToastActivatorCLSID: "5D0F6A52-8A3E-4C1B-9B7E-2F4C6E1D8A93"
Name: "{autodesktop}\Ebb"; Filename: "{app}\ebb.exe"; Tasks: desktopicon; AppUserModelID: "Unofn.Ebb"; AppUserModelToastActivatorCLSID: "5D0F6A52-8A3E-4C1B-9B7E-2F4C6E1D8A93"

[Run]
Filename: "{app}\ebb.exe"; Description: "{cm:LaunchProgram,Ebb}"; Flags: nowait postinstall skipifsilent
