unit uBriefFileView;

{$mode objfpc}{$H+}

interface

uses
  LMessages, Grids, uFileView, uFileSource, Graphics,
  Classes, SysUtils, Controls, ExtCtrls, ComCtrls, contnrs, fgl,
  uFile, uDisplayFile, uFormCommands, uDragDropEx, uXmlConfig,
  uClassesEx, uFileSorting, uFileViewHistory, uFileProperty, uFileViewWorker,
  uFunctionThread, uFileSystemWatcher, fQuickSearch, uTypes, uFileViewHeader;

type

  TBriefFileView = class;

  { TBriefDrawGrid }

  TBriefDrawGrid = class(TDrawGrid)
  private
    BriefView: TBriefFileView;
    procedure CalculateColRowCount(Data: PtrInt);
    function  CellToIndex(ACol, ARow: Integer): Integer;
    procedure IndexToCell(Index: Integer; out ACol, ARow: Integer);
  protected
    procedure UpdateView;
    procedure Resize; override;
    procedure RowHeightsChanged; override;
    procedure ColWidthsChanged;  override;
    function MouseOnGrid(X, Y: LongInt): Boolean;
    function  DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    function  DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift:TShiftState; X,Y:Integer); override;
    procedure KeyDown(var Key : Word; Shift : TShiftState); override;
  public
    constructor Create(AOwner: TComponent; AParent: TWinControl); reintroduce;

    procedure DrawCell(aCol, aRow: Integer; aRect: TRect;
              aState: TGridDrawState); override;
  end;

  { TBriefFileView }

  TBriefFileView = class (TFileView)
    private
      pnlHeader: TFileViewHeader;
      TabHeader: THeaderControl;
      dgPanel: TBriefDrawGrid;

      function GetVisibleFilesIndexes: TRange;
      procedure EnsureDisplayProperties;
      procedure UpdateFile(const UpdatedFile: TDisplayFile;
                           const UserData: Pointer);
      {en
         Redraw cell containing DisplayFile if it is visible.
      }
      procedure RedrawFile(DisplayFile: TDisplayFile);
      procedure MakeColumnsStrings(AFile: TDisplayFile);

      function DimColor(AColor: TColor): TColor;

      procedure dgPanelEnter(Sender: TObject);
      procedure dgPanelExit(Sender: TObject);
      procedure dgPanelDblClick(Sender: TObject);
      procedure dgPanelTopLeftChanged(Sender: TObject);
      procedure TabHeaderSectionClick(HeaderControl: TCustomHeaderControl;
                                      Section: THeaderSection);
   protected
      procedure CreateDefault(AOwner: TWinControl); override;
      procedure BeforeMakeFileList; override;
      procedure AfterMakeFileList; override;
      procedure AfterChangePath; override;
      function GetActiveDisplayFile: TDisplayFile; override;
      procedure Resize; override;
  public
    constructor Create(AOwner: TWinControl; AConfig: TXmlConfig; ANode: TXmlNode); override;
    destructor Destroy; override;

    procedure SaveConfiguration(AConfig: TXmlConfig; ANode: TXmlNode); override;

    procedure UpdateView; override;
    {en
       Handles drag&drop operations onto the file view.
       Does any graphic work and executes operations with dropped files if allowed.
       Handles freeing DropParams.
    }
    procedure DoDragDropOperation(Operation: TDragDropOperation;
                                  var DropParams: TDropParams); override;
  end;

implementation

uses
  LCLIntf, LCLType, Forms,
  LCLProc, uMasks, Clipbrd, uLng, uShowMsg, uGlobs, uPixmapManager, uDebug,
  uDCUtils, uOSUtils, math, fMain, fMaskInputDlg, uSearchTemplate,
  uInfoToolTip, dmCommonData,
  uFileSourceProperty,
  uFileSourceOperationTypes,
  uFileSystemFileSource,
  fColumnsSetConf,
  uKeyboard,
  uFileSourceUtil,
  uFileFunctions
{$IF DEFINED(LCLGTK)}
  , GtkProc  // for ReleaseMouseCapture
  , GTKGlobals  // for DblClickTime
{$ENDIF}
{$IF DEFINED(LCLGTK2)}
  , Gtk2Proc  // for ReleaseMouseCapture
  , GTK2Globals  // for DblClickTime
{$ENDIF}
  ;

