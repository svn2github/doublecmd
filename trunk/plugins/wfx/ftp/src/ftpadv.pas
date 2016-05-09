{
   Double commander
   -------------------------------------------------------------------------
   WFX plugin for working with File Transfer Protocol

   Copyright (C) 2009-2016 Alexander Koblov (alexx2000@mail.ru)

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
}

unit FtpAdv;

{$mode delphi}

interface

uses
  Classes, SysUtils, WfxPlugin, FtpSend, LazUTF8Classes, LConvEncoding,
  DCConvertEncoding;

type
  TConvertUTF8ToEncodingFunc = function(const S: String {$IFDEF FPC_HAS_CPSTRING}; SetTargetCodePage: Boolean = False{$ENDIF}): RawByteString;

type

  { EUserAbort }

  EUserAbort = class(Exception);

  { TFTPListRecEx }

  TFTPListRecEx = class(TFTPListRec)
  public
    procedure Assign(Value: TFTPListRec); override;
  end;

  { TFTPListEx }

  TFTPListEx = class(TFTPList)
  public
    procedure Assign(Value: TFTPList); override;
  end;

  { TProgressStream }

  TProgressStream = class(TFileStreamUTF8)
  public
    DoneSize: Int64;
    FileSize: Int64;
    PluginNumber: Integer;
    ProgressProc: TProgressProcW;
    RemoteName, LocalName: PWideChar;
  private
    procedure DoProgress(Result: Integer);
  public
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

  { TFTPSendEx }

  TFTPSendEx = class(TFTPSend)
  private
    FAuto: Boolean;
    FUnicode: Boolean;
    FSetTime: Boolean;
    FMachine: Boolean;
  private
    ConvertToUtf8: TConvertEncodingFunction;
    ConvertFromUtf8: TConvertUTF8ToEncodingFunc;
  protected
    function Connect: Boolean; override;
    function DataSocket: Boolean; override;
    function ListMachine(Directory: String): Boolean;
    procedure DoStatus(Response: Boolean; const Value: string); override;
  public
    function ClientToServer(const Value: UnicodeString): AnsiString;
    function ServerToClient(const Value: AnsiString): UnicodeString;
  public
    constructor Create(const Encoding: String); reintroduce;
    function Login: Boolean; override;
    procedure ParseRemote(Value: string); override;
    function List(Directory: String; NameList: Boolean): Boolean; override;
    function SetTime(const FileName: String; FileTime: TFileTime): Boolean;
    function StoreFile(const FileName: string; Restore: Boolean): Boolean; override;
    function RetrieveFile(const FileName: string; FileSize: Int64; Restore: Boolean): Boolean; overload;
    function NetworkError(): Boolean;
  end;

implementation

uses
  LazUTF8, LazFileUtils, FtpFunc, FtpUtils, synautil;

{$IF NOT DECLARED(EncodingCP1250)}
const
  EncodingCP1250 = 'cp1250';
  EncodingCP1251 = 'cp1251';
  EncodingCP1252 = 'cp1252';
  EncodingCP1253 = 'cp1253';
  EncodingCP1254 = 'cp1254';
  EncodingCP1255 = 'cp1255';
  EncodingCP1256 = 'cp1256';
  EncodingCP1257 = 'cp1257';
  EncodingCP1258 = 'cp1258';
  EncodingCP437 = 'cp437';
  EncodingCP850 = 'cp850';
  EncodingCP852 = 'cp852';
  EncodingCP866 = 'cp866';
  EncodingCP874 = 'cp874';
  EncodingCP932 = 'cp932';
  EncodingCP936 = 'cp936';
  EncodingCP949 = 'cp949';
  EncodingCP950 = 'cp950';
  EncodingCPKOI8 = 'koi8';
  EncodingCPIso1 = 'iso88591';
  EncodingCPIso2 = 'iso88592';
  EncodingCPIso15 = 'iso885915';
{$ENDIF}

function Dummy(const S: String): String;
begin
  Result:= S;
end;

function Ymmud(const S: String {$IFDEF FPC_HAS_CPSTRING}; SetTargetCodePage: Boolean = False{$ENDIF}): RawByteString;
begin
  Result:= S;
end;

function Utf8ToSys(const S: String {$IFDEF FPC_HAS_CPSTRING}; SetTargetCodePage: Boolean = False{$ENDIF}): RawByteString;
begin
  Result:= CeUtf8ToSys(S);
end;

{ TFTPListRecEx }

procedure TFTPListRecEx.Assign(Value: TFTPListRec);
begin
  inherited Assign(Value);
  Permission:= Value.Permission;
end;

{ TFTPListEx }

