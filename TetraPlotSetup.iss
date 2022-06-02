; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{71D51ED1-5151-4930-8D54-31D34922242F}
AppName=TetraPlot
AppVerName=TetraPlot 1.7.1
AppPublisher=Naoyuki Hatada
AppPublisherURL=https://github.com/n-hatada/tetraplot
AppSupportURL=https://github.com/n-hatada/tetraplot
AppUpdatesURL=https://github.com/n-hatada/tetraplot
DefaultDirName={pf}\TetraPlot
DefaultGroupName=TetraPlot
OutputBaseFilename=TetraPlot1.7.1_Setup
SetupIconFile=prjtetraplot.ico
Compression=lzma
SolidCompression=yes

[Languages]
Name: english; MessagesFile: compiler:Default.isl
Name: japanese; MessagesFile: compiler:Languages\Japanese.isl

[Tasks]
Name: desktopicon; Description: {cm:CreateDesktopIcon}; GroupDescription: {cm:AdditionalIcons}; Flags: unchecked

[Files]
Source: TetraPlot.exe; DestDir: {app}; Flags: ignoreversion
Source: TetraPlotFileIcon.ico; DestDir: {app}; Flags: ignoreversion
Source: readme.txt; DestDir: {app}; Flags: ignoreversion
Source: readme_jp.txt; DestDir: {app}; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: Languages\TetraPlot.jp.po; DestDir: {app}\Languages; Flags: ignoreversion
Source: samples\Sample (La-P-H-O).tpxml; DestDir: {app}\Samples; Flags: ignoreversion

[Icons]
Name: {group}\TetraPlot; Filename: {app}\TetraPlot.exe
Name: {group}\{cm:UninstallProgram,TetraPlot}; Filename: {uninstallexe}
Name: {commondesktop}\TetraPlot; Filename: {app}\TetraPlot.exe; Tasks: desktopicon
Name: {group}\Languages\TetraPlot (English); Filename: {app}\TetraPlot.exe; Parameters: -l en; IconIndex: 0
Name: {group}\Languages\TetraPlot (Japanese); Filename: {app}\TetraPlot.exe; Parameters: -l jp; IconIndex: 0
Name: {group}\Open sample folder; Filename: {app}\Samples
Name: {group}\Readme (English); Filename: {app}\readme.txt
Name: {group}\Readme (Japanese); Filename: {app}\readme_jp.txt

[Run]
Filename: {app}\TetraPlot.exe; Description: {cm:LaunchProgram,TetraPlot}; Flags: nowait postinstall skipifsilent
[Registry]
Root: HKLM; SubKey: SOFTWARE\Classes\.tpxml; ValueType: string; ValueData: TetraPlotXMLFile; Flags: uninsdeletekey
Root: HKLM; SubKey: SOFTWARE\Classes\TetraPlotXMLFile; ValueType: string; ValueName: ; ValueData: TetraPlot XML File; Flags: uninsdeletekey
Root: HKLM; SubKey: SOFTWARE\Classes\TetraPlotXMLFile\DefaultIcon; ValueType: string; ValueData: """{app}\TetraPlotFileIcon.ico"""; Flags: uninsdeletekey
Root: HKLM; SubKey: SOFTWARE\Classes\TetraPlotXMLFile\shell; ValueType: string; ValueName: ; ValueData: TetraPlot; Flags: uninsdeletekey
Root: HKLM; SubKey: SOFTWARE\Classes\TetraPlotXMLFile\shell\TetraPlot; ValueType: string; ValueName: ; ValueData: Open with TetraPlot; Flags: uninsdeletekey
Root: HKLM; SubKey: SOFTWARE\Classes\TetraPlotXMLFile\shell\TetraPlot\command; ValueType: string; ValueData: """{app}\TetraPlot.exe"" ""%1"""; Flags: uninsdeletekey
