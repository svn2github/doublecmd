unit uFileView; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls,
  uFile, uFileSource, uMethodsList, uDragDropEx;

type

  TOnBeforeChangeDirectory = function (FileView: TCustomPage; const NewDir : String): Boolean of object;
  TOnAfterChangeDirectory = procedure (FileView: TCustomPage; const NewDir : String) of object;
  TOnChangeFileSource = procedure (FileView: TCustomPage) of object;

  TDropParams = class;
  TDragDropType = (ddtInternal, ddtExternal);
  // Lists all operations supported by dragging and dropping items
  // in the panel (external, internal and via menu).
  TDragDropOperation = (ddoCopy, ddoMove, ddoSymLink, ddoHardLink);

  {en
     Base class for any view of a file or files.
     There should always be at least one file displayed on the view.
  }
  TFileView = class(TWinControl)
  private
    {en
       The file sources hierarchy associated with this view.
       Last element is the file source that is currently being viewed,
       parent file source is (index-1) and so on up to zero (first file source).

       For now they all live as long as TFileView lives,
       don't know if this should be changed or not.
    }
    FFileSources: TFileSources;
    FCurrentPaths: TStringList;   // always include trailing path delimiter

    FMethods: TMethodsList;

    FOnBeforeChangeDirectory : TOnBeforeChangeDirectory;
    FOnAfterChangeDirectory : TOnAfterChangeDirectory;
    FOnChangeFileSource : TOnChangeFileSource;

    function GetCurrentAddress: String;

    function GetNotebookPage: TCustomPage;

    function GetLastFileSource: IFileSource;
    function GetFileSource(Index: Integer): IFileSource;
    function GetFileSourcesCount: Integer;

  protected
    function GetCurrentPath: String; virtual;
    procedure SetCurrentPath(NewPath: String); virtual;
    function GetActiveFile: TFile; virtual;
    {en
       This function should set active file by reference of TFile
       or at least by all the properties of the given TFile,
       in case the object is a clone.
       It could be useful in case there are multiple files with the
       same name in the panel and SetActiveFile(String) is not enough.
    }
    procedure SetActiveFile(const aFile: TFile); virtual; overload;
    function GetDisplayedFiles: TFiles; virtual abstract;
    function GetSelectedFiles: TFiles; virtual abstract;

  public
    constructor Create(AOwner: TWinControl;
                       FileSource: IFileSource;
                       Path: String); virtual reintroduce;

    destructor Destroy; override;

    function Clone(NewParent: TWinControl): TFileView; virtual;
    procedure CloneTo(FileView: TFileView); virtual;

    procedure AddFileSource(aFileSource: IFileSource; aPath: String); virtual;
    procedure RemoveLastFileSource; virtual;
    {en
       Assigns the list of file sources and paths into those file sources
       from another file view.
    }
    procedure AssignFileSources(const otherFileView: TFileView); virtual;

    // Retrieves files from file source again and displays the new list of files.
    procedure Reload; virtual abstract;

    // For now we use here the knowledge that there are tabs.
    // Config should be independent of that in the future.
    procedure LoadConfiguration(Section: String; TabIndex: Integer); virtual abstract;
    procedure SaveConfiguration(Section: String; TabIndex: Integer); virtual abstract;

    procedure UpdateView; virtual abstract;

    procedure SetActiveFile(const aFileName: String); virtual; overload;

    {en
       Changes the current path to a parent directory.
       @param(AllowChangingFileSource
              If this parameter is @true and current path is the root path
              of the current file source, then the current file source will
              be removed (closed) and a previous file source will be displayed.)
    }
    procedure ChangePathToParent(AllowChangingFileSource: Boolean); virtual;
    {en
       Change the current path to a subdirectory pointed to by aFile.
    }
    procedure ChangePathToChild(const aFile: TFile); virtual;

    procedure ExecuteCommand(CommandName: String; Parameter: String = ''); virtual;

    {en
       Returns @true if at least one file is somehow selected.
       What "selected" means depends on the concrete file view implementation.
       (Usually it will be a different method of selecting than ActiveFile.)
    }
    function HasSelectedFiles: Boolean; virtual abstract;

    {en
       Handles drag&drop operations onto the file view.
       Does any graphic work and executes operations with dropped files if allowed.
       Handles freeing DropParams.
    }
    procedure DoDragDropOperation(Operation: TDragDropOperation;
                                  var DropParams: TDropParams); virtual abstract;

    property CurrentPath: String read GetCurrentPath write SetCurrentPath;
    property CurrentAddress: String read GetCurrentAddress;
    property FileSource: IFileSource read GetLastFileSource;
    property FileSources[Index: Integer]: IFileSource read GetFileSource;
