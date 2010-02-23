unit uFileSystemDeleteOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceDeleteOperation,
  uFileSource,
  uFileSourceOperationOptions,
  uFileSourceOperationUI,
  uFile,
  uFileSystemFile,
  uDescr, uGlobs, uLog;

type

  TFileSystemDeleteOperation = class(TFileSourceDeleteOperation)

  private
    FFullFilesTreeToDelete: TFileSystemFiles;  // source files including all files/dirs in subdirectories
    FStatistics: TFileSourceDeleteOperationStatistics; // local copy of statistics
    FDescription: TDescription;

    // Options.
    FSymLinkOption: TFileSourceOperationOptionSymLink;
    FSkipErrors: Boolean;
    FRecycle: Boolean;
    FDeleteReadOnly,
    FDeleteDirectly: TFileSourceOperationOptionGeneral;

  protected
    function ProcessFile(aFile: TFileSystemFile): Boolean;
    function ShowError(sMessage: String): TFileSourceOperationUIResponse;
    procedure LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);

  public
    constructor Create(aTargetFileSource: IFileSource;
                       var theFilesToDelete: TFiles); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;

    // For delete to trash
    property Recycle : boolean read FRecycle write FRecycle default false;
    property DeleteReadOnly: TFileSourceOperationOptionGeneral read FDeleteReadOnly write FDeleteReadOnly;
    property SymLinkOption: TFileSourceOperationOptionSymLink read FSymLinkOption write FSymLinkOption;
    property SkipErrors: Boolean read FSkipErrors write FSkipErrors;
  end;

implementation

uses
  uOSUtils, uLng, uFileProcs, uFileSystemUtil;

constructor TFileSystemDeleteOperation.Create(aTargetFileSource: IFileSource;
                                              var theFilesToDelete: TFiles);
begin
  FSymLinkOption := fsooslNone;
  FSkipErrors := gSkipFileOpError;
  FRecycle := False;
  FDeleteReadOnly := fsoogNone;
  FDeleteDirectly:= fsoogNone;
  FFullFilesTreeToDelete := nil;

  if gProcessComments then
    FDescription := TDescription.Create(True)
  else
    FDescription := nil;

  inherited Create(aTargetFileSource, theFilesToDelete);
end;

destructor TFileSystemDeleteOperation.Destroy;
begin
  inherited Destroy;

  if Assigned(FDescription) then
  begin
    FDescription.SaveDescription;
    FreeAndNil(FDescription);
  end;

  if not FRecycle then
  begin
    if Assigned(FFullFilesTreeToDelete) then
      FreeAndNil(FFullFilesTreeToDelete);
  end;
end;

procedure TFileSystemDeleteOperation.Initialize;
begin
  // Get initialized statistics; then we change only what is needed.
  FStatistics := RetrieveStatistics;

  if FRecycle then
    begin
      FFullFilesTreeToDelete:= FilesToDelete as TFileSystemFiles;
      FStatistics.TotalFiles:= FFullFilesTreeToDelete.Count;
    end
  else
    begin
      FillAndCount(FilesToDelete as TFileSystemFiles, True,
                   FFullFilesTreeToDelete,
                   FStatistics.TotalFiles,
                   FStatistics.TotalBytes);     // gets full list of files (recursive)
    end;

  if gProcessComments then
    FDescription.Clear;
end;

procedure TFileSystemDeleteOperation.MainExecute;
var
  aFile: TFileSystemFile;
  CurrentFileIndex: Integer;
begin
  for CurrentFileIndex := FFullFilesTreeToDelete.Count - 1 downto 0 do
  begin
    aFile := FFullFilesTreeToDelete[CurrentFileIndex] as TFileSystemFile;

    FStatistics.CurrentFile := aFile.Path + aFile.Name;
    UpdateStatistics(FStatistics);

    ProcessFile(aFile);

    with FStatistics do
    begin
      DoneFiles := DoneFiles + 1;
      DoneBytes := DoneBytes + aFile.Size;

      UpdateStatistics(FStatistics);
    end;

    CheckOperationState;
  end;
end;

procedure TFileSystemDeleteOperation.Finalize;
begin
end;

function TFileSystemDeleteOperation.ProcessFile(aFile: TFileSystemFile): Boolean;
var
  FileName: String;
  bRetry: Boolean;
  RemoveDirectly: TFileSourceOperationOptionGeneral = fsoogNone;
  sMessage, sQuestion: String;
  logOptions: TLogOptions;
