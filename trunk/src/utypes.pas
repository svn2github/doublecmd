{
Seksi Commander
----------------------------
Licence  : GNU GPL v 2.0
Author   : radek.cervinka@centrum.cz

Definitions of basic types.
This unit should depend on as little other units as possible.

contributors:


}

unit uTypes;

interface

{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}

{$IFDEF DARWIN}
uses
  MacOSAll;
{$ENDIF}

type
  TLibHandle = PtrInt;

  TDynamicStringArray = array of String;

  TFileAttrs = Cardinal;     // file attributes type regardless of system

  TWinFileTime = QWord;      // NTFS time (UTC) (2 x DWORD)
  TDosFileTime = LongInt;    // MS-DOS time (local)

{$IFDEF MSWINDOWS}
  TFileTime = TWinFileTime;
{$ELSE}
  // Unix time (UTC).
  // Unix defines time_t as signed integer,
  // but we define it as unsigned because sign is not needed.
  {$IFDEF cpu64}
  TFileTime = QWord;
  {$ELSE}
  TFileTime = DWord;
  {$ENDIF}
{$ENDIF}

  PFileTime = ^TFileTime;
  PWinFileTime = ^TWinFileTime;

  PSearchRecEx = ^TSearchRecEx;
  TSearchRecEx = Record
    Time : TFileTime;  // modification time
    Size : Int64;
    Attr : TFileAttrs;
    Name : UTF8String;
    ExcludeAttr : TFileAttrs;
{$ifdef unix}
    FindHandle : Pointer;
{$else unix}
    FindHandle : THandle;
{$endif unix}
{$if defined(Win32) or defined(WinCE) or defined(Win64)}
    FindData : Windows.TWin32FindDataW;
{$endif}
{$ifdef netware_clib}
    FindData : TNetwareFindData;
{$endif}
{$ifdef netware_libc}
    FindData : TNetwareLibcFindData;
{$endif}
{$ifdef MacOS}
    FindData : TMacOSFindData;
{$endif}
  end;

// plugin types
  TPluginType = (ptDSX, ptWCX, ptWDX, ptWFX, ptWLX);

  TRange = record
    First: Integer;
    Last: Integer;
  end;

  TCaseSensitivity = (
    cstNotSensitive,
    // According to locale collation specs. Usually it means linguistic sorting
    // of character case "aAbBcC" taking numbers into consideration (aa1, aa2, aa10, aA1, aA2, aA10, ...).
    cstLocale,
    // Depending on character value, direct comparison of bytes, so usually ABCabc.
    // Might not work correctly for Unicode, just for Ansi.
    cstCharValue);

implementation

end.
