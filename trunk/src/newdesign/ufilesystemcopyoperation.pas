unit uFileSystemCopyOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceCopyOperation,
  uFileSystemFileSource,
  uFileSource,
  uFileSourceOperation,
  uFileSourceOperationOptions,
  uFileSourceOperationUI,
  uFile,
  uFileSystemFile,
  uDescr;

type
  {
    Both operations are the same, just source and target reversed.
    Implement them in terms of the same functions,
    or have one use the other.
  }

  TFileSystemCopyInOperation = class(TFileSourceCopyInOperation)

  private

  public
    constructor Create(var aSourceFileSource: TFileSource;
                       var aTargetFileSource: TFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String;
                       aRenameMask: String); override;

    procedure Execute; override;

  end;

  TFileSystemCopyOutOperation = class(TFileSourceCopyOutOperation)

  private
    FBuffer: Pointer;
    FBufferSize: LongWord;
    FFullSourceFilesTree: TFileSystemFiles;  // source files including all files/dirs in subdirectories
    FStatistics: TFileSourceCopyOperationStatistics; // local copy of statistics
    FRenameMask: String;
    FRenameNameMask, FRenameExtMask: String;
    FDescription: TDescription;

    // Options.
    FCheckFreeSpace: Boolean;
    FSkipAllBigFiles: Boolean;
    FDropReadOnlyFlag: Boolean;
    FSymLinkOption: TFileSourceOperationOptionSymLink;
    FFileExistsOption: TFileSourceOperationOptionFileExists;
    FDirExistsOption: TFileSourceOperationOptionDirectoryExists;

  protected
    function ProcessFile(aFile: TFileSystemFile; AbsoluteTargetFileName: String): Boolean;

    // ProcessFileNoQuestions (when we're sure the targets don't exist)

    function CopyFile(const SourceFileName, TargetFileName: String; bAppend: Boolean): Boolean;
    function ShowError(sMessage: String): TFileSourceOperationUIResponse;

  public
    constructor Create(var aSourceFileSource: TFileSource;
                       var aTargetFileSource: TFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String;
                       aRenameMask: String); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;
  end;

implementation

uses
  uOSUtils, uDCUtils, uFileProcs, uLng,
  uFileSystemUtil, strutils, uClassesEx, FileUtil, LCLProc, uGlobs, uLog;

// -- TFileSystemCopyInOperation ----------------------------------------------

constructor TFileSystemCopyInOperation.Create(var aSourceFileSource: TFileSource;
                                              var aTargetFileSource: TFileSource;
                                              var theSourceFiles: TFiles;
                                              aTargetPath: String;
                                              aRenameMask: String);
begin
  inherited Create(aSourceFileSource, aTargetFileSource, theSourceFiles, aTargetPath, aRenameMask);
end;

procedure TFileSystemCopyInOperation.Execute;
begin
end;

// -- TFileSystemCopyOutOperation ---------------------------------------------

constructor TFileSystemCopyOutOperation.Create(var aSourceFileSource: TFileSource;
                                               var aTargetFileSource: TFileSource;
                                               var theSourceFiles: TFiles;
                                               aTargetPath: String;
                                               aRenameMask: String);
begin
  FBuffer := nil;
  FFullSourceFilesTree := nil;
  FRenameMask := aRenameMask;

  // Here we can read global settings if there are any.
  FSymLinkOption := fsooslNone;
  FFileExistsOption := fsoofeNone;
  FDirExistsOption := fsoodeNone;
  FCheckFreeSpace := True;
  FSkipAllBigFiles := False;
  FDropReadOnlyFlag := False;

  if gProcessComments then
    FDescription := TDescription.Create(True)
  else
    FDescription := nil;

  inherited Create(aSourceFileSource, aTargetFileSource, theSourceFiles, aTargetPath, aRenameMask);
end;

destructor TFileSystemCopyOutOperation.Destroy;
begin
  inherited Destroy;

  if Assigned(FBuffer) then
  begin
    FreeMem(FBuffer);
    FBuffer := nil;
  end;

  if Assigned(FDescription) then
  begin
    FDescription.SaveDescription;
    FreeAndNil(FDescription);
  end;

  if Assigned(FFullSourceFilesTree) then
    FreeAndNil(FFullSourceFilesTree);
end;

procedure TFileSystemCopyOutOperation.Initialize;
begin
  SplitFileMask(FRenameMask, FRenameNameMask, FRenameExtMask);

  // Get initialized statistics; then we change only what is needed.
  FStatistics := RetrieveStatistics;

  FillAndCount(SourceFiles as TFileSystemFiles,
               FFullSourceFilesTree,
               FStatistics.TotalFiles,
               FStatistics.TotalBytes);     // gets full list of files (recursive)

  // Create destination path if it doesn't exist.
  if not mbDirectoryExists(TargetPath) then
    mbForceDirectory(TargetPath);

  FBufferSize := gCopyBlockSize;
  GetMem(FBuffer, FBufferSize);

  FDescription.Clear;
