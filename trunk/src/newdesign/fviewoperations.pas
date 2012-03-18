unit fViewOperations; 

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  ComCtrls, Buttons, uFileSourceOperation, uOperationsManager;

type

  { TfrmViewOperations }

  TfrmViewOperations = class(TForm)
    Bevel3: TBevel;
    lblAllProgress: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    chkQueue: TCheckBox;
    pnlCurrentOperation: TPanel;
    lblCurrentOperation: TLabel;
    lblQueue: TLabel;
    lblRunning: TLabel;
    lblAll: TLabel;
    lblCount: TLabel;
    lblOperationsCount: TLabel;
    pbrAllProgress: TProgressBar;
    grpAllOperation: TGroupBox;
    Cntr_running: TPanel;
    btnAllPause: TBitBtn;
    btnAllStart: TBitBtn;
    btnCurOpQueueInOut: TBitBtn;
    btnAllInQueue: TBitBtn;
    btnRunAllStart: TBitBtn;
    btnStartQueue: TBitBtn;
    btnUpCurOp: TBitBtn;
    btnDnCurOp: TBitBtn;
    btnStartPauseCurOp: TBitBtn;
    btnCancelCurOp: TBitBtn;
    pnlHeader: TPanel;
    sboxOperations: TScrollBox;
    btnRunAllPause: TBitBtn;
    btnAllCancel: TBitBtn;
    UpdateTimer: TTimer;

    procedure btnAllInQueueClick(Sender: TObject);
    procedure btnAllPauseClick(Sender: TObject);
    procedure btnAllStartClick(Sender: TObject);
    procedure btnCancelCurOpClick(Sender: TObject);
    procedure btnDnCurOpClick(Sender: TObject);
    procedure btnRunAllPauseClick(Sender: TObject);
    procedure btnAllCancelClick(Sender: TObject);
    procedure btnRunAllStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OnUpdateTimer(Sender: TObject);
    procedure sboxOperationsDblClick(Sender: TObject);
    procedure sboxOperationsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure sboxOperationsPaint(Sender: TObject);
    procedure btnCurOpQueueInOutClick(Sender: TObject);
    procedure btnStartPauseCurOpClick(Sender: TObject);
    procedure btnStartQueueClick(Sender: TObject);
    procedure btnUpCurOpClick(Sender: TObject);

  private
    procedure UpdateView(Operation: TFileSourceOperation; Event: TOperationManagerEvent);

  public

  end;

procedure ShowOperationsViewer;

var
  indexFocus: integer;

implementation

{$R *.lfm}

uses
  uFileSourceOperationTypes,
  uLng, fFileOpDlg, uGlobs;

const
  aRowHeight = 50;

var
  frmViewOperations: TfrmViewOperations = nil;

procedure ShowOperationsViewer;
begin
  if not Assigned(frmViewOperations) then
    frmViewOperations := TfrmViewOperations.Create(Application);
  frmViewOperations.ShowOnTop;
end;

{ TfrmViewOperations }

procedure TfrmViewOperations.FormCreate(Sender: TObject);
begin
  InitPropStorage(Self);
  lblCount.Caption := '0';
  indexFocus := 1;
  sboxOperations.AutoScroll := True;
  sboxOperations.VertScrollBar.Visible := True;

  OperationsManager.AddEventsListener([omevOperationAdded, omevOperationRemoved], @UpdateView);

  lblCount.Caption := IntToStr(OperationsManager.OperationsCount);
  sboxOperations.Invalidate;     // force redraw
end;

procedure TfrmViewOperations.btnRunAllPauseClick(Sender: TObject);
begin
  OperationsManager.PauseRunning;
end;

procedure TfrmViewOperations.btnAllPauseClick(Sender: TObject);
begin
  OperationsManager.PauseAll;
end;

procedure TfrmViewOperations.btnAllInQueueClick(Sender: TObject);
var
  OpManItem: TOperationsManagerItem;
  i: integer;
begin
  for i := 0 to OperationsManager.OperationsCount - 1 do
  begin
    OpManItem := OperationsManager.GetItemByIndex(i);
    OperationsManager.InQueue(OpManItem.Handle, True);
  end;
end;

procedure TfrmViewOperations.btnAllStartClick(Sender: TObject);
begin
  OperationsManager.StartAll;
end;

procedure TfrmViewOperations.btnCancelCurOpClick(Sender: TObject);
var
  OpManItem: TOperationsManagerItem;
begin
  OpManItem := OperationsManager.GetItemByIndex(indexFocus);
  if Assigned(OpManItem) then
    OpManItem.Operation.Stop;
end;

