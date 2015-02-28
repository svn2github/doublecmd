unit fCopyMoveDlg;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, Controls, Forms, StdCtrls, Buttons, ExtCtrls, Menus, KASPathEdit,
  uFileSource,
  uFileViewNotebook,
  uFileSourceOperation,
  uFileSourceOperationOptionsUI,
  uOperationsManager,
  uFormCommands;

type

  TCopyMoveDlgType = (cmdtCopy, cmdtMove);

  { TfrmCopyDlg }

  TfrmCopyDlg = class(TForm, IFormCommands)
    btnCancel: TBitBtn;
    btnOK: TBitBtn;
    btnAddToQueue: TBitBtn;
    btnOptions: TButton;
    btnSaveOptions: TButton;
    edtDst: TKASPathEdit;
    grpOptions: TGroupBox;
    lblCopySrc: TLabel;
    mnuQueue2: TMenuItem;
    mnuQueue3: TMenuItem;
    mnuQueue4: TMenuItem;
    mnuQueue5: TMenuItem;
    mnuQueue1: TMenuItem;
    mnuNewQueue: TMenuItem;
    pmQueuePopup: TPopupMenu;
    pnlButtons: TPanel;
    pnlOptions: TPanel;
    pnlSelector: TPanel;
    btnCreateSpecialQueue: TBitBtn;
    procedure btnCreateSpecialQueueClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnOptionsClick(Sender: TObject);
    procedure btnSaveOptionsClick(Sender: TObject);
    procedure btnStartModeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure frmCopyDlgShow(Sender: TObject);
    procedure mnuNewQueueClick(Sender: TObject);
    procedure mnuQueueNumberClick(Sender: TObject);
    procedure pnlOptionsResize(Sender: TObject);

  private
    FCommands: TFormCommands;
    FDialogType: TCopyMoveDlgType;
    noteb: TFileViewNotebook;
    FFileSource: IFileSource;
    FOperationOptionsUIClass: TFileSourceOperationOptionsUIClass;
    FOperationOptionsUI: TFileSourceOperationOptionsUI;

    function GetQueueIdentifier: TOperationsManagerQueueIdentifier;
    function ShowTabsSelector: integer;
    procedure TabsSelector(Sender: TObject);
    procedure TabsSelectorMouseDown(Sender: TObject; Button: TMouseButton;
                                    Shift: TShiftState; X, Y: Integer);
    procedure RemoveConstraints(Data: PtrInt);
    procedure ShowOptions(bShow: Boolean);
    procedure UpdateSize;

    property Commands: TFormCommands read FCommands implements IFormCommands;

  public
    constructor Create(TheOwner: TComponent; DialogType: TCopyMoveDlgType;
                       AFileSource: IFileSource;
                       AOperationOptionsUIClass: TFileSourceOperationOptionsUIClass); reintroduce;
    constructor Create(TheOwner: TComponent); override;
    procedure SetOperationOptions(Operation: TFileSourceOperation);

    property QueueIdentifier: TOperationsManagerQueueIdentifier read GetQueueIdentifier;

  published
    procedure cm_AddToQueue(const Params: array of String);
  end;


implementation

{$R *.lfm}

uses
  fMain, LCLType, LCLVersion, uGlobs, uLng, uHotkeyManager, DCStrUtils;

const
  HotkeysCategory = 'Copy/Move Dialog';

var
  FQueueIdentifier: TOperationsManagerQueueIdentifier = SingleQueueId;

constructor TfrmCopyDlg.Create(TheOwner: TComponent; DialogType: TCopyMoveDlgType;
                               AFileSource: IFileSource;
                               AOperationOptionsUIClass: TFileSourceOperationOptionsUIClass);
begin
  FDialogType := DialogType;
  FFileSource := AFileSource;
  FOperationOptionsUIClass := AOperationOptionsUIClass;
  FCommands := TFormCommands.Create(Self);
  inherited Create(TheOwner);
end;

constructor TfrmCopyDlg.Create(TheOwner: TComponent);
begin
  Create(TheOwner, cmdtCopy, nil, nil);
end;

procedure TfrmCopyDlg.SetOperationOptions(Operation: TFileSourceOperation);
begin
  if Assigned(FOperationOptionsUI) then
    FOperationOptionsUI.SetOperationOptions(Operation);
end;

procedure TfrmCopyDlg.cm_AddToQueue(const Params: array of String);
var
  Value: Integer;
  sQueueId: String;
