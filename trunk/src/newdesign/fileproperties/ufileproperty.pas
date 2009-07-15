unit uFileProperty;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  // Forward declarations.
  IFilePropertyFormatter = interface;

  { TFileProperty }

  TFileProperty = class

  private

  public
    constructor Create; virtual;

    // Text description of the property.
    // Don't know if it will be really needed.
    class function GetDescription: String; virtual abstract;

    // Formats the property value as a string using some formatter object.
    function Format(Formatter: IFilePropertyFormatter): String; virtual abstract;
  end;


  TFilePropertyType = (
    //fpName,
    //fpPath,
    fpSize,           // = fpUncompressedSize?
    fpCompressedSize,
    fpAttributes,
    fpDateTime,         // non-specific - should be used?
                        // maybe it should be a default time
    fpModificationTime,
    fpCreationTime,
    fpLastAccessTime  // Last write?
  );

  TFilePropertiesTypes = set of TFilePropertyType;

  TFilePropertiesDescriptions = array of String;//TFileProperty;

  TFileProperties = array [TFilePropertyType] of TFileProperty//class(TList)
  {
    A list of TFileProperty. It would allow to query properties by index and name
    and by TFilePropertyType.
  }
  //end
  ;

  // -- Concrete properties ---------------------------------------------------

  TFileSizeProperty = class(TFileProperty)

  private
    FSize: Int64; // Cardinal;

  public
    constructor Create; override;
    constructor Create(Size: Int64); virtual; overload;

    class function GetDescription: String; override;

    // Retrieve possible values for the property.
    function GetMinimumValue: Int64; //Cardinal;
    function GetMaximumValue: Int64; //Cardinal;

    function Format(Formatter: IFilePropertyFormatter): String; override;

    property Value: Int64 read FSize write FSize;
  end;

  TFileDateTimeProperty = class(TFileProperty)

  private
    FDateTime: TDateTime;

  public
    constructor Create; override;
    constructor Create(DateTime: TDateTime); virtual; overload;

    class function GetDescription: String; override;

    // Retrieve possible values for the property.
    function GetMinimumValue: TDateTime;
    function GetMaximumValue: TDateTime;

    function Format(Formatter: IFilePropertyFormatter): String; override;

    property Value: TDateTime read FDateTime write FDateTime;
  end;

  TFileModificationDateTimeProperty = class(TFileDateTimeProperty)
  public
    class function GetDescription: String; override;

    function Format(Formatter: IFilePropertyFormatter): String; override;
  end;

  {en
     File system attributes.
  }
  TFileAttributesProperty = class(TFileProperty)

  private
    // I don't know if there would be a file source with attributes of some other type
    // than an integer number, but if there would we couldn't use Cardinal.
    FAttributes: Cardinal;

  public

    constructor Create; override;

    constructor Create(Attr: Cardinal); virtual; overload;

    // Is the file a directory.
    function IsDirectory: Boolean; virtual;

    // Is this a system file.
    function IsSysFile: boolean; virtual abstract;

    // Is it a symbolic link.
    function IsLink: Boolean; virtual;

    // Retrieves raw attributes.
    function GetAttributes: Cardinal; virtual;

    // Sets raw attributes.
    procedure SetAttributes(Attributes: Cardinal); virtual;

    property Value: Cardinal read GetAttributes write SetAttributes;

  end;

  TNtfsFileAttributesProperty = class(TFileAttributesProperty)
  public

    // Is this a system file.
    function IsSysFile: boolean; override;

    function IsReadOnly: Boolean;
    function IsHidden: Boolean;

    class function GetDescription: String; override;

    function Format(Formatter: IFilePropertyFormatter): String; override;
  end;

  TUnixFileAttributesProperty = class(TFileAttributesProperty)
  public

    // Is this a system file.
    function IsSysFile: boolean; override;

    function IsOwnerRead: Boolean;
    function IsOwnerWrite: Boolean;
    function IsOwnerExecute: Boolean;
    // ...

    class function GetDescription: String; override;

    function Format(Formatter: IFilePropertyFormatter): String; override;
  end;

  // -- Property formatter interface ------------------------------------------

  IFilePropertyFormatter = interface(IInterface)
    ['{18EF8E34-1010-45CD-8DC9-678C7C2DC89F}']

    function FormatFileSize(FileProperty: TFileSizeProperty): String;
    function FormatDateTime(FileProperty: TFileDateTimeProperty): String;
    function FormatModificationDateTime(FileProperty: TFileModificationDateTimeProperty): String;
    function FormatAttributes(FileProperty: TFileAttributesProperty): String;

  end;