//    property FileSourcesList: TFileSources read FFileSources;
    property FileSourcesCount: Integer read GetFileSourcesCount;

    {en
       Currently active file.
       There should always be at least one file in the view at any time, but
       what 'active' means depends on the specific view, so ActiveFile may
       return 'nil' if there is no file active. Usually it is the file pointed
       to by a cursor or some other indicator.
    }
    property ActiveFile: TFile read GetActiveFile write SetActiveFile;
    {en
       A list of currently displayed files.
       Caller is responsible for freeing the list.
    }
    property Files: TFiles read GetDisplayedFiles;
    {en
       A list of files selected by the user
       (this should be a subset of displayed files list returned by Files).
       Caller is responsible for freeing the list.
    }
    property SelectedFiles: TFiles read GetSelectedFiles;

    property NotebookPage: TCustomPage read GetNotebookPage;
    property OnBeforeChangeDirectory : TOnBeforeChangeDirectory read FOnBeforeChangeDirectory write FOnBeforeChangeDirectory;
    property OnAfterChangeDirectory : TOnAfterChangeDirectory read FOnAfterChangeDirectory write FOnAfterChangeDirectory;
    property OnChangeFileSource : TOnChangeFileSource read FOnChangeFileSource write FOnChangeFileSource;
  end;

  { TDropParams }

  {  Parameters passed to functions handling drag&drop.

     FileList
        List of files dropped (the class handles freeing it).
     DropEffect
        Desired action to take with regard to the files.
     ScreenDropPoint
        Point where the drop occurred.
     DropIntoDirectories
        If true it is/was allowed to drop into specific directories
        (directories may have been tracked while dragging).
        Target path will be modified accordingly if ScreenDropPoint points
        to a directory in the target panel.
     SourcePanel
        If drag drop type is internal, this field points to the source panel.
     TargetPanel
        Panel, where the drop occurred. }
  TDropParams = class
  public
    Files: TFiles;
    DropEffect: TDropEffect;
    ScreenDropPoint: TPoint;
    DropIntoDirectories: Boolean;
    SourcePanel: TFileView;
    TargetPanel: TFileView;
    TargetPath: String;

    constructor Create(var aFiles: TFiles;
                       aDropEffect: TDropEffect;
                       aScreenDropPoint: TPoint;
                       aDropIntoDirectories: Boolean;
                       aSourcePanel: TFileView;
                       aTargetPanel: TFileView;
                       aTargetPath: String);
    destructor Destroy; override;

    // States, whether the drag&drop operation was internal or external.
    // If SourcePanel is not nil, then it's assumed it was internal.
    function GetDragDropType: TDragDropType;
  end;
  PDropParams = ^TDropParams;

implementation

uses
  uActs, LCLProc;

constructor TFileView.Create(AOwner: TWinControl; FileSource: IFileSource; Path: String);
begin
  FOnBeforeChangeDirectory := nil;
  FOnAfterChangeDirectory := nil;
  FOnChangeFileSource := nil;

  FFileSources := TFileSources.Create;
  FFileSources.Add(FileSource);
  FCurrentPaths := TStringList.Create;
  FCurrentPaths.Add(Path);

  FMethods := TMethodsList.Create(Self);

  inherited Create(AOwner);
end;

destructor TFileView.Destroy;
begin
  inherited;
  FreeAndNil(FMethods);
  FreeAndNil(FFileSources);
  FreeAndNil(FCurrentPaths);
end;

function TFileView.Clone(NewParent: TWinControl): TFileView;
begin
  raise Exception.Create('Cannot create object of abstract class');
end;

procedure TFileView.CloneTo(FileView: TFileView);
begin
  if Assigned(FileView) then
  begin
    // FFileSource should have been passed to FileView constructor already.
    // FMethods are created in FileView constructor.
    FileView.OnBeforeChangeDirectory := Self.OnBeforeChangeDirectory;
    FileView.OnAfterChangeDirectory := Self.OnAfterChangeDirectory;
    FileView.OnChangeFileSource := Self.OnChangeFileSource;

    FileView.FFileSources.Assign(Self.FFileSources);
    FileView.FCurrentPaths.Assign(Self.FCurrentPaths);
  end;
end;

function TFileView.GetNotebookPage: TCustomPage;
begin
  Result := Parent as TCustomPage;
