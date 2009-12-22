unit uWcxArchiveCopyOutOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StringHashList, uLog, uGlobs,
  uFileSourceCopyOperation,
  uFileSource,
  uFileSourceOperation,
  uFile,
  uWcxArchiveFileSource;

type
  TWcxArchiveCopyOutOperation = class(TFileSourceCopyOutOperation)

  private
    FWcxArchiveFileSource: IWcxArchiveFileSource;
    FStatistics: TFileSourceCopyOperationStatistics; // local copy of statistics
    FCurrentFileSize: Int64;

    {en
      Creates neccessary paths before extracting files from archive.
      Also counts size of all files that will be extracted.

      @param(Files
             List of files/directories to extract (relative to archive root).)
      @param(FileMask
             Only directories containing files matching this mask will be created.)
      @param(sDestPath
             Destination path where the files will be extracted.)
      @param(CurrentArchiveDir
             Path inside the archive from where the files will be extracted.)
      @param(CreatedPaths
             This list will be filled with absolute paths to directories
             that were created, together with their attributes.)}
    procedure CreateDirsAndCountFiles(const theFiles: TFiles; FileMask: String;
                                      sDestPath: String; CurrentArchiveDir: String;
                                      var CreatedPaths: TStringHashList);

    {en
      Sets attributes for directories.
      @param(Paths
             The list of absolute paths, which attributes are to be set.
             Each list item's data field must be a pointer to THeaderData,
             from where the attributes are retrieved.}
    function SetDirsAttributes(const Paths: TStringHashList): Boolean;

    procedure ShowError(sMessage: String; logOptions: TLogOptions = []);
    procedure LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);

  protected

  public
    constructor Create(aSourceFileSource: IFileSource;
                       aTargetFileSource: IFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;

    class procedure ClearCurrentOperation;
  end;

implementation

uses
  LCLProc, Masks, FileUtil, contnrs, uOSUtils, uDCUtils, WcxPlugin,
  uFileSourceOperationUI, uWCXmodule, uFileProcs, uLng, uDateTimeUtils, uTypes;

// ----------------------------------------------------------------------------
// WCX callbacks

var
  // WCX interface cannot discern different operations (for reporting progress),
  // so this global variable is used to store currently running operation.
  // (There may be other running concurrently, but only one may report progress.)
  WcxCopyOutOperation: TWcxArchiveCopyOutOperation = nil;

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

  if Assigned(WcxCopyOutOperation) then
  begin
    if WcxCopyOutOperation.State = fsosStopping then  // Cancel operation
      Exit(0);

    with WcxCopyOutOperation.FStatistics do
    begin
      if Size >= 0 then
      begin
        CurrentFileDoneBytes := CurrentFileDoneBytes + Size;
        DoneBytes := DoneBytes + Size;
      end
      else // For plugins which unpack in CloseArchive
      begin
        if (Size >= -100) and (Size <= -1) then // first percent bar
          begin
            CurrentFileDoneBytes := CurrentFileTotalBytes * (-Size) div 100;
            CurrentFileTotalBytes := 100;

            if Size = -100 then // File finished
              DoneBytes := DoneBytes + WcxCopyOutOperation.FCurrentFileSize;
            //DebugLn('Working ' + FileName + ' Percent1 = ' + IntToStr(FFileOpDlg.iProgress1Pos));
          end
        else if (Size >= -1100) and (Size <= -1000) then // second percent bar
          begin
            DoneBytes := TotalBytes * Int64(-Size - 1000) div 100;
            //DebugLn('Working ' + FileName + ' Percent2 = ' + IntToStr(FFileOpDlg.iProgress2Pos));
          end
        else
          begin
            DoneBytes := DoneBytes + WcxCopyOutOperation.FCurrentFileSize;
          end;
      end;

      WcxCopyOutOperation.UpdateStatistics(WcxCopyOutOperation.FStatistics);
    end;
  end;
end;

// ----------------------------------------------------------------------------

constructor TWcxArchiveCopyOutOperation.Create(aSourceFileSource: IFileSource;
                                               aTargetFileSource: IFileSource;
                                               var theSourceFiles: TFiles;
                                               aTargetPath: String);
begin
  FWcxArchiveFileSource := aSourceFileSource as IWcxArchiveFileSource;

  inherited Create(aSourceFileSource, aTargetFileSource, theSourceFiles, aTargetPath);
end;

destructor TWcxArchiveCopyOutOperation.Destroy;
begin
  ClearCurrentOperation;
  inherited Destroy;
end;

procedure TWcxArchiveCopyOutOperation.Initialize;
begin
  {$IFNDEF WcxAllowMultipleOperations}
  if Assigned(WcxCopyOutOperation) and (WcxCopyOutOperation <> Self) then
    raise Exception.Create('Another WCX copy operation is already running');
  {$ENDIF}

  WcxCopyOutOperation := Self;

  // Get initialized statistics; then we change only what is needed.
  FStatistics := RetrieveStatistics;
end;

procedure TWcxArchiveCopyOutOperation.MainExecute;
var
  ArcHandle: TArcHandle;
  Header: TWCXHeader;
  TargetFileName: String;
  FileMask: String;
  CreatedPaths: TStringHashList;
  OpenResult: Longint;
  iResult: Integer;
  Files: TFiles = nil;
  WcxModule: TWcxModule;
begin
  WcxModule := FWcxArchiveFileSource.WcxModule;

  ArcHandle := WcxModule.OpenArchiveHandle(FWcxArchiveFileSource.ArchiveFileName,
                                           PK_OM_EXTRACT,
                                           OpenResult);
  if ArcHandle = 0 then
  begin
    AskQuestion(uWcxModule.GetErrorMsg(OpenResult), '', [fsourOk], fsourOk, fsourOk);
    RaiseAbortOperation;
  end;

  FileMask := ExtractFileName(TargetPath);
  if FileMask = '' then FileMask := '*';  // extract all selected files/folders

  // Convert file list so that filenames are relative to archive root.
  Files := SourceFiles.Clone;
  ChangeFileListRoot(PathDelim, Files);

  CreatedPaths := TStringHashList.Create(True);

  try
    // Count total files size and create needed directories.
    CreateDirsAndCountFiles(Files, FileMask,
                            TargetPath, Files.Path,
                            CreatedPaths);

    {$IFDEF WcxAllowMultipleOperations}
    // Operation allowed to run, but not to report progress.
    if WcxCopyOutOperation <> Self then
    begin
      WcxModule.SetChangeVolProc(ArcHandle, nil);
      WcxModule.SetProcessDataProc(ArcHandle, nil);
    end
    else
    {$ENDIF}
    begin
      WcxModule.SetChangeVolProc(ArcHandle, @ChangeVolProc);
      WcxModule.SetProcessDataProc(ArcHandle, @ProcessDataProc);
    end;

    while (WcxModule.ReadWCXHeader(ArcHandle, Header) = E_SUCCESS) do
    try
      CheckOperationState;

      // Now check if the file is to be extracted.

      if  (not FPS_ISDIR(Header.FileAttr))           // Omit directories (we handle them ourselves).
      and MatchesFileList(Files, Header.FileName)    // Check if it's included in the filelist
      and ((FileMask = '*.*') or (FileMask = '*')    // And name matches file mask
          or MatchesMaskList(ExtractFileName(Header.FileName), FileMask))
      then
      begin
        TargetFileName := TargetPath + ExtractDirLevel(Files.Path, Header.FileName);

        with FStatistics do
        begin
          CurrentFileFrom := Header.FileName;
          CurrentFileTo := TargetFileName;
          CurrentFileTotalBytes := Header.UnpSize;
          CurrentFileDoneBytes := 0;

          UpdateStatistics(FStatistics);
          FCurrentFileSize := Header.UnpSize;
        end;

        iResult := WcxModule.ProcessFile(ArcHandle, PK_EXTRACT, nil, PAnsiChar(UTF8ToSys(TargetFileName)));

        if iResult <> E_SUCCESS then
        begin
          ShowError(Format(rsMsgLogError + rsMsgLogExtract,
                           [FWcxArchiveFileSource.ArchiveFileName + PathDelim +
                            Header.FileName + ' -> ' + TargetFileName +
                            ' - ' + GetErrorMsg(iResult)]), [log_arc_op]);

          // User aborted operation.
          if iResult = E_EABORTED then
            Break;
        end // Error
        else
        begin
          LogMessage(Format(rsMsgLogSuccess + rsMsgLogExtract,
                            [FWcxArchiveFileSource.ArchiveFileName + PathDelim +
                             Header.FileName +' -> ' + TargetFileName]), [log_arc_op], lmtSuccess);
        end; // Success
      end // Extract
      else // Skip
      begin
        iResult := WcxModule.ProcessFile(ArcHandle, PK_SKIP, nil, nil);

        //Check for errors
        if iResult <> E_SUCCESS then
        begin
          ShowError(Format(rsMsgLogError + rsMsgLogExtract,
                           [FWcxArchiveFileSource.ArchiveFileName + PathDelim +
                            Header.FileName + ' -> ' + TargetFileName +
                            ' - ' + GetErrorMsg(iResult)]), [log_arc_op]);
        end;
      end; // Skip

    finally
      FreeAndNil(Header);
    end;

    WcxModule.CloseArchive(ArcHandle);

    SetDirsAttributes(CreatedPaths);

  finally
    if Assigned(Files) then
      FreeAndNil(Files);
    FreeAndNil(CreatedPaths);
  end;
end;

procedure TWcxArchiveCopyOutOperation.Finalize;
begin
  ClearCurrentOperation;
end;

procedure TWcxArchiveCopyOutOperation.CreateDirsAndCountFiles(
              const theFiles: TFiles; FileMask: String;
              sDestPath: String; CurrentArchiveDir: String;
              var CreatedPaths: TStringHashList);
var
  // List of paths that we know must be created.
  PathsToCreate: TStringHashList;

  // List of possible directories to create with their attributes.
  // This hash list is created to speed up searches for attributes in archive file list.
  DirsAttributes: TStringHashList;

  i: Integer;
  CurrentFileName: String;
  Header: TWCXHeader;
  Directories: TStringList;
  PathIndex: Integer;
  ListIndex: Integer;
  TargetDir: String;
  FileList: TObjectList;
begin
  FileList := FWcxArchiveFileSource.ArchiveFileList;

  { First, collect all the paths that need to be created and their attributes. }

  PathsToCreate := TStringHashList.Create(True);
  DirsAttributes := TStringHashList.Create(True);

  for i := 0 to FileList.Count - 1 do
  begin
    Header := TWCXHeader(FileList.Items[i]);

    // Check if the file from the archive fits the selection given via SourceFiles.
    if not MatchesFileList(theFiles, Header.FileName) then
      Continue;

    if FPS_ISDIR(Header.FileAttr) then
    begin
      CurrentFileName := ExtractDirLevel(CurrentArchiveDir, Header.FileName);

      // Save this directory and a pointer to its entry.
      DirsAttributes.Add(CurrentFileName, Header);

      // If extracting all files and directories, add this directory
      // to PathsToCreate so that empty directories are also created.
      if (FileMask = '*.*') or (FileMask = '*') then
      begin
        // Paths in PathsToCreate list must end with path delimiter.
        CurrentFileName := IncludeTrailingPathDelimiter(CurrentFileName);

        if PathsToCreate.Find(CurrentFileName) < 0 then
          PathsToCreate.Add(CurrentFileName);
      end;
    end
    else
    begin
      if ((FileMask = '*.*') or (FileMask = '*') or
          MatchesMaskList(ExtractFileName(Header.FileName), FileMask)) then
      begin
        Inc(FStatistics.TotalBytes, Header.UnpSize);
        Inc(FStatistics.TotalFiles, 1);

        CurrentFileName := ExtractDirLevel(CurrentArchiveDir, ExtractFilePath(Header.FileName));

        // If CurrentFileName is empty now then it was a file in current archive
        // directory, therefore we don't have to create any paths for it.
        if Length(CurrentFileName) > 0 then
          if PathsToCreate.Find(CurrentFileName) < 0 then
            PathsToCreate.Add(CurrentFileName);
      end;
    end;
  end;

  { Second, create paths and save which paths were created and their attributes. }

  Directories := TStringList.Create;

  try
    sDestPath := IncludeTrailingPathDelimiter(sDestPath);

    // Create path to destination directory (we don't have attributes for that).
    mbForceDirectory(sDestPath);

    CreatedPaths.Clear;

    for PathIndex := 0 to PathsToCreate.Count - 1 do
    begin
      Directories.Clear;

      // Create also all parent directories of the path to create.
      // This adds directories to list in order from the outer to inner ones,
      // for example: dir, dir/dir2, dir/dir2/dir3.
      if GetDirs(PathsToCreate.List[PathIndex]^.Key, Directories) <> -1 then
      try
        for i := 0 to Directories.Count - 1 do
        begin
          TargetDir := sDestPath + Directories.Strings[i];

          if (CreatedPaths.Find(TargetDir) = -1) and
             (not DirPathExists(TargetDir)) then
          begin
             if mbForceDirectory(TargetDir) = False then
             begin
               // Error, cannot create directory.
               Break; // Don't try to create subdirectories.
             end
             else
             begin
               // Retrieve attributes for this directory, if they are stored.
               ListIndex := DirsAttributes.Find(Directories.Strings[i]);
               if ListIndex <> -1 then
                 Header := TWcxHeader(DirsAttributes.List[ListIndex]^.Data)
               else
                 Header := nil;

               CreatedPaths.Add(TargetDir, Header);
             end;
          end;
        end;
      except
      end;
    end;

  finally
    FreeAndNil(PathsToCreate);
    FreeAndNil(DirsAttributes);
    FreeAndNil(Directories);
  end;
end;

function TWcxArchiveCopyOutOperation.SetDirsAttributes(const Paths: TStringHashList): Boolean;
var
  PathIndex: Integer;
  TargetDir: String;
  Header: TWCXHeader;
  Time: TFileTime;
begin
  Result := True;

  for PathIndex := 0 to Paths.Count - 1 do
  begin
    // Get attributes.
    Header := TWCXHeader(Paths.List[PathIndex]^.Data);

    if Assigned(Header) then
    begin
      TargetDir := Paths.List[PathIndex]^.Key;

      try
{$IF DEFINED(MSWINDOWS)}
        // Restore attributes, e.g., hidden, read-only.
        // On Unix attributes value would have to be translated somehow.
        mbFileSetAttr(TargetDir, Header.FileAttr);

        DosToWinTime(TDosFileTime(Header.FileTime), Time);
{$ELSE}
  {$PUSH}{$R-}
        Time := Header.FileTime;
  {$POP}
{$ENDIF}

        // Set creation, modification time
        mbFileSetTime(TargetDir, Time, Time, Time);

      except
        Result := False;
      end;
    end;
  end;
end;

procedure TWcxArchiveCopyOutOperation.ShowError(sMessage: String; logOptions: TLogOptions);
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

procedure TWcxArchiveCopyOutOperation.LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
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

class procedure TWcxArchiveCopyOutOperation.ClearCurrentOperation;
begin
  WcxCopyOutOperation := nil;
end;

end.

