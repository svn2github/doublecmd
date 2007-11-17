{
Seksi Commander
----------------------------
Licence  : GNU GPL v 2.0
Author   : Pavel Letko (letcuv@centrum.cz)

File combiner

contributors:
  Radek Cervinka
}

unit fLinker;
{$mode objfpc}{$H+}
interface

uses
  LResources,
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons;

type
  TfrmLinker = class(TForm)
    lblFileName: TLabel;
    lstFile: TListBox;
    gbSaveTo: TGroupBox;
    edSave: TEdit;
    btnSave: TButton;
    grbxControl: TGroupBox;
    btnOK: TButton;
    btnExit: TButton;
    spbtnUp: TButton;
    spbtnDown: TButton;
    spbtnDel: TButton;
    dlgSaveAll: TSaveDialog;
    prbrWork: TProgressBar;
    procedure spbtnUpClick(Sender: TObject);
    procedure spbtnDownClick(Sender: TObject);
    procedure spbtnDelClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { Private declarations }
  public
    sDirectory: String;
    procedure LoadLng;
    { Public declarations }
  end;

function ShowLinkerFilesForm(var lsFiles:TStringList):Boolean;
{start function with input arguments}
implementation

uses
  uLng, uFileProcs;

//var gDirectory:string;

procedure TfrmLinker.LoadLng;
begin
  //Caption:= StringReplace(lngGetString(clngMnuFileCombine),'&','',[rfReplaceAll]);
  //dlgSaveAll.Title:=lngGetString(clngLinkDialogSave);
end;

function ShowLinkerFilesForm(var lsFiles:TStringList):Boolean;
var
  c:Integer;
begin

  With TfrmLinker.Create(Application) do
  begin
    try
      for c:=0 to lsFiles.Count-1 do
      with lstFile.Items do
      begin
        writeln(ExtractFileName(lsFiles[c]));
        Add(ExtractFileName(lsFiles[c]));
      end;
      LoadLng;
      prbrWork.Max:=lsFiles.Count;
      prbrWork.Position:=0;
      prbrWork.Min:=0;
      edSave.Text:=lsFiles[0]+'.all';
      sDirectory:=ExtractFileDir(edSave.Text);
      ShowModal;
      Result:=True;
    finally
      Free;
    end;
  end;
end;

procedure TfrmLinker.spbtnDownClick(Sender: TObject);
var
  s:String;
  iSelected:Integer;
begin
  with lstFile do
  begin
    if ItemIndex<0 then Exit;
    if ItemIndex=Items.Count-1 then Exit;
    iSelected:=ItemIndex;
    s:=Items[iSelected];
    Items[iSelected]:=Items[iSelected+1];
    Items[iSelected+1]:=s;
    ItemIndex:=iSelected+1;
  end;
end;

procedure TfrmLinker.spbtnUpClick(Sender: TObject);
var
  s:String;
  iSelected:Integer;
begin
  with lstFile do
  begin
    if ItemIndex<1 then Exit;
    iSelected:=ItemIndex;
    s:=Items[iSelected];
    Items[iSelected]:=Items[iSelected-1];
    Items[iSelected-1]:=s;
    ItemIndex:=iSelected-1;
  end;
end;

procedure TfrmLinker.spbtnDelClick(Sender: TObject);
begin
  with lstFile do
  begin
    if ItemIndex>-1 then
      Items.Delete(ItemIndex);
  end;
end;

procedure TfrmLinker.btnSaveClick(Sender: TObject);
begin
  dlgSaveAll.InitialDir:=ExtractFileDir(edSave.Text);
  dlgSaveAll.FileName:=ExtractFileName(edSave.Text);

  if dlgSaveAll.Execute then
    edSave.Text:=dlgSaveAll.FileName;
end;

procedure TfrmLinker.btnOKClick(Sender: TObject);
var
  c:integer;
  fTarget,fSource:TFileStream;

begin
  if ForceDirectory(ExtractFileDir(edSave.Text)) then
  begin
    fTarget:=TFileStream.Create(edSave.Text,fmCreate);
    try
      prbrWork.Max:=lstFile.Items.Count;
      prbrWork.Position:=0;
      for c:=0 to lstFile.Items.Count-1 do
      begin
        fSource:=TFileStream.Create(sDirectory+PathDelim
              +lstFile.Items[c],fmOpenRead);
        try
          fTarget.CopyFrom(fSource,fSource.Size);
          prbrWork.Position:=prbrWork.Position+1;
        finally
          FreeAndNil(fSource);
        end;
      end;
      ShowMessage(rsLinkMsgOK);
    finally
      FreeAndNil(fTarget);
      prbrWork.Position:=0;
    end;
  end;
end;

initialization
 {$I flinker.lrs}
end.
