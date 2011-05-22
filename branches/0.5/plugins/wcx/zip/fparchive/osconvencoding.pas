unit osConvEncoding;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils; 

{en
  Convert from OEM to System encoding, if needed
}
function OEMToSys(Source: String): String;
function SysToOEM(Source: String): String;

{en
  Convert from Ansi to System encoding, if needed
}
function AnsiToSys(Source: String): String;
function SysToAnsi(Source: String): String;

{en
  Convert from Utf8 to System encoding, if needed
}
function Utf8ToSys(Source: String): String;
function SysToUtf8(Source: String): String;

{$IFDEF UNIX}
function GetSystemEncoding(out Language, Encoding: String): Boolean;
{$ENDIF}

implementation

uses
  {$IF DEFINED(UNIX)}
  iconvenc_dyn
  {$ELSEIF DEFINED(MSWINDOWS)}
  Windows
  {$ENDIF}
  ;

{$IFDEF UNIX}
var
  IsInitIconv: Boolean = False;

function GetSystemEncoding(out Language, Encoding: String): Boolean;
var
  I: Integer;
  Lang: String;
begin
  Result:= True;
  Lang:= SysUtils.GetEnvironmentVariable('LC_ALL');
  if Length(Lang) = 0 then
    begin
      Lang:= SysUtils.GetEnvironmentVariable('LC_MESSAGES');
      if Length(Lang) = 0 then
      begin
        Lang:= SysUtils.GetEnvironmentVariable('LANG');
        if Length(Lang) = 0 then
          Exit(False);
      end;
    end;
  Language:= Copy(Lang, 1, 2);
  I:= System.Pos('.', Lang);
  if (I > 0) then
    Encoding:= Copy(Lang, I + 1, Length(Lang) - I);
  if Length(Encoding) = 0 then
    Encoding:= 'UTF-8';
end;
{$ENDIF}

{ -------------------------------------------------------------------------- }

function OEMToSys(Source: String): String;
{$IFDEF MSWINDOWS}
var
  Dst: PAnsiChar;
begin
  Result:= Source;
  Dst:= AllocMem((Length(Result) + 1) * SizeOf(AnsiChar));
  if OEMToChar(PAnsiChar(Result), Dst) then
    Result:= StrPas(Dst);
  FreeMem(Dst);
end;
{$ELSE}
var
  Language, Encoding: String;
begin
  Result:= Source;
  if GetSystemEncoding(Language, Encoding) then
    begin
      if (Language = 'be') or (Language = 'ru') or (Language = 'uk') then
        if IsInitIconv then
          begin
            Iconvert(Source, Result, 'CP866', Encoding);
          end;
   end;
end;
{$ENDIF}

function SysToOEM(Source: String): String;
{$IFDEF MSWINDOWS}
var
  Dst: PAnsiChar;
begin
  Result := Source;
  Dst := AllocMem((Length(Result) + 1) * SizeOf(AnsiChar));
  if CharToOEM(PAnsiChar(Result), Dst) then
    Result := StrPas(Dst);
  FreeMem(Dst);
end;
{$ELSE}
var
  Language, Encoding: String;
begin
  Result:= Source;
  if GetSystemEncoding(Language, Encoding) then
    begin
      if (Language = 'be') or (Language = 'ru') or (Language = 'uk') then
        if IsInitIconv then
          begin
            Iconvert(Source, Result, Encoding, 'CP866');
          end;
   end;
end;
{$ENDIF}

{ -------------------------------------------------------------------------- }

function AnsiToSys(Source: String): String;
{$IFDEF MSWINDOWS}
begin
  Result:= Source;
end;
{$ELSE}
var
  Language, Encoding: String;
begin
  Result:= Source;
  if GetSystemEncoding(Language, Encoding) then
    begin
      if (Language = 'be') or (Language = 'bg') or (Language = 'ru') or (Language = 'uk') then
        if IsInitIconv then
          begin
            Iconvert(Source, Result, 'CP1251', Encoding);
          end;
   end;
end;
{$ENDIF}

function SysToAnsi(Source: String): String;
{$IFDEF MSWINDOWS}
begin
  Result:= Source;
end;
{$ELSE}
var
  Language, Encoding: String;
begin
  Result:= Source;
  if GetSystemEncoding(Language, Encoding) then
    begin
      if (Language = 'be') or (Language = 'bg') or (Language = 'ru') or (Language = 'uk') then
        if IsInitIconv then
          begin
            Iconvert(Source, Result, Encoding, 'CP1251');
          end;
   end;
end;
{$ENDIF}

function Utf8ToSys(Source: String): String;
begin
{$IFDEF MSWINDOWS}
  Result := Utf8ToAnsi(Source);
{$ELSE}
  Result := Source;
{$ENDIF}
end;

function SysToUtf8(Source: String): String;
begin
{$IFDEF MSWINDOWS}
  Result := AnsiToUtf8(Source);
{$ELSE}
  Result := Source;
{$ENDIF}
end;

{$IFDEF UNIX}
var
  sError: String;

initialization

  IsInitIconv:= InitIconv(sError);
  if not IsInitIconv then
    WriteLn(sError);
{$ENDIF}

end.

