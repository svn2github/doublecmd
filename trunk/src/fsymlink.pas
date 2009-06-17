unit fSymLink;

interface

uses
  LResources,
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type

  { TfrmSymLink }

  TfrmSymLink = class(TForm)
    lblNew: TLabel;
    lblDst: TLabel;
    edtNew: TEdit;
    edtDst: TEdit;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    procedure btnCancelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure btnOKClick(Sender: TObject);
    procedure btnOKMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function ShowSymLinkForm(const sNew, sDst:String): Boolean;

implementation

uses
  FileUtil, uLng, uGlobs, uLog, uShowMsg, uOSUtils;

function ShowSymLinkForm(const sNew, sDst:String): Boolean;
begin
  with TfrmSymLink.Create(Application) do
  begin
    try
      edtDst.Text:=sDst;
      edtNew.Text:=sNew;
      Result:= (ShowModal = mrOK);
    finally
      Free;
    end;
  end;
end;

procedure TfrmSymLink.btnOKClick(Sender: TObject);
var
  sSrc,sDst:String;
begin
  inherited;
  sSrc:=edtNew.Text;
  sDst:=edtDst.Text;
  if CompareFilenames(sSrc, sDst) = 0 then Exit;
  if CreateSymLink(sSrc, sDst) then
    begin
      // write log
      if (log_cp_mv_ln in gLogOptions) and (log_success in gLogOptions) then
        logWrite(Format(rsMsgLogSuccess+rsMsgLogSymLink,[sSrc+' -> '+sDst]), lmtSuccess);
    end
  else
    begin
      // write log
      if (log_cp_mv_ln in gLogOptions) and (log_errors in gLogOptions) then
        logWrite(Format(rsMsgLogError+rsMsgLogSymLink,[sSrc+' -> '+sDst]), lmtError);

      // Standart error modal dialog
      MsgError(rsSymErrCreate);
    end;
end;

procedure TfrmSymLink.btnCancelMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ModalResult := btnCancel.ModalResult;
end;

procedure TfrmSymLink.btnOKMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ModalResult := btnOK.ModalResult;
  btnOKClick(Sender);
end;

initialization
 {$I fsymlink.lrs}

end.
