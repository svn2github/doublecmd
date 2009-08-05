unit uFile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileProperty;

type

  TFile = class

  private
    FName: String;
    FPath: String;  // Always includes trailing path delimiter.

    // Cached values for extension and name.
    // Automatically set when name changes.
    FExtension: String;     //<en Extension.
    FNameNoExt: String;     //<en Name without extension.

    procedure SplitIntoNameAndExtension(const FileName: string;
                                        var aFileNameOnly: string;
                                        var aExtension: string);

  protected
    FProperties: TFileProperties;

    function GetProperties: TFileProperties; virtual;

    function GetFullPath: String;
    procedure SetFullPath(NewFullPath: String);
    procedure SetPath(NewPath: String);
    function GetName: String;
    procedure SetName(Name: String);
    function GetExtension: String;
    {en
       Retrieves name without extension.
    }
    function GetNameNoExt: String;

  public
    constructor Create; virtual;

    {en
       Creates an identical copy of the object (as far as object data is concerned).
    }
    function Clone: TFile; virtual;
    procedure CloneTo(AFile: TFile); virtual;

    class function GetSupportedProperties: TFilePropertiesTypes; virtual;

    {en
       Returns True if name is not '..'.
       May be extended to include other conditions.
    }
    function IsNameValid: Boolean; virtual;

    {en
       This list only contains pointers to TFileProperty objects.
       Never free element from this list!

       Choices for implementing retrieval of file properties:

       1. array [TFilePropertyType] of TFileProperty  (current implementation)

          Upside: it should be the fastest method.
          Downside: uses more memory as the array size includes properties
                    not supported by the given file type

       2. hash table indexed by TFilePropertyType key.

          It _may_ be a bit slower than the table.
          It _may_ use less memory though.

       3. a simple list

          Slowest, but the least memory usage.
    }
    //property Properties[Index: Integer];
    //property Properties[Name: String];
    //property Properties[Type: TFilePropertiesType]
    property Properties: TFileProperties read GetProperties;

    {en
       All supported properties should have an assigned Properties[propertyType].
    }
    property SupportedProperties: TFilePropertiesTypes read GetSupportedProperties;

    {en
       Sets/gets absolute path to file.
       On get returns Path + Name.
       On set sets Path and Name accordingly.
    }
    property FullPath: String read GetFullPath write SetFullPath;
    property Path: String read FPath write SetPath;
    property Name: String read GetName write SetName;
    property NameNoExt: String read GetNameNoExt;
    property Extension: String read GetExtension;

    // Convenience functions.
    // We assume here that when the file has no attributes
    // the result is false for all these functions.
    // These functions should probably be moved from here and should not be methods.
    function IsDirectory: Boolean;
    function IsSysFile: Boolean;
    function IsLink: Boolean;
    function IsLinkToDirectory: Boolean;
    function IsExecutable: Boolean;   // for ShellExecute
  end;

  // --------------------------------------------------------------------------

  TFiles = class { A list of TFile }

  private
    FList: TFPList;
    FPath: String; //<en path of all files

  protected
    function GetCount: Integer;
    procedure SetCount(Count: Integer);

    function Get(Index: Integer): TFile;
    procedure Put(Index: Integer; AFile: TFile);

  public
    constructor Create; virtual;
    destructor Destroy; override;

    {en
       Creates a new object of the same type.
    }
    function CreateObjectOfSameType: TFiles; virtual;

    {en
       Create a list with cloned files.
    }
    function Clone: TFiles; virtual;
    procedure CloneTo(Files: TFiles); virtual;

    function Add(AFile: TFile): Integer;
    procedure Clear;

    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: TFile read Get write Put; default;
    property List: TFPList read FList;
    property Path: String read FPath write FPath;

  end;

implementation

uses
  uOSUtils
{$IFDEF UNIX}
  , BaseUnix
{$ENDIF}
  ;

constructor TFile.Create;
begin
  inherited;
end;

function TFile.Clone: TFile;
begin
  Result := TFile.Create;
  CloneTo(Result);
end;

procedure TFile.CloneTo(AFile: TFile);
var
  PropertyType: TFilePropertyType;
begin
  if Assigned(AFile) then
  begin
    AFile.FName := FName;
    AFile.FPath := FPath;
    AFile.FExtension := FExtension;
    AFile.FNameNoExt := FNameNoExt;

    // Properties were already created and assigned in the constructor
    // of the appropriate class, so we already have objects to clone them to.

    for PropertyType := Low(TFilePropertyType) to High(TFilePropertyType) do
    begin
      if PropertyType in SupportedProperties then
      begin
        Self.Properties[PropertyType].CloneTo(AFile.Properties[PropertyType]);
      end;
    end;
  end;
end;

class function TFile.GetSupportedProperties: TFilePropertiesTypes;
begin
  Result := [];
end;

function TFile.GetProperties: TFileProperties;
begin
  Result := FProperties;
end;

function TFile.GetExtension: String;
begin
  Result := FExtension;
end;

function TFile.GetNameNoExt: String;
begin
  Result := FNameNoExt;
end;

function TFile.GetName: String;
begin
  Result := FName;
end;

procedure TFile.SetName(Name: String);
begin
  FName := Name;

  // Cache Extension and NameNoExt.

  if (FName = '') or
     ((fpAttributes in SupportedProperties) and IsDirectory) or
     (FName[1] = '.')
  then
  begin
    // For directories and files beginning with '.' there is no extension.
    FExtension := '';
    FNameNoExt := FName;
  end
  else
  begin
    SplitIntoNameAndExtension(FName, FNameNoExt, FExtension);
  end;