end;

procedure TFileSystemCopyOutOperation.MainExecute;
var
  aFile: TFileSystemFile;
  iTotalDiskSize, iFreeDiskSize: Int64;
  bProceed: Boolean;
  TargetName: String;
  OldDoneBytes: Int64; // for if there was an error
  CurrentFileIndex: Integer;
begin
  for CurrentFileIndex := 0 to FFullSourceFilesTree.Count - 1 do
  begin
    aFile := FFullSourceFilesTree[CurrentFileIndex] as TFileSystemFile;

    TargetName := GetAbsoluteTargetFileName(aFile,
                                            SourceFiles.Path,
                                            TargetPath,
                                            FRenameNameMask,
                                            FRenameExtMask);

    with FStatistics do
    begin
      CurrentFileFrom := aFile.Path + aFile.Name;
      CurrentFileTo := TargetName;
      CurrentFileTotalBytes := aFile.Size;
      CurrentFileDoneBytes := 0;
    end;

    UpdateStatistics(FStatistics);

    bProceed := True;

    { Check disk free space }
    if FCheckFreeSpace = True then
    begin
      GetDiskFreeSpace(TargetPath, iFreeDiskSize, iTotalDiskSize);
      if aFile.Size > iFreeDiskSize then
      begin
        if FSkipAllBigFiles = True then
        begin
          bProceed:= False;
        end
        else
        begin
          case AskQuestion('', rsMsgNoFreeSpaceCont,
                           [fsourYes, fsourAll, fsourNo, fsourSkip, fsourSkipAll],
                           fsourYes, fsourNo) of
            fsourNo:
              RaiseAbortOperation;

            fsourSkip:
              bProceed := False;

            fsourAll:
              FCheckFreeSpace := False;

            fsourSkipAll:
              begin
                bProceed := False;
                FSkipAllBigFiles := True;
              end;
          end;
        end;
      end;
    end;

    // If there will be an error in ProcessFile the DoneBytes value
    // will be inconsistent, so remember it here.
    OldDoneBytes := FStatistics.DoneBytes;

    if bProceed then
    begin
      bProceed := ProcessFile(aFile, TargetName);
    end;

    with FStatistics do
    begin
      DoneFiles := DoneFiles + 1;

      // Correct statistics if file not correctly processed.
      if not bProceed then
      begin
        DoneBytes := OldDoneBytes + aFile.Size;
      end;

      UpdateStatistics(FStatistics);
    end;

    CheckOperationState;
  end;
end;

procedure TFileSystemCopyOutOperation.Finalize;
begin
end;

function TFileSystemCopyOutOperation.ProcessFile(
             aFile: TFileSystemFile; AbsoluteTargetFileName: String): Boolean;
var
  sDstName: String;
  bIsFolder,
  bIsSymLink: Boolean;
  iAttr: TFileAttrs;
  sMsg: String;
  bAppend: Boolean = False;
begin
  // Check if copying to the same file.
  if CompareFilenames(aFile.Path + aFile.Name, AbsoluteTargetFileName) = 0 then
    Exit(False);

  if aFile.IsLink then
    begin
      // use sDstName as link target
      sDstName:= ReadSymLink(aFile.Path + aFile.Name);     // use sLinkTo ?
      if sDstName <> '' then
        begin
          sDstName:= GetAbsoluteFileName(aFile.Path, sDstName);