procedure TFTPListEx.Assign(Value: TFTPList);
var
  flr: TFTPListRecEx;
  n: integer;
begin
  Clear;
  for n := 0 to Value.Count - 1 do
  begin
    flr := TFTPListRecEx.Create;
    flr.Assign(Value[n]);
    Flist.Add(flr);
  end;
  Lines.Assign(Value.Lines);
  Masks.Assign(Value.Masks);
  UnparsedLines.Assign(Value.UnparsedLines);
end;

{ TProgressStream }

procedure TProgressStream.DoProgress(Result: Integer);
var
  Percent: Int64;
begin
  DoneSize += Result;
  Percent:= DoneSize * 100 div FileSize;
  if ProgressProc(PluginNumber, LocalName, RemoteName, Percent) = 1 then
    raise EUserAbort.Create(EmptyStr);
end;

function TProgressStream.Read(var Buffer; Count: Longint): Longint;
begin
  Result:= inherited Read(Buffer, Count);
  if FileSize > 0 then DoProgress(Result);
end;

function TProgressStream.Write(const Buffer; Count: Longint): Longint;
begin
  Result:= inherited Write(Buffer, Count);
  if FileSize > 0 then DoProgress(Result);
end;

{ TFTPSendEx }

function TFTPSendEx.Connect: Boolean;
begin
  Result:= inherited Connect;
  if Result then LogProc(PluginNumber, MSGTYPE_CONNECT, nil);
end;

function TFTPSendEx.DataSocket: Boolean;
var
  Message: UnicodeString;
begin
  Result:= inherited DataSocket;
  if FDSock.LastError <> 0 then begin
    Message:= UTF8ToUTF16(CeSysToUtf8(FDSock.LastErrorDesc));
    LogProc(PluginNumber, msgtype_importanterror, PWideChar('DSOCK ERROR ' + Message));
  end;
end;

function TFTPSendEx.ListMachine(Directory: String): Boolean;
var
  v: String;
  s, x, y: Integer;
  flr: TFTPListRec;
  option, value: String;
begin
  FFTPList.Clear;
  Result := False;
  FDataStream.Clear;
  if Directory <> '' then
    Directory := ' ' + Directory;
  FTPCommand('TYPE A');
  if not DataSocket then Exit;
  x := FTPCommand('MLSD' + Directory);
  if (x div 100) <> 1 then Exit;
  Result := DataRead(FDataStream);
  if Result then
  begin
    FDataStream.Position := 0;
    FFTPList.Lines.LoadFromStream(FDataStream);
    for x:= 0 to FFTPList.Lines.Count - 1 do
    begin
      s:= 1;
      flr := TFTPListRec.Create;
      v:= FFTPList.Lines[x];
      flr.OriginalLine:= v;
      for y:= 1 to Length(v) do
      begin
        if v[y] = '=' then
        begin
          option:= LowerCase(Copy(v, s, y - s));
          s:= y + 1;
        end
        else if v[y] = ';' then
        begin
          value:= LowerCase(Copy(v, s, y - s));
          if (option = 'type') then
          begin
            flr.Directory:= (value = 'dir');
          end
          else if (option = 'modify') then
          begin
            flr.FileTime:= DecodeMachineTime(value);
          end
          else if (option = 'size') then
          begin
            flr.FileSize:= StrToInt64Def(value, 0);
          end
          else if (option = 'unix.mode') then
          begin
            flr.Permission:= value;
          end;
          if (y < Length(v)) and (v[y + 1] = ' ') then
          begin
            flr.FileName:= SeparateLeft(Copy(v, y + 2, MaxInt), ' -> ');
            break;
          end;
          s:= y + 1;
        end;
      end;
      FFTPList.List.Add(flr);
      // DoStatus(True, FFTPList.Lines[x]);
    end;
  end;
  FDataStream.Position := 0;
end;

procedure TFTPSendEx.DoStatus(Response: Boolean; const Value: string);
var
  Index: Integer;
  Message: UnicodeString;
begin
  Index:= Pos('PASS ', Value);
  if Index = 0 then
    Message:= ServerToClient(Value)
  else begin
    Message:= ServerToClient(Copy(Value, 1, Index + 4)) + '********';
  end;
  LogProc(PluginNumber, msgtype_details, PWideChar(Message));
  if FSock.LastError <> 0 then begin
    Message:= UTF8ToUTF16(CeSysToUtf8(FSock.LastErrorDesc));
    LogProc(PluginNumber, msgtype_importanterror, PWideChar('CSOCK ERROR ' + Message));
  end;
end;

function TFTPSendEx.ClientToServer(const Value: UnicodeString): AnsiString;
begin
  Result:= ConvertFromUtf8(UTF16ToUTF8(Value));
