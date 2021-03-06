{
   Double Commander
   -------------------------------------------------------------------------
   Tooltips options page

   Copyright (C) 2011-2016 Alexander Koblov (alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License along
   with this program; if not, write to the Free Software Foundation, Inc.,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
}

unit fOptionsToolTips;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Buttons, Menus,
  ExtCtrls, fOptionsFrame, uInfoToolTip;

type

  { TfrmOptionsToolTips }

  TfrmOptionsToolTips = class(TOptionsEditor)
    btnAddFields: TBitBtn;
    btnDeleteFields: TBitBtn;
    btnApplyFields: TBitBtn;
    btnFieldsList: TButton;
    btnFieldsSearchTemplate: TBitBtn;
    chkShowToolTip: TCheckBox;
    edtFieldsList: TEdit;
    edtFieldsMask: TEdit;
    edtFieldsName: TEdit;
    gbCustomFields: TGroupBox;
    lblFieldsList: TLabel;
    lblFieldsMask: TLabel;
    lblFieldsName: TLabel;
    lsbCustomFields: TListBox;
    pnlEdit: TPanel;
    pmFields: TPopupMenu;
    procedure btnAddFieldsClick(Sender: TObject);
    procedure btnApplyFieldsClick(Sender: TObject);
    procedure btnDeleteFieldsClick(Sender: TObject);
    procedure btnFieldsListClick(Sender: TObject);
    procedure btnFieldsSearchTemplateClick(Sender: TObject);
    procedure chkShowToolTipChange(Sender: TObject);
    procedure miPluginClick(Sender: TObject);
    procedure lsbCustomFieldsSelectionChange(Sender: TObject; {%H-}User: boolean);
  private
    FFileInfoToolTip: TFileInfoToolTip;
    procedure ClearData;
  protected
    procedure Init; override;
    procedure Done; override;
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  public
    class function GetIconIndex: Integer; override;
    class function GetTitle: String; override;
    function IsSignatureComputedFromAllWindowComponents: Boolean; override;
    function ExtraOptionsSignature(CurrentSignature:dword):dword; override;
  end;

implementation

{$R *.lfm}

uses
  //Lazarus, Free-Pascal, etc.
  LCLProc,

  //DC
  uComponentsSignature, fMaskInputDlg, uLng, uGlobs, uSearchTemplate,
  uFileFunctions;

{ TfrmOptionsToolTips }

procedure TfrmOptionsToolTips.btnFieldsSearchTemplateClick(Sender: TObject);
var
  sMask: String;
  bTemplate: Boolean;
begin
  if ShowMaskInputDlg(rsMarkPlus, rsMaskInput, glsMaskHistory, sMask) then
    begin
      bTemplate:= IsMaskSearchTemplate(sMask);
      edtFieldsMask.Text:= sMask;
      edtFieldsMask.Enabled:= not bTemplate;
    end;
end;

procedure TfrmOptionsToolTips.chkShowToolTipChange(Sender: TObject);
begin
  gbCustomFields.Enabled:= chkShowToolTip.Checked;
end;

procedure TfrmOptionsToolTips.miPluginClick(Sender: TObject);
var
  sMask: String;
  MenuItem: TMenuItem absolute Sender;
begin
  case MenuItem.Tag of
    0:  begin
          sMask := '[DC().' + MenuItem.Hint + '{}]';
        end;
    1: begin
          sMask := '[Plugin(' + MenuItem.Parent.Caption + ').' + MenuItem.Caption + '{}]';
       end;
    2: begin
          sMask := '[Plugin(' + MenuItem.Parent.Parent.Caption + ').' + MenuItem.Parent.Caption + '{' + MenuItem.Caption + '}]';
       end;
    else
      begin
        sMask:= '\n'
      end;
  end;
  edtFieldsList.Text:= edtFieldsList.Text + sMask;
end;

procedure TfrmOptionsToolTips.lsbCustomFieldsSelectionChange(Sender: TObject;
  User: boolean);
var
  I: LongInt;
begin
  I:= lsbCustomFields.ItemIndex;
  pnlEdit.Enabled:= (I <> -1);
  btnDeleteFields.Enabled:= pnlEdit.Enabled;
  if pnlEdit.Enabled then
  begin
    edtFieldsName.Text:= lsbCustomFields.Items[I];
    with FFileInfoToolTip.HintItemList[I] do
    begin
      edtFieldsName.Text:= Name;
      edtFieldsMask.Text:= Mask;
      edtFieldsList.Text:= Hint;
    end;
  end;
end;

procedure TfrmOptionsToolTips.ClearData;
begin
  edtFieldsName.Text:= EmptyStr;
  edtFieldsMask.Text:= EmptyStr;
  edtFieldsList.Text:= EmptyStr;
end;

class function TfrmOptionsToolTips.GetIconIndex: Integer;
begin
  Result := 19;
end;

class function TfrmOptionsToolTips.GetTitle: String;
begin
  Result := rsOptionsEditorTooltips;
end;

{ TfrmOptionsToolTips.IsSignatureComputedFromAllWindowComponents }
function TfrmOptionsToolTips.IsSignatureComputedFromAllWindowComponents: Boolean;
begin
  Result := False;
end;

{ TfrmOptionsToolTips.ExtraOptionsSignature }
function TfrmOptionsToolTips.ExtraOptionsSignature(CurrentSignature:dword):dword;
begin
  Result := ComputeSignatureSingleComponent(chkShowToolTip, CurrentSignature);
end;

procedure TfrmOptionsToolTips.Init;
begin
  FFileInfoToolTip:= TFileInfoToolTip.Create;
end;

procedure TfrmOptionsToolTips.Done;
begin
  FreeThenNil(FFileInfoToolTip);
end;

procedure TfrmOptionsToolTips.btnDeleteFieldsClick(Sender: TObject);
var
  I: LongInt;
begin
  I:= lsbCustomFields.ItemIndex;
  if I <> -1 then
  begin
    lsbCustomFields.Items.Delete(I);
    FFileInfoToolTip.HintItemList.Delete(I);
  end;
  lsbCustomFields.ItemIndex:= lsbCustomFields.Items.Count - 1;
  pnlEdit.Enabled:= (lsbCustomFields.ItemIndex <> -1);
  btnDeleteFields.Enabled:= (lsbCustomFields.ItemIndex <> -1);
  if (lsbCustomFields.Items.Count = 0) then ClearData;
end;

procedure TfrmOptionsToolTips.btnFieldsListClick(Sender: TObject);
var
  MenuItem: TMenuItem;
begin
  FillContentFieldMenu(pmFields.Items, @miPluginClick);
  MenuItem:= TMenuItem.Create(pmFields);
  MenuItem.Caption:= '\n (New line)';
  MenuItem.Tag:= -1;
  MenuItem.OnClick:= @miPluginClick;
  pmFields.Items.Add(MenuItem);
  pmFields.PopUp(Mouse.CursorPos.x, Mouse.CursorPos.y);
end;

procedure TfrmOptionsToolTips.btnAddFieldsClick(Sender: TObject);
begin
  pnlEdit.Enabled:= (lsbCustomFields.Items.Count <> 0);
  btnDeleteFields.Enabled:= (lsbCustomFields.Items.Count <> 0);
  FFileInfoToolTip.HintItemList.Add(THintItem.Create);
  lsbCustomFields.ItemIndex:= lsbCustomFields.Items.Add(EmptyStr);
  ClearData;
end;

procedure TfrmOptionsToolTips.btnApplyFieldsClick(Sender: TObject);
var
  I: LongInt;
begin
  I:= lsbCustomFields.ItemIndex;
  if I <> -1 then
  begin
    lsbCustomFields.Items[I] := edtFieldsName.Text;
    with FFileInfoToolTip.HintItemList[I] do
    begin
      Name:= edtFieldsName.Text;
      Mask:= edtFieldsMask.Text;
      Hint:= edtFieldsList.Text;
    end;
  end;
end;

procedure TfrmOptionsToolTips.Load;
var
  I: LongInt;
begin
  gbCustomFields.Enabled:= gShowToolTipMode;
  chkShowToolTip.Checked:= gShowToolTipMode;

  FFileInfoToolTip.Assign(gFileInfoToolTip);
  for I:= 0 to FFileInfoToolTip.HintItemList.Count - 1 do
    lsbCustomFields.Items.Add(FFileInfoToolTip.HintItemList[I].Name);
end;

function TfrmOptionsToolTips.Save: TOptionsEditorSaveFlags;
begin
  gShowToolTipMode:= chkShowToolTip.Checked;

  gFileInfoToolTip.Assign(FFileInfoToolTip);
  Result := [];
end;

end.