end;

function TFile.GetFullPath: String;
begin
  Result := Path + Name;
end;

procedure TFile.SetFullPath(NewFullPath: String);
var
  aExtractedName: String;
begin
  if NewFullPath <> '' then
  begin
    if NewFullPath[Length(NewFullPath)] = PathDelim then
    begin
      // Only path passed.
      SetPath(NewFullPath);
      SetName('');
    end
    else
    begin
      aExtractedName := ExtractFileName(NewFullPath);
      SetPath(Copy(NewFullPath, 1, Length(NewFullPath) - Length(aExtractedName)));
      SetName(aExtractedName);
    end;
  end;
end;

procedure TFile.SetPath(NewPath: String);
begin
  if NewPath = '' then
    FPath := ''
  else
    FPath := IncludeTrailingPathDelimiter(NewPath);
end;

function TFile.IsNameValid: Boolean;
begin
  if Name <> '..' then
    Result := True
  else
    Result := False;
end;

function TFile.IsDirectory: Boolean;
var
  FileAttributes: TFileAttributesProperty;
begin
  if fpAttributes in SupportedProperties then
  begin
    FileAttributes := Properties[fpAttributes] as TFileAttributesProperty;
    Result := FileAttributes.IsDirectory
{$IF DEFINED(MSWINDOWS)}
              //Because symbolic link works on Windows 2k/XP for directories only
              or FileAttributes.IsLink
{$ELSEIF DEFINED(UNIX)}
//              or (IsLink and IsDirByName(sLinkTo))
{$ENDIF}
              ;
  end
  else
    Result := False;
end;

function TFile.IsLink: Boolean;
var
  FileAttributes: TFileAttributesProperty;
begin
  if fpAttributes in SupportedProperties then
  begin
    FileAttributes := Properties[fpAttributes] as TFileAttributesProperty;
    Result := FileAttributes.IsLink;
  end
  else
    Result := False;
end;

function TFile.IsLinkToDirectory: Boolean;
begin
  // For now IsDirectory also returns True when the link points to directory.
  // Maybe this should be changed?
  Result := False;
end;

function TFile.IsExecutable: Boolean;
var
  FileAttributes: TFileAttributesProperty;
begin
  if fpAttributes in SupportedProperties then
  begin
    FileAttributes := Properties[fpAttributes] as TFileAttributesProperty;
{$IF DEFINED(MSWINDOWS)}
    Result := not IsDirectory;
{$ELSEIF DEFINED(UNIX)}
    Result := (not IsDirectory) and
              (FileAttributes.Value AND (S_IXUSR OR S_IXGRP OR S_IXOTH)>0);
{$ELSE}
    Result := False;
{$ENDIF}
  end
  else
    Result := False;
end;

function TFile.IsSysFile: Boolean;
var
  FileAttributes: TFileAttributesProperty;
begin
{$IFDEF MSWINDOWS}
  if fpAttributes in SupportedProperties then
  begin
    FileAttributes := Properties[fpAttributes] as TFileAttributesProperty;
    Result := FileAttributes.IsSysFile;
  end
  else
    Result := False;
{$ELSE}
  // Files beginning with '.' are treated as system/hidden files on Unix.
  Result := (Name <> '') and
            (Name <> '..') and
            (Name[1] = '.');
{$ENDIF}
end;

procedure TFile.SplitIntoNameAndExtension(const FileName: string;
                                          var aFileNameOnly: string;
                                          var aExtension: string);
var
  i : longint;
begin
  I := Length(FileName);
  while (I > 0) and (FileName[I] <> ExtensionSeparator) do
    Dec(I);
  if I > 0 then
  begin
    aFileNameOnly := Copy(FileName, 1, I - 1);
    aExtension    := Copy(FileName, I + 1, MaxInt);
  end
  else
  begin
    aFileNameOnly := FileName;
    aExtension := '';
  end;
end;

// ----------------------------------------------------------------------------

constructor TFiles.Create;
begin
  inherited;
  FList := TFPList.Create;
end;

destructor TFiles.Destroy;
begin
  Clear;
  FreeAndNil(FList);
  inherited;
end;

function TFiles.CreateObjectOfSameType: TFiles;
begin
  Result := TFiles.Create;
end;

function TFiles.Clone: TFiles;
begin
  Result := TFiles.Create;
  CloneTo(Result);
end;

procedure TFiles.CloneTo(Files: TFiles);
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do
  begin
    Files.Add(Get(i).Clone);
  end;

  Files.FPath := FPath;
end;

function TFiles.GetCount: Integer;
begin
  Result := FList.Count;
end;

procedure TFiles.SetCount(Count: Integer);
begin
  FList.Count := Count;
end;

function TFiles.Add(AFile: TFile): Integer;
begin
  Result := FList.Add(AFile);
end;

procedure TFiles.Clear;
var
  i: Integer;
  p: Pointer;
begin
  for i := 0 to FList.Count - 1 do
  begin
    p := FList.Items[i];
    if Assigned(p) then
      TFile(p).Free;
  end;

  FList.Clear;
end;

function TFiles.Get(Index: Integer): TFile;
begin
  Result := TFile(FList.Items[Index]);
end;

procedure TFiles.Put(Index: Integer; AFile: TFile);
begin
  FList.Items[Index] := AFile;
end;

end.

