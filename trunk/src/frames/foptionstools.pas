unit fOptionsTools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Grids, StdCtrls, EditBtn, Spin, ExtCtrls, ColorBox,
  Dialogs, fOptionsFrame, uGlobs;

type

  { TfrmOptionsTools }

  TfrmOptionsTools = class(TOptionsEditor)
    btnBackViewerColor: TButton;
    btnFontViewerColor: TButton;
    cbBackgroundColorViewerBook: TColorBox;
    cbFontColorViewerBook: TColorBox;
    cbToolsKeepTerminalOpen: TCheckBox;
    cbToolsRunInTerminal: TCheckBox;
    cbToolsUseExternalProgram: TCheckBox;
    edtToolsParameters: TEdit;
    fneToolsPath: TFileNameEdit;
    gbViewerBookMode: TGroupBox;
    gbViewerExample: TGroupBox;
    lblBackgroundColorViewerBook: TLabel;
    lblFontColorViewerBook: TLabel;
    lblNumberColumnsViewer: TLabel;
    lblToolsParameters: TLabel;
    lblToolsPath: TLabel;
    optColorDialog: TColorDialog;
    pbViewerBook: TPaintBox;
    seNumberColumnsViewer: TSpinEdit;
    stgTools: TStringGrid;
    procedure btnBackViewerColorClick(Sender: TObject);
    procedure btnFontViewerColorClick(Sender: TObject);
    procedure stgToolsSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure edtToolsParametersChange(Sender: TObject);
    procedure fneToolsPathAcceptFileName(Sender: TObject; var Value: String);
    procedure fneToolsPathChange(Sender: TObject);
    procedure cbColorBoxChange(Sender: TObject);
    procedure cbToolsKeepTerminalOpenChange(Sender: TObject);
    procedure cbToolsRunInTerminalChange(Sender: TObject);
    procedure cbToolsUseExternalProgramChange(Sender: TObject);
    procedure seNumberColumnsViewerChange(Sender: TObject);
    procedure pbViewerBookPaint(Sender: TObject);
  private
    tmpExternalTools: TExternalToolsOptions;
    FUpdatingTools: Boolean;
    procedure ShowExternalToolOptions(ExtTool: TExternalTool);
  protected
    procedure Init; override;
  public
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  end; 

implementation

{$R *.lfm}

uses
  uDCUtils, uLng;

const
  // Tools page: what tool is displayed in each row.
  ExtToolFromRow: array[0..2] of TExternalTool = (etViewer, etEditor, etDiffer);

{ TfrmOptionsTools }

procedure TfrmOptionsTools.btnBackViewerColorClick(Sender: TObject);
begin
  optColorDialog.Color:= cbBackgroundColorViewerBook.Selected;
  if optColorDialog.Execute then
  begin
    SetColorInColorBox(cbBackgroundColorViewerBook, optColorDialog.Color);
  end;
end;

procedure TfrmOptionsTools.btnFontViewerColorClick(Sender: TObject);
begin
  optColorDialog.Color:= cbFontColorViewerBook.Selected;
  if optColorDialog.Execute then
  begin
    SetColorInColorBox(cbFontColorViewerBook, optColorDialog.Color);
  end;
end;

procedure TfrmOptionsTools.stgToolsSelectCell(Sender: TObject; aCol, aRow: Integer; var CanSelect: Boolean);
begin
  aRow := aRow - stgTools.FixedRows;
  if (aRow >= 0) and (aRow < SizeOf(ExtToolFromRow)) then
  begin
    FUpdatingTools := True;
    ShowExternalToolOptions(ExtToolFromRow[aRow]);
    FUpdatingTools := False;
  end;
end;

procedure TfrmOptionsTools.edtToolsParametersChange(Sender: TObject);
var
  aRow: Integer;
begin
  if not FUpdatingTools then
  begin
    aRow := stgTools.Row - stgTools.FixedRows;
    if (aRow >= 0) and (aRow < SizeOf(ExtToolFromRow)) then
      tmpExternalTools[ExtToolFromRow[aRow]].Parameters := edtToolsParameters.Text;
  end;

end;

procedure TfrmOptionsTools.fneToolsPathAcceptFileName(Sender: TObject; var Value: String);
begin
  Value:= SetCmdDirAsEnvVar(Value);
end;

procedure TfrmOptionsTools.fneToolsPathChange(Sender: TObject);
var
  aRow: Integer;
begin
  if not FUpdatingTools then
  begin
    aRow := stgTools.Row - stgTools.FixedRows;
    if (aRow >= 0) and (aRow < SizeOf(ExtToolFromRow)) then
      // Use fneToolsPath.Caption because Filename is one letter behind when typing manually.
      tmpExternalTools[ExtToolFromRow[aRow]].Path := fneToolsPath.Caption;
  end;
end;

procedure TfrmOptionsTools.cbColorBoxChange(Sender: TObject);
begin
  pbViewerBook.Repaint;
end;

procedure TfrmOptionsTools.cbToolsKeepTerminalOpenChange(Sender: TObject);
var
  aRow: Integer;
begin
  if not FUpdatingTools then
  begin
    aRow := stgTools.Row - stgTools.FixedRows;
    if (aRow >= 0) and (aRow < SizeOf(ExtToolFromRow)) then
      tmpExternalTools[ExtToolFromRow[aRow]].KeepTerminalOpen := cbToolsKeepTerminalOpen.Checked;
  end;
