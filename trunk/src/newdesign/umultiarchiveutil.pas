unit uMultiArchiveUtil;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uMultiArc, un_process, uFile;

type

  TOnGetArchiveItem = procedure(ArchiveItem: TArchiveItem) of object;

  TKeyPos = record
    Index,
    Start,
    Finish: longint;
  end;

  { TOutputParser }

  TOutputParser = class
    FMultiArcItem: TMultiArcItem;
    FExProcess: TExProcess;
  private
    FNamePos,
    FUnpSizePos,
    FPackSizePos,
    FYearPos,
    FMonthPos,
    FMonthNamePos,
    FDayPos,
    FHourPos,
    FMinPos,
    FSecPos,
    FAttrPos: TKeyPos;
  private
    FOnGetArchiveItem: TOnGetArchiveItem;
    FStartParsing: boolean;
    FFormatIndex: longint;
    FArchiveItem: TArchiveItem;
  protected
    function KeyPos(Key: char; out Position: TKeyPos): boolean;
    procedure OnReadLn(str: string);
    function CheckOut(const SubStr, Str: string): boolean;
  public
    constructor Create(aMultiArcItem: TMultiArcItem; const anArchiveName: UTF8String);
    destructor Destroy; override;
    procedure Execute;
    property OnGetArchiveItem: TOnGetArchiveItem read FOnGetArchiveItem write FOnGetArchiveItem;
  end;

function FormatArchiverCommand(const Archiver, sCmd, anArchiveName: UTF8String;
                               aFiles: TFiles;
                               aDestPath: UTF8String): string;

implementation

uses
  LCLProc, FileUtil, StrUtils, uClassesEx, uDCUtils, uOSUtils;

function TOutputParser.KeyPos(Key: char; out Position: TKeyPos): boolean;
var
  I: integer;
  Format: string;