{ TBriefDrawGrid }

procedure TBriefDrawGrid.CalculateColRowCount(Data: PtrInt);
var
  glw, bw: Integer;
begin
  if (csDesigning in ComponentState) then Exit;

  if not Assigned(BriefView.FFiles) then Exit;

  glw := Max(GridLineWidth, 1);
  bw  := Max(BorderWidth, 1);

  if DefaultRowHeight > 0 then
  begin
    RowCount := (Height - GetSystemMetrics(SM_CYHSCROLL) -
                 glw - (2 * bw)) div (DefaultRowHeight + glw);
    if RowCount > 0 then
    ColCount := (BriefView.FFiles.Count + RowCount - 1) div RowCount;
  end;
  Invalidate;
end;

function TBriefDrawGrid.CellToIndex(ACol, ARow: Integer): Integer;
begin
  if (ARow < 0) or (ARow >= RowCount) or (ACol <  0) or (ACol >= ColCount) then Exit(-1);
  Result:= ACol * RowCount + ARow;
  if (Result < 0) or (Result >= BriefView.FFiles.Count) then
    Result:= -1;
end;

procedure TBriefDrawGrid.IndexToCell(Index: Integer; out ACol, ARow: integer);
begin
  if (Index < 0) or (Index >= BriefView.FFiles.Count) then
    begin
      ACol:= -1;
      ARow:= -1;
    end
  else
    begin
      ACol:= Index div RowCount;
      ARow:= Index mod RowCount;
    end;
end;

procedure TBriefDrawGrid.UpdateView;

  function CalculateDefaultRowHeight: Integer;
  var
    OldFont, NewFont: TFont;
    MaxFontHeight: Integer = 0;
    CurrentHeight: Integer;
  begin
    // Start with height of the icons.
    if gShowIcons <> sim_none then
      MaxFontHeight := gIconsSize;

    // Assign temporary font.
    OldFont     := Canvas.Font;
    NewFont     := TFont.Create;
    Canvas.Font := NewFont;

    // Search columns settings for the biggest font (in height).
    Canvas.Font.Name  := gFonts[dcfMain].Name;
    Canvas.Font.Style := gFonts[dcfMain].Style;
    Canvas.Font.Size  := gFonts[dcfMain].Size;

    CurrentHeight := Canvas.GetTextHeight('Wg');
    MaxFontHeight := Max(MaxFontHeight, CurrentHeight);

    // Restore old font.
    Canvas.Font := OldFont;
    FreeAndNil(NewFont);

    Result := MaxFontHeight;
  end;

var
  TempRowHeight: Integer;
begin
  Flat := gInterfaceFlat;
  Color := BriefView.DimColor(gBackColor);
  ShowHint:= (gShowToolTipMode <> []);

  // Calculate row height.
  TempRowHeight := CalculateDefaultRowHeight;
  if TempRowHeight > 0 then
    DefaultRowHeight := TempRowHeight;
end;

procedure TBriefDrawGrid.Resize;
begin
  inherited Resize;
  Application.QueueAsyncCall(@CalculateColRowCount, 0);
end;

procedure TBriefDrawGrid.RowHeightsChanged;
begin
  inherited RowHeightsChanged;
  Application.QueueAsyncCall(@CalculateColRowCount, 0);
end;

procedure TBriefDrawGrid.ColWidthsChanged;
begin
  inherited ColWidthsChanged;
  Application.QueueAsyncCall(@CalculateColRowCount, 0);
end;

function TBriefDrawGrid.MouseOnGrid(X, Y: LongInt): Boolean;
var
  bTemp: Boolean;
  iRow, iCol: LongInt;
begin
  bTemp:= AllowOutboundEvents;
  AllowOutboundEvents:= False;
  MouseToCell(X, Y, iCol, iRow);
  AllowOutboundEvents:= bTemp;
  Result:= not (CellToIndex(iCol, iRow) < 0);
end;

function TBriefDrawGrid.DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result:= inherited DoMouseWheelDown(Shift, MousePos);
  Result:= Perform(LM_HSCROLL, SB_PAGERIGHT, 0) = 0;
end;