end;

procedure TfrmOptionsTools.cbToolsRunInTerminalChange(Sender: TObject);
var
  aRow: Integer;
begin
  cbToolsKeepTerminalOpen.Enabled := cbToolsRunInTerminal.Checked;

  if not FUpdatingTools then
  begin
    aRow := stgTools.Row - stgTools.FixedRows;
    if (aRow >= 0) and (aRow < SizeOf(ExtToolFromRow)) then
      tmpExternalTools[ExtToolFromRow[aRow]].RunInTerminal := cbToolsRunInTerminal.Checked;
  end;
end;

procedure TfrmOptionsTools.cbToolsUseExternalProgramChange(Sender: TObject);
var
  aRow: Integer;
begin
  lblToolsPath.Enabled            := cbToolsUseExternalProgram.Checked;
  fneToolsPath.Enabled            := cbToolsUseExternalProgram.Checked;
  lblToolsParameters.Enabled      := cbToolsUseExternalProgram.Checked;
  edtToolsParameters.Enabled      := cbToolsUseExternalProgram.Checked;
  cbToolsRunInTerminal.Enabled    := cbToolsUseExternalProgram.Checked;
  cbToolsKeepTerminalOpen.Enabled := cbToolsUseExternalProgram.Checked;
  gbViewerBookMode.Enabled        := not (cbToolsUseExternalProgram.Checked);
  lblBackgroundColorViewerBook.Enabled := not (cbToolsUseExternalProgram.Checked);
  lblNumberColumnsViewer.Enabled  := not (cbToolsUseExternalProgram.Checked);
  lblFontColorViewerBook.Enabled  := not (cbToolsUseExternalProgram.Checked);
  if not FUpdatingTools then
  begin
    aRow := stgTools.Row - stgTools.FixedRows;
    if (aRow >= 0) and (aRow < SizeOf(ExtToolFromRow)) then
      tmpExternalTools[ExtToolFromRow[aRow]].Enabled := cbToolsUseExternalProgram.Checked;
  end;
end;

procedure TfrmOptionsTools.seNumberColumnsViewerChange(Sender: TObject);
begin
  pbViewerBook.Repaint;
end;

procedure TfrmOptionsTools.pbViewerBookPaint(Sender: TObject);
var
  i, numb, x, y: integer;
  sStr: String;
begin
  sStr:= 'Text';
  with pbViewerBook.Canvas do
  begin
    Font.Name := gFonts[dcfViewerBook].Name;
    Font.Size := gFonts[dcfViewerBook].Size;
    x:= TextWidth(sStr);
    y:= TextHeight(sStr);
    pbViewerBook.Width := (x + 10) * seNumberColumnsViewer.Value;
    Brush.Color := cbBackgroundColorViewerBook.Selected;
    Font.Color := cbFontColorViewerBook.Selected;
    FillRect(0, 0, pbViewerBook.Width, pbViewerBook.Height);
    for i:= 0 to seNumberColumnsViewer.Value - 1 do
    begin
      for numb:= 0 to 1 do
        TextOut(i * (x + 5) + 5, y * numb + 4, sStr);
    end;
  end;
end;

procedure TfrmOptionsTools.ShowExternalToolOptions(ExtTool: TExternalTool);
begin
  with tmpExternalTools[ExtTool] do
  begin
    cbToolsUseExternalProgram.Checked := Enabled;
    fneToolsPath.FileName             := Path;
    edtToolsParameters.Text           := Parameters;
    cbToolsRunInTerminal.Checked      := RunInTerminal;
    cbToolsKeepTerminalOpen.Checked   := KeepTerminalOpen;
  end;
  gbViewerBookMode.Visible := (ExtTool = etViewer);
end;

procedure TfrmOptionsTools.Init;
begin
  FUpdatingTools := False;

  // Disable focus rectangle on tools grid.
  stgTools.FocusRectVisible := False;
  // Localize tools names.
  stgTools.Cells[0, stgTools.FixedRows + 0] := rsToolViewer;
  stgTools.Cells[0, stgTools.FixedRows + 1] := rsToolEditor;
  stgTools.Cells[0, stgTools.FixedRows + 2] := rsToolDiffer;

  // Enable/disable tools controls.
  FUpdatingTools := True;
  cbToolsUseExternalProgramChange(nil);
  gbViewerBookMode.Enabled := not (cbToolsUseExternalProgram.Checked);
  FUpdatingTools := False;
end;

procedure TfrmOptionsTools.Load;
begin
  tmpExternalTools := gExternalTools;
  seNumberColumnsViewer.Value := gColCount;
  SetColorInColorBox(cbBackgroundColorViewerBook,gBookBackgroundColor);
  SetColorInColorBox(cbFontColorViewerBook,gBookFontColor);
end;

function TfrmOptionsTools.Save: TOptionsEditorSaveFlags;
begin
  Result := [];
  gExternalTools := tmpExternalTools;
  gColCount := seNumberColumnsViewer.Value;
  gBookBackgroundColor := cbBackgroundColorViewerBook.Selected;
  gBookFontColor := cbFontColorViewerBook.Selected;
end;

initialization
  RegisterOptionsEditor(optedTools, TfrmOptionsTools);

end.

