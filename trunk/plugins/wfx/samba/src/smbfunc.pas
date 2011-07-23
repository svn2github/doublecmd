{
   Double commander
   -------------------------------------------------------------------------
   WFX plugin for working with Common Internet File System (CIFS)

   Copyright (C) 2011  Koblov Alexander (Alexx2000@mail.ru)

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}

unit SmbFunc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, WfxPlugin;

function FsInit(PluginNr: Integer; pProgressProc: TProgressProc; pLogProc: TLogProc; pRequestProc: TRequestProc): Integer; stdcall;

function FsFindFirst(Path: PAnsiChar; var FindData: TWin32FindData): THandle; stdcall;
function FsFindNext(Hdl: THandle; var FindData: TWin32FindData): BOOL; stdcall;
function FsFindClose(Hdl: THandle): Integer; stdcall;

function FsDeleteFile(RemoteName: PAnsiChar): BOOL; stdcall;

function FsMkDir(RemoteDir: PAnsiChar): BOOL; stdcall;
function FsRemoveDir(RemoteName: PAnsiChar): BOOL; stdcall;

implementation

uses
  Unix, BaseUnix, UnixType, StrUtils, libsmbclient;

type
  PSambaHandle = ^TSambaHandle;
  TSambaHandle = record
    Path: String;
    Handle: LongInt;
  end;

var
  ProgressProc: TProgressProc;
  LogProc: TLogProc;
  RequestProc: TRequestProc;
  PluginNumber: Integer;
  Abort: Boolean = False;
  NeedAuth: Boolean = False;
  UserName: array[0..MAX_PATH-1] of AnsiChar;
  Password: array[0..MAX_PATH-1] of AnsiChar;

function FileTimeToUnixTime(ft: TFileTime): time_t;
var
  UnixTime: Int64;
begin
  UnixTime:= ft.dwHighDateTime;
  UnixTime:= (UnixTime shl 32) or ft.dwLowDateTime;
  UnixTime:= (UnixTime - 116444736000000000) div 10000000;
  Result:= time_t(UnixTime);
end;

function UnixTimeToFileTime(mtime: time_t): TFileTime;
var
  FileTime: Int64;
begin
  FileTime:= Int64(mtime) * 10000000 + 116444736000000000;
  Result.dwLowDateTime:= (FileTime and $FFFF);
  Result.dwHighDateTime:= (FileTime shr $20);
end;

procedure WriteError(const FuncName: String);
begin
  WriteLn(FuncName + ': ', SysErrorMessage(GetLastOSError));
end;

procedure smbc_get_auth_data(server, share: PAnsiChar;
                                  wg: PAnsiChar; wglen: LongInt;
                                  un: PAnsiChar; unlen: LongInt;
                                  pw: PAnsiChar; pwlen: LongInt); cdecl;
begin
  if NeedAuth then
  begin
    Abort:= True;

    // Query user name
    if RequestProc(PluginNumber, RT_UserName, nil, nil, un, unlen) then
    begin
      Abort:= False;
      // Save user name
      StrLCopy(UserName, un, unlen);
    end;

    if Abort then Exit;

    // Query password
    if RequestProc(PluginNumber, RT_Password, nil, nil, pw, pwlen) then
    begin
      Abort:= False;
      // Save password
      StrLCopy(Password, pw, pwlen);
    end;
  end
  else
    begin
      // If has saved user name then use it
      if StrLen(UserName) <> 0 then
        StrLCopy(un, UserName, unlen);
      // If has saved password then use it
      if StrLen(Password) <> 0 then
        StrLCopy(pw, Password, pwlen);
    end;
end;

function BuildNetworkPath(const Path: String): String;
var
  I, C: Integer;
begin
  C:= 0;
  if Path = PathDelim then Exit('smb://');
  Result := Path;
  // Don't check last symbol
  for I := 1 to Length(Result) - 1 do
  begin
    if (Result[I] = PathDelim) then
      Inc(C);
  end;
  if (C < 2) then
    Result:= 'smb:/' + Result
  else
    begin
      I:= PosEx(PathDelim, Result, 2);
      Result:= 'smb:/' + Copy(Result, I, MaxInt);
    end;
end;

