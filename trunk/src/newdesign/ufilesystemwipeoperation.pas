{
   Double Commander
   -------------------------------------------------------------------------
   This module implements a secure erase of disk media as per the
   Department of Defense clearing and sanitizing standard: DOD 5220.22-M

   The standard states that hard disk media is erased by
   overwriting with a character, then the character's complement,
   and then a random character. Note that the standard specicically
   states that this method is not suitable for TOP SECRET information.
   TOP SECRET data sanatizing is only achievable by a Type 1 or 2
   degauss of the disk, or by disintegrating, incinerating,
   pulverizing, shreding, or melting the disk.

   Copyright (C) 2008-2009  Koblov Alexander (Alexx2000@mail.ru)

   Based on:

     WP - wipes files in a secure way.
     version 3.2 - By Uri Fridman. urifrid@yahoo.com
     www.geocities.com/urifrid

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

unit uFileSystemWipeOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceWipeOperation,
  uFileSource,
  uFileSourceOperationOptions,
  uFileSourceOperationUI,
  uFile,
  uFileSystemFile,
  uDescr, uGlobs, uLog;

type

  { TFileSystemWipeOperation }

  TFileSystemWipeOperation = class(TFileSourceWipeOperation)
  private
    FEverythingOK: Boolean;
    FErrors,
    files,
    directories: Integer;
    buffer: array [0..4095] of Byte;
    procedure Fill(chr: Integer);
    procedure SecureDelete(pass: Integer; FileName: String);
    procedure WipeDir(dir: string);
    procedure WipeFile(filename: String);
  private
    FFullFilesTreeToDelete: TFileSystemFiles;  // source files including all files/dirs in subdirectories
    FStatistics: TFileSourceWipeOperationStatistics; // local copy of statistics
    FDescription: TDescription;

    // Options.
    FSymLinkOption: TFileSourceOperationOptionSymLink;
    FSkipErrors: Boolean;
    FDeleteReadOnly: TFileSourceOperationOptionGeneral;

  protected
    procedure Wipe(aFile: TFileSystemFile);
    function ShowError(sMessage: String): TFileSourceOperationUIResponse;
    procedure LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);

  public
    constructor Create(aTargetFileSource: IFileSource;
                       var theFilesToWipe: TFiles); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;
  end;

implementation

uses
  uOSUtils, uLng, uFindEx, uClassesEx, uFileSystemUtil, LCLProc, uTypes;

constructor TFileSystemWipeOperation.Create(aTargetFileSource: IFileSource;
                                            var theFilesToWipe: TFiles);
begin
  FSymLinkOption := fsooslNone;
  FSkipErrors := False;
  FDeleteReadOnly := fsoogNone;
  FFullFilesTreeToDelete := nil;

  if gProcessComments then
    FDescription := TDescription.Create(True)
  else
    FDescription := nil;

  inherited Create(aTargetFileSource, theFilesToWipe);
end;

destructor TFileSystemWipeOperation.Destroy;
begin
  inherited Destroy;

  if Assigned(FDescription) then
  begin
    FDescription.SaveDescription;
    FreeAndNil(FDescription);
  end;

  if Assigned(FFullFilesTreeToDelete) then
    FreeAndNil(FFullFilesTreeToDelete);
end;

procedure TFileSystemWipeOperation.Initialize;
begin
  // Get initialized statistics; then we change only what is needed.
  FStatistics := RetrieveStatistics;

  FillAndCount(FilesToWipe as TFileSystemFiles, True,
               FFullFilesTreeToDelete,
               FStatistics.TotalFiles,
               FStatistics.TotalBytes);     // gets full list of files (recursive)

  if gProcessComments then
    FDescription.Clear;
end;

procedure TFileSystemWipeOperation.MainExecute;
var
  aFile: TFileSystemFile;
  CurrentFileIndex: Integer;
  OldDoneBytes: Int64; // for if there was an error
begin
  for CurrentFileIndex := FFullFilesTreeToDelete.Count - 1 downto 0 do
  begin
    aFile := FFullFilesTreeToDelete[CurrentFileIndex] as TFileSystemFile;

    FStatistics.CurrentFile := aFile.Path + aFile.Name;
    UpdateStatistics(FStatistics);

    // If there will be an error in Wipe the DoneBytes value
    // will be inconsistent, so remember it here.
    OldDoneBytes := FStatistics.DoneBytes;

    Wipe(aFile);

    with FStatistics do
    begin
      DoneFiles := DoneFiles + 1;
      // Correct statistics if file not correctly processed.
      if DoneBytes < (OldDoneBytes + aFile.Size) then
        DoneBytes := OldDoneBytes + aFile.Size;

      UpdateStatistics(FStatistics);
    end;

    CheckOperationState;
  end;
