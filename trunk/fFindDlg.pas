{
   Double Commander
   -------------------------------------------------------------------------
   Find dialog, with searching in thread

   Copyright (C) 2003-2004 Radek Cervinka (radek.cervinka@centrum.cz)
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

{ $threading on}
unit fFindDlg;
{$mode objfpc}{$H+}
{$DEFINE NOFAKETHREAD}
interface

uses
  LResources,
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, Buttons, uFindThread, Menus,
  Calendar, EditBtn, Spin, MaskEdit,udsxmodule,udsxplugin;

type

  { TfrmFindDlg }

  TfrmFindDlg = class(TForm)
    btnClose: TButton;
    btnStart: TButton;
    btnStop: TButton;
    btnView: TButton;
    btnNewSearch: TButton;
    btnGoToPath: TButton;
    btnWorkWithFound: TButton;
    cbFindInFile: TCheckBox;
    cbNoThisText: TCheckBox;
    cbDateFrom: TCheckBox;
    cbNotOlderThan: TCheckBox;
    cbFileSizeFrom: TCheckBox;
    cbDateTo: TCheckBox;
    cbFileSizeTo: TCheckBox;
    cbReplaceText: TCheckBox;
    cbTimeFrom: TCheckBox;
    cbTimeTo: TCheckBox;
    cbDelayUnit: TComboBox;
    cbUnitOfMeasure: TComboBox;
    cbDirectory: TCheckBox;
    cbSymLink: TCheckBox;
    cbMore: TCheckBox;
    cbAttrib: TCheckBox;
    cbUsePlugin: TCheckBox;
    cbbSPlugins: TComboBox;
    cbEncoding: TComboBox;
    deDateFrom: TDateEdit;
    deDateTo: TDateEdit;
    edtFindPathStart: TDirectoryEdit;
    edtAttrib: TEdit;
    edtTimeFrom: TEdit;
    edtTimeTo: TEdit;
    edtReplaceText: TEdit;
    gbAttributes: TGroupBox;
    lblEncoding: TLabel;
    lblInfo: TLabel;
    Panel4: TPanel;
    seNotOlderThan: TSpinEdit;
    seFileSizeFrom: TSpinEdit;
    seFileSizeTo: TSpinEdit;
    Splitter1: TSplitter;
    Panel2: TPanel;
    pgcSearch: TPageControl;
    tsStandard: TTabSheet;
    lblFindPathStart: TLabel;
    lblFindFileMask: TLabel;
    cmbFindFileMask: TComboBox;
    gbFindData: TGroupBox;
    cbCaseSens: TCheckBox;
    edtFindText: TEdit;
    tsAdvanced: TTabSheet;
    Panel1: TPanel;
    Panel3: TPanel;
    lsFoundedFiles: TListBox;
    lblStatus: TLabel;
    lblCurrent: TLabel;
    PopupMenuFind: TPopupMenu;
    miShowInViewer: TMenuItem;
    procedure cbUsePluginChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnGoToPathClick(Sender: TObject);
    procedure btnNewSearchClick(Sender: TObject);
    procedure btnSelDirClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnViewClick(Sender: TObject);
    procedure btnWorkWithFoundClick(Sender: TObject);
    procedure cbAttribChange(Sender: TObject);
    procedure cbDateFromChange(Sender: TObject);
    procedure cbDateToChange(Sender: TObject);
    procedure cbDirectoryChange(Sender: TObject);
    procedure cbFileSizeFromChange(Sender: TObject);
    procedure cbFileSizeToChange(Sender: TObject);
    procedure cbMoreChange(Sender: TObject);
    procedure cbNotOlderThanChange(Sender: TObject);
    procedure cbReplaceTextChange(Sender: TObject);
    procedure cbSymLinkChange(Sender: TObject);
    procedure cbTimeFromChange(Sender: TObject);
    procedure cbTimeToChange(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnCloseClick(Sender: TObject);
    procedure cbFindInFileClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure frmFindDlgClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure frmFindDlgShow(Sender: TObject);
    procedure lsFoundedFilesDblClick(Sender: TObject);
    procedure meTimeChange(Sender: TObject);
    procedure miShowInViewerClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    FFindThread:TFindThread;
  public
    { Public declarations }
    DSL:TDSXModuleList;
    procedure ThreadTerminate(Sender:TObject);
  end;

var
  frmFindDlg: TfrmFindDlg =nil;

procedure ShowFindDlg(const sActPath:String);

implementation

uses
  LCLProc, LConvEncoding, fViewer, uLng, uGlobs, uShowForm, fMain, uTypes, uFileOp, uFindEx, uOSUtils;

procedure SAddFileProc(PlugNr:integer; FoundFile:pchar); stdcall;
var s:string;
begin
s:=string(FoundFile);
  if s='' then
    begin
      frmFindDlg.ThreadTerminate(nil);
    end
  else
    begin
     frmFindDlg.lsFoundedFiles.Items.Add(s);
     DebugLn('fFindLlg: '+S);
     Application.ProcessMessages;
    end;

end;

procedure SUpdateStatusProc(PlugNr:integer; CurrentFile:pchar; FilesScaned:integer); stdcall;
begin
  frmFindDlg.lblStatus.Caption:=Format(rsFindScaned,[FilesScaned]);
  frmFindDlg.lblCurrent.Caption:=string(CurrentFile);
  Application.ProcessMessages;
end;

procedure ShowFindDlg(const sActPath:String);
begin
  if not assigned (frmFindDlg) then
    frmFindDlg:=TfrmFindDlg.Create(nil);
  frmFindDlg.edtFindPathStart.Text := sActPath;
  frmFindDlg.Show;
  frmFindDlg.BringToFront;
  frmFindDlg.cmbFindFileMask.SetFocus;

end;

procedure TfrmFindDlg.FormCreate(Sender: TObject);
begin
  // load language
  edtFindPathStart.DialogTitle:= rsFindWhereBeg;
  FFindThread:= nil;
  edtFindPathStart.Text:= mbGetCurrentDir;
  lblCurrent.Caption:= '';
  lblStatus.Caption:= '';
  Panel1.Visible:= False;
  Splitter1.Visible:= False;
  Height:= Panel2.Height + 22;
  DSL:= TDSXModuleList.Create;
  DSL.Load(gini);
  // fill encoding combobox
  cbEncoding.Clear;
  GetSupportedEncodings(cbEncoding.Items);
  cbEncoding.ItemIndex:= cbEncoding.Items.IndexOf(EncodingAnsi);
end;

procedure TfrmFindDlg.cbUsePluginChange(Sender: TObject);
begin
  cbbSPlugins.Enabled:=cbUsePlugin.Checked;
end;


procedure TfrmFindDlg.btnSelDirClick(Sender: TObject);
var
  s:String;
begin
  s:=edtFindPathStart.Text;
  if not mbDirectoryExists(s) then s:='';
  SelectDirectory(rsFindWhereBeg,'',s, False);
  edtFindPathStart.Text:=s;
end;

procedure TfrmFindDlg.btnNewSearchClick(Sender: TObject);
begin
  btnStopClick(Sender);
  Panel1.Visible := False;
  Splitter1.Visible := False;
  Height := Panel2.Height + 22;
end;

procedure TfrmFindDlg.btnGoToPathClick(Sender: TObject);
begin
  frmMain.ActiveFrame.pnlFile.ActiveDir := ExtractFilePath(lsFoundedFiles.Items[lsFoundedFiles.ItemIndex]);
  frmMain.ActiveFrame.pnlFile.LastActive:= ExtractFileName(lsFoundedFiles.Items[lsFoundedFiles.ItemIndex]);
  frmMain.ActiveFrame.pnlFile.LoadPanel;
  Close;
end;

procedure TfrmFindDlg.btnStartClick(Sender: TObject);
var
  dtTime : TDateTime;
  sr:TSearchAttrRecord;
begin
  if cmbFindFileMask.Items.IndexOf(cmbFindFileMask.Text) < 0 then
    cmbFindFileMask.Items.Add(cmbFindFileMask.Text);
            
  if not mbDirectoryExists(edtFindPathStart.Text) then
  begin
    ShowMessage(Format(rsFindDirNoEx,[edtFindPathStart.Text]));
    Exit;
  end;
  
  Panel1.Visible := True;
  Splitter1.Visible := True;
  Height := (Screen.Height * 4) div 5;
  
  lsFoundedFiles.Items.Clear;
  btnStop.Enabled:=True;
  btnStart.Enabled:=False;
  btnClose.Enabled:=False;
  FFindThread:=TFindThread.Create;
  with FFindThread do
  begin
    FilterMask:= cmbFindFileMask.Text;
    PathStart:= edtFindPathStart.Text;
    Items:= lsFoundedFiles.Items;
    IsNoThisText:= cbNoThisText.Checked;
    FindInFiles:= cbFindInFile.Checked;
    FindData:= ConvertEncoding(edtFindText.Text, EncodingUTF8, cbEncoding.Text);
    CaseSensitive:= cbCaseSens.Checked;
    ReplaceInFiles:= cbReplaceText.Checked;
    ReplaceData:= edtReplaceText.Text;
    (* Date search *)
    if cbDateFrom.Checked then
       begin
         IsDateFrom := True;
         DateTimeFrom := deDateFrom.Date;
       end;
    if cbDateTo.Checked then
       begin
         IsDateTo := True;
         DateTimeTo := deDateTo.Date;
       end;
    (* Time search *)
    if cbTimeFrom.Checked then
       begin
         IsTimeFrom := True;
         dtTime := 0;
         if TryStrToTime(edtTimeFrom.Text, dtTime) then
           DateTimeFrom := DateTimeFrom + dtTime;
       end;
       
    if cbTimeTo.Checked then
       begin
         IsTimeTo := True;
         dtTime := 0;
         if TryStrToTime(edtTimeTo.Text, dtTime) then
           DateTimeTo := DateTimeTo +  dtTime;
       end;
    (* Not Older Than *)
     if cbNotOlderThan.Checked then
       begin
         case cbDelayUnit.ItemIndex of
           0:  //Minute(s)
             begin
               IsTimeFrom := True;
               IsDateFrom := True;
               DateTimeFrom := Now -  0.0006945 * StrToInt(seNotOlderThan.Text);
             end;
           1:  //Hour(s)
             begin
               IsTimeFrom := True;
               IsDateFrom := True;
               DateTimeFrom := Now -  0.0416667 * StrToInt(seNotOlderThan.Text);
             end;
           2:  //Day(s)
             begin
               IsDateFrom := True;
               DateTimeFrom := Now - 1 * StrToInt(seNotOlderThan.Text);
             end;
           3:  //Week(s)
             begin
               IsDateFrom := True;
               DateTimeFrom := Now - 7 * StrToInt(seNotOlderThan.Text);
             end;
           4:  //Month(s)
             begin
               IsDateFrom := True;
               DateTimeFrom := Now - 31 * StrToInt(seNotOlderThan.Text);
             end;
           5:  //Year(s)
             begin
               IsDateFrom := True;
               DateTimeFrom := Now - 365 * StrToInt(seNotOlderThan.Text);
             end;
         end;
       end;

                
    (* File size search *)
     if cbFileSizeFrom.Checked then
       begin
         IsFileSizeFrom := True;
         case cbUnitOfMeasure.ItemIndex of
           0:
             FileSizeFrom := seFileSizeFrom.Value;   //Byte
           1:
             FileSizeFrom := seFileSizeFrom.Value * 1024; //KiloByte
           2:
             FileSizeFrom := seFileSizeFrom.Value * 1048576; //MegaByte
           3:
             FileSizeFrom := seFileSizeFrom.Value * 1073741824; //GigaByte
         end;
       end;
    if cbFileSizeTo.Checked then
       begin
         IsFileSizeTo := True;
         case cbUnitOfMeasure.ItemIndex of
           0:
             FileSizeTo := seFileSizeTo.Value;   //Byte
           1:
             FileSizeTo := seFileSizeTo.Value * 1024; //KiloByte
           2:
             FileSizeTo := seFileSizeTo.Value * 1048576; //MegaByte
           3:
             FileSizeTo := seFileSizeTo.Value * 1073741824; //GigaByte
         end;
       end;
    (* File attributes *)
    if cbAttrib.Checked then
      begin
        Attributes := 0;

        if cbDirectory.Checked then
          Attributes := Attributes or faDirectory;

        DebugLn('Attributes == ' + IntToStr(Attributes));

        if cbSymLink.Checked then
          Attributes := Attributes or uOSUtils.faSymLink;

        if Attributes = 0 then
          Attributes := faAnyFile;

        if cbMore.Checked then
          AttribStr := edtAttrib.Text;

      end;
    Status:=lblStatus;
    Current:=lblCurrent;

     //---------------------
     if (cbUsePlugin.Checked) and (cbbSPlugins.ItemIndex<>-1) then
       begin
         FillSearchRecord(sr);
         DSL:=TDSXModuleList.Create;
         DSL.Load(gini);
         DSL.LoadModule(cbbSPlugins.ItemIndex);
         FillSearchRecord(sr);
         DSL.GetDSXModule(cbbSPlugins.ItemIndex).CallInit(@SAddFileProc,@SUpdateStatusProc);
         DSL.GetDSXModule(cbbSPlugins.ItemIndex).CallStartSearch(PChar(edtFindPathStart.Text),sr);
         
       end
    //end
    else
      begin



      DebugLn('thread a');
  {$IFDEF NOFAKETHREAD}
      FreeOnTerminate:=False;
      OnTerminate:=@ThreadTerminate; // napojime udalost na obsluhu tlacitka
      DebugLn('thread a1');
      Resume;
{$ELSE}
    Resume;
    //WaitFor;      //remove
  //ThreadTerminate(self); //remove if thread is Ok
{$ENDIF}
  end;
end;

    DebugLn('thread a2');

end;

procedure TfrmFindDlg.btnViewClick(Sender: TObject);
begin
  ShowViewerByGlob(lsFoundedFiles.Items[lsFoundedFiles.ItemIndex]);
end;

(* Not working full now *)

procedure TfrmFindDlg.btnWorkWithFoundClick(Sender: TObject);
var
  I, Count : Integer;
  pfri:PFileRecItem;
  sr : TSearchRec;
begin
  Count := lsFoundedFiles.Items.Count - 1;
  frmMain.ActiveFrame.pnlFile.FileList.Clear;
  New(pfri);
  with pfri^ do
  for I := 0 to Count do
    begin
      sNameNoExt := lsFoundedFiles.Items[I];
      sName := sNameNoExt;
      FindFirstEx(sNameNoExt, faAnyFile, sr);
      sExt := ExtractFileExt(sNameNoExt);
      iSize := sr.Size;
      sTime := DateTimeToStr(Trunc(FileDateToDateTime(sr.Time)));
      iMode := sr.Attr;
      sModeStr := AttrToStr(sr.Attr);
      bLinkIsDir:=False;
      bSelected:=False;
      frmMain.ActiveFrame.pnlFile.FileList.AddItem(pfri);
    end;
  Dispose(pfri);
  frmMain.ActiveFrame.pnlFile.FileList.UpdateFileInformation(pmDirectory);
  frmMain.ActiveFrame.pnlFile.Sort;
  frmMain.ActiveFrame.pnlFile.ActiveDir := '';
  Close;
end;

procedure TfrmFindDlg.cbAttribChange(Sender: TObject);
begin
  gbAttributes.Enabled := cbAttrib.Checked;
end;

procedure TfrmFindDlg.cbDateFromChange(Sender: TObject);
begin
  deDateFrom.Enabled := cbDateFrom.Checked;
end;

procedure TfrmFindDlg.cbDateToChange(Sender: TObject);
begin
  deDateTo.Enabled := cbDateTo.Checked;
end;

procedure TfrmFindDlg.cbDirectoryChange(Sender: TObject);
begin
end;

procedure TfrmFindDlg.cbFileSizeFromChange(Sender: TObject);
begin
  seFileSizeFrom.Enabled := cbFileSizeFrom.Checked;

  if seFileSizeFrom.Enabled or seFileSizeTo.Enabled then
    cbUnitOfMeasure.Enabled := True
  else
    cbUnitOfMeasure.Enabled := False;
end;

procedure TfrmFindDlg.cbFileSizeToChange(Sender: TObject);
begin
  seFileSizeTo.Enabled := cbFileSizeTo.Checked;

  if seFileSizeFrom.Enabled or seFileSizeTo.Enabled then
    cbUnitOfMeasure.Enabled := True
  else
    cbUnitOfMeasure.Enabled := False;
end;

procedure TfrmFindDlg.cbMoreChange(Sender: TObject);
begin
  edtAttrib.Enabled := cbMore.Checked;
end;

procedure TfrmFindDlg.cbNotOlderThanChange(Sender: TObject);
begin
  seNotOlderThan.Enabled := cbNotOlderThan.Checked;
  cbDelayUnit.Enabled := cbNotOlderThan.Checked;
end;

procedure TfrmFindDlg.cbReplaceTextChange(Sender: TObject);
begin
  edtReplaceText.Enabled := cbReplaceText.Checked;
  cbNoThisText.Checked := False;
  cbNoThisText.Enabled := not cbReplaceText.Checked;
end;

procedure TfrmFindDlg.cbSymLinkChange(Sender: TObject);
begin

end;

procedure TfrmFindDlg.cbTimeFromChange(Sender: TObject);
var
  sTime : String;
begin
  edtTimeFrom.Enabled := cbTimeFrom.Checked;
  DateTimeToString(sTime, 'hh:mm:ss', Time);
  edtTimeFrom.Text := sTime;
end;

procedure TfrmFindDlg.cbTimeToChange(Sender: TObject);
var
  sTime : String;
begin
  edtTimeTo.Enabled := cbTimeTo.Checked;
  DateTimeToString(sTime, 'hh:mm:ss', Time);
  edtTimeTo.Text := sTime;
end;

procedure TfrmFindDlg.ThreadTerminate(Sender:TObject);
begin
  DebugLn('thread terminate end');
{  FFindThread.Terminate;
  FFindThread.WaitFor;}
  btnStop.Enabled:=False;
  btnStart.Enabled:=True;
  btnClose.Enabled:=True;  
  FFindThread:=nil;
end;

procedure TfrmFindDlg.btnStopClick(Sender: TObject);
begin
  if (cbUsePlugin.Checked) and (cbbSPlugins.ItemIndex<>-1) then
    begin
      DSL.GetDSXModule(cbbSPlugins.ItemIndex).CallStopSearch;
      DSL.GetDSXModule(cbbSPlugins.ItemIndex).CallFinalize;
      ThreadTerminate(nil);
    end;
    
  if not assigned(FFindThread) then Exit;
  FFindThread.Terminate;
//  FFindThread.WaitFor;
//  FFindThread:=nil;
end;

procedure TfrmFindDlg.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
  CanClose:= not Assigned(FFindThread);
end;

procedure TfrmFindDlg.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmFindDlg.cbFindInFileClick(Sender: TObject);
begin
  gbFindData.Enabled:=cbFindInFile.Checked;
end;

procedure TfrmFindDlg.FormDestroy(Sender: TObject);
begin
    FreeAndNil(DSL);
end;

procedure TfrmFindDlg.frmFindDlgClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
//  CloseAction:=caFree;
  Panel1.Visible := False;
  Height := Panel2.Height + 22;
  glsMaskHistory.Assign(cmbFindFileMask.Items);
end;

procedure TfrmFindDlg.frmFindDlgShow(Sender: TObject);
var i:integer;
begin
  if cmbFindFileMask.Visible then
    cmbFindFileMask.SelectAll;
  //cmbFindFileMask.SetFocus;
  cmbFindFileMask.Items.Assign(glsMaskHistory);
  for i:=0 to DSL.Count-1 do
    begin
      cbbSPlugins.AddItem(DSL.GetDSXModule(i).Name+' ('+DSL.GetDSXModule(i).Descr+' )',nil);
    end;
  if (cbbSPlugins.Items.Count>0) then cbbSPlugins.ItemIndex:=0;
end;

procedure TfrmFindDlg.lsFoundedFilesDblClick(Sender: TObject);
begin
  miShowInViewer.Click;
end;

procedure TfrmFindDlg.meTimeChange(Sender: TObject);
var
  ME : TMaskEdit;
begin
  ME := TMaskEdit(Sender);

  if StrToIntDef(Copy(ME.EditText, 1, 2), 24) > 23 then
    ME.EditText := '00' + Copy(ME.EditText, 3, 6);

  if StrToIntDef(Copy(ME.EditText, 4, 2), 60) > 59 then
    ME.EditText := Copy(ME.EditText, 1, 3) + '00' + Copy(ME.EditText, 6, 3);

  if StrToIntDef(Copy(ME.EditText, 7, 2), 60) > 59 then
    ME.EditText := Copy(ME.EditText, 1, 6) + '00';

end;


procedure TfrmFindDlg.miShowInViewerClick(Sender: TObject);
var
  sl:TStringList;
  i:Integer;
begin
  if lsFoundedFiles.ItemIndex=-1 then Exit;

  sl:=TStringList.Create;
  try
    for i:=0 to lsFoundedFiles.Items.Count-1 do
      if lsFoundedFiles.Selected[i] then
        sl.Add(lsFoundedFiles.Items[i]);
    ShowViewer(sl);
  finally
    sl.Free;
  end;
end;

procedure TfrmFindDlg.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if key=#13 then
  begin
    if btnStart.Enabled then
      btnStart.Click
    else
      btnStop.Click;
  end;
  if key=#27 then
  begin
    Key:=#0;
    Close;
  end;
end;

initialization
 {$I fFindDlg.lrs}
finalization
  if assigned(frmFindDlg) then
    FreeAndNil(frmFindDlg);
end.