function TBriefDrawGrid.DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint): Boolean;
begin
  Result:= inherited DoMouseWheelUp(Shift, MousePos);
  Result:= Perform(LM_HSCROLL, SB_PAGELEFT, 0) = 0;
end;

procedure TBriefDrawGrid.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  if MouseOnGrid(X, Y) then
    inherited MouseDown(Button, Shift, X, Y)
  else
    begin
      if Assigned(OnMouseDown) then
        OnMouseDown(Self, Button, Shift, X, Y);
    end;
end;

procedure TBriefDrawGrid.KeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_UP, VK_DOWN:
      begin
        if (CellToIndex(Col, Row) >= BriefView.FFiles.Count - 1) and
           (Key = VK_DOWN) then
          begin
            Key:= 0;
          end
        else if ((Row = RowCount-1) and (Key = VK_DOWN)) then
          begin
            if (Col < ColCount - 1) then
            begin
              Row:= 0;
              Col:= Col + 1;
            end;
            Key:= 0;
          end
        else if (Row = FixedRows) and (Key = VK_UP) then
          begin
            if (Col > 0) then
            begin
              Row:= RowCount - 1;
              Col:= Col - 1;
            end;
            Key:= 0;
          end;
      end;
  end;
  inherited KeyDown(Key, Shift);
end;

constructor TBriefDrawGrid.Create(AOwner: TComponent; AParent: TWinControl);
begin
  BriefView := AParent as TBriefFileView;

  inherited Create(AOwner);

  // Workaround for Lazarus issue 18832.
  // Set Fixed... before setting ...Count.
  FixedRows := 0;
  FixedCols := 0;

  // Override default values to start with no columns and no rows.
  RowCount := 0;
  ColCount := 0;

  DefaultColWidth:= 200;

  Self.Parent := AParent;

  DoubleBuffered := True;
  Align := alClient;
  MouseWheelOption:= mwGrid;
  Options := [goTabs, goThumbTracking, goSmoothScroll];
  TabStop := False;

  UpdateView;
end;

procedure TBriefDrawGrid.DrawCell(aCol, aRow: Integer; aRect: TRect;
  aState: TGridDrawState);
var
  Idx: Integer;
  //shared variables
  s:   string;
  iTextTop: Integer;
  AFile: TDisplayFile;
  FileSourceDirectAccess: Boolean;

  //------------------------------------------------------
  //begin subprocedures
  //------------------------------------------------------

  procedure DrawIconCell;
    //------------------------------------------------------
    var
      Y: Integer;
      IconID: PtrInt;
    begin
      if (gShowIcons <> sim_none) then
      begin
        IconID := AFile.IconID;
        // Draw default icon if there is no icon for the file.
        if IconID = -1 then
          IconID := PixMapManager.GetDefaultIcon(AFile.FSFile);

        // center icon vertically
        Y:= aRect.Top + (RowHeights[ARow] - gIconsSize) div 2;

        // Draw icon for a file
        PixMapManager.DrawBitmap(IconID,
                                 Canvas,
                                 aRect.Left + 1,
                                 Y
                                 );

        // Draw overlay icon for a file if needed
        if gIconOverlays then
        begin
          PixMapManager.DrawBitmapOverlay(AFile,
                                          FileSourceDirectAccess,
                                          Canvas,
                                          aRect.Left + 1,
                                          Y
                                          );
        end;

      end;

      s := AFile.FSFile.Name;

      while Canvas.TextWidth(s) - (aRect.Right - aRect.Left) - 4 > 0 do
        Delete(s, Length(s), 1);

      if (gShowIcons <> sim_none) then
        Canvas.TextOut(aRect.Left + gIconsSize + 4, iTextTop, s)
      else
        Canvas.TextOut(aRect.Left + 2, iTextTop, s);
    end; //of DrawIconCell
    //------------------------------------------------------

  procedure PrepareColors;
  //------------------------------------------------------
  var
    TextColor: TColor = -1;
    BackgroundColor: TColor;
  //---------------------
  begin
    Canvas.Font.Name   := gFonts[dcfMain].Name;
    Canvas.Font.Size   := gFonts[dcfMain].Size;
    Canvas.Font.Style  := gFonts[dcfMain].Style;

    // Set up default background color first.
    if (gdSelected in aState) and BriefView.Active and (not gUseFrameCursor) then
      BackgroundColor := gCursorColor
    else
      begin
        // Alternate rows background color.
        if odd(ARow) then
          BackgroundColor := gBackColor
        else
          BackgroundColor := gBackColor2;
      end;

    // Set text color.
    TextColor := gColorExt.GetColorBy(AFile.FSFile);
    if TextColor = -1 then TextColor := gForeColor;

    if AFile.Selected then
    begin
      if gUseInvertedSelection then
        begin
          //------------------------------------------------------
          if (gdSelected in aState) and BriefView.Active and (not gUseFrameCursor) then
            begin
              Canvas.Font.Color := InvertColor(gCursorText);
            end
          else
            begin
              BackgroundColor := gMarkColor;
              Canvas.Font.Color := TextColor;
            end;
          //------------------------------------------------------
        end
      else
        begin
          Canvas.Font.Color := gMarkColor;
        end;
    end
    else if (gdSelected in aState) and BriefView.Active and (not gUseFrameCursor) then
      begin
        Canvas.Font.Color := gCursorText;
      end
    else
      begin
        Canvas.Font.Color := TextColor;
      end;

    // Draw background.
    Canvas.Brush.Color := BriefView.DimColor(BackgroundColor);
    Canvas.FillRect(aRect);
  end;// of PrepareColors;

  procedure DrawLines;
  begin
    // Draw frame cursor.
    if gUseFrameCursor and (gdSelected in aState) and BriefView.Active then
    begin
      Canvas.Pen.Color := gCursorColor;
      Canvas.Line(aRect.Left, aRect.Top, aRect.Right, aRect.Top);
      Canvas.Line(aRect.Left, aRect.Bottom - 1, aRect.Right, aRect.Bottom - 1);
    end;
  end;
  //------------------------------------------------------
  //end of subprocedures
  //------------------------------------------------------

