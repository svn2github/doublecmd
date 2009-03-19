{
   Double commander
   -------------------------------------------------------------------------
   Archive File support - class for manage WCX plugins (Version 2.10)

   Copyright (C) 2006-2009  Koblov Alexander (Alexx2000@mail.ru)

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

unit uWCXmodule;

interface
uses
  uWCXprototypes, uWCXhead, uFileList, uTypes, dynlibs, Classes, uVFSModule,
  uVFSTypes, uVFSUtil, fFileOpDlg, Dialogs, DialogAPI, uClassesEx;

{$H+}
Type
  TWCXOperation = (OP_EXTRACT, OP_PACK, OP_DELETE);

  TWCXModule = class;
  
  PHeaderData = ^THeaderData;
  
  { Packing/Unpacking thread }
  
   TWCXCopyThread = class(TThread)
   private
     FOperation: TWCXOperation;
     FFileList: TFileList;
     FPath: String;
     FFlags: Integer;
     FWCXModule : TWCXModule;

   protected
     procedure Execute; override;
     procedure Terminating(Sender: TObject);

   public
     constructor Create(WCXModule: TWCXModule;
                        Operation: TWCXOperation; var FileList: TFileList;
                        Path: String; Flags: Integer);
   end;
  
  
  { TWCXModule }

  TWCXModule = class (TVFSModule)
  private
    FArcFileList : TList;
    FPackerCaps : Integer;
    FFolder : String;
    FFilesSize: Int64;
    FPercent : Double;
    CT : TWCXCopyThread;         // Packing/Unpacking thread
    FFileOpDlg: TfrmFileOp; // progress window
    procedure ShowErrorMessage;

    // These 3 functions handle freeing FileList.
    {Extract files from archive}
    function WCXCopyOut(var FileList: TFileList; sDestPath: String; Flags: Integer) : Boolean;
    {Pack files in archive}
    function WCXCopyIn(var FileList: TFileList; sDestPath: String; Flags: Integer) : Boolean;
    {Delete files from archive}
    function WCXDelete(var FileList: TFileList) : Boolean;

    {en
      Counts size of all files in archive that match selection in FileList
      and given file mask.
    }
    procedure CountFiles(const FileList: TFileList; FileMask: String);

    {en
      Creates neccessary paths before extracting files from archive.
      Also counts size of all files that will be extracted.

      @param(FileList
             List of files/directories to extract (relative to archive root).)
      @param(FileMask
             Only files matching this mask will be extracted.)
      @param(sDestPath
             Destination path where the files will be extracted.)
      @param(CurrentArchiveDir
             Path inside the archive from where the files will be extracted.)
    }
    procedure CreateDirsAndCountFiles(const FileList: TFileList; FileMask: String;
                                      sDestPath: String; CurrentArchiveDir: String);

    {en
      Creates paths to directories and sets their attributes.

      @param(sDestPath
             Destination path where directories will be created.)
      @param(PathsToCreate
             Path names relative to destination path.)
      @param(DirsAttributes
             List of directories and their attributes.
             If a directory being created is in this list its attributes are set.)
    }
    function ForceDirectoriesWithAttrs(sDestPath: String;
                                       const PathsToCreate: TStringList;
                                       const DirsAttributes: TFileList): Boolean;

    { Frees current archive file list (fArcFileList). }
    procedure DeleteArchiveFileList;

    { Initializes and shows progress dialog. }
    procedure PrepareDialog(Operation: TWCXOperation);
    { Closes progress dialog and cleans up. }
    procedure FinishDialog;

  protected
    // module's functions
  //**mandatory:
    OpenArchive : TOpenArchive;
    ReadHeader : TReadHeader;
    ProcessFile : TProcessFile;
    CloseArchive : TCloseArchive;
  //**optional:
    // TODO: add ReadHeaderEx for archives with >2GB files
    PackFiles : TPackFiles;
    DeleteFiles : TDeleteFiles;
    GetPackerCaps : TGetPackerCaps;
    ConfigurePacker : TConfigurePacker;
    SetChangeVolProc : TSetChangeVolProc;
    SetProcessDataProc : TSetProcessDataProc;
    StartMemPack : TStartMemPack;
    PackToMem : TPackToMem;
    DoneMemPack : TDoneMemPack;
    CanYouHandleThisFile : TCanYouHandleThisFile;
    PackSetDefaultParams : TPackSetDefaultParams;
    // Dialog API
    SetDlgProc: TSetDlgProc;
    FModuleHandle:TLibHandle;  // Handle to .DLL or .so
    FArchiveName : String;
  public
    constructor Create;
    destructor Destroy; override;

    function LoadModule(const sName:String):Boolean;override; {Load WCX plugin}
    procedure UnloadModule;override;                          {UnLoad WCX plugin}

    function VFSInit(Data: PtrInt):Boolean;override;
    procedure VFSDestroy;override;
    function VFSCaps : TVFSCaps;override;

    function VFSConfigure(Parent: THandle):Boolean;override;
    function VFSOpen(const sName:String; bCanYouHandleThisFile : Boolean = False):Boolean;override;
    function VFSClose:Boolean;override;
    function VFSRefresh : Boolean;override;

    function VFSMkDir(const sDirName:String ):Boolean;override;{Create a directory}
    function VFSRmDir(const sDirName:String):Boolean;override; {Remove a directory}

    function VFSCopyOut(var flSrcList : TFileList; sDstPath:String; Flags: Integer):Boolean;override;{Extract files from archive}
    function VFSCopyIn(var flSrcList : TFileList; sDstName:String;  Flags : Integer):Boolean;override;{Pack files in archive}
    function VFSCopyOutEx(var flSrcList : TFileList; sDstPath:String; Flags: Integer):Boolean;override;{Extract files from archive in thread}
    function VFSCopyInEx(var flSrcList : TFileList; sDstName:String;  Flags : Integer):Boolean;override;{Pack files in archive in thread}

    function VFSRename(const sSrcName, sDstName:String):Boolean;override;{Rename or move file}
    function VFSRun(const sName:String):Boolean;override;
    function VFSDelete(var flNameList:TFileList):Boolean;override;{Delete files from archive}

    function VFSList(const sDir:String; var fl:TFileList ):Boolean;override;{Return the filelist of archive}
    function VFSMisc : PtrUInt;override;
  end;

  { TWCXModuleList }

  TWCXModuleList = class(TStringList)
  private
    function GetAEnabled(Index: Integer): Boolean;
    function GetAExt(Index: Integer): String;
    function GetAFileName(Index: Integer): String;
    function GetAFlags(Index: Integer): PtrInt;
    procedure SetAEnabled(Index: Integer; const AValue: Boolean);
    procedure SetAFileName(Index: Integer; const AValue: String);
    procedure SetAFlags(Index: Integer; const AValue: PtrInt);
    procedure SetExt(Index: Integer; const AValue: String);
  public
    procedure Load(Ini: TIniFileEx); overload;
    procedure Save(Ini: TIniFileEx); overload;
    function Add(Ext: String; Flags: PtrInt; FileName: String): Integer;
    property FileName[Index: Integer]: String read GetAFileName write SetAFileName;
    property Flags[Index: Integer]: PtrInt read GetAFlags write SetAFlags;
    property Ext[Index: Integer]: String read GetAExt write SetExt;
    property Enabled[Index: Integer]: Boolean read GetAEnabled write SetAEnabled;
  end;

function IsBlocked : Boolean;

implementation
uses Forms, SysUtils, Masks, uFileOp, uGlobs, uLog, uOSUtils, LCLProc, uFileProcs,
     uDCUtils, uLng, Controls, fPackInfoDlg, fDialogBox, uGlobsPaths, FileUtil;

var
  WCXModule : TWCXModule = nil;  // used in ProcessDataProc
  iResult : Integer;

constructor TWCXModule.Create;
begin
  FFilesSize:= 0;
  FPercent := 0;
  FArcFileList := nil;
  CT := nil;
  FFileOpDlg := nil;
end;

destructor TWCXModule.Destroy;
begin
  UnloadModule;
  WCXModule := nil; // clear global variable pointing to self
end;

function TWCXModule.LoadModule(const sName:String):Boolean;
var
  PackDefaultParamStruct : TPackDefaultParamStruct;
  SetDlgProcInfo: TSetDlgProcInfo;
begin
  FModuleHandle := mbLoadLibrary(sName);
  Result := (FModuleHandle <> 0);
  if  FModuleHandle = 0 then exit;
  //DebugLN('FModuleHandle =', FModuleHandle);
  // mandatory functions
  OpenArchive:= TOpenArchive(GetProcAddress(FModuleHandle,'OpenArchive'));
  @ReadHeader:= GetProcAddress(FModuleHandle,'ReadHeader');
  @ProcessFile:= GetProcAddress(FModuleHandle,'ProcessFile');
  @CloseArchive:= GetProcAddress(FModuleHandle,'CloseArchive');
  if ((@OpenArchive = nil)or(@ReadHeader = nil)or
   (@ProcessFile = nil)or(@CloseArchive = nil)) then
    begin
      OpenArchive := nil;
      ReadHeader:= nil;
      ProcessFile := nil;
      CloseArchive := nil;
      Result := False;
      Exit;
    end;
  // optional functions
  @PackFiles:= GetProcAddress(FModuleHandle,'PackFiles');
  @DeleteFiles:= GetProcAddress(FModuleHandle,'DeleteFiles');
  @GetPackerCaps:= GetProcAddress(FModuleHandle,'GetPackerCaps');
  @ConfigurePacker:= GetProcAddress(FModuleHandle,'ConfigurePacker');
  @SetChangeVolProc:= GetProcAddress(FModuleHandle,'SetChangeVolProc');
  @SetProcessDataProc:= GetProcAddress(FModuleHandle,'SetProcessDataProc');
  @StartMemPack:= GetProcAddress(FModuleHandle,'StartMemPack');
  @PackToMem:= GetProcAddress(FModuleHandle,'PackToMem');
  @DoneMemPack:= GetProcAddress(FModuleHandle,'DoneMemPack');
  @CanYouHandleThisFile:= GetProcAddress(FModuleHandle,'CanYouHandleThisFile');
  @PackSetDefaultParams:= GetProcAddress(FModuleHandle,'PackSetDefaultParams');
  // Dialog API function
  @SetDlgProc:= GetProcAddress(FModuleHandle,'SetDlgProc');
  
  if Assigned(PackSetDefaultParams) then
    begin
      with PackDefaultParamStruct do
        begin
          Size := SizeOf(PackDefaultParamStruct);
          PluginInterfaceVersionLow := 10;
          PluginInterfaceVersionHi := 2;
          DefaultIniName := '';
        end;
      PackSetDefaultParams(@PackDefaultParamStruct);
    end;

  // Dialog API
  if Assigned(SetDlgProc) then
    begin
      with SetDlgProcInfo do
      begin
        PluginDir:= PWideChar(WideString(ExtractFilePath(sName)));
        PluginConfDir:= PWideChar(UTF8Decode(gpIniDir));
        InputBox:= @fDialogBox.InputBox;
        MessageBox:= @fDialogBox.MessageBox;
        DialogBox:= @fDialogBox.DialogBox;
        DialogBoxEx:= @fDialogBox.DialogBoxEx;
        SendDlgMsg:= @fDialogBox.SendDlgMsg;
      end;
      SetDlgProc(SetDlgProcInfo);
    end;
end;

procedure TWCXModule.UnloadModule;
begin
  if FModuleHandle <> 0 then
    FreeLibrary(FModuleHandle);
  FModuleHandle := 0;
  @OpenArchive:= nil;
  @ReadHeader:= nil;
  @ProcessFile:= nil;
  @CloseArchive:= nil;
  @PackFiles:= nil;
  @DeleteFiles:= nil;
  @GetPackerCaps:= nil;
  @ConfigurePacker:= nil;
  @SetChangeVolProc:= nil;
  @SetProcessDataProc:= nil;
  @StartMemPack:= nil;
  @PackToMem:= nil;
  @DoneMemPack:= nil;
  @CanYouHandleThisFile:= nil;
  @PackSetDefaultParams:= nil;
end;

procedure  ShowErrorMsg(iErrorMsg : Integer);
var
  sErrorMsg : String;
begin
  case iErrorMsg of
  E_END_ARCHIVE    :   sErrorMsg := rsMsgErrEndArchive;
  E_NO_MEMORY      :   sErrorMsg := rsMsgErrNoMemory;
  E_BAD_DATA       :   sErrorMsg := rsMsgErrBadData;
  E_BAD_ARCHIVE    :   sErrorMsg := rsMsgErrBadArchive;
  E_UNKNOWN_FORMAT :   sErrorMsg := rsMsgErrUnknownFormat;
  E_EOPEN          :   sErrorMsg := rsMsgErrEOpen;
  E_ECREATE        :   sErrorMsg := rsMsgErrECreate;
  E_ECLOSE         :   sErrorMsg := rsMsgErrEClose;
  E_EREAD          :   sErrorMsg := rsMsgErrERead;
  E_EWRITE         :   sErrorMsg := rsMsgErrEWrite;
  E_SMALL_BUF      :   sErrorMsg := rsMsgErrSmallBuf;
  E_EABORTED       :   sErrorMsg := rsMsgErrEAborted;
  E_NO_FILES       :   sErrorMsg := rsMsgErrNoFiles;
  E_TOO_MANY_FILES :   sErrorMsg := rsMsgErrTooManyFiles;
  E_NOT_SUPPORTED  :   sErrorMsg := rsMsgErrNotSupported;
  end;

  // write log error
  if (log_arc_op in gLogOptions) and (log_errors in gLogOptions) then
    logWrite(rsMsgLogError + sErrorMsg, lmtError);

  // Standart error modal dialog
  ShowMessage(sErrorMsg);
end;

function ChangeVolProc(ArcName : Pchar; Mode:Longint):Longint; stdcall;
begin
  case Mode of
  PK_VOL_ASK:
    ArcName := PChar(UTF8ToSys(Dialogs.InputBox ('Double Commander', rsMsgSelLocNextVol, SysToUTF8(ArcName))));
  PK_VOL_NOTIFY:
    ShowMessage(rsMsgNextVolUnpack);
  end;
end;

function ProcessDataProc(FileName: PChar; Size: Integer): Integer; stdcall;
begin
  //DebugLn('Working ' + FileName + ' Size = ' + IntToStr(Size));

  Result := 1;
  if Assigned(WCXModule) then
  with WCXModule do
  begin
    if not Assigned(FFileOpDlg) then Exit;
    if FFileOpDlg.ModalResult = mrCancel then // Cancel operation
      Result := 0;

    FFileOpDlg.sFileName := SysToUTF8(FileName);

    if not (Size < 0) then
      begin
        if FFilesSize <> 0 then
          FPercent := FPercent + ((Size * 100) / FFilesSize);
        //DebugLn('Percent = ' + IntToStr(Round(FPercent)));

        FFileOpDlg.iProgress1Pos := 100;
        FFileOpDlg.iProgress2Pos := Round(FPercent);
      end
    else // For plugins which unpack in CloseArchive
      if (Size >= -100) and (Size <= -1) then // first percent bar
        begin
          FFileOpDlg.iProgress1Pos := (Size * -1);
          //DebugLn('Working ' + FileName + ' Percent1 = ' + IntToStr(FFileOpDlg.iProgress1Pos));
        end
      else if (Size >= -1100) and (Size <= -1000) then // second percent bar
        begin
          FFileOpDlg.iProgress2Pos := (Size * -1) - 1000;
          //DebugLn('Working ' + FileName + ' Percent2 = ' + IntToStr(FFileOpDlg.iProgress2Pos));
        end;
        
        
    if Assigned(CT) then
      CT.Synchronize(FFileOpDlg.UpdateDlg)
    else
      begin
        FFileOpDlg.UpdateDlg;
        Application.ProcessMessages;
      end;
  end; //with
end;

procedure TWCXModule.ShowErrorMessage;
begin
  ShowErrorMsg(iResult);
end;

procedure TWCXModule.DeleteArchiveFileList;
var
  i: Integer;
begin
  if Assigned(FArcFileList) then
  begin
    for i := 0 to FArcFileList.Count - 1 do
    begin
      if Assigned(FArcFileList.Items[i]) then
      begin
        Dispose(PHeaderData(FArcFileList.Items[i]));
        FArcFileList.Items[i] := nil;
      end;
    end;

    FreeAndNil(FArcFileList);
  end;
end;

function TWCXModule.VFSInit(Data: PtrInt): Boolean;
begin
  FPackerCaps:= Data;
end;

procedure TWCXModule.VFSDestroy;
begin
  DeleteArchiveFileList;
  UnloadModule;
end;

function TWCXModule.VFSCaps: TVFSCaps;
begin
  Result := [];
  Include(Result, VFS_CAPS_COPYOUT);
  if Assigned(PackFiles) then
    Include(Result, VFS_CAPS_COPYIN);
  if Boolean(FPackerCaps and PK_CAPS_DELETE) and Assigned(DeleteFiles) then
    Include(Result, VFS_CAPS_DELETE);
end;

function TWCXModule.VFSConfigure(Parent: THandle): Boolean;
begin
  if Assigned(ConfigurePacker) then
    ConfigurePacker(Parent, FModuleHandle);
end;


function TWCXModule.VFSOpen(const sName: String; bCanYouHandleThisFile : Boolean = False): Boolean;
var
  ArcHandle : TArcHandle;
  ArcFile : tOpenArchiveData;
  ArcHeader : THeaderData;
  HeaderData : PHeaderData;
  sDirs, ExistsDirList : TStringList;
  I : Integer;
  NameLength: Integer;
begin
  FArchiveName := sName;
  DebugLN('FArchiveName = ' + FArchiveName);

  if not mbFileAccess(FArchiveName, fmOpenRead) then
    begin
      Result := False;
      Exit;
    end;

  if bCanYouHandleThisFile and Assigned(CanYouHandleThisFile) then
    begin
      Result := CanYouHandleThisFile(PChar(UTF8ToSys(sName)));
      if not Result then Exit;
    end;

  DebugLN('Open Archive');

  (*Open Archive*)
  FillChar(ArcFile, SizeOf(ArcFile), #0);
  ArcFile.ArcName := PChar(UTF8ToSys(sName));
  ArcFile.OpenMode := PK_OM_LIST;

  try
    ArcHandle := OpenArchive(ArcFile);
  except
    ArcHandle := 0;
  end;
  
  if ArcHandle = 0 then
    begin
      if not bCanYouHandleThisFile then
        ShowErrorMsg(ArcFile.OpenResult);
      Result := False;
      Exit;
    end;

  WCXModule := Self;  // set WCXModule variable to current module
  SetChangeVolProc(ArcHandle, ChangeVolProc);
  SetProcessDataProc(ArcHandle, ProcessDataProc);

  DebugLN('Get File List');
  (*Get File List*)
  FillChar(ArcHeader, SizeOf(ArcHeader), #0);
  DeleteArchiveFileList;
  FArcFileList := TList.Create;
  sDirs := TStringList.Create;
  ExistsDirList := TStringList.Create;

  try
    while (ReadHeader(ArcHandle, ArcHeader) = 0) do
      begin
        New(HeaderData);
        HeaderData^ := ArcHeader;

        // Some plugins end directories with path delimiter. Delete it if present.
        if FPS_ISDIR(HeaderData^.FileAttr) then
        begin
          NameLength := strlen(HeaderData^.FileName);   // This is a C-String
          if (NameLength < Sizeof(HeaderData^.FileName)) and
             (HeaderData^.FileName[NameLength-1] = PathDelim)
          then
            HeaderData^.FileName[NameLength-1] := #0;
        end;

        //****************************
        (* Workaround for plugins that don't give a list of folders
           or the list does not include all of the folders.
           This considerably slows down opening archives with lots of files. *)

        if FPS_ISDIR(HeaderData^.FileAttr) then
        begin
          // Collect directories that the plugin supplies.
          if (ExistsDirList.IndexOf(HeaderData.FileName) < 0) then
            ExistsDirList.Add(HeaderData.FileName);
        end;

        // Collect all directories.
        GetDirs(String(HeaderData^.FileName), sDirs);

        //****************************

        FArcFileList.Add(HeaderData);

        FillChar(ArcHeader, SizeOf(ArcHeader), #0);
        // get next file
        iResult := ProcessFile(ArcHandle, PK_SKIP, nil, nil);

        //Check for errors
        if iResult <> E_SUCCESS then
          ShowErrorMessage;
      end; // while
    
    (* if plugin does not give a list of folders *)
      begin
        for I := 0 to sDirs.Count - 1 do
          begin
            // Add only those directories that were not supplied by the plugin.
            if ExistsDirList.IndexOf(sDirs.Strings[I]) >= 0 then
              Continue;
            FillChar(ArcHeader, SizeOf(ArcHeader), #0);
            ArcHeader.FileName := sDirs.Strings[I];
            ArcHeader.FileAttr := faFolder;
            ArcHeader.FileTime := mbFileAge(FArchiveName);
            New(HeaderData);
            HeaderData^ := ArcHeader;
            FArcFileList.Add(HeaderData);
          end;
      end;
  finally
    sDirs.Free;
    ExistsDirList.Free;
    CloseArchive(ArcHandle);
  end;
  Result := True;
end;

function TWCXModule.VFSClose: Boolean;
begin
  DeleteArchiveFileList;
end;

function TWCXModule.VFSRefresh: Boolean;
begin
  Result := VFSOpen(FArchiveName)
end;

function TWCXModule.VFSMkDir(const sDirName: String): Boolean;
begin

end;

function TWCXModule.VFSRmDir(const sDirName: String): Boolean;
begin

end;

function ExcludeFrontPathDelimiter(s:String): String;
begin
  if (Length(s) > 0) and (s[1] = PathDelim) then
    Result := Copy(s, 2, Length(s) - 1)
  else
    Result := s;
end;

function GetFileList(var fl:TFileList; Operation: TWCXOperation) : String;
var
  I        : Integer;
  FileName : String;
begin
  Result := '';

  for I := 0 to fl.Count - 1 do
    begin
      // Filenames must be relative to archive root and shouldn't start with path delimiter.
      FileName := ExcludeFrontPathDelimiter(fl.GetItem(I)^.sName);

      // Special treatment of directories.
      if FPS_ISDIR(fl.GetItem(I)^.iMode) then
      begin
        case Operation of
          OP_PACK:
              FileName := IncludeTrailingPathDelimiter(FileName);

          OP_DELETE:
              FileName := IncludeTrailingPathDelimiter(FileName) + '*.*';
        end;
      end;

      Result := Result + FileName + #0;
    end;

  Result := Result + #0;
end;

function TWCXModule.WCXCopyOut(var FileList: TFileList; sDestPath: String; Flags: Integer) : Boolean;
var
  ArcHandle : TArcHandle;
  ArcFile : tOpenArchiveData;
  ArcHeader : THeaderData;
  CurrentFileName: String;
  TargetFileName: String;
  FileMask: String;
begin
  FPercent := 0;

  FillChar(ArcFile, SizeOf(ArcFile), #0);
  ArcFile.ArcName := PChar(UTF8ToSys(FArchiveName));
  ArcFile.OpenMode := PK_OM_EXTRACT;
  ArcHandle := OpenArchive(ArcFile);

  if ArcHandle = 0 then
   begin
    if Assigned(CT) then
      begin
        iResult := ArcFile.OpenResult;
        CT.Synchronize(ShowErrorMessage);
      end
    else
      ShowErrorMsg(ArcFile.OpenResult);

    Result := False;
    FreeAndNil(FileList);
    Exit;
   end;

  FileMask := ExtractFileName(sDestPath);
  if FileMask = '' then FileMask := '*';  // extract all selected files/folders
  sDestPath := ExtractFilePath(sDestPath);

  // Convert file list so that filenames are relative to archive root.
  ChangeFileListRoot(FArchiveName + PathDelim, FileList);

  // Count total files size and create needed directories.
  CreateDirsAndCountFiles(FileList, FileMask, sDestPath, FileList.CurrentDirectory);

  WCXModule := Self;  // set WCXModule variable to current module
  SetChangeVolProc(ArcHandle, ChangeVolProc);
  SetProcessDataProc(ArcHandle, ProcessDataProc);


  FillChar(ArcHeader, SizeOf(ArcHeader), #0);
  while (ReadHeader(ArcHandle, ArcHeader) = 0) do
   begin
    CurrentFileName := SysToUTF8(ArcHeader.FileName);

    // Now check if the file is to be extracted.

    if  (not FPS_ISDIR(ArcHeader.FileAttr))        // Omit directories (we handle them ourselves).
    and MatchesFileList(FileList, CurrentFileName) // Check if it's included in the filelist
    and ((FileMask = '*.*') or (FileMask = '*')    // And name matches file mask
        or MatchesMaskList(ExtractFileName(CurrentFileName), FileMask))
    then
       begin
         TargetFileName := sDestPath + ExtractDirLevel(FileList.CurrentDirectory, CurrentFileName);

         iResult := ProcessFile(ArcHandle, PK_EXTRACT, nil, PChar(UTF8ToSys(TargetFileName)));

         //Check for errors
         if iResult <> E_SUCCESS then
           begin
             if Assigned(CT) then
               begin
                 // write log error
                 if (log_arc_op in gLogOptions) and (log_errors in gLogOptions) then
                   logWrite(CT, Format(rsMsgLogError+rsMsgLogExtract, [FArchiveName + PathDelim + CurrentFileName + ' -> ' + TargetFileName]), lmtError);
                 // Standart error modal dialog
                 CT.Synchronize(ShowErrorMessage)
               end
             else
               begin
                 // write log error
                 if (log_arc_op in gLogOptions) and (log_errors in gLogOptions) then
                   logWrite(Format(rsMsgLogError+rsMsgLogExtract, [FArchiveName + PathDelim + CurrentFileName + ' -> ' + TargetFileName]), lmtError);
                 // Standart error modal dialog
                 ShowErrorMessage;
               end;
             // user abort operation
             if iResult = E_EABORTED then Break;
           end // Error
         else
           begin
             if Assigned(CT) then
               begin
                 // write log success
                 if (log_arc_op in gLogOptions) and (log_success in gLogOptions) then
                   logWrite(CT, Format(rsMsgLogSuccess+rsMsgLogExtract, [FArchiveName + PathDelim + CurrentFileName +' -> ' + TargetFileName]), lmtSuccess);
               end
             else
               begin
                 // write log success
                 if (log_arc_op in gLogOptions) and (log_success in gLogOptions) then
                   logWrite(Format(rsMsgLogSuccess+rsMsgLogExtract, [FArchiveName + PathDelim + CurrentFileName + ' -> ' + TargetFileName]), lmtSuccess);
               end;
           end; // Success
       end // Extract
     else // Skip
       begin
         iResult := ProcessFile(ArcHandle, PK_SKIP, nil, nil);

         //Check for errors
         if iResult <> E_SUCCESS then
           if Assigned(CT) then
             CT.Synchronize(ShowErrorMessage)
           else
             ShowErrorMessage;
       end; // Skip
     FillChar(ArcHeader, SizeOf(ArcHeader), #0);
   end;
  CloseArchive(ArcHandle);
  FreeAndNil(FileList);
  Result := True;
end;

function TWCXModule.WCXCopyIn(var FileList: TFileList; sDestPath: String; Flags: Integer) : Boolean;
var
  pDestPath : PChar;
begin
  DebugLN('VFSCopyIn =' + FArchiveName);
  FPercent := 0;

  sDestPath := ExtractDirLevel(FArchiveName + PathDelim, sDestPath);
  sDestPath := ExcludeTrailingPathDelimiter(sDestPath);

  DebugLN('sDstPath == ' + sDestPath);

  sDestPath := UTF8ToSys(sDestPath);

  if sDestPath = '' then
    pDestPath := nil
  else
    pDestPath := PChar(sDestPath); // Make pointer to local variable
    
  // Convert file list so that filenames are relative to archive root.
  ChangeFileListRoot(FArchiveName + PathDelim, FileList);

  (* Add in file list files from subfolders *)
  FillAndCount(FileList, FFilesSize);

  DebugLN('Curr Dir := ' + FileList.CurrentDirectory);


  WCXModule := Self;  // set WCXModule variable to current module
  SetChangeVolProc(INVALID_HANDLE_VALUE, ChangeVolProc);
  SetProcessDataProc(INVALID_HANDLE_VALUE, ProcessDataProc);

  iResult := PackFiles(PChar(UTF8ToSys(FArchiveName)),
                       pDestPath, // no trailing path delimiter here
                       PChar(UTF8ToSys(IncludeTrailingPathDelimiter(FileList.CurrentDirectory))), // end with path delimiter here
                       PChar(UTF8ToSys(GetFileList(FileList, OP_PACK))),  // Convert TFileList into PChar
                       Flags);

  //Check for errors
  if iResult <> E_SUCCESS then
    begin
      if Assigned(CT) then
        begin
          // write log error
          if (log_arc_op in gLogOptions) and (log_errors in gLogOptions) then
            logWrite(CT, Format(rsMsgLogError+rsMsgLogPack, [FArchiveName]), lmtError);
          // Standart error modal dialog
          CT.Synchronize(ShowErrorMessage)
        end
      else
        begin
          // write log error
            if (log_arc_op in gLogOptions) and (log_errors in gLogOptions) then
              logWrite(Format(rsMsgLogError+rsMsgLogPack, [FArchiveName]), lmtError);
            // Standart error modal dialog
            ShowErrorMessage;
        end;
    end // Error
  else
    begin
      if Assigned(CT) then
        begin
          // write log success
          if (log_arc_op in gLogOptions) and (log_success in gLogOptions) then
            logWrite(CT, Format(rsMsgLogSuccess+rsMsgLogPack, [FArchiveName]), lmtSuccess);
        end
      else
        begin
          // write log success
          if (log_arc_op in gLogOptions) and (log_success in gLogOptions) then
            logWrite(Format(rsMsgLogSuccess+rsMsgLogPack, [FArchiveName]), lmtSuccess);
        end;
    end; // Success

  FreeAndNil(FileList);
  Result := True;
end;

function TWCXModule.WCXDelete(var FileList: TFileList) : Boolean;
var
  iResult: Integer;
begin
  FPercent := 0;

  // Convert file list so that filenames are relative to archive root.
  ChangeFileListRoot(FArchiveName + PathDelim, FileList);

  CountFiles(FileList, '*.*');

  WCXModule := Self;  // set WCXModule variable to current module
  SetChangeVolProc(INVALID_HANDLE_VALUE, ChangeVolProc);
  SetProcessDataProc(INVALID_HANDLE_VALUE, ProcessDataProc);

  iResult := DeleteFiles(PChar(UTF8ToSys(FArchiveName)),
                         PChar(UTF8ToSys(GetFileList(FileList, OP_DELETE))));

  //Check for errors
  if iResult <> E_SUCCESS then
    begin
      if Assigned(CT) then
          CT.Synchronize(ShowErrorMessage)
      else
          ShowErrorMessage;
    end;

  FreeAndNil(FileList);
end;

function TWCXModule.ForceDirectoriesWithAttrs(sDestPath: String;
                                              const PathsToCreate: TStringList;
                                              const DirsAttributes: TFileList): Boolean;
var
  Directories: TStringList;
  i: Integer;
  PathIndex: Integer;
  ListIndex: Integer;
  TargetDir: String;
  Time: Longint;
begin
  Result := True;

  sDestPath := IncludeTrailingPathDelimiter(sDestPath);

  // First create path to destination directory (we don't have attributes for that).
  ForceDirectory(sDestPath);

  Directories := TStringList.Create;

  for PathIndex := 0 to PathsToCreate.Count - 1 do
  begin
    Directories.Clear;

    // Get all relative directories from the path to create.
    // This adds directories to list in order from the outer to inner ones,
    // for example: dir, dir/dir2, dir/dir2/dir3.
    if GetDirs(PathsToCreate.Strings[PathIndex], Directories) <> -1 then
    try
      for i := 0 to Directories.Count - 1 do
      begin
        TargetDir := sDestPath + Directories.Strings[i];

        if not DirPathExists(TargetDir) then
        begin
           if ForceDirectory(TargetDir) = False then
           begin
             // Error, cannot create directory.
             Result := False;
           end
           else
           begin
             // Check, if attributes are stored for the directory in the DirectoriesList.
             ListIndex := DirsAttributes.CheckFileName(Directories.Strings[i]);
             if ListIndex <> -1 then
             begin
{$IF DEFINED(MSWINDOWS)}
               // Restore attributes, e.g., hidden, read-only.
               // On Unix iMode value would have to be translated somehow.
               mbFileSetAttr(TargetDir, DirsAttributes.GetItem(ListIndex)^.iMode);
{$ENDIF}
               Time := Trunc(DirsAttributes.GetItem(ListIndex)^.fTimeI);

               // Set creation, modification time
               mbFileSetTime(TargetDir, Time, Time, Time);
             end;
           end;
        end;
      end;

    except
    end;

  end;

  FreeAndNil(Directories);
end;

procedure TWCXModule.CreateDirsAndCountFiles(const FileList: TFileList; FileMask: String; sDestPath: String; CurrentArchiveDir: String);
var
  // List of paths that we know must be created.
  PathsToCreate: TStringList;

  // List of possible directories to create with their attributes.
  // This usually short list is created so that we don't traverse
  // the whole archive each time we need an attribute for a directory.
  DirsWithAttributes: TFileList;

  i: Integer;
  fri : TFileRecItem;
  CurrentFileName: String;
  ArcHeader: THeaderData;
begin
  FFilesSize := 0;

  PathsToCreate := TStringList.Create;
  DirsWithAttributes := TFileList.Create;

  for i := 0 to FArcFileList.Count - 1 do
  begin
    ArcHeader := PHeaderData(FArcFileList.Items[I])^;
    CurrentFileName := SysToUTF8(ArcHeader.FileName);

    // Check if the file from the archive fits the selection given via FileList.
    if not MatchesFileList(FileList, CurrentFileName) then
      Continue;

    if FPS_ISDIR(ArcHeader.FileAttr) then
    begin
      // Save this directory with its attributes.
      fri.sName  := ExtractDirLevel(CurrentArchiveDir, CurrentFileName);
      fri.iMode  := ArcHeader.FileAttr;
      fri.fTimeI := ArcHeader.FileTime;

      DirsWithAttributes.AddItem(@fri);
    end
    else
    begin
      if ((FileMask = '*.*') or (FileMask = '*') or
          MatchesMaskList(ExtractFileName(CurrentFileName), FileMask)) then
      begin
        Inc(FFilesSize, ArcHeader.UnpSize);

        CurrentFileName := ExtractDirLevel(CurrentArchiveDir, ExtractFilePath(CurrentFileName));

        // If CurrentFileName is empty now then it was a file in current archive
        // directory, therefore we don't have to create any paths for it.
        if Length(CurrentFileName) > 0 then
          if PathsToCreate.IndexOf(CurrentFileName) < 0 then
            PathsToCreate.Add(CurrentFileName);
      end;
    end;
  end;

  try
    if ForceDirectoriesWithAttrs(sDestPath, PathsToCreate, DirsWithAttributes) = False then
      ; // Error.
  except
  end;

  FreeAndNil(PathsToCreate);
  FreeAndNil(DirsWithAttributes);
end;

procedure TWCXModule.CountFiles(const FileList: TFileList; FileMask: String);
var
  i: Integer;
  CurrentFileName: String;
  ArcHeader: THeaderData;
begin
  FFilesSize := 0;

  for i := 0 to FArcFileList.Count - 1 do
  begin
    ArcHeader := PHeaderData(FArcFileList.Items[I])^;
    CurrentFileName := SysToUTF8(ArcHeader.FileName);

    // Check if the file from the archive fits the selection given via FileList.
    if  (not FPS_ISDIR(ArcHeader.FileAttr))        // Omit directories
    and MatchesFileList(FileList, CurrentFileName) // Check if it's included in the filelist
    and ((FileMask = '*.*') or (FileMask = '*')    // And name matches file mask
        or MatchesMaskList(ExtractFileName(CurrentFileName), FileMask))
    then
      Inc(FFilesSize, ArcHeader.UnpSize);
  end;
end;

procedure TWCXModule.PrepareDialog(Operation: TWCXOperation);
begin
  FFileOpDlg:= TfrmFileOp.Create(nil);
  FFileOpDlg.iProgress1Max:=100;
  FFileOpDlg.iProgress2Max:=100;

  case Operation of
    OP_EXTRACT:  FFileOpDlg.Caption := rsDlgExtract;
    OP_PACK   :  FFileOpDlg.Caption := rsDlgPack;
    OP_DELETE :  FFileOpDlg.Caption := rsDlgDel;
  end;

  FFileOpDlg.Thread := TThread(CT);
  FFileOpDlg.Show;
end;

procedure TWCXModule.FinishDialog;
begin
  FFileOpDlg.Close;
  FFileOpDlg := nil;
end;

{Extract files from archive}

function TWCXModule.VFSCopyOut(var flSrcList: TFileList; sDstPath: String;
  Flags: Integer): Boolean;
begin
  CT := nil;
  PrepareDialog(OP_EXTRACT);
  Result := WCXCopyOut(flSrcList, sDstPath, Flags);
  FinishDialog;
end;

{Pack files}

function TWCXModule.VFSCopyIn(var flSrcList: TFileList; sDstName: String; Flags : Integer
  ): Boolean;
begin
  CT := nil;
  PrepareDialog(OP_PACK);
  Result := WCXCopyIn(flSrcList, sDstName, Flags);
  FinishDialog;
end;

{Extract files from archive in thread}

function TWCXModule.VFSCopyOutEx(var flSrcList: TFileList; sDstPath: String;
  Flags: Integer): Boolean;
begin
  // check if other operations are running
  if not IsBlocked then
  begin
    CT := TWCXCopyThread.Create(Self, OP_EXTRACT, flSrcList, sDstPath, Flags);
    PrepareDialog(OP_EXTRACT);
    CT.Resume;
    Result := True;
  end
  else
  begin
    Result := False;
    FreeAndNil(flSrcList);
  end;
end;

{Pack files in thread}

function TWCXModule.VFSCopyInEx(var flSrcList: TFileList; sDstName: String; Flags : Integer
  ): Boolean;
begin
  // check if other operations are running
  if not IsBlocked then
  begin
    CT := TWCXCopyThread.Create(Self, OP_PACK, flSrcList, sDstName, Flags);
    PrepareDialog(OP_PACK);
    CT.Resume;
    Result := True;
  end
  else
  begin
    Result := False;
    FreeAndNil(flSrcList);
  end;
end;

function TWCXModule.VFSRename(const sSrcName, sDstName: String): Boolean;
begin

end;

function TWCXModule.VFSRun(const sName: String): Boolean;
var
  iCount, I: Integer;
begin
  //DebugLn(fFolder + sName);

  iCount := FArcFileList.Count - 1;
  for I := 0 to  iCount do
   begin
     //DebugLn(PHeaderData(FArcFileList.Items[I])^.FileName);
     if (PathDelim + PHeaderData(FArcFileList.Items[I])^.FileName) = UTF8ToSys(fFolder + sName) then
     begin
       Result:= ShowPackInfoDlg(Self, PHeaderData(FArcFileList.Items[I])^);
       Exit;
     end;
   end;
   Result:= False;
end;

function TWCXModule.VFSDelete(var flNameList: TFileList): Boolean;
begin
  CT := nil;
  PrepareDialog(OP_DELETE);
  Result := WCXDelete(flNameList);
  FinishDialog;
end;

function TWCXModule.VFSList(const sDir: String; var fl: TFileList): Boolean;
var
  fr : TFileRecItem;
  I, Count : Integer;
  CurrFileName : String;  // Current file name
begin
  fl.Clear;
  FFolder := sDir; // save current folder
  AddUpLevel(LowDirLevel(sDir), fl);
  
  DebugLN('LowDirLevel(sDir) = ' + LowDirLevel(sDir));
  
  Count := FArcFileList.Count - 1;
  for I := 0 to  Count do
   begin
     CurrFileName := PathDelim + SysToUTF8(PHeaderData(FArcFileList.Items[I])^.FileName);

     if not IsFileInPath(sDir, CurrFileName, False) then
       Continue;

     FillByte(fr, SizeOf(fr), 0);
     with fr, PHeaderData(FArcFileList.Items[I])^  do
         begin
            sName := ExtractFileName(CurrFileName);
            iMode := FileAttr;
            sModeStr := AttrToStr(iMode);
            bLinkIsDir := False;
            bSelected := False;
            if FPS_ISDIR(iMode) then
              sExt:=''
            else
              sExt:=ExtractFileExt(sName);
            sNameNoExt:=Copy(sName,1,length(sName)-length(sExt));
            sPath := sDir;
            try
              fTimeI := FileDateToDateTime(FileTime);
            except
              fTimeI := 0;
            end;
            sTime := FormatDateTime(gDateTimeFormat, fTimeI);
            iSize := UnpSize;
         end; //with
     fl.AddItem(@fr);
   end;
end;

function TWCXModule.VFSMisc: PtrUInt;
begin
  if Assigned(GetPackerCaps) then
    Result := GetPackerCaps
  else
    Result := 0;
end;

{ TWCXCopyThread }

constructor TWCXCopyThread.Create(WCXModule: TWCXModule;
                                  Operation: TWCXOperation; var FileList: TFileList;
                                  Path: String; Flags: Integer);
begin
  inherited Create(True, DefaultStackSize);

  FreeOnTerminate := True;
  OnTerminate := Terminating;

  FWCXModule := WCXModule;
  FOperation := Operation;
  FFileList := FileList;
  FPath := Path;
  FFlags:= Flags;
end;

procedure TWCXCopyThread.Execute;
begin
// main archive thread code started here
  with FWCXModule do
  begin
    try
      case FOperation of
        OP_EXTRACT:
            WCXCopyOut(FFileList, FPath, FFlags);
        OP_PACK:
            WCXCopyIn(FFileList, FPath, FFlags);
        OP_DELETE:
            WCXDelete(FFileList);
      end;
    except
      DebugLN('Error in "WCXCopyThread.Execute"');
    end;

    Synchronize(FinishDialog);
    CT := nil;
  end; //with
end;

procedure TWCXCopyThread.Terminating(Sender: TObject);
begin
  // Last chance to clean up if there was an error.
  if Assigned(FFileList) then
    FreeAndNil(FFileList);

  if Assigned(FWCXModule) and Assigned(FWCXModule.FFileOpDlg) then
    Synchronize(FWCXModule.FinishDialog);

  FWCXModule.CT := nil;
end;

function IsBlocked : Boolean;
begin
  Result := Assigned(WCXModule);
  if Result then
    with WCXModule do
      begin
        Result := Assigned(FFileOpDlg);
        if Result then
          if Assigned(CT) then
            CT.Synchronize(FFileOpDlg.ShowOnTop)
          else
            FFileOpDlg.ShowOnTop;
      end;  // with
end;

{ TWCXModuleList }

function TWCXModuleList.GetAEnabled(Index: Integer): Boolean;
begin
  Result:= Boolean(Objects[Index]);
end;

function TWCXModuleList.GetAExt(Index: Integer): String;
begin
  Result:= Names[Index];
end;

function TWCXModuleList.GetAFileName(Index: Integer): String;
var
  sCurrPlugin: String;
  iPosComma : Integer;
begin
  sCurrPlugin:= ValueFromIndex[Index];
  iPosComma:= Pos(',', sCurrPlugin);
    //get file name
  Result:= Copy(sCurrPlugin, iPosComma + 1, Length(sCurrPlugin) - iPosComma);
end;

function TWCXModuleList.GetAFlags(Index: Integer): PtrInt;
var
  sCurrPlugin: String;
  iPosComma : Integer;
begin
  sCurrPlugin:= ValueFromIndex[Index];
  iPosComma:= Pos(',', sCurrPlugin);
  // get packer flags
  Result:= StrToInt(Copy(sCurrPlugin, 1, iPosComma-1));
end;

procedure TWCXModuleList.SetAEnabled(Index: Integer; const AValue: Boolean);
begin
  Objects[Index]:= TObject(AValue);
end;

procedure TWCXModuleList.SetAFileName(Index: Integer; const AValue: String);
begin
  ValueFromIndex[Index]:= IntToStr(GetAFlags(Index)) + #44 + AValue;
end;

procedure TWCXModuleList.SetAFlags(Index: Integer; const AValue: PtrInt);
begin
  ValueFromIndex[Index]:= IntToStr(AValue) + #44 + GetAFileName(Index);
end;

procedure TWCXModuleList.SetExt(Index: Integer; const AValue: String);
var
  sValue : String;
begin
  sValue:= ValueFromIndex[Index];
  Self[Index]:= AValue + '=' + sValue;
end;

procedure TWCXModuleList.Load(Ini: TIniFileEx);
var
  I: Integer;
  sCurrPlugin,
  sValue: String;
begin
  Ini.ReadSectionRaw('PackerPlugins', Self);
  for I:= 0 to Count - 1 do
    if Pos('#', Names[I]) = 0 then
      begin
        Enabled[I]:= True;
      end
    else
      begin
        sCurrPlugin:= Names[I];
        sValue:= ValueFromIndex[I];
        Self[I]:= Copy(sCurrPlugin, 2, Length(sCurrPlugin) - 1) + '=' + sValue;
        Enabled[I]:= False;
      end;
end;

procedure TWCXModuleList.Save(Ini: TIniFileEx);
var
 I: Integer;
begin
  Ini.EraseSection('PackerPlugins');
  for I := 0 to Count - 1 do
    begin
      if Boolean(Objects[I]) then
        begin
          Ini.WriteString('PackerPlugins', Names[I], ValueFromIndex[I])
        end
      else
        begin
          Ini.WriteString('PackerPlugins', '#' + Names[I], ValueFromIndex[I]);
        end;
    end;
end;

function TWCXModuleList.Add(Ext: String; Flags: PtrInt; FileName: String): Integer;
begin
  Result:= AddObject(Ext + '=' + IntToStr(Flags) + #44 + FileName, TObject(True));
end;

end.
