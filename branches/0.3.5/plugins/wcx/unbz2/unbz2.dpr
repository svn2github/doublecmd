library unbz2;



uses
  bz2func in 'bz2func.pas';

{$E wcx}

{$R *.res}
exports
{ Mandatory }
OpenArchive,
ReadHeader,
ProcessFile,
CloseArchive,
SetChangeVolProc,
SetProcessDataProc,
{ Optional }
CanYouHandleThisFile;

begin
{$IFNDEF WIN32}
WriteLN('unbz2 plugin is loaded');
{$ENDIF}
end.
