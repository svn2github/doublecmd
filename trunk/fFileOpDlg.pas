{
   Seksi Commander
   ----------------------------
   Implementing of progress dialog for file operation

   Licence  : GNU GPL v 2.0
   Author   : radek.cervinka@centrum.cz

   contributors:

   Copyright (C) 2008-2009  Koblov Alexander (Alexx2000@mail.ru)
}

unit fFileOpDlg;

{$mode objfpc}{$H+}

interface

uses
  LResources,
  SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, Buttons;

type

  { TfrmFileOp }

  TfrmFileOp = class(TForm)
    btnPauseStart: TBitBtn;
    pbSecond: TProgressBar;
    pbFirst: TProgressBar;
    lblFileName: TLabel;
    lblEstimated: TLabel;
    btnCancel: TBitBtn;
    procedure btnCancelClick(Sender: TObject);
    procedure btnPauseStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }

  public
    iProgress1Max:Integer;
    iProgress1Pos:Integer;
    iProgress2Max:Integer;
    iProgress2Pos:Integer;
    sEstimated:ShortString;  // bugbug, must be short string
//    sEstimated:String;
    sFileName:String;
    Thread : TThread;
    procedure UpdateDlg;
  end;

implementation

uses
   fMain, dmCommonData, uFileOpThread;

procedure TfrmFileOp.btnCancelClick(Sender: TObject);
begin
  if Assigned(Thread) then
    begin
      Thread.Terminate;
      if Thread is TFileOpThread then
        with Thread as TFileOpThread do
          if Paused then Paused:= False; 
    end;
  ModalResult := mrCancel;
end;

procedure TfrmFileOp.btnPauseStartClick(Sender: TObject);
begin
  if Assigned(Thread) then
    begin
      if Thread is TFileOpThread then
        with Thread as TFileOpThread do
        begin
          Paused:= not Paused;
          dmComData.ImageList.GetBitmap(Integer(not Paused), btnPauseStart.Glyph);
        end;
    end;
end;

procedure TfrmFileOp.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   CloseAction:= caFree;
   frmMain.frameLeft.RefreshPanel;
   frmMain.frameRight.RefreshPanel;
   frmMain.ActiveFrame.SetFocus;
end;

procedure TfrmFileOp.FormCreate(Sender: TObject);
begin
  Thread := nil;
end;

procedure TfrmFileOp.FormShow(Sender: TObject);
begin
  sEstimated:='';
  sFileName:='';
  pbFirst.Position:=0;
  pbSecond.Position:=0;
  pbFirst.Max:=1;
  pbSecond.Max:=1;
  iProgress1Max:=0;
  iProgress2Max:=0;
  iProgress1Pos:=0;
  iProgress2Pos:=0;
  if btnPauseStart.Visible then
    dmComData.ImageList.GetBitmap(1, btnPauseStart.Glyph);
end;

procedure TfrmFileOp.UpdateDlg;
var
  bP1, bP2:Boolean; // repaint if needed
  s:String;
begin
// in processor intensive task we force repaint immedially
  bP1:=False;
  bP2:=False;

  if pbFirst.Max<> iProgress1Max then
  begin
    if iProgress1Max>0 then
      pbFirst.Max:= iProgress1Max;
{    pbFirst.Max:=20000;}
    bP1:=True;
  end;
  if pbFirst.Position<> iProgress1Pos then
  begin
    if iProgress1Pos>=0 then
      pbFirst.Position:= iProgress1Pos;
    bP1:=True;
  end;

  if pbSecond.Max<> iProgress2Max then
  begin
    if iProgress2Max>0 then
      pbSecond.Max:= iProgress2Max;
    bP2:=True;
  end;
  if pbSecond.Position<> iProgress2Pos then
  begin
    if iProgress2Pos>0 then
      pbSecond.Position:= iProgress2Pos;
    bP2:=True;
  end;
  
  if bp1 then
    pbFirst.Invalidate;
  if bp2 then
    pbSecond.Invalidate;
    
  if sEstimated<>lblEstimated.Caption then
  begin
    lblEstimated.Caption:=sEstimated;
    lblEstimated.Invalidate;
  end;
  if sFileName<>lblFileName.Caption then
  begin
    lblFileName.Caption:=sFileName;
    lblFileName.Invalidate;
  end;
end;

initialization
 {$I fFileOpDlg.lrs}

end.
