{
    Double Commander
    -------------------------------------------------------------------------
    This unit contains platform depended functions.

    Copyright (C) 2006-2008  Koblov Alexander (Alexx2000@mail.ru)

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
  Classes, SysUtils, uTypes, uFileList, Menus, Controls, Graphics, ExtDlgs,
  {$IFDEF UNIX}
  fFileProperties;
  {$ELSE}
  FileUtil, Windows, Messages, ShellApi, ShlObj, ActiveX, uShlObjAdditional, JwaShlGuid, JwaDbt;
  {$ENDIF}
const
  sCmdVerbOpen = 'open';
  sCmdVerbRename = 'rename';
  sCmdVerbDelete = 'delete';
  sCmdVerbPaste = 'paste';

type
  TContextMenu = class(TPopupMenu)
    procedure ContextMenuSelect(Sender:TObject);
  end;

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
procedure ShowFilePropertiesDialog(FileList:TFileList; const aPath:String);
{en
   Show file/folder context menu
   @param(Handle Parent window handle)
   @param(FileList List of files)
   @param(X X coordinate)
   @param(Y Y coordinate)
}
procedure ShowContextMenu(Handle : THandle; FileList : TFileList; X, Y : Integer);
{en
   Show open icon dialog
   @param(Owner Owner)
   @param(sFileName Icon file name)
   @returns(The function returns @true if successful, @false otherwise)
}
function ShowOpenIconDialog(Owner: TCustomControl; var sFileName : String) : Boolean;

implementation

uses
  LCLProc, fMain, uVFSutil, uOSUtils, uExts, uGlobs;

var
{$IFDEF MSWINDOWS}
  OldWProc: WNDPROC;
  ICM2: IContextMenu2 = nil;
{$ELSE}
  CM : TContextMenu = nil;
{$ENDIF}

{$IFDEF MSWINDOWS}
function MyWndProc(hwnd: HWND; Msg, wParam, lParam: Cardinal): Cardinal; stdcall;
begin
  case Msg of
    (* For working with submenu of contex menu *)
    WM_INITMENUPOPUP,
    WM_DRAWITEM,
    WM_MENUCHAR,
    WM_MEASUREITEM:
      if Assigned(ICM2) then
        begin
          ICM2.HandleMenuMsg(Msg, wParam, lParam);
          Result := 0;
        end
      else
        Result := CallWindowProc(OldWProc, hwnd, Msg, wParam, lParam);
        
    WM_DEVICECHANGE:
      if (wParam = DBT_DEVICEARRIVAL) or (wParam = DBT_DEVICEREMOVECOMPLETE) then
        frmMain.UpdateDiskCount;
  else
    Result := CallWindowProc(OldWProc, hwnd, Msg, wParam, lParam);
  end; // case
end;
{$ENDIF}

procedure SetMyWndProc(Handle : THandle);
{$IFDEF MSWINDOWS}
begin
  OldWProc := WNDPROC(SetWindowLong(Handle, GWL_WNDPROC, Integer(@MyWndProc)));
end;
{$ELSE}
begin
end;
{$ENDIF}

(* handling user commands from context menu *)
procedure TContextMenu.ContextMenuSelect(Sender:TObject);
var
  sCmd:String;
begin
//  ShowMessage((Sender as TMenuItem).Hint);
  sCmd:=(Sender as TMenuItem).Hint;
  with frmMain.ActiveFrame do
  begin
    if Pos('{!VFS}',sCmd)>0 then
     begin
        pnlFile.LoadPanelVFS(PFileRecItem((Sender as TMenuItem).Tag));
        Exit;
      end;
    if not pnlFile.ProcessExtCommand(sCmd) then
      frmMain.ExecCmd(sCmd);
  end;
end;

{$IFDEF MSWINDOWS}
function GetIContextMenu(Handle : THandle; FileList : TFileList): IContextMenu;
type
  TPIDLArray = array[0..0] of PItemIDList;
  PPIDLArray = ^TPIDLArray;

var
  Folder,
  DesktopFolder: IShellFolder;
  PathPIDL,
  tmpPIDL: PItemIDList;
  malloc: IMalloc;
  S: WideString;
  List: PPIDLArray;
  I : Integer;
  pchEaten,
  dwAttributes: ULONG;
begin
  Result := nil;
  if not Succeeded(SHGetMalloc(malloc)) then Exit;
  if not Succeeded(SHGetDesktopFolder(DeskTopFolder)) then Exit;

  try
    List := malloc.Alloc(SizeOf(PItemIDList)*FileList.Count);
    for I := 0 to FileList.Count - 1 do
      begin
      //**********   if s <> sPath then
        S := FileList.GetItem(I)^.sPath;
        
        OleCheck(DeskTopFolder.ParseDisplayName(Handle, nil, PWideChar(S), pchEaten, PathPIDL, dwAttributes));
        try
          OleCheck(DeskTopFolder.BindToObject(PathPIDL, nil, IID_IShellFolder, Folder));
        finally
          malloc.Free(PathPIDL);
        end;
      //*****************

        S:=FileList.GetItem(I)^.sName;;
        OleCheck(Folder.ParseDisplayName(Handle, nil, PWideChar(S), pchEaten, tmpPIDL, dwAttributes));
        List^[i] := tmpPIDL;
      end;

    Folder.GetUIObjectOf(Handle, FileList.Count, PItemIDList(List^), IID_IContextMenu, nil, Result);
  finally
    for I := 0 to FileList.Count - 1 do
      malloc.Free(List^[i]);
    malloc.Free(List);
  end;
end;
{$ENDIF}

procedure ShowContextMenu(Handle : THandle; FileList : TFileList; X, Y : Integer);
var
{$IFDEF MSWINDOWS}
  contMenu: IContextMenu;
  menu: HMENU;
  cmd: UINT;
  iCmd: Integer;
  HR: HResult;
  cmici: CMINVOKECOMMANDINFO;
  bHandled : Boolean;
  ZVerb: array[0..255] of char;
  sVerb : String;
{$ELSE}
  fri : TFileRecItem;
  mi, miActions : TMenuItem;
  i:Integer;
  sCmd:String;
  sl: TStringList;
{$ENDIF}
begin
  if FileList.Count = 0 then Exit;

{$IFDEF MSWINDOWS}
  contMenu := GetIContextMenu(Handle, FileList);
  menu := CreatePopupMenu;
  try
    OleCheck( contMenu.QueryContextMenu(menu, 0, 1, $7FFF, CMF_EXPLORE or CMF_CANRENAME) );
    //AppendMenu(menu,0,0,'Test');
    contMenu.QueryInterface(IID_IContextMenu2, ICM2); // to handle submenus.
    cmd := UINT(TrackPopupMenu(menu, TPM_LEFTALIGN or TPM_LEFTBUTTON or TPM_RIGHTBUTTON or TPM_RETURNCMD, X, Y, 0, Handle, nil));
  finally
    DestroyMenu(menu);
    ICM2 := nil;
  end;
  
  if cmd > 0 then
    begin
      iCmd := LongInt(Cmd) - 1;
      HR := contMenu.GetCommandString(iCmd, GCS_VERBA, nil, ZVerb, SizeOf(ZVerb));
      sVerb := StrPas(ZVerb);
      bHandled := False;

      if SameText(sVerb, sCmdVerbDelete) then
        begin
          frmMain.actDelete.Execute;
          bHandled := True;
        end
      else if SameText(sVerb, sCmdVerbRename) then
        begin
          if FileList.Count = 1 then
            frmMain.RenameFile('')
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
        end;

      if not bHandled then
        begin
          FillChar(cmici, SizeOf(cmici), #0);
          with cmici do
          begin
            cbSize := sizeof(cmici);
            hwnd := Handle;
            lpVerb := PChar(cmd - 1);
            nShow := SW_NORMAL;
          end;
          OleCheck( contMenu.InvokeCommand(cmici) );
        end;
        
      if SameText(sVerb, sCmdVerbDelete) or SameText(sVerb, sCmdVerbPaste) then
        frmMain.ActiveFrame.RefreshPanel;

    end; // if cmd > 0
    FileList.Free;
end;
{$ELSE}
  if not Assigned(CM) then
    CM := TContextMenu.Create(nil)
  else
    CM.Items.Clear;

  mi:=TMenuItem.Create(CM);
  mi.Action := frmMain.actOpen;
  CM.Items.Add(mi);

  mi:=TMenuItem.Create(CM);
  mi.Caption:='-';
  CM.Items.Add(mi);

  fri := FileList.GetItem(0)^;
  if (FileList.Count = 1) and not (FPS_ISDIR(fri.iMode) or (fri.bLinkIsDir)) then
    begin
      miActions:=TMenuItem.Create(CM);
      miActions.Caption:='Actions';
      CM.Items.Add(miActions);
  
      { Actions submenu }
      // Read actions from doublecmd.ext
      sl:=TStringList.Create;
      try
        if gExts.GetExtActions(lowercase(ExtractFileExt(fri.sName)),sl) then
          begin
          //founded any commands
            for i:=0 to sl.Count-1 do
              begin
                sCmd:=sl.Strings[i];
                if pos('VIEW=',sCmd)>0 then Continue;  // view command is only for viewer
                frmMain.ActiveFrame.pnlFile.ReplaceExtCommand(sCmd, @fri);
                mi:=TMenuItem.Create(miActions);
                mi.Caption:=sCmd;
                mi.Hint:=Copy(sCmd, pos('=',sCmd)+1, length(sCmd));
                // length is bad, but in Copy is corrected
                mi.OnClick:=TContextMenu.ContextMenuSelect; // handler
                mi.Tag:=Integer(@fri);
                miActions.Add(mi);
              end;
          end;
    
        // now add delimiter
        mi:=TMenuItem.Create(miActions);
        mi.Caption:='-';
        miActions.Add(mi);

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
  mi.Action := frmMain.actFileProperties;
  CM.Items.Add(mi);
  
  CM.PopUp(X, Y);

  FileList.Free;
end;
{$ENDIF}

(* Show file properties dialog *)
procedure ShowFilePropertiesDialog(FileList:TFileList; const aPath:String);
{$IFDEF UNIX}
begin
  ShowFileProperties(FileList, aPath);
end;
{$ELSE}
var
  cmici: CMINVOKECOMMANDINFO;
  contMenu: IContextMenu;
  fl : TFileList;
begin
  if FileList.Count = 0 then Exit;

  fl := TFileList.Create;
  CopyListSelectedExpandNames(FileList, fl, aPath, False);
  contMenu := GetIContextMenu(frmMain.Handle, fl);

  FillChar(cmici, sizeof(cmici), #0);
  with cmici do
    begin
      cbSize := sizeof(cmici);
      hwnd := frmMain.Handle;
      lpVerb := 'properties';
      nShow := SW_SHOWNORMAL;
    end;

  OleCheck(contMenu.InvokeCommand(cmici));
  fl.Free;
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
  sFilter := GraphicFilter(TGraphic)+'|'+ 'Programs and Libraries(*.exe;*.dll)|*.exe;*.dll'+'|'+
                       Format('All files (%s)',[GetAllFilesMask]);
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

end.