begin
  Result := False;
  FileName := aFile.Path + aFile.Name;

  if FileIsReadOnly(aFile.Attributes) then
  begin
    case FDeleteReadOnly of
      fsoogNone:
        case AskQuestion(Format(rsMsgFileReadOnly, [FileName]), '',
                         [fsourYes, fsourAll, fsourSkip, fsourSkipAll],
                         fsourYes, fsourSkip) of
          fsourAll:
            FDeleteReadOnly := fsoogYes;
          fsourSkip:
            Exit;
          fsourSkipAll:
            begin
              FDeleteReadOnly := fsoogNo;
              Exit;
            end;
        end;

       fsoogNo:
         Exit;
    end;
  end;

  repeat
    bRetry := False;

    if (FRecycle = False) then
    begin
      if FileIsReadOnly(aFile.Attributes) then
        mbFileSetReadOnly(FileName, False);

      if aFile.IsDirectory then // directory
      begin
        Result := mbRemoveDir(FileName);
      end
      else
      begin // files and other stuff
        Result := mbDeleteFile(FileName);
      end;
    end
    else
    begin
      // Delete to trash (one function for file and folder)
      if not mbDeleteToTrash(FileName) then
        begin
          case FDeleteDirectly of
            fsoogNone:
              case AskQuestion(Format(rsMsgDelToTrashForce, [FileName]), '',
                               [fsourYes, fsourAll, fsourSkip, fsourSkipAll, fsourAbort],
                               fsourYes, fsourSkip) of
                fsourYes:
                  RemoveDirectly:= fsoogYes;
                fsourAll:
                  begin
                    FDeleteDirectly := fsoogYes;
                    RemoveDirectly:= fsoogYes;
                  end;
                fsourSkip:
                  RemoveDirectly:= fsoogNo;
                fsourSkipAll:
                  begin
                    FDeleteDirectly := fsoogNo;
                    RemoveDirectly:= fsoogNo;
                  end;
                fsourAbort:
                  RaiseAbortOperation;
              end;
            fsoogYes:
              RemoveDirectly:= fsoogYes;
            fsoogNo:
              RemoveDirectly:= fsoogNo;
          end;
          if RemoveDirectly = fsoogYes then
            begin
              if aFile.IsDirectory then // directory
                begin
                  DelTree(FileName);
                  Result := True;
                end
              else  // files and other stuff
                begin
                  Result := mbDeleteFile(FileName);
                end;
            end;
        end;
    end;

    if Result then
    begin // success
      // process comments if need
      if gProcessComments then
        FDescription.DeleteDescription(FileName);

      if aFile.IsDirectory then
      begin
        LogMessage(Format(rsMsgLogSuccess + rsMsgLogRmDir, [FileName]), [log_dir_op, log_delete], lmtSuccess);
      end
      else
      begin
        LogMessage(Format(rsMsgLogSuccess + rsMsgLogDelete, [FileName]), [log_delete], lmtSuccess);
      end;
    end
    else // error
    begin
      if aFile.IsDirectory then
      begin
        logOptions := [log_dir_op, log_delete];
        sMessage := Format(rsMsgLogError + rsMsgLogRmDir, [FileName]);
        sQuestion := Format(rsMsgNotDelete, [FileName]);
      end
      else
      begin
        logOptions := [log_delete];
        sMessage := Format(rsMsgLogError + rsMsgLogDelete, [FileName]);
        sQuestion := Format(rsMsgNotDelete, [FileName]);
      end;

      if FSkipErrors or (RemoveDirectly <> fsoogYes) then
        LogMessage(sMessage, logOptions, lmtError)
      else
      begin
        case AskQuestion(sQuestion, '',
                         [fsourRetry, fsourSkip, fsourSkipAll, fsourAbort],
                         fsourRetry, fsourSkip) of
          fsourRetry:
            bRetry := True;
          fsourSkipAll:
            FSkipErrors := True;
          fsourAbort:
            RaiseAbortOperation;
        end;
      end;
    end;
  until bRetry = False;
end;

function TFileSystemDeleteOperation.ShowError(sMessage: String): TFileSourceOperationUIResponse;
begin
  if FSkipErrors then
  begin
    logWrite(Thread, sMessage, lmtError, True);
    Result := fsourSkip;
  end
  else
  begin
    Result := AskQuestion(sMessage, '', [fsourSkip, fsourCancel], fsourSkip, fsourCancel);
    if Result = fsourCancel then
      RaiseAbortOperation;
  end;
end;

procedure TFileSystemDeleteOperation.LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
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

end.

