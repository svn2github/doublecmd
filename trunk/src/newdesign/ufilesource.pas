unit uFileSource;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uDCUtils,
  uFileSourceOperation,
  uFileSourceOperationTypes,
  uFileSourceProperty,
  uFileProperty,
  uFile;

type

  TFileSource = class;

  { IFileSource }

  IFileSource = interface(IInterface)
    ['{B7F0C4C8-59F6-4A35-A54C-E8242F4AD809}']

    function IsInterface(InterfaceGuid: TGuid): Boolean;
    function IsClass(ClassType: TClass): Boolean;

    function GetCurrentAddress: String;
    function GetSupportedFileProperties: TFilePropertiesTypes;
    function GetOperationsTypes: TFileSourceOperationTypes;
    function GetFilePropertiesDescriptions: TFilePropertiesDescriptions;
    function GetProperties: TFileSourceProperties;
    function GetFiles(TargetPath: String): TFiles;

    function CreateListOperation(TargetPath: String): TFileSourceOperation;
    function CreateCopyInOperation(SourceFileSource: IFileSource;
                                   var SourceFiles: TFiles;
                                   TargetPath: String): TFileSourceOperation;
    function CreateCopyOutOperation(TargetFileSource: IFileSource;
                                    var SourceFiles: TFiles;
                                    TargetPath: String): TFileSourceOperation;
    function CreateMoveOperation(var SourceFiles: TFiles;
                                 TargetPath: String): TFileSourceOperation;
    function CreateDeleteOperation(var FilesToDelete: TFiles): TFileSourceOperation;
    function CreateWipeOperation(var FilesToWipe: TFiles): TFileSourceOperation;
    function CreateCreateDirectoryOperation(BasePath: String; DirectoryPath: String): TFileSourceOperation;
    function CreateExecuteOperation(BasePath, ExecutablePath, Verb: String): TFileSourceOperation;
    function CreateCalcChecksumOperation(var theFiles: TFiles;
                                         aTargetPath: String;
                                         aTargetMask: String): TFileSourceOperation;
    function CreateCalcStatisticsOperation(var theFiles: TFiles): TFileSourceOperation;

    function IsPathAtRoot(Path: String): Boolean;
    function GetParentDir(sPath : String): String;
    function GetRootDir(sPath : String): String; overload;
    function GetRootDir: String; overload;
    function GetPathType(sPath : String): TPathType;
    function GetFreeSpace(Path: String; out FreeSize, TotalSize : Int64) : Boolean;

    property CurrentAddress: String read GetCurrentAddress;
    property Properties: TFileSourceProperties read GetProperties;
    property SupportedFileProperties: TFilePropertiesTypes read GetSupportedFileProperties;
  end;

  { TFileSource }

  TFileSource = class(TInterfacedObject, IFileSource)

  private

  protected
    FCurrentAddress: String;

    {en
       Retrieves the full address of the file source
       (the CurrentPath is relative to this).
       This may be used for specifying address:
       - archive : path to archive
       - network : address of server
       etc.
    }
    function GetCurrentAddress: String; virtual;

    {en
       Returns all the properties supported by the file type of the given file source.
    }
    function GetSupportedFileProperties: TFilePropertiesTypes; virtual abstract;
//    class function ClassGetSupportedFileProperties: TFilePropertiesTypes;

  public
    constructor Create; virtual;
    destructor Destroy; override;

    function IsInterface(InterfaceGuid: TGuid): Boolean;
    function IsClass(aClassType: TClass): Boolean;

    // Retrieve operations permitted on the source.  = capabilities?
    function GetOperationsTypes: TFileSourceOperationTypes; virtual abstract;
//    class function ClassGetOperationsTypes: TFileSourceOperationTypes;

    // Returns a list of property types supported by this source for each file.
    function GetFilePropertiesDescriptions: TFilePropertiesDescriptions; virtual abstract;
//    class function ClassGetFilePropertiesDescriptions: TFilePropertiesDescriptions;

    // Retrieve some properties of the file source.
    function GetProperties: TFileSourceProperties; virtual abstract;
