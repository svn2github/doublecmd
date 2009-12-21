unit uFileSystemUtil;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLProc, uDescr, uLog, uGlobs,
  uFileSystemFile,
  uFile,
  uFileSourceOperation,
  uFileSourceOperationOptions,
  uFileSourceOperationUI,
  uFileSourceCopyOperation;

  procedure SplitFileMask(const DestMask: String; out DestNameMask: String; out DestExtMask: String);
  function ApplyRenameMask(aFile: TFile; NameMask: String; ExtMask: String): String;
  function GetAbsoluteTargetFileName(aFile: TFile; SourcePath: String; TargetPath: String;
                                     NameMask: String; ExtMask: String): String;
  procedure FillAndCount(Files: TFileSystemFiles;
                         CountDirs: Boolean;
                         out NewFiles: TFileSystemFiles;
                         out FilesCount: Int64;
                         out FilesSize: Int64);

type
  // Additional data for the filesystem tree node.
  TFileTreeNodeData = class
  public
    // True if any of the subnodes (recursively) are links.
    SubnodesHaveLinks: Boolean;

    constructor Create;
  end;

  TUpdateStatisticsFunction = procedure(var NewStatistics: TFileSourceCopyOperationStatistics) of object;

  TFileSystemOperationTargetExistsResult =
    (fsoterNotExists, fsoterDeleted, fsoterAddToTarget, fsoterSkip);

  TFileSystemOperationHelperMode =
    (fsohmCopy, fsohmMove);

  TFileSystemOperationHelperMoveOrCopy
    = function(SourceFile: TFileSystemFile; TargetFileName: String; bAppend: Boolean): Boolean of object;

  TFileSystemTreeBuilder = class
  private
    FFilesTree: TFileTree;
    FFilesCount: Int64;
    FDirectoriesCount: Int64;
    FFilesSize: Int64;
    FSymlinkOption: TFileSourceOperationOptionSymLink;
    FRecursive: Boolean;

    AskQuestion: TAskQuestionFunction;
    CheckOperationState: TCheckOperationStateFunction;

    procedure AddItem(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
    procedure AddFilesInDirectory(srcPath: String; CurrentNode: TFileTreeNode);
    procedure AddFile(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
    procedure AddLink(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
    procedure AddLinkTarget(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
    procedure AddDirectory(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
    procedure DecideOnLink(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);

    function GetItemsCount: Int64;

  public
    constructor Create(AskQuestionFunction: TAskQuestionFunction;
                       CheckOperationStateFunction: TCheckOperationStateFunction);
    destructor Destroy; override;

    procedure BuildFromFiles(Files: TFileSystemFiles);
    function ReleaseTree: TFileTree;

    property Recursive: Boolean read FRecursive write FRecursive;
    property SymLinkOption: TFileSourceOperationOptionSymLink read FSymlinkOption write FSymlinkOption;

    property FilesTree: TFileTree read FFilesTree;
    property FilesSize: Int64 read FFilesSize;
    property FilesCount: Int64 read FFilesCount;
    property DirectoriesCount: Int64 read FDirectoriesCount;
    property ItemsCount: Int64 read GetItemsCount;
  end;

  TFileSystemOperationHelper = class
  private
    FOperationThread: TThread;
    FMode: TFileSystemOperationHelperMode;
    FBuffer: Pointer;
    FBufferSize: LongWord;
    FRootTargetPath: String;
    FRenameMask: String;
    FRenameNameMask, FRenameExtMask: String;
    FStatistics: TFileSourceCopyOperationStatistics; // local copy of statistics
    FDescription: TDescription;
    FLogCaption: String;
    FRenamingFiles: Boolean;
    FCheckFreeSpace: Boolean;
    FSkipAllBigFiles: Boolean;
    FDropReadOnlyAttribute: Boolean;
    FCorrectSymLinks: Boolean;
    FFileExistsOption: TFileSourceOperationOptionFileExists;
    FDirExistsOption: TFileSourceOperationOptionDirectoryExists;

    AskQuestion: TAskQuestionFunction;
    AbortOperation: TAbortOperationFunction;
    CheckOperationState: TCheckOperationStateFunction;
    UpdateStatistics: TUpdateStatisticsFunction;
    MoveOrCopy: TFileSystemOperationHelperMoveOrCopy;

    procedure ShowError(sMessage: String);
    procedure LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);

    function CopyFile(SourceFile: TFileSystemFile; TargetFileName: String; bAppend: Boolean): Boolean;
    function MoveFile(SourceFile: TFileSystemFile; TargetFileName: String; bAppend: Boolean): Boolean;

    function ProcessNode(aFileTreeNode: TFileTreeNode; CurrentTargetPath: String): Boolean;
    function ProcessDirectory(aNode: TFileTreeNode; AbsoluteTargetFileName: String): Boolean;
    function ProcessLink(aNode: TFileTreeNode; AbsoluteTargetFileName: String): Boolean;
    function ProcessFile(aNode: TFileTreeNode; AbsoluteTargetFileName: String): Boolean;

    function TargetExists(aNode: TFileTreeNode; AbsoluteTargetFileName: String)
                 : TFileSystemOperationTargetExistsResult;
    function DirExists(aFile: TFileSystemFile;
                       AbsoluteTargetFileName: String;
                       AllowCopyInto: Boolean): TFileSourceOperationOptionDirectoryExists;
    function FileExists(aFile: TFileSystemFile;
                        AbsoluteTargetFileName: String;
                        AllowAppend: Boolean): TFileSourceOperationOptionFileExists;

    procedure CountStatistics(aNode: TFileTreeNode);

  public
    constructor Create(AskQuestionFunction: TAskQuestionFunction;
                       AbortOperationFunction: TAbortOperationFunction;
                       CheckOperationStateFunction: TCheckOperationStateFunction;
                       UpdateStatisticsFunction: TUpdateStatisticsFunction;
                       OperationThread: TThread;
                       Mode: TFileSystemOperationHelperMode;
                       TargetPath: String;
                       StartingStatistics: TFileSourceCopyOperationStatistics);
    destructor Destroy; override;

    procedure Initialize;

    procedure ProcessTree(aFileTree: TFileTree);

    property FileExistsOption: TFileSourceOperationOptionFileExists read FFileExistsOption write FFileExistsOption;
    property DirExistsOption: TFileSourceOperationOptionDirectoryExists read FDirExistsOption write FDirExistsOption;
    property CheckFreeSpace: Boolean read FCheckFreeSpace write FCheckFreeSpace;
    property SkipAllBigFiles: Boolean read FSkipAllBigFiles write FSkipAllBigFiles;
    property DropReadOnlyAttribute: Boolean read FDropReadOnlyAttribute write FDropReadOnlyAttribute;
    property CorrectSymLinks: Boolean read FCorrectSymLinks write FCorrectSymLinks;
    property RenameMask: String read FRenameMask write FRenameMask;
  end;

implementation

uses
  uOSUtils, uDCUtils, FileUtil, uFindEx, uClassesEx, uFileProcs, uLng, uTypes;

procedure SplitFileMask(const DestMask: String; out DestNameMask: String; out DestExtMask: String);
begin
  DivFileName(DestMask, DestNameMask, DestExtMask);
  // Treat empty mask as '*.*'.
  if (DestNameMask = '') and (DestExtMask = '') then
  begin
    DestNameMask := '*';
    DestExtMask  := '.*';
  end;
end;

function ApplyRenameMask(aFile: TFile; NameMask: String; ExtMask: String): String;

  function ApplyMask(const TargetString: String; Mask: String): String;
  var
    i:Integer;
  begin
    Result:='';
    for i:=1 to Length(Mask) do
    begin
      if Mask[i]= '?' then
        Result:=Result + TargetString[i]
      else
      if Mask[i]= '*' then
        Result:=Result + Copy(TargetString, i, Length(TargetString) - i + 1)
      else
        Result:=Result + Mask[i];
    end;
  end;

var
  sDstExt: String;
  sDstName: String;
begin
  if ((NameMask = '*') and (ExtMask = '.*')) or
     // Only change name for files.
     aFile.IsDirectory or aFile.IsLink then
  begin
    Result := aFile.Name;
  end
  else
  begin
    DivFileName(aFile.Name, sDstName, sDstExt);
    sDstName := ApplyMask(sDstName, NameMask);
    sDstExt  := ApplyMask(sDstExt, ExtMask);

    Result := sDstName;
    if sDstExt <> '.' then
      Result := Result + sDstExt;
  end;
end;

function GetAbsoluteTargetFileName(aFile: TFile; SourcePath: String; TargetPath: String;
                                   NameMask: String; ExtMask: String): String;
begin
  Result := TargetPath + ExtractDirLevel(SourcePath, aFile.Path)
          + ApplyRenameMask(aFile, NameMask, ExtMask);
end;

procedure FillAndCount(Files: TFileSystemFiles; CountDirs: Boolean;
  out NewFiles: TFileSystemFiles; out FilesCount: Int64; out FilesSize: Int64);

  procedure FillAndCountRec(const srcPath: String);
  var
    sr: TSearchRecEx;
    aFile: TFileSystemFile;
  begin
    if FindFirstEx(srcPath + '*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Name='.') or (sr.Name='..') then Continue;
        aFile := TFileSystemFile.Create(sr);
        aFile.Path := srcPath;

        // For process symlinks, read only files etc.
  //      CheckFile(aFile);

        NewFiles.Add(aFile);
        if aFile.IsLink then
        begin
        end
        else if aFile.IsDirectory then
        begin
          if CountDirs then
            Inc(FilesCount);
          FillAndCountRec(srcPath + sr.Name + DirectorySeparator); // go down to directory
        end
        else
        begin
          Inc(FilesSize, aFile.Size);
          Inc(FilesCount);
        end;
      until FindNextEx(sr) <> 0;
    end;

    FindCloseEx(sr);
  end;

var
  i: Integer;
  aFile: TFileSystemFile;
begin
  NewFiles := TFileSystemFiles.Create;
  NewFiles.Path := Files.Path;
  FilesCount:= 0;
  FilesSize:= 0;
  for i := 0 to Files.Count - 1 do
  begin
    aFile := Files[i];

    // For process symlinks, read only files etc.
    //CheckFile(aFile);

    NewFiles.Add(aFile.Clone);

    if aFile.IsDirectory and (not aFile.IsLinkToDirectory) then
    begin
      if CountDirs then
        Inc(FilesCount);
      FillAndCountRec(aFile.Path + aFile.Name + DirectorySeparator);  // recursive browse child dir
    end
    else
    begin
      Inc(FilesCount);
      Inc(FilesSize, aFile.Size); // in first level we know file size -> use it
    end;
  end;
end;

// ----------------------------------------------------------------------------

constructor TFileTreeNodeData.Create;
begin
  SubnodesHaveLinks := False;
end;

// ----------------------------------------------------------------------------

constructor TFileSystemTreeBuilder.Create(AskQuestionFunction: TAskQuestionFunction;
                                          CheckOperationStateFunction: TCheckOperationStateFunction);
begin
  AskQuestion := AskQuestionFunction;
  CheckOperationState := CheckOperationStateFunction;

  FFilesTree := nil;
  FRecursive := True;
  FSymlinkOption := fsooslNone;
end;

destructor TFileSystemTreeBuilder.Destroy;
begin
  inherited Destroy;

  if Assigned(FFilesTree) then
    FreeAndNil(FFilesTree);
end;

procedure TFileSystemTreeBuilder.BuildFromFiles(Files: TFileSystemFiles);
var
  i: Integer;
  aFile: TFileSystemFile;
begin
  if Assigned(FFilesTree) then
    FreeAndNil(FFilesTree);

  FFilesTree := TFileTreeNode.Create;
  FFilesTree.Data := TFileTreeNodeData.Create;
  FFilesSize := 0;
  FFilesCount := 0;
  FDirectoriesCount := 0;

  for i := 0 to Files.Count - 1 do
  begin
    aFile := Files[i] as TFileSystemFile;
    AddItem(aFile.Clone, FFilesTree);
  end;
end;

procedure TFileSystemTreeBuilder.AddFile(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
var
  AddedNode: TFileTreeNode;
  AddedIndex: Integer;
begin
  AddedIndex := CurrentNode.AddSubNode(aFile);
  AddedNode := CurrentNode.SubNodes[AddedIndex];
  AddedNode.Data := TFileTreeNodeData.Create;

  Inc(FFilesCount);
  Inc(FFilesSize, aFile.Size);
end;

procedure TFileSystemTreeBuilder.AddLink(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
var
  AddedNode: TFileTreeNode;
  AddedIndex: Integer;
begin
  AddedIndex := CurrentNode.AddSubNode(aFile);
  AddedNode := CurrentNode.SubNodes[AddedIndex];
  AddedNode.Data := TFileTreeNodeData.Create;

  (CurrentNode.Data as TFileTreeNodeData).SubnodesHaveLinks := True;

  Inc(FFilesCount);
end;

procedure TFileSystemTreeBuilder.AddLinkTarget(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
var
  LinkedFilePath: String;
  LinkedFile: TFileSystemFile = nil;
  AddedNode: TFileTreeNode;
  AddedIndex: Integer;
begin
  LinkedFilePath := mbReadAllLinks(aFile.FullPath);
  if LinkedFilePath <> '' then
  begin
    try
      LinkedFile := TFileSystemFile.Create(LinkedFilePath);

      // Add link to current node.
      AddedIndex := CurrentNode.AddSubNode(aFile);
      AddedNode := CurrentNode.SubNodes[AddedIndex];
      AddedNode.Data := TFileTreeNodeData.Create;
      (CurrentNode.Data as TFileTreeNodeData).SubnodesHaveLinks := True;

      // Then add linked file/directory as a subnode of the link.
      AddItem(LinkedFile, AddedNode);

    except
      on EFileSystemFileNotExists do
        begin
          // Link target doesn't exist - add symlink instead of target (or ask user).
          AddLink(aFile, CurrentNode);
        end;
    end;
  end
  else
  begin
    // error - cannot follow symlink - adding symlink instead of target (or ask user)
    AddLink(aFile, CurrentNode);
  end;
end;

procedure TFileSystemTreeBuilder.AddDirectory(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
var
  AddedNode: TFileTreeNode;
  AddedIndex: Integer;
begin
  AddedIndex := CurrentNode.AddSubNode(aFile);
  AddedNode := CurrentNode.SubNodes[AddedIndex];
  AddedNode.Data := TFileTreeNodeData.Create;

  Inc(FDirectoriesCount);

  if FRecursive then
  begin
    AddFilesInDirectory(aFile.FullPath + DirectorySeparator, AddedNode);

    // Propagate flag to parent.
    if (AddedNode.Data as TFileTreeNodeData).SubnodesHaveLinks then
      (CurrentNode.Data as TFileTreeNodeData).SubnodesHaveLinks := True;
  end;
end;

procedure TFileSystemTreeBuilder.DecideOnLink(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
begin
  case FSymLinkOption of
    fsooslFollow:
      AddLinkTarget(aFile, CurrentNode);
    fsooslDontFollow:
      AddLink(aFile, CurrentNode);
    fsooslNone:
      begin
        case AskQuestion('', Format(rsMsgFollowSymlink, [aFile.Name]),
                       [fsourYes, fsourAll, fsourNo, fsourSkipAll],
                       fsourYes, fsourNo)
        of
          fsourYes:
            AddLinkTarget(aFile, CurrentNode);
          fsourAll:
            begin
              FSymLinkOption := fsooslFollow;
              AddLinkTarget(aFile, CurrentNode);
            end;
          fsourNo:
            AddLink(aFile, CurrentNode);
          fsourSkipAll:
            begin
              FSymLinkOption := fsooslDontFollow;
              AddLink(aFile, CurrentNode);
            end;
          else
            raise Exception.Create('Invalid user response');
        end;
      end;
    else
      raise Exception.Create('Invalid symlink option');
  end;
end;

procedure TFileSystemTreeBuilder.AddItem(aFile: TFileSystemFile; CurrentNode: TFileTreeNode);
begin
  if aFile.IsDirectory then
    AddDirectory(aFile, CurrentNode)
  else if aFile.IsLink then
    DecideOnLink(aFile, CurrentNode)
  else
    AddFile(aFile, CurrentNode);
end;

procedure TFileSystemTreeBuilder.AddFilesInDirectory(
              srcPath: String;
              CurrentNode: TFileTreeNode);
var
  sr: TSearchRecEx;
  aFile: TFileSystemFile;
begin
  if FindFirstEx(srcPath + '*', faAnyFile, sr) = 0 then
  begin
    repeat
      if (sr.Name = '.') or (sr.Name = '..') then Continue;

      aFile := TFileSystemFile.Create(sr);
      aFile.Path := srcPath;

      AddItem(aFile, CurrentNode);
    until FindNextEx(sr) <> 0;
  end;

  FindCloseEx(sr);
end;

function TFileSystemTreeBuilder.ReleaseTree: TFileTree;
begin
  Result := FFilesTree;
  FFilesTree := nil;
end;

function TFileSystemTreeBuilder.GetItemsCount: Int64;
begin
  Result := FilesCount + DirectoriesCount;
end;

// ----------------------------------------------------------------------------

constructor TFileSystemOperationHelper.Create(AskQuestionFunction: TAskQuestionFunction;
                                         AbortOperationFunction: TAbortOperationFunction;
                                         CheckOperationStateFunction: TCheckOperationStateFunction;
                                         UpdateStatisticsFunction: TUpdateStatisticsFunction;
                                         OperationThread: TThread;
                                         Mode: TFileSystemOperationHelperMode;
                                         TargetPath: String;
                                         StartingStatistics: TFileSourceCopyOperationStatistics);
begin
  AskQuestion := AskQuestionFunction;
  AbortOperation := AbortOperationFunction;
  CheckOperationState := CheckOperationStateFunction;
  UpdateStatistics := UpdateStatisticsFunction;

  FOperationThread := OperationThread;
  FMode := Mode;

  FBufferSize := gCopyBlockSize;
  GetMem(FBuffer, FBufferSize);

  FCheckFreeSpace := True;
  FSkipAllBigFiles := False;
  FDropReadOnlyAttribute := False;
  FFileExistsOption := fsoofeNone;
  FDirExistsOption := fsoodeNone;
  FRootTargetPath := TargetPath;
  FRenameMask := '';
  FStatistics := StartingStatistics;
  FRenamingFiles := False;

  if gProcessComments then
    FDescription := TDescription.Create(True)
  else
    FDescription := nil;

  case FMode of
    fsohmCopy:
      begin
        MoveOrCopy := @CopyFile;
        FLogCaption := rsMsgLogCopy;
      end;
    fsohmMove:
      begin
        MoveOrCopy := @MoveFile;
        FLogCaption := rsMsgLogMove;
      end;
    else
      raise Exception.Create('Invalid operation mode');
  end;

  inherited Create;
end;

destructor TFileSystemOperationHelper.Destroy;
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
end;

procedure TFileSystemOperationHelper.Initialize;
begin
  SplitFileMask(FRenameMask, FRenameNameMask, FRenameExtMask);

  FRenamingFiles := (FRenameMask <> '*.*') and (FRenameMask <> '');

  // Create destination path if it doesn't exist.
  if not mbDirectoryExists(FRootTargetPath) then
    if not mbForceDirectory(FRootTargetPath) then
      Exit; // do error
end;

procedure TFileSystemOperationHelper.ProcessTree(aFileTree: TFileTree);
begin
  ProcessNode(aFileTree, FRootTargetPath);
end;

// ----------------------------------------------------------------------------

function TFileSystemOperationHelper.CopyFile(
           SourceFile: TFileSystemFile;
           TargetFileName: String;
           bAppend: Boolean): Boolean;
var
  SourceFileStream, TargetFileStream: TFileStreamEx;
  iTotalDiskSize, iFreeDiskSize: Int64;
  bRetryRead, bRetryWrite: Boolean;
  BytesRead, BytesToRead, BytesWrittenTry, BytesWritten: Int64;
  TotalBytesToRead: Int64 = 0;
begin
  Result := False;

  { Check disk free space }
  if FCheckFreeSpace = True then
  begin
    GetDiskFreeSpace(ExtractFilePath(TargetFileName), iFreeDiskSize, iTotalDiskSize);
    if SourceFile.Size > iFreeDiskSize then
    begin
      if FSkipAllBigFiles = True then
      begin
        Exit;
      end
      else
      begin
        case AskQuestion('', rsMsgNoFreeSpaceCont,
                         [fsourYes, fsourAll, fsourNo, fsourSkip, fsourSkipAll],
                         fsourYes, fsourNo) of
          fsourNo:
            AbortOperation;

          fsourSkip:
            Exit;

          fsourAll:
            FCheckFreeSpace := False;

          fsourSkipAll:
            begin
              FSkipAllBigFiles := True;
              Exit;
            end;
        end;
      end;
    end;
  end;

  BytesToRead := FBufferSize;
  SourceFileStream := nil;
  TargetFileStream := nil; // for safety exception handling
  try
    try
      SourceFileStream := TFileStreamEx.Create(SourceFile.FullPath, fmOpenRead or fmShareDenyNone);
      if bAppend then
        begin
          TargetFileStream := TFileStreamEx.Create(TargetFileName, fmOpenReadWrite);
          TargetFileStream.Seek(0, soFromEnd); // seek to end
        end
      else
        begin
          TargetFileStream := TFileStreamEx.Create(TargetFileName, fmCreate);
        end;

      TotalBytesToRead := SourceFileStream.Size;

      while TotalBytesToRead > 0 do
      begin
        // Without the following line the reading is very slow
        // if it tries to read past end of file.
        if TotalBytesToRead < BytesToRead then
          BytesToRead := TotalBytesToRead;

        repeat
          try
            bRetryRead := False;
            BytesRead := SourceFileStream.Read(FBuffer^, BytesToRead);

            if (BytesRead = 0) then
              Raise EReadError.Create(mbSysErrorMessage(GetLastOSError));

            TotalBytesToRead := TotalBytesToRead - BytesRead;
            BytesWritten := 0;

            repeat
              try
                bRetryWrite := False;
                BytesWrittenTry := TargetFileStream.Write((FBuffer + BytesWritten)^, BytesRead);
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
                    GetDiskFreeSpace(ExtractFilePath(TargetFileName), iFreeDiskSize, iTotalDiskSize);
                    if BytesRead > iFreeDiskSize then
                      begin
                        case AskQuestion(rsMsgNoFreeSpaceRetry, '',
                                         [fsourYes, fsourNo, fsourSkip],
                                         fsourYes, fsourNo) of
                          fsourYes:
                            bRetryWrite := True;
                          fsourNo:
                            AbortOperation;
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
                            AbortOperation;
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
                case AskQuestion(rsMsgErrERead + ' ' + SourceFile.FullPath + ':',
                                 E.Message,
                                 [fsourRetry, fsourSkip, fsourAbort],
                                 fsourRetry, fsourSkip) of
                  fsourRetry:
                    bRetryRead := True;
                  fsourAbort:
                    AbortOperation;
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
      if Assigned(SourceFileStream) then
        FreeAndNil(SourceFileStream);
      if Assigned(TargetFileStream) then
      begin
        FreeAndNil(TargetFileStream);
        if TotalBytesToRead > 0 then
          // There was some error, because not all of the file has been copied.
          // Delete the not completed target file.
          mbDeleteFile(TargetFileName);
      end;
    end;

    // copy file attributes
    Result := FileCopyAttr(SourceFile.FullPath, TargetFileName, FDropReadOnlyAttribute);

  except
    on EFCreateError do
      begin
        ShowError(rsMsgLogError + rsMsgErrECreate + ': ' + TargetFileName);
      end;
    on EFOpenError do
      begin
        ShowError(rsMsgLogError + rsMsgErrEOpen + ': ' + SourceFile.FullPath);
      end;
    on EWriteError do
      begin
        ShowError(rsMsgLogError + rsMsgErrEWrite + ': ' + TargetFileName);
      end;
  end;
end;

function TFileSystemOperationHelper.MoveFile(SourceFile: TFileSystemFile; TargetFileName: String; bAppend: Boolean): Boolean;
begin
  if bAppend or (not mbRenameFile(SourceFile.FullPath, TargetFileName)) then
  begin
    if CopyFile(SourceFile, TargetFileName, bAppend) then
      Result := mbDeleteFile(SourceFile.FullPath)
    else
      Result := False;
  end
  else
    Result := True;
end;

function TFileSystemOperationHelper.ProcessNode(aFileTreeNode: TFileTreeNode;
                                                CurrentTargetPath: String): Boolean;
var
  aFile: TFileSystemFile;
  ProcessedOk: Boolean;
  TargetName: String;
  CurrentFileIndex: Integer;
  CurrentSubNode: TFileTreeNode;
begin
  Result := True;

  for CurrentFileIndex := 0 to aFileTreeNode.SubNodesCount - 1 do
  begin
    CurrentSubNode := aFileTreeNode.SubNodes[CurrentFileIndex];
    aFile := CurrentSubNode.TheFile as TFileSystemFile;

    TargetName := CurrentTargetPath + ApplyRenameMask(aFile, FRenameNameMask, FRenameExtMask);

    with FStatistics do
    begin
      CurrentFileFrom := aFile.Path + aFile.Name;
      CurrentFileTo := TargetName;
      CurrentFileTotalBytes := aFile.Size;
      CurrentFileDoneBytes := 0;
    end;

    UpdateStatistics(FStatistics);

    // Check if moving to the same file.
    if CompareFilenames(aFile.Path + aFile.Name, TargetName) = 0 then
    begin
      ProcessedOk := False;
      CountStatistics(CurrentSubNode);
    end
    else if aFile.IsDirectory then
      ProcessedOk := ProcessDirectory(CurrentSubNode, TargetName)
    else if aFile.IsLink then
      ProcessedOk := ProcessLink(CurrentSubNode, TargetName)
    else
      ProcessedOk := ProcessFile(CurrentSubNode, TargetName);

    if not ProcessedOk then
      Result := False;

    CheckOperationState;
  end;
end;

function TFileSystemOperationHelper.ProcessDirectory(aNode: TFileTreeNode; AbsoluteTargetFileName: String): Boolean;
var
  bRemoveDirectory: Boolean;
  aFile: TFileSystemFile;
begin
  bRemoveDirectory := (FMode = fsohmMove);
  aFile := aNode.TheFile as TFileSystemFile;

  case TargetExists(aNode, AbsoluteTargetFileName) of
    fsoterSkip:
      begin
        Result := False;
        CountStatistics(aNode);
      end;

    fsoterDeleted, fsoterNotExists:
      begin
        // Try moving whole directory tree. It can be done only if we don't have
        // to process each subnode: if there are no links, or they're not being
        // processed and if the files are not being renamed.
        if (FMode = fsohmMove) and
           (not FRenamingFiles) and
           ((FCorrectSymlinks = False) or
            ((aNode.Data as TFileTreeNodeData).SubnodesHaveLinks = False)) and
           mbRenameFile(aNode.TheFile.FullPath, AbsoluteTargetFileName) then
        begin
          // Success.
          CountStatistics(aNode);
          Result := True;
          bRemoveDirectory := False;
        end
        else
        begin
          // Create target directory.
          if mbForceDirectory(AbsoluteTargetFileName) then
          begin
            FileCopyAttr(aNode.TheFile.FullPath, AbsoluteTargetFileName, False);
            // Copy/Move all files inside.
            Result := ProcessNode(aNode, IncludeTrailingPathDelimiter(AbsoluteTargetFileName));
          end
          else
          begin
            // Error - all files inside not copied/moved.
            ShowError(rsMsgLogError + Format(rsMsgErrForceDir, [AbsoluteTargetFileName]));
            Result := False;
            CountStatistics(aNode);
          end;
        end;
      end;

    fsoterAddToTarget:
      begin
        // Don't create existing directory, but copy files into it.
        Result := ProcessNode(aNode, IncludeTrailingPathDelimiter(AbsoluteTargetFileName));
      end;

    else
      raise Exception.Create('Invalid TargetExists result');
  end;

  if bRemoveDirectory and Result then
    mbRemoveDir(aFile.FullPath);
end;

function TFileSystemOperationHelper.ProcessLink(aNode: TFileTreeNode; AbsoluteTargetFileName: String): Boolean;
var
  LinkTarget, CorrectedLink: String;
  aFile: TFileSystemFile;
  aSubNode: TFileTreeNode;
begin
  aFile := aNode.TheFile as TFileSystemFile;
  Result := True;

  // If link was followed then it's target is stored in a subnode.
  if aNode.SubNodesCount > 0 then
  begin
    aSubNode := aNode.SubNodes[0];
    //DebugLn('Link ' + aFile.FullPath + ' followed to '
    //        + (aSubNode.TheFile as TFileSystemFile).FullPath
    //        + ' will be copied as: ' + AbsoluteTargetFileName);
    aFile := aSubNode.TheFile as TFileSystemFile;
    if aFile.IsDirectory then
      Result := ProcessDirectory(aSubNode, AbsoluteTargetFileName)
    else
      Result := ProcessFile(aSubNode, AbsoluteTargetFileName);

    Exit; // exit without counting statistics, because they are not counted for followed links
  end;

  case TargetExists(aNode, AbsoluteTargetFileName) of
    fsoterSkip:
      Result := False;

    fsoterDeleted, fsoterNotExists:
      begin
        if (FMode <> fsohmMove) or
           (not mbRenameFile(aFile.FullPath, AbsoluteTargetFileName)) then
        begin
          LinkTarget := ReadSymLink(aFile.Path + aFile.Name);     // use sLinkTo ?
          if LinkTarget <> '' then
          begin
            if FCorrectSymlinks then
            begin
              CorrectedLink := GetAbsoluteFileName(aFile.Path, LinkTarget);

              // If the link was relative - make also the corrected link relative.
              if uDCUtils.GetPathType(LinkTarget) = ptRelative then
                LinkTarget := ExtractRelativepath(AbsoluteTargetFileName, CorrectedLink)
              else
                LinkTarget := CorrectedLink;
            end;

            if CreateSymlink(LinkTarget, AbsoluteTargetFileName) then
            begin
              FileCopyAttr(aFile.FullPath, AbsoluteTargetFileName, False);
            end
            else
            begin
              ShowError(rsMsgLogError + Format(rsMsgLogSymLink, [AbsoluteTargetFileName]));
              Result := False;
            end;
          end
          else
          begin
            DebugLn('Error reading link');
            Result := False;
          end;
        end;
      end;

    fsoterAddToTarget:
      raise Exception.Create('Cannot add to link');

    else
      raise Exception.Create('Invalid TargetExists result');
  end;

  Inc(FStatistics.DoneFiles);
  UpdateStatistics(FStatistics);
end;

function TFileSystemOperationHelper.ProcessFile(aNode: TFileTreeNode; AbsoluteTargetFileName: String): Boolean;
var
  aFile: TFileSystemFile;
  OldDoneBytes: Int64; // for if there was an error
begin
  aFile := aNode.TheFile as TFileSystemFile;
  Result:= False;

  // If there will be an error the DoneBytes value
  // will be inconsistent, so remember it here.
  OldDoneBytes := FStatistics.DoneBytes;

  case TargetExists(aNode, AbsoluteTargetFileName) of
    fsoterSkip:
      Result := False;

    fsoterDeleted, fsoterNotExists:
      Result := MoveOrCopy(aFile, AbsoluteTargetFileName, False);

    fsoterAddToTarget:
      Result := MoveOrCopy(aFile, AbsoluteTargetFileName, True);

    else
      raise Exception.Create('Invalid TargetExists result');
  end;

  if Result = True then
    begin
      LogMessage(Format(rsMsgLogSuccess+FLogCaption, [aFile.FullPath + ' -> ' + AbsoluteTargetFileName]),
                 [log_cp_mv_ln], lmtSuccess);

      // process comments if need
      if gProcessComments then
      begin
        case FMode of
          fsohmCopy:
            FDescription.CopyDescription(aFile.Path + aFile.Name, AbsoluteTargetFileName);
          fsohmMove:
            FDescription.MoveDescription(aFile.Path + aFile.Name, AbsoluteTargetFileName);
        end;
      end;
    end
  else
    begin
      LogMessage(Format(rsMsgLogError+FLogCaption, [aFile.FullPath + ' -> ' + AbsoluteTargetFileName]),
                 [log_cp_mv_ln], lmtError);
    end;

  with FStatistics do
  begin
    DoneFiles := DoneFiles + 1;
    DoneBytes := OldDoneBytes + aFile.Size;
    UpdateStatistics(FStatistics);
  end;
end;

// ----------------------------------------------------------------------------

function TFileSystemOperationHelper.TargetExists(
             aNode: TFileTreeNode;
             AbsoluteTargetFileName: String): TFileSystemOperationTargetExistsResult;
var
  Attrs, LinkTargetAttrs: TFileAttrs;
  aFile: TFileSystemFile;

  function DoDirectoryExists(AllowCopyInto: Boolean): TFileSystemOperationTargetExistsResult;
  begin
    case DirExists(aFile, AbsoluteTargetFileName, AllowCopyInto) of
      fsoodeSkip:
        Exit(fsoterSkip);
      fsoodeDelete:
        begin
          if FPS_ISLNK(Attrs) then
            mbDeleteFile(AbsoluteTargetFileName)
          else
            DelTree(AbsoluteTargetFileName);
          Exit(fsoterDeleted);
        end;
      fsoodeCopyInto:
        begin
          Exit(fsoterAddToTarget);
        end;
      else
        raise Exception.Create('Invalid dir exists option');
    end;
  end;

  function DoFileExists(AllowAppend: Boolean): TFileSystemOperationTargetExistsResult;
  begin
    case FileExists(aFile, AbsoluteTargetFileName, AllowAppend) of
      fsoofeSkip:
        Exit(fsoterSkip);
      fsoofeOverwrite:
        begin
          mbDeleteFile(AbsoluteTargetFileName);
          Exit(fsoterDeleted);
        end;
      fsoofeAppend:
        begin
          Exit(fsoterAddToTarget);
        end;
      else
        raise Exception.Create('Invalid file exists option');
    end;
  end;

  function IsLinkFollowed: Boolean;
  begin
    // If link was followed then it's target is stored in a subnode.
    Result := aFile.IsLink and (aNode.SubNodesCount > 0);
  end;

  function AllowAppendFile: Boolean;
  begin
    Result := (not aFile.IsDirectory) and
              ((not aFile.IsLink) or
               (IsLinkFollowed and (not aNode.SubNodes[0].TheFile.IsDirectory)));
  end;

  function AllowCopyInto: Boolean;
  begin
    Result := aFile.IsDirectory or
              (IsLinkFollowed and aNode.SubNodes[0].TheFile.IsDirectory);
  end;

begin
  Attrs := mbFileGetAttr(AbsoluteTargetFileName);
  if Attrs <> faInvalidAttributes then
  begin
    aFile := aNode.TheFile as TFileSystemFile;

    // Target exists - ask user what to do.
    if FPS_ISDIR(Attrs) then
    begin
      Result := DoDirectoryExists(AllowCopyInto)
    end
    else if FPS_ISLNK(Attrs) then
    begin
      // Check if target of the link exists.
      LinkTargetAttrs := mbFileGetAttrNoLinks(AbsoluteTargetFileName);
      if (LinkTargetAttrs <> faInvalidAttributes) then
      begin
        if FPS_ISDIR(LinkTargetAttrs) then
          Result := DoDirectoryExists(AllowCopyInto)
        else
          Result := DoFileExists(AllowAppendFile);
      end
      else
        // Target of link doesn't exist. Treat link as file and don't allow append.
        Result := DoFileExists(False);
    end
    else
      // Existing target is a file.
      Result := DoFileExists(AllowAppendFile);
  end
  else
    Result := fsoterNotExists;
end;

function TFileSystemOperationHelper.DirExists(
             aFile: TFileSystemFile;
             AbsoluteTargetFileName: String;
             AllowCopyInto: Boolean): TFileSourceOperationOptionDirectoryExists;
const
  Responses: array[0..4] of TFileSourceOperationUIResponse
    = (fsourRewrite, fsourCopyInto, fsourSkip, fsourRewriteAll, fsourSkipAll);
  ResponsesNoCopyInto: array[0..3] of TFileSourceOperationUIResponse
    = (fsourRewrite, fsourSkip, fsourRewriteAll, fsourSkipAll);
var
  PossibleResponses: array of TFileSourceOperationUIResponse;
  DefaultOkResponse: TFileSourceOperationUIResponse;
begin
  case FDirExistsOption of
    fsoodeNone:
      begin
        case AllowCopyInto of
          True :
            begin
              PossibleResponses := Responses;
              DefaultOkResponse := fsourCopyInto;
            end;
          False:
            begin
              PossibleResponses := ResponsesNoCopyInto;
              DefaultOkResponse := fsourRewrite;
            end;
        end;

        case AskQuestion(Format(rsMsgFolderExistsRwrt, [AbsoluteTargetFileName]), '',
                         PossibleResponses, DefaultOkResponse, fsourSkip) of
          fsourRewrite:
            Result := fsoodeDelete;
          fsourCopyInto:
            Result := fsoodeCopyInto;
          fsourSkip:
            Result := fsoodeSkip;
          fsourRewriteAll:
            begin
              FDirExistsOption := fsoodeDelete;
              Result := fsoodeDelete;
            end;
          fsourSkipAll:
            begin
              FDirExistsOption := fsoodeSkip;
              Result := fsoodeSkip;
            end;
        end;
      end;

    else
      Result := FDirExistsOption;
  end;
end;

function TFileSystemOperationHelper.FileExists(
             aFile: TFileSystemFile;
             AbsoluteTargetFileName: String;
             AllowAppend: Boolean): TFileSourceOperationOptionFileExists;
const
  Responses: array[0..4] of TFileSourceOperationUIResponse
    = (fsourRewrite, fsourSkip, fsourAppend, fsourRewriteAll, fsourSkipAll);
  ResponsesNoAppend: array[0..3] of TFileSourceOperationUIResponse
    = (fsourRewrite, fsourSkip, fsourRewriteAll, fsourSkipAll);
var
  PossibleResponses: array of TFileSourceOperationUIResponse;
begin
  case FFileExistsOption of
    fsoofeNone:
      begin
        case AllowAppend of
          True :  PossibleResponses := Responses;
          False:  PossibleResponses := ResponsesNoAppend;
        end;

        case AskQuestion(Format(rsMsgFileExistsRwrt, [AbsoluteTargetFileName]), '',
                         PossibleResponses, fsourRewrite, fsourSkip) of
          fsourRewrite:
            Result := fsoofeOverwrite;
          fsourSkip:
            Result := fsoofeSkip;
          fsourAppend:
            begin
              //FFileExistsOption := fsoofeAppend; - for AppendAll
              Result := fsoofeAppend;
            end;
          fsourRewriteAll:
            begin
              FFileExistsOption := fsoofeOverwrite;
              Result := fsoofeOverwrite;
            end;
          fsourSkipAll:
            begin
              FFileExistsOption := fsoofeSkip;
              Result := fsoofeSkip;
            end;
        end;
      end;

    else
      Result := FFileExistsOption;
  end;
end;

procedure TFileSystemOperationHelper.ShowError(sMessage: String);
begin
  if gSkipFileOpError then
  begin
    if log_errors in gLogOptions then
      logWrite(FOperationThread, sMessage, lmtError, True);
  end
  else
  begin
    if AskQuestion(sMessage, '', [fsourSkip, fsourCancel],
                   fsourSkip, fsourAbort) = fsourAbort then
    begin
      AbortOperation;
    end;
  end;
end;

procedure TFileSystemOperationHelper.LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
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
    logWrite(FOperationThread, sMessage, logMsgType);
  end;
end;

procedure TFileSystemOperationHelper.CountStatistics(aNode: TFileTreeNode);
  procedure CountNodeStatistics(aNode: TFileTreeNode);
  var
    aFile: TFileSystemFile;
    i: Integer;
  begin
    aFile := aNode.TheFile as TFileSystemFile;

    with FStatistics do
    begin
      if aFile.IsDirectory then
      begin
        // No statistics for directory.
        // Go through subdirectories.
        for i := 0 to aNode.SubNodesCount - 1 do
          CountNodeStatistics(aNode.SubNodes[i]);
      end
      else if aFile.IsLink then
      begin
        // Count only not-followed links.
        if aNode.SubNodesCount = 0 then
          DoneFiles := DoneFiles + 1
        else
          // Count target of link.
          CountNodeStatistics(aNode.SubNodes[0]);
      end
      else
      begin
        // Count files.
        DoneFiles := DoneFiles + 1;
        DoneBytes := DoneBytes + aFile.Size;
      end;
    end;
  end;

begin
  CountNodeStatistics(aNode);
  UpdateStatistics(FStatistics);
end;

end.