end;

function TFileView.GetCurrentAddress: String;
begin
  Result := FileSource.CurrentAddress;
end;

function TFileView.GetCurrentPath: String;
begin
  Result := FCurrentPaths.Strings[FCurrentPaths.Count - 1];
end;

procedure TFileView.SetCurrentPath(NewPath: String);
begin
  if NewPath <> '' then
    NewPath := IncludeTrailingPathDelimiter(NewPath);

  FCurrentPaths.Strings[FCurrentPaths.Count - 1] := NewPath;
end;

function TFileView.GetActiveFile: TFile;
begin
  Result := nil;
end;

procedure TFileView.SetActiveFile(const aFile: TFile);
begin
end;

procedure TFileView.SetActiveFile(const aFileName: String);
begin
end;

procedure TFileView.ChangePathToParent(AllowChangingFileSource: Boolean);
var
  PreviousSubDirectory,
  sUpLevel: String;
begin
  // Check if this is root level of the current file source.
  if FileSource.IsPathAtRoot(CurrentPath) then
  begin
    // If there is a higher level file source then change to it.
    if (FileSourcesCount > 1) and AllowChangingFileSource then
    begin
      RemoveLastFileSource;
      Reload;
      UpdateView;
    end;
  end
  else
  begin
    PreviousSubDirectory := ExtractFileName(ExcludeTrailingPathDelimiter(CurrentPath));

    sUpLevel:= FileSource.GetParentDir(CurrentPath);
    if sUpLevel <> EmptyStr then
    begin
      CurrentPath := sUpLevel;
      SetActiveFile(PreviousSubDirectory);
    end;
  end;
end;

procedure TFileView.ChangePathToChild(const aFile: TFile);
begin
  if Assigned(aFile) and aFile.IsNameValid and
     (aFile.IsDirectory or aFile.IsLinkToDirectory) then
  begin
    CurrentPath := CurrentPath + IncludeTrailingPathDelimiter(aFile.Name);
  end;
end;

procedure TFileView.ExecuteCommand(CommandName: String; Parameter: String);
var
  Method: TMethod;
begin
  Method := FMethods.GetMethod(CommandName);
  if Assigned(Method.Code) then
  begin
    // Command is supported - execute it.
    TCommandFunc(Method)(Parameter);
  end;
end;

procedure TFileView.AddFileSource(aFileSource: IFileSource;
                                  aPath: String);
begin
  FFileSources.Add(aFileSource);
  FCurrentPaths.Add(aPath);
  Reload;
  UpdateView;
end;

procedure TFileView.RemoveLastFileSource;
begin
  FFileSources.Delete(FFileSources.Count - 1);
  FCurrentPaths.Delete(FCurrentPaths.Count - 1);
  Reload;
  UpdateView;
end;

procedure TFileView.AssignFileSources(const otherFileView: TFileView);
begin
  FFileSources.Assign(otherFileView.FFileSources);
  FCurrentPaths.Assign(otherFileView.FCurrentPaths);

  Reload;
  UpdateView;
end;

function TFileView.GetLastFileSource: IFileSource;
begin
  if FFileSources.Count > 0 then
    Result := FFileSources.Last as IFileSource
  else
    Result := nil;
end;

function TFileView.GetFileSource(Index: Integer): IFileSource;
begin
  Result := FFileSources.Items[Index] as IFileSource;
end;

function TFileView.GetFileSourcesCount: Integer;
begin
  Result := FFileSources.Count;
end;

{ TDropParams }

constructor TDropParams.Create(
                  var aFiles: TFiles;
                  aDropEffect: TDropEffect;
                  aScreenDropPoint: TPoint;
                  aDropIntoDirectories: Boolean;
                  aSourcePanel: TFileView;
                  aTargetPanel: TFileView;
                  aTargetPath: String);
begin
  Files := aFiles;
  aFiles := nil;
  DropEffect := aDropEffect;
  ScreenDropPoint := aScreenDropPoint;
  DropIntoDirectories := aDropIntoDirectories;
  SourcePanel := aSourcePanel;
  TargetPanel := aTargetPanel;
  TargetPath := aTargetPath;
end;

destructor TDropParams.Destroy;
begin
  if Assigned(Files) then
    FreeAndNil(Files);
end;

function TDropParams.GetDragDropType: TDragDropType;
begin
  if Assigned(SourcePanel) then
    Result := ddtInternal
  else
    Result := ddtExternal;
end;

end.

