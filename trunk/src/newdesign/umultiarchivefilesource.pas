unit uMultiArchiveFileSource;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs, syncobjs, StringHashList, uOSUtils,
  uMultiArc, uFile, uFileSourceProperty, uFileSourceOperationTypes,
  uArchiveFileSource, uFileProperty, uFileSource, uFileSourceOperation,
  uMultiArchiveUtil;

type

  { IMultiArchiveFileSource }

  IMultiArchiveFileSource = interface(IArchiveFileSource)
    ['{71BF41D3-1E40-4E84-83BB-B6D3E0DEB6FC}']

    function GetArcFileList: TObjectList;
    function GetArchiveFlags: PtrInt;
    procedure SetArchiveFlags(NewArchiveFlags: PtrInt);
    function GetMultiArcItem: TMultiArcItem;

    property ArchiveFileList: TObjectList read GetArcFileList;
    property ArchiveFlags: PtrInt read GetArchiveFlags write SetArchiveFlags;
    property MultiArcItem: TMultiArcItem read GetMultiArcItem;
  end;

  { TMultiArchiveFileSource }

  TMultiArchiveFileSource = class(TArchiveFileSource, IMultiArchiveFileSource)
  private
    FOutputParser: TOutputParser;
    FArchiveFlags: PtrInt;
    FArcFileList : TObjectList;
    FMultiArcItem: TMultiArcItem;
    FAllDirsList,
    FExistsDirList : TStringHashList;

    function GetArchiveFlags: PtrInt;
    function GetMultiArcItem: TMultiArcItem;
    procedure OnGetArchiveItem(ArchiveItem: TArchiveItem);

    function ReadArchive(bCanYouHandleThisFile : Boolean = False): Boolean;

    function GetArcFileList: TObjectList;
    procedure SetArchiveFlags(NewArchiveFlags: PtrInt);

  protected

    function GetSupportedFileProperties: TFilePropertiesTypes; override;
    function SetCurrentWorkingDirectory(NewDir: String): Boolean; override;

    procedure DoReload(const PathsToReload: TPathsArray); override;

  public
    constructor Create(anArchiveFileName: String; aMultiArcItem: TMultiArcItem); reintroduce;
    destructor Destroy; override;

    // Retrieve operations permitted on the source.  = capabilities?
    function GetOperationsTypes: TFileSourceOperationTypes; override;

    // Returns a list of property types supported by this source for each file.
    function GetFilePropertiesDescriptions: TFilePropertiesDescriptions; override;

    // Retrieve some properties of the file source.
    function GetProperties: TFileSourceProperties; override;

    // These functions create an operation object specific to the file source.
    function CreateListOperation(TargetPath: String): TFileSourceOperation; override;
    {
    function CreateCopyInOperation(SourceFileSource: IFileSource;
                                   var SourceFiles: TFiles;
                                   TargetPath: String): TFileSourceOperation; override;
    function CreateCopyOutOperation(TargetFileSource: IFileSource;
                                    var SourceFiles: TFiles;
                                    TargetPath: String): TFileSourceOperation; override;
    function CreateDeleteOperation(var FilesToDelete: TFiles): TFileSourceOperation; override;
    function CreateExecuteOperation(const ExecutableFile: TFile;
                                    BasePath, Verb: String): TFileSourceOperation; override;
    function CreateTestArchiveOperation(var theSourceFiles: TFiles): TFileSourceOperation; override;
    }

    class function CreateByArchiveName(anArchiveFileName: String): IMultiArchiveFileSource;

    property ArchiveFileList: TObjectList read GetArcFileList;
    property ArchiveFlags: PtrInt read GetArchiveFlags write SetArchiveFlags;
    property MultiArcItem: TMultiArcItem read GetMultiArcItem;
  end;

implementation

uses
  uGlobs, LCLProc, uDCUtils,
  uDateTimeUtils,
  FileUtil, uMultiArchiveFile,
  uMultiArchiveListOperation
  {
  uMultiArchiveCopyInOperation,
  uMultiArchiveCopyOutOperation,
  uMultiArchiveDeleteOperation,
  uMultiArchiveExecuteOperation,
  uMultiArchiveTestArchiveOperation
  }
  ;

class function TMultiArchiveFileSource.CreateByArchiveName(anArchiveFileName: String): IMultiArchiveFileSource;
var
  I: Integer;
  sExtension: String;
  aMultiArcItem: TMultiArcItem;
