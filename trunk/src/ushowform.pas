{
   Seksi Commander
   ----------------------------
   Licence  : GNU GPL v 2.0
   Author   : radek.cervinka@centrum.cz

   showing editor or viewer by configuration dialog

   contributors:

   Copyright (C) 2006-2008  Koblov Alexander (Alexx2000@mail.ru)
}


unit uShowForm;

interface

uses
  Classes, uFileSource;

type

  { TWaitThread }

  TWaitThread = class(TThread)
  private
    FFileList : TStringList;
    FFileSource: IFileSource;

  protected
    procedure Execute; override;

  public
    constructor Create(const FilesToView: TStringList; const aFileSource: IFileSource);
    destructor Destroy; override;
  end;

Function ShowEditorByGlob(sFileName:String):Boolean;
Function ShowViewerByGlob(sFileName:String):Boolean;
Function ShowViewerByGlobList(const FilesToView: TStringList;
                              const aFileSource: IFileSource):Boolean;


implementation

uses
  SysUtils, Process, UTF8Process, LCLProc, uGlobs, uOSUtils, fEditor, fViewer,
  uDCUtils, uTempFileSystemFileSource;

const
  sCmdLine = '%s %s';

function ShowEditorByGlob(sFileName:String):Boolean;
begin
  if gUseExtEdit then
    ExecCmdFork(Format(sCmdLine, [gExtEdit, QuoteStr(sFileName)]))
  else
    ShowEditor(sFileName);
  Result:=True;   
end;

function ShowViewerByGlob(sFileName:String):Boolean;
var
  sl:TStringList;
begin
  if gUseExtView then
    ExecCmdFork(Format(sCmdLine, [gExtView, QuoteStr(sFileName)]))
  else
  begin
    sl:=TStringList.Create;
    try
      sl.Add(sFileName);
      ShowViewer(sl);
    finally
      FreeAndNil(sl);
    end;
  end;
  Result:=True;
end;

function ShowViewerByGlobList(const FilesToView : TStringList;
                              const aFileSource: IFileSource):Boolean;
var
  I : Integer;
  WaitThread : TWaitThread;
begin
  if gUseExtView then
  begin
    DebugLN('ShowViewerByGlobList - Use ExtView ');
    if aFileSource.IsClass(TTempFileSystemFileSource) then
      begin
        WaitThread := TWaitThread.Create(FilesToView, aFileSource);
        WaitThread.Resume;
      end
    else
     for i:=0 to FilesToView.Count-1 do
       ExecCmdFork(Format(sCmdLine, [gExtView, QuoteStr(FilesToView.Strings[i])]));
  end // gUseExtView
  else
    ShowViewer(FilesToView, aFileSource);
  Result:=True;
end;

{ TWaitThread }

constructor TWaitThread.Create(const FilesToView: TStringList; const aFileSource: IFileSource);
begin
  inherited Create(True);

  FreeOnTerminate := True;

  FFileList := TStringList.Create;
  // Make a copy of list elements.
  FFileList.Assign(FilesToView);
  FFileSource := aFileSource;
end;

destructor TWaitThread.Destroy;
begin
  if Assigned(FFileList) then
    FreeAndNil(FFileList);

  // Delete the temporary file source and all files inside.
  FFileSource := nil;

  inherited Destroy;
end;

procedure TWaitThread.Execute;
var
  I : Integer;
  Process : TProcessUTF8;
begin
  Process := TProcessUTF8.Create(nil);
  // TProcess arguments must be enclosed with double quotes and not escaped.
  Process.CommandLine := Format(sCmdLine, [gExtView, '"' + FFileList.Strings[0] + '"']);
  Process.Options := [poWaitOnExit];
  Process.Execute;
  Process.Free;

  (* Delete temp files after view *)
  for I := 0 to FFileList.Count - 1 do
    mbDeleteFile(FFileList.Strings[I]);
end;

end.