begin
  Result := False;
  Position.Index := -1;
  for I := 0 to FMultiArcItem.FFormat.Count - 1 do
    with FMultiArcItem do
    begin
      Format := FFormat[I];
      Position.Start := Pos(Key, Format);
      if Position.Start = 0 then
        Continue;
      Position.Finish := PosEx(#32, Format, Position.Start + 1);
      if Position.Finish = 0 then
        Position.Finish := Length(Format);
      Position.Finish := Position.Finish - Position.Start;
      Position.Index := I;
      DebugLn('Key: ', Key, ' Start: ', IntToStr(Position.Start), ' Finish: ', IntToStr(Position.Finish));
      Result := True;
      Break;
    end;
end;

{ TOutputParser }

procedure TOutputParser.OnReadLn(str: string);
begin
  DebugLn(str);
  if FStartParsing and CheckOut(FMultiArcItem.FEnd, Str) then
  begin
    FExProcess.Stop;
    Exit;
  end;

  if FStartParsing then
  begin
    // if next item
    if FFormatIndex = 0 then
      FArchiveItem := TArchiveItem.Create;
    // get all file properties
    if FNamePos.Index = FFormatIndex then
      FArchiveItem.FileName := Copy(str, FNamePos.Start, FNamePos.Finish);
    if FPackSizePos.Index = FFormatIndex then
      FArchiveItem.UnpSize :=
        StrToInt(Trim(Copy(str, FPackSizePos.Start, FUnpSizePos.Finish)));
    if FPackSizePos.Index = FFormatIndex then
      FArchiveItem.PackSize :=
        StrToInt(Trim(Copy(str, FPackSizePos.Start, FPackSizePos.Finish)));
    if FYearPos.Index = FFormatIndex then
      FArchiveItem.Year := StrToInt(Copy(str, FYearPos.Start, FYearPos.Finish));
    if FMonthPos.Index = FFormatIndex then
      FArchiveItem.Month := StrToInt(Copy(str, FMonthPos.Start, FMonthPos.Finish));
    if FMonthNamePos.Index = FFormatIndex then
      FArchiveItem.MonthName := Copy(str, FMonthNamePos.Start, FMonthNamePos.Finish);
    if FDayPos.Index = FFormatIndex then
      FArchiveItem.Day := StrToInt(Copy(str, FDayPos.Start, FDayPos.Finish));
    if FHourPos.Index = FFormatIndex then
      FArchiveItem.Hour := StrToInt(Copy(str, FHourPos.Start, FHourPos.Finish));
    if FMinPos.Index = FFormatIndex then
      FArchiveItem.Minute := StrToInt(Copy(str, FMinPos.Start, FMinPos.Finish));
    if FSecPos.Index = FFormatIndex then
      FArchiveItem.Second := StrToInt(Copy(str, FSecPos.Start, FSecPos.Finish));
    if FAttrPos.Index = FFormatIndex then
      FArchiveItem.Attributes := StrToAttr(Copy(str, FAttrPos.Start, FAttrPos.Finish));

    FFormatIndex := FFormatIndex + 1;
    if FFormatIndex >= FMultiArcItem.FFormat.Count then
    begin
      FFormatIndex := 0;
      //+++++++++++++++++++++++++++++++++++++++++++++++++++
      DebugLn('FileName: ', FArchiveItem.FileName);
      DebugLn('Size: ', IntToStr(FArchiveItem.UnpSize));
      DebugLn('Pack size: ', IntToStr(FArchiveItem.PackSize));
      DebugLn('Attributes: ', IntToStr(FArchiveItem.Attributes));
      DebugLn('-------------------------------------');
      //+++++++++++++++++++++++++++++++++++++++++++++++++++
      if Assigned(FOnGetArchiveItem) then
        FOnGetArchiveItem(FArchiveItem);
    end;
  end
  else
  begin
    FStartParsing := CheckOut(FMultiArcItem.FStart, Str);
    if FStartParsing then
      FFormatIndex := 0;
  end;
end;

function TOutputParser.CheckOut(const SubStr, Str: string): boolean;
begin
  if SubStr[1] = '^' then
    Result := (Pos(PChar(SubStr) + 1, Str) = 1)
  else
    Result := (Pos(SubStr, Str) > 0);
end;

constructor TOutputParser.Create(aMultiArcItem: TMultiArcItem;
  const anArchiveName: UTF8String);
begin
  FStartParsing := False;
  FMultiArcItem := aMultiArcItem;
  FExProcess := TExProcess.Create(FormatArchiverCommand(FMultiArcItem.FArchiver,
    FMultiArcItem.FList, anArchiveName, nil, EmptyStr));
  FExProcess.OnReadLn := @OnReadLn;
end;

destructor TOutputParser.Destroy;
begin
  FreeThenNil(FExProcess);
  inherited Destroy;
end;

procedure TOutputParser.Execute;
begin
  // get positions of all properties
  KeyPos('n', FNamePos);  // file name
  KeyPos('z', FUnpSizePos); // unpacked size
  KeyPos('p', FPackSizePos); // packed size
  KeyPos('y', FYearPos);
  KeyPos('t', FMonthPos);
  KeyPos('T', FMonthNamePos);
  KeyPos('d', FDayPos);
  KeyPos('h', FHourPos);
  KeyPos('m', FMinPos);
  KeyPos('s', FSecPos);
  KeyPos('a', FAttrPos);
  // execute archiver
  FExProcess.Execute;
end;

function FormatArchiverCommand(const Archiver, sCmd, anArchiveName: UTF8String;
                               aFiles: TFiles;
                               aDestPath: UTF8String): string;
type
  TFunctType = (ftNone, ftArchiverLongName, ftArchiverShortName,
    ftArchiveLongName, ftArchiveShortName,
    ftFileListLongName, ftFileListShortName, ftFileName, ftTargetArchiveDir);
  TStatePos = (spNone, spPercent, spFunction, spComplete);
  TFuncModifiers = set of (fmQuoteWithSpaces, fmQuoteAny, fmNameOnly,
    fmPathOnly, fmAnsi);

  TState = record
    pos: TStatePos;
    functStartIndex: integer;
    funct: TFunctType;
    FuncModifiers: TFuncModifiers;
  end;

var
  index: integer;
  state: Tstate;
  sOutput: string = '';
  parseStartIndex: integer;

  function BuildName(const sFileName: UTF8String): UTF8String;
  begin
    Result := sFileName;
    if fmNameOnly in state.FuncModifiers then
      Result := ExtractFileName(Result);
    if fmPathOnly in state.FuncModifiers then
      Result := ExtractFilePath(Result);
    if (fmQuoteWithSpaces in state.FuncModifiers) and (Pos(#32, Result) <> 0) then
      Result := '"' + Result + '"';
    if (fmQuoteAny in state.FuncModifiers) then
      Result := '"' + Result + '"';
    if not (fmAnsi in state.FuncModifiers) then
      Result := UTF8ToConsole(Result);
  end;

  function BuildFileList(bShort: boolean): UTF8String;
  var
    I: integer;
    FileList: TStringListEx;
  begin
    if not Assigned(aFiles) then Exit(EmptyStr);
    Result := GetTempName(GetTempFolder);
    FileList := TStringListEx.Create;
    for I := 0 to aFiles.Count - 1 do
    begin
      if bShort then
        FileList.Add(mbFileNameToSysEnc(aFiles[I].FullPath))
      else
        FileList.Add(aFiles[I].FullPath);
    end;
    try
      FileList.SaveToFile(Result);
    except
      Result := EmptyStr;
    end;
    FileList.Free;
  end;

  function BuildOutput: UTF8String;
  begin
    case state.funct of
      ftArchiverLongName:
        Result := BuildName(Archiver);
      ftArchiverShortName:
        Result := BuildName(mbFileNameToSysEnc(Archiver));
      ftArchiveLongName:
        Result := BuildName(anArchiveName);
      ftArchiveShortName:
        Result := BuildName(mbFileNameToSysEnc(anArchiveName));
      ftFileListLongName:
        Result := BuildFileList(False);
      ftFileListShortName:
        Result := BuildFileList(True);
      ftTargetArchiveDir:
        Result := BuildName(aDestPath);
      else
        Exit('');
    end;
  end;

  procedure ResetState(var aState: TState);
  begin
    with aState do
    begin
      pos := spNone;
      funct := ftNone;
      functStartIndex := 0;
      FuncModifiers := [];
    end;
  end;

  procedure AddParsedText(limit: integer);
  begin
    // Copy [parseStartIndex .. limit - 1].
    if limit > parseStartIndex then
      sOutput := sOutput + Copy(sCmd, parseStartIndex, limit - parseStartIndex);
    parseStartIndex := index;
  end;

  procedure DoFunction;
  begin
    AddParsedText(state.functStartIndex);
    if sOutPut <> EmptyStr then
      sOutput := sOutput + #32 + BuildOutput
    else
      sOutput := BuildOutput;
    ResetState(state);
  end;

begin
  try
    index := 1;
    parseStartIndex := index;

    ResetState(state);

    while index <= Length(sCmd) do
    begin
      case state.pos of
        spNone:
          if sCmd[index] = '%' then
          begin
            state.pos := spPercent;
            state.functStartIndex := index;
          end;

        spPercent:
          case sCmd[index] of
            'P':
            begin
              state.funct := ftArchiverLongName;
              state.pos := spFunction;
            end;
            'p':
            begin
              state.funct := ftArchiverShortName;
              state.pos := spFunction;
            end;
            'A':
            begin
              state.funct := ftArchiveLongName;
              state.pos := spFunction;
            end;
            'a':
            begin
              state.funct := ftArchiveShortName;
              state.pos := spFunction;
            end;
            'L':
            begin
              state.funct := ftFileListLongName;
              state.pos := spFunction;
            end;
            'l':
            begin
              state.funct := ftFileListShortName;
              state.pos := spFunction;
            end;
            'F':
            begin
              state.funct := ftFileName;
              state.pos := spFunction;
            end;
            'R':
            begin
              state.funct := ftTargetArchiveDir;
              state.pos := spFunction;
            end;
            else
              ResetState(state);
          end;

        spFunction:
          case sCmd[index] of
            'Q':
            begin
              state.FuncModifiers := state.FuncModifiers + [fmQuoteWithSpaces];
              state.pos := spFunction;
            end;
            'q':
            begin
              state.FuncModifiers := state.FuncModifiers + [fmQuoteAny];
              state.pos := spFunction;
            end;
            'W':
            begin
              state.FuncModifiers := state.FuncModifiers + [fmNameOnly];
              state.pos := spFunction;
            end;
            'P':
            begin
              state.FuncModifiers := state.FuncModifiers + [fmPathOnly];
              state.pos := spFunction;
            end;
            'A':
            begin
              state.FuncModifiers := state.FuncModifiers + [fmAnsi];
              state.pos := spFunction;
            end;
            else
              state.pos := spComplete;
          end;
      end;

      if state.pos <> spComplete then
        Inc(index) // check next character
      else
        // Process function and then check current character again after resetting state.
        DoFunction;
    end;

    // Finish current parse.
    if state.pos in [spFunction] then
      DoFunction
    else
      AddParsedText(index);

    Result := sOutput;

  finally

  end;
end;

end.

