unit uWcxArchiveDeleteOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceDeleteOperation,
  uFileSource,
  uFileSourceOperation,
  uFileSourceOperationUI,
  uFile,
  uWcxArchiveFileSource,
  uGlobs, uLog;

type

  TWcxArchiveDeleteOperation = class(TFileSourceDeleteOperation)

  private
    FWcxArchiveFileSource: TWcxArchiveFileSource;
    FStatistics: TFileSourceDeleteOperationStatistics; // local copy of statistics

    procedure CountFiles(const theFiles: TFiles; FileMask: String);

    {en
      Convert TFiles into a string separated with #0 (format used by WCX).
    }
    function GetFileList(const theFiles: TFiles): String;

  protected
    procedure ShowError(sMessage: String; logOptions: TLogOptions);
    procedure LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);

  public
    constructor Create(var aTargetFileSource: TFileSource;
                       var theFilesToDelete: TFiles); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;
  end;

implementation

uses
  uOSUtils, uDCUtils, uLng, uWCXmodule, uWCXhead, Masks, FileUtil, LCLProc;

// ----------------------------------------------------------------------------
// WCX callbacks

var
  // WCX interface cannot discern different operations (for reporting progress),
  // so this global variable is used to store currently running operation.
  // (There may be other running concurrently, but only one may report progress.)
  WcxDeleteOperation: TWcxArchiveDeleteOperation;

function ChangeVolProc(ArcName : Pchar; Mode:Longint):Longint; stdcall;
begin
{ // Use operation UI for this.

  case Mode of
    PK_VOL_ASK:
      ArcName := PChar(UTF8ToSys(Dialogs.InputBox('Double Commander', rsMsgSelLocNextVol, SysToUTF8(ArcName))));
    PK_VOL_NOTIFY:
      ShowMessage(rsMsgNextVolUnpack);
  end;
}
  Result := 0;
end;

function ProcessDataProc(FileName: PChar; Size: Integer): Integer; stdcall;
begin
  //DebugLn('Working ' + FileName + ' Size = ' + IntToStr(Size));

  Result := 1;

  if Assigned(WcxDeleteOperation) then
  begin
    if WcxDeleteOperation.State = fsosStopping then  // Cancel operation
      Exit(0);

    with WcxDeleteOperation.FStatistics do
    begin
      CurrentFile := SysToUTF8(FileName);

      if Size >= 0 then
      begin
        DoneBytes := DoneBytes + Size;
        DoneFiles := DoneFiles + 1;
      end
      else // For plugins which unpack in CloseArchive
      begin
        if (Size >= -100) and (Size <= -1) then // first percent bar
          begin
            if Size = -100 then // File finished
            begin
              //DoneBytes := DoneBytes + {FileSize(FileName)};
              DoneFiles := DoneFiles + 1;
            end;
          end
        else if (Size >= -1100) and (Size <= -1000) then // second percent bar
          begin
            DoneBytes := TotalBytes * Int64(-Size - 1000) div 100;
            DoneFiles := DoneFiles + 1;
          end
        else
          begin
            DoneFiles := DoneFiles + 1;
          end;
      end;

      WcxDeleteOperation.UpdateStatistics(WcxDeleteOperation.FStatistics);
    end;
  end;
end;

// ----------------------------------------------------------------------------

constructor TWcxArchiveDeleteOperation.Create(var aTargetFileSource: TFileSource;
                                              var theFilesToDelete: TFiles);
begin
  FWcxArchiveFileSource := aTargetFileSource as TWcxArchiveFileSource;

  inherited Create(aTargetFileSource, theFilesToDelete);
end;

destructor TWcxArchiveDeleteOperation.Destroy;
begin
  inherited Destroy;
end;

procedure TWcxArchiveDeleteOperation.Initialize;
begin
  if Assigned(WcxDeleteOperation) then
    raise Exception.Create('Another WCX delete operation is already running');

  WcxDeleteOperation := Self;

  // Get initialized statistics; then we change only what is needed.
  FStatistics := RetrieveStatistics;

  CountFiles(FilesToDelete, '*.*');
end;

