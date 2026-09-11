[Setup]
AppName=Ultimate Study App
AppVersion=1.0.3
DefaultDirName={autopf}\UltimateStudyApp
DefaultGroupName=Ultimate Study App
OutputDir=D:\ultimate_study_app\build
OutputBaseFilename=UltimateStudyApp-Setup-v1.0.3
Compression=lzma
SolidCompression=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Files]
Source: "D:\ultimate_study_app\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Ultimate Study App"; Filename: "{app}\ultimate_study_app.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Ultimate Study App"; Filename: "{app}\ultimate_study_app.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\ultimate_study_app.exe"; Description: "Mở ứng dụng"; Flags: postinstall nowait skipifsilent; WorkingDir: "{app}"