procedure TfrmViewOperations.btnDnCurOpClick(Sender: TObject);
begin
  if indexFocus < OperationsManager.OperationsCount-1 then
  begin
 OperationsManager.MoveOperation(indexFocus, indexFocus + 1);
  indexFocus:= indexFocus+1;
  end;
end;

procedure TfrmViewOperations.btnAllCancelClick(Sender: TObject);
begin
  OperationsManager.CancelAll;
end;

procedure TfrmViewOperations.btnRunAllStartClick(Sender: TObject);
begin
  OperationsManager.StartRunning;
end;

procedure TfrmViewOperations.FormDestroy(Sender: TObject);
begin
  OperationsManager.RemoveEventsListener([omevOperationAdded, omevOperationRemoved], @UpdateView);
end;

procedure TfrmViewOperations.OnUpdateTimer(Sender: TObject);
var
  OpManItem: TOperationsManagerItem;
  i: Integer;
begin
  if indexFocus > OperationsManager.OperationsCount-1 then
    indexFocus := OperationsManager.OperationsCount-1;           //���� ����� ���� �� �������, �� ������ ��� ���������

  if OperationsManager.OperationsCount=0 then
    begin
      pnlCurrentOperation.Enabled:=false;
      grpAllOperation.Enabled:=false;
    end
  else
    begin
      pnlCurrentOperation.Enabled:=true;
      grpAllOperation.Enabled:=true;
    end;

  pbrAllProgress.Position:= Round(OperationsManager.AllProgressPoint * pbrAllProgress.Max);

  if pbrAllProgress.Position <> 0 then
    lblAllProgress.Caption:= Format(rsDlgAllOpProgress, [pbrAllProgress.Position])
  else
    lblAllProgress.Caption:= rsDlgAllOpComplete;

  for i := 0 to OperationsManager.OperationsCount - 1 do
  begin
    // Timer is called from main thread, so it is safe
    // to use reference to Operation from OperationsManager.
    OpManItem := OperationsManager.GetItemByIndex(i);
    if Assigned(OpManItem) then
      sboxOperations.Invalidate;     // force redraw
  end;
end;

procedure TfrmViewOperations.sboxOperationsDblClick(Sender: TObject);
var
  OperationNumber: Integer;
  CursorPos: TPoint;
  OperationDialog: TfrmFileOp;
  OpManItem: TOperationsManagerItem;
begin
  CursorPos := Mouse.CursorPos;
  CursorPos := sboxOperations.ScreenToClient(CursorPos);

  OperationNumber := CursorPos.Y div aRowHeight;
  OpManItem := OperationsManager.GetItemByIndex(OperationNumber);
  if Assigned(OpManItem) and (OpManItem.Form = False) then
  begin
    OperationDialog := TfrmFileOp.Create(OpManItem.Handle);
    OperationDialog.Show;
  end;
end;

procedure TfrmViewOperations.sboxOperationsMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  OperationNumber: Integer;
  CursorPos: TPoint;
begin
  CursorPos := Mouse.CursorPos;
  CursorPos := sboxOperations.ScreenToClient(CursorPos);

  OperationNumber := CursorPos.Y div aRowHeight;

  if OperationsManager.OperationsCount > 0 then
  begin
  case Button of
    mbMiddle:
      begin
        if OperationNumber-1>=0 then //��������, ���� �������� ����� ������, �� ������ ��� �� ��������(((
        begin
          if  (OperationNumber = indexFocus) or (OperationNumber-1 = indexFocus) then     // �������� �����, ���� �� ����� �� ������� ��� �����
          begin
            if  OperationNumber=indexFocus then indexFocus:=indexFocus-1 else indexFocus:=indexFocus+1;
          end;
          OperationsManager.MoveOperation(OperationNumber, OperationNumber - 1);
        end;
      end;
    mbRight:
      begin
        if OperationNumber<OperationsManager.OperationsCount then    //���� �������� ���������, �� ������ ��� �� ��������(((
        begin
          if  (OperationNumber = indexFocus) or (OperationNumber+1 = indexFocus) then     // �������� �����, ���� �� ����� �� ������� ��� �����
          begin
            if  OperationNumber=indexFocus then indexFocus:=indexFocus+1 else indexFocus:=indexFocus-1;
          end;
          OperationsManager.MoveOperation(OperationNumber, OperationNumber + 1);
        end;
      end;
    mbLeft:
      begin
        if OperationNumber< OperationsManager.OperationsCount then indexFocus:=OperationNumber;
      end;
  end;
  end;
end;


procedure TfrmViewOperations.sboxOperationsPaint(Sender: TObject);
var
  OpManItem: TOperationsManagerItem;
  i: Integer;
  OutString: String;
