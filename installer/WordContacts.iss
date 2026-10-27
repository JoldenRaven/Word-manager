#define MyAppName "Word Contacts"
#define MyAppVersion "1.0.0"
[Setup]
AppId={{AD86FA46-76CF-485D-8564-FF0AA3380E11}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\Word Contacts
DefaultGroupName=Word Contacts
OutputDir=..\dist\windows
OutputBaseFilename=WordContactsSetup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin
[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Word Contacts"; Filename: "{app}\word_contacts.exe"
Name: "{autodesktop}\Word Contacts"; Filename: "{app}\word_contacts.exe"; Tasks: desktopicon
