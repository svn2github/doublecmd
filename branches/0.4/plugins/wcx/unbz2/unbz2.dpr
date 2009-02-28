library unbz2;

{$IFDEF CPU64}
{$FATAL This plugin don't work with 64 bit CPU}
{$ENDIF}

uses
  bz2func in 'bz2func.pas';

{$E wcx}

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
  {$IFDEF UNIX}
  WriteLN('unbz2 plugin is loaded');
  {$ENDIF}
end.