begin
  Result := nil;

  sExtension := ExtractFileExt(anArchiveFileName);
  if sExtension <> '' then   // delete '.' at the front
    Delete(sExtension, 1, 1);

  // Check if there is a registered addon for the extension of the archive file name.
  for I := 0 to gMultiArcList.Count - 1 do
  begin
    aMultiArcItem:= gMultiArcList.Items[I];

    if SameText(sExtension, aMultiArcItem.FExtension) {and (aMultiArcItem.FEnabled)} then
    begin
      Result := TMultiArchiveFileSource.Create(anArchiveFileName,
                                               aMultiArcItem);

      DebugLn('Found registered addon "' + aMultiArcItem.FDescription + '" for archive ' + anArchiveFileName);
      Break;
    end;
  end;
end;

// ----------------------------------------------------------------------------

constructor TMultiArchiveFileSource.Create(anArchiveFileName: String; aMultiArcItem: TMultiArcItem);
begin
  inherited Create(anArchiveFileName);

  FMultiArcItem := aMultiArcItem;
  FArcFileList := TObjectList.Create(True);
  FOutputParser := TOutputParser.Create(aMultiArcItem, anArchiveFileName);
  FOutputParser.OnGetArchiveItem:= @OnGetArchiveItem;

  ReadArchive;
end;

destructor TMultiArchiveFileSource.Destroy;
begin
  inherited Destroy;

  if Assigned(FArcFileList) then
    FreeAndNil(FArcFileList);
end;

function TMultiArchiveFileSource.GetOperationsTypes: TFileSourceOperationTypes;
begin
  Result := [fsoList];
end;

function TMultiArchiveFileSource.GetFilePropertiesDescriptions: TFilePropertiesDescriptions;
begin
  Result := nil;
end;

function TMultiArchiveFileSource.GetProperties: TFileSourceProperties;
begin
  Result := [];
end;

function TMultiArchiveFileSource.GetSupportedFileProperties: TFilePropertiesTypes;
begin
  Result := TMultiArchiveFile.GetSupportedProperties;
end;

function TMultiArchiveFileSource.SetCurrentWorkingDirectory(NewDir: String): Boolean;
var
  I: Integer;
  ArchiveItem: TArchiveItem;
begin
  Result := False;
  if Length(NewDir) > 0 then
  begin
    if NewDir = GetRootDir() then
      Exit(True);

    NewDir := IncludeTrailingPathDelimiter(NewDir);

    // Search file list for a directory with name NewDir.
    for I := 0 to FArcFileList.Count - 1 do
    begin
      ArchiveItem := TArchiveItem(FArcFileList.Items[I]);
      if FPS_ISDIR(ArchiveItem.Attributes) and (Length(ArchiveItem.FileName) > 0) then
      begin
        if NewDir = IncludeTrailingPathDelimiter(GetRootDir() + ArchiveItem.FileName) then
          Exit(True);
      end;
    end;
  end;
end;

function TMultiArchiveFileSource.GetArcFileList: TObjectList;
begin
  Result := FArcFileList;
end;

function TMultiArchiveFileSource.GetArchiveFlags: PtrInt;
begin
  Result := FArchiveFlags;
end;

procedure TMultiArchiveFileSource.SetArchiveFlags(NewArchiveFlags: PtrInt);
begin
  FArchiveFlags := NewArchiveFlags;
end;

function TMultiArchiveFileSource.GetMultiArcItem: TMultiArcItem;
begin
  Result := FMultiArcItem;
end;

function TMultiArchiveFileSource.CreateListOperation(TargetPath: String): TFileSourceOperation;
var
  TargetFileSource: IFileSource;
begin
  TargetFileSource := Self;
  Result := TMultiArchiveListOperation.Create(TargetFileSource, TargetPath);
end;