//    class function ClassGetProperties: TFileSourceProperties;

    // Retrieves a list of files.
    // This is the same as GetOperation(fsoList), executing it
    // and returning the result of Operation.ReleaseFiles.
    // Caller is responsible for freeing the result list.
    function GetFiles(TargetPath: String): TFiles; virtual;

    // These functions create an operation object specific to the file source.
    function CreateListOperation(TargetPath: String): TFileSourceOperation; virtual;
    function CreateCopyInOperation(SourceFileSource: IFileSource;
                                   var SourceFiles: TFiles;
                                   TargetPath: String): TFileSourceOperation; virtual;
    function CreateCopyOutOperation(TargetFileSource: IFileSource;
                                    var SourceFiles: TFiles;
                                    TargetPath: String): TFileSourceOperation; virtual;
    function CreateMoveOperation(var SourceFiles: TFiles;
                                 TargetPath: String): TFileSourceOperation; virtual;
    function CreateDeleteOperation(var FilesToDelete: TFiles): TFileSourceOperation; virtual;
    function CreateWipeOperation(var FilesToWipe: TFiles): TFileSourceOperation; virtual;
    function CreateCreateDirectoryOperation(BasePath: String; DirectoryPath: String): TFileSourceOperation; virtual;
    function CreateExecuteOperation(BasePath, ExecutablePath, Verb: String): TFileSourceOperation; virtual;
    function CreateCalcChecksumOperation(var theFiles: TFiles;
                                         aTargetPath: String;
                                         aTargetMask: String): TFileSourceOperation; virtual;
    function CreateCalcStatisticsOperation(var theFiles: TFiles): TFileSourceOperation; virtual;

    {en
       Returns @true if the given path is the root path of the file source,
       @false otherwise.
    }
    function IsPathAtRoot(Path: String): Boolean; virtual;

    function GetParentDir(sPath : String): String; virtual;
    function GetRootDir(sPath : String): String; virtual;
    function GetRootDir: String; virtual;
    function GetPathType(sPath : String): TPathType; virtual;

{
    class function ClassGetParentDir(sPath : String): String;
    class function ClassGetRootDir(sPath : String): String;
    class function ClassGetPathType(sPath : String): TPathType;
}

    function GetFreeSpace(Path: String; out FreeSize, TotalSize : Int64) : Boolean; virtual;

    property CurrentAddress: String read GetCurrentAddress;
    property Properties: TFileSourceProperties read GetProperties;
    property SupportedFileProperties: TFilePropertiesTypes read GetSupportedFileProperties;

  end;

  { TFileSourceConnection }

  TFileSourceConnection = class
  protected
    FCurrentPath: String;    // Always includes trailing path delimiter.

    function GetCurrentPath: String; virtual;
    procedure SetCurrentPath(NewPath: String); virtual;

  public
    property CurrentPath: String read GetCurrentPath write SetCurrentPath;
  end;

  { TFileSources }

  TFileSources = class(TInterfaceList)
  private
    function Get(I: Integer): IFileSource;

  public
    procedure Assign(otherFileSources: TFileSources);

    property Items[I: Integer]: IFileSource read Get; default;
  end;

  { TFileSourceManager }

  TFileSourceManager = class
  private
    FFileSources: TFileSources;

    // Only allow adding and removing to/from Manager by TFileSource constructor and destructor.
    procedure Add(aFileSource: IFileSource);
    procedure Remove(aFileSource: IFileSource);

  public
    constructor Create;
    destructor Destroy; override;

    function Find(FileSourceClass: TClass; Address: String): IFileSource;
  end;

  EFileSourceException = class(Exception);

var
  FileSourceManager: TFileSourceManager;

implementation

uses
  LCLProc, uFileSourceListOperation;

{ TFileSource }

constructor TFileSource.Create;
begin
  if ClassType = TFileSource then
    raise Exception.Create('Cannot construct abstract class');
  inherited Create;

  FileSourceManager.Add(Self); // Increases RefCount

  // We don't want to count the reference in Manager, because we want to detect
  // when there are no more references other than this single one in the Manager.
  // So, we remove this reference here.
  // When RefCount reaches 0 Destroy gets called and the last remaining reference
  // (in the Manager) is removed there.
  InterLockedDecrement(frefcount);

  DebugLn('Creating ', ClassName);
end;

destructor TFileSource.Destroy;
begin
  DebugLn('Destroying ', ClassName, ' when refcount=', DbgS(refcount));

  if RefCount <> 0 then
  begin
    // There could have been an exception raised in the constructor
    // in which case RefCount will be 1, so only issue warning if there was no exception.
    // This will check for any exception, but it's enough for a warning.
    if not Assigned(ExceptObject) then
      DebugLn('Error: RefCount <> 0 for ', Self.ClassName);
  end;

  if Assigned(FileSourceManager) then
  begin
    // Restore reference removed in Create and
    // remove the instance remaining in Manager.

    // Increase refcount by 2, because we don't want removing the last instance
    // from Manager to trigger another Destroy.

    // RefCount = 0
    InterLockedIncrement(frefcount);
    InterLockedIncrement(frefcount);
    // RefCount = 2
    FileSourceManager.Remove(Self);
    // RefCount = 1
    InterLockedDecrement(frefcount);
    // RefCount = 0 (back at the final value)
  end
  else
    DebugLn('Error: Cannot remove file source - manager already destroyed!');

  inherited Destroy;
end;

function TFileSource.IsInterface(InterfaceGuid: TGuid): Boolean;
var
  t: TObject;
begin
  Result := (Self.QueryInterface(InterfaceGuid, t) = S_OK);
  if Result then
    _Release;  // QueryInterface increases refcount.
end;

function TFileSource.IsClass(aClassType: TClass): Boolean;
begin
  Result := Self is aClassType;
end;

function TFileSource.GetCurrentAddress: String;
begin
  Result := FCurrentAddress;
end;