begin
  if GetParamValue(Params, 'queueid', sQueueId) and TryStrToInt(sQueueId, Value) then
    begin
      if Value < 0 then
        mnuNewQueue.Click
      else
        FQueueIdentifier := Value
    end
  else
    FQueueIdentifier := SingleQueueId;
  ModalResult := btnAddToQueue.ModalResult;
end;

procedure TfrmCopyDlg.TabsSelector(Sender: TObject);
begin
  edtDst.Text := noteb[(Sender as TButton).tag].CurrentPath;
end;

procedure TfrmCopyDlg.TabsSelectorMouseDown(Sender: TObject; Button: TMouseButton;
                                            Shift: TShiftState; X, Y: Integer);
begin
  edtDst.Text := noteb[(Sender as TButton).tag].CurrentPath;
end;

procedure TfrmCopyDlg.RemoveConstraints(Data: PtrInt);
begin
  AutoSize := False;
  Constraints.MinWidth := 0;
end;

function TfrmCopyDlg.ShowTabsSelector: integer;
var
  btnS, btnL: TButton;
  i, tc: PtrInt;
  st: TStringList;
  s: String;
begin
  noteb := frmMain.NotActiveNotebook;

  if noteb.PageCount = 1 then
    begin
      Result:=0;
      exit;
    end;

  tc := noteb.PageCount;
  st := TStringList.Create;
  try
    for i:=0 to tc-1 do
    if noteb.View[i].Visible then
      begin
        s:=noteb[i].CurrentPath;
        if st.IndexOf(s)=-1 then
          begin
            st.Add(s);
            st.Objects[st.Count-1]:=TObject(i);
          end;
      end;

    tc := st.Count;
    btnL := nil;
    if tc>10 then tc:=10;
    for i:=0 to tc-1 do
      begin
        btnS:= TButton.Create(Self);
        btns.Parent:=pnlSelector;
        btns.Tag:=PtrInt(st.Objects[i]);
        if i<9 then
          btns.Caption := '&' + IntToStr(i+1) + ' - ' + noteb.Page[PtrInt(st.Objects[i])].Caption
        else
          btns.Caption := '&0 - ' + noteb.Page[PtrInt(st.Objects[i])].Caption;

        btnS.OnClick := @TabsSelector;
        btnS.OnMouseDown := @TabsSelectorMouseDown;

        btns.AutoSize:=True;
        btns.Left := 0;
        btns.Top := 0;
        btns.Anchors :=[akLeft,akTop,akBottom];
        btns.Visible := True;

        if btnL <> nil then
        begin
          btns.AnchorSideLeft.Control := btnL;
          btns.AnchorSideLeft.Side := asrRight;
        end;

        btnL := btnS;
        if (Self.Width < (btnL.Left+btnL.Width+200)) then // 200 = Ok + Cancel
          Self.Width := (btnL.Left+btnL.Width+200);
      end;

  finally
    st.Free;
  end;
end;

function TfrmCopyDlg.GetQueueIdentifier: TOperationsManagerQueueIdentifier;
begin
  Result:= FQueueIdentifier;
end;

procedure TfrmCopyDlg.frmCopyDlgShow(Sender: TObject);
begin
  case FDialogType of
    cmdtCopy:
      begin
        Caption := rsDlgCp;
      end;

    cmdtMove:
      begin
        Caption := rsDlgMv;
      end;
  end;

  if gShowCopyTabSelectPanel then
    ShowTabsSelector;

  edtDst.SelectAll;
  edtDst.SetFocus;

  Application.QueueAsyncCall(@RemoveConstraints, 0);
end;

procedure TfrmCopyDlg.mnuNewQueueClick(Sender: TObject);
var
  NewQueueId: TOperationsManagerQueueIdentifier;
begin
  for NewQueueId := Succ(FreeOperationsQueueId) to MaxInt do
  with OperationsManager do
  begin
    if not Assigned(QueueByIdentifier[NewQueueId]) then
    begin
      FQueueIdentifier := NewQueueId;
      ModalResult := btnAddToQueue.ModalResult;
      Break;
    end;
  end;
end;

procedure TfrmCopyDlg.mnuQueueNumberClick(Sender: TObject);
var
  NewQueueNumber: TOperationsManagerQueueIdentifier;
begin
  if TryStrToInt(Copy((Sender as TMenuItem).Name, 9, 1), NewQueueNumber) then
  begin
    FQueueIdentifier := NewQueueNumber;
    ModalResult := btnAddToQueue.ModalResult;
  end;
