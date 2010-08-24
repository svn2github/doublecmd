{
    Double Commander
    -------------------------------------------------------------------------
    This unit contains specific WINDOWS functions.

    Copyright (C) 2006-2010  Koblov Alexander (Alexx2000@mail.ru)

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

unit uMyWindows;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, JwaWinBase, Windows;

type
  tagMENUITEMINFOW = record
    cbSize: UINT;
    fMask: UINT;
    fType: UINT;            // used if MIIM_TYPE (4.0) or MIIM_FTYPE (>4.0)
    fState: UINT;           // used if MIIM_STATE
    wID: UINT;              // used if MIIM_ID
    hSubMenu: HMENU;        // used if MIIM_SUBMENU
    hbmpChecked: HBITMAP;   // used if MIIM_CHECKMARKS
    hbmpUnchecked: HBITMAP; // used if MIIM_CHECKMARKS
    dwItemData: ULONG_PTR;  // used if MIIM_DATA
    dwTypeData: LPWSTR;     // used if MIIM_TYPE (4.0) or MIIM_STRING (>4.0)
    cch: UINT;              // used if MIIM_TYPE (4.0) or MIIM_STRING (>4.0)
    hbmpItem: HBITMAP;      // used if MIIM_BITMAP
  end;

  MENUITEMINFOW = tagMENUITEMINFOW;
  LPMENUITEMINFOW = ^MENUITEMINFOW;
  LPCMENUITEMINFOW = ^MENUITEMINFOW;
  TMenuItemInfoW = MENUITEMINFOW;
  PMenuItemInfoW = LPMENUITEMINFOW;

function InsertMenuItemW(hMenu: HMENU; uItem: UINT; fByPosition: BOOL;
                         const lpmii: MENUITEMINFOW): BOOL; stdcall; external 'user32' name 'InsertMenuItemW';

{en
   Extracts volume GUID from a volume GUID path
}
function ExtractVolumeGUID(const VolumeName: WideString): WideString;
{en
   Retrieves a volume GUID path for the volume that is associated with the specified
   volume mount point (drive letter, volume GUID path, or mounted folder)
   @param(Path The string that contains the path of a mounted folder or a drive letter)
   @returns(Volume GUID path)
}
function GetMountPointVolumeName(const Path: WideString): WideString;
{en
   Checks readiness of a drive
   @param(sDrv  String specifying the root directory of a file system volume)
   @returns(The function returns @true if drive is ready, @false otherwise)
}
function mbDriveReady(const sDrv: UTF8String): Boolean;
{en
   Get the label of a file system volume
   @param(sDrv  String specifying the root directory of a file system volume)
   @param(bVolReal @true if it a real file system volume)
   @returns(The function returns volume label)
}
function mbGetVolumeLabel(const sDrv: UTF8String; const bVolReal: Boolean): UTF8String;
{en
   Set the label of a file system volume
   @param(sRootPathName  String specifying the root directory of a file system volume)
   @param(sVolumeName String specifying a new name for the volume)
   @returns(The function returns @true if successful, @false otherwise)
}
function mbSetVolumeLabel(sRootPathName, sVolumeName: UTF8String): Boolean;
{en
   Wait for change disk label
   @param(sDrv  String specifying the root directory of a file system volume)
   @param(sCurLabel Current volume label)
}
procedure mbWaitLabelChange(const sDrv: UTF8String; const sCurLabel: UTF8String);
{en
   Close CD/DVD drive
   @param(sDrv  String specifying the root directory of a drive)
}
procedure mbCloseCD(const sDrv: UTF8String);
{en
   Get remote file name by local file name
   @param(sLocalName String specifying the local file name)
   @returns(The function returns remote file name)
}
function mbGetRemoteFileName(const sLocalName: UTF8String): UTF8String;
{en
   Retrieves the short path form of the specified path
   @param(sLongPath The path string)
   @param(sShortPath A string to receive the short form of the path that sLongPath specifies)
   @returns(The function returns @true if successful, @false otherwise)
}
function mbGetShortPathName(const sLongPath: UTF8String; out sShortPath: AnsiString): Boolean;
{en
   Retrieves owner of the file (user and group).
   Both user and group contain computer name.
   @param(sPath Absolute path to the file. May be UNC path.)
   @param(sUser Returns user name of the file.)
   @param(sGroup Returns primary group of the file.)
}
function GetFileOwner(const sPath: String; out sUser, sGroup: String): Boolean;
{en
   Retrieves a description of file's type.
   @param(sPath Absolute path to the file.)
}
function GetFileDescription(const sPath: String): String;

implementation

uses
  LCLProc, ShellAPI, MMSystem, JwaWinNetWk, uShlObjAdditional;

function mciSendCommand(IDDevice: MCIDEVICEID; uMsg: UINT; fdwCommand: DWORD; dwParam: DWORD_PTR): MCIERROR; stdcall; external 'winmm.dll' name 'mciSendCommandA';

function DisplayName(const wsDrv: WideString): WideString;
var
  SFI: TSHFileInfoW;
begin
  FillChar(SFI, SizeOf(SFI), 0);
  SHGetFileInfoW(PWChar(wsDrv), 0, SFI, SizeOf(SFI), SHGFI_DISPLAYNAME);
  Result:= SFI.szDisplayName;

  if Pos('(', Result) <> 0 then
    SetLength(Result, Pos('(', Result) - 2);
end;

function ExtractVolumeGUID(const VolumeName: WideString): WideString;
var
  I, J: LongInt;
begin
  I:= Pos('{', VolumeName);
  J:= Pos('}', VolumeName);
  if (I = 0) or (J = 0) then Exit(EmptyStr);
  Result:= Copy(VolumeName, I, J - I + 1);
end;

function GetMountPointVolumeName(const Path: WideString): WideString;
const
  MAX_VOLUME_NAME = 50;
var
  wsPath: WideString;
  wsVolumeName: array[0..Pred(MAX_VOLUME_NAME)] of WideChar;
begin
  FillByte(wsVolumeName, MAX_VOLUME_NAME, 0);
  wsPath:= IncludeTrailingPathDelimiter(Path);
  if not GetVolumeNameForVolumeMountPointW(PWideChar(wsPath), wsVolumeName, MAX_VOLUME_NAME) then
    Result:= EmptyStr
  else
    Result:= WideString(wsVolumeName);
end;

(* Drive ready *)

function mbDriveReady(const sDrv: UTF8String): Boolean;
var
  NotUsed: DWORD;
  wsDrv: WideString;
begin
  wsDrv:= UTF8Decode(sDrv);
  Result:= GetVolumeInformationW(PWChar(wsDrv), nil, 0, nil, NotUsed, NotUsed, nil, 0);
end;

(* Disk label *)

function mbGetVolumeLabel(const sDrv: UTF8String; const bVolReal: Boolean): UTF8String;
var
  WinVer: Byte;
  DriveType, NotUsed: DWORD;
  Buf: array [0..MAX_PATH - 1] of WideChar;
  wsDrv,
  wsResult: WideString;
begin
  Result:= '';
  wsDrv:= UTF8Decode(sDrv);
  WinVer:= LOBYTE(LOWORD(GetVersion));
  DriveType:= GetDriveTypeW(PWChar(wsDrv));

  if (WinVer <= 4) and (DriveType <> DRIVE_REMOVABLE) or bVolReal then
    begin // Win9x, Me, NT <= 4.0
      Buf[0]:= #0;
      GetVolumeInformationW(PWChar(wsDrv), Buf, DWORD(SizeOf(Buf)), nil,
                            NotUsed, NotUsed, nil, 0);
      wsResult:= Buf;

      if bVolReal and (WinVer >= 5) and (Result <> '') and
         (DriveType <> DRIVE_REMOVABLE) then // Win2k, XP and higher
        wsResult:= DisplayName(wsDrv)
      else if (Result = '') and (not bVolReal) then
        wsResult:= '<none>';
    end
  else
    wsResult:= DisplayName(wsDrv);
  Result:= UTF8Encode(wsResult);
end;

(* Wait for change disk label *)

function mbSetVolumeLabel(sRootPathName, sVolumeName: UTF8String): Boolean;
var
  wsRootPathName,
  wsVolumeName: WideString;
begin
  wsRootPathName:= UTF8Decode(sRootPathName);
  wsVolumeName:= UTF8Decode(sVolumeName);
  Result:= SetVolumeLabelW(PWChar(wsRootPathName), PWChar(wsVolumeName));
end;

procedure mbWaitLabelChange(const sDrv: UTF8String; const sCurLabel: UTF8String);
var
  st1, st2: UTF8String;
begin
  if mbGetVolumeLabel(sDrv, True) = '' then
    Exit;
  st1:= TrimLeft(sCurLabel);
  st2:= st1;
  while st1 = st2 do
    st2:= mbGetVolumeLabel(sDrv, FALSE);
end;

(* Close CD/DVD *)

procedure mbCloseCD(const sDrv: UTF8String);
var
  OpenParms: MCI_OPEN_PARMS;
begin
  FillChar(OpenParms, SizeOf(OpenParms), 0);
  OpenParms.lpstrDeviceType:= 'CDAudio';
  OpenParms.lpstrElementName:= PChar(ExtractFileDrive(sDrv));
  mciSendCommand(0, MCI_OPEN, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, DWORD_PTR(@OpenParms));
  mciSendCommand(OpenParms.wDeviceID, MCI_SET, MCI_SET_DOOR_CLOSED, 0);
  mciSendCommand(OpenParms.wDeviceID, MCI_CLOSE, MCI_OPEN_TYPE or MCI_OPEN_ELEMENT, DWORD_PTR(@OpenParms));
end;

function mbGetRemoteFileName(const sLocalName: UTF8String): UTF8String;
var
  wsLocalName: WideString;
  dwResult,
  lpBufferSize: DWORD;
  lpBuffer: PUniversalNameInfoW;
begin
  Result:= sLocalName;
  wsLocalName:= UTF8Decode(sLocalName);
  lpBufferSize:= SizeOf(TUniversalNameInfoW);
  GetMem(lpBuffer, lpBufferSize);
  try
    dwResult:= WNetGetUniversalNameW(PWideChar(wsLocalName), UNIVERSAL_NAME_INFO_LEVEL, lpBuffer, lpBufferSize);
    if dwResult = ERROR_MORE_DATA then
      begin
        lpBuffer:= ReallocMem(lpBuffer, lpBufferSize);
        dwResult:= WNetGetUniversalNameW(PWideChar(wsLocalName), UNIVERSAL_NAME_INFO_LEVEL, lpBuffer, lpBufferSize);
      end;
    if dwResult = NO_ERROR then
      Result:= UTF8Encode(WideString(lpBuffer^.lpUniversalName));
  finally
    FreeMem(lpBuffer);
  end;
end;

function mbGetShortPathName(const sLongPath: UTF8String; out sShortPath: AnsiString): Boolean;
var
  wsLongPath,
  wsShortPath: WideString;
  cchBuffer: DWORD;
begin
  Result:= False;
  wsLongPath:= UTF8Decode(sLongPath);
  cchBuffer:= GetShortPathNameW(PWideChar(wsLongPath), nil, 0);
  if cchBuffer = 0 then Exit;
  SetLength(wsShortPath, cchBuffer);
  cchBuffer:= GetShortPathNameW(PWideChar(wsLongPath), PWideChar(wsShortPath), cchBuffer);
  if cchBuffer <> 0 then
    begin
      sShortPath:= wsShortPath;
      Result:= True;
    end;
end;

function GetFileOwner(const sPath: String; out sUser, sGroup: String): Boolean;
var
  wsMachineName: WideString;

  function SidToDisplayString(sid: PSID; sidType: SID_NAME_USE): String;
  var
    pName: PWideChar = nil;
    pDomain: PWideChar = nil;
    NameLen: DWORD = 0;
    DomainLen: DWORD = 0;
  begin
    // We're expecting insufficient buffer error here.
    if (LookupAccountSidW(PWideChar(wsMachineName), sid,
                          nil, @NameLen,
                          nil, @DomainLen,
                          @SidType) = False) and
       (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
    begin
      pName := Getmem(NameLen * SizeOf(WideChar));
      pDomain := Getmem(DomainLen * SizeOf(WideChar));

      if Assigned(pName) and Assigned(pDomain) and
         LookupAccountSidW(PWideChar(wsMachineName), sid,
                           pName, @NameLen,
                           pDomain, @DomainLen,
                           @SidType) then
      begin
        if pDomain[0] <> #0 then
          Result := UTF8Encode(WideString(pDomain) + PathDelim + WideString(pName))
        else
          Result := UTF8Encode(WideString(pName));
      end
      else
        Result := EmptyStr;

      Freemem(pName);
      Freemem(pDomain);
    end
    else
      Result := EmptyStr;
  end;

  // From UNC name extracts computer name.
  function GetMachineName(wPathName: LPCWSTR): WideString;
  var
    lpMachineName,
    lpMachineNameNext: PWideChar;
  begin
    lpMachineName := PathFindNextComponentW(wPathName);

    if Assigned(lpMachineName) then
    begin
      lpMachineNameNext := PathFindNextComponentW(lpMachineName);

      if Assigned(lpMachineNameNext) then
        SetString(Result, lpMachineName, lpMachineNameNext - lpMachineName - 1)
      else
        Result := lpMachineName;
    end
    else
      Result := EmptyWideStr;
  end;

var
  wszUNCPathName: array[0..32767] of WideChar;
  wsPathName: WideString;
  pSecurityDescriptor: PSECURITY_DESCRIPTOR = nil;
  pOwnerSid: PSID = nil;
  pUNI: PUniversalNameInfoW;
  bDefault: Boolean;
  dwBufferSize: DWORD = 0;
  dwSizeNeeded: DWORD = 0;
begin
  Result := False;

  if Length(sPath) = 0 then
    Exit;

  try
    wsPathName := UTF8Decode(sPath);

    // Check if the path is to remote share and get remote machine name.

    if PathIsUNCW(PWideChar(wsPathName)) then
    begin
      // Path is in full UNC format.
      wsMachineName := GetMachineName(PWideChar(wsPathName));
    end
    else
    begin
      // Check if local path is mapped to network share.
      dwBufferSize := SizeOf(wszUNCPathName);
      pUNI := PUniversalNameInfoW(@wszUNCPathName[0]);
      if WNetGetUniversalNameW(PWideChar(wsPathName),
           UNIVERSAL_NAME_INFO_LEVEL, pUNI, dwBufferSize) = NO_ERROR then
      begin
        wsMachineName := GetMachineName(pUNI^.lpUniversalName);
      end;
      // else not a network share, no network connection, etc.
    end;

    { Get security descriptor. }

    // We're expecting insufficient buffer error here.
    if (GetFileSecurityW(PWideChar(wsPathName),
                         OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION,
                         nil, 0, @dwSizeNeeded) <> False) or
       (GetLastError <> ERROR_INSUFFICIENT_BUFFER) or
       (dwSizeNeeded = 0) then
    begin
      Exit;
    end;

    pSecurityDescriptor := GetMem(dwSizeNeeded);
    if not Assigned(pSecurityDescriptor) then
      Exit;

    if not GetFileSecurityW(PWideChar(wsPathName),
                            OWNER_SECURITY_INFORMATION or GROUP_SECURITY_INFORMATION,
                            pSecurityDescriptor,
                            dwSizeNeeded, @dwSizeNeeded) then
    begin
      Exit;
    end;

    { Get Owner and Group. }

    if GetSecurityDescriptorOwner(pSecurityDescriptor, pOwnerSid, @bDefault) then
      sUser := SidToDisplayString(pOwnerSid, SidTypeUser)
    else
      sUser := EmptyStr;

    if GetSecurityDescriptorGroup(pSecurityDescriptor, pOwnerSid, @bDefault) then
      sGroup := SidToDisplayString(pOwnerSid, SidTypeGroup)
    else
      sGroup := EmptyStr;

    Result := True;

  finally
    if Assigned(pSecurityDescriptor) then
      Freemem(pSecurityDescriptor);
  end;
end;

function GetFileDescription(const sPath: String): String;
var
  SFI: TSHFileInfoW;
begin
  FillChar(SFI, SizeOf(SFI), 0);
  if SHGetFileInfoW(PWideChar(UTF8Decode(sPath)), 0, SFI, SizeOf(SFI), SHGFI_TYPENAME) <> 0 then
    Result := UTF8Encode(WideString(SFI.szTypeName))
  else
    Result := EmptyStr;
end;

end.