begin
  Idx:= CellToIndex(aCol, aRow);
  if (Idx >= 0) and (BriefView.FFiles.Count > 0) then
  begin
    AFile:= BriefView.FFiles[Idx];
    FileSourceDirectAccess:= fspDirectAccess in BriefView.FileSource.Properties;

    PrepareColors;

    iTextTop := aRect.Top + (RowHeights[aRow] - Canvas.TextHeight('Wg')) div 2;

    DrawIconCell;
  end;

  DrawCellGrid(aCol,aRow,aRect,aState);
  DrawLines;
end;

{ TBriefFileView }

function TBriefFileView.GetVisibleFilesIndexes: TRange; {Done}
begin
  with dgPanel do
  begin
    Result.First:= (LeftCol * VisibleRowCount - 1);
    Result.Last:=  (LeftCol + VisibleColCount) * VisibleRowCount - 1;
  end;

  if Result.First < 0 then
    Result.First:= 0;
  if Result.Last >= FFiles.Count then
    Result.Last:= FFiles.Count - 1;
end;

procedure TBriefFileView.EnsureDisplayProperties;
var
  VisibleFiles: TRange;
  i: Integer;
  AFileList: TFVWorkerFileList;
  Worker: TFileViewWorker;
  AFile: TDisplayFile;
begin
  if (csDestroying in ComponentState) or
     (not Assigned(FFiles)) or
     (GetCurrentWorkType = fvwtCreate) then
    Exit;

  VisibleFiles := GetVisibleFilesIndexes;

  if not gListFilesInThread then
  begin
    for i := VisibleFiles.First to VisibleFiles.Last do
    begin
      AFile := FFiles[i];
      if AFile.FSFile.Name <> '..' then
      begin
        if AFile.IconID = -1 then
          AFile.IconID := PixMapManager.GetIconByFile(AFile.FSFile, fspDirectAccess in FileSource.Properties, True);
        {$IF DEFINED(MSWINDOWS)}
        if gIconOverlays and (AFile.IconOverlayID < 0) then
        begin
          AFile.IconOverlayID := PixMapManager.GetIconOverlayByFile(AFile.FSFile,
                                                                    fspDirectAccess in FileSource.Properties);
        end;
        {$ENDIF}
        FileSource.RetrieveProperties(AFile.FSFile, FilePropertiesNeeded);
        MakeColumnsStrings(AFile);
      end;
    end;
  end
  else
  begin
    AFileList := TFVWorkerFileList.Create;
    try
      for i := VisibleFiles.First to VisibleFiles.Last do
      begin
        AFile := FFiles[i];
        if (AFile.FSFile.Name <> '..') and
           (FileSource.CanRetrieveProperties(AFile.FSFile, FilePropertiesNeeded) or
           (AFile.IconID = -1) or (AFile.IconOverlayID = -1)) then
        begin
          AFileList.AddClone(AFile, AFile);
        end;
      end;

      if AFileList.Count > 0 then
      begin
        Worker := TFilePropertiesRetriever.Create(
          FileSource,
          WorkersThread,
          FilePropertiesNeeded,
          @UpdateFile,
          AFileList);

        AddWorker(Worker, False);
        WorkersThread.QueueFunction(@Worker.StartParam);
      end;

    finally
      if Assigned(AFileList) then
        FreeAndNil(AFileList);
    end;
  end;
