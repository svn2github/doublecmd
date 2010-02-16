unit un_process;

{$mode delphi}{$H+}

interface

uses
  Process, UTF8Process, SysUtils, Math;
 
type

  TOnReadLn = procedure (str: String) of object;
  
  { TExProcess }

  TExProcess = class
  protected
    p: TProcessUTF8;
    s: string;
    FStop:boolean;
    function _GetExitStatus(): integer;
  public
    OnReadLn:TOnReadLn;
    constructor Create(commandline: string='');
    procedure Execute;
    procedure Stop;
    procedure SetCmdLine(commandline:string);
    destructor Destroy;

    property Process: TProcessUTF8 read p;
    property ExitStatus: integer read _GetExitStatus;
  end;

implementation

uses
  LCLProc;

const buf_len = 3000;


{ TExProcess }

function TExProcess._GetExitStatus(): integer;
begin
  Result:= p.ExitStatus;
end;

constructor TExProcess.Create(commandline: string='');
begin
  s:= '';
  p:= TProcessUTF8.Create(nil);
  p.CommandLine:=commandline;
  p.Options:=[poUsePipes,poNoConsole];
end;

procedure TExProcess.Execute;
var
  buf: string;
  i, j, c, n: integer;
begin
  DebugLn('Execute: ', p.CommandLine);
  try
    p.Execute;
    repeat
      if FStop then exit;
      SetLength(buf, buf_len);
      SetLength(buf, p.output.Read(buf[1], length(buf))); //waits for the process output
      // cut the incoming stream to lines:
      s:=s + buf; //add to the accumulator

      repeat //detect the line breaks and cut.
        if FStop then exit;
        i:=Pos(#13, s);
        j:=Pos(#10, s);
        if i=0 then i:=j;
        if j=0 then j:=i;
        if j = 0 then Break; //there are no complete lines yet.
        if Assigned(OnReadLn) then
        OnReadLn(Copy(s, 1, min(i, j) - 1)); //return the line without the CR/LF characters
        s:=Copy(s, max(i, j) + 1, length(s) - max(i, j)); //remove the line from accumulator
      until false;
    until buf = '';
    if FStop then exit;
    if s <> '' then
      if Assigned(OnReadLn) then
       OnReadLn(s);
    buf:='';
    if Assigned(OnReadLn) then
      OnReadLn(buf); //Empty line to notify DC about search process finish
  finally
  end;
end;

procedure TExProcess.Stop;
begin
  FStop:=true;
end;

procedure TExProcess.SetCmdLine(commandline:string);
begin
  p.CommandLine:=commandline;
end;

destructor TExProcess.Destroy;
begin
  FreeAndNil(p);
end;

end.
