{
   Double Commander
   -------------------------------------------------------------------------
   Implementing of Options dialog

   Copyright (C) 2006-2011  Koblov Alexander (Alexx2000@mail.ru)

   contributors:

   Radek Cervinka  <radek.cervinka@centrum.cz>

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
  SysUtils, Classes, Controls, Forms, Dialogs, ExtCtrls, ComCtrls, Buttons,
  fgl, uGlobs, fOptionsFrame;

type

  { TOptionsEditorView }

  TOptionsEditorView = class
    EditorClass: TOptionsEditorClass;
    Instance: TOptionsEditor;
    TreeNode: TTreeNode;
  end;

  TOptionsEditorViews = specialize TFPGObjectList<TOptionsEditorView>;

  { TfrmOptions }

  TfrmOptions = class(TForm)
    OptionsEditorsImageList: TImageList;
    Panel1: TPanel;
    Panel3: TPanel;
    pnlCaption: TPanel;
    btnOK: TBitBtn;
    btnApply: TBitBtn;
    btnCancel: TBitBtn;
    tvTreeView: TTreeView;
    splOptionsSplitter: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tvTreeViewChange(Sender: TObject; Node: TTreeNode);
  private
    FOptionsEditorList: TOptionsEditorViews;
    FOldEditor: TOptionsEditorView;
    procedure CreateOptionsEditorList;
    procedure SelectEditor(EditorClassName: String);
  public
    constructor Create(TheOwner: TComponent); override;
    constructor Create(TheOwner: TComponent; EditorClass: TOptionsEditorClass); overload;
    constructor Create(TheOwner: TComponent; EditorClassName: String); overload;
    procedure LoadConfig;
    procedure SaveConfig;
  end;

implementation

{$R *.lfm}

uses
  LCLProc, uLng, fMain;

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  // Initialize property storage
  InitPropStorage(Self);
end;

procedure TfrmOptions.btnOKClick(Sender: TObject);
begin
  // save all configuration
  SaveConfig;
  // write to config file
  SaveGlobs;
end;

procedure TfrmOptions.btnApplyClick(Sender: TObject);
begin
  // save all configuration
  SaveConfig;
  // write to config file
  SaveGlobs;
end;

procedure TfrmOptions.FormDestroy(Sender: TObject);
begin
  FreeThenNil(FOptionsEditorList);
end;

procedure TfrmOptions.CreateOptionsEditorList;
  procedure AddEditors(EditorClassList: TOptionsEditorClassList; RootNode: TTreeNode);
  var
    I: LongInt;
    aOptionsEditorClass: TOptionsEditorClass;
    aOptionsEditorView: TOptionsEditorView;
    TreeNode: TTreeNode;
    IconIndex: Integer;
  begin
    for I:= 0 to EditorClassList.Count - 1 do
    begin
      aOptionsEditorClass := EditorClassList[I].EditorClass;

      aOptionsEditorView := TOptionsEditorView.Create;
      aOptionsEditorView.EditorClass := aOptionsEditorClass;
      aOptionsEditorView.Instance    := nil;
      FOptionsEditorList.Add(aOptionsEditorView);

      TreeNode := tvTreeView.Items.AddChild(RootNode, aOptionsEditorClass.GetTitle);
      if Assigned(TreeNode) then
      begin
        IconIndex := aOptionsEditorClass.GetIconIndex;
        TreeNode.ImageIndex    := IconIndex;
        TreeNode.SelectedIndex := IconIndex;
        TreeNode.StateIndex    := IconIndex;
        TreeNode.Data          := aOptionsEditorView;
      end;

      aOptionsEditorView.TreeNode := TreeNode;

      if EditorClassList[I].HasChildren then
        AddEditors(EditorClassList[I].Children, TreeNode);
    end;
  end;
begin
  FOptionsEditorList:= TOptionsEditorViews.Create;
  AddEditors(OptionsEditorClassList, nil);
end;

procedure TfrmOptions.SelectEditor(EditorClassName: String);
var
  I: Integer;
begin
  for I := 0 to FOptionsEditorList.Count - 1 do
  begin
    if (FOptionsEditorList[I].EditorClass.ClassName = EditorClassName) then
      if Assigned(FOptionsEditorList[I].TreeNode) then
      begin
        FOptionsEditorList[I].TreeNode.Selected := True;
        Break;
      end;
  end;
end;

constructor TfrmOptions.Create(TheOwner: TComponent);
begin
  if OptionsEditorClassList.Count > 0 then
    Create(TheOwner, OptionsEditorClassList[0].EditorClass) // Select first editor.
  else
    Create(TheOwner, nil);
end;

constructor TfrmOptions.Create(TheOwner: TComponent; EditorClass: TOptionsEditorClass);
begin
  if Assigned(EditorClass) then
    Create(TheOwner, EditorClass.ClassName)
  else
    Create(TheOwner, '');
end;

constructor TfrmOptions.Create(TheOwner: TComponent; EditorClassName: String);
begin
  FOldEditor := nil;
  inherited Create(TheOwner);
  CreateOptionsEditorList;
  SelectEditor(EditorClassName);
end;

procedure TfrmOptions.tvTreeViewChange(Sender: TObject; Node: TTreeNode);
var
  SelectedEditorView: TOptionsEditorView;
begin
  SelectedEditorView := TOptionsEditorView(Node.Data);

  if Assigned(SelectedEditorView) and (FOldEditor <> SelectedEditorView) then
  begin
    if Assigned(FOldEditor) and Assigned(FOldEditor.Instance) then
      FOldEditor.Instance.Visible := False;

    // Don't create editors for groups, they don't show anything anyway.
    if not Assigned(SelectedEditorView.Instance) and not Node.HasChildren then
    begin
      if Assigned(SelectedEditorView.EditorClass) then
      begin
        SelectedEditorView.Instance := SelectedEditorView.EditorClass.Create(Self);
        SelectedEditorView.Instance.Align   := alClient;
        SelectedEditorView.Instance.Visible := True;
        SelectedEditorView.Instance.Parent  := Panel3;
        SelectedEditorView.Instance.Load;
      end;
    end;

    if Assigned(SelectedEditorView.Instance) then
      SelectedEditorView.Instance.Visible := True;

    FOldEditor := SelectedEditorView;

    pnlCaption.Caption := SelectedEditorView.EditorClass.GetTitle;
  end;
end;

procedure TfrmOptions.LoadConfig;
var
  I: LongInt;
begin
  { Load options to frames }
  for I:= 0 to FOptionsEditorList.Count - 1 do
  begin
    if Assigned(FOptionsEditorList[I].Instance) then
      FOptionsEditorList[I].Instance.Load;
  end;
end;

procedure TfrmOptions.SaveConfig;
var
  I: LongInt;
  NeedsRestart: Boolean = False;
begin
  { Save options from frames }
  for I:= 0 to FOptionsEditorList.Count - 1 do
    if Assigned(FOptionsEditorList[I].Instance) then
      if oesfNeedsRestart in FOptionsEditorList[I].Instance.Save then
        NeedsRestart := True;

  if NeedsRestart then
    MessageDlg(rsMsgRestartForApplyChanges, mtInformation, [mbOK], 0);

  frmMain.UpdateWindowView;
end;

end.
