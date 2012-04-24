unit uColumnsFileViewVtv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, StdCtrls, ExtCtrls, Grids,
  LMessages, LCLIntf, LCLType, Menus, uTypes,
  uDragDropEx,
  uFile,
  uFileProperty,
  uFileView,
  uOrderedFileView,
  uFileSource,
  uDisplayFile,
  uColumns,
  uFileSorting,
  DCXmlConfig,
  DCClassesUtf8,
  uFileViewWorker,
  VirtualTrees;

type

  { Columns sorting }

  PColumnsSorting = ^TColumnsSorting;
  TColumnsSorting = record
    Column : Integer;
    SortDirection : uFileSorting.TSortDirection;
  end;

  PFileListSorting = ^TColumnsSortings;
  TColumnsSortings = class(TList)
  public
    Destructor Destroy; override;
    function Clone: TColumnsSortings;
    procedure AddSorting(iColumn : Integer; SortDirection : uFileSorting.TSortDirection);
    procedure Clear; override;
    function GetSortingDirection(iColumn : Integer) : uFileSorting.TSortDirection;
  end;

  TColumnsFileViewVTV = class;

  TNodeRange = record
    First: PVirtualNode;
    Last: PVirtualNode;
  end;

  TColumnsDrawTreeRecord = record end; // We don't need anything in it, just Node^.Index.
  PColumnsDrawTreeRecord = ^TColumnsDrawTreeRecord;

  { TColumnsDrawTree }

  TColumnsDrawTree = class(TVirtualDrawTree)
  private
    // Used to register as a drag and drop source and target.
    DragDropSource: uDragDropEx.TDragDropSource;
    DragDropTarget: uDragDropEx.TDragDropTarget;

    StartDrag: Boolean;
    DragStartPoint: TPoint;
    DragNode,
    DropNode,
    HintNode: PVirtualNode;
    LastMouseButton: TMouseButton; // Mouse button that initiated dragging
    SelectionStartIndex: Cardinal;
    FMouseDown: Boolean; // Used to check if button-up was received after button-down
                         // or after dropping something after dragging with right mouse button

    ColumnsView: TColumnsFileViewVTV;

    // Updates the drop row index, which is used to draw a rectangle
    // on directories during drag&drop operations.
    procedure ChangeDropNode(NewNode: PVirtualNode);

    // Simulates releasing mouse button that started a dragging operation,
    // but was released in another window or another application.
    procedure ClearMouseButtonAfterDrag;

    function GetGridHorzLine: Boolean;
    function GetGridVertLine: Boolean;
    procedure SetGridHorzLine(const AValue: Boolean);
    procedure SetGridVertLine(const AValue: Boolean);

    // If internal dragging is currently in effect, this function
    // stops internal dragging and starts external.
    procedure TransformDraggingToExternal(ScreenPoint: TPoint);

    { Events for drag&drop from external applications }
    function OnExDragBegin: Boolean;
    function OnExDragEnd  : Boolean;
    function OnExDragEnter(var DropEffect: TDropEffect; ScreenPoint: TPoint):Boolean;
    function OnExDragOver(var DropEffect: TDropEffect; ScreenPoint: TPoint):Boolean;
    function OnExDrop(const FileNamesList: TStringList; DropEffect: TDropEffect; ScreenPoint: TPoint):Boolean;
    function OnExDragLeave:Boolean;

    function GetNodeFile(Node: PVirtualNode): TDisplayFile;
    procedure SetAllRowsHeights(ARowHeight: Cardinal);

  protected

    procedure MouseMove(Shift: TShiftState; X,Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;

    procedure InitializeWnd; override;
    procedure FinalizeWnd; override;

    procedure DoPaintNode(var PaintInfo: TVTPaintInfo); override;

  public
{$IFDEF LCLGTK2}
    fLastDoubleClickTime : TDateTime;

    function TooManyDoubleClicks: Boolean;
{$ENDIF}
    constructor Create(AOwner: TComponent; AParent: TWinControl); reintroduce;
    procedure AfterConstruction; override;

    procedure UpdateView;

    function MouseOnGrid(X, Y: LongInt): Boolean;

    // Returns height of all the header rows.
    function GetHeaderHeight: Integer;
    function GetVisibleIndexes: TRange;

    property GridVertLine: Boolean read GetGridVertLine write SetGridVertLine;
    property GridHorzLine: Boolean read GetGridHorzLine write SetGridHorzLine;
  end;

  { TColumnsFileViewVTV }

  TColumnsFileViewVTV = class(TOrderedFileView)
  private
    FColumnsSorting: TColumnsSortings;
    FFileNameColumn: Integer;
    FExtensionColumn: Integer;
    FLastSelectionState: Boolean;

    pmColumnsMenu: TPopupMenu;
    edtRename: TEdit;
    dgPanel: TColumnsDrawTree;
    tmContextMenu: TTimer;
    tmClearGrid: TTimer;

    function GetColumnsClass: TPanelColumnsClass;

    procedure SetRowCount(Count: Integer);
    procedure SetFilesDisplayItems;
    procedure SetColumns;

    procedure MakeVisible(Node: PVirtualNode);
    procedure DoSelectionChanged(Node: PVirtualNode); overload;

    {en
       Updates GUI after the display file list has changed.
    }
    procedure DisplayFileListHasChanged;
    {en
       Format and cache all columns strings for the file.
    }
    procedure MakeColumnsStrings(AFile: TDisplayFile);
    procedure MakeColumnsStrings(AFile: TDisplayFile; ColumnsClass: TPanelColumnsClass);
    procedure ClearAllColumnsStrings;
    procedure EachViewUpdateColumns(AFileView: TFileView; UserData: Pointer);

    {en
       Prepares sortings for later use in Sort function.
       This function must be called from main thread.
    }
    function PrepareSortings: TFileSortings;
    {en
       Translates file sorting by functions to sorting by columns.
    }
    procedure SetColumnsSorting(const ASortings: TFileSortings);

    {en
       Checks which file properties are needed for displaying.
    }
    function GetFilePropertiesNeeded: TFilePropertiesTypes;

    procedure ShowRenameFileEdit(AFile: TFile);

    // -- Events --------------------------------------------------------------

    procedure edtRenameExit(Sender: TObject);

    procedure edtRenameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure dgPanelEnter(Sender: TObject);
    procedure dgPanelExit(Sender: TObject);
    procedure dgPanelAdvancedHeaderDraw(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo;
      const Elements: THeaderPaintElements);
    procedure dgPanelAfterItemPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect);
    procedure dgPanelBeforeItemErase(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect; var ItemColor: TColor; var EraseAction: TItemEraseAction);
    procedure dgPanelHeaderDrawQueryElements(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo;
      var Elements: THeaderPaintElements);
    procedure dgPanelDblClick(Sender: TObject);
    procedure dgPanelKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dgPanelKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure dgPanelMouseLeave(Sender: TObject);
    procedure dgPanelMouseDown(Sender: TObject; Button: TMouseButton;
                                    Shift: TShiftState; X, Y: Integer);
    procedure dgPanelMouseMove(Sender: TObject; Shift: TShiftState;
                               X, Y: Integer);
    procedure dgPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure dgPanelStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure dgPanelDragOver(Sender: TBaseVirtualTree; Source: TObject; Shift: TShiftState; State: TDragState;
      const Pt: TPoint; Mode: TDropMode; var Effect: Integer; var Accept: Boolean);
    procedure dgPanelDragDrop(Sender: TBaseVirtualTree; Source: TObject;
      Formats: TFormatArray; Shift: TShiftState; const Pt: TPoint; var Effect: Integer; Mode: TDropMode);
    procedure dgPanelEndDrag(Sender, Target: TObject; X, Y: Integer);
    procedure dgPanelFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure dgPanelFocusChanging(Sender: TBaseVirtualTree; OldNode, NewNode: PVirtualNode; OldColumn,
      NewColumn: TColumnIndex; var Allowed: Boolean);
    procedure dgPanelHeaderClick(Sender: TVTHeader; Column: TColumnIndex;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure dgPanelMouseWheelUp(Sender: TObject; Shift: TShiftState;
                                  MousePos: TPoint; var Handled: Boolean);
    procedure dgPanelMouseWheelDown(Sender: TObject; Shift: TShiftState;
                                  MousePos: TPoint; var Handled: Boolean);
    procedure dgPanelShowHint(Sender: TObject; HintInfo: PHintInfo);
    procedure dgPanelScroll(Sender: TBaseVirtualTree; DeltaX, DeltaY: Integer);
    procedure dgPanelResize(Sender: TObject);
    procedure tmContextMenuTimer(Sender: TObject);
    procedure tmClearGridTimer(Sender: TObject);
    procedure ColumnsMenuClick(Sender: TObject);

    procedure UTF8KeyPressEvent(Sender: TObject; var UTF8Key: TUTF8Char);

  protected
    procedure CreateDefault(AOwner: TWinControl); override;

    procedure BeforeMakeFileList; override;
    procedure AfterMakeFileList; override;
    procedure DoFileUpdated(AFile: TDisplayFile; UpdatedProperties: TFilePropertiesTypes = []); override;
    procedure DoUpdateView; override;
    function GetActiveFileIndex: PtrInt; override;
    function GetVisibleFilesIndexes: TRange; override;
    procedure RedrawFile(FileIndex: PtrInt); override;
    procedure RedrawFile(DisplayFile: TDisplayFile); override;
    procedure RedrawFiles; override;
    {en
       Changes drawing colors depending on if this panel is active.
    }
    procedure SetActive(bActive: Boolean); override;
    procedure SetActiveFile(FileIndex: PtrInt); override;
    procedure SetSorting(const NewSortings: TFileSortings); override;

    procedure WorkerStarting(const Worker: TFileViewWorker); override;
    procedure WorkerFinished(const Worker: TFileViewWorker); override;

  public
    ActiveColm: String;
    ActiveColmSlave: TPanelColumnsClass;
    isSlave:boolean;
//---------------------

    constructor Create(AOwner: TWinControl; AFileSource: IFileSource; APath: String; AFlags: TFileViewFlags = []); override;
    constructor Create(AOwner: TWinControl; AFileView: TFileView; AFlags: TFileViewFlags = []); override;
    constructor Create(AOwner: TWinControl; AConfig: TIniFileEx; ASectionName: String; ATabIndex: Integer; AFlags: TFileViewFlags = []); override;
    constructor Create(AOwner: TWinControl; AConfig: TXmlConfig; ANode: TXmlNode; AFlags: TFileViewFlags = []); override;

    destructor Destroy; override;

    function Clone(NewParent: TWinControl): TColumnsFileViewVTV; override;
    procedure CloneTo(FileView: TFileView); override;

    procedure AddFileSource(aFileSource: IFileSource; aPath: String); override;

    procedure LoadConfiguration(Section: String; TabIndex: Integer); override;
    procedure SaveConfiguration(Section: String; TabIndex: Integer); override;
    procedure LoadConfiguration(AConfig: TXmlConfig; ANode: TXmlNode); override;
    procedure SaveConfiguration(AConfig: TXmlConfig; ANode: TXmlNode); override;

    function Focused: Boolean; override;
    procedure SetFocus; override;

    procedure UpdateColumnsView;

    procedure DoDragDropOperation(Operation: TDragDropOperation;
                                  var DropParams: TDropParams); override;

  published  // commands
    procedure cm_RenameOnly(const Params: array of string);
    procedure cm_ContextMenu(const Params: array of string);
  end;

implementation

uses
  LCLProc, Clipbrd, uLng, uShowMsg, uGlobs, uPixmapManager, uDebug,
  uDCUtils, DCStrUtils, math, fMain, fOptions,
  uInfoToolTip,
  uFileSourceProperty,
  uFileSourceOperationTypes,
  uFileSystemFileSource,
  fColumnsSetConf,
  uKeyboard,
  uFileSourceUtil,
  uFileFunctions,
  uFormCommands,
  fOptionsCustomColumns
{$IF DEFINED(LCLGTK)}
  , GtkProc  // for ReleaseMouseCapture
  , GTKGlobals  // for DblClickTime
{$ENDIF}
{$IF DEFINED(LCLGTK2)}
  , Gtk2Proc  // for ReleaseMouseCapture
  , GTK2Globals  // for DblClickTime
{$ENDIF}
  ;

type
  TEachViewCallbackReason = (evcrUpdateColumns);
  TEachViewCallbackMsg = record
    Reason: TEachViewCallbackReason;
    UpdatedColumnsSetName: String;
    NewColumnsSetName: String; // If columns name renamed
  end;
  PEachViewCallbackMsg = ^TEachViewCallbackMsg;

function TColumnsFileViewVTV.Focused: Boolean;
begin
  Result := Assigned(dgPanel) and dgPanel.Focused;
end;

procedure TColumnsFileViewVTV.SetFocus;
begin
  // CanFocus checks parent controls, but not parent form.
  if GetParentForm(Self).CanFocus and dgPanel.CanFocus then
    dgPanel.SetFocus;
end;

procedure TColumnsFileViewVTV.SetActive(bActive: Boolean);
begin
  inherited SetActive(bActive);
  dgPanel.Color := DimColor(gBackColor);
end;

procedure TColumnsFileViewVTV.SetSorting(const NewSortings: TFileSortings);
begin
  SetColumnsSorting(NewSortings);
  inherited SetSorting(PrepareSortings); // NewSortings
  SortAllDisplayFiles;
  ReDisplayFileList;
end;

procedure TColumnsFileViewVTV.LoadConfiguration(Section: String; TabIndex: Integer);
var
  ColumnsClass: TPanelColumnsClass;
  SortCount: Integer;
  SortColumn: Integer;
  SortDirection: uFileSorting.TSortDirection;
  i: Integer;
  sIndex: String;
begin
  sIndex := IntToStr(TabIndex);

  ActiveColm := gIni.ReadString(Section, sIndex + '_columnsset', 'Default');

  // Load sorting options.
  FColumnsSorting.Clear;
  ColumnsClass := GetColumnsClass;
  SortCount := gIni.ReadInteger(Section, sIndex + '_sortcount', 0);
  for i := 0 to SortCount - 1 do
  begin
    SortColumn := gIni.ReadInteger(Section, sIndex + '_sortcolumn' + IntToStr(i), -1);
    if (SortColumn >= 0) and (SortColumn < ColumnsClass.ColumnsCount) then
    begin
      SortDirection := uFileSorting.TSortDirection(gIni.ReadInteger(Section, sIndex + '_sortdirection' + IntToStr(i), Integer(sdNone)));
      FColumnsSorting.AddSorting(SortColumn, SortDirection);
    end;
  end;
  inherited SetSorting(PrepareSortings);
end;

procedure TColumnsFileViewVTV.SaveConfiguration(Section: String; TabIndex: Integer);
var
  SortingColumn: PColumnsSorting;
  sIndex: String;
  i: Integer;
begin
  sIndex := IntToStr(TabIndex);

  gIni.WriteString(Section, sIndex + '_columnsset', ActiveColm);

  // Save sorting options.
  gIni.WriteInteger(Section, sIndex + '_sortcount', FColumnsSorting.Count);
  for i := 0 to FColumnsSorting.Count - 1 do
  begin
    SortingColumn := PColumnsSorting(FColumnsSorting.Items[i]);

    gIni.WriteInteger(Section, sIndex + '_sortcolumn' + IntToStr(i),
                      SortingColumn^.Column);
    gIni.WriteInteger(Section, sIndex + '_sortdirection' + IntToStr(i),
                      Integer(SortingColumn^.SortDirection));
  end;
end;

procedure TColumnsFileViewVTV.LoadConfiguration(AConfig: TXmlConfig; ANode: TXmlNode);
var
  ColumnsClass: TPanelColumnsClass;
  SortColumn: Integer;
  SortDirection: uFileSorting.TSortDirection;
  ColumnsViewNode: TXmlNode;
begin
  inherited LoadConfiguration(AConfig, ANode);

  // Try to read new view-specific node.
  ColumnsViewNode := AConfig.FindNode(ANode, 'ColumnsView');
  if Assigned(ColumnsViewNode) then
    ANode := ColumnsViewNode;

  ActiveColm := AConfig.GetValue(ANode, 'ColumnsSet', 'Default');

  // Load sorting options.
  FColumnsSorting.Clear;
  ColumnsClass := GetColumnsClass;
  ANode := ANode.FindNode('Sorting');
  if Assigned(ANode) then
  begin
    ANode := ANode.FirstChild;
    while Assigned(ANode) do
    begin
      if ANode.CompareName('Sort') = 0 then
      begin
        if AConfig.TryGetValue(ANode, 'Column', SortColumn) and
           (SortColumn >= 0) and (SortColumn < ColumnsClass.ColumnsCount) then
        begin
          SortDirection := uFileSorting.TSortDirection(AConfig.GetValue(ANode, 'Direction', Integer(sdNone)));
          FColumnsSorting.AddSorting(SortColumn, SortDirection);
        end
        else
          DCDebug('Invalid entry in configuration: ' + AConfig.GetPathFromNode(ANode) + '.');
      end;
      ANode := ANode.NextSibling;
    end;
    inherited SetSorting(PrepareSortings);
  end;
end;

procedure TColumnsFileViewVTV.SaveConfiguration(AConfig: TXmlConfig; ANode: TXmlNode);
var
  SortingColumn: PColumnsSorting;
  i: Integer;
  SubNode: TXmlNode;
begin
  inherited SaveConfiguration(AConfig, ANode);

  AConfig.SetAttr(ANode, 'Type', 'columns');
  ANode := AConfig.FindNode(ANode, 'ColumnsView', True);
  AConfig.ClearNode(ANode);

  AConfig.SetValue(ANode, 'ColumnsSet', ActiveColm);
  ANode := AConfig.FindNode(ANode, 'Sorting', True);

  // Save sorting options.
  for i := 0 to FColumnsSorting.Count - 1 do
  begin
    SortingColumn := PColumnsSorting(FColumnsSorting.Items[i]);
    SubNode := AConfig.AddNode(ANode, 'Sort');
    AConfig.AddValue(SubNode, 'Column', SortingColumn^.Column);
    AConfig.AddValue(SubNode, 'Direction', Integer(SortingColumn^.SortDirection));
  end;
end;

procedure TColumnsFileViewVTV.dgPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  AFile: TDisplayFile;
  Node: PVirtualNode;
begin
  if (Y < dgPanel.GetHeaderHeight) then Exit; // if is header

  SetFocus;

  // history navigation for mice with extra buttons
  case Button of
    mbExtra1:
      begin
        GoToPrevHistory;
        Exit;
      end;
    mbExtra2:
      begin
        GoToNextHistory;
        Exit;
      end;
  end;

  if IsEmpty then Exit;

  Node := dgPanel.GetNodeAt(X, Y);

  if Assigned(Node) then
  begin
    AFile := dgPanel.GetNodeFile(Node);
    dgPanel.LastMouseButton:= Button;

    case Button of
      mbRight:
      begin
        dgPanel.FocusedNode := Node;

        if (gMouseSelectionEnabled) and (gMouseSelectionButton = 1) then
        begin
          begin
            dgPanel.SelectionStartIndex:=Node^.Index;
            tmContextMenu.Enabled:= True; // start context menu timer
            FLastSelectionState:= not AFile.Selected;
            MarkFile(AFile, FLastSelectionState, False);
            Exit;
          end;
        end;
      end;

      mbLeft:
      begin
        if gMouseSelectionEnabled then
        begin
          if ssCtrl in Shift then
            begin
              // if there is no selected files then select also previous file
              if not HasSelectedFiles then
                MarkFile(dgPanel.GetNodeFile(dgPanel.FocusedNode), True, False);
              InvertFileSelection(AFile, False);
              DoSelectionChanged(Node);
            end
          else if ssShift in Shift then
            begin
              SelectRange(Node^.Index);
            end
          else if (gMouseSelectionButton = 0) then
            begin
              if not AFile.Selected then
                MarkFiles(False);
            end;
        end;//of mouse selection handler
      end;
    else
      dgPanel.FocusedNode := Node;
      Exit;
    end;
  end
  else // if mouse on empty space
    begin
      if (Button = mbRight) and (gMouseSelectionEnabled) and (gMouseSelectionButton = 1) then
        tmContextMenu.Enabled:= True; // start context menu timer
    end;

  { Dragging }

  if (not dgPanel.Dragging)   and  // we could be in dragging mode already (started by a different button)
     (dgPanel.MouseOnGrid(X, Y)) then // check if there is an item under the mouse cursor
  begin
    // indicate that drag start at next mouse move event
    dgPanel.StartDrag:= True;
    dgPanel.DragStartPoint.X := X;
    dgPanel.DragStartPoint.Y := Y;
    dgPanel.DragNode := Node;
    uDragDropEx.TransformDragging := False;
    uDragDropEx.AllowTransformToInternal := True;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  AFile: TDisplayFile;
  SelStartIndex, SelEndIndex: Integer;
  Node: PVirtualNode;
  i: Integer;
begin
  // if right mouse button selection enabled
  if dgPanel.FMouseDown and (dgPanel.LastMouseButton = mbRight) and
     gMouseSelectionEnabled and (gMouseSelectionButton = 1) then
    begin
      Node := dgPanel.GetNodeAt(X, Y);
      if not Assigned(Node) then
      begin
        if Y < dgPanel.GetHeaderHeight then
          Node := dgPanel.GetFirstNoInit
        else
          Node := dgPanel.GetLastNoInit;
      end;
      if dgPanel.FocusedNode <> Node then // if new row index
        begin
          tmContextMenu.Enabled:= False; // stop context menu timer
          if dgPanel.SelectionStartIndex < Node^.Index then begin
            SelStartIndex := dgPanel.SelectionStartIndex;
            SelEndIndex := Node^.Index;
          end else begin
            SelStartIndex := Node^.Index;
            SelEndIndex := dgPanel.SelectionStartIndex;

          end;
          dgPanel.FocusedNode:= Node;
          BeginUpdate;
          try
            for i := SelStartIndex to SelEndIndex do
            begin
              AFile := FFiles[i];
              MarkFile(AFile, FLastSelectionState);
            end;
          finally
            EndUpdate;
          end;
        end;
    end;
end;

{ Show context or columns menu on right click }
{ Is called manually from TColumnsDrawTree.MouseUp }
procedure TColumnsFileViewVTV.dgPanelMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Background: Boolean;
begin
  if Button = mbRight then
    begin
      { If right click on file/directory }
      if ((gMouseSelectionButton<>1) or not gMouseSelectionEnabled) then
        begin
          Background:= not (Sender as TColumnsDrawTree).MouseOnGrid(X, Y);
          frmMain.Commands.DoContextMenu(Self, Mouse.CursorPos.x, Mouse.CursorPos.y, Background);
        end
      else if (gMouseSelectionEnabled and (gMouseSelectionButton = 1)) then
        begin
          tmContextMenu.Enabled:= False; // stop context menu timer
        end;
    end
  { Open folder in new tab on middle click }
  else if (Button = mbMiddle) and (Y > dgPanel.GetHeaderHeight) then
    begin
      frmMain.Commands.cm_OpenDirInNewTab([]);
    end;
end;

procedure TColumnsFileViewVTV.dgPanelStartDrag(Sender: TObject; var DragObject: TDragObject);
begin
end;

procedure TColumnsFileViewVTV.dgPanelDragOver(Sender: TBaseVirtualTree;
  Source: TObject; Shift: TShiftState; State: TDragState;
  const Pt: TPoint; Mode: TDropMode; var Effect: Integer; var Accept: Boolean);
var
  AFile: TDisplayFile = nil;
  SourcePanel: TColumnsFileViewVTV = nil;
  TargetPanel: TColumnsFileViewVTV = nil;
  SourceDir, TargetDir: String;
  Node: PVirtualNode;
begin
  Accept := False;

  if (not (Source is TColumnsDrawTree)) or (not (Sender is TColumnsDrawTree)) then
    Exit;

  // Always allow dropping into an empty panel.
  // And it is also allowed to drop onto header in case all visible items
  // are directories and the user wants to drop into panel's current directory.
  if IsEmpty or (pt.y < dgPanel.GetHeaderHeight) then
  begin
    dgPanel.ChangeDropNode(nil);
    Accept:= True;
    Exit;
  end;

  SourcePanel := ((Source as TColumnsDrawTree).Parent) as TColumnsFileViewVTV;
  TargetPanel := ((Sender as TColumnsDrawTree).Parent) as TColumnsFileViewVTV;

  SourceDir := SourcePanel.CurrentPath;
  TargetDir := TargetPanel.CurrentPath;

  Node := dgPanel.GetNodeAt(pt.x, pt.y);

  if Assigned(Node) then
    AFile := dgPanel.GetNodeFile(Node);

  if Assigned(AFile) and
     (AFile.FSFile.IsDirectory or AFile.FSFile.IsLinkToDirectory) and
     (dgPanel.MouseOnGrid(pt.x, pt.y))
  then
    begin
      if State = dsDragLeave then
        // Mouse is leaving the control or drop will occur immediately.
        // Don't draw DropRow rectangle.
        dgPanel.ChangeDropNode(nil)
      else
        dgPanel.ChangeDropNode(Node);

      if Sender = Source then
      begin
        if not ((Node = dgPanel.DragNode) or (AFile.Selected = True)) then
          Accept := True;
      end
      else
      begin
        if Assigned(SourcePanel) and Assigned(TargetPanel) then
        begin
          if AFile.FSFile.Name = '..' then
            TargetDir := TargetPanel.FileSource.GetParentDir(TargetDir)
          else
            TargetDir := TargetDir + AFile.FSFile.Name + DirectorySeparator;

          if SourceDir <> TargetDir then Accept := True;
        end
        else
          Accept := True;
      end;
    end
  else if (Sender <> Source) then
    begin
      dgPanel.ChangeDropNode(nil);

      if Assigned(SourcePanel) and Assigned(TargetPanel) then
      begin
        if SourcePanel.CurrentPath <> TargetPanel.CurrentPath then
          Accept := True;
      end
      else
        Accept := True;
    end
  else
    begin
      dgPanel.ChangeDropNode(nil);
    end;
end;

procedure TColumnsFileViewVTV.dgPanelDragDrop(Sender: TBaseVirtualTree;
  Source: TObject;
  Formats: TFormatArray; Shift: TShiftState;
  const Pt: TPoint; var Effect: Integer; Mode: TDropMode);
var
  SourcePanel: TColumnsFileViewVTV;
  SourceFiles: TFiles;
  DropParams: TDropParams;
begin
  if (Sender is TColumnsDrawTree) and (Source is TColumnsDrawTree) then
  begin
    SourcePanel := ((Source as TColumnsDrawTree).Parent) as TColumnsFileViewVTV;

    // Get file names from source panel.
    SourceFiles := SourcePanel.CloneSelectedFiles;
    try
      // Drop onto target panel.
      with Sender as TColumnsDrawTree do
      begin
        DropParams := TDropParams.Create(
          SourceFiles, // Will be freed automatically.
          GetDropEffectByKeyAndMouse(GetKeyShiftState,
                                    (Source as TColumnsDrawTree).LastMouseButton),
          ClientToScreen(Classes.Point(pt.x, pt.y)),
          True,
          SourcePanel,
          Self, Self.CurrentPath);

        frmMain.DropFiles(DropParams);
        ChangeDropNode(nil);
      end;
    except
      FreeAndNil(SourceFiles);
      raise;
    end;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelEndDrag(Sender, Target: TObject; X, Y: Integer);
  procedure ClearDropNode(aFileView: TFileView);
  begin
    if aFileView is TColumnsFileViewVTV then
      TColumnsFileViewVTV(aFileView).dgPanel.ChangeDropNode(nil);
  end;
begin
  // If cancelled by the user, DragManager does not send drag-leave event
  // to the target, so we must clear the DropNode in both panels.

  ClearDropNode(frmMain.FrameLeft);
  ClearDropNode(frmMain.FrameRight);

  if uDragDropEx.TransformDragging = False then
    dgPanel.ClearMouseButtonAfterDrag;
end;

procedure TColumnsFileViewVTV.dgPanelFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
var
  aFile: TFile = nil;
begin
  dgPanel.TreeOptions.AutoOptions := dgPanel.TreeOptions.AutoOptions - [toDisableAutoscrollOnFocus];

  if Assigned(Node) and (FLastActiveFileIndex <> Node^.Index) and (not FUpdatingActiveFile) then
    begin
      FLastActiveFileIndex := Node^.Index;

      if Assigned(Node) then
      begin
        SetLastActiveFile(Node^.Index);
        if Assigned(OnChangeActiveFile) then
        begin
          aFile := dgPanel.GetNodeFile(Node).FSFile.Clone;
          try
            OnChangeActiveFile(Self, aFile);
          finally
            FreeAndNil(aFile);
          end;
        end;
      end
      else
        LastActiveFile := '';
    end;
end;

procedure TColumnsFileViewVTV.dgPanelFocusChanging(Sender: TBaseVirtualTree;
  OldNode, NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex; var Allowed: Boolean);
begin
  if (OldColumn <> NewColumn) and (OldNode = NewNode) then
    dgPanel.TreeOptions.AutoOptions := dgPanel.TreeOptions.AutoOptions + [toDisableAutoscrollOnFocus]
  else
    dgPanel.TreeOptions.AutoOptions := dgPanel.TreeOptions.AutoOptions - [toDisableAutoscrollOnFocus];
end;

procedure TColumnsFileViewVTV.dgPanelHeaderClick(Sender: TVTHeader; Column: TColumnIndex;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ShiftState : TShiftState;
  SortingDirection : uFileSorting.TSortDirection = uFileSorting.sdAscending;
  I : Integer;
  Point: TPoint;
  MI: TMenuItem;
begin
  case Button of
    mbLeft:
      begin
        ShiftState := GetKeyShiftStateEx;
        if not ((ssShift in ShiftState) or (ssCtrl in ShiftState)) then
        begin
          SortingDirection := FColumnsSorting.GetSortingDirection(Column);
          if SortingDirection = uFileSorting.sdNone then
            SortingDirection := uFileSorting.sdAscending
          else
            SortingDirection := ReverseSortDirection(SortingDirection);
          FColumnsSorting.Clear;
        end;

        FColumnsSorting.AddSorting(Column, SortingDirection);
        inherited SetSorting(PrepareSortings);
        SortAllDisplayFiles;
        ReDisplayFileList;
      end;

    mbRight:
      begin
        //Load Columns into menu
        pmColumnsMenu.Items.Clear;
        if ColSet.Items.Count>0 then
          begin
            For I:=0 to ColSet.Items.Count-1 do
              begin
                MI:=TMenuItem.Create(pmColumnsMenu);
                MI.Tag:=I;
                MI.Caption:=ColSet.Items[I];
                MI.OnClick:=@ColumnsMenuClick;
                pmColumnsMenu.Items.Add(MI);
              end;
          end;

        //-
    	  MI:=TMenuItem.Create(pmColumnsMenu);
    	  MI.Caption:='-';
    	  pmColumnsMenu.Items.Add(MI);
        //Configure this custom columns
    	  MI:=TMenuItem.Create(pmColumnsMenu);
    	  MI.Tag:=1000;
    	  MI.Caption:=rsMenuConfigureThisCustomColumn;
    	  MI.OnClick:=@ColumnsMenuClick;
    	  pmColumnsMenu.Items.Add(MI);
        //Configure custom columns
    	  MI:=TMenuItem.Create(pmColumnsMenu);
    	  MI.Tag:=1001;
    	  MI.Caption:=rsMenuConfigureCustomColumns;
    	  MI.OnClick:=@ColumnsMenuClick;
    	  pmColumnsMenu.Items.Add(MI);

        Point   := dgPanel.ClientToScreen(Classes.Point(0,0));
        Point.X := Point.X + X - 50;
        Point.Y := Point.Y + dgPanel.GetHeaderHeight;
        pmColumnsMenu.PopUp(Point.X, Point.Y);
      end;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelAdvancedHeaderDraw(Sender: TVTHeader;
  var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
var
  SortingDirection: uFileSorting.TSortDirection;
  TitleX: Integer;
  ColumnsSet: TPanelColumnsClass;
  aCol: Integer;
  iTextTop: Integer;
  s: String;
  aRect: TRect;
begin
  aCol  := PaintInfo.Column.Index;
  aRect := PaintInfo.PaintRectangle;
  // PaintRectangle is reduced by 2 pixels on each side even with owner draw,
  // so revert this change.
  InflateRect(aRect, 2, 2);

  ColumnsSet := GetColumnsClass;

  iTextTop := aRect.Top + (PaintInfo.Column.Owner.Header.Height - PaintInfo.TargetCanvas.TextHeight('Wg')) div 2;
  TitleX   := 0;
  s        := ColumnsSet.GetColumnTitle(ACol);

  SortingDirection := FColumnsSorting.GetSortingDirection(ACol);
  if SortingDirection <> sdNone then
  begin
    TitleX := TitleX + gIconsSize;
    PixMapManager.DrawBitmap(
        PixMapManager.GetIconBySortingDirection(SortingDirection),
        PaintInfo.TargetCanvas,
        aRect.Left, aRect.Top + (PaintInfo.Column.Owner.Header.Height - gIconsSize) div 2);
  end;

  TitleX := max(TitleX, 4);

  if gCutTextToColWidth then
  begin
    if (aRect.Right - aRect.Left) < TitleX then
      // Column too small to display text.
      Exit
    else
      while PaintInfo.TargetCanvas.TextWidth(s) - ((aRect.Right - aRect.Left) - TitleX) > 0 do
        UTF8Delete(s, UTF8Length(s), 1);
  end;

  PaintInfo.TargetCanvas.TextOut(aRect.Left + TitleX, iTextTop, s);
end;

procedure TColumnsFileViewVTV.dgPanelAfterItemPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect);
var
  ColumnsSet: TPanelColumnsClass;
  IsFocused: Boolean;

  procedure DrawLines;
  begin
    // Draw focus rect.
    if not gUseFrameCursor and IsFocused and Active then
    begin
      TargetCanvas.Pen.Color := ColumnsSet.GetCursorBorderColor;
      TargetCanvas.Brush.Color := ColumnsSet.GetCursorBorderColor;
      TargetCanvas.FrameRect(ItemRect);
    end;
  end;
begin
  IsFocused := Node = dgPanel.FocusedNode;
  ColumnsSet := GetColumnsClass;
  DrawLines;
end;

procedure TColumnsFileViewVTV.dgPanelBeforeItemErase(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; const ItemRect: TRect; var ItemColor: TColor; var EraseAction: TItemEraseAction);
begin
  EraseAction := eaNone;
end;

procedure TColumnsFileViewVTV.dgPanelHeaderDrawQueryElements(Sender: TVTHeader;
  var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements);
begin
  Elements := [hpeSortGlyph, hpeText];
end;

procedure TColumnsFileViewVTV.dgPanelMouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  I: Integer;
begin
  Handled:= True;
  case gScrollMode of
  smLineByLine:
    for I:= 1 to gWheelScrollLines do
    dgPanel.Perform(LM_VSCROLL, SB_LINEUP, 0);
  smPageByPage:
    dgPanel.Perform(LM_VSCROLL, SB_PAGEUP, 0);
  else
    Handled:= False;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelMouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
var
  I: Integer;
begin
  Handled:= True;
  case gScrollMode of
  smLineByLine:
    for I:= 1 to gWheelScrollLines do
    dgPanel.Perform(LM_VSCROLL, SB_LINEDOWN, 0);
  smPageByPage:
    dgPanel.Perform(LM_VSCROLL, SB_PAGEDOWN, 0);
  else
    Handled:= False;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelShowHint(Sender: TObject; HintInfo: PHintInfo);
var
  AFile: TDisplayFile;
  sHint: UTF8String;
begin
  if (HintInfo^.HintStr = EmptyStr) or not Assigned(dgPanel.HintNode) then
    Exit;

  AFile := dgPanel.GetNodeFile(dgPanel.HintNode);
  if not AFile.FSFile.IsDirectory then
    begin
      sHint:= GetFileInfoToolTip(FileSource, AFile.FSFile);
      with HintInfo^ do
      if (sHint = EmptyStr) and (HintStr = #32) then  // no tooltip
        HintStr:= EmptyStr
      else if (sHint <> EmptyStr) then // has tooltip
        begin
          if HintStr = #32 then // without name
            HintStr:= sHint
          else
            HintStr:= HintStr + LineEnding + sHint;
        end;
    end;
end;

procedure TColumnsFileViewVTV.dgPanelScroll(Sender: TBaseVirtualTree; DeltaX, DeltaY: Integer);
begin
  if DeltaY <> 0 then
    EnsureDisplayProperties;
end;

procedure TColumnsFileViewVTV.dgPanelResize(Sender: TObject);
begin
  EnsureDisplayProperties;
end;

procedure TColumnsFileViewVTV.tmContextMenuTimer(Sender: TObject);
var
  AFile: TDisplayFile;
  MousePoint: TPoint;
  Background: Boolean;
  Node: PVirtualNode;
begin
  dgPanel.FMouseDown:= False;
  tmContextMenu.Enabled:= False; // stop context menu timer
  // show context menu
  MousePoint:= dgPanel.ScreenToClient(Mouse.CursorPos);
  Background:= not dgPanel.MouseOnGrid(MousePoint.x, MousePoint.y);

  if not Background then
  begin
    // get current node
    Node := dgPanel.GetNodeAt(MousePoint.x, MousePoint.y);
    if Assigned(Node) then
    begin
      AFile := dgPanel.GetNodeFile(Node);
      MarkFile(AFile, not FLastSelectionState, False);
      DoSelectionChanged(Node);
    end;
  end;

  frmMain.Commands.DoContextMenu(Self, Mouse.CursorPos.x, Mouse.CursorPos.y, Background);
end;

procedure TColumnsFileViewVTV.tmClearGridTimer(Sender: TObject);
begin
  tmClearGrid.Enabled := False;

  if IsEmpty then
  begin
    SetRowCount(0);
    RedrawFiles;
  end;
end;

procedure TColumnsFileViewVTV.ShowRenameFileEdit(AFile: TFile);
var
  ALeft, ATop, AWidth, AHeight: Integer;
  aRect: TRect;
begin
  if FFileNameColumn <> -1 then
  begin
    edtRename.Font.Name  := GetColumnsClass.GetColumnFontName(FFileNameColumn);
    edtRename.Font.Size  := GetColumnsClass.GetColumnFontSize(FFileNameColumn);
    edtRename.Font.Style := GetColumnsClass.GetColumnFontStyle(FFileNameColumn);

    aRect := dgPanel.GetDisplayRect(dgPanel.FocusedNode, FFileNameColumn, False);
    ATop := aRect.Top - 2;
    ALeft := aRect.Left;
    if gShowIcons <> sim_none then
      Inc(ALeft, gIconsSize + 2);
    AWidth := aRect.Right - aRect.Left;
    if Succ(FFileNameColumn) = FExtensionColumn then
      Inc(AWidth, dgPanel.Header.Columns[FExtensionColumn].Width);
    AHeight := dgPanel.FocusedNode^.NodeHeight + 4;

    edtRename.SetBounds(ALeft, ATop, AWidth, AHeight);

    edtRename.Hint := aFile.FullPath;
    edtRename.Text := aFile.Name;
    edtRename.Visible := True;
    edtRename.SetFocus;
    if gRenameSelOnlyName and (aFile.Extension <> EmptyStr) and (aFile.Name <> EmptyStr) then
      begin
        {$IFDEF LCLGTK2}
        edtRename.SelStart:=1;
        {$ENDIF}
        edtRename.SelStart:=0;
        edtRename.SelLength:= UTF8Length(aFile.Name) - UTF8Length(aFile.Extension) - 1;
      end
    else
      edtRename.SelectAll;
  end;
end;

function TColumnsFileViewVTV.PrepareSortings: TFileSortings;
var
  ColumnsClass: TPanelColumnsClass;
  i: Integer;
  pSortingColumn : PColumnsSorting;
  Column: TPanelColumn;
begin
  Result := nil;

  ColumnsClass := GetColumnsClass;
  if ColumnsClass.ColumnsCount = 0 then
    Exit;

  for i := 0 to FColumnsSorting.Count - 1 do
  begin
    pSortingColumn := PColumnsSorting(FColumnsSorting[i]);

    if (pSortingColumn^.Column >= 0) and
       (pSortingColumn^.Column < ColumnsClass.ColumnsCount) then
    begin
      Column := ColumnsClass.GetColumnItem(pSortingColumn^.Column);
      AddSorting(Result, Column.GetColumnFunctions, pSortingColumn^.SortDirection);
    end;
  end;
end;

procedure TColumnsFileViewVTV.RedrawFile(FileIndex: PtrInt);
begin
  dgPanel.InvalidateNode(PVirtualNode(FFiles[FileIndex].DisplayItem));
end;

procedure TColumnsFileViewVTV.RedrawFile(DisplayFile: TDisplayFile);
begin
  dgPanel.InvalidateNode(PVirtualNode(DisplayFile.DisplayItem));
end;

procedure TColumnsFileViewVTV.SetColumnsSorting(const ASortings: TFileSortings);

var
  Columns: TPanelColumnsClass;

  function AddColumnsSorting(ASortFunction: TFileFunction; ASortDirection: uFileSorting.TSortDirection): Boolean;
  var
    k, l: Integer;
    ColumnFunctions: TFileFunctions;
  begin
    for k := 0 to Columns.Count - 1 do
    begin
      ColumnFunctions := Columns.GetColumnItem(k).GetColumnFunctions;
      for l := 0 to Length(ColumnFunctions) - 1 do
        if ColumnFunctions[l] = ASortFunction then
        begin
          FColumnsSorting.AddSorting(k, ASortDirection);
          Exit(True);
        end;
    end;
    Result := False;
  end;

var
  i, j: Integer;
begin
  FColumnsSorting.Clear;
  Columns := GetColumnsClass;
  for i := 0 to Length(ASortings) - 1 do
  begin
    for j := 0 to Length(ASortings[i].SortFunctions) - 1 do
    begin
      // Search for the column containing the sort function and add sorting
      // by that column. If function is Name and it is not found try searching
      // for NameNoExtension + Extension.
      if (not AddColumnsSorting(ASortings[i].SortFunctions[j], ASortings[i].SortDirection)) and
         (ASortings[i].SortFunctions[j] = fsfName) then
      begin
        if AddColumnsSorting(fsfNameNoExtension, ASortings[i].SortDirection) then
          AddColumnsSorting(fsfExtension, ASortings[i].SortDirection);
      end;
    end;
  end;
end;

procedure TColumnsFileViewVTV.SetFilesDisplayItems;
var
  Node: PVirtualNode;
  Index: Integer = 0;
begin
  Node := dgPanel.GetFirstNoInit;
  while Assigned(Node) do
  begin
    FFiles[Index].DisplayItem := Node;
    Inc(Index);
    Node := Node^.NextSibling;
  end;
end;

function TColumnsFileViewVTV.GetFilePropertiesNeeded: TFilePropertiesTypes;
var
  i, j: Integer;
  ColumnsClass: TPanelColumnsClass;
  Column: TPanelColumn;
  FileFunctionsUsed: TFileFunctions;
begin
  // By default always use some properties.
  Result := [fpName,
             fpSize,              // For info panel (total size, selected size)
             fpAttributes,        // For distinguishing directories
             fpLink,              // For distinguishing directories (link to dir) and link icons
             fpModificationTime   // For selecting/coloring files (by SearchTemplate)
            ];

  ColumnsClass := GetColumnsClass;
  FFileNameColumn := -1;
  FExtensionColumn := -1;

  // Scan through all columns.
  for i := 0 to ColumnsClass.Count - 1 do
  begin
    Column := ColumnsClass.GetColumnItem(i);
    FileFunctionsUsed := Column.GetColumnFunctions;
    if Length(FileFunctionsUsed) > 0 then
    begin
      // Scan through all functions in the column.
      for j := Low(FileFunctionsUsed) to High(FileFunctionsUsed) do
      begin
        // Add file properties needed to display the function.
        Result := Result + TFileFunctionToProperty[FileFunctionsUsed[j]];
        if (FFileNameColumn = -1) and (FileFunctionsUsed[j] in [fsfName, fsfNameNoExtension]) then
          FFileNameColumn := i;
        if (FExtensionColumn = -1) and (FileFunctionsUsed[j] in [fsfExtension]) then
          FExtensionColumn := i;
      end;
    end;
  end;
end;

function TColumnsFileViewVTV.GetVisibleFilesIndexes: TRange;
begin
  Result := dgPanel.GetVisibleIndexes;
end;

procedure TColumnsFileViewVTV.SetRowCount(Count: Integer);
begin
  FUpdatingActiveFile := True;
  dgPanel.RootNodeCount := Count;
  FUpdatingActiveFile := False;
end;

procedure TColumnsFileViewVTV.SetColumns;
var
  x: Integer;
  ColumnsClass: TPanelColumnsClass;
  col: TVirtualTreeColumn;
begin
  //  setup column widths
  ColumnsClass := GetColumnsClass;

  dgPanel.Header.Columns.Clear;
  dgPanel.Header.Columns.BeginUpdate;
  try
    for x:= 0 to ColumnsClass.ColumnsCount - 1 do
    begin
      col := dgPanel.Header.Columns.Add;
      if not ((x = 0) and gAutoFillColumns and (gAutoSizeColumn = 0)) then
        col.Options := col.Options + [coAutoSpring];
      if gAutoFillColumns then
        dgPanel.Header.AutoSizeIndex := gAutoSizeColumn;

      col.Width   := ColumnsClass.GetColumnWidth(x);
      //col.Text    := ColumnsClass.GetColumnTitle(x); // I think not needed, as we draw text ourselves.
      col.Margin  := 0;
      col.Spacing := 0;
    end;
  finally
    dgPanel.Header.Columns.EndUpdate;
  end;
end;

procedure TColumnsFileViewVTV.edtRenameExit(Sender: TObject);
begin
  edtRename.Visible := False;

  // dgPanelEnter don't called automatically (bug?)
  dgPanelEnter(dgPanel);
end;

procedure TColumnsFileViewVTV.edtRenameKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
var
  NewFileName: String;
  OldFileNameAbsolute: String;
  lenEdtText, lenEdtTextExt, i: Integer;
  seperatorSet: set of AnsiChar;
  aFile: TFile = nil;
begin
  case Key of
    VK_ESCAPE:
      begin
        Key := 0;
        edtRename.Visible:=False;
        SetFocus;
      end;

    VK_RETURN,
    VK_SELECT:
      begin
        Key := 0; // catch the enter

        NewFileName         := edtRename.Text;
        OldFileNameAbsolute := edtRename.Hint;

        aFile := CloneActiveFile;
        try
          try
            if RenameFile(FileSource, aFile, NewFileName, True) = True then
            begin
              edtRename.Visible:=False;
              SetActiveFile(CurrentPath + NewFileName);
              SetFocus;
            end
            else
              msgError(Format(rsMsgErrRename, [ExtractFileName(OldFileNameAbsolute), NewFileName]));

          except
            on e: EInvalidFileProperty do
              msgError(Format(rsMsgErrRename + ':' + LineEnding + '%s (%s)', [ExtractFileName(OldFileNameAbsolute), NewFileName, rsMsgInvalidFileName, e.Message]));
          end;
        finally
          FreeAndNil(aFile);
        end;
      end;

    VK_F2, VK_F6:
        begin
          Key := 0;
          lenEdtText := UTF8Length(edtRename.Text);
          lenEdtTextExt := UTF8Length(ExtractFileExt(edtRename.Text));
          if (edtRename.SelLength = lenEdtText) then
          begin
            // Now all selected, change it to name-only.
            edtRename.SelStart:= 0;
            edtRename.SelLength:= lenEdtText - lenEdtTextExt;
          end
          else if (edtRename.SelStart = 0) and (edtRename.SelLength = lenEdtText - lenEdtTextExt) then
          begin
            // Now name-only selected, change it to ext-only.
            edtRename.SelStart:= edtRename.SelLength + 1;
            edtRename.SelLength:= lenEdtText - edtRename.SelStart;
          end
          else begin
            // Partial selection cycle.
            seperatorSet:= [' ', '-', '_', '.'];
            i:= edtRename.SelStart + edtRename.SelLength;
            while true do
            begin
              if (edtRename.Text[UTF8CharToByteIndex(PChar(edtRename.Text), length(edtRename.Text), i)] in seperatorSet)
                  and not(edtRename.Text[UTF8CharToByteIndex(PChar(edtRename.Text), length(edtRename.Text), i+1)] in seperatorSet) then
              begin
                edtRename.SelStart:= i;
                Break;
              end;
              inc(i);
              if i >= lenEdtText then
              begin
                edtRename.SelStart:= 0;
                Break;
              end;
            end;
            i:= edtRename.SelStart + 1;
            while true do
            begin
              if (i >= lenEdtText)
                  or (edtRename.Text[UTF8CharToByteIndex(PChar(edtRename.Text), length(edtRename.Text), i+1)] in seperatorSet) then
              begin
                edtRename.SelLength:= i - edtRename.SelStart;
                Break;
              end;
              inc(i);
            end;
          end;
        end;

{$IFDEF LCLGTK2}
    // Workaround for GTK2 - up and down arrows moving through controls.
    VK_UP,
    VK_DOWN:
      Key := 0;
{$ENDIF}
  end;
end;

procedure TColumnsFileViewVTV.MakeVisible(Node: PVirtualNode);
begin
  dgPanel.ScrollIntoView(Node, False, False);
end;

procedure TColumnsFileViewVTV.dgPanelExit(Sender: TObject);
begin
  SetActive(False);
end;

procedure TColumnsFileViewVTV.SetActiveFile(FileIndex: PtrInt);
begin
  dgPanel.FocusedNode := PVirtualNode(FFiles[FileIndex].DisplayItem);
end;

procedure TColumnsFileViewVTV.dgPanelDblClick(Sender: TObject);
var
  Point : TPoint;
  Node: PVirtualNode;
begin
{$IFDEF LCLGTK2}
  // Workaround for two doubleclicks being sent on GTK.
  if dgPanel.TooManyDoubleClicks then Exit;
{$ENDIF}

  dgPanel.StartDrag:= False; // don't start drag on double click
  Point:= dgPanel.ScreenToClient(Mouse.CursorPos);

  // If on a file/directory then choose it.
  Node := dgPanel.GetNodeAt(Point.X, Point.Y);
  if Assigned(Node) then
  begin
    ChooseFile(dgPanel.GetNodeFile(Node));
  end;

{$IFDEF LCLGTK2}
  dgPanel.fLastDoubleClickTime := Now;
{$ENDIF}
end;

procedure TColumnsFileViewVTV.dgPanelEnter(Sender: TObject);
begin
  SetActive(True);

  if Assigned(OnActivate) then
    OnActivate(Self);
end;

procedure TColumnsFileViewVTV.RedrawFiles;
begin
  dgPanel.Invalidate;
end;

procedure TColumnsFileViewVTV.UpdateColumnsView;
var
  ColumnsClass: TPanelColumnsClass;
  OldFilePropertiesNeeded: TFilePropertiesTypes;
begin
  ClearAllColumnsStrings;

  // If the ActiveColm set doesn't exist this will retrieve either
  // the first set or the default set.
  ColumnsClass := GetColumnsClass;
  // Set name in case a different set was loaded.
  ActiveColm := ColumnsClass.Name;

  SetColumns;

  dgPanel.UpdateView;

  OldFilePropertiesNeeded := FilePropertiesNeeded;
  FilePropertiesNeeded := GetFilePropertiesNeeded;
  if FilePropertiesNeeded >= OldFilePropertiesNeeded then
  begin
    EnsureDisplayProperties;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_SHIFT: begin
      FLastSelectionStartIndex := -1;
    end;
  end;
end;

procedure TColumnsFileViewVTV.dgPanelMouseLeave(Sender: TObject);
begin
  if (gMouseSelectionEnabled) and (gMouseSelectionButton = 1) then
    dgPanel.FMouseDown:= False;
end;

procedure TColumnsFileViewVTV.dgPanelKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  ScreenPoint: TPoint;
  aFile: TDisplayFile;
  Node, NextNode: PVirtualNode;
begin
  // check if ShiftState is equal to quick search / filter modes
  if quickSearch.CheckSearchOrFilter(Key) then
    Exit;

  case Key of
    VK_APPS:
      begin
        cm_ContextMenu([]);
        Key := 0;
      end;

    VK_INSERT:
      begin
        if not IsEmpty then
        begin
          Node := dgPanel.FocusedNode;
          if IsActiveItemValid then
          begin
            InvertFileSelection(GetActiveDisplayFile, False);
            DoSelectionChanged(nil);
          end;
          NextNode := dgPanel.GetNextSiblingNoInit(Node);
          if (Node <> NextNode) and Assigned(NextNode) then
            dgPanel.FocusedNode := NextNode
          else
            dgPanel.InvalidateNode(Node);
        end;
        Key := 0;
      end;

    VK_LEFT:
      if (Shift = []) then
      begin
        if gLynxLike then
          ChangePathToParent(True)
        else
          dgPanel.OffsetX := dgPanel.OffsetX + 20;
        Key := 0;
      end;

    VK_RIGHT:
      if (Shift = []) then
      begin
        if gLynxLike then
          ChooseFile(GetActiveDisplayFile, True)
        else
          dgPanel.OffsetX := dgPanel.OffsetX - 20;
        Key := 0;
      end;

    VK_UP, VK_DOWN:
      begin
        if ssShift in Shift then
        begin
          Node := dgPanel.FocusedNode;
          aFile := dgPanel.GetNodeFile(Node);
          if IsItemValid(aFile) then
          begin
            InvertFileSelection(aFile, False);
            DoSelectionChanged(nil);
            if (Node = dgPanel.GetFirstNoInit) or
               (Node = dgPanel.GetLastNoInit) then
            begin
              dgPanel.InvalidateNode(Node);
            end;
            //Key := 0; // not needed!
          end;
        end
{$IFDEF LCLGTK2}
        else
        begin
          if ((dgPanel.Row = dgPanel.RowCount-1) and (Key = VK_DOWN))
          or ((dgPanel.Row = dgPanel.FixedRows) and (Key = VK_UP)) then
            Key := 0;
        end;
{$ENDIF}
      end;

    VK_SPACE:
      if Shift * KeyModifiersShortcut = [] then
      begin
        Node := dgPanel.FocusedNode;
        if Assigned(Node) then
        begin
          aFile := dgPanel.GetNodeFile(Node);
          if IsItemValid(aFile) then
          begin
            if (aFile.FSFile.IsDirectory or
               aFile.FSFile.IsLinkToDirectory) and
               not aFile.Selected then
            begin
              CalculateSpace(aFile);
            end;

            InvertFileSelection(aFile, False);
            DoSelectionChanged(nil);
          end;

          if gSpaceMovesDown then
          begin
            NextNode := dgPanel.GetNextSiblingNoInit(Node);
            if (Node <> NextNode) and Assigned(NextNode) then
              dgPanel.FocusedNode := NextNode
            else
              dgPanel.InvalidateNode(Node);
          end
          else
            dgPanel.InvalidateNode(Node);
          Key := 0;
        end;
      end;

    VK_MENU:  // Alt key
      if dgPanel.Dragging then
      begin
        // Force transform to external dragging in anticipation of user
        // pressing Alt+Tab to change active application window.

        // Disable flag, so that dragging isn't immediately transformed
        // back to internal before the other application window is shown.
        uDragDropEx.AllowTransformToInternal := False;

        GetCursorPos(ScreenPoint);
        dgPanel.TransformDraggingToExternal(ScreenPoint);
      end;
  end;

  DoHandleKeyDown(Key, Shift);
end;

procedure TColumnsFileViewVTV.ColumnsMenuClick(Sender: TObject);
var
  frmColumnsSetConf: TfColumnsSetConf;
  Index: Integer;
  Msg: TEachViewCallbackMsg;
begin
  Case (Sender as TMenuItem).Tag of
    1000: //This
          begin
            frmColumnsSetConf := TfColumnsSetConf.Create(nil);
            try
              Msg.Reason := evcrUpdateColumns;
              Msg.UpdatedColumnsSetName := ActiveColm;
              {EDIT Set}
              frmColumnsSetConf.edtNameofColumnsSet.Text:=ColSet.GetColumnSet(ActiveColm).CurrentColumnsSetName;
              Index:=ColSet.Items.IndexOf(ActiveColm);
              frmColumnsSetConf.lbNrOfColumnsSet.Caption:=IntToStr(1 + Index);
              frmColumnsSetConf.Tag:=Index;
              frmColumnsSetConf.SetColumnsClass(GetColumnsClass);
              {EDIT Set}
              if frmColumnsSetConf.ShowModal = mrOK then
              begin
                // Force saving changes to config file.
                SaveGlobs;
                Msg.NewColumnsSetName := frmColumnsSetConf.GetColumnsClass.Name;
                frmMain.ForEachView(@EachViewUpdateColumns, @Msg);
              end;
            finally
              FreeAndNil(frmColumnsSetConf);
            end;
          end;
    1001: //All columns
          begin
            ShowOptions(TfrmOptionsCustomColumns);
          end;
  else
    begin
      ActiveColm:=ColSet.Items[(Sender as TMenuItem).Tag];
      UpdateColumnsView;
      RedrawFiles;
    end;
  end;
end;

constructor TColumnsFileViewVTV.Create(AOwner: TWinControl; AFileSource: IFileSource; APath: String; AFlags: TFileViewFlags = []);
begin
  FColumnsSorting := TColumnsSortings.Create;
  ActiveColm := 'Default';
  inherited Create(AOwner, AFileSource, APath, AFlags);
end;

constructor TColumnsFileViewVTV.Create(AOwner: TWinControl; AFileView: TFileView; AFlags: TFileViewFlags = []);
begin
  inherited Create(AOwner, AFileView, AFlags);
end;

constructor TColumnsFileViewVTV.Create(AOwner: TWinControl; AConfig: TIniFileEx; ASectionName: String; ATabIndex: Integer; AFlags: TFileViewFlags = []);
begin
  FColumnsSorting := TColumnsSortings.Create;
  inherited Create(AOwner, AConfig, ASectionName, ATabIndex, AFlags);
end;

constructor TColumnsFileViewVTV.Create(AOwner: TWinControl; AConfig: TXmlConfig; ANode: TXmlNode; AFlags: TFileViewFlags = []);
begin
  FColumnsSorting := TColumnsSortings.Create;
  inherited Create(AOwner, AConfig, ANode, AFlags);
end;

procedure TColumnsFileViewVTV.CreateDefault(AOwner: TWinControl);
begin
  DCDebug('TColumnsFileViewVTV.Create components');

  BorderStyle := bsNone; // Before Create or the window handle may be recreated
  inherited CreateDefault(AOwner);
  Align := alClient;

  FFileNameColumn := -1;
  FExtensionColumn := -1;

  // -- other components

  dgPanel:=TColumnsDrawTree.Create(Self, Self);

  HotMan.Register(dgPanel, 'Files Panel');

  edtRename:=TEdit.Create(dgPanel);
  edtRename.Parent:=dgPanel;
  edtRename.Visible:=False;
  edtRename.TabStop:=False;
  edtRename.AutoSize:=False;

  tmContextMenu:= TTimer.Create(Self);
  tmContextMenu.Enabled:= False;
  tmContextMenu.Interval:= 500;
  tmContextMenu.OnTimer:= @tmContextMenuTimer;

  tmClearGrid := TTimer.Create(Self);
  tmClearGrid.Enabled := False;
  tmClearGrid.Interval := 500;
  tmClearGrid.OnTimer := @tmClearGridTimer;

  // ---
  dgPanel.OnUTF8KeyPress := @UTF8KeyPressEvent;
  dgPanel.OnMouseLeave:= @dgPanelMouseLeave;
  dgPanel.OnMouseDown := @dgPanelMouseDown;
  dgPanel.OnStartDrag := @dgPanelStartDrag;
  dgPanel.OnMouseMove:= @dgPanelMouseMove;
  dgPanel.OnDragOver := @dgPanelDragOver;
  dgPanel.OnDragDrop:= @dgPanelDragDrop;
  dgPanel.OnEndDrag:= @dgPanelEndDrag;
  dgPanel.OnAdvancedHeaderDraw:=@dgPanelAdvancedHeaderDraw;
  dgPanel.OnAfterItemPaint := @dgPanelAfterItemPaint;
  dgPanel.OnBeforeItemErase := @dgPanelBeforeItemErase;
  dgPanel.OnDblClick:=@dgPanelDblClick;
  dgPanel.OnEnter:=@dgPanelEnter;
  dgPanel.OnExit:=@dgPanelExit;
  dgPanel.OnFocusChanged:=@dgPanelFocusChanged;
  dgPanel.OnFocusChanging:=@dgPanelFocusChanging;
  dgPanel.OnHeaderDrawQueryElements:=@dgPanelHeaderDrawQueryElements;
  dgPanel.OnKeyUp:=@dgPanelKeyUp;
  dgPanel.OnKeyDown:=@dgPanelKeyDown;
  dgPanel.OnHeaderClick:=@dgPanelHeaderClick;
  dgPanel.OnMouseWheelUp := @dgPanelMouseWheelUp;
  dgPanel.OnMouseWheelDown := @dgPanelMouseWheelDown;
  dgPanel.OnShowHint:= @dgPanelShowHint;
  dgPanel.OnScroll:= @dgPanelScroll;
  dgpanel.OnResize:= @dgPanelResize;

  edtRename.OnKeyDown := @edtRenameKeyDown;
  edtRename.OnExit := @edtRenameExit;

  pmColumnsMenu := TPopupMenu.Create(Self);
  pmColumnsMenu.Parent := Self;
end;

destructor TColumnsFileViewVTV.Destroy;
begin
  if Assigned(HotMan) then
    HotMan.UnRegister(dgPanel);
  inherited Destroy;
  FColumnsSorting.Free;
end;

function TColumnsFileViewVTV.Clone(NewParent: TWinControl): TColumnsFileViewVTV;
begin
  Result := TColumnsFileViewVTV.Create(NewParent, Self);
end;

procedure TColumnsFileViewVTV.CloneTo(FileView: TFileView);
begin
  if Assigned(FileView) then
  begin
    inherited CloneTo(FileView);

    with FileView as TColumnsFileViewVTV do
    begin
      FColumnsSorting := Self.FColumnsSorting.Clone;

      ActiveColm := Self.ActiveColm;
      ActiveColmSlave := nil;    // set to nil because only used in preview?
      isSlave := Self.isSlave;
    end;
  end;
end;

procedure TColumnsFileViewVTV.AddFileSource(aFileSource: IFileSource; aPath: String);
begin
  inherited AddFileSource(aFileSource, aPath);
end;

procedure TColumnsFileViewVTV.BeforeMakeFileList;
begin
  inherited;

  if gListFilesInThread then
  begin
    // Display info that file list is being loaded.
    UpdateInfoPanel;

    // If we cleared grid here there would be flickering if list operation is quickly completed.
    // So, only clear the grid after the file list has been loading for some time.
    tmClearGrid.Enabled := True;
  end;
end;

procedure TColumnsFileViewVTV.AfterMakeFileList;
begin
  inherited;

  tmClearGrid.Enabled := False;
  DisplayFileListHasChanged;
  EnsureDisplayProperties; // After displaying.
end;

procedure TColumnsFileViewVTV.DisplayFileListHasChanged;
var
  AFocused: Boolean = False;
  Node: PVirtualNode;
begin
  // Update grid row count.
  SetRowCount(FFiles.Count);
  SetFilesDisplayItems;
  RedrawFiles;

  if SetActiveFileNow(RequestedActiveFile) then
    RequestedActiveFile := ''
  else
    // Requested file was not found, restore position to last active file.
    if not SetActiveFileNow(LastActiveFile) then
    begin
      if FLastActiveFileIndex >= dgPanel.RootNodeCount then
      begin
        FUpdatingActiveFile := True;
        dgPanel.FocusedNode := dgPanel.GetLastNoInit;
        FUpdatingActiveFile := False;
        SetLastActiveFile(FLastActiveFileIndex);
        AFocused := True;
      end
      else if FLastActiveFileIndex >= 0 then
      begin
        Node := dgPanel.GetFirstNoInit;
        while Assigned(Node) do
        begin
          if Node^.Index = FLastActiveFileIndex then
          begin
            FUpdatingActiveFile := True;
            dgPanel.FocusedNode := Node;
            FUpdatingActiveFile := False;
            SetLastActiveFile(Node^.Index);
            AFocused := True;
            Break;
          end;
          Node := Node^.NextSibling;
        end;
      end;
      if not AFocused then
        dgPanel.FocusedNode := dgPanel.GetFirstNoInit;
      // At creation the control has default size (100, 200).
      // If the first column is wider than ClientWidth then VTV scrolls
      // to the right edge of the column. So, we scroll back here.
      // dgPanel.OffsetX := 0;
    end;

  UpdateInfoPanel;
end;

procedure TColumnsFileViewVTV.MakeColumnsStrings(AFile: TDisplayFile);
begin
  MakeColumnsStrings(AFile, GetColumnsClass);
end;

procedure TColumnsFileViewVTV.MakeColumnsStrings(AFile: TDisplayFile; ColumnsClass: TPanelColumnsClass);
var
  ACol: Integer;
begin
  AFile.DisplayStrings.Clear;
  for ACol := 0 to ColumnsClass.Count - 1 do
  begin
    AFile.DisplayStrings.Add(ColumnsClass.GetColumnItemResultString(
      ACol, AFile.FSFile, FileSource));
  end;
end;

procedure TColumnsFileViewVTV.ClearAllColumnsStrings;
var
  i: Integer;
begin
  if Assigned(FAllDisplayFiles) then
  begin
    // Clear display strings in case columns have changed.
    for i := 0 to FAllDisplayFiles.Count - 1 do
      FAllDisplayFiles[i].DisplayStrings.Clear;
  end;
end;

procedure TColumnsFileViewVTV.EachViewUpdateColumns(AFileView: TFileView; UserData: Pointer);
var
  ColumnsView: TColumnsFileViewVTV;
  PMsg: PEachViewCallbackMsg;
begin
  if AFileView is TColumnsFileViewVTV then
  begin
    ColumnsView := TColumnsFileViewVTV(AFileView);
    PMsg := UserData;
    if ColumnsView.ActiveColm = PMsg^.UpdatedColumnsSetName then
    begin
      ColumnsView.ActiveColm := PMsg^.NewColumnsSetName;
      ColumnsView.UpdateColumnsView;
      ColumnsView.RedrawFiles;
    end;
  end;
end;

procedure TColumnsFileViewVTV.WorkerStarting(const Worker: TFileViewWorker);
begin
  inherited;
  dgPanel.Cursor := crHourGlass;
  UpdateInfoPanel;
end;

procedure TColumnsFileViewVTV.WorkerFinished(const Worker: TFileViewWorker);
begin
  inherited;
  dgPanel.Cursor := crDefault;
  UpdateInfoPanel;
end;

procedure TColumnsFileViewVTV.DoUpdateView;
begin
  inherited DoUpdateView;
  UpdateColumnsView;
end;

function TColumnsFileViewVTV.GetActiveFileIndex: PtrInt;
begin
  if Assigned(dgPanel.FocusedNode) then
    Result := dgPanel.FocusedNode^.Index
  else
    Result := InvalidFileIndex;
end;

function TColumnsFileViewVTV.GetColumnsClass: TPanelColumnsClass;
begin
  if isSlave then
    Result := ActiveColmSlave
  else
    Result := ColSet.GetColumnSet(ActiveColm);
end;

procedure TColumnsFileViewVTV.UTF8KeyPressEvent(Sender: TObject; var UTF8Key: TUTF8Char);
begin
  // check if ShiftState is equal to quick search / filter modes
  if quickSearch.CheckSearchOrFilter(UTF8Key) then
    Exit;
end;

procedure TColumnsFileViewVTV.DoDragDropOperation(Operation: TDragDropOperation;
                                               var DropParams: TDropParams);
var
  AFile: TDisplayFile;
  Node: PVirtualNode;
  ClientDropPoint: TPoint;
begin
  try
    with DropParams do
    begin
      if Files.Count > 0 then
      begin
        ClientDropPoint := dgPanel.ScreenToClient(ScreenDropPoint);
        Node := dgPanel.GetNodeAt(ClientDropPoint.X, ClientDropPoint.Y);

        // default to current active directory in the destination panel
        TargetPath := Self.CurrentPath;

        if (DropIntoDirectories = True) and
           Assigned(Node) and
           (dgPanel.MouseOnGrid(ClientDropPoint.X, ClientDropPoint.Y)) then
        begin
          AFile := dgPanel.GetNodeFile(Node);

          // If dropped into a directory modify destination path accordingly.
          if AFile.FSFile.IsDirectory or AFile.FSFile.IsLinkToDirectory then
          begin
            if AFile.FSFile.Name = '..' then
              // remove the last subdirectory in the path
              TargetPath := GetParentDir(TargetPath)
            else
              TargetPath := TargetPath + AFile.FSFile.Name + DirectorySeparator;
          end;
        end;
      end;
    end;

    // Execute the operation.
    frmMain.DoDragDropOperation(Operation, DropParams);

  finally
    FreeAndNil(DropParams);
  end;
end;

procedure TColumnsFileViewVTV.DoFileUpdated(AFile: TDisplayFile; UpdatedProperties: TFilePropertiesTypes);
begin
  MakeColumnsStrings(AFile);
  inherited DoFileUpdated(AFile, UpdatedProperties);
end;

procedure TColumnsFileViewVTV.DoSelectionChanged(Node: PVirtualNode);
begin
  if Assigned(Node) then
    DoSelectionChanged(Node^.Index)
  else
    DoSelectionChanged(-1);
end;

procedure TColumnsFileViewVTV.cm_RenameOnly(const Params: array of string);
var
  aFile: TFile;
begin
  if (fsoSetFileProperty in FileSource.GetOperationsTypes) then
    begin
      aFile:= CloneActiveFile;
      if Assigned(aFile) then
      try
        if aFile.IsNameValid then
          ShowRenameFileEdit(aFile)
        else
          ShowPathEdit;
      finally
        FreeAndNil(aFile);
      end;
    end;
end;

procedure TColumnsFileViewVTV.cm_ContextMenu(const Params: array of string);
var
  Rect: TRect;
  Point: TPoint;
begin
  Rect := dgPanel.GetDisplayRect(dgPanel.FocusedNode, 0, False);
  Point.X := Rect.Left + ((Rect.Right - Rect.Left) div 2);
  Point.Y := Rect.Top + ((Rect.Bottom - Rect.Top) div 2);
  Point := dgPanel.ClientToScreen(Point);
  frmMain.Commands.DoContextMenu(Self, Point.X, Point.Y, False);
end;

{ TColumnsDrawTree }

constructor TColumnsDrawTree.Create(AOwner: TComponent; AParent: TWinControl);
begin
{$IFDEF LCLGTK2}
  FLastDoubleClickTime := Now;
{$ENDIF}

  inherited Create(AOwner);

  Self.Parent := AParent;
  ColumnsView := AParent as TColumnsFileViewVTV;

  DragType := dtVCL;
  HintMode := hmHint;
end;

procedure TColumnsDrawTree.AfterConstruction;
begin
  inherited;

  RootNodeCount := 0;
  NodeDataSize := SizeOf(TColumnsDrawTreeRecord);

  Align := alClient;

  TreeOptions.AutoOptions := [toAutoScroll, toDisableAutoscrollHorizontal];
  TreeOptions.MiscOptions := [toFullRowDrag];
  // TODO: if no mouse action for middle button: include toWheelPanning
  TreeOptions.PaintOptions := [toShowBackground, toShowDropmark,
    toThemeAware, toUseBlendedImages, toGhostedIfUnfocused, toStaticBackground,
    toAlwaysHideSelection, toHideFocusRect];
  TreeOptions.SelectionOptions := [toDisableDrawSelection, toExtendedFocus,
    toFullRowSelect];

  TabStop := False;
  Margin := 0;
  TextMargin := 0;
  Indent := 0;
  AnimationDuration := 0;

  UpdateView;
end;

procedure TColumnsDrawTree.UpdateView;

  function CalculateDefaultRowHeight: Integer;
  var
    OldFont, NewFont: TFont;
    i: Integer;
    MaxFontHeight: Integer = 0;
    CurrentHeight: Integer;
    ColumnsSet: TPanelColumnsClass;
  begin
    // Start with height of the icons.
    if gShowIcons <> sim_none then
      MaxFontHeight := gIconsSize;

    // Get columns settings.
    with (Parent as TColumnsFileViewVTV) do
    begin
      if not isSlave then
        ColumnsSet := ColSet.GetColumnSet(ActiveColm)
      else
        ColumnsSet := ActiveColmSlave;
    end;

    // Assign temporary font.
    OldFont     := Canvas.Font;
    NewFont     := TFont.Create;
    Canvas.Font := NewFont;

    // Search columns settings for the biggest font (in height).
    for i := 0 to ColumnsSet.Count - 1 do
    begin
      Canvas.Font.Name  := ColumnsSet.GetColumnFontName(i);
      Canvas.Font.Style := ColumnsSet.GetColumnFontStyle(i);
      Canvas.Font.Size  := ColumnsSet.GetColumnFontSize(i);

      CurrentHeight := Canvas.GetTextHeight('Wg');
      MaxFontHeight := Max(MaxFontHeight, CurrentHeight);
    end;

    // Restore old font.
    Canvas.Font := OldFont;
    FreeAndNil(NewFont);

    Result := MaxFontHeight;
  end;

  function CalculateTabHeaderHeight: Integer;
  var
    OldFont: TFont;
  begin
    OldFont     := Canvas.Font;
    Canvas.Font := Font;
    Result      := Canvas.TextHeight('Wg');
    Canvas.Font := OldFont;
  end;

var
  TabHeaderHeight: Integer;
  TempRowHeight: Integer;
  Node: PVirtualNode;
begin
  BeginUpdate;

  try
    if gInterfaceFlat then
    begin
      Header.Style := hsPlates;
      BorderStyle := bsNone;
      BorderWidth := 0;
    end
    else
      Header.Style := hsFlatButtons;

    Color := ColumnsView.DimColor(gBackColor);
    ShowHint:= (gShowToolTipMode <> []);
    GridVertLine:= gGridVertLine;
    GridHorzLine:= gGridHorzLine;

    // Calculate row height.
    TempRowHeight := CalculateDefaultRowHeight;
    if TempRowHeight > 0 then
    begin
      DefaultNodeHeight := TempRowHeight;

      // Set each node's height if changed.
      Node := GetFirstNoInit;
      if Assigned(Node) and (NodeHeight[Node] <> TempRowHeight) then
        SetAllRowsHeights(TempRowHeight);
    end;

    // Add additional space at the bottom so that the filelist doesn't jump at the end.
    // It happens when ClientHeight is not an exact multiplication of DefaultNodeHeight.
    BottomSpace := ClientHeight mod DefaultNodeHeight;

    Header.Options := [hoColumnResize, hoDblClickResize, hoDisableAnimatedResize,
      hoOwnerDraw];

    // Set rows of header.
    if gTabHeader then
    begin
      Header.Options := Header.Options + [hoVisible];

      TabHeaderHeight := Max(gIconsSize, CalculateTabHeaderHeight);
      TabHeaderHeight := TabHeaderHeight + 2; // for borders
      if not gInterfaceFlat then
      begin
        TabHeaderHeight := TabHeaderHeight + 2; // additional borders if not flat
      end;
      Header.DefaultHeight := TabHeaderHeight;
    end;

    if gAutoFillColumns then
      Header.Options := Header.Options + [hoAutoResize, hoAutoSpring];

  finally
    EndUpdate;
  end;
end;

procedure TColumnsDrawTree.InitializeWnd;
begin
  inherited;

  // Register as drag&drop source and target.
  DragDropSource := uDragDropEx.CreateDragDropSource(Self);
  if Assigned(DragDropSource) then
    DragDropSource.RegisterEvents(nil, nil, @OnExDragEnd);

  DragDropTarget := uDragDropEx.CreateDragDropTarget(Self);
  if Assigned(DragDropTarget) then
    DragDropTarget.RegisterEvents(@OnExDragEnter,@OnExDragOver,
                                  @OnExDrop,@OnExDragLeave);
end;

procedure TColumnsDrawTree.FinalizeWnd;
begin
  FreeAndNil(DragDropSource);
  FreeAndNil(DragDropTarget);

  inherited;
end;

procedure TColumnsDrawTree.DoPaintNode(var PaintInfo: TVTPaintInfo);
var
  //shared variables
  s:   string;
  iTextTop: Integer;
  AFile: TDisplayFile;
  FileSourceDirectAccess: Boolean;
  ColumnsSet: TPanelColumnsClass;
  IsFocused: Boolean;
  aRect: TRect;
  aCol: TColumnIndex;

  //------------------------------------------------------
  //begin subprocedures
  //------------------------------------------------------

  procedure DrawIconCell;
  //------------------------------------------------------
  var
    Y: Integer;
    IconID: PtrInt;
    oldClipping: Boolean;
  begin
    if (gShowIcons <> sim_none) then
    begin
      IconID := AFile.IconID;
      // Draw default icon if there is no icon for the file.
      if IconID = -1 then
        IconID := PixMapManager.GetDefaultIcon(AFile.FSFile);

      // center icon vertically
      Y:= aRect.Top + (PaintInfo.Node^.NodeHeight - gIconsSize) div 2;

      // Draw icon for a file
      PixMapManager.DrawBitmap(IconID,
                               PaintInfo.Canvas,
                               aRect.Left + 1,
                               Y
                               );

      // Draw overlay icon for a file if needed
      if gIconOverlays then
      begin
        PixMapManager.DrawBitmapOverlay(AFile,
                                        FileSourceDirectAccess,
                                        PaintInfo.Canvas,
                                        aRect.Left + 1,
                                        Y
                                        );
      end;

    end;

    s := AFile.DisplayStrings.Strings[ACol];

    if gCutTextToColWidth then
    begin
      Y:= ((aRect.Right - aRect.Left) - 4 - PaintInfo.Canvas.TextWidth('W'));
      if (gShowIcons <> sim_none) then Y:= Y - gIconsSize;
      if PaintInfo.Canvas.TextWidth(s) - Y > 0 then
      begin
        repeat
          IconID:= UTF8Length(s);
          UTF8Delete(s, IconID, 1);
        until (PaintInfo.Canvas.TextWidth(s) - Y < 1) or (IconID = 0);
        if (IconID > 0) then
        begin
          s:= UTF8Copy(s, 1, IconID - 3);
          if gDirBrackets and (AFile.FSFile.IsDirectory or AFile.FSFile.IsLinkToDirectory) then
            s:= s + '..]'
          else
            s:= s + '...';
        end;
      end;
    end;

    oldClipping := PaintInfo.Canvas.Clipping;
    //PaintInfo.Canvas.Clipping := False;

    if (gShowIcons <> sim_none) then
      PaintInfo.Canvas.TextOut(aRect.Left + gIconsSize + 4, iTextTop, s)
    else
      PaintInfo.Canvas.TextOut(aRect.Left + 2, iTextTop, s);

//    PaintInfo.Canvas.Clipping := oldClipping;
  end; //of DrawIconCell
  //------------------------------------------------------

  procedure DrawOtherCell;
  //------------------------------------------------------
  var
    tw, cw: Integer;
    oldClipping: Boolean;
  begin
    s := AFile.DisplayStrings.Strings[ACol];

    if gCutTextToColWidth then
    begin
      while PaintInfo.Canvas.TextWidth(s) - (aRect.Right - aRect.Left) - 4 > 0 do
        Delete(s, Length(s), 1);
    end;

    oldClipping := PaintInfo.Canvas.Clipping;
    //PaintInfo.Canvas.Clipping := False;

    case ColumnsSet.GetColumnAlign(ACol) of

      taRightJustify:
        begin
          cw := Header.Columns.Items[ACol].Width;
          tw := PaintInfo.Canvas.TextWidth(s);
          PaintInfo.Canvas.TextOut(aRect.Right - tw - 3, iTextTop, s);
        end;

      taLeftJustify:
        begin
          PaintInfo.Canvas.TextOut(aRect.Left + 3, iTextTop, s);
        end;

      taCenter:
        begin
          cw := Header.Columns.Items[ACol].Width;
          tw := PaintInfo.Canvas.TextWidth(s);
          PaintInfo.Canvas.TextOut(aRect.Left + ((cw - tw - 3) div 2), iTextTop, s);
        end;

    end; //of case

//    PaintInfo.Canvas.Clipping := oldClipping;
  end; //of DrawOtherCell
  //------------------------------------------------------

  procedure PrepareColors;
  //------------------------------------------------------
  var
    TextColor: TColor = -1;
    BackgroundColor: TColor;
    IsCursor: Boolean;
  //---------------------
  begin
    PaintInfo.Canvas.Font.Name   := ColumnsSet.GetColumnFontName(ACol);
    PaintInfo.Canvas.Font.Size   := ColumnsSet.GetColumnFontSize(ACol);
    PaintInfo.Canvas.Font.Style  := ColumnsSet.GetColumnFontStyle(ACol);

    IsCursor := IsFocused and ColumnsView.Active and (not gUseFrameCursor);
    // Set up default background color first.
    if IsCursor then
      begin
        BackgroundColor := ColumnsSet.GetColumnCursorColor(ACol);
      end
    else
      begin
        // Alternate rows background color.
        if odd(PaintInfo.Node^.Index) then
          BackgroundColor := ColumnsSet.GetColumnBackground(ACol)
        else
          BackgroundColor := ColumnsSet.GetColumnBackground2(ACol);
      end;

    // Set text color.
    if ColumnsSet.GetColumnOvercolor(ACol) then
      TextColor := gColorExt.GetColorBy(AFile.FSFile);
    if TextColor = -1 then
      TextColor := ColumnsSet.GetColumnTextColor(ACol);

    if AFile.Selected then
    begin
      if gUseInvertedSelection then
        begin
          //------------------------------------------------------
          if IsCursor then
            begin
              TextColor := InvertColor(ColumnsSet.GetColumnCursorText(ACol));
            end
          else
            begin
              BackgroundColor := ColumnsSet.GetColumnMarkColor(ACol);
              TextColor := ColumnsSet.GetColumnBackground(ACol);
            end;
          //------------------------------------------------------
        end
      else
        begin
          TextColor := ColumnsSet.GetColumnMarkColor(ACol);
        end;
    end
    else if IsCursor then
      begin
        TextColor := ColumnsSet.GetColumnCursorText(ACol);
      end;

    BackgroundColor := ColumnsView.DimColor(BackgroundColor);

    if AFile.RecentlyUpdatedPct <> 0 then
    begin
      TextColor := LightColor(TextColor, AFile.RecentlyUpdatedPct);
      BackgroundColor := LightColor(BackgroundColor, AFile.RecentlyUpdatedPct);
    end;

    // Draw background.
    PaintInfo.Canvas.Brush.Color := BackgroundColor;
    PaintInfo.Canvas.FillRect(aRect);
    PaintInfo.Canvas.Font.Color := TextColor;
  end;// of PrepareColors;

  procedure DrawLines;
  begin
    // Draw frame cursor.
    if gUseFrameCursor and IsFocused and ColumnsView.Active then
    begin
      PaintInfo.Canvas.Pen.Color := ColumnsSet.GetColumnCursorColor(ACol);
      PaintInfo.Canvas.Line(aRect.Left, aRect.Top, aRect.Right, aRect.Top);
      PaintInfo.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
    end;

    // Draw drop selection.
    if PaintInfo.Node = DropNode then
    begin
      PaintInfo.Canvas.Pen.Color := ColumnsSet.GetColumnTextColor(ACol);
      PaintInfo.Canvas.Line(aRect.Left, aRect.Top + 1, aRect.Right, aRect.Top + 1);
      PaintInfo.Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
    end;
  end;
  //------------------------------------------------------
  //end of subprocedures
  //------------------------------------------------------

begin
  aRect := PaintInfo.ContentRect;
  aCol := PaintInfo.Column;

  AFile := GetNodeFile(PaintInfo.Node);
  if not Assigned(AFile) then
  begin
    PaintInfo.Canvas.Brush.Color := Self.Color;
    PaintInfo.Canvas.FillRect(aRect);
    Exit;
  end;

  ColumnsSet := ColumnsView.GetColumnsClass;
  FileSourceDirectAccess := fspDirectAccess in ColumnsView.FileSource.Properties;
  if AFile.DisplayStrings.Count = 0 then
    ColumnsView.MakeColumnsStrings(AFile, ColumnsSet);

  IsFocused := PaintInfo.Node = FocusedNode;

  PrepareColors;

  // Paint on next column if it is empty.
  {if (ColumnsSet.GetColumnAlign(ACol) = taLeftJustify) and
     (ACol + 1 < ColumnsSet.ColumnsCount) and
     (AFile.DisplayStrings[ACol + 1] = EmptyStr) then
    aRect.Right := aRect.Right + Header.Columns.Items[ACol + 1].Width;

  // Paint on previous column if it is empty.
  if (ColumnsSet.GetColumnAlign(ACol) = taRightJustify) and
     (ACol - 1 >= 0) and
     (AFile.DisplayStrings[ACol - 1] = EmptyStr) then
    aRect.Left := aRect.Left - Header.Columns.Items[ACol - 1].Width;
  }
  iTextTop := aRect.Top + (PaintInfo.Node^.NodeHeight - PaintInfo.Canvas.TextHeight('Wg')) div 2;

  if PaintInfo.Column = 0 then
    DrawIconCell  // Draw icon in the first column
  else
    DrawOtherCell;

  DrawLines;
end;

function TColumnsDrawTree.GetNodeFile(Node: PVirtualNode): TDisplayFile;
begin
  if InRange(Node^.Index, 0, ColumnsView.FFiles.Count-1) then
    Result := ColumnsView.FFiles[Node^.Index]
  else
    Result := nil;
end;

procedure TColumnsDrawTree.SetAllRowsHeights(ARowHeight: Cardinal);
var
  Node: PVirtualNode;
begin
  BeginUpdate;
  try
    Node := GetFirstNoInit;
    while Assigned(Node) do
    begin
      NodeHeight[Node] := ARowHeight;
      Node := Node^.NextSibling;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TColumnsDrawTree.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Point: TPoint;
  AFile: TDisplayFile;
  ExpectedButton: TShiftStateEnum;
  iCol: Integer;
  Node: PVirtualNode;
  aRect: TRect;
begin
  inherited MouseMove(Shift, X, Y);

  if FMouseDown and Self.Dragging then
  begin
    // If dragging has started then clear MouseDown flag.
    if (Abs(DragStartPoint.X - X) > DragManager.DragThreshold) or
       (Abs(DragStartPoint.Y - Y) > DragManager.DragThreshold) then
    begin
      FMouseDown := False;
    end;
  end;

  // If dragging is currently in effect, the window has mouse capture and
  // we can retrieve the window over which the mouse cursor currently is.
  if Self.Dragging and uDragDropEx.IsExternalDraggingSupported then
  begin
    Point := Self.ClientToScreen(Classes.Point(X, Y));

    // use specifically LCLIntf.WindowFromPoint to avoid confusion with Windows.WindowFromPoint
    if LCLIntf.WindowFromPoint(Point) = 0 then
    begin
      // If result is 0 then the window belongs to another process
      // and we transform intra-process dragging into inter-process dragging.

      TransformDraggingToExternal(Point);
    end;
  end

  else

  // if we are about to start dragging
  if StartDrag then
    begin
      StartDrag := False;

      case LastMouseButton of
        mbLeft   : ExpectedButton := ssLeft;
        mbMiddle : ExpectedButton := ssMiddle;
        mbRight  : ExpectedButton := ssRight;
        else       Exit;
      end;

      // Make sure the same mouse button is still pressed.
      if not (ExpectedButton in Shift) then
      begin
        ClearMouseButtonAfterDrag;
      end
      else if Assigned(DragNode) then
      begin
        AFile := GetNodeFile(DragNode);
        // Check if valid item is being dragged.
        if (Parent as TColumnsFileViewVTV).IsItemValid(AFile) then
        begin
          BeginDrag(False);
        end;
      end;
    end;

  // Show file info tooltip
  if ShowHint then
    begin
      if MouseOnGrid(X, Y) then
        begin
          Node := GetNodeAt(X, Y);
          if (Node <> HintNode) then
            begin
              HintNode:= Node;
              Application.CancelHint;
              Self.Hint:= EmptyStr; // don't show by default
              with (Parent as TColumnsFileViewVTV) do
                if Assigned(HintNode) then
                begin
                  AFile := GetNodeFile(HintNode);
                  if Assigned(AFile) then
                  begin
                    aRect:= GetDisplayRect(HintNode, 0, False);
                    iCol:= aRect.Right - aRect.Left - 8;
                    if gShowIcons <> sim_none then
                      Dec(iCol, gIconsSize);
                    if iCol < Self.Canvas.TextWidth(AFile.FSFile.Name) then // with file name
                        Self.Hint:= AFile.FSFile.Name
                    else if (stm_only_large_name in gShowToolTipMode) then // don't show
                      Exit
                    else if not AFile.FSFile.IsDirectory then // without name
                      Self.Hint:= #32;
                  end
                  else
                    HintNode := nil;
                end;
            end;
        end
      else
        begin
          HintNode:= nil;
          Application.CancelHint;
          Self.Hint:= EmptyStr;
        end;
    end;
end;

procedure TColumnsDrawTree.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
{$IFDEF LCLGTK2}
  // Workaround for two doubleclicks being sent on GTK.
  // MouseUp event is sent just after doubleclick, so if we drop
  // doubleclick events we have to also drop MouseUp events that follow them.
  if TooManyDoubleClicks then Exit;
{$ENDIF}

  StartDrag := False;

  inherited MouseUp(Button, Shift, X, Y);

  // Call handler only if button-up was not lifted to finish drag&drop operation.
  if FMouseDown then
  begin
    (Parent as TColumnsFileViewVTV).dgPanelMouseUp(Self, Button, Shift, X, Y);
    FMouseDown := False;
  end;
end;

procedure TColumnsDrawTree.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
{$IFDEF LCLGTK2}
  // Workaround for two doubleclicks being sent on GTK.
  // MouseDown event is sent just before doubleclick, so if we drop
  // doubleclick events we have to also drop MouseDown events that precede them.
  if TooManyDoubleClicks then Exit;
{$ENDIF}

  FMouseDown := True;

  if MouseOnGrid(X, Y) then
    inherited MouseDown(Button, Shift, X, Y)
  else
    begin
      if Assigned(OnMouseDown) then
        OnMouseDown(Self, Button, Shift, X, Y);
    end;
end;

procedure TColumnsDrawTree.KeyDown(var Key: Word; Shift: TShiftState);
var
  Node, Temp: PVirtualNode;
  Offset: Integer;
begin
  // Override scrolling with PageUp, PageDown because VirtualTreeView scrolls too much.
  case Key of
    VK_PRIOR:
      if Shift = [] then
      begin
        Offset := 0;
        // If there's no focused node then just take the very first one.
        if FocusedNode = nil then
          Node := GetFirstNoInit
        else
        begin
          // Go up as many nodes as comprise together a size of ClientHeight.
          Node := FocusedNode;
          Temp := Node;
          while Assigned(Temp) do
          begin
            Inc(Offset, NodeHeight[Temp]);
            if Offset >= ClientHeight then
              Break;
            Node := Temp;
            Temp := GetPreviousSiblingNoInit(Temp);
          end;
        end;
        FocusedNode := Node;
        Key := 0;
      end;

    VK_NEXT:
      if Shift = [] then
      begin
        Offset := 0;
        // If there's no focused node then just take the very last one.
        if FocusedNode = nil then
          Node := GetLastNoInit
        else
        begin
          // Go down as many nodes as comprise together a size of ClientHeight.
          Node := FocusedNode;
          Temp := Node;
          while Assigned(Temp) do
          begin
            Inc(Offset, NodeHeight[Temp]);
            if Offset >= ClientHeight then
              Break;
            Node := Temp;
            Temp := GetNextSiblingNoInit(Temp);
          end;
        end;
        FocusedNode := Node;
        //if OffsetY mod DefaultNodeHeight <> 0 then
        //  OffsetY := OffsetY - ClientHeight mod DefaultNodeHeight;
        Key := 0;
      end;
  end;

  inherited;
end;

function TColumnsDrawTree.MouseOnGrid(X, Y: LongInt): Boolean;
begin
  Result := Assigned(GetNodeAt(X, Y));
end;

function TColumnsDrawTree.GetHeaderHeight: Integer;
begin
  Result := Header.Height;
end;

procedure TColumnsDrawTree.ChangeDropNode(NewNode: PVirtualNode);
var
  OldDropNode: PVirtualNode;
begin
  if DropNode <> NewNode then
  begin
    OldDropNode := DropNode;

    // Set new index before redrawing.
    DropNode := NewNode;

    if Assigned(OldDropNode) then // invalidate old row if need
      InvalidateNode(OldDropNode);
    if Assigned(NewNode) then
      InvalidateNode(NewNode);
  end;
end;

procedure TColumnsDrawTree.TransformDraggingToExternal(ScreenPoint: TPoint);
begin
  // Set flag temporarily before stopping internal dragging,
  // so that triggered events will know that dragging is transforming.
  TransformDragging := True;

  // Stop internal dragging
  DragManager.DragStop(False);

{$IF DEFINED(LCLGTK) or DEFINED(LCLGTK2)}
  // Under GTK, DragManager does not release it's mouse capture on
  // DragStop(). We must release it here manually or LCL will get confused
  // with who "owns" the capture after the GTK drag&drop finishes.
  ReleaseMouseCapture;
{$ENDIF}

  // Clear flag before starting external dragging.
  TransformDragging := False;

  // Start external dragging.
  // On Windows it does not return until dragging is finished.

  if Assigned(DragNode) then
    ColumnsView.BeginDragExternal(GetNodeFile(DragNode), DragDropSource, LastMouseButton, ScreenPoint);
end;

function TColumnsDrawTree.OnExDragEnter(var DropEffect: TDropEffect; ScreenPoint: TPoint):Boolean;
begin
  Result := True;
end;

function TColumnsDrawTree.OnExDragOver(var DropEffect: TDropEffect; ScreenPoint: TPoint):Boolean;
var
  ClientPoint: TPoint;
  AFile: TDisplayFile = nil;
  TargetPanel: TColumnsFileViewVTV = nil;
  Node: PVirtualNode;
begin
  Result := False;

  ClientPoint := Self.ScreenToClient(ScreenPoint);

  TargetPanel := (Self.Parent as TColumnsFileViewVTV);

  // Allow dropping into empty panel or on the header.
  if TargetPanel.IsEmpty or (ClientPoint.Y < GetHeaderHeight) then
  begin
    ChangeDropNode(nil);
    Result := True;
    Exit;
  end;

  // Get the item over which there is something dragged.
  Node := GetNodeAt(ClientPoint.X, ClientPoint.Y);
  if Assigned(Node) then
    AFile := GetNodeFile(Node);

  if Assigned(AFile) and
     (AFile.FSFile.IsDirectory or AFile.FSFile.IsLinkToDirectory) and
     (MouseOnGrid(ClientPoint.X, ClientPoint.Y)) then
    // It is a directory or link.
    begin
      ChangeDropNode(Node);
      Result := True;
    end
  else
    begin
      ChangeDropNode(nil);
      Result := True;
    end;
end;

function TColumnsDrawTree.OnExDrop(const FileNamesList: TStringList; DropEffect: TDropEffect;
                                   ScreenPoint: TPoint):Boolean;
var
  Files: TFiles;
  DropParams: TDropParams;
  TargetFileView: TFileView;
begin
  if FileNamesList.Count > 0 then
  begin
    Files := TFileSystemFileSource.CreateFilesFromFileList(
        ExtractFilePath(FileNamesList[0]), FileNamesList);
    try
      TargetFileView := Self.Parent as TFileView;

      DropParams := TDropParams.Create(
        Files, DropEffect, ScreenPoint, True,
        nil, TargetFileView, TargetFileView.CurrentPath);

      frmMain.DropFiles(DropParams);
    except
      FreeAndNil(Files);
      raise;
    end;
  end;

  ChangeDropNode(nil);
  Result := True;
end;

function TColumnsDrawTree.OnExDragLeave: Boolean;
begin
  ChangeDropNode(nil);
  Result := True;
end;

function TColumnsDrawTree.OnExDragBegin: Boolean;
begin
  Result := True;
end;

function TColumnsDrawTree.OnExDragEnd: Boolean;
{$IF DEFINED(MSWINDOWS)}
var
  startPoint: TPoint;
  currentPoint: TPoint;
{$ENDIF}
begin
{$IF DEFINED(MSWINDOWS)}
  // On windows dragging can be transformed back into internal.
  // Check if drag was aborted due to mouse moving back into
  // the application window or the user just cancelled it.
  if (DragDropSource.GetLastStatus = DragDropAborted) and
     TransformDragging then
  begin
    // Transform to internal dragging again.

    // Save current mouse position.
    GetCursorPos(currentPoint);

    // Temporarily set cursor position to the point where the drag was started
    // so that DragManager can properly read the control being dragged.
    startPoint := ClientToScreen(Self.DragStartPoint);
    SetCursorPos(startPoint.X,startPoint.Y);

    // Begin internal dragging.
    BeginDrag(True);

    // Move cursor back.
    SetCursorPos(currentPoint.X, currentPoint.Y);

    // Clear flag.
    TransformDragging := False;

    Exit;
  end;
{$ENDIF}

  ClearMouseButtonAfterDrag;

  Result := True;
end;

procedure TColumnsDrawTree.ClearMouseButtonAfterDrag;
begin
  // Clear some control specific flags.
  ControlState := ControlState - [csClicked, csLButtonDown];

  // Reset state. TODO: Check if this is needed on any widgetset.
  TreeStates := TreeStates - [tsLeftButtonDown, tsMiddleButtonDown,
    tsRightButtonDown, tsVCLDragging];
end;

function TColumnsDrawTree.GetGridHorzLine: Boolean;
begin
  Result := toShowHorzGridLines in TreeOptions.PaintOptions;
end;

function TColumnsDrawTree.GetGridVertLine: Boolean;
begin
  Result := toShowVertGridLines in TreeOptions.PaintOptions;
end;

procedure TColumnsDrawTree.SetGridHorzLine(const AValue: Boolean);
begin
  if AValue then
    TreeOptions.PaintOptions := TreeOptions.PaintOptions + [toShowHorzGridLines]
  else
    TreeOptions.PaintOptions := TreeOptions.PaintOptions - [toShowHorzGridLines];
end;

procedure TColumnsDrawTree.SetGridVertLine(const AValue: Boolean);
begin
  if AValue then
    TreeOptions.PaintOptions := TreeOptions.PaintOptions + [toShowVertGridLines]
  else
    TreeOptions.PaintOptions := TreeOptions.PaintOptions - [toShowVertGridLines];
end;

{$IFDEF LCLGTK2}
function TColumnsDrawTree.TooManyDoubleClicks: Boolean;
begin
  Result := ((Now - fLastDoubleClickTime) <= ((1/86400)*(DblClickTime/1000)));
end;
{$ENDIF}

function TColumnsDrawTree.GetVisibleNodes: TNodeRange;
var
  Offset: Integer = 0;
  Node: PVirtualNode;
  CH: Integer;
begin
  if csLoading in ComponentState then
  begin
    Result.First := nil;
    Result.Last  := nil;
  end
  else
  begin
    Result.First := GetNodeAt(0, 0, True, Offset);
    Result.Last := Result.First;
    CH := ClientHeight;

    // Go down as many nodes as comprise together a size of ClientHeight.
    if Assigned(Result.Last) then
    begin
      while True do
      begin
        if Offset >= CH then
          Break;
        Node := GetNextSiblingNoInit(Result.Last);
        if not Assigned(Node) then
          Break;
        Result.Last := Node;
        Inc(Offset, NodeHeight[Node]);
      end;
    end;
  end;
end;

function TColumnsDrawTree.GetVisibleIndexes: TRange;
begin
  if csLoading in ComponentState then
  begin
    Result.First := 0;
    Result.Last  := -1;
  end
  else
  begin
    // This assumes each row has the same height = DefaultNodeHeight.
    Result.First := -OffsetY div DefaultNodeHeight;
    Result.Last  := (-OffsetY + ClientHeight) div DefaultNodeHeight;
    // Account for the fact the BottomSpace might be > 0.
    if Result.Last >= RootNodeCount then
      Result.Last := RootNodeCount - 1;
  end;
end;

// -- TColumnsSortings --------------------------------------------------------

procedure TColumnsSortings.AddSorting(iColumn : Integer; SortDirection : uFileSorting.TSortDirection);
var
  i : Integer;
  pSortingColumn : PColumnsSorting;
begin
  i := Count - 1;
  while i >= 0 do
  begin
    pSortingColumn := PColumnsSorting(Self[i]);
    if pSortingColumn^.Column = iColumn then
    begin
      pSortingColumn^.SortDirection := ReverseSortDirection(pSortingColumn^.SortDirection);
      Exit;
    end;
    dec(i);
  end;

  new(pSortingColumn);
  pSortingColumn^.Column := iColumn;
  pSortingColumn^.SortDirection := SortDirection;
  Add(pSortingColumn);
end;

Destructor TColumnsSortings.Destroy;
begin
  Clear;
  inherited;
end;

function TColumnsSortings.Clone: TColumnsSortings;
var
  i: Integer;
  pSortingColumn : PColumnsSorting;
begin
  Result := TColumnsSortings.Create;

  for i := 0 to Count - 1 do
  begin
    pSortingColumn := PColumnsSorting(Self[i]);
    Result.AddSorting(pSortingColumn^.Column, pSortingColumn^.SortDirection);
  end;
end;

procedure TColumnsSortings.Clear;
var
  i : Integer;
  pSortingColumn : PColumnsSorting;
begin
  i := Count - 1;
  while i >= 0 do
  begin
    pSortingColumn := PColumnsSorting(Self[i]);
    dispose(pSortingColumn);
    dec(i);
  end;

  Inherited Clear;
end;

function TColumnsSortings.GetSortingDirection(iColumn : Integer) : uFileSorting.TSortDirection;
var
  i : Integer;
  pSortingColumn : PColumnsSorting;
begin
  Result := sdNone;

  i := Count - 1;
  while i >= 0 do
  begin
    pSortingColumn := PColumnsSorting(Self[i]);
    if pSortingColumn^.Column = iColumn then
    begin
      Result := pSortingColumn^.SortDirection;
      break;
    end;
    dec(i);
  end;
end;

end.