end;

function TFTPSendEx.ServerToClient(const Value: AnsiString): UnicodeString;
begin
  Result:= UTF8ToUTF16(ConvertToUtf8(Value));
end;

constructor TFTPSendEx.Create(const Encoding: String);
var
  AEncoding: String;
begin
  inherited Create;
  FTimeout:= 15000;
  FDirectFile:= True;

  ConvertToUtf8:= @CeSysToUtf8;
  ConvertFromUtf8:= @Utf8ToSys;

  AEncoding:= NormalizeEncoding(Encoding);
  FAuto:= (AEncoding = '') or (AEncoding = 'auto');

  if AEncoding = EncodingUTF8 then
  begin
    ConvertToUtf8:= @Dummy;
    ConvertFromUtf8:= @Ymmud;
  end
  else if AEncoding = EncodingCPIso1 then
  begin
    ConvertToUtf8:= @ISO_8859_1ToUTF8;
    ConvertFromUtf8:= @UTF8ToISO_8859_1;
  end
  else if AEncoding = EncodingCPIso2 then
  begin
    ConvertToUtf8:= @ISO_8859_2ToUTF8;
    ConvertFromUtf8:= @UTF8ToISO_8859_2;
  end
  else if AEncoding = EncodingCPIso15 then
  begin
    ConvertToUtf8:= @ISO_8859_15ToUTF8;
    ConvertFromUtf8:= @UTF8ToISO_8859_15;
  end
  else if AEncoding = EncodingCP1250 then
  begin
    ConvertToUtf8:= @CP1250ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1250;
  end
  else if AEncoding = EncodingCP1251 then
  begin
    ConvertToUtf8:= @CP1251ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1251;
  end
  else if AEncoding = EncodingCP1252 then
  begin
    ConvertToUtf8:= @CP1252ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1252;
  end
  else if AEncoding = EncodingCP1253 then
  begin
    ConvertToUtf8:= @CP1253ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1253;
  end
  else if AEncoding = EncodingCP1254 then
  begin
    ConvertToUtf8:= @CP1254ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1254;
  end
  else if AEncoding = EncodingCP1255 then
  begin
    ConvertToUtf8:= @CP1255ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1255;
  end
  else if AEncoding = EncodingCP1256 then
  begin
    ConvertToUtf8:= @CP1256ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1256;
  end
  else if AEncoding = EncodingCP1257 then
  begin
    ConvertToUtf8:= @CP1257ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1257;
  end
  else if AEncoding = EncodingCP1258 then
  begin
    ConvertToUtf8:= @CP1258ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP1258;
  end
  else if AEncoding = EncodingCP437 then
  begin
    ConvertToUtf8:= @CP437ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP437;
  end
  else if AEncoding = EncodingCP850 then
  begin
    ConvertToUtf8:= @CP850ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP850;
  end
  else if AEncoding = EncodingCP852 then
  begin
    ConvertToUtf8:= @CP852ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP852;
  end
  else if AEncoding = EncodingCP866 then
  begin
    ConvertToUtf8:= @CP866ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP866;
  end
  else if AEncoding = EncodingCP874 then
  begin
    ConvertToUtf8:= @CP874ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP874;
  end
  else if AEncoding = EncodingCP932 then
  begin
    ConvertToUtf8:= @CP932ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP932;
  end
  else if AEncoding = EncodingCP936 then
  begin
    ConvertToUtf8:= @CP936ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP936;
  end
  else if AEncoding = EncodingCP949 then
  begin
    ConvertToUtf8:= @CP949ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP949;
  end
  else if AEncoding = EncodingCP950 then
  begin
    ConvertToUtf8:= @CP950ToUTF8;
    ConvertFromUtf8:= @UTF8ToCP950;
  end
  else if AEncoding = EncodingCPKOI8 then
  begin
    ConvertToUtf8:= @KOI8ToUTF8;
    ConvertFromUtf8:= @UTF8ToKOI8;
  end;
end;

function TFTPSendEx.Login: Boolean;
var
  Index: Integer;
begin
  Result:= inherited Login;
  if Result then
  begin
    if (FTPCommand('FEAT') div 100) = 2 then
    begin
      for Index:= 0 to FFullResult.Count - 1 do
      begin
        if not FMachine then FMachine:= Pos('MLSD', FFullResult[Index]) > 0;
        if not FUnicode then FUnicode:= Pos('UTF8', FFullResult[Index]) > 0;
        if not FSetTime then FSetTime:= Pos('MFMT', FFullResult[Index]) > 0;
      end;
      if FUnicode and FAuto then
      begin
        ConvertToUtf8:= @Dummy;
        ConvertFromUtf8:= @Ymmud;
        FTPCommand('OPTS UTF8 ON');
      end;
    end;
  end;