end;

procedure TFileSystemWipeOperation.Finalize;
begin
end;

//fill buffer with characters
//0 = with 0, 1 = with 1 and 2 = random
procedure TFileSystemWipeOperation.Fill(chr: Integer);
var i: integer;
begin
   if chr=0 then
   begin
    for i := Low(buffer) to High(buffer) do
      buffer[i] := 0;
      exit;
   end;

   if chr=1 then
   begin
    for i := Low(buffer) to High(buffer) do
      buffer[i] := 1;
      exit;
   end;

   if chr=2 then
   begin
    for i := Low(buffer) to High(buffer) do
      buffer[i] := Random(256);
      exit;
   end;
end;

procedure TFileSystemWipeOperation.SecureDelete(pass: Integer; FileName: String);
var
  i, j, n: Integer;
  max: Int64;
  fs: TFileStreamEx;
  sTempFileName: String; // renames file to delete
begin
  sTempFileName:= 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.aaaaaaa';
  if mbFileAccess(FileName, fmOpenWrite) then
    begin
      sTempFileName:= ExtractFilePath(FileName) + sTempFileName;
      if mbRenameFile(FileName, sTempFileName) then
        begin
          FileName:= sTempFileName;
        end
      else
        begin
          ShowError(Format(rsMsgErrRename, [FileName, sTempFileName]));
          Exit;
        end;
    end
  else
    begin
      ShowError(rsMsgErrEOpen + #32 + FileName);
      Exit;
    end;

  try
    fs := TFilestreamEx.Create(FileName, fmOpenReadWrite or fmShareExclusive);
    for i := 1 to pass do
    begin
      //---------------Progress--------------
      CheckOperationState; // check pause and stop
      FStatistics.CurrentFileTotalBytes:= fs.Size * 3;
      FStatistics.CurrentFileDoneBytes:= 0;
      UpdateStatistics(FStatistics);
      //-------------------------------------
      for j:= 0 to 2 do
      begin
        fill(j);
        max := fs.Size;
        fs.Position := 0;
        while max > 0 do
        begin
          if max > SizeOf(buffer) then
             n := SizeOf(buffer)
          else
            n := max;
          fs.Write(Buffer, n);
          max := max - n;
          //---------------Progress--------------
          with FStatistics do
          begin
            Inc(CurrentFileDoneBytes, n);
            Inc(DoneBytes, n div (3 * pass));
            UpdateStatistics(FStatistics);
            CheckOperationState; // check pause and stop
          end;
          //-------------------------------------
        end;
        FileFlush(fs.Handle);
        CheckOperationState; // check pause and stop
      end;
    end;
    FileTruncate(fs.Handle, 0);
    FreeThenNil(fs);
  except
    on E: Exception do
    begin
      FreeThenNil(fs);
      ShowError(E.Message);
      Exit;
    end;
  end;

  if not mbDeleteFile(FileName) then
    begin
      ShowError(Format(rsMsgNotDelete, [FileName]));
      Exit;
    end;
  files:= files+1;
  DebugLn('OK');
  FEverythingOK:= True;
end;

procedure TFileSystemWipeOperation.WipeDir(dir: string);
var
  Search: TSearchRecEx;
  ok: Integer;
  sPath: String;
begin
  sPath:= IncludeTrailingPathDelimiter(dir);
  ok:= FindFirstEx(sPath + '*', faAnyFile, Search);
  while ok = 0 do  begin
    if ((Search.Name <> '.' ) and (Search.Name <> '..')) then
      begin
        //remove read-only attr
        try
          if not mbFileSetReadOnly(sPath + Search.Name, False) then
            DebugLn('wp: FAILED when trying to remove read-only attr on '+ sPath + Search.Name);
        except
          DebugLn('wp: FAILED when trying to remove read-only attr on '+ sPath + Search.Name);
        end;

        if fpS_ISDIR(Search.Attr) then
          begin
            DebugLn('Entering '+ sPath + Search.Name);
            WipeDir(sPath + Search.Name);
          end
        else
          begin
            DebugLn('Wiping '+ sPath + Search.Name);
            SecureDelete(gWipePassNumber, sPath + Search.Name);
          end;
      end;
    ok:= FindNextEx(Search);
  end;
  FindCloseEx(Search);
  try
    if FEverythingOK then
      begin
        DebugLn('Wiping ' + dir);

        if not mbRemoveDir(dir) then
          begin
            DebugLn('wp: error wiping directory ' + dir);
            // write log -------------------------------------------------------------------
            LogMessage(Format(rsMsgLogError+rsMsgLogRmDir, [dir]), [log_dir_op, log_delete], lmtError);
            //------------------------------------------------------------------------------
          end
        else
          begin
            directories:= directories + 1;
            DebugLn('OK');
            // write log -------------------------------------------------------------------
            LogMessage(Format(rsMsgLogSuccess+rsMsgLogRmDir, [dir]), [log_dir_op, log_delete], lmtSuccess);
            //------------------------------------------------------------------------------
          end;
      end;
  except
    on EInOutError do DebugLn('Couldn''t remove '+ dir);
  end;
end;

procedure TFileSystemWipeOperation.WipeFile(filename: String);
var
  Found: Integer;
  SRec: TSearchRecEx;
  sPath: String;
begin
  sPath:= ExtractFilePath(filename);
  { Use FindFirst so we can specify wild cards in the filename }
  Found:= FindFirstEx(filename,faReadOnly or faSysFile or faArchive or faHidden, SRec);
  if Found <> 0 then
    begin
      DebugLn('wp: file not found: ', filename);
      FErrors:= FErrors + 1;
      Exit;
    end;
    while Found = 0 do
    begin
      //remove read-only attr
      try
        if not mbFileSetReadOnly(sPath + SRec.Name, False) then
          DebugLn('wp: FAILED when trying to remove read-only attr on '+ sPath + SRec.Name);
      except
        DebugLn('wp: can''t wipe '+ sPath + SRec.Name + ', file might be in use.');
        FEverythingOK:= False;
        FErrors:= FErrors + 1;
        Exit;
      end;

      DebugLn('Wiping ' + sPath + SRec.Name);
      SecureDelete(gWipePassNumber, sPath + SRec.Name);
      // write log -------------------------------------------------------------------
      if FEverythingOK then
        LogMessage(Format(rsMsgLogSuccess+rsMsgLogDelete, [sPath + SRec.Name]), [log_delete], lmtSuccess)
      else
        LogMessage(Format(rsMsgLogError+rsMsgLogDelete, [sPath + SRec.Name]), [log_delete], lmtError);
      // -----------------------------------------------------------------------------
      Found:= FindNextEx(SRec);   { Find the next file }
    end;
    FindCloseEx(SRec);
end;

procedure TFileSystemWipeOperation.Wipe(aFile: TFileSystemFile);
var
  FileName: String;
begin
  try
    FileName:= aFile.Path + aFile.Name;
    if aFile.IsDirectory then // directory
      WipeDir(FileName)
    else // files
      WipeFile(FileName);

    // process comments if need
    if gProcessComments then
      FDescription.DeleteDescription(FileName);
  except
    DebugLn('Can not wipe ', FileName);
  end;
end;

function TFileSystemWipeOperation.ShowError(sMessage: String): TFileSourceOperationUIResponse;
begin
  FEverythingOK:= False;
  Inc(FErrors);
  if gSkipFileOpError then
  begin
    logWrite(Thread, sMessage, lmtError, True);
    Result := fsourSkip;
  end
  else
  begin
    Result := AskQuestion(sMessage, '', [fsourSkip, fsourCancel], fsourSkip, fsourCancel);
    if Result = fsourCancel then
      RaiseAbortOperation;
  end;
end;

procedure TFileSystemWipeOperation.LogMessage(sMessage: String; logOptions: TLogOptions; logMsgType: TLogMsgType);
begin
  case logMsgType of
    lmtError:
      if not (log_errors in gLogOptions) then Exit;
    lmtInfo:
      if not (log_info in gLogOptions) then Exit;
    lmtSuccess:
      if not (log_success in gLogOptions) then Exit;
  end;

  if logOptions <= gLogOptions then
  begin
    logWrite(Thread, sMessage, logMsgType);
  end;
end;

end.