{
function TMultiArchiveFileSource.CreateCopyInOperation(
            SourceFileSource: IFileSource;
            var SourceFiles: TFiles;
            TargetPath: String): TFileSourceOperation;
var
  TargetFileSource: IFileSource;
begin
  TargetFileSource := Self;
  Result := TWcxArchiveCopyInOperation.Create(SourceFileSource,
                                              TargetFileSource,
                                              SourceFiles, TargetPath);
end;

function TMultiArchiveFileSource.CreateCopyOutOperation(
            TargetFileSource: IFileSource;
            var SourceFiles: TFiles;
            TargetPath: String): TFileSourceOperation;
var
  SourceFileSource: IFileSource;
begin
  SourceFileSource := Self;
  Result := TWcxArchiveCopyOutOperation.Create(SourceFileSource,
                                               TargetFileSource,
                                               SourceFiles, TargetPath);
end;

function TMultiArchiveFileSource.CreateDeleteOperation(var FilesToDelete: TFiles): TFileSourceOperation;
var
  TargetFileSource: IFileSource;
begin
  TargetFileSource := Self;
  Result := TWcxArchiveDeleteOperation.Create(TargetFileSource,
                                              FilesToDelete);
end;

function TMultiArchiveFileSource.CreateExecuteOperation(const ExecutableFile: TFile;
                                                      BasePath, Verb: String): TFileSourceOperation;
var
  TargetFileSource: IFileSource;
begin
  TargetFileSource := Self;
  Result:=  TWcxArchiveExecuteOperation.Create(TargetFileSource, ExecutableFile, BasePath, Verb);
end;

function TMultiArchiveFileSource.CreateTestArchiveOperation(var theSourceFiles: TFiles): TFileSourceOperation;
var
  SourceFileSource: IFileSource;
begin
  SourceFileSource := Self;
  Result:=  TWcxArchiveTestArchiveOperation.Create(SourceFileSource, theSourceFiles);
end;
}

procedure TMultiArchiveFileSource.OnGetArchiveItem(ArchiveItem: TArchiveItem);

  procedure CollectDirs(Path: PAnsiChar; var DirsList: TStringHashList);
  var
    I : Integer;
    Dir : AnsiString;
  begin
    // Scan from the second char from the end, to the second char from the beginning.
    for I := strlen(Path) - 2 downto 1 do
    begin
      if Path[I] = PathDelim then
      begin
        SetString(Dir, Path, I);
        if DirsList.Find(Dir) = -1 then
          // Add directory and continue scanning for parent directories.
          DirsList.Add(Dir)
        else
          // This directory is already in the list and we assume
          // that all parent directories are too.
          Exit;
      end
    end;
  end;

var
  I : Integer;
  NameLength: Integer;
begin
  // Some archivers end directories with path delimiter. Delete it if present.
  if FPS_ISDIR(ArchiveItem.Attributes) then
    begin
      NameLength := Length(ArchiveItem.FileName);
      if (ArchiveItem.FileName[NameLength] = PathDelim) then
        Delete(ArchiveItem.FileName, NameLength, 1);

      //****************************
      (* Workaround for archivers that don't give a list of folders
         or the list does not include all of the folders. *)

      // Collect directories that the plugin supplies.
      if (FExistsDirList.Find(ArchiveItem.FileName) < 0) then
        FExistsDirList.Add(ArchiveItem.FileName);
    end;

  // Collect all directories.
  CollectDirs(PAnsiChar(ArchiveItem.FileName), FAllDirsList);

  //****************************

  FArcFileList.Add(ArchiveItem);
end;

function TMultiArchiveFileSource.ReadArchive(bCanYouHandleThisFile : Boolean = False): Boolean;
var
  I : Integer;
  ArchiveItem: TArchiveItem;
begin
  if not mbFileAccess(ArchiveFileName, fmOpenRead) then
    begin
      Result := False;
      Exit;
    end;

  {
  if bCanYouHandleThisFile and (Assigned(WcxModule.CanYouHandleThisFile) or Assigned(WcxModule.CanYouHandleThisFileW)) then
    begin
      Result := WcxModule.WcxCanYouHandleThisFile(ArchiveFileName);
      if not Result then Exit;
    end;
  }

  { Get File List }
  FArcFileList.Clear;
  FExistsDirList := TStringHashList.Create(True);
  FAllDirsList := TStringHashList.Create(True);

  try
    DebugLn('Get File List');

    FOutputParser.Execute;

    (* if archiver does not give a list of folders *)
    for I := 0 to FAllDirsList.Count - 1 do
    begin
      // Add only those directories that were not supplied by the plugin.
      if FExistsDirList.Find(FAllDirsList.List[I]^.Key) < 0 then
      begin
        ArchiveItem:= TArchiveItem.Create;
        try
          ArchiveItem.FileName := FAllDirsList.List[I]^.Key;
          ArchiveItem.Attributes := faFolder;
          FArcFileList.Add(ArchiveItem);
        except
          FreeAndNil(ArchiveItem);
        end;
      end;
    end;

  finally
    FreeAndNil(FAllDirsList);
    FreeAndNil(FExistsDirList);
  end;

  Result := True;
end;

procedure TMultiArchiveFileSource.DoReload(const PathsToReload: TPathsArray);
begin
  ReadArchive;
end;

end.

