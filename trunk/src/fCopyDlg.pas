unit fCopyDlg;

interface

uses
  LResources,
  SysUtils, Types, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, ExtCtrls;

type

  { TfrmCopyDlg }

  TfrmCopyDlg = class(TForm)
    btnCancel: TBitBtn;
    btnOK: TBitBtn;
    cbDropReadOnlyFlag: TCheckBox;
    cmbFileType: TComboBox;
    edtDst: TEdit;
    lblCopySrc: TLabel;
    lblFileType: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    pnlSelector: TPanel;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure frmCopyDlgKeyPress(Sender: TObject; var Key: Char);
    procedure frmCopyDlgShow(Sender: TObject);
  private
    function ShowTabsSelector: integer;
    procedure TabsSelector(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmCopyDlg: TfrmCopyDlg;

implementation
uses
  uLng,fmain,framePanel,LCLType,uGlobs;

var noteb:TNotebook;
procedure TfrmCopyDlg.TabsSelector(Sender: TObject);
begin
  edtDst.Text:=TFrameFilePanel(noteb.Page[(sender as TBitBtn).tag].Components[0]).ActiveDir;
end;

function TfrmCopyDlg.ShowTabsSelector: integer;
var btnS:TBitBtn; i,tc:integer; st:TStringList; s:string;
begin
  if frmmain.SelectedPanel=fpRight
  then noteb:=frmmain.nbLeft
  else noteb:=frmmain.nbRight;

  if noteb.PageCount=1 then
    begin
      Result:=0;
      exit;
    end;
  tc:=noteb.PageCount;
  try
    st:=TStringList.Create;
    for i:=0 to tc-1 do
    if TFrameFilePanel(noteb.Page[i].Components[0]).Visible=true then
      begin
       s:=TFrameFilePanel(noteb.Page[i].Components[0]).ActiveDir;
        if st.IndexOf(s)=-1 then
          begin
            st.Add(s);
            st.Objects[st.Count-1]:=TObject(i);
          end;
      end;

  tc:=st.Count;
  if tc>10 then tc:=10;
  for i:=0 to tc-1 do
    begin
      btnS:=TBitBtn.Create(frmCopyDlg);
      btns.Parent:=pnlSelector;
      btns.Tag:=PtrInt(st.Objects[i]);
      if i<9 then
        btns.Caption:=inttostr(i+1)+' - '+noteb.Page[PtrInt(st.Objects[i])].Caption
      else
        btns.Caption:='0 - '+noteb.Page[PtrInt(st.Objects[i])].Caption;

      btnS.OnClick:=TabsSelector;

      btns.Width:=60;
      btns.Height:=34;
      btns.Left:=i*62;
      btns.Top:=5;
      btns.Visible:=true;
    end;
  finally
    st.Free;
  end;

end;


procedure TfrmCopyDlg.frmCopyDlgShow(Sender: TObject);
begin
  if gShowCopyTabSelectPanel then
    begin
      ShowTabsSelector;
      Panel1.SetFocus;
    end
  else
    begin
      edtDst.SelectAll;
      edtDst.SetFocus;
    end;
end;

procedure TfrmCopyDlg.frmCopyDlgKeyPress(Sender: TObject; var Key: Char);
begin
  if Key=#27 then
    ModalResult:=mrCancel;
  if Key=#13 then
  begin
    ModalResult:=mrOK;
    Key:=#0;
  end;
end;


procedure TfrmCopyDlg.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if gShowCopyTabSelectPanel and (edtDst.Focused=false) and (key-49<pnlSelector.ControlCount) then
    begin
      if (key>=VK_1) and (Key<=VK_9) then
         TBitBtn(pnlSelector.Controls[key-49]).Click;

      if key=vk_0 then
        TBitBtn(pnlSelector.Controls[9]).Click;
    end;
end;

initialization
 {$I fCopyDlg.lrs}
end.