end;

procedure TBriefFileView.UpdateFile(const UpdatedFile: TDisplayFile;
  const UserData: Pointer);
var
  propType: TFilePropertyType;
  aFile: TFile;
  OrigDisplayFile: TDisplayFile;
begin
  OrigDisplayFile := TDisplayFile(UserData);

  if not IsReferenceValid(OrigDisplayFile) then
    Exit; // File does not exist anymore (reference is invalid).

  aFile := OrigDisplayFile.FSFile;

{$IF (fpc_version>2) or ((fpc_version=2) and (fpc_release>4))}
  // This is a bit faster.
  for propType in UpdatedFile.FSFile.AssignedProperties - aFile.AssignedProperties do
{$ELSE}
  for propType := Low(TFilePropertyType) to High(TFilePropertyType) do
    if (propType in UpdatedFile.FSFile.AssignedProperties) and
       (not (propType in aFile.AssignedProperties)) then
{$ENDIF}
    begin
      aFile.Properties[propType] := UpdatedFile.FSFile.ReleaseProperty(propType);
    end;

  if UpdatedFile.IconID <> -1 then
    OrigDisplayFile.IconID := UpdatedFile.IconID;

  if UpdatedFile.IconOverlayID <> -1 then
    OrigDisplayFile.IconOverlayID := UpdatedFile.IconOverlayID;

  MakeColumnsStrings(OrigDisplayFile);
  RedrawFile(OrigDisplayFile);
end;

procedure TBriefFileView.RedrawFile(DisplayFile: TDisplayFile); {Done}
var
  VisibleFiles: TRange;
  I, ACol, ARow: Integer;
begin
  VisibleFiles:= GetVisibleFilesIndexes;
  for I:= VisibleFiles.First to VisibleFiles.Last do
  begin
    if FFiles[I] = DisplayFile then
    begin
      dgPanel.IndexToCell(I, ACol, ARow);
      dgPanel.InvalidateCell(ACol, ARow);
      Break;
    end;
  end;
end;

procedure TBriefFileView.MakeColumnsStrings(AFile: TDisplayFile);
begin
  AFile.DisplayStrings.Add(FormatFileFunction('GETFILENAME', AFile.FSFile, FileSource));
end;

function TBriefFileView.DimColor(AColor: TColor): TColor;
begin
  if (not Active) and (gInactivePanelBrightness < 100) then
    Result := ModColor(AColor, gInactivePanelBrightness)
  else
    Result := AColor;
end;

procedure TBriefFileView.dgPanelEnter(Sender: TObject);
begin
  SetActive(True);
  pnlHeader.SetActive(True);
end;

procedure TBriefFileView.dgPanelExit(Sender: TObject);
begin
  SetActive(False);
end;

procedure TBriefFileView.dgPanelDblClick(Sender: TObject);
var
  Point : TPoint;
begin
{$IFDEF LCLGTK2}
  // Workaround for two doubleclicks being sent on GTK.
//  if dgPanel.TooManyDoubleClicks then Exit;
{$ENDIF}

//  dgPanel.StartDrag:= False; // don't start drag on double click
  Point:= dgPanel.ScreenToClient(Mouse.CursorPos);

  // If on a file/directory then choose it.
  if (Point.Y >=  0) and
     (Point.Y <   dgPanel.GridHeight) then
  begin
    ChooseFile(GetActiveDisplayFile);
  end;

