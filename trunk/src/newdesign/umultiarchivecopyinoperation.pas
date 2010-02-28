unit uMultiArchiveCopyInOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StringHashList, uLog, uGlobs, un_process,
  uFileSourceCopyOperation,
  uFileSource,
  uFileSourceOperation,
  uFile,
  uFileSystemFile,
  uMultiArchiveFileSource;

type

  { TMultiArchiveCopyInOperation }

  TMultiArchiveCopyInOperation = class(TFileSourceCopyInOperation)

  private
    FMultiArchiveFileSource: IMultiArchiveFileSource;
    FStatistics: TFileSourceCopyOperationStatistics; // local copy of statistics
    FFullFilesTree: TFileSystemFiles;

    procedure ShowError(sMessage: String; logOptions: TLogOptions = []);
    procedure LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
    function CheckForErrors(const FileName: UTF8String; ExitStatus: LongInt): Boolean;
    procedure DeleteFile(const BasePath: UTF8String; aFile: TFile);

  protected
    FExProcess: TExProcess;
    FTempFile: UTF8String;
    FErrorLevel: LongInt;
    procedure OnReadLn(str: string);
    procedure UpdateProgress(SourceName, TargetName: UTF8String; IncSize: Int64);

  public
    constructor Create(aSourceFileSource: IFileSource;
                       aTargetFileSource: IFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;

  end;

implementation

uses
  LCLProc, FileUtil, uDCUtils, uMultiArc, uLng, uShowMsg, Process, WcxPlugin,
  uFileSourceOperationUI, uFileSystemUtil, uMultiArchiveUtil, uOSUtils;

constructor TMultiArchiveCopyInOperation.Create(aSourceFileSource: IFileSource;
                                              aTargetFileSource: IFileSource;
                                              var theSourceFiles: TFiles;
                                              aTargetPath: String);
begin
  FMultiArchiveFileSource := aTargetFileSource as IMultiArchiveFileSource;
  FFullFilesTree := nil;

  inherited Create(aSourceFileSource, aTargetFileSource, theSourceFiles, aTargetPath);
end;

destructor TMultiArchiveCopyInOperation.Destroy;
begin
  inherited Destroy;

  if Assigned(FFullFilesTree) then
    FreeAndNil(FFullFilesTree);
end;

procedure TMultiArchiveCopyInOperation.Initialize;
begin
  FExProcess:= TExProcess.Create(EmptyStr);
  FExProcess.OnReadLn:= @OnReadLn;
  FTempFile:= GetTempName(GetTempFolder);

  // Get initialized statistics; then we change only what is needed.
  FStatistics := RetrieveStatistics;

  FillAndCount(SourceFiles as TFileSystemFiles, False,
               FFullFilesTree,
               FStatistics.TotalFiles,
               FStatistics.TotalBytes);     // gets full list of files (recursive)
end;

procedure TMultiArchiveCopyInOperation.MainExecute;
var
  I: Integer;
  sRootPath,
  sCurrPath,
  sDestPath: String;
  MultiArcItem: TMultiArcItem;
  aFile: TFileSystemFile;
  sCommandLine: UTF8String;
begin
  MultiArcItem := FMultiArchiveFileSource.MultiArcItem;

  sDestPath := ExcludeFrontPathDelimiter(TargetPath);
  sDestPath := ExcludeTrailingPathDelimiter(sDestPath);
  // save current path
  sCurrPath:= mbGetCurrentDir;
  sRootPath:= FFullFilesTree.Path;
  // set current path to file list root
  mbSetCurrentDir(sRootPath);
  ChangeFileListRoot(EmptyStr, FFullFilesTree);
  with FMultiArchiveFileSource do
  begin
    if (VolumeSize <> 0) and (MultiArcItem.FAddMultiVolume <> EmptyStr) then
      sCommandLine:= MultiArcItem.FAddMultiVolume
    else if (ExtractFileExt(ArchiveFileName) = GetSfxExt) and (MultiArcItem.FAddSelfExtract <> EmptyStr) then
      sCommandLine:= MultiArcItem.FAddSelfExtract
    else
      sCommandLine:= MultiArcItem.FAdd;
  end;
  // Get maximum acceptable command errorlevel
  FErrorLevel:= ExtractErrorLevel(sCommandLine);
  if Pos('%F', sCommandLine) <> 0 then // pack file by file
    for I:= FFullFilesTree.Count - 1 downto 0 do
    begin
      aFile:= FFullFilesTree[I];
      UpdateProgress(sRootPath + aFile.FullPath, sDestPath, 0);

      sCommandLine:= FormatArchiverCommand(
                                           MultiArcItem.FArchiver,
                                           sCommandLine,
                                           FMultiArchiveFileSource.ArchiveFileName,
                                           nil,
                                           aFile.FullPath,
                                           sDestPath,
                                           FTempFile,
                                           FMultiArchiveFileSource.Password,
                                           FMultiArchiveFileSource.VolumeSize
                                           );
      OnReadLn(sCommandLine);

      FExProcess.SetCmdLine(sCommandLine);
      FExProcess.Execute;

      UpdateProgress(sRootPath + aFile.FullPath, sDestPath, aFile.Size);
      // Check for errors.
      if CheckForErrors(sRootPath + aFile.FullPath, FExProcess.ExitStatus) then
        begin
          if (FMultiArchiveFileSource.ArchiveFlags and PK_PACK_MOVE_FILES) <> 0 then
            DeleteFile(sRootPath, aFile);
        end;
    end
  else  // pack whole file list
    begin
      sCommandLine:= FormatArchiverCommand(
                                           MultiArcItem.FArchiver,
                                           sCommandLine,
                                           FMultiArchiveFileSource.ArchiveFileName,
                                           FFullFilesTree,
                                           EmptyStr,
                                           sDestPath,
                                           FTempFile,
                                           FMultiArchiveFileSource.Password,
                                           FMultiArchiveFileSource.VolumeSize
                                           );
      OnReadLn(sCommandLine);

      FExProcess.SetCmdLine(sCommandLine);
      FExProcess.Execute;

      // Check for errors.
      if CheckForErrors(FMultiArchiveFileSource.ArchiveFileName, FExProcess.ExitStatus) then
        begin
           if (FMultiArchiveFileSource.ArchiveFlags and PK_PACK_MOVE_FILES) <> 0 then
             for I:= FFullFilesTree.Count - 1 downto 0 do
               DeleteFile(sRootPath, FFullFilesTree[I]);
        end;
    end;
  // restore current path
  mbSetCurrentDir(sCurrPath);
end;

procedure TMultiArchiveCopyInOperation.Finalize;
begin
  FreeThenNil(FExProcess);
  with FMultiArchiveFileSource.MultiArcItem do
  if not FDebug then
    mbDeleteFile(FTempFile);
end;

procedure TMultiArchiveCopyInOperation.ShowError(sMessage: String; logOptions: TLogOptions);
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

procedure TMultiArchiveCopyInOperation.LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
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

function TMultiArchiveCopyInOperation.CheckForErrors(const FileName: UTF8String; ExitStatus: LongInt): Boolean;
begin
  if ExitStatus > FErrorLevel then
    begin
      Result:= False;
      ShowError(Format(rsMsgLogError + rsMsgLogPack,
                       [FileName +
                        ' - Exit status: ' + IntToStr(ExitStatus)]), [log_arc_op]);
    end
  else
    begin
      Result:= True;
      LogMessage(Format(rsMsgLogSuccess + rsMsgLogPack,
                        [FileName]), [log_arc_op], lmtSuccess);
    end;
end;

procedure TMultiArchiveCopyInOperation.DeleteFile(const BasePath: UTF8String; aFile: TFile);
begin
  if aFile.IsDirectory then
    mbRemoveDir(BasePath + aFile.FullPath)
  else
    mbDeleteFile(BasePath + aFile.FullPath);
end;

procedure TMultiArchiveCopyInOperation.OnReadLn(str: string);
begin
  with FMultiArchiveFileSource.MultiArcItem do
  if FOutput or FDebug then
    logWrite(Thread, str, lmtInfo, True, False);
end;

procedure TMultiArchiveCopyInOperation.UpdateProgress(SourceName,
  TargetName: UTF8String; IncSize: Int64);
begin
  with FStatistics do
  begin
    FStatistics.CurrentFileFrom:= SourceName;
    FStatistics.CurrentFileTo:= TargetName;

    CurrentFileDoneBytes:= IncSize;
    DoneBytes := DoneBytes + CurrentFileDoneBytes;

    UpdateStatistics(FStatistics);
  end;
end;

end.

