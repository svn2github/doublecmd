; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
AppName=Double Commander
AppVerName=Double Commander 0.5.5 beta
AppPublisherURL=http://doublecmd.sourceforge.net
AppSupportURL=http://doublecmd.sourceforge.net
AppUpdatesURL=http://doublecmd.sourceforge.net
DefaultDirName={pf}\Double Commander
DefaultGroupName=Double Commander
AllowNoIcons=yes
LicenseFile=doublecmd\doc\COPYING.txt
OutputDir=release
Compression=lzma
SolidCompression=yes
; "ArchitecturesInstallIn64BitMode=x64" requests that the install be
; done in "64-bit mode" on x64, meaning it should use the native
; 64-bit Program Files directory and the 64-bit view of the registry.
; On all other architectures it will install in "32-bit mode".
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"
Name: "catalan"; MessagesFile: "compiler:Languages\Catalan.isl"
Name: "corsican"; MessagesFile: "compiler:Languages\Corsican.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "finnish"; MessagesFile: "compiler:Languages\Finnish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "greek"; MessagesFile: "compiler:Languages\Greek.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "nepali"; MessagesFile: "compiler:Languages\Nepali.islu"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "serbiancyrillic"; MessagesFile: "compiler:Languages\SerbianCyrillic.isl"
Name: "serbianlatin"; MessagesFile: "compiler:Languages\SerbianLatin.isl"
Name: "slovenian"; MessagesFile: "compiler:Languages\Slovenian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "ukrainian"; MessagesFile: "compiler:Languages\Ukrainian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "doublecmd\doublecmd.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "doublecmd\doublecmd.zdli"; DestDir: "{app}"; Flags: ignoreversion
Source: "doublecmd\doublecmd.xml"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "doublecmd\pixmaps.txt"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "doublecmd\multiarc.ini"; DestDir: "{app}"; Flags: onlyifdoesntexist
Source: "doublecmd\doc\*"; DestDir: "{app}\doc"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "doublecmd\language\*"; DestDir: "{app}\language"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "doublecmd\pixmaps\*"; DestDir: "{app}\pixmaps"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "doublecmd\plugins\*"; DestDir: "{app}\plugins"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: "doublecmd\*.dll"; DestDir: "{app}"; Flags: skipifsourcedoesntexist

[Icons]
Name: "{group}\Double Commander"; Filename: "{app}\doublecmd.exe"
Name: "{group}\{cm:ProgramOnTheWeb,Double Commander}"; Filename: "http://doublecmd.sourceforge.net"
Name: "{group}\{cm:UninstallProgram,Double Commander}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\Double Commander"; Filename: "{app}\doublecmd.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\Double Commander"; Filename: "{app}\doublecmd.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\doublecmd.exe"; Description: "{cm:LaunchProgram,Double Commander}"; Flags: nowait postinstall skipifsilent