//          DebugLn('ReadSymLink := ' + sDstName);

          iAttr := mbFileGetAttr(AbsoluteTargetFileName);
          if iAttr <> faInvalidAttributes then // file exists
            begin
              bIsFolder:= FPS_ISDIR(iAttr);
              bIsSymLink:= FPS_ISLNK(iAttr);

              case FFileExistsOption of
                fsoofeSkip:  Exit(False);
                fsoofeNone:
                  begin
                    sMsg := IfThen(bIsFolder and not bIsSymLink, rsMsgFolderExistsRwrt, rsMsgFileExistsRwrt);
                    sMsg := Format(sMsg, [AbsoluteTargetFileName]);

                    case AskQuestion(sMsg, '',
                                     [fsourRewrite, fsourSkip, fsourRewriteAll, fsourSkipAll],
                                     fsourRewrite, fsourSkip) of
                      fsourSkip: Exit(False);
                      fsourRewrite: ; //continue
                      fsourRewriteAll:
                        begin
                          FFileExistsOption := fsoofeOverwrite;
                          //continue
                        end;
                      fsourSkipAll:
                        begin
                          FFileExistsOption := fsoofeSkip;
                          Exit(False);
                        end;
                    end; //case
                  end;
                // else continue
              end;

              if bIsFolder and bIsSymLink then // symlink to folder
                mbRemoveDir(AbsoluteTargetFileName)
              else if bIsFolder then // folder
                DelTree(AbsoluteTargetFileName)
              else // file
                mbDeleteFile(AbsoluteTargetFileName);
            end; // mbFileExists

          if not CreateSymlink(sDstName, AbsoluteTargetFileName) then
            DebugLn('Symlink error');
        end
      else
        DebugLn('Error reading link');
      Result:= True;
    end
  else if aFile.IsDirectory then
    begin
      if not mbDirectoryExists(AbsoluteTargetFileName) then
        mbForceDirectory(AbsoluteTargetFileName);
      // if preserve attrs/times - set them here
      Result:= True;
    end
  else
    begin // files and other stuff
      Result:= False;

      iAttr := mbFileGetAttr(AbsoluteTargetFileName);
      if iAttr <> faInvalidAttributes then // file exists
        begin
          if FPS_ISLNK(iAttr) then
            begin
              case FFileExistsOption of
                fsoofeSkip: Exit(False);
                fsoofeNone:
                  begin
                    sMsg := Format(rsMsgFileExistsRwrt, [AbsoluteTargetFileName]);
                    case AskQuestion(sMsg, '',
                                     [fsourRewrite, fsourSkip, fsourRewriteAll, fsourSkipAll],
                                     fsourRewrite, fsourSkip) of
                      fsourSkip: Exit(False);
                      fsourRewrite: ; //continue
                      fsourRewriteAll:
                        begin
                          FFileExistsOption := fsoofeOverwrite;
                          //continue
                        end;
                      fsourSkipAll:
                        begin
                          FFileExistsOption := fsoofeSkip;
                          Exit(False);
                        end;
                    end; //case
                  end;
              end;

              mbDeleteFile(AbsoluteTargetFileName);
            end // FPS_ISLNK
          else if FPS_ISDIR(iAttr) then
            begin
              // what if directory exists? ask if copy into it?
            end
          else // file
            begin
              case FFileExistsOption of
                fsoofeSkip: Exit(False);
                fsoofeAppend:
                  bAppend := True;
                fsoofeNone:
                  begin
                    sMsg := Format(rsMsgFileExistsRwrt, [AbsoluteTargetFileName]);
                    case AskQuestion(sMsg, '',
                                     [fsourRewrite, fsourSkip, fsourRewriteAll, fsourSkipAll, fsourAppend],
                                     fsourRewrite, fsourSkip) of
                      fsourSkip: Exit(False);
                      fsourRewrite: ; //continue
                      fsourRewriteAll:
                        begin
                          FFileExistsOption := fsoofeOverwrite;
                          //continue
                        end;
                      fsourSkipAll:
                        begin
                          FFileExistsOption := fsoofeSkip;
                          Exit(False);
                        end;
                      fsourAppend:
                        begin
                          //FFileExistsOption := fsoofeAppend; - append all
                          bAppend := True;
                        end;
                    end; //case
                  end;
              end; //case

//            if not bAppend then mbDeleteFile(AbsoluteTargetFileName);
            end;
        end; // file exists

      Result:= Self.CopyFile(aFile.Path + aFile.Name, AbsoluteTargetFileName, bAppend);

      // process comments if need
      if Result and gProcessComments then
        FDescription.CopyDescription(aFile.Path + aFile.Name, AbsoluteTargetFileName);

      if Result = True then
        begin
          // write log success
          if (log_cp_mv_ln in gLogOptions) and (log_success in gLogOptions) then
          begin
            logWrite(Thread, Format(rsMsgLogSuccess+rsMsgLogCopy,
                     [aFile.Path + aFile.Name+' -> '+AbsoluteTargetFileName]), lmtSuccess);
          end;
        end
      else
        begin
          // write log error
          if (log_cp_mv_ln in gLogOptions) and (log_errors in gLogOptions) then
          begin
            logWrite(Thread, Format(rsMsgLogError+rsMsgLogCopy,
                     [aFile.Path + aFile.Name+' -> '+AbsoluteTargetFileName]), lmtError);
          end;
        end;
    end; // files and other stuff
end;

function TFileSystemCopyOutOperation.CopyFile(const SourceFileName, TargetFileName: String; bAppend: Boolean): Boolean;
var
  SourceFile, TargetFile: TFileStreamEx;
  iTotalDiskSize, iFreeDiskSize: Int64;
  bRetryRead, bRetryWrite: Boolean;
  BytesRead, BytesToRead, BytesWrittenTry, BytesWritten: Int64;
  TotalBytesToRead: Int64 = 0;
