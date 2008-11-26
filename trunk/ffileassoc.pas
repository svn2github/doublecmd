{
    Double Commander
    -------------------------------------------------------------------------
    File associations configuration

    Copyright (C) 2008  Koblov Alexander (Alexx2000@mail.ru)

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

unit fFileAssoc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, ExtCtrls, EditBtn, uExts, ExtDlgs, Menus;

type

  { TfrmFileAssoc }

  TfrmFileAssoc = class(TForm)
    btnAddAct: TButton;
    btnAddExt: TButton;
    btnAddNewType: TButton;
    btnCancel: TBitBtn;
    btnDownAct: TButton;
    btnOK: TBitBtn;
    btnUpAct: TButton;
    btnRemoveAct: TButton;
    btnRemoveExt: TButton;
    btnRemoveType: TButton;
    btnRenameType: TButton;
    edbAction: TEditButton;
    edtIconFileName: TEdit;
    fneCommand: TFileNameEdit;
    gbFileTypes: TGroupBox;
    gbIcon: TGroupBox;
    gbExts: TGroupBox;
    gbActions: TGroupBox;
    lblAction: TLabel;
    lblCommand: TLabel;
    lbActions: TListBox;
    lbExts: TListBox;
    lbFileTypes: TListBox;
    miFullPath: TMenuItem;
    miFilePath: TMenuItem;
    miFileName: TMenuItem;
    miGetOutputFromCommand: TMenuItem;
    miShell: TMenuItem;
    miViewer: TMenuItem;
    miVfs: TMenuItem;
    miEditor: TMenuItem;
    miEdit: TMenuItem;
    miView: TMenuItem;
    miOpen: TMenuItem;
    OpenPictureDialog: TOpenPictureDialog;
    pnlButtonPanel: TPanel;
    pmActions: TPopupMenu;
    pmCommands: TPopupMenu;
    sbtnIcon: TSpeedButton;
    btnCommands: TSpeedButton;
    procedure btnActionsClick(Sender: TObject);
    procedure btnAddActClick(Sender: TObject);
    procedure btnAddExtClick(Sender: TObject);
    procedure btnAddNewTypeClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnCommandsClick(Sender: TObject);
    procedure btnDownActClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnRemoveActClick(Sender: TObject);
    procedure btnRemoveExtClick(Sender: TObject);
    procedure btnRemoveTypeClick(Sender: TObject);
    procedure btnRenameTypeClick(Sender: TObject);
    procedure btnUpActClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure lbActionsSelectionChange(Sender: TObject; User: boolean);
    procedure lbFileTypesDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure lbFileTypesSelectionChange(Sender: TObject; User: boolean);
    procedure edtActionChange(Sender: TObject);
    procedure fneCommandChange(Sender: TObject);
    procedure miActionsClick(Sender: TObject);
    procedure miCommandsClick(Sender: TObject);
    procedure sbtnIconClick(Sender: TObject);
  private
    { private declarations }
    Exts : TExts;
    procedure UpdateEnabledButtons;
  public
    { public declarations }
  end; 

procedure ShowFileAssocDlg;

implementation
uses LCLType, uGlobsPaths, uGlobs, uPixMapManager;

procedure ShowFileAssocDlg;
begin
  with TfrmFileAssoc.Create(Application) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

{ TfrmFileAssoc }

procedure TfrmFileAssoc.FormCreate(Sender: TObject);
var
  I, iCount : Integer;
  sName : String;
begin
  Exts := TExts.Create;
  // load extension file
  if FileExists(gpIniDir + 'doublecmd.ext') then
    Exts.LoadFromFile(gpIniDir + 'doublecmd.ext');
  lbFileTypes.ItemHeight := gIconsSize + 4;
  // fill file types list box
  iCount := Exts.Count - 1;
  for I := 0 to iCount do
    begin
      // update icon index
      Exts.Items[I].IconIndex := gExts.Items[I].IconIndex;
      sName := Exts.Items[I].Name;
      if sName = '' then
        sName := Exts.Items[I].SectionName;
      lbFileTypes.Items.AddObject(sName, nil);
    end;
  if iCount > 0 then
    lbFileTypes.ItemIndex:= 0;
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.UpdateEnabledButtons;
begin
  if (lbExts.Items.Count = 0) or (lbExts.ItemIndex = -1) then
    btnRemoveExt.Enabled := False
  else
    btnRemoveExt.Enabled := True;

  if (lbActions.Items.Count = 0) or (lbActions.ItemIndex = -1) then
    begin
      btnRemoveAct.Enabled := False;
      btnUpAct.Enabled := False;
      btnDownAct.Enabled := False;
      edbAction.Enabled:= False;
      fneCommand.Enabled:= False;
      edbAction.Text:= '';
      fneCommand.FileName:= '';
    end
  else
    begin
      btnRemoveAct.Enabled := True;
      btnUpAct.Enabled := True;
      btnDownAct.Enabled := True;
      edbAction.Enabled:= True;
      fneCommand.Enabled:= True;
    end;

  if lbActions.ItemIndex = 0 then
    btnUpAct.Enabled:= False;
  if lbActions.ItemIndex = lbActions.Items.Count - 1 then
    btnDownAct.Enabled:= False;
end;

procedure TfrmFileAssoc.btnAddNewTypeClick(Sender: TObject);
var
  ExtAction : TExtAction;
  s:string;
begin
  s:=InputBox(Caption, 'Enter name:', ''); // TODO: Localize
  if s='' then exit;
  ExtAction := TExtAction.Create;
  ExtAction.IsChanged := True;
  with lbFileTypes do
  begin
    ExtAction.Name :=s;
    Items.AddObject(ExtAction.Name, ExtAction);
    // add file type to TExts object
    Exts.AddItem(ExtAction);
    ItemIndex := Items.Count - 1;
  end;
end;

procedure TfrmFileAssoc.btnRemoveTypeClick(Sender: TObject);
var
  iIndex : Integer;
begin
  iIndex := lbFileTypes.ItemIndex;
  if iIndex < 0 then Exit;
  lbFileTypes.ItemIndex := iIndex - 1;
  lbFileTypes.Items.Delete(iIndex);
  // remove file type from TExts object
  Exts.DeleteItem(iIndex);
end;

procedure TfrmFileAssoc.btnRenameTypeClick(Sender: TObject);
var
  iIndex : Integer;
  sName : String;
begin
  iIndex := lbFileTypes.ItemIndex;
  if iIndex < 0 then Exit;
  sName := lbFileTypes.Items[iIndex];
  sName := InputBox(Caption, 'Enter name:', sName); // TODO: Localize
  lbFileTypes.Items[iIndex] := sName;
  // rename file type in TExts object
  Exts.Items[iIndex].Name := sName;
  Exts.Items[iIndex].IsChanged:= True;
end;

procedure TfrmFileAssoc.lbActionsSelectionChange(Sender: TObject; User: boolean);
var
  iIndex : Integer;
  slActions : TStringList;
begin
  iIndex := lbActions.ItemIndex;
  if (iIndex < 0) or (lbActions.Tag = 1) then Exit;
  slActions := TStringList(lbActions.Items.Objects[iIndex]);
  edbAction.Text := slActions.Names[iIndex];
  fneCommand.FileName := slActions.ValueFromIndex[iIndex];
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.lbFileTypesDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  I, iTextTop: Integer;
  ExtAction: TExtAction;
  MR: TRect;
begin
  with (Control as TListBox) do
  begin
    MR.Left:= ARect.Left + 1;
    MR.Top:= ARect.Top + 1;
    MR.Right:= ARect.Right - 1;
    MR.Bottom:= ARect.Bottom - 1;

    ExtAction:= Exts.Items[Index];

    if odSelected in State then
      begin
        Canvas.Font.Color := clWindowText;
        Canvas.Brush.Color:= clWindowText;
        Canvas.FillRect(ARect);
        Canvas.Brush.Color:= Color;
        Canvas.FillRect(MR);
      end
    else
      begin
        Canvas.Brush.Color:= Color;
        Canvas.FillRect(ARect);
      end ;

    iTextTop := MR.Top + (gIconsSize div 2) - (Canvas.TextHeight(Items[Index]) div 2);
    if ExtAction.IconIndex < 0 then
      Canvas.Draw(MR.Left + 2, MR.Top + 1, TBitmap(Items.Objects[Index]))
    else
      PixMapManager.DrawBitmap(ExtAction.IconIndex, Canvas, MR);
    Canvas.TextOut(MR.Left + gIconsSize + 6, iTextTop, Items[Index]);
  end;

end;

procedure TfrmFileAssoc.lbFileTypesSelectionChange(Sender: TObject;
  User: boolean);
var
  ExtCommand : TExtAction;
  I, iCount : Integer;
begin
  with Sender as TListBox do
    begin
      if ItemIndex=-1 then ItemIndex:=0;
      ExtCommand := Exts.Items[ItemIndex];
      lbExts.Items.Assign(ExtCommand.Extensions);
      lbExts.ItemIndex := lbExts.Count - 1;
      lbActions.Items.Clear;
      iCount := ExtCommand.Actions.Count - 1;
      for I := 0 to iCount do
        begin
          lbActions.Items.AddObject(ExtCommand.Actions.Names[I], ExtCommand.Actions);
        end;
      lbActions.ItemIndex := iCount;
    end;
  if Assigned(sbtnIcon.Glyph) then
    sbtnIcon.Glyph.FreeImage;
  sbtnIcon.Glyph := LoadBitmapFromFile(ExtCommand.Icon, 32, sbtnIcon.Color);
  edtIconFileName.Text:= ExtCommand.Icon;
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.edtActionChange(Sender: TObject);
var
  iIndex : Integer;
  slActions : TStringList;
begin
  iIndex := lbActions.ItemIndex;
  if (iIndex < 0) or (edbAction.Text = '') then Exit;
  slActions := TStringList(lbActions.Items.Objects[iIndex]);
  slActions.Strings[iIndex] := edbAction.Text + '=' + slActions.ValueFromIndex[iIndex];
  lbActions.Items[iIndex] := edbAction.Text;
  if lbFileTypes.ItemIndex >= 0 then
    Exts.Items[lbFileTypes.ItemIndex].IsChanged:= True;
end;

procedure TfrmFileAssoc.fneCommandChange(Sender: TObject);
var
  iIndex : Integer;
  slActions : TStringList;
begin
  iIndex := lbActions.ItemIndex;
  if (iIndex < 0) or (fneCommand.FileName = '') then Exit;
  slActions := TStringList(lbActions.Items.Objects[iIndex]);
  slActions.ValueFromIndex[iIndex] := fneCommand.FileName;
  if lbFileTypes.ItemIndex >= 0 then
    Exts.Items[lbFileTypes.ItemIndex].IsChanged:= True;
end;

procedure TfrmFileAssoc.miActionsClick(Sender: TObject);
var
  miMenuItem: TMenuItem absolute Sender;
begin
  if miMenuItem.Name = 'miOpen' then
    edbAction.Text:= 'Open'
  else if miMenuItem.Name = 'miView' then
    edbAction.Text:= 'View'
  else if miMenuItem.Name = 'miEdit' then
    edbAction.Text:= 'Edit';
end;

procedure TfrmFileAssoc.miCommandsClick(Sender: TObject);
var
  miMenuItem: TMenuItem absolute Sender;
begin
  if miMenuItem.Name = 'miVfs' then
    fneCommand.Text:= fneCommand.Text + '{!VFS} '
  else if miMenuItem.Name = 'miViewer' then
    fneCommand.Text:= fneCommand.Text + '{!VIEWER} '
  else if miMenuItem.Name = 'miEditor' then
    fneCommand.Text:= fneCommand.Text + '{!EDITOR} '
  else if miMenuItem.Name = 'miShell' then
    fneCommand.Text:= fneCommand.Text + '{!SHELL} '
  else if miMenuItem.Name = 'miGetOutputFromCommand' then
    begin
      fneCommand.Text:= fneCommand.Text + '<??>';
      fneCommand.SetFocus;
      fneCommand.SelStart:= Pos('?>', fneCommand.Text) - 1;
    end
  else if miMenuItem.Name = 'miFileName' then
    fneCommand.Text:= fneCommand.Text + '''%f'''
  else if miMenuItem.Name = 'miFilePath' then
    fneCommand.Text:= fneCommand.Text + '''%d'''
  else if miMenuItem.Name = 'miFullPath' then
    fneCommand.Text:= fneCommand.Text + '''%p''';
end;

procedure TfrmFileAssoc.sbtnIconClick(Sender: TObject);
begin
  OpenPictureDialog.FileName:= edtIconFileName.Text;
  if OpenPictureDialog.Execute then
    begin
      edtIconFileName.Text := OpenPictureDialog.FileName;
      sbtnIcon.Glyph := LoadBitmapFromFile(edtIconFileName.Text, 32, sbtnIcon.Color);
      with lbFileTypes do
      begin
        // save icon for use in OnDrawItem procedure
        Items.Objects[ItemIndex]:= LoadBitmapFromFile(edtIconFileName.Text, gIconsSize, Color);
        Exts.Items[ItemIndex].Icon:= edtIconFileName.Text;
        // and set IconIndex
        Exts.Items[ItemIndex].IconIndex:= -1;
        Exts.Items[ItemIndex].IsChanged:= True;
        Repaint;
      end;
    end;
end;

procedure TfrmFileAssoc.btnAddExtClick(Sender: TObject);
var
  sExt : String;
begin
  sExt := InputBox(Caption, 'Enter file extension:', ''); // TODO: Localize
  if sExt <> '' then
    begin
      lbExts.ItemIndex := lbExts.Items.Add(sExt);
      // add extension in TExts object
      with lbFileTypes do
      begin
        Exts.Items[ItemIndex].Extensions.Add(sExt);
        Exts.Items[ItemIndex].IsChanged:= True;
      end;
    end;
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.btnRemoveExtClick(Sender: TObject);
var
  I : Integer;
begin
  // remove extension from extensions listbox
  with lbExts do
  begin
    I := ItemIndex;
    if I = - 1 then exit;
    Items.Delete(I);
    ItemIndex := I - 1;
  end;
  // remove extension from TExts object
  with lbFileTypes do
  begin
    Exts.Items[ItemIndex].Extensions.Delete(I);
    Exts.Items[ItemIndex].IsChanged:= True;
  end;
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.btnUpActClick(Sender: TObject);
var
  I : Integer;
begin
  // move action in actions listbox
  with lbActions do
  begin
    Tag := 1; // start moving
    I := ItemIndex;
    if I = - 1 then exit;
    if I > 0 then
    begin
      Items.Move(I, I - 1);
      ItemIndex:= I - 1;
    end;
  end;
  // move action in TExts object
  with lbFileTypes do
  begin
    Exts.Items[ItemIndex].Actions.Move(I, I - 1);
    Exts.Items[ItemIndex].IsChanged:= True;
  end;
  lbActions.Tag := 0; // end moving
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.btnDownActClick(Sender: TObject);
var
  I : Integer;
begin
  // move action in actions listbox
  with lbActions do
  begin
    Tag := 1; // start moving
    I := ItemIndex;
    if I = - 1 then exit;
    if (I < Items.Count - 1) and (I > -1) then
    begin
      Items.Move(I, I + 1);
      ItemIndex:= I + 1;
    end;
  end;
  // move action in TExts object
  with lbFileTypes do
  begin
    Exts.Items[ItemIndex].Actions.Move(I, I + 1);
    Exts.Items[ItemIndex].IsChanged:= True;
  end;
  lbActions.Tag := 0; // end moving
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.btnAddActClick(Sender: TObject);
var
  I : Integer;
  ExtAction : TExtAction;
begin
  with lbFileTypes do
    ExtAction := Exts.Items[ItemIndex];
    ExtAction.IsChanged:= True;
  // add action to TExts object
  I := ExtAction.Actions.Add('=');
  // add action to actions listbox
  with lbActions do
  begin
    Items.AddObject('', ExtAction.Actions);
    ItemIndex := I;
  end;
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.btnActionsClick(Sender: TObject);
begin
  pmActions.PopUp();
end;

procedure TfrmFileAssoc.btnRemoveActClick(Sender: TObject);
var
  I : Integer;
begin
  // remove action from actions listbox
  with lbActions do
  begin
    I := ItemIndex;
    if I = - 1 then exit;
    Items.Delete(I);
    ItemIndex := Count - 1;
  end;
  // remove action from TExts object
  with lbFileTypes do
  begin
    Exts.Items[ItemIndex].Actions.Delete(I);
    Exts.Items[ItemIndex].IsChanged:= True;
  end;
  UpdateEnabledButtons;
end;

procedure TfrmFileAssoc.btnOKClick(Sender: TObject);
begin
  gExts.Free;
  gExts := Exts;
  gExts.SaveToFile(gpIniDir + 'doublecmd.ext');
  Close;
end;

procedure TfrmFileAssoc.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmFileAssoc.btnCommandsClick(Sender: TObject);
begin
  pmCommands.PopUp();
end;

initialization
  {$I ffileassoc.lrs}

end.

