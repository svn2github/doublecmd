{
   Double Commander
   -------------------------------------------------------------------------
   Directories synchronization utility (specially for DC)

   Copyright (C) 2013  Anton Panferov (ast.a_s@mail.ru)
   Copyright (C) 2014-2015  Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

}

unit fSyncDirsDlg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Masks, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, Buttons, ComCtrls, Grids, Menus, uFileView, uFileSource,
  uFileSourceCopyOperation, uFile, uFileSourceOperationMessageBoxesUI;

type

  TSyncRecState = (srsUnknown, srsEqual, srsNotEq, srsCopyLeft, srsCopyRight, srsDeleteRight,
    srsDoNothing);

  { TfrmSyncDirsDlg }

  TfrmSyncDirsDlg = class(TForm)
    btnSelDir1: TButton;
    btnSelDir2: TButton;
    btnCompare: TButton;
    btnSynchronize: TButton;
    btnClose: TButton;
    chkAsymmetric: TCheckBox;
    chkSubDirs: TCheckBox;
    chkByContent: TCheckBox;
    chkIgnoreDate: TCheckBox;
    chkOnlySelected: TCheckBox;
    cbExtFilter: TComboBox;
    HeaderDG: TDrawGrid;
    MainDrawGrid: TDrawGrid;
    edPath1: TEdit;
    edPath2: TEdit;
    GroupBox1: TGroupBox;
    ImageList1: TImageList;
    Label1: TLabel;
    LeftPanel1: TPanel;
    LeftPanel2: TPanel;
    MenuItemCompare: TMenuItem;
    MenuItemViewRight: TMenuItem;
    MenuItemViewLeft: TMenuItem;
    pmGridMenu: TPopupMenu;
    sbCopyRight: TSpeedButton;
    sbEqual: TSpeedButton;
    sbNotEqual: TSpeedButton;
    sbCopyLeft: TSpeedButton;
    sbDuplicates: TSpeedButton;
    sbSingles: TSpeedButton;
    StatusBar1: TStatusBar;
    TopPanel: TPanel;
    procedure btnCloseClick(Sender: TObject);
    procedure btnSelDir1Click(Sender: TObject);
    procedure btnCompareClick(Sender: TObject);
    procedure btnSynchronizeClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MainDrawGridDblClick(Sender: TObject);
    procedure MainDrawGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure MainDrawGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HeaderDGHeaderClick(Sender: TObject; IsColumn: Boolean;
      Index: Integer);
    procedure HeaderDGHeaderSizing(sender: TObject; const IsColumn: boolean;
      const aIndex, aSize: Integer);
    procedure FilterSpeedButtonClick(Sender: TObject);
    procedure MenuItemViewClick(Sender: TObject);
  private
    { private declarations }
    FCancel: Boolean;
    FFoundItems: TStringList;
    FVisibleItems: TStringList;
    FSortIndex: Integer;
    FSortDesc: Boolean;
    FNtfsShift: Boolean;
    FFileExists: TSyncRecState;
    FFileSourceL, FFileSourceR: IFileSource;
    FCmpFileSourceL, FCmpFileSourceR: IFileSource;
    FCmpFilePathL, FCmpFilePathR: string;
    FAddressL, FAddressR: string;
    hCols: array [0..6] of record Left, Width: Integer end;
    CheckContentThread: TObject;
    Ftotal, Fequal, Fnoneq, FuniqueL, FuniqueR: Integer;
    FFileSourceOperationMessageBoxesUI: TFileSourceOperationMessageBoxesUI;
    procedure ClearFoundItems;
    procedure Compare;
    procedure FillFoundItemsDG;
    procedure InitVisibleItems;
    procedure RecalcHeaderCols;
    procedure ScanDirs;
    procedure SetSortIndex(AValue: Integer);
    procedure SortFoundItems;
    procedure SortFoundItems(sl: TStringList);
    procedure UpdateStatusBar;
    property SortIndex: Integer read FSortIndex write SetSortIndex;
  public
    { public declarations }
    constructor Create(AOwner: TComponent;
      FileView1, FileView2: TFileView); reintroduce;
    destructor Destroy; override;
  end;

resourcestring
  rsComparingPercent = 'Comparing... %d%% (ESC to cancel)';
  rsLeftToRightCopy = 'Left to Right: Copy %d files, total size: %d bytes';
  rsRightToLeftCopy = 'Right to Left: Copy %d files, total size: %d bytes';
  rsDeleteRight = 'Right: Delete %d file(s)';
  rsFilesFound = 'Files found: %d  (Identical: %d, Different: %d, '
    + 'Unique left: %d, Unique right: %d)';

procedure ShowSyncDirsDlg(FileView1, FileView2: TFileView);

implementation

uses
  fMain, uDebug, fDiffer, fSyncDirsPerformDlg, uGlobs, LCLType, LazUTF8,
  DCClassesUtf8, uFileSystemFileSource, uFileSourceOperationOptions, DCDateTimeUtils,
  uFileSourceOperation, uDCUtils, uFileSourceUtil, uFileSourceOperationTypes,
  uShowForm, uFileSourceDeleteOperation, uOSUtils;

{$R *.lfm}