end;

procedure TfrmCopyDlg.pnlOptionsResize(Sender: TObject);
begin
  UpdateSize;
end;

procedure TfrmCopyDlg.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if gShowCopyTabSelectPanel and (edtDst.Focused=false) and (key-49<pnlSelector.ControlCount) then
    begin
      if (key>=VK_1) and (Key<=VK_9) then
         TButton(pnlSelector.Controls[key-49]).Click;

      if key=vk_0 then
        TButton(pnlSelector.Controls[9]).Click;
    end;

  {$IF lcl_fullversion < 093100}
  case Key of
    VK_ESCAPE: // Must handle before drag manager. Lazarus bug 0020676.
      begin
        ModalResult := mrCancel;
        Key := 0;
      end;
  end;
  {$ENDIF}
end;

procedure TfrmCopyDlg.btnCreateSpecialQueueClick(Sender: TObject);
begin
  btnCreateSpecialQueue.PopupMenu.PopUp;
end;

procedure TfrmCopyDlg.btnOKClick(Sender: TObject);
begin
  FQueueIdentifier := FreeOperationsQueueId;
end;

procedure TfrmCopyDlg.btnOptionsClick(Sender: TObject);
begin
  Constraints.MinWidth := Width;
  ShowOptions(not pnlOptions.Visible);
  btnOptions.Enabled := not btnOptions.Enabled;
  ClientWidth := pnlOptions.Width + ChildSizing.LeftRightSpacing * 2;
  pnlOptions.Anchors := pnlOptions.Anchors + [akRight];
  MoveToDefaultPosition;
  Constraints.MinWidth := 0;
end;

procedure TfrmCopyDlg.btnSaveOptionsClick(Sender: TObject);
begin
  if Assigned(FOperationOptionsUI) then
    FOperationOptionsUI.SaveOptions;
end;

procedure TfrmCopyDlg.btnStartModeClick(Sender: TObject);
begin
  btnOK.PopupMenu.PopUp;
end;

procedure TfrmCopyDlg.FormCreate(Sender: TObject);
var
  HMForm: THMForm;
  Hotkey: THotkey;
begin
  Constraints.MinWidth := Width;
  pnlSelector.Visible := gShowCopyTabSelectPanel;

  // Fix align of options panel and dialog size at start.
  if not pnlSelector.Visible then
    pnlOptions.Top := pnlOptions.Top -
                      (pnlSelector.Height +
                       pnlSelector.BorderSpacing.Top +
                       pnlSelector.BorderSpacing.Bottom);

  // Operation options.
  if Assigned(FOperationOptionsUIClass) then
  begin
    FOperationOptionsUI := FOperationOptionsUIClass.Create(Self, FFileSource);
    FOperationOptionsUI.Parent := grpOptions;
    FOperationOptionsUI.Align  := alClient;
  end
  else
    btnOptions.Visible := False;
  ShowOptions(False);

  btnOK.Caption := rsDlgOpStart;
  if FQueueIdentifier = FreeOperationsQueueId then FQueueIdentifier:= SingleQueueId;
  btnAddToQueue.Caption:= btnAddToQueue.Caption + ' #' + IntToStr(FQueueIdentifier);

  HMForm := HotMan.Register(Self, HotkeysCategory);
  Hotkey := HMForm.Hotkeys.FindByCommand('cm_AddToQueue');

  if Assigned(Hotkey) then
    btnAddToQueue.Caption := btnAddToQueue.Caption + ' (' + ShortcutsToText(Hotkey.Shortcuts) + ')';
end;

procedure TfrmCopyDlg.FormDestroy(Sender: TObject);
begin
  HotMan.UnRegister(Self);
end;

procedure TfrmCopyDlg.ShowOptions(bShow: Boolean);
begin
    pnlOptions.Visible := bShow;
  UpdateSize;
end;

procedure TfrmCopyDlg.UpdateSize;
begin
  if pnlOptions.Visible then
    Self.Height := pnlOptions.Top + pnlOptions.Height +
                   pnlOptions.BorderSpacing.Top + pnlOptions.BorderSpacing.Bottom
  else
    Self.Height := pnlOptions.Top;
end;

initialization
  TFormCommands.RegisterCommandsForm(TfrmCopyDlg, HotkeysCategory, @rsHotkeyCategoryCopyMoveDialog);

end.
