{
Seksi Commander
----------------------------
Licence  : GNU GPL v 2.0
Author   : radek.cervinka@centrum.cz

Globals variables and some consts

contributors:

Alexander Koblov (Alexx2000@mail.ru)

}

unit uGlobs;

interface
uses
  Classes, uExts, uColorExt, Graphics, IniFiles;
const
  cTopBorder = 23; // px on top is title
  cLeftBorder = 6; // px on left

var
  gDirSortFirst:Boolean=True; // want to show dir first in panels
  gDirHistoryCount:Integer=30; // how many history we remember
  gShowSystemFiles:Boolean=True;
  gLng:String='english.lng';
  gTerm:String='/usr/X11R6/bin/xterm -e bash -i -c %s';
  gRunTerm:String='/usr/X11R6/bin/xterm';
  gCaseSensitiveSort:Boolean=True;
  gLynxLike:Boolean=True;
  gDirSelect:Boolean=True;
  glsHotDir:TStringList;
  glsDirHistory:TStringList;
  gColumnSize:Array[0..4] of Integer;

  gShortFileSizeFormat:Boolean=True;
  gSeparateExt:Boolean=False;    // draw filename and extension separate

  gUseExtEdit:Boolean=False;
  gUseExtView:Boolean=False;
  gUseExtDiff:Boolean=False;

  gExtEdit:String='emacs "%s"';
  gExtView:String='emacs "%s"';
  gExtDiff:String='gtk-diff "%s" "%s"';
  gExts:TExts;
  gColorExt:TColorExt;

  gFontName:String;
  gFontSize:Integer;
  gFontWeight : Integer;
  gEditorFontName:String;
  gEditorSize:Integer;
  gViewerFontName:String;
  gViewerSize:Integer;

  gViewerPos:TRect;
  gEditorPos:TRect;

function LoadGlobs : Boolean;
procedure SaveGlobs;
function LoadStringsFromFile(var list:TStringList; const sFileName:String):boolean;

const
  cMaxStringItems=50;
  
var
  gIni:TIniFile = nil;

implementation
uses
   SysUtils, uGlobsPaths, uLng, uShowMsg;

procedure LoadRect(Var ARect:TRect; sPrefix:String);
begin
//  writeln('Load Rect',sPrefix);
  ARect.Left:=gIni.ReadInteger('Configuration', sPrefix+'left',50);
//  writeln(ARect.Left);
  ARect.Top:=gIni.ReadInteger('Configuration', sPrefix+'top',50);
//  writeln(ARect.Top);
// warning Bottom = height rigth = width, TRect is used only for simplification
  ARect.Bottom:=gIni.ReadInteger('Configuration', sPrefix+'height',300);
//  writeln(ARect.Bottom);
  ARect.Right:=gIni.ReadInteger('Configuration', sPrefix+'width',400);
//  writeln(ARect.Right);
end;

procedure SaveRect(ARect:TRect; sPrefix:String);
begin

  gIni.WriteInteger('Configuration', sPrefix+'left', ARect.Left + cLeftBorder);
  gIni.WriteInteger('Configuration', sPrefix+'top', ARect.Top + cTopBorder);
// warning Bottom = height rigth = width, TRect is used only for simplification
  gIni.WriteInteger('Configuration', sPrefix+'height', ARect.Bottom);
  gIni.WriteInteger('Configuration', sPrefix+'width', ARect.Right);
end;

procedure InitGlobs;
begin
  gIni:=TIniFile.Create(gpIniDir+'doublecmd.ini');
  gExts:=TExts.Create;
  gColorExt:=TColorExt.Create;
  glsHotDir:=TStringList.Create;
  glsDirHistory:=TStringList.Create;
end;

procedure DeInitGlobs;
begin
  if assigned(gColorExt) then
    FreeAndNil(gColorExt);
  if assigned(glsDirHistory) then
    FreeAndNil(glsDirHistory);
  if assigned(glsHotDir) then
    FreeAndNil(glsHotDir);
  if Assigned(gExts) then
    FreeAndNil(gExts);
  if Assigned(gIni) then
    FreeAndNil(gIni);
end;

