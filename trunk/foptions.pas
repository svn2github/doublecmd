{
   Double Commander
   ----------------------------
   Implementing of Options dialog

   Licence  : GNU GPL v 2.0
   Author   : radek.cervinka@centrum.cz

   contributors:

   Copyright (C) 2006-2007  Koblov Alexander (Alexx2000@mail.ru)

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

unit fOptions;
{$mode objfpc}{$H+}
interface

uses
  LResources,
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, ComCtrls, Buttons, fLngForm, Spin, ColorBox,
  CheckLst;

type

  { TfrmOptions }

  TfrmOptions = class(TfrmLng)
    bbtnApply: TBitBtn;
    bbtnHelp: TBitBtn;
    bbtnAddCategory: TBitBtn;
    bbtnDeleteCategory: TBitBtn;
    bbtnApplyCategory: TBitBtn;
    bbtnWFXAdd: TBitBtn;
    bbtnWFXDelete: TBitBtn;
    bbtnWFXRename: TBitBtn;
    bbtnWFXApply: TBitBtn;
    btnCategoryColor: TButton;
    btnOpen: TBitBtn;
    btnSelEditFnt: TButton;
    btnSelMainFnt: TButton;
    btnSelViewFnt: TButton;
    btSetHotKey: TButton;
    btnForeColor: TButton;
    btnBackColor: TButton;
    btClearHotKey: TButton;
    btnBackColor2: TButton;
    btnMarkColor: TButton;
    btnCursorColor: TButton;
    btnCursorText: TButton;
    cbBackColor: TColorBox;
    cBackGrndLabel: TLabel;
    cbActions: TComboBox;
    cbCaseSensitiveSort: TCheckBox;
    cbDirSelect: TCheckBox;
    cbEditorFont: TComboBox;
    cbExtDiffer: TCheckBox;
    cbExtEditor: TCheckBox;
    cbExtViewer: TCheckBox;
    cbIconsSize: TComboBox;
    cbLynxLike: TCheckBox;
    cbMainFont: TComboBox;
    cbSeparateExt: TCheckBox;
    cbShortFileSizeFormat: TCheckBox;
    cbViewerFont: TComboBox;
    cbExt: TComboBox;
    cbWCXPath: TComboBox;
    cbDropReadOnlyFlag: TCheckBox;
    cbFlatInterface: TCheckBox;
    cbFlatToolBar: TCheckBox;
    clbWFXList: TCheckListBox;
    clbWCXList: TCheckListBox;
    cbBackColor2: TColorBox;
    cbMarkColor: TColorBox;
    cbCursorColor: TColorBox;
    cbCursorText: TColorBox;
    cbTextColor: TColorBox;
    cbCategoryColor: TColorBox;
    cTextLabel: TLabel;
    dlgFnt: TFontDialog;
    edHotKey: TEdit;
    edtCategoryName: TEdit;
    edtCategoryMask: TEdit;
    edtEditorSize: TSpinEdit;
    edtExtDiffer: TEdit;
    edtExtEditor: TEdit;
    edtExtViewer: TEdit;
    edtMainSize: TSpinEdit;
    edtRunTerm: TEdit;
    edtTerm: TEdit;
    edtTest1: TEdit;
    edtTest2: TEdit;
    edtTest3: TEdit;
    edtViewerSize: TSpinEdit;
    gb: TGroupBox;
    gbExample: TGroupBox;
    gbFileTypesColors: TGroupBox;
    gbMisc: TGroupBox;
    gbScreenLayout: TGroupBox;
    cbFlatDiskPanel: TCheckBox;
    cbShowMainToolBar: TCheckBox;
    cbShowCmdLine: TCheckBox;
    cbShowCurDir: TCheckBox;
    cbShowDiskPanel: TCheckBox;
    cbShowDriveMenuButton: TCheckBox;
    cbShowKeysPanel: TCheckBox;
    cbShowStatusBar: TCheckBox;
    cbShowTabHeader: TCheckBox;
    cbShowTabs: TCheckBox;
    cbTwoDiskPanels: TCheckBox;
    ilTreeView: TImageList;
    lblIconsSize: TLabel;
    lblInstalledPlugins: TLabel;
    lblCategoryColor: TLabel;
    lblCategoryName: TLabel;
    lblCategoryMask: TLabel;
    lblBackground2: TLabel;
    lblMarkColor: TLabel;
    lblCursorColor: TLabel;
    lblCursorText: TLabel;
    lblAssociateWith: TLabel;
    lblExt: TLabel;
    lblAbout: TLabel;
    lblActions: TLabel;
    lblEditorFont: TLabel;
    lblHotKey: TLabel;
    lblMainFont: TLabel;
    lblRunTerm: TLabel;
    lblTerm: TLabel;
    lblViewerFont: TLabel;
    lbCategories: TListBox;
    lngList: TListBox;
    nbNotebook: TNotebook;
    odOpenDialog: TOpenDialog;
    optColorDialog: TColorDialog;
    pbExample: TPaintBox;
    pcPluginsTypes: TPageControl;
    pcPluginsType: TPageControl;
    pgFileTypesColors: TPage;
    pgLayout: TPage;
    pgPlugins: TPage;
    pnlCaption: TPanel;
    Panel3: TPanel;
    Panel1: TPanel;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    pgBehav: TPage;
    pgColor: TPage;
    pgFonts: TPage;
    pgHotKey: TPage;
    pgLng: TPage;
    pgTools: TPage;
    tsWCX: TTabSheet;
    tsWFX: TTabSheet;
    tvTreeView: TTreeView;
    procedure bbtnAddCategoryClick(Sender: TObject);
    procedure bbtnApplyCategoryClick(Sender: TObject);
    procedure bbtnApplyClick(Sender: TObject);
    procedure bbtnDeleteCategoryClick(Sender: TObject);
    procedure bbtnWFXAddClick(Sender: TObject);
    procedure bbtnWFXApplyClick(Sender: TObject);
    procedure bbtnWFXDeleteClick(Sender: TObject);
    procedure bbtnWFXRenameClick(Sender: TObject);
    procedure btClearHotKeyClick(Sender: TObject);
    procedure btnBackColor2Click(Sender: TObject);
    procedure btnCursorColorClick(Sender: TObject);
    procedure btnCursorTextClick(Sender: TObject);
    procedure btnCategoryColorClick(Sender: TObject);
    procedure btnMarkColorClick(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnForeColorClick(Sender: TObject);
    procedure btnBackColorClick(Sender: TObject);
    procedure cbCategoryColorChange(Sender: TObject);
    procedure cbColorBoxChange(Sender: TObject);
    procedure cbExtChange(Sender: TObject);
    procedure cbShowDiskPanelChange(Sender: TObject);
    procedure clbWCXListClick(Sender: TObject);
    procedure cbTextColorChange(Sender: TObject);
    procedure cbColorBoxDropDown(Sender: TObject);
    procedure edtEditorSizeChange(Sender: TObject);
    procedure edtMainSizeChange(Sender: TObject);
    procedure edtViewerSizeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btSetHotKeyClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnSelEditFntClick(Sender: TObject);
    procedure btnSelMainFntClick(Sender: TObject);
    procedure btnSelViewFntClick(Sender: TObject);
    procedure cbExtEditorClick(Sender: TObject);
    procedure cbExtDifferClick(Sender: TObject);
    procedure cbExtViewerClick(Sender: TObject);
    procedure cbMainFontChange(Sender: TObject);
    procedure cbEditorFontChange(Sender: TObject);
    procedure cbViewerFontChange(Sender: TObject);
    procedure edHotKeyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure lbCategoriesClick(Sender: TObject);
    procedure pbExamplePaint(Sender: TObject);
    procedure tsWCXShow(Sender: TObject);
    procedure tsWFXShow(Sender: TObject);
    procedure tvTreeViewChange(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
    vShortCut: TShortCut;
  public
    { Public declarations }
    procedure FillLngListBox;
    procedure LoadLng; override;
    procedure FillFontLists;
    procedure FillActionLists;
    procedure FillFileColorsList;
  end;
type
  TColorFileMask = record
    sFileMask : String;
    clMaskColor : TColor;
  end;
  PColorFileMask=^TColorFileMask;

implementation

uses
  uLng, uGlobs, uGlobsPaths, uPixMapManager, fMain, ActnList, LCLProc, menus, uWCXModule, uWFXmodule, uOSUtils;

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  inherited;
  FillActionLists;
  FillLngListBox;
  FillFontLists;
  FillFileColorsList;
  DebugLn(gTerm);
  edtTerm.Text:=gTerm;
  nbNotebook.PageIndex := 0;//let not warning on which page save form
end;

procedure TfrmOptions.btSetHotKeyClick(Sender: TObject);
var vNum: integer;
    vActions: TAction;
begin
  // ToDo Black list HotKey which can't use

  for vNum := 0 to cbActions.Items.Count - 1 do
  begin
    vActions := cbActions.Items.Objects[vNum] as TAction;
    if vActions.ShortCut = vShortCut then
    begin
      ShowMessage('ShortCut used by '+vActions.Name);// ToDo lang
      Exit;
    end;
  end;

  vActions := cbActions.Items.Objects[cbActions.ItemIndex] as TAction;
  vActions.ShortCut := vShortCut;
  cbActions.Items[cbActions.ItemIndex] := vActions.Name+'('+ShortCutToText(vActions.ShortCut)+')';
  cbActions.Text := vActions.Name+'('+ShortCutToText(vActions.ShortCut)+')';
end;


procedure TfrmOptions.btnForeColorClick(Sender: TObject);
begin
 if optColorDialog.Execute then
   begin
     cbTextColor.Text := '';
     cbTextColor.Color := optColorDialog.Color;
   end;
end;

procedure TfrmOptions.btnOpenClick(Sender: TObject);
var
  WCXmodule : TWCXmodule;
begin
  odOpenDialog.Filter := 'Archive plugins (*.wcx)|*.wcx';
  if odOpenDialog.Execute then
  begin
    WCXmodule := TWCXmodule.Create;
    if WCXmodule.LoadModule(odOpenDialog.FileName)then
      cbWCXPath.Text := IntToStr(WCXmodule.VFSCaps) + ',' + odOpenDialog.FileName
    else
      cbWCXPath.Text := '0,' + odOpenDialog.FileName;
  WCXModule.UnloadModule;
  WCXmodule.Free;
  end;
end;

procedure TfrmOptions.btnBackColorClick(Sender: TObject);
begin
   if optColorDialog.Execute then
   begin
     cbBackColor.Text := '';
     cbBackColor.Color := optColorDialog.Color;
   end;
end;

procedure TfrmOptions.cbColorBoxChange(Sender: TObject);
begin
  (Sender as TColorBox).Color := (Sender as TColorBox).Selection;
  pbExample.Repaint;
end;

procedure TfrmOptions.cbExtChange(Sender: TObject);
begin
  clbWCXList.ItemIndex := cbExt.ItemIndex;
end;

procedure TfrmOptions.cbShowDiskPanelChange(Sender: TObject);
begin
  cbTwoDiskPanels.Enabled := cbShowDiskPanel.Checked;
  cbFlatDiskPanel.Enabled := cbShowDiskPanel.Checked;
end;

procedure TfrmOptions.clbWCXListClick(Sender: TObject);
begin
  cbWCXPath.Text := clbWCXList.Items[clbWCXList.ItemIndex];
end;

procedure TfrmOptions.cbTextColorChange(Sender: TObject);
begin
  cbTextColor.Color := cbTextColor.Selection;
end;

procedure TfrmOptions.cbColorBoxDropDown(Sender: TObject);
begin
  (Sender as TColorBox).Color := clWindow;
end;

procedure TfrmOptions.edtEditorSizeChange(Sender: TObject);
begin
  edtTest2.Font.Size := edtEditorSize.Value;
end;

procedure TfrmOptions.edtMainSizeChange(Sender: TObject);
begin
  edtTest1.Font.Size := edtMainSize.Value;
end;

procedure TfrmOptions.edtViewerSizeChange(Sender: TObject);
begin
  edtTest3.Font.Size := edtViewerSize.Value;
end;

procedure TfrmOptions.LoadLng;
begin
  btnCancel.Caption:= lngGetString(clngbutCancel);
//  btnOK.Caption:= lngGetString(clngbutOK);

  Caption:=lngGetString(clngDlgOpt);
  tvTreeView.Items.Item[0].Text := lngGetString(clngDlgOptSelLng);
  pnlCaption.Caption := tvTreeView.Items.Item[0].Text;
  lblTerm.Caption:=lngGetString(clngDlgOptTerm);
  cbDirSelect.Caption:=lngGetString(clngDlgOptSelDir);
  cbCaseSensitiveSort.Caption:=lngGetString(clngDlgOptCaseSens);
  cbLynxLike.Caption:=lngGetString(clngDlgOptLynx);

  cbShortFileSizeFormat.Caption:=lngGetString(clngDlgOptShortFileSize);
  tvTreeView.Items.Item[1].Text := lngGetString(clngDlgOptBehaviourTab);
  tvTreeView.Items.Item[2].Text := lngGetString(clngDlgOptToolsTab);

  cbExtEditor.Caption:=lngGetString(clngDlgOptExtEdit);
  cbExtViewer.Caption:=lngGetString(clngDlgOptExtView);
  cbExtDiffer.Caption:=lngGetString(clngDlgOptExtDiff);
  cbSeparateExt.Caption:=lngGetString(clngDlgOptSeparateExt);

  {Layout page}
  cbShowMainToolBar.Checked := gButtonBar;
  cbFlatToolBar.Checked := gToolBarFlat;
  cbShowDiskPanel.Checked := gDriveBar1;
  cbTwoDiskPanels.Checked := gDriveBar2;
  cbFlatDiskPanel.Checked := gDriveBarFlat;
  cbShowDriveMenuButton.Checked := gDriveMenuButton;
  cbShowTabs.Checked := gDirectoryTabs;
  cbShowCurDir.Checked := gCurDir;
  cbShowTabHeader.Checked := gTabHeader;
  cbShowStatusBar.Checked := gStatusBar;
  cbShowCmdLine.Checked := gCmdLine;
  cbShowKeysPanel.Checked := gKeyButtons;
  cbFlatInterface.Checked := gInterfaceFlat;


  cbDirSelect.Checked:=gDirSelect;
  cbCaseSensitiveSort.Checked:=gCaseSensitiveSort;
  cbLynxLike.Checked:=gLynxLike;
  cbShortFileSizeFormat.Checked:=gShortFileSizeFormat;

  cbExtEditor.Checked:=gUseExtEdit;
  cbExtViewer.Checked:=gUseExtView;
  cbExtDiffer.Checked:=gUseExtDiff;
  cbSeparateExt.Checked:=gSeparateExt;
  cbDropReadOnlyFlag.Checked := gDropReadOnlyFlag;

  edtExtEditor.Text:= gExtEdit;
  edtExtViewer.Text:=gExtView;
  edtExtDiffer.Text:=gExtDiff;
  
  edtExtEditor.Enabled:= cbExtEditor.Checked;
  edtExtDiffer.Enabled:= cbExtDiffer.Checked;
  edtExtViewer.Enabled:= cbExtViewer.Checked;

  edtRunTerm.Text:=gRunTerm;
  lblRunTerm.Caption:=lngGetString(clngDlgOptRunTerm);

  tvTreeView.Items.Item[3].Text := lngGetString(clngDlgOptFonts);
  lblMainFont.Caption:= lngGetString(clngDlgOptMainFont);
  lblEditorFont.Caption:= lngGetString(clngDlgOptEditorFont);
  lblViewerFont.Caption:= lngGetString(clngDlgOptViewerFont);

  { Colors }
  cbTextColor.Selection := gForeColor;
  cbTextColor.Color := gForeColor;
  
  cbBackColor.Selection := gBackColor;
  cbBackColor.Color := gBackColor;

  cbBackColor2.Selection := gBackColor2;
  cbBackColor2.Color := gBackColor2;

  cbMarkColor.Selection := gMarkColor;
  cbMarkColor.Color := gMarkColor;

  cbCursorColor.Selection := gCursorColor;
  cbCursorColor.Color := gCursorColor;

  cbCursorText.Selection := gCursorText;
  cbCursorText.Color := gCursorText;

  { Icons sizes in file panels }
  cbIconsSize.Text := IntToStr(gIconsSize) + 'x' + IntToStr(gIconsSize);
  // ToDo lang to tsColor tsHotKey
end;

procedure TfrmOptions.FillLngListBox;
var
  fr:TSearchRec;
  iIndex:Integer;
begin
  lngList.Clear;
  DebugLn('Language dir:'+gpLngDir);
  if FindFirst(gpLngDir+'*.lng', faAnyFile, fr)<>0 then
  begin
    FindClose(fr);
    Exit;
  end;
  repeat
    lngList.Items.Add(fr.Name);
  until FindNext(fr)<>0;
  
  FindClose(fr);

  iIndex:=lngList.Items.IndexOf(gLng);
  if iIndex>=0 then
    lngList.Selected[iIndex]:=True;
end;

procedure TfrmOptions.btnOKClick(Sender: TObject);
begin
  inherited;
  
  {Layout page}
  gButtonBar := cbShowMainToolBar.Checked;
  gToolBarFlat := cbFlatToolBar.Checked;
  gDriveBar1 := cbShowDiskPanel.Checked;
  gDriveBar2 := cbTwoDiskPanels.Checked;
  gDriveBarFlat := cbFlatDiskPanel.Checked;
  gDriveMenuButton := cbShowDriveMenuButton.Checked;
  gDirectoryTabs := cbShowTabs.Checked;
  gCurDir := cbShowCurDir.Checked;
  gTabHeader := cbShowTabHeader.Checked;
  gStatusBar := cbShowStatusBar.Checked;
  gCmdLine := cbShowCmdLine.Checked;
  gKeyButtons := cbShowKeysPanel.Checked;
  gInterfaceFlat := cbFlatInterface.Checked;
  
  gTerm:=edtTerm.Text;
  if lngList.ItemIndex>-1 then
    gLng:=lngList.Items[lngList.ItemIndex];
  gDirSelect:=cbDirSelect.Checked;
  gCaseSensitiveSort:=cbCaseSensitiveSort.Checked;
  gLynxLike:=cbLynxLike.Checked;
  gShortFileSizeFormat:=cbShortFileSizeFormat.Checked;

  gUseExtEdit:=cbExtEditor.Checked;
  gUseExtView:=cbExtViewer.Checked;
  gUseExtDiff:=cbExtDiffer.Checked;
  gSeparateExt:=cbSeparateExt.Checked;
  gDropReadOnlyFlag := cbDropReadOnlyFlag.Checked;

  gExtEdit:= edtExtEditor.Text;
  gExtView:= edtExtViewer.Text;
  gExtDiff:= edtExtDiffer.Text;
  gRunTerm:= edtRunTerm.Text;
  
  gFontName:=cbMainFont.Text;
  if (fsBold in EdtTest1.Font.Style) then
    gFontWeight := 700
  else
    gFontWeight := 400;
  gEditorFontName:=cbEditorFont.Text;
  gViewerFontName:=cbViewerFont.Text;
  
  {$hints off}
  gEditorSize:=Round(edtEditorSize.Value);
  gViewerSize:=Round(edtViewerSize.Value);
  gFontSize:=Round(edtMainSize.Value);
  {$hints on}

  { Colors }
  gForeColor := cbTextColor.Color;
  gBackColor := cbBackColor.Color; // background color
  gBackColor2 := cbBackColor2.Color;
  gMarkColor := cbMarkColor.Color;
  gCursorColor := cbCursorColor.Color;
  gCursorText := cbCursorText.Color;
  
  frmMain.UpdateWindowView;
  frmMain.Repaint; // for panels repaint
  frmMain.SaveShortCuts;
  
  if (gIconsSize <> StrToInt(Copy(cbIconsSize.Text, 1, 2))) then
    begin
      gIconsSize := StrToInt(Copy(cbIconsSize.Text, 1, 2)); //file panel icons size
      SaveGlobs;
      ShowMessage('Double Commander will restart for apply changes');
      ExecCmdFork(Application.ExeName);
      frmMain.Close;
    end;
end;

procedure TfrmOptions.btnSelEditFntClick(Sender: TObject);
begin
  dlgFnt.Font.Name:=cbEditorFont.Text;
  if dlgFnt.Execute then
    begin
      cbEditorFont.Text:=dlgFnt.Font.Name;
      edtEditorSize.Value := dlgFnt.Font.Size;
      edtTest2.Font := dlgFnt.Font;
    end;
end;

procedure TfrmOptions.btnSelMainFntClick(Sender: TObject);
begin
  dlgFnt.Font.Name:=cbMainFont.Text;
  if dlgFnt.Execute then
    begin
      cbMainFont.Text:=dlgFnt.Font.Name;
      edtMainSize.Value := dlgFnt.Font.Size;
      edtTest1.Font := dlgFnt.Font;
    end;
end;

procedure TfrmOptions.btnSelViewFntClick(Sender: TObject);
begin
  dlgFnt.Font.Name:=cbViewerFont.Text;
  if dlgFnt.Execute then
    begin
      cbViewerFont.Text:=dlgFnt.Font.Name;
      edtViewerSize.Value:= dlgFnt.Font.Size;
      edtTest3.Font := dlgFnt.Font;
    end;
end;

procedure TfrmOptions.cbExtEditorClick(Sender: TObject);
begin
  inherited;
  edtExtEditor.Enabled:=cbExtEditor.Checked
end;

procedure TfrmOptions.cbExtDifferClick(Sender: TObject);
begin
  inherited;
  edtExtDiffer.Enabled:=cbExtDiffer.Checked
end;

procedure TfrmOptions.cbExtViewerClick(Sender: TObject);
begin
  inherited;
  edtExtViewer.Enabled:=cbExtViewer.Checked
end;

procedure TfrmOptions.FillFontLists;
begin
  cbMainFont.Text := gFontName;
  cbViewerFont.Text := gViewerFontName;
  cbEditorFont.Text := gEditorFontName;

  if gFontWeight = 700 then
    EdtTest1.Font.Style := [fsBold];
    
  edtEditorSize.Value:=gEditorSize;
  edtViewerSize.Value:=gViewerSize;
  edtMainSize.Value:=gFontSize;
  
  with edtTest1.Font do
  begin
    Name := gFontName;
    Size := gFontSize;
  end; // with
  
  with edtTest2.Font do
  begin
    Name := gEditorFontName;
    Size := gEditorSize;
  end; // with
  
  with edtTest3.Font do
  begin
    Name := gViewerFontName;
    Size := gViewerSize;
  end; // with
end;

procedure TfrmOptions.FillActionLists;
var vNum: integer;
var vActions: TAction;
begin
  for vNum := 0 to frmMain.actionLst.ActionCount -1 do
  begin
    vActions := frmMain.actionLst.Actions[vNum] as TAction;
    cbActions.Items.AddObject(vActions.Name+'('+ShortCutToText(vActions.ShortCut)+')',vActions);
  end;
end;

procedure TfrmOptions.cbMainFontChange(Sender: TObject);
begin
//  edtTest1.Font.Name:=cbMainFont.Text;
end;

procedure TfrmOptions.cbEditorFontChange(Sender: TObject);
begin
//  edtTest2.Font.Name:=cbEditorFont.Text;
end;

procedure TfrmOptions.cbViewerFontChange(Sender: TObject);
begin
//  edtTest3.Font.Name:=cbViewerFont.Text;
end;

procedure TfrmOptions.edHotKeyKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  vShortCut := ShortCut(Key,Shift);
  TEdit(Sender).Text := ShortCutToText(vShortCut);
  Key := 0;
  btSetHotKey.Enabled := (edHotKey.Text <> '');
end;

procedure TfrmOptions.pbExamplePaint(Sender: TObject);
var
  h, I : integer;
  sText : String;
  iTextTop, iTextLeft : Integer;
  Rect : TRect;
begin
  h := pbExample.Height div 6;
  Rect.Left := 0;
  Rect.Top := 0;
  Rect.Right := pbExample.Width;
  Rect.Bottom := h;

  for I := 1 to 6 do
  with pbExample.Canvas do
  begin
    case I of
    1:
      begin
        Brush.Color := cbBackColor.Color;
        Font.Color := cbMarkColor.Color;
        sText := 'Mark';
      end;
    2:
      begin
        Brush.Color := cbBackColor2.Color;
        Font.Color := cbMarkColor.Color;
        sText := 'Mark';
      end;
    3:
      begin
        Brush.Color := cbBackColor.Color;
        Font.Color := cbTextColor.Color;
        sText := 'Text';
      end;
    4:
      begin
        Brush.Color := cbBackColor2.Color;
        Font.Color := cbTextColor.Color;
        sText := 'Text';
      end;
    5:
      begin
        Brush.Color := cbCursorColor.Color;
        Font.Color := cbCursorText.Color;
        sText := 'Cursor';
      end;
    6:
      begin
        Brush.Color := cbCursorColor.Color;
        Font.Color := cbMarkColor.Color;
        sText := 'Mark + Cursor';
      end;
    end; // case
    
    Font.Style := EdtTest1.Font.Style;
    Font.Size := EdtTest1.Font.Size;
    Font.Name := EdtTest1.Font.Name;

    iTextTop := Rect.Top + (h div 2) - (TextHeight(sText) div 2);
    iTextLeft := Rect.Left + (pbExample.Width div 2) - (TextWidth(sText) div 2);
    FillRect(Rect);
    TextOut(iTextLeft, iTextTop, sText);
    Rect.Top := Rect.Bottom;
    Rect.Bottom := h * (I + 1);
  end; // for
end;

procedure TfrmOptions.tsWCXShow(Sender: TObject);
var
  I : Integer;
  sCurrPlugin,
  sExt : String;
  PosEqual : Integer;
begin
  gIni.ReadSectionRaw('PackerPlugins', clbWCXList.Items);
  for I := 0 to clbWCXList.Count - 1 do
  begin
    sCurrPlugin := clbWCXList.Items[I];
    PosEqual := Pos('=', sCurrPlugin);
    sExt := Copy(sCurrPlugin, 1, PosEqual - 1);
    if sExt[1] = '#' then
      Delete(sExt, 1, 1);
    cbExt.Items.Add(sExt);
    if Pos('#', clbWCXList.Items[I]) = 0 then
      begin
        clbWCXList.Items[I] := Copy(sCurrPlugin, PosEqual + 1, Length(sCurrPlugin) - PosEqual);
        clbWCXList.Checked[I] := True
      end
    else
      begin
        clbWCXList.Items[I] := Copy(sCurrPlugin, PosEqual + 1, Length(sCurrPlugin) - PosEqual);
        clbWCXList.Checked[I] := False;
      end;
  end;
end;

procedure TfrmOptions.bbtnApplyClick(Sender: TObject);
var
 I,
 iIndex : Integer;
 bChecked : Boolean;
begin
  if cbExt.Text <> '' then
  if cbExt.Items.IndexOf(cbExt.Text) < 0 then
    begin
    
      if cbWCXPath.Text = '' then
        Exit;
        
      if Pos(',', cbWCXPath.Text) = 0 then
        iIndex := clbWCXList.Items.Add('0,' + cbWCXPath.Text)
      else
        iIndex := clbWCXList.Items.Add(cbWCXPath.Text);
      clbWCXList.Checked[iIndex] := True;
      cbExt.Items.Add(cbExt.Text);
    end
  else
    begin
      iIndex := cbExt.Items.IndexOf(cbExt.Text);
      bChecked := clbWCXList.Checked[iIndex];
      
      if cbWCXPath.Text = '' then
        begin
          gIni.DeleteKey('PackerPlugins', cbExt.Items[iIndex]);
          Exit;
        end;
        
      if Pos(',', cbWCXPath.Text) = 0 then
        clbWCXList.Items[iIndex] := '0,' + cbWCXPath.Text
      else
        clbWCXList.Items[iIndex] := cbWCXPath.Text;
      clbWCXList.Checked[iIndex] := bChecked;
    end;
  
  for I := 0 to clbWCXList.Count - 1 do
    begin
      if clbWCXList.Checked[I] then
        begin
          gIni.DeleteKey('PackerPlugins', '#' + cbExt.Items[I]);
          gIni.WriteString('PackerPlugins', cbExt.Items[I],  clbWCXList.Items[I])
        end
      else
        begin
          gIni.DeleteKey('PackerPlugins', cbExt.Items[I]);
          gIni.WriteString('PackerPlugins', '#' + cbExt.Items[I],  clbWCXList.Items[I]);
        end;
    end;
end;

{WFX plugins}

procedure TfrmOptions.tsWFXShow(Sender: TObject);
var
  I : Integer;
  sCurrPlugin : String;
begin
  gIni.ReadSectionRaw('FileSystemPlugins', clbWFXList.Items);
  for I := 0 to clbWFXList.Count - 1 do
  begin
    sCurrPlugin := clbWFXList.Items[I];

    if Pos('#', clbWFXList.Items[I]) = 0 then
      begin
        clbWFXList.Items[I] := Copy(sCurrPlugin, 1, Length(sCurrPlugin));
        clbWFXList.Checked[I] := True
      end
    else
      begin
        clbWFXList.Items[I] := Copy(sCurrPlugin, 2, Length(sCurrPlugin) - 1);
        clbWFXList.Checked[I] := False;
      end;
  end;
end;

procedure TfrmOptions.bbtnWFXAddClick(Sender: TObject);
var
  WFXmodule : TWFXmodule;
  sPluginName : String;
begin
  odOpenDialog.Filter := 'File system plugins (*.wfx)|*.wfx';
  if odOpenDialog.Execute then
  begin
    WFXmodule := TWFXmodule.Create;
    if WFXmodule.LoadModule(odOpenDialog.FileName)then
      sPluginName := PChar(Pointer(WFXmodule.VFSCaps)) + '=' + odOpenDialog.FileName
    else
      sPluginName := ExtractFileName(odOpenDialog.FileName) +'=' + odOpenDialog.FileName;

  clbWFXList.Items.Add(sPluginName);
  WFXModule.UnloadModule;
  WFXmodule.Free;
  end;
end;

procedure TfrmOptions.bbtnWFXApplyClick(Sender: TObject);
var
 I,
 iIndex : Integer;
 bChecked : Boolean;
begin
  gIni.EraseSection('FileSystemPlugins');
  for I := 0 to clbWFXList.Count - 1 do
    begin
      if clbWFXList.Checked[I] then
        begin
          gIni.WriteString('FileSystemPlugins', clbWFXList.Items.Names[I],  clbWFXList.Items.ValueFromIndex[I])
        end
      else
        begin
          gIni.WriteString('FileSystemPlugins', '#' + clbWFXList.Items.Names[I],  clbWFXList.Items.ValueFromIndex[I]);
        end;
    end;
end;

procedure TfrmOptions.bbtnWFXDeleteClick(Sender: TObject);
begin
 if clbWFXList.SelCount > 0 then
   clbWFXList.Items.Delete(clbWFXList.ItemIndex);
end;

procedure TfrmOptions.bbtnWFXRenameClick(Sender: TObject);
var
  iItemIndex : Integer;
  sName,
  sValue : String;
  bChecked : Boolean;
begin
  iItemIndex := clbWFXList.ItemIndex;
  if iItemIndex < 0 then exit;
  sName := clbWFXList.Items.Names[iItemIndex];
  sValue := clbWFXList.Items.ValueFromIndex[iItemIndex];
  bChecked := clbWFXList.Checked[iItemIndex]; // Save state
  clbWFXList.Items[iItemIndex] := InputBox('Double Commander', 'Rename', sName) + '=' + sValue;
  clbWFXList.Checked[iItemIndex] := bChecked; // Restore state
end;

{/WFXPlugins}

{File types category color}
procedure TfrmOptions.FillFileColorsList;
var
  sCategoryName,
  sFileMask : String;
  iColor,
  I : Integer;
  ColorFileMask : PColorFileMask;
begin
  I := 1;

  while gIni.ReadString('Colors', 'ColorFilter' + IntToStr(I), '') <> '' do
    begin
      sFileMask := gIni.ReadString('Colors', 'ColorFilter' + IntToStr(I), '');
      sCategoryName := gIni.ReadString('Colors', 'ColorFilter' + IntToStr(I) + 'Name', sFileMask);
      iColor := gIni.ReadInteger('Colors', 'ColorFilter' + IntToStr(I) + 'Color', clText);
      New(ColorFileMask);
      ColorFileMask^.sFileMask := sFileMask;
      ColorFileMask^.clMaskColor := iColor;
      lbCategories.Items.AddObject(sCategoryName,TObject(ColorFileMask));

      Inc(I);
    end; // while gIni.ReadString();
    if lbCategories.Count > 0 then
      lbCategories.ItemIndex := 0;
    lbCategoriesClick(lbCategories);
end;

procedure TfrmOptions.cbCategoryColorChange(Sender: TObject);
begin
  (Sender as TColorBox).Color := (Sender as TColorBox).Selection;
end;

procedure TfrmOptions.lbCategoriesClick(Sender: TObject);
var
  ColorFileMask : PColorFileMask;
begin

  if (lbCategories.Count > 0) and (Assigned(lbCategories.Items.Objects[lbCategories.ItemIndex])) then
    begin
      edtCategoryName.Text := lbCategories.Items[lbCategories.ItemIndex];
      ColorFileMask := PColorFileMask(lbCategories.Items.Objects[lbCategories.ItemIndex]);

      edtCategoryMask.Text := ColorFileMask^.sFileMask;
      cbCategoryColor.Color := ColorFileMask^.clMaskColor;
      cbCategoryColor.Selection := cbCategoryColor.Color;
    end
  else
    begin
      if lbCategories.Count = 0 then
        edtCategoryName.Text := ''
      else
        edtCategoryName.Text := lbCategories.Items[lbCategories.ItemIndex];
      edtCategoryMask.Text := '';
      cbCategoryColor.ItemIndex := -1;
      cbCategoryColor.Color := clWindow;
      cbCategoryColor.Selection := cbCategoryColor.Color;
    end;
end;

procedure TfrmOptions.bbtnAddCategoryClick(Sender: TObject);
var
  iIndex : Integer;
begin
  iIndex := lbCategories.Items.AddObject('', nil);
  lbCategories.ItemIndex := iIndex;
  edtCategoryName.Text := '';
  edtCategoryMask.Text := '';
  cbCategoryColor.ItemIndex := -1;
  cbCategoryColor.Color := clWindow;
end;

procedure TfrmOptions.bbtnApplyCategoryClick(Sender: TObject);
var
  ColorFileMask : PColorFileMask;
  I, iCount : Integer;
begin
  if bbtnDeleteCategory.Tag = 0 then // if we add or change category
    begin
      lbCategories.Items[lbCategories.ItemIndex] := edtCategoryName.Text;
      New(ColorFileMask);
      ColorFileMask^.sFileMask := edtCategoryMask.Text;
      ColorFileMask^.clMaskColor := cbCategoryColor.Color;
      lbCategories.Items.Objects[lbCategories.ItemIndex] := TObject(ColorFileMask);
      I := lbCategories.ItemIndex;
      gIni.WriteString('Colors', 'ColorFilter' + IntToStr(I + 1), ColorFileMask^.sFileMask);
      gIni.WriteInteger('Colors', 'ColorFilter' + IntToStr(I + 1) + 'Color', ColorFileMask^.clMaskColor);
      gIni.WriteString('Colors', 'ColorFilter' + IntToStr(I + 1) + 'Name', lbCategories.Items[I]);
    end
  else  // if we delete category
    begin
      iCount := lbCategories.Tag;
      for I := 1 to iCount do  // delete old categories
    begin
      gIni.DeleteKey('Colors', 'ColorFilter' + IntToStr(I));
      gIni.DeleteKey('Colors', 'ColorFilter' + IntToStr(I) + 'Color');
      gIni.DeleteKey('Colors', 'ColorFilter' + IntToStr(I) + 'Name');
    end;
  iCount := lbCategories.Count;
  for I := 0 to iCount - 1 do  //write new categories
    begin
      ColorFileMask := PColorFileMask(lbCategories.Items.Objects[I]);
      gIni.WriteString('Colors', 'ColorFilter' + IntToStr(I + 1), ColorFileMask^.sFileMask);
      gIni.WriteInteger('Colors', 'ColorFilter' + IntToStr(I + 1) + 'Color', ColorFileMask^.clMaskColor);
      gIni.WriteString('Colors', 'ColorFilter' + IntToStr(I + 1) + 'Name', lbCategories.Items[I]);

    end;
    end;
    bbtnDeleteCategory.Tag := 0;
end;

procedure TfrmOptions.bbtnDeleteCategoryClick(Sender: TObject);
begin
  if bbtnDeleteCategory.Tag = 0 then
    lbCategories.Tag := lbCategories.Count; // old categories count
  lbCategories.Items.Delete(lbCategories.ItemIndex);
  bbtnDeleteCategory.Tag := 1; // show that we delete category
  if lbCategories.Count > 0 then
    lbCategories.ItemIndex := 0;
  lbCategoriesClick(lbCategories);
end;

procedure TfrmOptions.btnCategoryColorClick(Sender: TObject);
begin
  if optColorDialog.Execute then
   begin
     cbCategoryColor.Text := '';
     cbCategoryColor.Color := optColorDialog.Color;
   end;
end;
{/File types category color}

procedure TfrmOptions.btClearHotKeyClick(Sender: TObject);
var vActions: TAction;
begin
  vActions := cbActions.Items.Objects[cbActions.ItemIndex] as TAction;
  vActions.ShortCut := TextToShortCut('');
  cbActions.Items[cbActions.ItemIndex] := vActions.Name+'('+ShortCutToText(vActions.ShortCut)+')';
  cbActions.Text := vActions.Name+'('+ShortCutToText(vActions.ShortCut)+')';
end;

procedure TfrmOptions.btnBackColor2Click(Sender: TObject);
begin
   if optColorDialog.Execute then
   begin
     cbBackColor2.Text := '';
     cbBackColor2.Color := optColorDialog.Color;
   end;
end;

procedure TfrmOptions.btnCursorColorClick(Sender: TObject);
begin
   if optColorDialog.Execute then
   begin
     cbCursorColor.Text := '';
     cbCursorColor.Color := optColorDialog.Color;
   end;
end;

procedure TfrmOptions.btnCursorTextClick(Sender: TObject);
begin
   if optColorDialog.Execute then
   begin
     cbCursorText.Text := '';
     cbCursorText.Color := optColorDialog.Color;
   end;
end;

procedure TfrmOptions.btnMarkColorClick(Sender: TObject);
begin
   if optColorDialog.Execute then
   begin
     cbMarkColor.Text := '';
     cbMarkColor.Color := optColorDialog.Color;
   end;
end;

procedure TfrmOptions.tvTreeViewChange(Sender: TObject; Node: TTreeNode);
begin
  //DebugLN('Page index == ' + IntToStr(Node.Index));
  nbNotebook.PageIndex := tvTreeView.Selected.ImageIndex; // temporally image index
  pnlCaption.Caption := tvTreeView.Selected.Text;
end;


initialization
 {$I fOptions.lrs}

end.