begin
  Result:= False;
  BytesToRead := FBufferSize;
  SourceFile := nil;
  TargetFile := nil; // for safety exception handling
  try
    try
      SourceFile := TFileStreamEx.Create(SourceFileName, fmOpenRead or fmShareDenyNone);
      if bAppend then
        begin
          TargetFile:= TFileStreamEx.Create(TargetFileName, fmOpenReadWrite);
          TargetFile.Seek(0,soFromEnd); // seek to end
        end
      else
        begin
          TargetFile:= TFileStreamEx.Create(TargetFileName, fmCreate);
        end;

      TotalBytesToRead := SourceFile.Size;

      while TotalBytesToRead > 0 do
      begin
        // Without the following line the reading is very slow
        // if it tries to read past end of file.
        if TotalBytesToRead < BytesToRead then
          BytesToRead := TotalBytesToRead;

        repeat
          try
            bRetryRead := False;
            BytesRead := SourceFile.Read(FBuffer^, BytesToRead);

            if (BytesRead = 0) then
              Raise EReadError.Create(mbSysErrorMessage(GetLastOSError));

            TotalBytesToRead := TotalBytesToRead - BytesRead;
            BytesWritten := 0;

            repeat
              try
                bRetryWrite := False;
                BytesWrittenTry := TargetFile.Write((FBuffer + BytesWritten)^, BytesRead);
                BytesWritten := BytesWritten + BytesWrittenTry;
                if BytesWrittenTry = 0 then
                begin
                  Raise EWriteError.Create(mbSysErrorMessage(GetLastOSError));
                end
                else if BytesWritten < BytesRead then
                begin
                  bRetryWrite := True;   // repeat and try to write the rest
                end;
              except
                on E: EWriteError do
                  begin
                    { Check disk free space }
                    GetDiskFreeSpace(TargetPath, iFreeDiskSize, iTotalDiskSize);
                    if BytesRead > iFreeDiskSize then
                      begin
                        case AskQuestion(rsMsgNoFreeSpaceRetry, '',
                                         [fsourYes, fsourNo, fsourSkip],
                                         fsourYes, fsourNo) of
                          fsourYes:
                            bRetryWrite := True;
                          fsourNo:
                            RaiseAbortOperation;
                          fsourSkip:
                            Exit;
                        end; // case
                      end
                    else
                      begin
                        case AskQuestion(rsMsgErrEWrite + ' ' + TargetFileName + ':',
                                         E.Message,
                                         [fsourRetry, fsourSkip, fsourAbort],
                                         fsourRetry, fsourSkip) of
                          fsourRetry:
                            bRetryWrite := True;
                          fsourAbort:
                            RaiseAbortOperation;
                          fsourSkip:
                            Exit;
                        end; // case
                      end;

                  end; // on do
              end; // except
            until not bRetryWrite;
          except
            on E: EReadError do
              begin
                case AskQuestion(rsMsgErrERead + ' ' + SourceFileName + ':',
                                 E.Message,
                                 [fsourRetry, fsourSkip, fsourAbort],
                                 fsourRetry, fsourSkip) of
                  fsourRetry:
                    bRetryRead := True;
                  fsourAbort:
                    RaiseAbortOperation;
                  fsourSkip:
                    Exit;
                end; // case
              end;
          end;
        until not bRetryRead;

        with FStatistics do
        begin
          CurrentFileDoneBytes := CurrentFileDoneBytes + BytesRead;
          DoneBytes := DoneBytes + BytesRead;

          UpdateStatistics(FStatistics);
        end;

        CheckOperationState; // check pause and stop
      end;//while

    finally
      if assigned(SourceFile) then
        FreeAndNil(SourceFile);
      if assigned(TargetFile) then
      begin
        FreeAndNil(TargetFile);
        if TotalBytesToRead > 0 then
          // There was some error, because not all of the file has been copied.
          // Delete the not completed target file.
          mbDeleteFile(TargetFileName);
      end;
    end;
  // copy file attributes
  Result:= FileCopyAttr(SourceFileName, TargetFileName, FDropReadOnlyFlag);
  //if Preserve_attr
  except
    on EFCreateError do
      begin
        ShowError(rsMsgLogError + rsMsgErrECreate + ' - ' + TargetFileName);
      end;
    on EFOpenError do
      begin
        ShowError(rsMsgLogError + rsMsgErrEOpen + ' - ' + SourceFileName);
      end;
    on EWriteError do
      begin
        ShowError(rsMsgLogError + rsMsgErrEWrite + ' - ' + TargetFileName);
      end;
  end;
end;

function TFileSystemCopyOutOperation.ShowError(sMessage: String): TFileSourceOperationUIResponse;
begin
  if gSkipFileOpError then
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

end.