type

  { TFileSyncRec }

  TFileSyncRec = class
  private
    FRelPath: string;
    FState: TSyncRecState;
    FAction: TSyncRecState;
    FFileR, FFileL: TFile;
    FForm: TfrmSyncDirsDlg;
  public
    constructor Create(AForm: TfrmSyncDirsDlg; RelPath: string);
    destructor Destroy; override;
    procedure UpdateState(ignoreDate: Boolean);
  end;

  { TCheckContentThread }

  TCheckContentThread = class(TThread)
  private
    FOwner: TfrmSyncDirsDlg;
    FDone: Boolean;
    procedure UpdateGrid;
    procedure ReapplyFilter;
    procedure DoOnTerminate(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor Create(Owner: TfrmSyncDirsDlg);
    property Done: Boolean read FDone;
  end;

procedure ShowSyncDirsDlg(FileView1, FileView2: TFileView);
begin
  if not Assigned(FileView1) then
    raise Exception.Create('ShowSyncDirsDlg: FileView1=nil');
  if not Assigned(FileView2) then
    raise Exception.Create('ShowSyncDirsDlg: FileView2=nil');
  with TfrmSyncDirsDlg.Create(Application, FileView1, FileView2) do
    Show;
end;

{ TCheckContentThread }

procedure TCheckContentThread.DoOnTerminate(Sender: TObject);
begin
  FOwner.CheckContentThread := nil;
  FOwner := nil;
end;

procedure TCheckContentThread.UpdateGrid;
begin
  FOwner.MainDrawGrid.Invalidate;
  FOwner.UpdateStatusBar;
end;

procedure TCheckContentThread.ReapplyFilter;
begin
  FOwner.FillFoundItemsDG;
  FOwner.UpdateStatusBar;
end;

procedure TCheckContentThread.Execute;

  function CompareFiles(fn1, fn2: String; len: Int64): Boolean;
  const
    BUFLEN = 1024 * 32;
  var
    fs1, fs2: TFileStreamEx;
    buf1, buf2: array [1..BUFLEN] of Byte;
    i, j: Int64;
  begin
    fs1 := TFileStreamEx.Create(fn1, fmOpenRead or fmShareDenyWrite);
    try
      fs2 := TFileStreamEx.Create(fn2, fmOpenRead or fmShareDenyWrite);
      try
        i := 0;
        repeat
          if len - i <= BUFLEN then
            j := len - i
          else
            j := BUFLEN;
          fs1.Read(buf1, j);
          fs2.Read(buf2, j);
          i := i + j;
          Result := CompareMem(@buf1, @buf2, j);
        until Terminated or not Result or (i >= len);
      finally
        fs2.Free;
      end;
    finally
      fs1.Free;
    end;
  end;

var
  i, j: Integer;
  r: TFileSyncRec;
begin
  with FOwner do
    for i := 0 to FFoundItems.Count - 1 do
      for j := 0 to TStringList(FFoundItems.Objects[i]).Count - 1 do
      begin
        if Terminated then Exit;
          r := TFileSyncRec(TStringList(FFoundItems.Objects[i]).Objects[j]);
        if Assigned(r) and (r.FState = srsUnknown) then
        begin
          try
            if CompareFiles(r.FFileL.FullPath, r.FFileR.FullPath, r.FFileL.Size) then
            begin
              Inc(Fequal);
              r.FState := srsEqual
            end
            else
              r.FState := srsNotEq;
            if r.FAction = srsUnknown then
              r.FAction := r.FState;
            if j mod 20 = 0 then
              Synchronize(@UpdateGrid);
          except
            on e: Exception do
              DCDebug('[SyncDirs::CmpContentThread] ' + e.Message);
          end;
        end;
      end;
  FDone := True;
  Synchronize(@ReapplyFilter);
end;

constructor TCheckContentThread.Create(Owner: TfrmSyncDirsDlg);
begin
  inherited Create(True);
  OnTerminate := @DoOnTerminate;
  FreeOnTerminate := True;
  FOwner := Owner;
  Start;
end;

constructor TFileSyncRec.Create(AForm: TfrmSyncDirsDlg; RelPath: string);
begin
  FForm:= AForm;
  FRelPath := RelPath;
end;

destructor TFileSyncRec.Destroy;
begin
  FreeAndNil(FFileL);
  FreeAndNil(FFileR);
  inherited Destroy;
end;

procedure TFileSyncRec.UpdateState(ignoreDate: Boolean);
var
  FileTimeDiff: Integer;
begin
  FState := srsNotEq;
  if Assigned(FFileR) and not Assigned(FFileL) then
    FState := FForm.FFileExists
  else
  if not Assigned(FFileR) and Assigned(FFileL) then
    FState := srsCopyRight
  else begin
    FileTimeDiff := FileTimeCompare(FFileL.ModificationTime, FFileR.ModificationTime, FForm.FNtfsShift);
    if ((FileTimeDiff = 0) or ignoreDate) and (FFileL.Size = FFileR.Size) then
      FState := srsEqual
    else
    if not ignoreDate then
      if FileTimeDiff > 0 then
        FState := srsCopyRight
      else
      if FileTimeDiff < 0 then
        FState := srsCopyLeft;
  end;
  FAction := FState;
end;

{ TfrmSyncDirsDlg }

procedure TfrmSyncDirsDlg.btnCloseClick(Sender: TObject);
begin
  Close
end;

procedure TfrmSyncDirsDlg.btnSelDir1Click(Sender: TObject);
var w: TEdit;
begin
  w := nil;
  case TComponent(Sender).Tag of
  0: w := edPath1;
  1: w := edPath2;
  end;
  if w = nil then Exit;
  with TSelectDirectoryDialog.Create(Self) do
  try
    InitialDir := w.Text;
    if Execute then
    begin
      w.Text := FileName;
      case TComponent(Sender).Tag of
      0:
        begin
          FFileSourceL := TFileSystemFileSource.GetFileSource;
          FAddressL := '';
        end;
      1:
        begin
          FFileSourceR := TFileSystemFileSource.GetFileSource;
          FAddressR := '';
        end;
      end;
    end;
  finally
    Free
  end;
end;

procedure TfrmSyncDirsDlg.btnCompareClick(Sender: TObject);
begin
  InsertFirstItem(Trim(cbExtFilter.Text), cbExtFilter);
  StatusBar1.Panels[0].Text := Format(rsComparingPercent, [0]);
  if Assigned(CheckContentThread) then
    with TCheckContentThread(CheckContentThread) do
    begin
      Terminate;
      WaitFor;
    end;
  Compare
end;

procedure TfrmSyncDirsDlg.btnSynchronizeClick(Sender: TObject);
var
  OperationType: TFileSourceOperationType;
  FileExistsOption: TFileSourceOperationOptionFileExists;

  function CopyFiles(src, dst: IFileSource; fs: TFiles; Dest: string): Boolean;
  var
    Operation: TFileSourceCopyOperation;
  begin
    if GetCopyOperationType(Src, Dst, OperationType) then
    begin
      Fs.Path:= fs[0].Path;
      // Create destination directory
      Dst.CreateDirectory(Dest);
      // Determine operation type
      case OperationType of
        fsoCopy:
          begin
            // Copy within the same file source.
            Operation := Src.CreateCopyOperation(
                           Fs,
                           Dest) as TFileSourceCopyOperation;
          end;
        fsoCopyOut:
          begin
            // CopyOut to filesystem.
            Operation := Src.CreateCopyOutOperation(
                           Dst,
                           Fs,
                           Dest) as TFileSourceCopyOperation;
          end;
        fsoCopyIn:
          begin
            // CopyIn from filesystem.
            Operation := Dst.CreateCopyInOperation(
                           Src,
                           Fs,
                           Dest) as TFileSourceCopyOperation;
          end;
      end;
      Operation.FileExistsOption := FileExistsOption;
      Operation.AddUserInterface(FFileSourceOperationMessageBoxesUI);
      try
        Operation.Execute;
        Result := Operation.Result = fsorFinished;
        FileExistsOption := Operation.FileExistsOption;
      finally
        Operation.Free;
      end;
    end;
  end;

  function DeleteFiles(FileSource: IFileSource; Files: TFiles): Boolean;
  var
    Operation: TFileSourceDeleteOperation;
  begin
    Operation:= FileSource.CreateDeleteOperation(Files) as TFileSourceDeleteOperation;
    Operation.AddUserInterface(FFileSourceOperationMessageBoxesUI);
    try
      Operation.Execute;
      Result := Operation.Result = fsorFinished;
    finally
      Operation.Free;
    end;
  end;

var
  i,
  DeleteRightCount,
  CopyLeftCount, CopyRightCount: Integer;
  CopyLeftSize, CopyRightSize: Int64;
  fsr: TFileSyncRec;
  DeleteRight,
  CopyLeft, CopyRight: Boolean;
  DeleteRightFiles,
  CopyLeftFiles, CopyRightFiles: TFiles;
  Dest: string;
begin
  DeleteRightCount := 0;
  CopyLeftCount := 0; CopyRightCount := 0;
  CopyLeftSize := 0;  CopyRightSize := 0;
  for i := 0 to FVisibleItems.Count - 1 do
    if Assigned(FVisibleItems.Objects[i]) then
    begin
      fsr := TFileSyncRec(FVisibleItems.Objects[i]);
      case fsr.FAction of
      srsCopyLeft:
        begin
          Inc(CopyLeftCount);
          Inc(CopyLeftSize, fsr.FFileR.Size);
        end;
      srsCopyRight:
        begin
          Inc(CopyRightCount);
          Inc(CopyRightSize, fsr.FFileL.Size);
        end;
      srsDeleteRight:
        begin
          Inc(DeleteRightCount);
        end;
      end;
    end;
  with TfrmSyncDirsPerformDlg.Create(Self) do
  try
    edLeftPath.Text := FCmpFileSourceL.CurrentAddress + FCmpFilePathL;
    edRightPath.Text := FCmpFileSourceR.CurrentAddress + FCmpFilePathR;
    if (CopyLeftCount > 0) and
        GetCopyOperationType(FFileSourceR, FFileSourceL, OperationType) then
    begin
      chkRightToLeft.Enabled := True;
      chkRightToLeft.Checked := True;
      edLeftPath.Enabled := True;
    end;
    if (CopyRightCount > 0) and
        GetCopyOperationType(FFileSourceL, FFileSourceR, OperationType) then
    begin
      chkLeftToRight.Enabled := True;
      chkLeftToRight.Checked := True;
      edRightPath.Enabled := True;
    end;
    chkDeleteRight.Enabled := DeleteRightCount > 0;
    chkDeleteRight.Checked := chkDeleteRight.Enabled;
    chkDeleteRight.Caption := Format(rsDeleteRight, [DeleteRightCount]);
    chkLeftToRight.Caption :=
      Format(rsLeftToRightCopy, [CopyRightCount, CopyRightSize]);
    chkRightToLeft.Caption :=
      Format(rsRightToLeftCopy, [CopyLeftCount, CopyLeftSize]);
    if ShowModal = mrOk then
    begin
      if chkConfirmOverwrites.Checked then
        FileExistsOption := fsoofeNone
      else begin
        FileExistsOption := fsoofeOverwrite;
      end;
      CopyLeft := chkRightToLeft.Checked;
      CopyRight := chkLeftToRight.Checked;
      DeleteRight := chkDeleteRight.Checked;
      i := 0;
      while i < FVisibleItems.Count do
      begin
        CopyLeftFiles := TFiles.Create('');
        CopyRightFiles := TFiles.Create('');
        DeleteRightFiles := TFiles.Create('');
        if FVisibleItems.Objects[i] <> nil then
          repeat
            fsr := TFileSyncRec(FVisibleItems.Objects[i]);
            Dest := fsr.FRelPath;
            case fsr.FAction of
            srsCopyRight:
              if CopyRight then CopyRightFiles.Add(fsr.FFileL.Clone);
            srsCopyLeft:
              if CopyLeft then CopyLeftFiles.Add(fsr.FFileR.Clone);
            srsDeleteRight:
              if DeleteRight then DeleteRightFiles.Add(fsr.FFileR.Clone);
            end;
            i := i + 1;
          until (i = FVisibleItems.Count) or (FVisibleItems.Objects[i] = nil);
        i := i + 1;
        if CopyLeftFiles.Count > 0 then
        begin
          if not CopyFiles(FCmpFileSourceR, FCmpFileSourceL, CopyLeftFiles,
            FCmpFilePathL + Dest) then Break;
        end else CopyLeftFiles.Free;
        if CopyRightFiles.Count > 0 then
        begin
          if not CopyFiles(FCmpFileSourceL, FCmpFileSourceR, CopyRightFiles,
            FCmpFilePathR + Dest) then Break;
        end else CopyRightFiles.Free;
        if DeleteRightFiles.Count > 0 then
        begin
          if not DeleteFiles(FCmpFileSourceR, DeleteRightFiles) then Break;
        end
        else DeleteRightFiles.Free;
      end;
      btnCompare.Click;
    end;
  finally
    Free
  end;
end;

procedure TfrmSyncDirsDlg.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
  { settings }
  gSyncDirsSubdirs              := chkSubDirs.Checked;
  gSyncDirsIgnoreDate           := chkIgnoreDate.Checked;
  gSyncDirsShowFilterCopyRight  := sbCopyRight.Down;
  gSyncDirsShowFilterEqual      := sbEqual.Down;
  gSyncDirsShowFilterNotEqual   := sbNotEqual.Down;
  gSyncDirsShowFilterCopyLeft   := sbCopyLeft.Down;
  gSyncDirsShowFilterDuplicates := sbDuplicates.Down;
  gSyncDirsShowFilterSingles    := sbSingles.Down;
  gSyncDirsFileMask             := cbExtFilter.Text;
  if chkByContent.Enabled then
    gSyncDirsByContent          := chkByContent.Checked;
  glsMaskHistory.Assign(cbExtFilter.Items);
end;

procedure TfrmSyncDirsDlg.FormCreate(Sender: TObject);
begin
  // Initialize property storage
  InitPropStorage(Self);
  { settings }
  chkByContent.Enabled   := FFileSourceL.IsClass(TFileSystemFileSource) and
                            FFileSourceR.IsClass(TFileSystemFileSource);
  chkSubDirs.Checked     := gSyncDirsSubdirs;
  chkByContent.Checked   := gSyncDirsByContent and chkByContent.Enabled;
  chkIgnoreDate.Checked  := gSyncDirsIgnoreDate;
  sbCopyRight.Down       := gSyncDirsShowFilterCopyRight;
  sbEqual.Down           := gSyncDirsShowFilterEqual;
  sbNotEqual.Down        := gSyncDirsShowFilterNotEqual;
  sbCopyLeft.Down        := gSyncDirsShowFilterCopyLeft;
  sbDuplicates.Down      := gSyncDirsShowFilterDuplicates;
  sbSingles.Down         := gSyncDirsShowFilterSingles;
  cbExtFilter.Items.Assign(glsMaskHistory);
  cbExtFilter.Text       := gSyncDirsFileMask;
end;

procedure TfrmSyncDirsDlg.MainDrawGridDblClick(Sender: TObject);
var
  r: Integer;
  sr: TFileSyncRec;
begin
  r := MainDrawGrid.Row;
  if (r < 0) or (r >= FVisibleItems.Count) then Exit;
  sr := TFileSyncRec(FVisibleItems.Objects[r]);
  if not Assigned(sr)
  or not Assigned(sr.FFileR) or not Assigned(sr.FFileL) or (sr.FState = srsEqual)
  then
    Exit;
  ShowDifferByGlob(sr.FFileL.FullPath, sr.FFileR.FullPath);
end;

procedure TfrmSyncDirsDlg.MainDrawGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  r: TFileSyncRec;
  x: Integer;
  s: string;
begin
  if (FVisibleItems = nil) or (aRow >= FVisibleItems.Count) then Exit;
  with MainDrawGrid.Canvas do
  begin
    r := TFileSyncRec(FVisibleItems.Objects[aRow]);
    if r = nil then
    begin
      Brush.Color := clBtnFace;
      FillRect(aRect);
      Font.Bold := True;
      Font.Color := clWindowText;
      TextOut(aRect.Left + 2, aRect.Top + 2, FVisibleItems[aRow]);
    end else begin
      case r.FState of
      srsNotEq:       Font.Color := clRed;
      srsCopyLeft:    Font.Color := clBlue;
      srsCopyRight:   Font.Color := clGreen;
      srsDeleteRight: Font.Color := clBlue;
      else Font.Color := clWindowText;
      end;
      if Assigned(r.FFileL) then
      begin
        TextOut(aRect.Left + 2, aRect.Top + 2, FVisibleItems[aRow]);
        s := IntToStr(r.FFileL.Size);
        x := hCols[1].Left + hCols[1].Width - 2 - TextWidth(s);
        TextOut(x, aRect.Top + 2, s);
        s := DateTimeToStr(r.FFileL.ModificationTime);
        with hCols[2] do
          TextRect(Rect(Left, aRect.Top, Left + Width, aRect.Bottom),
            Left + 2, aRect.Top + 2, s)
      end;
      if Assigned(r.FFileR) then
      begin
        TextOut(hCols[6].Left + 2, aRect.Top + 2, FVisibleItems[aRow]);
        s := IntToStr(r.FFileR.Size);
        x := hCols[5].Left + hCols[5].Width - 2 - TextWidth(s);
        TextOut(x, aRect.Top + 2, s);
        s := DateTimeToStr(r.FFileR.ModificationTime);
        with hCols[4] do
          TextRect(Rect(Left, aRect.Top, Left + Width, aRect.Bottom),
            Left + 2, aRect.Top + 2, s)
      end;
      ImageList1.Draw(MainDrawGrid.Canvas,
        hCols[3].Left + (hCols[3].Width - ImageList1.Width) div 2 - 2,
        (aRect.Top + aRect.Bottom - ImageList1.Height - 1) div 2, Ord(r.FAction));
    end;
  end;
end;

procedure TfrmSyncDirsDlg.MainDrawGridMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  c, r: Integer;
  sr: TFileSyncRec;
  ca: TSyncRecState;
begin
  MainDrawGrid.MouseToCell(X, Y, c, r);
  if (r < 0) or (r >= FVisibleItems.Count)
  or (x - 2 < hCols[3].Left)
  or (x - 2 > hCols[3].Left + hCols[3].Width)
  then
    Exit;
  sr := TFileSyncRec(FVisibleItems.Objects[r]);
  if not Assigned(sr) or (sr.FState = srsEqual) then Exit;
  ca := sr.FAction;
  case ca of
  srsNotEq:
    ca := srsCopyRight;
  srsCopyRight:
    if Assigned(sr.FFileR) then
      ca := srsCopyLeft
    else
      ca := srsDoNothing;
  srsCopyLeft:
    if Assigned(sr.FFileL) then
      ca := srsNotEq
    else
      ca := srsDoNothing;
  srsDeleteRight:
    ca := srsDoNothing;
  srsDoNothing:
    if Assigned(sr.FFileL) then
      ca := srsCopyRight
    else
      ca := FFileExists;
  end;
  sr.FAction := ca;
  MainDrawGrid.InvalidateRow(r);
end;

procedure TfrmSyncDirsDlg.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    if not FCancel then
      FCancel := True
    else
      Close;
  end;
end;

procedure TfrmSyncDirsDlg.HeaderDGHeaderClick(Sender: TObject;
  IsColumn: Boolean; Index: Integer);
begin
  if (Index <> 3) and (Index <= 6) then
    SortIndex := Index;
end;

procedure TfrmSyncDirsDlg.HeaderDGHeaderSizing(sender: TObject;
  const IsColumn: boolean; const aIndex, aSize: Integer);
begin
  RecalcHeaderCols;
  MainDrawGrid.Invalidate;
end;

procedure TfrmSyncDirsDlg.FilterSpeedButtonClick(Sender: TObject);
begin
  FillFoundItemsDG
end;

procedure TfrmSyncDirsDlg.MenuItemViewClick(Sender: TObject);
var
  r: Integer;
  f: TFile = nil;
  sr: TFileSyncRec;
begin
  r := MainDrawGrid.Row;
  if (r < 0) or (r >= FVisibleItems.Count) then Exit;
  sr := TFileSyncRec(FVisibleItems.Objects[r]);
  if Assigned(sr) then
  begin
    if Sender = MenuItemViewLeft then
      f := sr.FFileL
    else if Sender = MenuItemViewRight then begin
      f := sr.FFileR;
    end;
    if Assigned(f) then ShowViewerByGlob(f.FullPath);
  end;
end;

procedure TfrmSyncDirsDlg.SetSortIndex(AValue: Integer);
var
  s: string;
begin
  if AValue = FSortIndex then
  begin
    s := HeaderDG.Columns[AValue].Title.Caption;
    UTF8Delete(s, 1, 1);
    FSortDesc := not FSortDesc;
    if FSortDesc then s := '↑' + s else s := '↓' + s;
    HeaderDG.Columns[AValue].Title.Caption := s;
    SortFoundItems;
    FillFoundItemsDG;
  end else begin
    if FSortIndex >= 0 then
    begin
      s := HeaderDG.Columns[FSortIndex].Title.Caption;
      UTF8Delete(s, 1, 1);
      HeaderDG.Columns[FSortIndex].Title.Caption := s;
    end;
    FSortIndex := AValue;
    FSortDesc := False;
    with HeaderDG.Columns[FSortIndex].Title do
      Caption := '↓' + Caption;
    SortFoundItems;
    FillFoundItemsDG;
  end;
end;

procedure TfrmSyncDirsDlg.ClearFoundItems;
var
  i, j: Integer;
begin
  for i := 0 to FFoundItems.Count - 1 do
    with TStringList(FFoundItems.Objects[i]) do
    begin
      for j := 0 to Count - 1 do
        Objects[j].Free;
      Clear;
    end;
  FFoundItems.Clear;
end;

procedure TfrmSyncDirsDlg.Compare;
begin
  TopPanel.Enabled := False;
  try
    ClearFoundItems;
    MainDrawGrid.RowCount := 0;
    ScanDirs;
    FillFoundItemsDG;
  finally
    TopPanel.Enabled := True;
  end;
end;

procedure TfrmSyncDirsDlg.FillFoundItemsDG;

  procedure CalcStat;
  var
    i: Integer;
    r: TFileSyncRec;
  begin
    Ftotal := 0;
    Fequal := 0;
    Fnoneq := 0;
    FuniqueL := 0;
    FuniqueR := 0;
    for i := 0 to FVisibleItems.Count - 1 do
    begin
      r := TFileSyncRec(FVisibleItems.Objects[i]);
      if Assigned(r) then
      begin
        Inc(Ftotal);
        if Assigned(r.FFileL) and not Assigned(r.FFileR) then Inc(FuniqueL) else
        if Assigned(r.FFileR) and not Assigned(r.FFileL) then Inc(FuniqueR);
        if r.FState = srsEqual then Inc(Fequal) else
        if r.FState = srsNotEq then Inc(Fnoneq);
      end;
    end;
  end;

begin
  InitVisibleItems;
  MainDrawGrid.ColCount := 1;
  MainDrawGrid.RowCount := FVisibleItems.Count;
  MainDrawGrid.Invalidate;
  CalcStat;
  UpdateStatusBar;
  if FVisibleItems.Count > 0 then
  begin
    btnCompare.Default := False;
    btnSynchronize.Enabled := True;
    btnSynchronize.Default := True;
  end else begin
    btnCompare.Default := True;
    btnSynchronize.Enabled := False;
    btnSynchronize.Default := False;
  end;
end;

procedure TfrmSyncDirsDlg.InitVisibleItems;
var
  i, j: Integer;
  filter: record
    copyLeft, copyRight, eq, neq: Boolean;
    dup, single: Boolean;
  end;
  r: TFileSyncRec;

begin
  if not Assigned(FVisibleItems) then
    FVisibleItems := TStringList.Create
  else
    FVisibleItems.Clear;
  { init filter }
  with filter do
  begin
    copyLeft := sbCopyLeft.Down;
    copyRight := sbCopyRight.Down;
    eq := sbEqual.Down;
    neq := sbNotEqual.Down;
    dup := sbDuplicates.Down;
    single := sbSingles.Down;
  end;
  for i := 0 to FFoundItems.Count - 1 do
  begin
    if FFoundItems[i] <> '' then
      FVisibleItems.Add(AppendPathDelim(FFoundItems[i]));
    with TStringList(FFoundItems.Objects[i]) do
      for j := 0 to Count - 1 do
      begin
        { check filter }
        r := TFileSyncRec(Objects[j]);
        if ((Assigned(r.FFileL) <> Assigned(r.FFileR)) and filter.single or
           (Assigned(r.FFileL) = Assigned(r.FFileR)) and filter.dup)
           and
           ((r.FState = srsCopyLeft) and filter.copyLeft or
            (r.FState = srsCopyRight) and filter.copyRight or
            (r.FState = srsDeleteRight) and filter.copyLeft or
            (r.FState = srsEqual) and filter.eq or
            (r.FState = srsNotEq) and filter.neq or
            (r.FState = srsUnknown))
        then
          FVisibleItems.AddObject(Strings[j], Objects[j]);
      end;
  end;
  { remove empty dirs after filtering }
  for i := FVisibleItems.Count - 1 downto 0 do
    if (FVisibleItems.Objects[i] = nil)
    and ((i + 1 >= FVisibleItems.Count) or (FVisibleItems.Objects[i + 1] = nil)) then
      FVisibleItems.Delete(i);
end;

procedure TfrmSyncDirsDlg.RecalcHeaderCols;
var
  i, l: Integer;
begin
  l := 0;
  for i := 0 to 6 do
    with hCols[i] do
    begin
      Left := l;
      Width := HeaderDG.Columns[i].Width;
      l := l + Width;
    end;
end;

procedure TfrmSyncDirsDlg.ScanDirs;

var
  BaseDirL, BaseDirR: string;
  MasksStr: string;
  ignoreDate, Subdirs, ByContent: Boolean;

  procedure ScanDir(dir: string);

    procedure ProcessOneSide(it, dirs: TStringList; sideLeft: Boolean);
    var
      fs: TFiles;
      i, j: Integer;
      f: TFile;
      r: TFileSyncRec;
    begin
      if sideLeft then
        fs := FFileSourceL.GetFiles(BaseDirL + dir)
      else
        fs := FFileSourceR.GetFiles(BaseDirR + dir);
      try
        for i := 0 to fs.Count - 1 do
        begin
          f := fs.Items[i];
          if not f.IsDirectory and MatchesMaskList(f.Name, MasksStr) then
          begin
            j := it.IndexOf(f.Name);
            if j < 0 then
              r := TFileSyncRec.Create(Self, dir)
            else
              r := TFileSyncRec(it.Objects[j]);
            if sideLeft then
            begin
              r.FFileL := f.Clone;
              r.UpdateState(ignoreDate);
            end else begin
              r.FFileR := f.Clone;
              r.UpdateState(ignoreDate);
              if ByContent and (r.FState = srsEqual) and (r.FFileR.Size > 0) then
              begin
                r.FAction := srsUnknown;
                r.FState := srsUnknown;
              end;
            end;
            it.AddObject(f.Name, r);
          end else
          if (f.NameNoExt <> '.') and (f.NameNoExt <> '..') then
            dirs.Add(f.Name);
        end;
      finally
        fs.Free;
      end;
    end;

  var
    i, j, tot: Integer;
    it: TStringList;
    dirsLeft, dirsRight: TStringList;
    d: string;
  begin
    i := FFoundItems.IndexOf(dir);
    if i < 0 then
    begin
      it := TStringList.Create;
      it.Sorted := True;
      FFoundItems.AddObject(dir, it);
    end else
      it := TStringList(FFoundItems.Objects[i]);
    if dir <> '' then dir := AppendPathDelim(dir);
    dirsLeft := TStringList.Create;
    dirsLeft.Sorted := True;
    dirsRight := TStringList.Create;
    dirsRight.Sorted := True;
    try
      Application.ProcessMessages;
      if FCancel then Exit;
      ProcessOneSide(it, dirsLeft, True);
      ProcessOneSide(it, dirsRight, False);
      SortFoundItems(it);
      if not Subdirs then Exit;
      tot := dirsLeft.Count + dirsRight.Count;
      for i := 0 to dirsLeft.Count - 1 do
      begin
        if dir = '' then
          StatusBar1.Panels[0].Text :=
            Format(rsComparingPercent, [i * 100 div tot]);
        d := dirsLeft[i];
        ScanDir(dir + d);
        j := dirsRight.IndexOf(d);
        if j >= 0 then
        begin
          dirsRight.Delete(j);
          Dec(tot);
        end
      end;
      for i := 0 to dirsRight.Count - 1 do
      begin
        if dir = '' then
          StatusBar1.Panels[0].Text :=
            Format(rsComparingPercent, [(dirsLeft.Count + i) * 100 div tot]);
        d := dirsRight[i];
        ScanDir(dir + d);
      end;
    finally
      dirsLeft.Free;
      dirsRight.Free;
    end;
  end;

begin
  FCancel := False;
  FCmpFileSourceL := FFileSourceL;
  FCmpFileSourceR := FFileSourceR;
  MasksStr := cbExtFilter.Text;
  BaseDirL := AppendPathDelim(edPath1.Text);
  if (FAddressL <> '') and (Copy(BaseDirL, 1, Length(FAddressL)) = FAddressL) then
    Delete(BaseDirL, 1, Length(FAddressL));
  BaseDirR := AppendPathDelim(edPath2.Text);
  if (FAddressR <> '') and (Copy(BaseDirR, 1, Length(FAddressR)) = FAddressR) then
    Delete(BaseDirR, 1, Length(FAddressR));
  FCmpFilePathL := BaseDirL;
  FCmpFilePathR := BaseDirR;
  ignoreDate := chkIgnoreDate.Checked;
  Subdirs := chkSubDirs.Checked;
  ByContent := chkByContent.Checked;
  if chkAsymmetric.Checked then
    FFileExists:= srsDeleteRight
  else begin
    FFileExists:= srsCopyLeft;
  end;
  ScanDir('');
  if (FFoundItems.Count > 0) and chkByContent.Checked then
    CheckContentThread := TCheckContentThread.Create(Self);
  FCancel := True;
end;

procedure TfrmSyncDirsDlg.SortFoundItems;
var
  i: Integer;
begin
  if FSortIndex < 0 then Exit;
  for i := 0 to FFoundItems.Count - 1 do
    SortFoundItems(TStringList(FFoundItems.Objects[i]));
end;

procedure TfrmSyncDirsDlg.SortFoundItems(sl: TStringList);

  function CompareFn(sl: TStringList; i, j: Integer): Integer;
  var
    r1, r2: TFileSyncRec;
  begin
    r1 := TFileSyncRec(sl.Objects[i]);
    r2 := TFileSyncRec(sl.Objects[j]);
    case FSortIndex of
    0:
      if Assigned(r1.FFileL) <> Assigned(r2.FFileL) then
        Result := Ord(Assigned(r1.FFileL)) - Ord(Assigned(r2.FFileL))
      else
      if Assigned(r1.FFileL) then
        Result := UTF8CompareStr(r1.FFileL.Name, r2.FFileL.Name)
      else
        Result := 0;
    1:
      if (Assigned(r1.FFileL) < Assigned(r2.FFileL))
      or Assigned(r2.FFileL) and (r1.FFileL.Size < r2.FFileL.Size) then
        Result := -1
      else
      if (Assigned(r1.FFileL) > Assigned(r2.FFileL))
      or Assigned(r1.FFileL) and (r1.FFileL.Size > r2.FFileL.Size) then
        Result := 1
      else
        Result := 0;
    2:
      if (Assigned(r1.FFileL) < Assigned(r2.FFileL))
      or Assigned(r2.FFileL)
      and (r1.FFileL.ModificationTime < r2.FFileL.ModificationTime) then
        Result := -1
      else
      if (Assigned(r1.FFileL) > Assigned(r2.FFileL))
      or Assigned(r1.FFileL)
      and (r1.FFileL.ModificationTime > r2.FFileL.ModificationTime) then
        Result := 1
      else
        Result := 0;
    4:
      if (Assigned(r1.FFileR) < Assigned(r2.FFileR))
      or Assigned(r2.FFileR)
      and (r1.FFileR.ModificationTime < r2.FFileR.ModificationTime) then
        Result := -1
      else
      if (Assigned(r1.FFileR) > Assigned(r2.FFileR))
      or Assigned(r1.FFileR)
      and (r1.FFileR.ModificationTime > r2.FFileR.ModificationTime) then
        Result := 1
      else
        Result := 0;
    5:
      if (Assigned(r1.FFileR) < Assigned(r2.FFileR))
      or Assigned(r2.FFileR) and (r1.FFileR.Size < r2.FFileR.Size) then
        Result := -1
      else
      if (Assigned(r1.FFileR) > Assigned(r2.FFileR))
      or Assigned(r1.FFileR) and (r1.FFileR.Size > r2.FFileR.Size) then
        Result := 1
      else
        Result := 0;
    6:
      if Assigned(r1.FFileR) <> Assigned(r2.FFileR) then
        Result := Ord(Assigned(r1.FFileR)) - Ord(Assigned(r2.FFileR))
      else
      if Assigned(r1.FFileR) then
        Result := UTF8CompareStr(r1.FFileR.Name, r2.FFileR.Name)
      else
        Result := 0;
    end;
    if FSortDesc then
      Result := -Result;
  end;

  procedure QuickSort(L, R: Integer; sl: TStringList);
  var
    Pivot, vL, vR: Integer;
  begin
    if R - L <= 1 then begin // a little bit of time saver
      if L < R then
        if CompareFn(sl, L, R) > 0 then
          sl.Exchange(L, R);
      Exit;
    end;

    vL := L;
    vR := R;

    Pivot := L + Random(R - L); // they say random is best

    while vL < vR do begin
      while (vL < Pivot) and (CompareFn(sl, vL, Pivot) <= 0) do
        Inc(vL);

      while (vR > Pivot) and (CompareFn(sl, vR, Pivot) > 0) do
        Dec(vR);

      sl.Exchange(vL, vR);

      if Pivot = vL then // swap pivot if we just hit it from one side
        Pivot := vR
      else if Pivot = vR then
        Pivot := vL;
    end;

    if Pivot - 1 >= L then
      QuickSort(L, Pivot - 1, sl);
    if Pivot + 1 <= R then
      QuickSort(Pivot + 1, R, sl);
  end;

begin
  QuickSort(0, sl.Count - 1, sl);
end;

procedure TfrmSyncDirsDlg.UpdateStatusBar;
var s: string;
begin
  s := Format(rsFilesFound, [Ftotal, Fequal, Fnoneq, FuniqueL, FuniqueR]);
  if Assigned(CheckContentThread)
  and not TCheckContentThread(CheckContentThread).Done then
    s := s + ' ...';
  StatusBar1.Panels[0].Text := s;
end;

constructor TfrmSyncDirsDlg.Create(AOwner: TComponent; FileView1,
  FileView2: TFileView);
begin
  inherited Create(AOwner);
  FFoundItems := TStringList.Create;
  FFoundItems.Sorted := True;
  FFileSourceL := FileView1.FileSource;
  FFileSourceR := FileView2.FileSource;
  FAddressL := FileView1.CurrentAddress;
  FAddressR := FileView2.CurrentAddress;
  with FileView1 do
    edPath1.Text := FAddressL + CurrentPath;
  with FileView2 do
    edPath2.Text := FAddressR + CurrentPath;
  RecalcHeaderCols;
  MainDrawGrid.DoubleBuffered := True;
  MainDrawGrid.Font.Bold := True;
  FSortIndex := -1;
  SortIndex := 0;
  FSortDesc := False;
  MainDrawGrid.RowCount := 0;
  chkAsymmetric.Enabled := fsoDelete in FileView2.FileSource.GetOperationsTypes;
  FFileSourceOperationMessageBoxesUI := TFileSourceOperationMessageBoxesUI.Create;
  if (FFileSourceL.IsClass(TFileSystemFileSource)) and (FFileSourceR.IsClass(TFileSystemFileSource)) then
  begin
    FNtfsShift := gNtfsHourTimeDelay and NtfsHourTimeDelay(FileView1.CurrentPath, FileView2.CurrentPath);
  end;
end;

destructor TfrmSyncDirsDlg.Destroy;
begin
  FFileSourceOperationMessageBoxesUI.Free;
  FVisibleItems.Free;
  ClearFoundItems;
  FFoundItems.Free;
  inherited Destroy;
end;

end.