procedure TWcxArchiveDeleteOperation.MainExecute;
var
  iResult: Integer;
  WcxModule: TWcxModule;
begin
  WcxModule := FWcxArchiveFileSource.WcxModule;

  WcxModule.SetChangeVolProc(wcxInvalidHandle, @ChangeVolProc);
  WcxModule.SetProcessDataProc(wcxInvalidHandle, @ProcessDataProc);

  iResult := WcxModule.DeleteFiles(
               PAnsiChar(UTF8ToSys(FWcxArchiveFileSource.ArchiveFileName)),
               PAnsiChar(UTF8ToSys(GetFileList(FilesToDelete))));

  // Check for errors.
  if iResult <> E_SUCCESS then
  begin
    ShowError(Format(rsMsgLogError + rsMsgLogDelete,
                     [FWcxArchiveFileSource.ArchiveFileName +
                      ' - ' + GetErrorMsg(iResult)]), [log_arc_op]);
  end
  else
  begin
    LogMessage(Format(rsMsgLogSuccess + rsMsgLogDelete,
                      [FWcxArchiveFileSource.ArchiveFileName]), [log_arc_op], lmtSuccess);
  end;
end;

procedure TWcxArchiveDeleteOperation.Finalize;
begin
  WcxDeleteOperation := nil;
end;

procedure TWcxArchiveDeleteOperation.ShowError(sMessage: String; logOptions: TLogOptions);
begin
  if not gSkipFileOpError then
  begin
    if AskQuestion(sMessage, '', [fsourSkip, fsourCancel],
                   fsourSkip, fsourAbort) = fsourAbort then
    begin
      RaiseAbortOperation;
    end;
  end
  else
  begin
    LogMessage(sMessage, logOptions, lmtError);
  end;
end;

procedure TWcxArchiveDeleteOperation.LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
begin
  case logMsgType of
    lmtError:
      if not (log_errors in gLogOptions) then Exit;
    lmtInfo:
      if not (log_info in gLogOptions) then Exit;
    lmtSuccess:
      if not (log_success in gLogOptions) then Exit;
  end;

  if logOptions <= gLogOptions then
  begin
    logWrite(Thread, sMessage, logMsgType);
  end;
end;

procedure TWcxArchiveDeleteOperation.CountFiles(const theFiles: TFiles; FileMask: String);
var
  i: Integer;
  Header: TWCXHeader;
  ArcFileList: TList;
begin
  ArcFileList := FWcxArchiveFileSource.ArchiveFileList;
  for i := 0 to ArcFileList.Count - 1 do
  begin
    Header := TWCXHeader(ArcFileList.Items[I]);

    // Check if the file from the archive fits the selection given via theFiles.
    if  (not FPS_ISDIR(Header.FileAttr))           // Omit directories
    and MatchesFileList(theFiles, Header.FileName) // Check if it's included in the filelist
    and ((FileMask = '*.*') or (FileMask = '*')    // And name matches file mask
        or MatchesMaskList(ExtractFileName(Header.FileName), FileMask))
    then
    begin
      Inc(FStatistics.TotalBytes, Header.UnpSize);
      Inc(FStatistics.TotalFiles, 1);
    end;
  end;

  UpdateStatistics(FStatistics);
end;

function TWcxArchiveDeleteOperation.GetFileList(const theFiles: TFiles): String;
var
  I        : Integer;
  FileName : String;
begin
  Result := '';

  for I := 0 to theFiles.Count - 1 do
    begin
      // Filenames must be relative to archive root and shouldn't start with path delimiter.
      FileName := ExcludeFrontPathDelimiter(theFiles[I].FullPath);
                  //ExtractDirLevel(FWcxArchiveFileSource.GetRootString, theFiles[I].FullPath)

      // Special treatment of directories.
      if theFiles[i].IsDirectory then
        // TC ends paths to directories to be deleted with '\*.*'
        // (which means delete this directory and all files in it).
        FileName := IncludeTrailingPathDelimiter(FileName) + '*.*';

      Result := Result + FileName + #0;
    end;

  Result := Result + #0;
end;

end.