{$IFDEF LCLGTK2}
//  dgPanel.fLastDoubleClickTime := Now;
{$ENDIF}
end;

procedure TBriefFileView.dgPanelTopLeftChanged(Sender: TObject);
begin
  EnsureDisplayProperties;
end;

procedure TBriefFileView.TabHeaderSectionClick(
  HeaderControl: TCustomHeaderControl; Section: THeaderSection);
begin

end;

procedure TBriefFileView.CreateDefault(AOwner: TWinControl);
begin
  inherited CreateDefault(AOwner);
  dgPanel:= TBriefDrawGrid.Create(Self, Self);

  HotMan.Register(dgPanel, 'Files Panel');

  Align:= alClient;

  TabHeader:= TBriefHeaderControl.Create(Self);
  TabHeader.Parent:= Self;
  TabHeader.Align:= alTop;
  TabHeader.Sections.Add.Text:= rsColName;
  TabHeader.Sections.Add.Text:= rsColExt;
  TabHeader.Sections.Add.Text:= rsColSize;
  TabHeader.Sections.Add.Text:= rsColDate;
  TabHeader.Sections.Add.Text:= rsColAttr;
  TabHeader.OnSectionClick:= @TabHeaderSectionClick;

  pnlHeader:= TFileViewHeader.Create(Self, Self);

  dgPanel.OnTopLeftChanged:= @dgPanelTopLeftChanged;
  dgPanel.OnDblClick:=@dgPanelDblClick;
  dgPanel.OnEnter:=@dgPanelEnter;
  dgPanel.OnExit:=@dgPanelExit;
end;

procedure TBriefFileView.BeforeMakeFileList;
begin
  inherited BeforeMakeFileList;
end;

procedure TBriefFileView.AfterMakeFileList;
begin
  inherited AfterMakeFileList;
  dgPanel.CalculateColRowCount(0);
  EnsureDisplayProperties;
end;

procedure TBriefFileView.AfterChangePath;
begin
  inherited AfterChangePath;

//  FUpdatingGrid := True;
  dgPanel.Row := 0;
//  FUpdatingGrid := False;

  MakeFileSourceFileList;
  pnlHeader.UpdatePathLabel;
end;

function TBriefFileView.GetActiveDisplayFile: TDisplayFile;
var
  Idx: Integer;
begin
  Result:= nil;
  if not IsEmpty then
  begin
    Idx:= dgPanel.CellToIndex(dgPanel.Col, dgPanel.Row);
    if (Idx >= 0) then Result:= FFiles[Idx]
  end;
end;

procedure TBriefFileView.Resize;
var
  I: Integer;
  AWidth: Integer;
begin
  inherited Resize;

  if Assigned(TabHeader) then
  begin
    AWidth:= Width div TabHeader.Sections.Count;
    for I:= 0 to TabHeader.Sections.Count - 1 do
      TabHeader.Sections[I].Width:= AWidth;
  end;
end;

constructor TBriefFileView.Create(AOwner: TWinControl; AConfig: TXmlConfig;
  ANode: TXmlNode);
begin
  inherited Create(AOwner, AConfig, ANode);

  LoadConfiguration(AConfig, ANode);

  if FileSourcesCount > 0 then
  begin
    // Update view before making file source file list,
    // so that file list isn't unnecessarily displayed twice.
    UpdateView;
    MakeFileSourceFileList;
  end;
end;

destructor TBriefFileView.Destroy;
begin
  if Assigned(HotMan) then
    HotMan.UnRegister(dgPanel);

  inherited Destroy;
end;

procedure TBriefFileView.SaveConfiguration(AConfig: TXmlConfig; ANode: TXmlNode);
begin
  inherited SaveConfiguration(AConfig, ANode);

  AConfig.SetAttr(ANode, 'Type', 'brief');
end;

procedure TBriefFileView.UpdateView;
begin
  inherited UpdateView;
  dgPanel.UpdateView;
  MakeFileSourceFileList;
end;

procedure TBriefFileView.DoDragDropOperation(Operation: TDragDropOperation;
  var DropParams: TDropParams);
begin

end;

end.