function TFileSource.IsPathAtRoot(Path: String): Boolean;
begin
  // Default root is '/'. Override in descendant classes for other.
  Result := (Path = PathDelim);
end;

function TFileSource.GetParentDir(sPath : String): String;
begin
  Result := uDCUtils.GetParentDir(sPath);
end;

function TFileSource.GetRootDir(sPath : String): String;
begin
  Result := PathDelim;
end;

function TFileSource.GetPathType(sPath : String): TPathType;
begin
  Result := ptNone;
  if sPath <> '' then
  begin
    // Default root is '/'. Override in descendant classes for other.
    if (sPath[1] = PathDelim) then
      Result := ptAbsolute
    else if ( Pos( PathDelim, sPath ) > 0 ) then
      Result := ptRelative;
  end;
end;

function TFileSource.GetRootDir: String;
begin
  Result := GetRootDir('');
end;

function TFileSource.GetFreeSpace(Path: String; out FreeSize, TotalSize : Int64) : Boolean;
begin
  Result := False; // not supported by default
end;

// Operations.

function TFileSource.GetFiles(TargetPath: String): TFiles;
var
  Operation: TFileSourceOperation;
  ListOperation: TFileSourceListOperation;
begin
  Result := nil;

  if fsoList in GetOperationsTypes then
  begin
    Operation := CreateListOperation(TargetPath);
    if Assigned(Operation) then
      try
        ListOperation := Operation as TFileSourceListOperation;
        ListOperation.Execute;
        Result := ListOperation.ReleaseFiles;

      finally
        FreeAndNil(Operation);
      end;
  end;
end;

function TFileSource.CreateListOperation(TargetPath: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateCopyInOperation(SourceFileSource: IFileSource;
                                           var SourceFiles: TFiles;
                                           TargetPath: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateCopyOutOperation(TargetFileSource: IFileSource;
                                            var SourceFiles: TFiles;
                                            TargetPath: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateMoveOperation(var SourceFiles: TFiles;
                                         TargetPath: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateDeleteOperation(var FilesToDelete: TFiles): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateWipeOperation(var FilesToWipe: TFiles): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateCreateDirectoryOperation(BasePath: String; DirectoryPath: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateExecuteOperation(BasePath, ExecutablePath, Verb: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateCalcChecksumOperation(var theFiles: TFiles;
                                                 aTargetPath: String;
                                                 aTargetMask: String): TFileSourceOperation;
begin
  Result := nil;
end;

function TFileSource.CreateCalcStatisticsOperation(var theFiles: TFiles): TFileSourceOperation;
begin
  Result := nil;
end;

{ TFileSourceConnection }

function TFileSourceConnection.GetCurrentPath: String;
begin
  Result := FCurrentPath;
end;

procedure TFileSourceConnection.SetCurrentPath(NewPath: String);
begin
  if NewPath <> '' then
    NewPath := IncludeTrailingPathDelimiter(NewPath);

  FCurrentPath := NewPath;
end;

{ TFileSources }

function TFileSources.Get(I: Integer): IFileSource;
begin
  if (I >= 0) and (I < Count) then
    Result := inherited Items[I] as IFileSource
  else
    Result := nil;
end;

procedure TFileSources.Assign(otherFileSources: TFileSources);
var
  i: Integer;
begin
  Clear;
  for i := 0 to otherFileSources.Count - 1 do
    Add(otherFileSources.Items[i]);
end;

{ TFileSourceManager }

constructor TFileSourceManager.Create;
begin
  FFileSources := TFileSources.Create;
end;

destructor TFileSourceManager.Destroy;
var
  i: Integer;
begin
  if FFileSources.Count > 0 then
  begin
    DebugLn('Warning: Destroying manager with existing file sources!');

    for i := 0 to FFileSources.Count - 1 do
    begin
      // Restore the reference taken in TFileSource.Create before removing
      // all file sources from the list.
      FFileSources[i]._AddRef;
      // Free instance.
      FFileSources.put(i, nil);
    end;
  end;

  if Assigned(FFileSources) then
    FreeAndNil(FFileSources);

  inherited;
end;

procedure TFileSourceManager.Add(aFileSource: IFileSource);
begin
  if FFileSources.IndexOf(aFileSource) < 0 then
  begin
    FFileSources.Add(aFileSource);
  end
  else
    DebugLn('Error: File source already exists in manager!');
end;

procedure TFileSourceManager.Remove(aFileSource: IFileSource);
begin
  FFileSources.Remove(aFileSource);
end;

function TFileSourceManager.Find(FileSourceClass: TClass; Address: String): IFileSource;
var
  i: Integer;
begin
  for i := 0 to FFileSources.Count - 1 do
  begin
    if (FFileSources[i].IsClass(FileSourceClass)) and
       (FFileSources[i].CurrentAddress = Address) then
    begin
      Result := FFileSources[i];
      Exit;
    end;
  end;
  Result := nil;
end;

initialization
  FileSourceManager := TFileSourceManager.Create;

finalization
  FreeAndNil(FileSourceManager);

end.

