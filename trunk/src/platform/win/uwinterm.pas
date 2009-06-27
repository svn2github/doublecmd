unit uWinTerm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Windows, uTerminal;

type

   { TWinTerm }

   TWinTerm = class(TTerminal)
   private
     FSecurityAttributes: TSecurityAttributes;
     FStartupInfo: TStartupInfo;
     FProcessInformation: TProcessInformation;
     PipeStdInRead,
     PipeStdInWrite,
     PipeStdOutRead,
     PipeStdOutWrite: THandle;
   public
     constructor Create;
     destructor Destroy; override;
     //---------------------
     function Read_Pty(var Output: UTF8String; const TimeOut: LongInt = 10): LongInt; override; // Read info from pty
     function Fork_pty(const RowCount, ColCount: Integer; const Command: UTF8String; const Params: UTF8String=''): THandle; override;//Create new pty and start cmd
     function Write_pty(const Input: UTF8String): Boolean; override; //write str to pty
     //---------------------
     function SendBreak_pty(): Boolean;  override; // ^C
     function SendSignal_pty(Sig: Cint): Boolean; override;
     function SetScreenSize(ColCount, RowCount: Integer): Boolean; override;
     //---------------------
     function KillShell: LongInt;
   end;

  { TWinConThread }

  TWinConThread = class(TConsoleThread)
  private
    procedure AddSymbol;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  FileUtil, uOSUtils;

function ConsoleToUTF8(const Str: AnsiString): UTF8String;
{$ifdef MSWindows}
var
  Dst: PChar;
{$endif}
begin
  Result:= Str;
  {$ifdef MSWindows}
  Dst:= AllocMem((Length(Result) + 1) * SizeOf(Char));
  if OEMToChar(PChar(Result), Dst) then
    Result:= SysToUTF8(Dst);
  FreeMem(Dst);
  {$endif}
end;

{ TWinTerm }

constructor TWinTerm.Create;
begin

end;

destructor TWinTerm.Destroy;
begin
  KillShell;
  inherited Destroy;
end;

function TWinTerm.Read_Pty(var Output: UTF8String; const timeout: LongInt): LongInt;
var
  I: Integer;
  dwRead, BufSize, DesBufSize: DWORD;
  Res: Boolean;
  pcOutput: PChar;
begin
  try
    BufSize:= 0;
    dwRead:= 0;
    Output:= EmptyStr;
    repeat
      for I:= 0 to 9 do
        begin
	  Res:= PeekNamedPipe(PipeStdOutRead, nil, 0, nil, @DesBufSize, nil);
      	  Res:= Res and (DesBufSize > 0);
          if Res then Break;
          Sleep(TimeOut);
        end;
      if Res then
      	begin
          if DesBufSize > BufSize then
            begin
	      GetMem(pcOutput, DesBufSize);
              BufSize:= DesBufSize;
            end;
	  Res:= ReadFile(PipeStdOutRead, pcOutput^, BufSize, dwRead, nil);
        end;
    until not Res;
  except
  end;
  if dwRead > 0 then
    begin
      Output:= ConsoleToUTF8(Copy(pcOutput, 1, dwRead));
      FreeMem(pcOutput);
    end;
  Result:= dwRead;
end;

function TWinTerm.Fork_pty(const RowCount, ColCount: Integer; const Command: UTF8String;
  const Params: UTF8String): THandle;
var
 hTmp1, hTmp2: THandle;
begin
  ZeroMemory(@FSecurityAttributes, SizeOf(FSecurityAttributes));
  FSecurityAttributes.nLength:= SizeOf(FSecurityAttributes);
  FSecurityAttributes.bInheritHandle:= True;
  FSecurityAttributes.lpSecurityDescriptor:= nil;

  // create input/output pipes
  CreatePipe(PipeStdInRead, PipeStdInWrite, @FSecurityAttributes, 0);
  CreatePipe(PipeStdOutRead, PipeStdOutWrite, @FSecurityAttributes, 0);

  DuplicateHandle(GetCurrentProcess(), PipeStdInWrite, GetCurrentProcess(), @hTmp1, 0, False, DUPLICATE_SAME_ACCESS);
  DuplicateHandle(GetCurrentProcess(), PipeStdOutRead, GetCurrentProcess(), @hTmp2, 0, False, DUPLICATE_SAME_ACCESS);

  CloseHandle(PipeStdInWrite);
  CloseHandle(PipeStdOutRead);

  PipeStdInWrite:= hTmp1;
  PipeStdOutRead:= hTmp2;

  ZeroMemory(@FStartupInfo, SizeOf(FStartupInfo));
  FStartupInfo.cb:= SizeOf(FStartupInfo);
  with FStartupInfo do
  begin
    dwFlags:= STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    wShowWindow:= SW_HIDE;
    hStdInput:= PipeStdInRead;
    hStdOutput:= PipeStdOutWrite;
  end;

  ZeroMemory(@FProcessInformation, SizeOf(FProcessInformation));

  CreateProcessW(nil,
      PWideChar(UTF8Decode(Command)),       // command line
      nil,          // process security attributes
      nil,          // primary thread security attributes
      TRUE,         // handles are inherited
      0,            // creation flags
      nil,          // use parent's environment
      nil,          // use parent's current directory
      FStartupInfo,  // STARTUPINFO pointer
      FProcessInformation);  // receives PROCESS_INFORMATION

  Result:= FProcessInformation.hProcess;
end;

function TWinTerm.Write_pty(const Input: UTF8String): Boolean;
var
  dwWritten, BufSize: DWORD;
  pcCommand: PChar;
begin
  pcCommand:= PChar(UTF8ToConsole(Input));
  BufSize:= Length(pcCommand);
  Result:= WriteFile(PipeStdInWrite, pcCommand^, BufSize, dwWritten, nil);
  Result:= Result and (BufSize = dwWritten);
end;

function TWinTerm.SendBreak_pty(): Boolean;
begin
  Result:= False;
end;

function TWinTerm.SendSignal_pty(Sig: Cint): Boolean;
begin
  Result:= False;
end;

function TWinTerm.SetScreenSize(ColCount, RowCount: Integer): Boolean;
begin
  Result:= False;
end;

function TWinTerm.KillShell: LongInt;
begin
  try
    CloseHandle(PipeStdInRead);
    CloseHandle(PipeStdInWrite);
    CloseHandle(PipeStdOutRead);
    CloseHandle(PipeStdOutWrite);
    CloseHandle(FProcessInformation.hThread);
    CloseHandle(FProcessInformation.hProcess);
  except
  end;
end;

{ TWinConThread }

procedure TWinConThread.AddSymbol;
begin
  if Assigned(FOut) then
    FOut.Write(FBuf);
end;

procedure TWinConThread.Execute;
begin
  FShell:= GetShell;
  if Length(FShell) = 0 then
    FShell:= RunTerm;
  if Assigned(FTerm) then
    FTerm.Fork_pty(FRowsCount, FColsCount, FShell);
  while True do
    begin
     if Assigned(FTerm) then
       begin
         if FTerm.Read_pty(FBuf, 0) > 0 then
           Synchronize(@AddSymbol)
         else
           Sleep(1);
       end else Break;
    end;
end;

constructor TWinConThread.Create;
begin
  inherited Create(True);
  System.InitCriticalSection(FLock);
  FTerm:= TWinTerm.Create;
  FRowsCount:= 50;
  FColsCount:= 100;
end;

destructor TWinConThread.Destroy;
begin
  FreeAndNil(FTerm);
  System.DoneCriticalSection(FLock);
  inherited Destroy;
end;

end.