function LoadGlobs : Boolean;
begin
  Result := False;
  writeln('Loading configuration...');
  InitGlobs;
  gShowSystemFiles := gIni.ReadBool('Configuration', 'ShowSystemFiles', False);
  gLng := gIni.ReadString('Configuration', 'Language', gLng);
  gTerm := gIni.ReadString('Configuration', 'Term', gTerm);
  gCaseSensitiveSort := gIni.ReadBool('Configuration', 'CaseSensitiveSort', False);
  gLynxLike := gIni.ReadBool('Configuration', 'LynxLike', True);
  gDirSelect := gIni.ReadBool('Configuration', 'DirSelect', True);
  glsHotDir.CommaText := gIni.ReadString('Configuration', 'HotDir', '');
  gShortFileSizeFormat := gIni.ReadBool('Configuration', 'ShortFileSizeFormat', True);

  gUseExtEdit := gIni.ReadBool('Configuration', 'UseExtEdit', False);
  gUseExtView := gIni.ReadBool('Configuration', 'UseExtView', False);
  gUseExtDiff := gIni.ReadBool('Configuration', 'UseExtDiff', False);
  gSeparateExt := gIni.ReadBool('Configuration', 'SeparateExt', True);

  gExtEdit := gIni.ReadString('Configuration', 'ExtEdit', '');
  gExtView := gIni.ReadString('Configuration', 'ExtView', '');
  gExtDiff := gIni.ReadString('Configuration', 'ExtDiff', '');
  gRunTerm := gIni.ReadString('Configuration', 'RunTerm', gRunTerm);

  gFontName:=gIni.ReadString('Configuration', 'FontName', '');
  gFontWeight := gIni.ReadInteger('Configuration', 'FontWeight', 700);
  writeln('gFontName:',gFontName);
  gEditorFontName:=gIni.ReadString('Configuration', 'FontEditorName', '');
  writeln('gEditorFontName:',gEditorFontName);
  gViewerFontName:=gIni.ReadString('Configuration', 'FontViewerName', '');
  writeln('gViewerEditorFontName:',gViewerFontName);
  gFontSize:=gIni.ReadInteger('Configuration', 'FontSize', 10);
  gEditorSize:=gIni.ReadInteger('Configuration', 'EditorSize', 14);
  gViewerSize:=gIni.ReadInteger('Configuration', 'ViewerSize', 14);

  if FileExists(gpCfgDir+'doublecmd.ext') then
    gExts.LoadFromFile(gpCfgDir+'doublecmd.ext');

  if FileExists(gpIniDir+'dirhistory.txt') then
    LoadStringsFromFile(glsDirHistory,gpIniDir+'dirhistory.txt');

  if FileExists(gpCfgDir+'color.ext') then
    gColorExt.LoadFromFile(gpCfgDir+'color.ext');

  // default column widths
  gColumnSize[0] := gIni.ReadInteger('Configuration', 'Col0', 133);
  gColumnSize[1] := gIni.ReadInteger('Configuration', 'Col1', 50);
  gColumnSize[2] := gIni.ReadInteger('Configuration', 'Col2', 64);
  gColumnSize[3] := gIni.ReadInteger('Configuration', 'Col3', 73);
  gColumnSize[4] := gIni.ReadInteger('Configuration', 'Col4', 59);

  writeln('Loading viewer position...');
  LoadRect(gViewerPos, 'Viewer.');
  writeln('Loading editor position...');
  LoadRect(gEditorPos, 'Editor.');

    if FileExists(gpLngDir + gLng) then
      begin
        DoLoadLng;
        msgLoadLng;
        Result := True;
        WriteLn
      end
    else
      msgError('File "' + gpLngDir + gLng + '" not found. Double Commander is closed.');
end;

function LoadStringsFromFile(var list:TStringList; const sFileName:String):boolean;
var
  i:Integer;
begin
  Assert(list <> nil,'LoadStringsFromFile: list=nil');
  list.Clear;
  Result:=False;
  if not FileExists(sFileName) then Exit;
  list.LoadFromFile(sFileName);
  for i:=list.Count-1 downto 0 do
    if i>cMaxStringItems then
      list.Delete(i)
    else
      Break;
  Result:=True;
end;


procedure SaveGlobs;
var
  x:Integer;
begin
  glsDirHistory.SaveToFile(gpIniDir+'dirhistory.txt');

  gIni.WriteBool('Configuration', 'ShowSystemFiles', gShowSystemFiles);
  gIni.WriteString('Configuration', 'Language', gLng);
  gIni.WriteString('Configuration', 'Term', gTerm);
  gIni.WriteBool('Configuration', 'CaseSensitiveSort', gCaseSensitiveSort);
  gIni.WriteBool('Configuration', 'LynxLike', gLynxLike);
  gIni.WriteBool('Configuration', 'DirSelect', gDirSelect);
  gIni.WriteString('Configuration', 'HotDir', glsHotDir.CommaText);
  gIni.WriteBool('Configuration', 'ShortFileSizeFormat', gShortFileSizeFormat);


  gIni.WriteBool('Configuration', 'UseExtEdit', gUseExtEdit);
  gIni.WriteBool('Configuration', 'UseExtView', gUseExtView);
  gIni.WriteBool('Configuration', 'UseExtDiff', gUseExtDiff);
  gIni.WriteBool('Configuration', 'SeparateExt', gSeparateExt);

  gIni.WriteString('Configuration', 'ExtEdit', gExtEdit);
  gIni.WriteString('Configuration', 'ExtView', gExtView);
  gIni.WriteString('Configuration', 'ExtDiff', gExtDiff);
  gIni.WriteString('Configuration', 'RunTerm', gRunTerm);

  gIni.WriteString('Configuration', 'FontName', gFontName);
  gIni.WriteInteger('Configuration', 'FontWeight', gFontWeight);
  gIni.WriteString('Configuration', 'FontEditorName', gEditorFontName);
  gIni.WriteString('Configuration', 'FontViewerName', gViewerFontName);

  gIni.WriteInteger('Configuration', 'FontSize', gFontSize);
  gIni.WriteInteger('Configuration', 'EditorSize', gEditorSize);
  gIni.WriteInteger('Configuration', 'ViewerSize', gViewerSize);

  for x:=0 to 4 do
    gIni.WriteInteger('Configuration', 'Col'+IntToStr(x), gColumnSize[x]);
    
  SaveRect(gViewerPos, 'Viewer.');
  SaveRect(gEditorPos, 'Editor.');
end;

initialization

finalization
  SaveGlobs;
end.