end;

procedure TFTPSendEx.ParseRemote(Value: string);
var
  RemoteIP: String;
begin
  inherited ParseRemote(Value);
  RemoteIP:= FSock.GetRemoteSinIP;
  if FDataIP = '0.0.0.0' then FDataIP:= RemoteIP
  else if IsIpPrivate(FDataIP) and (IsIpPrivate(RemoteIP) = False) then
  begin
    FDataIP:= RemoteIP;
    DoStatus(False, 'Server reports local IP -> Redirect to: ' + FDataIP);
  end;
end;

function TFTPSendEx.List(Directory: String; NameList: Boolean): Boolean;
var
  Message: UnicodeString;
begin
  if FMachine then
    Result:= ListMachine(Directory)
  else begin
    Result:= inherited List(Directory, NameList);
  end;
  if (Result = False) and (FSock.WaitingData > 0) then
  begin
    Message:= UnicodeString(FSock.RecvPacket(1000));
    LogProc(PluginNumber, msgtype_importanterror, PWideChar(Message));
  end;
end;

function TFTPSendEx.SetTime(const FileName: String; FileTime: TFileTime): Boolean;
var
  Time: String;
begin
  if not FSetTime then Exit(False);
  Time:= FormatMachineTime(FileTime);
  Result:= FTPCommand('MFMT ' + Time + ' ' + FileName) = 213;
end;

function TFTPSendEx.StoreFile(const FileName: string; Restore: Boolean): Boolean;
var
  StorSize: Int64;
  RestoreAt: Int64 = 0;
  SendStream: TProgressStream;
begin
  Result := False;
  Restore := Restore and FCanResume;
  if Restore then
  begin
    RestoreAt := Self.FileSize(FileName);
    if RestoreAt < 0 then RestoreAt := 0;
  end;

  SendStream := TProgressStream.Create(FDirectFileName, fmOpenRead or fmShareDenyWrite);

  SendStream.PluginNumber:= PluginNumber;
  SendStream.ProgressProc:= ProgressProc;
  SendStream.LocalName:= PWideChar(UTF8Decode(FDirectFileName));
  SendStream.RemoteName:= PWideChar(ServerToClient(FileName));

  try
    if not DataSocket then Exit;
    FTPCommand('TYPE I');
    StorSize := SendStream.Size;
    if not FCanResume then RestoreAt := 0;
    if RestoreAt > StorSize then RestoreAt := 0;
    if (StorSize > 0) and (RestoreAt = StorSize) then
    begin
      Result := True;
      Exit;
    end;
    SendStream.FileSize := StorSize;
    SendStream.DoneSize := RestoreAt;
    FTPCommand('ALLO ' + IntToStr(StorSize - RestoreAt));
    if FCanResume then
    begin
      if (FTPCommand('REST ' + IntToStr(RestoreAt)) div 100) <> 3 then
        Exit;
    end;
    SendStream.Position := RestoreAt;
    if (FTPCommand('STOR ' + FileName) div 100) <> 1 then
      Exit;
    Result := DataWrite(SendStream);
  finally
    SendStream.Free;
  end;
end;

function TFTPSendEx.RetrieveFile(const FileName: string; FileSize: Int64; Restore: Boolean): Boolean;
var
  RetrStream: TProgressStream;
begin
  Result := False;
  if not DataSocket then Exit;
  Restore := Restore and FCanResume;

  if Restore and FileExistsUTF8(FDirectFileName) then
    RetrStream := TProgressStream.Create(FDirectFileName, fmOpenWrite or fmShareExclusive)
  else begin
    RetrStream := TProgressStream.Create(FDirectFileName, fmCreate or fmShareDenyWrite)
  end;

  RetrStream.FileSize := FileSize;
  RetrStream.PluginNumber := PluginNumber;
  RetrStream.ProgressProc := ProgressProc;
  RetrStream.LocalName := PWideChar(UTF8Decode(FDirectFileName));
  RetrStream.RemoteName := PWideChar(ServerToClient(FileName));

  try
    FTPCommand('TYPE I');
    if Restore then
    begin
      RetrStream.DoneSize := RetrStream.Size;
      RetrStream.Position := RetrStream.DoneSize;
      if (FTPCommand('REST ' + IntToStr(RetrStream.DoneSize)) div 100) <> 3 then
        Exit;
    end;
    if (FTPCommand('RETR ' + FileName) div 100) <> 1 then
      Exit;
    Result := DataRead(RetrStream);
  finally
    RetrStream.Free;
  end;
end;

function TFTPSendEx.NetworkError: Boolean;
begin
  Result := FSock.CanRead(0);
end;

end.

