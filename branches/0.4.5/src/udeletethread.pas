﻿{
   Seksi Commander
   ----------------------------
   Implementing of Delete thread

   Licence  : GNU GPL v 2.0
   Author   : radek.cervinka@centrum.cz

   contributors:

   Copyright (C) 2006-2009  Koblov Alexander (Alexx2000@mail.ru)
}

unit uDeleteThread;

{$mode objfpc}{$H+}

interface

uses
  uFileOpThread, uFileList, uTypes, SysUtils, LCLProc;

type

  { TDeleteThread }

  TDeleteThread = class(TFileOpThread)
  private
   // 30.04.2009 - поле, показывающее удаление в корзину
    FRecycle : boolean;
  protected
    procedure MainExecute; override;
    function DeleteFile(fr:PFileRecItem):Boolean;
    function GetCaptionLng: String; override;
    function CheckFile(FileRecItem: PFileRecItem): Boolean; override;
    function GetFileOpDlgLook: TFileOpDlgLook; override;
 public
    constructor Create(aFileList:TFileList); override;
    // 30.04.2009 - свойство для удаления в корзину
    property Recycle : boolean read FRecycle write FRecycle default false;
  end;

implementation
uses
  uLng, uGlobs, uLog, uOSUtils;

constructor TDeleteThread.Create(aFileList: TFileList);
begin
  inherited Create(aFileList);
  FSymLinkAll:= True;
end;

procedure TDeleteThread.MainExecute;
var
  pr: PFileRecItem;
  xIndex: Integer;
  iCopied: Int64;
  FileList: TFileList;
begin
  iCopied:= 0;
  FFileOpDlg.iProgress1Max:= 1;
  FFileOpDlg.iProgress1Pos:= 1; // in delete use only 1 progress
  Synchronize(@FFileOpDlg.UpdateDlg);
  
  if FRecycle then
    FileList:= FFileList
  else
    FileList:= NewFileList;

  for xIndex:= FileList.Count - 1 downto 0 do // deleting
  begin
    if Terminated then Exit;
    if Paused then Suspend;
    pr:= FileList.GetItem(xIndex);
    FFileOpDlg.sFileNameFrom:= pr^.sName;
    Synchronize(@FFileOpDlg.UpdateDlg);
    Inc(iCopied, pr^.iSize);
    EstimateTime(iCopied);
    DeleteFile(pr);
    FFileOpDlg.iProgress2Pos:= ((FileList.Count - xIndex) * 100) div FileList.Count;
    Synchronize(@FFileOpDlg.UpdateDlg);
  end;
end;


function TDeleteThread.DeleteFile (fr:PFileRecItem):Boolean;
begin
  try
  If (FRecycle = false) then
   begin
    if FPS_ISDIR(fr^.iMode) then // directory
      begin
        Result := mbRemoveDir(fr^.sName);
        // write log
        if Result then
          begin
            if (log_dir_op in gLogOptions) and (log_success in gLogOptions) then
              logWrite(Self, Format(rsMsgLogSuccess+rsMsgLogRmDir, [fr^.sName]), lmtSuccess);
          end
        else
          begin
            if (log_dir_op in gLogOptions) and (log_errors in gLogOptions) then
              logWrite(Self, Format(rsMsgLogError+rsMsgLogRmDir, [fr^.sName]), lmtError);
          end;
      end
    else
      begin // files and other stuff
        Result := mbDeleteFile(fr^.sName);
        // write log
        if Result then
          begin
            if (log_delete in gLogOptions) and (log_success in gLogOptions) then
              logWrite(Self, Format(rsMsgLogSuccess+rsMsgLogDelete, [fr^.sName]), lmtSuccess);
          end
        else
          begin
            if (log_delete in gLogOptions) and (log_errors in gLogOptions) then
              logWrite(Self, Format(rsMsgLogError+rsMsgLogDelete, [fr^.sName]), lmtError);
          end;
      end;
   end
  else
   begin // 30.04.2009 - Вызов удаления в корзину. Файлы и папки удаляются одной функцией.
    Result := mbDeleteToTrash(fr^.sName);
    // write log
    if Result then
     begin
      if (log_delete in gLogOptions) and (log_success in gLogOptions) then
        logWrite(Self, Format(rsMsgLogSuccess+rsMsgLogDelete, [fr^.sName]), lmtSuccess);
     end
    else
     begin
      if (log_delete in gLogOptions) and (log_errors in gLogOptions) then
        logWrite(Self, Format(rsMsgLogError+rsMsgLogDelete, [fr^.sName]), lmtError);
     end;
   end;
    // process comments if need
    if Result and gProcessComments and Assigned(FDescr) then
      FDescr.DeleteDescription(fr^.sName);
  except
    DebugLN('Can not delete ', fr^.sName);
  end;
end;

function TDeleteThread.GetCaptionLng:String;
begin
  Result:= rsDlgDel;
end;

function TDeleteThread.CheckFile(FileRecItem: PFileRecItem): Boolean;
begin
  Result:= inherited CheckFile(FileRecItem);
  if FileIsReadOnly(FileRecItem^.iMode) then
    mbFileSetReadOnly(FileRecItem^.sName, False);
end;

function TDeleteThread.GetFileOpDlgLook: TFileOpDlgLook;
begin
  Result:= [fodl_from_lbl, fodl_second_pb];
end;

end.