function FsInit(PluginNr: Integer; pProgressProc: tProgressProc; pLogProc: tLogProc; pRequestProc: tRequestProc): Integer; stdcall;
begin
  if not LoadSambaLibrary then
  begin
    pRequestProc(PluginNr, RT_MsgOK, nil, 'Can not load "libsmbclient" library!', nil, 0);
    Exit(-1);
  end;
  ProgressProc := pProgressProc;
  LogProc := pLogProc;
  RequestProc := pRequestProc;
  PluginNumber := PluginNr;
  FillChar(UserName, SizeOf(UserName), #0);
  FillChar(Password, SizeOf(Password), #0);

  Result := smbc_init(@smbc_get_auth_data, 0);
  if Result < 0 then WriteError('smbc_init');
end;

function FsFindFirst(Path: PAnsiChar; var FindData: TWin32FindData): THandle; stdcall;
var
  NetworkPath: String;
  SambaHandle: PSambaHandle;
  Handle: LongInt;
  r: Boolean;
  h:LongInt;
begin
  Abort:= False;
  NetworkPath:= BuildNetworkPath(Path);
  repeat
    Handle:= smbc_opendir(PChar(NetworkPath));
    NeedAuth:= (Handle = -1);
  until not NeedAuth or Abort;
  if Handle < 0 then
    begin
      WriteError('smbc_opendir');
      Result:= wfxInvalidHandle;
    end
  else
    begin
      New(SambaHandle);
      SambaHandle^.Path:= IncludeTrailingPathDelimiter(NetworkPath);
      SambaHandle^.Handle:= Handle;
      Result:= THandle(SambaHandle);
      FsFindNext(Result, FindData);
    end;
end;

function FsFindNext(Hdl: THandle; var FindData: TWin32FindData): BOOL; stdcall;
var
  dirent: psmbc_dirent;
  FileInfo: BaseUnix.Stat;
  SambaHandle: PSambaHandle absolute Hdl;
begin
  Result:= True;
  dirent := smbc_readdir(SambaHandle^.Handle);
  if (dirent = nil) then Exit(False);
  FillByte(FindData, SizeOf(TWin32FindData), 0);
  StrLCopy(FindData.cFileName, dirent^.name, dirent^.namelen);
  if dirent^.smbc_type in [SMBC_WORKGROUP, SMBC_SERVER, SMBC_FILE_SHARE] then
    FindData.dwFileAttributes:= FILE_ATTRIBUTE_DIRECTORY;
  if dirent^.smbc_type in [SMBC_DIR, SMBC_FILE, SMBC_LINK] then
    begin
      if smbc_stat(PChar(SambaHandle^.Path + FindData.cFileName), @FileInfo) = 0 then
      begin
        FindData.dwFileAttributes:= FILE_ATTRIBUTE_UNIX_MODE;
        FindData.dwReserved0:= FileInfo.st_mode;
        FindData.nFileSizeLow := (FileInfo.st_size and $FFFF);
        FindData.nFileSizeHigh := (FileInfo.st_size shr $20);
        FindData.ftLastAccessTime:= UnixTimeToFileTime(FileInfo.st_atime);
        FindData.ftCreationTime:= UnixTimeToFileTime(FileInfo.st_ctime);
        FindData.ftLastWriteTime:= UnixTimeToFileTime(FileInfo.st_mtime);
      end;
  end;
end;

function FsFindClose(Hdl: THandle): Integer; stdcall;
var
  SambaHandle: PSambaHandle absolute Hdl;
begin
  Result:= smbc_closedir(SambaHandle^.Handle);
  if Result < 0 then WriteError('smbc_closedir');
  Dispose(SambaHandle);
end;

function FsDeleteFile(RemoteName: PAnsiChar): BOOL; stdcall;
var
  FileName: String;
begin
  FileName:= BuildNetworkPath(RemoteName);
  Result:= smbc_unlink(PChar(FileName)) = 0;
end;

function FsMkDir(RemoteDir: PAnsiChar): BOOL; stdcall;
var
  NewDir: String;
begin
  NewDir:= BuildNetworkPath(RemoteDir);
  Result:= smbc_mkdir(PChar(NewDir), $1FF) = 0; // $1FF = &0777
end;

function FsRemoveDir(RemoteName: PAnsiChar): BOOL; stdcall;
var
  RemDir: String;
begin
  RemDir:= BuildNetworkPath(RemoteName);
  Result:= smbc_rmdir(PChar(RemDir)) = 0;
end;

end.

