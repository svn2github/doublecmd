unit uFileViewNotebook; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls,
  uFileView, uFilePanelSelect;

type

  TTabLockState = (
    tlsNormal,           //<en Default state.
    tlsPathLocked,       //<en Path changes are not allowed.
    tlsPathResets,       //<en Path is reset when activating the tab.
    tlsDirsInNewTab);    //<en Path change opens a new tab.

  TFileViewNotebook = class;

  { TFileViewPage }

  TFileViewPage = class(TCustomPage)
  private
    FLockState: TTabLockState;
    FLockPath: String;          //<en Path on which tab is locked

    {en
       Shows or removes the '*' indicator of a locked tab.
    }
    procedure UpdateTabLockState;
    {en
       Retrieves the file view on this page.
    }
    function GetFileView: TFileView;
    {en
       Frees current file view and assigns a new one.
    }
    procedure SetFileView(aFileView: TFileView);
    {en
       Retrieves notebook on which this page is.
    }
    function GetNotebook: TFileViewNotebook;

    procedure SetLockState(NewLockState: TTabLockState);

  public
    constructor Create(TheOwner: TComponent); override;

    function IsActive: Boolean;
    procedure MakeActive;
    procedure UpdateCaption(NewCaption: String);

    property LockState: TTabLockState read FLockState write SetLockState;
    property LockPath: String read FLockPath write FLockPath;
    property FileView: TFileView read GetFileView write SetFileView;
    property Notebook: TFileViewNotebook read GetNotebook;

  end;

  { TFileViewNotebook }

  TFileViewNotebook = class(TCustomNotebook)
  private
    FNotebookSide: TFilePanelSelect;
    FStartDrag: Boolean;
    FDraggedPageIndex: Integer;
    {$IF DEFINED(LCLGTK2)}
    FLastMouseDownTime: TDateTime;
    {$ENDIF}

    function GetActivePage: TFileViewPage;
    function GetActiveView: TFileView;
    function GetFileViewOnPage(Index: Integer): TFileView;
    function GetPage(Index: Integer): TFileViewPage;

    procedure SetMultilineTabs(aMultiline: Boolean);

    procedure DragOverEvent(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure DragDropEvent(Sender, Source: TObject; X, Y: Integer);

  public
    constructor Create(ParentControl: TWinControl;
                       NotebookSide: TFilePanelSelect); reintroduce;

    function AddPage(aCaption: String = ''): TFileViewPage;
    function InsertPage(Index: Integer; aCaption: String = ''): TFileViewPage;
    procedure RemovePage(Index: Integer);
    procedure RemovePage(var aPage: TFileViewPage);
    procedure RemoveAllPages;
    procedure ActivatePrevTab;
    procedure ActivateNextTab;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;

    property ActivePage: TFileViewPage read GetActivePage;
    property ActiveView: TFileView read GetActiveView;
    property Page[Index: Integer]: TFileViewPage read GetPage;
    property View[Index: Integer]: TFileView read GetFileViewOnPage; default;
    property Side: TFilePanelSelect read FNotebookSide;

  published
    property OnDblClick;
    property OnMouseDown;
    property OnMouseUp;
    property MultilineTabs: Boolean write SetMultilineTabs;
  end;

implementation

uses
  WSExtCtrls,
  uGlobs
  {$IF DEFINED(LCLGTK2)}
  , GTKGlobals // for DblClickTime
  {$ENDIF}
  ;

// -- TFileViewPage -----------------------------------------------------------

constructor TFileViewPage.Create(TheOwner: TComponent);
begin
  FLockState := tlsNormal;
  inherited Create(TheOwner);
end;

function TFileViewPage.IsActive: Boolean;
begin
  Result := (Notebook.PageIndex = PageIndex);
end;

procedure TFileViewPage.MakeActive;
var
  aFileView: TFileView;
begin
  Notebook.PageIndex := PageIndex;

  aFileView := FileView;
  if Assigned(aFileView) then
    aFileView.SetFocus;
end;

procedure TFileViewPage.UpdateCaption(NewCaption: String);
begin
  if NewCaption <> '' then
  begin
    if (tb_text_length_limit in gDirTabOptions) and (Length(NewCaption) > gDirTabLimit) then
      Caption := Copy(NewCaption, 1, gDirTabLimit) + '...'
    else
      Caption := NewCaption;

    UpdateTabLockState;
  end;
end;

procedure TFileViewPage.UpdateTabLockState;
var
  NewCaption: String;
begin
  if Caption[1] = '*' then
    NewCaption := Copy(Caption, 2, Length(Caption) - 1)
  else
    NewCaption := Caption;

  if (FLockState <> tlsNormal) and (tb_show_asterisk_for_locked in gDirTabOptions) then
    Caption := '*' + NewCaption
  else
    Caption := NewCaption;
end;

function TFileViewPage.GetFileView: TFileView;
begin
  if ComponentCount > 0 then
    Result := TFileView(Components[0])
  else
    Result := nil;
end;

procedure TFileViewPage.SetFileView(aFileView: TFileView);
var
  aComponent: TComponent;
begin
  while ComponentCount > 0 do
  begin
    aComponent := Components[0];
    RemoveComponent(aComponent);
    aComponent.Free;
  end;

  if Assigned(aFileView) then
  begin
    InsertComponent(aFileView);
    aFileView.Parent := Self;
  end;
end;

function TFileViewPage.GetNotebook: TFileViewNotebook;
begin
  Result := Parent as TFileViewNotebook;
end;

procedure TFileViewPage.SetLockState(NewLockState: TTabLockState);
begin
  FLockState := NewLockState;
  if NewLockState = tlsPathResets then
    LockPath := FileView.CurrentPath;
  UpdateTabLockState;
end;

// -- TFileViewNotebook -------------------------------------------------------

constructor TFileViewNotebook.Create(ParentControl: TWinControl;
                                     NotebookSide: TFilePanelSelect);
begin
  PageClass := TFileViewPage;
  inherited Create(ParentControl);

  Parent := ParentControl;
  Align := alClient;
  TabStop := False;

  FNotebookSide := NotebookSide;
  FStartDrag := False;

  OnDragOver := @DragOverEvent;
  OnDragDrop := @DragDropEvent;
end;

function TFileViewNotebook.GetActivePage: TFileViewPage;
begin
  if PageIndex <> -1 then
    Result := GetPage(PageIndex)
  else
    Result := nil;
end;

function TFileViewNotebook.GetActiveView: TFileView;
var
  APage: TFileViewPage;
begin
  APage := GetActivePage;
  if Assigned(APage) then
    Result := APage.FileView
  else
    Result := nil;
end;

function TFileViewNotebook.GetFileViewOnPage(Index: Integer): TFileView;
var
  APage: TFileViewPage;
begin
  APage := GetPage(Index);
  Result := APage.FileView;
end;

function TFileViewNotebook.GetPage(Index: Integer): TFileViewPage;
begin
  Result := TFileViewPage(CustomPage(Index));
end;

procedure TFileViewNotebook.SetMultilineTabs(aMultiline: Boolean);
begin
  if (nbcMultiline in GetCapabilities) and
      // If different then current setting
     (aMultiline <> (nboMultiline in Options)) then
  begin
    if aMultiline then
      Options := Options + [nboMultiLine]
    else
      Options := Options - [nboMultiLine];

    // Workaround: nboMultiline property is currently not updated by LCL.
    // Force update and realign all pages.

    TWSCustomNotebookClass(Self.WidgetSetClass).UpdateProperties(Self);

    if ClientRectNeedsInterfaceUpdate then
    begin
      // Change sizes of pages, because multiline tabs may
      // take up different amount of space than single line.
      InvalidateClientRectCache(True);
      ReAlign;
    end;
  end;
end;

function TFileViewNotebook.AddPage(aCaption: String): TFileViewPage;
begin
  Result := InsertPage(PageCount, aCaption);
end;

function TFileViewNotebook.InsertPage(Index: Integer; aCaption: String = ''): TFileViewPage;
begin
  if aCaption = '' then
    aCaption := IntToStr(Index);

  Pages.Insert(Index, aCaption);
  Result := GetPage(Index);

  ShowTabs:= ((PageCount > 1) or (tb_always_visible in gDirTabOptions)) and gDirectoryTabs;
end;

procedure TFileViewNotebook.RemovePage(Index: Integer);
begin
{$IFDEF LCLGTK2}
  // If removing currently active page, switch to another page first.
  // Otherwise there can be no page selected.
  if (PageIndex = Index) and (PageCount > 1) then
  begin
    if Index = PageCount - 1 then
      Page[Index - 1].MakeActive
    else
      Page[Index + 1].MakeActive;
  end;
{$ENDIF}

  Pages.Delete(Index);

  if (nboMultiLine in Options) and
     ClientRectNeedsInterfaceUpdate then
  begin
    // The height of the tabs (nr of lines) has changed.
    // Recalculate size of each page.
    InvalidateClientRectCache(False);
    ReAlign;
  end;

  ShowTabs:= ((PageCount > 1) or (tb_always_visible in gDirTabOptions)) and gDirectoryTabs;

{$IFNDEF LCLGTK2}
  // Force-activate current page.
  if PageIndex <> -1 then
    Page[PageIndex].MakeActive;
{$ENDIF}
end;

procedure TFileViewNotebook.RemovePage(var aPage: TFileViewPage);
begin
  RemovePage(aPage.PageIndex);
  aPage := nil;
end;

procedure TFileViewNotebook.RemoveAllPages;
begin
  Pages.Clear;
end;

procedure TFileViewNotebook.ActivatePrevTab;
begin
  if PageIndex = 0 then
    Page[PageCount - 1].MakeActive
  else
    Page[PageIndex - 1].MakeActive;
end;

procedure TFileViewNotebook.ActivateNextTab;
begin
  if PageIndex = PageCount - 1 then
    Page[0].MakeActive
  else
    Page[PageIndex + 1].MakeActive;
end;

procedure TFileViewNotebook.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if Button = mbLeft then
  begin
    FDraggedPageIndex := TabIndexAtClientPos(Classes.Point(X, Y));
    FStartDrag := (FDraggedPageIndex <> -1);
  end;
  {$IF DEFINED(LCLGTK2)} // emulate double click under GTK2
  if (Button = mbLeft) and Assigned(OnDblClick) and (FDraggedPageIndex < 0) then
    begin
      if ((Now - FLastMouseDownTime) > ((1/86400)*(DblClickTime/1000))) then
        FLastMouseDownTime:= Now
      else
        begin
          OnDblClick(Self);
          FLastMouseDownTime:= 0;
        end;
    end;
  {$ENDIF}
end;

procedure TFileViewNotebook.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  if FStartDrag then
  begin
    FStartDrag := False;
    BeginDrag(False);
  end;
end;

procedure TFileViewNotebook.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;

  FStartDrag := False;
end;

procedure TFileViewNotebook.DragOverEvent(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
var
  TabIndex: Integer;
begin
  if (Source is TFileViewNotebook) and (Sender is TFileViewNotebook) then
  begin
    TabIndex := TabIndexAtClientPos(Classes.Point(X, Y));
    Accept := (TabIndex <> -1) and
              ((Source <> Sender) or (TabIndex <> FDraggedPageIndex));
  end
  else
    Accept := False;
end;

procedure TFileViewNotebook.DragDropEvent(Sender, Source: TObject; X, Y: Integer);
var
  SourceNotebook: TFileViewNotebook;
  TabIndex: Integer;
  NewPage, DraggedPage: TFileViewPage;
begin
  if (Source is TFileViewNotebook) and (Sender is TFileViewNotebook) then
  begin
    TabIndex := TabIndexAtClientPos(Classes.Point(X, Y));
    if TabIndex = -1 then
      Exit;

    if Source = Sender then
    begin
      // Move within the same panel.
      Pages.Move(FDraggedPageIndex, TabIndex);
    end
    else
    begin
      // Move page between panels.
      SourceNotebook := (Source as TFileViewNotebook);
      DraggedPage := SourceNotebook.Page[SourceNotebook.FDraggedPageIndex];

      // Create a clone of the page in the panel.
      NewPage := InsertPage(TabIndex, DraggedPage.Caption);
      DraggedPage.FileView.Clone(NewPage);
      NewPage.MakeActive;

      if (ssShift in GetKeyShiftState) and (SourceNotebook.PageCount > 1) then
      begin
        // Remove page from source panel.
        SourceNotebook.RemovePage(DraggedPage);
      end;
    end;
  end;
end;

end.