begin
  for i := 0 to OperationsManager.OperationsCount - 1 do
  begin
    // Timer is called from main thread, so it is safe
    // to use reference to Operation from OperationsManager.

    OpManItem := OperationsManager.GetItemByIndex(i);
    if Assigned(OpManItem) then
    begin
      case OpManItem.Operation.ID of
        fsoCopy, fsoCopyIn, fsoCopyOut:
          OutString := rsDlgCp;
        fsoMove:
          OutString := rsDlgMv;
        fsoDelete:
          OutString := rsDlgDel;
        fsoWipe:
          OutString := rsDlgWipe;
        fsoCalcChecksum:
          OutString := rsDlgCheckSumCalc;
        else
          OutString := rsDlgUnknownOperation;
      end;

      OutString := IntToStr(OpManItem.Handle) + ': '
                 + OutString + ' - '
                 + FloatToStrF(OpManItem.Operation.Progress * 100, ffFixed, 0, 0) + ' %'
                 + ' (' + FileSourceOperationStateText[OpManItem.Operation.State] + ')';

      sboxOperations.Canvas.Brush.Color := Canvas.Brush.Color;
      sboxOperations.Canvas.Rectangle(0, 0 + (aRowHeight * i), sboxOperations.Width, aRowHeight + (aRowHeight * i));
      sboxOperations.Canvas.TextOut(5, 5 + (aRowHeight * i), OutString);
      sboxOperations.Caption := OutString;

      if i <> indexFocus then
        sboxOperations.Canvas.Brush.Color := clMenu
      else
      begin
        sboxOperations.Canvas.Brush.Color := clHighlight;                    // ��������� ����� ������� ���� �� ��� �����
        lblCurrentOperation.Caption := OutString;                              // ��������� ��� ������� �������� � CurrentOperation panel ������������ ��������

        if OpManItem.Operation.State = fsosRunning then
          btnStartPauseCurOp.Caption:= rsDlgOpPause
        else
          btnStartPauseCurOp.Caption:= rsDlgOpStart;
      end;

      sboxOperations.Canvas.FillRect(
        5,
        5 + (aRowHeight * i) + sboxOperations.Canvas.TextHeight('Pg'),
        Round(5 + (sboxOperations.Width - 10) * OpManItem.Operation.Progress),
        aRowHeight * (i + 1) - 5);
    end;
  end;
end;

procedure TfrmViewOperations.btnCurOpQueueInOutClick(Sender: TObject);
begin
{  if (OperationsManager.GetStartingState(OperationsManager.GetHandleById(indexFocus)) in [ossQueueFirst, ossQueueLast, ossQueueIn])  then
    begin
      OperationsManager.InQueue(OperationsManager.GetHandleById(indexFocus), false);
      btnCurOpQueueInOut.Caption:= rsDlgQueueIn;
    end
  else
    begin
      OperationsManager.InQueue(OperationsManager.GetHandleById(indexFocus), true);
      btnCurOpQueueInOut.Caption:= rsDlgQueueOut;
    end;}
end;

procedure TfrmViewOperations.btnStartPauseCurOpClick(Sender: TObject);
var
  OpManItem: TOperationsManagerItem;
begin
  OpManItem := OperationsManager.GetItemByIndex(indexFocus);
  if Assigned(OpManItem) then
  begin
    if OpManItem.Operation.State = fsosRunning then
      begin
        OpManItem.Operation.Pause;
        btnStartPauseCurOp.Caption := rsDlgOpStart;
        OperationsManager.CheckQueuedOperations;
      end
    else
      begin
        OpManItem.Operation.Start;
        OpManItem.PauseRunning := False;
        btnStartPauseCurOp.Caption:= rsDlgOpPause;
      end;
  end;
end;

procedure TfrmViewOperations.btnStartQueueClick(Sender: TObject);
begin
  OperationsManager.CheckQueuedOperations;
end;

procedure TfrmViewOperations.btnUpCurOpClick(Sender: TObject);
begin
  if indexFocus>0 then
  begin
   OperationsManager.MoveOperation(indexFocus, indexFocus - 1);
   indexFocus:= indexFocus - 1;
  end;
end;


procedure TfrmViewOperations.UpdateView(Operation: TFileSourceOperation;
                                        Event: TOperationManagerEvent);
begin
  if OperationsManager.OperationsCount = 0 then
  begin
    indexFocus:= -1;                                 //����� ������� �
    lblCurrentOperation.Caption:= rsDlgOpCaption; // ���������, ���� ��� �������� � ����
  end;
  lblCount.Caption := IntToStr(OperationsManager.OperationsCount);
  sboxOperations.Invalidate;     // force redraw
end;

end.

