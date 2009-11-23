{
    Double Commander
    -------------------------------------------------------------------------
    This unit contains platform depended functions.

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

unit uOSForms;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, uTypes, uFileList, Menus, Controls, Graphics, ExtDlgs, Dialogs,
  {$IFDEF UNIX}
  BaseUnix, Unix, fFileProperties;
  {$ELSE}
  FileUtil, Windows, ShlObj, ActiveX, uShlObjAdditional,
  JwaShlGuid, JwaDbt, uMyWindows;
  {$ENDIF}

const
  sCmdVerbOpen = 'open';
  sCmdVerbRename = 'rename';
  sCmdVerbDelete = 'delete';
  sCmdVerbCut = 'cut';
  sCmdVerbCopy = 'copy';
  sCmdVerbPaste = 'paste';

type
  EContextMenuException = class(Exception);

{$IFDEF UNIX}
type
  TContextMenu = class(TPopupMenu)
    procedure ContextMenuSelect(Sender:TObject);
    procedure DriveContextMenuSelect(Sender:TObject);
  end;
{$ENDIF}

{en
   Replace window procedure
   @param(Handle Window handle)
}
procedure SetMyWndProc(Handle : THandle);
{en
   Show file/folder properties dialog
   @param(FileList List of files)
   @param(aPath Current file path)
}  
procedure ShowFilePropertiesDialog(const FileList:TFileList; const aPath:String);
{en
   Show file/folder context menu
   @param(Owner Parent window)
   @param(FileList List of files. It is freed by this function.)
   @param(X X coordinate)
   @param(Y Y coordinate)
}
procedure ShowContextMenu(Owner: TWinControl; FileList : TFileList; X, Y : Integer);
{en
   Show drive context menu
   @param(Owner Parent window)
   @param(sPath Path to drive)
   @param(X X coordinate)
   @param(Y Y coordinate)
}
procedure ShowDriveContextMenu(Owner: TWinControl; sPath: String; X, Y : Integer);
{en
   Show open icon dialog
   @param(Owner Owner)
   @param(sFileName Icon file name)
   @returns(The function returns @true if successful, @false otherwise)
}
function ShowOpenIconDialog(Owner: TCustomControl; var sFileName : String) : Boolean;

implementation

uses
  LCLProc, fMain, uOSUtils, uGlobs, uLng, uDCUtils, uShellExecute
  {$IF DEFINED(MSWINDOWS)}
  , uTotalCommander, comobj
  {$ENDIF}
  {$IF DEFINED(LINUX)}
  , uFileSystemWatcher, inotify
  {$ENDIF}
  ;

var
{$IFDEF MSWINDOWS}
  OldWProc: WNDPROC;
  ICM2: IContextMenu2 = nil;
{$ELSE}
  CM : TContextMenu = nil;
  FileRecItem: TFileRecItem;
{$ENDIF}

{$IFDEF WIN64}
function SetWindowLong(hWnd: HWND; nIndex: Integer; dwNewLong: LONG_PTR): LONG_PTR; stdcall; external 'user32' name 'SetWindowLongPtrW';
{$ENDIF}

{$IFDEF MSWINDOWS}
function MyWndProc(hWnd: HWND; uiMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  case uiMsg of
    (* For working with submenu of contex menu *)
    WM_INITMENUPOPUP,
    WM_DRAWITEM,
    WM_MENUCHAR,
    WM_MEASUREITEM:
      if Assigned(ICM2) then
        begin
          ICM2.HandleMenuMsg(uiMsg, wParam, lParam);
          Result := 0;
        end
      else
        Result := CallWindowProc(OldWProc, hWnd, uiMsg, wParam, lParam);
        
    WM_DEVICECHANGE:
      if (wParam = DBT_DEVICEARRIVAL) or (wParam = DBT_DEVICEREMOVECOMPLETE) then
        frmMain.UpdateDiskCount;
  else
    Result := CallWindowProc(OldWProc, hWnd, uiMsg, wParam, lParam);
  end; // case
end;
{$ENDIF}

procedure SetMyWndProc(Handle : THandle);
{$IFDEF MSWINDOWS}
begin
  OldWProc := WNDPROC(SetWindowLong(Handle, GWL_WNDPROC, LONG_PTR(@MyWndProc)));
  CreateTotalCommanderWindow(Handle);
end;
{$ELSE}
begin
  if fpGetUID = 0 then // if run under root
    frmMain.Caption:= frmMain.Caption + ' - ROOT PRIVILEGES';
end;
{$ENDIF}

{$IFDEF UNIX}
(* handling user commands from context menu *)
procedure TContextMenu.ContextMenuSelect(Sender: TObject);
var
  sCmd: String;
begin
  // ShowMessage((Sender as TMenuItem).Hint);
  sCmd:= (Sender as TMenuItem).Hint;
  with frmMain.ActiveFrame do
  begin
    if (Pos('{!VFS}',sCmd)>0) and pnlFile.VFS.FindModule(ActiveDir + FileRecItem.sName) then
     begin
        pnlFile.LoadPanelVFS(@FileRecItem);
        Exit;
      end;
    if not ProcessExtCommand(sCmd, pnlFile.ActiveDir) then
      frmMain.ExecCmd(sCmd);
  end;
end;

(* handling user commands from drive context menu *)
procedure TContextMenu.DriveContextMenuSelect(Sender:TObject);
var
  sExecCmd,
  sCmd, sPath: String;
  iPos: Integer;
begin
  // ShowMessage((Sender as TMenuItem).Hint);
  sCmd:= (Sender as TMenuItem).Hint;
  // mount drive
  iPos:= Pos('{!MOUNT}', sCmd);
  if iPos > 0 then
    sExecCmd:= 'mount ';
  // umount drive
  iPos:= Pos('{!UMOUNT}', sCmd);
  if iPos > 0 then
    sExecCmd:= 'umount ';
  // eject drive
  iPos:= Pos('{!EJECT}', sCmd);
  if iPos > 0 then
    sExecCmd:= 'eject ';
  // exit if command not found
  if sExecCmd = '' then Exit;
  // get path
  iPos:= Pos('}', sCmd);
  sPath:= Copy(sCmd, iPos + 1, Length(sCmd)-iPos);
  // execute command
  fpSystem(sExecCmd + sPath);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function InsertMenuItemEx(hMenu, SubMenu: HMENU; Caption: PWChar;
                         Position, ItemID,  ItemType : UINT): boolean;
var
  mi: TMenuItemInfoW;
begin
   FillChar(mi, SizeOf(mi), 0);
   with mi do
   begin
      cbSize := SizeOf(mi);
      fMask := MIIM_STATE or MIIM_TYPE or MIIM_SUBMENU or MIIM_ID;
      fType := ItemType;
      fState := MFS_ENABLED;
      wID := ItemID;
      hSubMenu := SubMenu;
      dwItemData := 0;
      dwTypeData := Caption;
      cch := SizeOf(Caption);
   end;
   Result := InsertMenuItemW(hMenu, Position, false, mi);
end;

function GetIContextMenu(Handle : THandle; FileList : TFileList): IContextMenu;
type
  PPIDLArray = ^PItemIDList;

var
  Folder,
  DesktopFolder: IShellFolder;
  PathPIDL: PItemIDList = nil;
  tmpPIDL: PItemIDList = nil;
  S: WideString;
  List: PPIDLArray = nil;
  I : Integer;
  pchEaten: ULONG;
  dwAttributes: ULONG = 0;
begin
  Result := nil;

  OleCheckUTF8(SHGetDesktopFolder(DeskTopFolder));
  try
    List := CoTaskMemAlloc(SizeOf(PItemIDList)*FileList.Count);
    ZeroMemory(List, SizeOf(PItemIDList)*FileList.Count);

    for I := 0 to FileList.Count - 1 do
      begin
        S := UTF8Decode(FileList.GetItem(I)^.sPath);

        OleCheckUTF8(DeskTopFolder.ParseDisplayName(Handle, nil, PWideChar(S), pchEaten, PathPIDL, dwAttributes));
        try
          OleCheckUTF8(DeskTopFolder.BindToObject(PathPIDL, nil, IID_IShellFolder, Folder));
        finally
          CoTaskMemFree(PathPIDL);
        end;

        S := UTF8Decode(FileList.GetItem(I)^.sName);
        OleCheckUTF8(Folder.ParseDisplayName(Handle, nil, PWideChar(S), pchEaten, tmpPIDL, dwAttributes));
        (List + i)^ := tmpPIDL;
      end;

    Folder.GetUIObjectOf(Handle, FileList.Count, PItemIDList(List^), IID_IContextMenu, nil, Result);

  finally
    if Assigned(List) then
    begin
      for I := 0 to FileList.Count - 1 do
        if Assigned((List + i)^) then
          CoTaskMemFree((List + i)^);
      CoTaskMemFree(List);
    end;

    DesktopFolder._Release;
  end;
end;
{$ENDIF}

procedure ShowContextMenu(Owner: TWinControl; FileList : TFileList; X, Y : Integer);
{$IFDEF MSWINDOWS}
var
  fri : TFileRecItem;
  sl: TStringList = nil;
  i:Integer;
  sCmd:String;  
  contMenu: IContextMenu;
  menu: HMENU = 0;
  hActionsSubMenu: HMENU = 0;
  cmd: UINT = 0;
  iCmd: Integer;
  cmici: TCMINVOKECOMMANDINFO;
  bHandled : Boolean = False;
  ZVerb: array[0..255] of char;
  sVerb : String;
begin
  try
    try
      if FileList.Count = 0 then Exit;

      contMenu := GetIContextMenu(Owner.Handle, FileList);
      if Assigned(contMenu) then
      try
        menu := CreatePopupMenu;
        OleCheckUTF8(contMenu.QueryContextMenu(menu, 0, 1, $7FFF, CMF_EXPLORE or CMF_CANRENAME));
        contMenu.QueryInterface(IID_IContextMenu2, ICM2); // to handle submenus.
        //------------------------------------------------------------------------------
        { Actions submenu }
        fri := FileList.GetItem(0)^;
        if (FileList.Count = 1) then
          begin
            hActionsSubMenu := CreatePopupMenu;

            // Read actions from doublecmd.ext
            sl:=TStringList.Create;

            if gExts.GetExtActions(fri, sl) then
              begin
              //founded any commands
                InsertMenuItemEx(menu, hActionsSubMenu, PWChar(UTF8Decode(rsMnuActions)), 0, 333, MFT_STRING);
                for i:=0 to sl.Count-1 do
                  begin
                    sCmd:=sl.Strings[i];
                    if pos('VIEW=',sCmd)>0 then Continue;  // view command is only for viewer
                    ReplaceExtCommand(sCmd, @fri, frmMain.ActiveFrame.pnlFile.ActiveDir);

                    sCmd:= RemoveQuotation(sCmd);
                    InsertMenuItemEx(hActionsSubMenu,0, PWChar(UTF8Decode(sCmd)), 0, I + $1000, MFT_STRING);
                  end;
              end;

            if not (FPS_ISDIR(fri.iMode) or (fri.bLinkIsDir)) then
              begin
                if sl.Count = 0 then
                  InsertMenuItemEx(menu, hActionsSubMenu, PWChar(UTF8Decode(rsMnuActions)), 0, 333, MFT_STRING)
                else
                  // now add delimiter
                  InsertMenuItemEx(hActionsSubMenu,0, nil, 0, 0, MFT_SEPARATOR);

                // now add VIEW item
                sCmd:= '{!VIEWER}' + fri.sPath + fri.sName;
                I := sl.Add(sCmd);
                InsertMenuItemEx(hActionsSubMenu,0, PWChar(UTF8Decode(sCmd)), 1, I + $1000, MFT_STRING);

                // now add EDITconfigure item
                sCmd:= '{!EDITOR}' + fri.sPath + fri.sName;
                I := sl.Add(sCmd);
                InsertMenuItemEx(hActionsSubMenu,0, PWChar(UTF8Decode(sCmd)), 1, I + $1000, MFT_STRING);
              end;
          end;
        { /Actions submenu }
        //------------------------------------------------------------------------------
        cmd := UINT(TrackPopupMenu(menu, TPM_LEFTALIGN or TPM_LEFTBUTTON or TPM_RIGHTBUTTON or TPM_RETURNCMD, X, Y, 0, Owner.Handle, nil));
      finally
        if hActionsSubMenu <> 0 then
          DestroyMenu(hActionsSubMenu);
        if menu <> 0 then
          DestroyMenu(menu);
        ICM2 := nil;
      end;

      if (cmd > 0) and (cmd < $1000) then
        begin
          iCmd := LongInt(Cmd) - 1;
          OleCheckUTF8(contMenu.GetCommandString(iCmd, GCS_VERBA, nil, ZVerb, SizeOf(ZVerb)));
          sVerb := StrPas(ZVerb);

          if SameText(sVerb, sCmdVerbDelete) then
            begin
              frmMain.actDelete.Execute;
              bHandled := True;
            end
          else if SameText(sVerb, sCmdVerbRename) then
            begin
              if FileList.Count = 1 then
                with FileList.GetItem(0)^ do
                  begin
                    DebugLn(sNAme);
                    DebugLn(ExtractFileDrive(sName));
                    if sName <> (ExtractFileDrive(sName)+PathDelim) then
                      frmMain.RenameFile('', True)
                    else  // change drive label
                      begin
                        sCmd:= mbGetVolumeLabel(sName, True);
                        if InputQuery(rsMsgSetVolumeLabel, rsMsgVolumeLabel, sCmd) then
                          mbSetVolumeLabel(sName, sCmd);
                      end;
                  end
              else
                frmMain.actRename.Execute;
              bHandled := True;
            end
          else if SameText(sVerb, sCmdVerbOpen) then
            begin
              if FileList.Count = 1 then
                with FileList.GetItem(0)^ do
                  begin
                    if FPS_ISDIR(iMode) or (bLinkIsDir) then
                      begin
                        if sName = '..' then
                          frmMain.ActiveFrame.pnlFile.cdUpLevel
                        else
                          frmMain.ActiveFrame.pnlFile.cdDownLevel(FileList.GetItem(0));
                        bHandled := True;
                      end; // is dir
                  end; // with
            end
          else if SameText(sVerb, sCmdVerbCut) then
            begin
              frmMain.actCutToClipboard.Execute;
              bHandled := True;
            end
          else if SameText(sVerb, sCmdVerbCopy) then
            begin
              frmMain.actCopyToClipboard.Execute;
              bHandled := True;
            end
          else if SameText(sVerb, sCmdVerbPaste) then
            begin
              frmMain.actPasteFromClipboard.Execute;
              bHandled := True;
            end;

          if not bHandled then
            begin
              FillChar(cmici, SizeOf(cmici), #0);
              with cmici do
              begin
                cbSize := sizeof(cmici);
                hwnd := Owner.Handle;
                lpVerb := PChar(cmd - 1);
                nShow := SW_NORMAL;
              end;
              OleCheckUTF8( contMenu.InvokeCommand(cmici) );
            end;

          if SameText(sVerb, sCmdVerbDelete) or SameText(sVerb, sCmdVerbPaste) then
            frmMain.ActiveFrame.RefreshPanel;

        end // if cmd > 0
      else if (cmd >= $1000) then // actions sub menu
        begin
          sCmd:= sl.Strings[cmd - $1000];
          ReplaceExtCommand(sCmd, @fri, frmMain.ActiveFrame.pnlFile.ActiveDir);
          sCmd:= Copy(sCmd, pos('=',sCmd)+1, length(sCmd));
          try
            with frmMain.ActiveFrame do
            begin
              if (Pos('{!VFS}',sCmd)>0) and pnlFile.VFS.FindModule(ActiveDir + fri.sName) then
                begin
                  pnlFile.LoadPanelVFS(@fri);
                  Exit;
                end;
              if not ProcessExtCommand(sCmd, pnlFile.ActiveDir) then
                frmMain.ExecCmd(sCmd);
            end;
          finally
            bHandled:= True;
          end;
        end;

    finally
      FreeAndNil(FileList);
      if Assigned(sl) then
        FreeAndNil(sl);
    end;

  except
    on e: EOleError do
      raise EContextMenuException.Create(e.Message);
  end;
end;
{$ELSE}
var
  fri: TFileRecItem;
  sl: TStringList;
  i: Integer;
  sCmd: String;
  mi, miActions: TMenuItem;
begin
  if FileList.Count = 0 then
  begin
    FreeAndNil(FileList);
    Exit;
  end;

  if not Assigned(CM) then
    CM:= TContextMenu.Create(Owner)
  else
    CM.Items.Clear;

  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actOpen;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Caption:='-';
  CM.Items.Add(mi);

  fri := FileList.GetItem(0)^;
  if (FileList.Count = 1) then
    begin
      FileRecItem:= fri;
      miActions:=TMenuItem.Create(CM);
      miActions.Caption:= rsMnuActions;
  
      { Actions submenu }
      // Read actions from doublecmd.ext
      sl:=TStringList.Create;
      try
        if gExts.GetExtActions(fri, sl) then
          begin
            //founded any commands
            CM.Items.Add(miActions);
            for i:=0 to sl.Count-1 do
              begin
                sCmd:=sl.Strings[i];
                if pos('VIEW=',sCmd)>0 then Continue;  // view command is only for viewer
                ReplaceExtCommand(sCmd, @fri, frmMain.ActiveFrame.pnlFile.ActiveDir);
                mi:=TMenuItem.Create(miActions);
                mi.Caption:=RemoveQuotation(sCmd);
                mi.Hint:=Copy(sCmd, pos('=',sCmd)+1, length(sCmd));
                // length is bad, but in Copy is corrected
                mi.OnClick:=TContextMenu.ContextMenuSelect; // handler
                miActions.Add(mi);
              end;
          end;
        if not (FPS_ISDIR(fri.iMode) or (fri.bLinkIsDir)) then
          begin
            if sl.Count = 0 then
              CM.Items.Add(miActions)
            else
              begin
                // now add delimiter
                mi:=TMenuItem.Create(miActions);
                mi.Caption:='-';
                miActions.Add(mi);
              end;

            // now add VIEW item
            mi:=TMenuItem.Create(miActions);
            mi.Caption:='{!VIEWER}' + fri.sPath + fri.sName;
            mi.Hint:=mi.Caption;
            mi.OnClick:=TContextMenu.ContextMenuSelect; // handler
            miActions.Add(mi);

            // now add EDITconfigure item
            mi:=TMenuItem.Create(miActions);
            mi.Caption:='{!EDITOR}' + fri.sPath + fri.sName;
            mi.Hint:=mi.Caption;
            mi.OnClick:=TContextMenu.ContextMenuSelect; // handler
            miActions.Add(mi);
          end;
      finally
        FreeAndNil(sl);
      end;
     { /Actions submenu }

      mi:=TMenuItem.Create(CM);
      mi.Caption:='-';
      CM.Items.Add(mi);
    end; // if count = 1

  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actRename;
  CM.Items.Add(mi);
  
  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actCopy;
  CM.Items.Add(mi);
  
  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actDelete;
  CM.Items.Add(mi);
  
  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actRenameOnly;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Caption:='-';
  CM.Items.Add(mi);
  
  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actCutToClipboard;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actCopyToClipboard;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actPasteFromClipboard;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Caption:='-';
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actFileProperties;
  CM.Items.Add(mi);
  
  CM.PopUp(X, Y);

  FileList.Free;
end;
{$ENDIF}

procedure ShowDriveContextMenu(Owner: TWinControl; sPath: String; X, Y : Integer);
{$IFDEF MSWINDOWS}
var
  fri: TFileRecItem;
  FileList: TFileList;
  OldErrorMode: Word;
begin
  fri.sName:= sPath;
  FileList:= TFileList.Create; // free in ShowContextMenu
  FileList.AddItem(@fri);
  OldErrorMode:= SetErrorMode(SEM_FAILCRITICALERRORS or SEM_NOOPENFILEERRORBOX);
  ShowContextMenu(Owner, FileList, X, Y);
  SetErrorMode(OldErrorMode);
end;
{$ELSE}
var
  mi: TMenuItem;
begin
  if not Assigned(CM) then
    CM:= TContextMenu.Create(Owner)
  else
    CM.Items.Clear;

  mi:= TMenuItem.Create(CM);
  mi.Caption := rsMnuMount;
  if IsAvailable(sPath) then
    begin
      mi.Enabled:= False;
    end
  else
    begin
      mi.Hint:= '{!MOUNT}' + sPath;
      mi.OnClick:= TContextMenu.DriveContextMenuSelect;
    end;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Caption:= rsMnuUmount;
  if not IsAvailable(sPath) then
    begin
      mi.Enabled:= False;
    end
  else
    begin
      mi.Hint:= '{!UMOUNT}' + sPath;
      mi.OnClick:= TContextMenu.DriveContextMenuSelect;
    end;
  CM.Items.Add(mi);
  
  mi:=TMenuItem.Create(CM);
  mi.Caption:= rsMnuEject;
  mi.Hint:= '{!EJECT}' + sPath;
  mi.OnClick:= TContextMenu.DriveContextMenuSelect;
  CM.Items.Add(mi);

  // show context menu
  CM.PopUp(X, Y);
end;
{$ENDIF}

(* Show file properties dialog *)
procedure ShowFilePropertiesDialog(const FileList:TFileList; const aPath:String);
{$IFDEF UNIX}
begin
  ShowFileProperties(FileList, aPath);
end;
{$ELSE}
var
  cmici: TCMINVOKECOMMANDINFO;
  contMenu: IContextMenu;
  fl : TFileList;
begin
  if FileList.Count = 0 then Exit;

  fl := TFileList.Create;
  try
    CopyListSelectedExpandNames(FileList, fl, aPath, False);
    try
      contMenu := GetIContextMenu(frmMain.Handle, fl);
      if Assigned(contMenu) then
      begin
        FillChar(cmici, sizeof(cmici), #0);
        with cmici do
          begin
            cbSize := sizeof(cmici);
            hwnd := frmMain.Handle;
            lpVerb := 'properties';
            nShow := SW_SHOWNORMAL;
          end;

        OleCheckUTF8(contMenu.InvokeCommand(cmici));
      end;

    except
      on e: EOleError do
        raise EContextMenuException.Create(e.Message);
    end;

  finally
    fl.Free;
  end;
end;
{$ENDIF}

function ShowOpenIconDialog(Owner: TCustomControl; var sFileName : String) : Boolean;
var
  opdDialog : TOpenPictureDialog;
{$IFDEF MSWINDOWS}
  sFilter : String;
  iPos,
  iIconIndex: Integer;
  bAlreadyOpen : Boolean;
{$ENDIF}
begin
  opdDialog := nil;
{$IFDEF MSWINDOWS}
  sFilter := GraphicFilter(TGraphic)+'|'+ 'Programs and Libraries (*.exe;*.dll)|*.exe;*.dll'+'|'+
                       Format('All files (%s)|%s',[GetAllFilesMask, GetAllFilesMask]);
  bAlreadyOpen := False;
  iPos :=Pos(',', sFileName);
  if iPos <> 0 then
    begin
      iIconIndex := StrToIntDef(Copy(sFileName, iPos + 1, Length(sFileName) - iPos), 0);
      sFileName := Copy(sFileName, 1, iPos - 1);
    end
  else
    begin
      opdDialog := TOpenPictureDialog.Create(Owner);
      opdDialog.Filter:= sFilter;;
      Result:= opdDialog.Execute;
      sFileName := opdDialog.FileName;
      bAlreadyOpen := True;
    end;

  if FileIsExeLib(sFileName) then
    begin
      Result := SHChangeIconDialog(Owner.Handle, sFileName, iIconIndex);
      if Result then
        sFileName := sFileName + ',' + IntToStr(iIconIndex);
    end
  else if not bAlreadyOpen then
{$ENDIF}
    begin
      opdDialog := TOpenPictureDialog.Create(Owner);
{$IFDEF MSWINDOWS}
      opdDialog.Filter:= sFilter;
{$ENDIF}
      Result:= opdDialog.Execute;
      sFileName := opdDialog.FileName;
{$IFDEF MSWINDOWS}
      bAlreadyOpen := True;
{$ENDIF}
    end;
  if Assigned(opdDialog) then
    FreeAndNil(opdDialog);
end;

{$IFDEF LINUX}
var
  FileSystemWatcher: TFileSystemWatcher = nil;
type
  TFakeClass = class
    procedure OnWatcherNotifyEvent(Sender: TObject; NotifyData: PtrInt);
  end;

procedure TFakeClass.OnWatcherNotifyEvent(Sender: TObject; NotifyData: PtrInt);
var
  ev: pinotify_event absolute NotifyData;
begin
  if (ev^.mask = IN_DELETE) and (Pos('mtab', PChar(@ev^.name)) = 1) then
    frmMain.UpdateDiskCount;
end;

initialization
  FileSystemWatcher:= TFileSystemWatcher.Create(nil, '/etc', [wfFileNameChange]);
  FileSystemWatcher.OnWatcherNotifyEvent:= TFakeClass.OnWatcherNotifyEvent;
  FileSystemWatcher.Active:= True;
finalization
  if Assigned(FileSystemWatcher) then
    FreeAndNil(FileSystemWatcher);
{$ENDIF}

end.