implementation

uses
  uOSUtils;

resourcestring
  rsSizeDescription = 'Size';
  rsDateTimeDescription = 'DateTime';
  rsModificationDateTimeDescription = 'Modification date/time';

// ----------------------------------------------------------------------------

constructor TFileProperty.Create;
begin
  inherited;
end;

// ----------------------------------------------------------------------------

constructor TFileSizeProperty.Create;
begin
  Self.Create(0);
end;

constructor TFileSizeProperty.Create(Size: Int64);
begin
  inherited Create;
  Value := Size;
end;

class function TFileSizeProperty.GetDescription: String;
begin
  Result := rsSizeDescription;
end;

function TFileSizeProperty.GetMinimumValue: Int64;
begin
  Result := 0;
end;

function TFileSizeProperty.GetMaximumValue: Int64;
begin
  Result := 0; // maximum file size
end;

function TFileSizeProperty.Format(Formatter: IFilePropertyFormatter): String;
begin
  Result := Formatter.FormatFileSize(Self);
end;

// ----------------------------------------------------------------------------

constructor TFileDateTimeProperty.Create;
begin
  Self.Create(0);
end;

constructor TFileDateTimeProperty.Create(DateTime: TDateTime);
begin
  inherited Create;
  Value := DateTime;
end;

class function TFileDateTimeProperty.GetDescription: String;
begin
  Result := rsDateTimeDescription;
end;

function TFileDateTimeProperty.GetMinimumValue: TDateTime;
begin
  Result := 0;
end;

function TFileDateTimeProperty.GetMaximumValue: TDateTime;
begin
  Result := 0; // maximum file size
end;

function TFileDateTimeProperty.Format(Formatter: IFilePropertyFormatter): String;
begin
  Result := Formatter.FormatDateTime(Self);
end;

// ----------------------------------------------------------------------------

class function TFileModificationDateTimeProperty.GetDescription: String;
begin
  Result := rsModificationDateTimeDescription;
end;

function TFileModificationDateTimeProperty.Format(Formatter: IFilePropertyFormatter): String;
begin
  Result := Formatter.FormatModificationDateTime(Self);
end;

// ----------------------------------------------------------------------------

constructor TFileAttributesProperty.Create;
begin
  Create(0);
end;

constructor TFileAttributesProperty.Create(Attr: Cardinal);
begin
  inherited Create;
  FAttributes := Attr;
end;

function TFileAttributesProperty.GetAttributes: Cardinal;
begin
  Result := FAttributes;
end;

procedure TFileAttributesProperty.SetAttributes(Attributes: Cardinal);
begin
  FAttributes := Attributes;
end;

function TFileAttributesProperty.IsDirectory: Boolean;
begin
  Result := fpS_ISDIR(FAttributes);
end;

function TFileAttributesProperty.IsLink: Boolean;
begin
  Result := fpS_ISLNK(FAttributes);
end;

// ----------------------------------------------------------------------------

function TNtfsFileAttributesProperty.IsSysFile: boolean;
begin
  Result := ((FAttributes and faSysFile) <> 0) or
            ((FAttributes and faHidden) <> 0);
end;

function TNtfsFileAttributesProperty.IsReadOnly: Boolean;
begin
  Result := (FAttributes and faReadOnly) <> 0;
end;

function TNtfsFileAttributesProperty.IsHidden: Boolean;
begin
  Result := (FAttributes and faHidden) <> 0;
end;

class function TNtfsFileAttributesProperty.GetDescription: String;
begin
end;

function TNtfsFileAttributesProperty.Format(Formatter: IFilePropertyFormatter): String;
begin
  Result := Formatter.FormatAttributes(Self)
end;

// ----------------------------------------------------------------------------

function TUnixFileAttributesProperty.IsSysFile: Boolean;
begin
  Result := False;
end;

function TUnixFileAttributesProperty.IsOwnerRead: Boolean;
begin
end;

function TUnixFileAttributesProperty.IsOwnerWrite: Boolean;
begin
end;

function TUnixFileAttributesProperty.IsOwnerExecute: Boolean;
begin
end;

class function TUnixFileAttributesProperty.GetDescription: String;
begin
end;

function TUnixFileAttributesProperty.Format(Formatter: IFilePropertyFormatter): String;
begin
  Result := Formatter.FormatAttributes(Self);
end;

end.

