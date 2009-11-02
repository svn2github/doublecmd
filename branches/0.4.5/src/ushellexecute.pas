{
    Double Commander
    -------------------------------------------------------------------------
    This unit contains some functions for open files in associated applications.

    Copyright (C) 2006-2009  Koblov Alexander (Alexx2000@mail.ru)

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

unit uShellExecute;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uTypes, uFilePanel, framePanel;

procedure ReplaceExtCommand(var sCmd: String;
                            leftPanel: TFrameFilePanel;
                            rightPanel: TFrameFilePanel;
                            activePanel: TFrameFilePanel); overload;

procedure ReplaceExtCommand(var sCmd:String; pfr:PFileRecItem; ActiveDir: String); overload;
function ProcessExtCommand(sCmd:String; ActiveDir: String): Boolean;
function ShellExecuteEx(sCmd, sFileName, sActiveDir: String): Boolean;

implementation

uses
  Process, UTF8Process, StrUtils, uDCUtils, uShowForm, uGlobs, uOSUtils;

{
  Functions (without parameters they give output for all selected files):
  %f - only filename
  %d - only path, without trailing delimiter
  %p - path+filename
  %D - current path in active or chosen panel

  Choosing panel (if not given, active panel is used):
    %X[l|r] - where X is function (l - left, r - right)

  Choosing selected files (only for %f, %d, %p):
    %X[<nr>] - where X is function
               <nr> is 1..n, where n is number of selected files.
               If there are no selected files, currently active file is nr 1.
               If <nr> is invalid or there is no selected file by that number
               the result for the whole function will be empty string.

  Adding prefix, postfix before or after the result string:
    %X[{<prefix>}][{<postfix>}]
      If applied to multiple files, each name is prefixed/postfixed.

  Above parameters can be combined together.
  Order of params:
  - %function
  - left or right panel (optional)
  - nr of file (optional)
  - prefix, postfix (optional)

  Examples:
    %f1       - first selected file in active panel
    %pr2      - full path of second selected file in right panel
    %fl       - only filenames from left panel
    %pr       - full filenames from right panel
    %Dl       - current path in left panel
    %f{-f }   - prepend each name with "-f "
                (ex.: -f <file_1> -f <file_2>)
    %f{"}{"}  - enclose each name in quotes
                (ex.: "<file_1>" "<file_2>")
    %f1{-first }%f2{ -second }
         - if only 1 file selected      : -first <file_1>
         - if 2 (or more) files selected: -first <file_1> -second <file_2>
}
procedure ReplaceExtCommand(var sCmd: String;
                            leftPanel: TFrameFilePanel;
                            rightPanel: TFrameFilePanel;
                            activePanel: TFrameFilePanel);
type
  TFunctType = (ftNone, ftName, ftDir, ftPath, ftSingleDir);
  TStatePos = (spNone, spPercent, spFunction, spPrefix, spPostfix,
               spGotPrefix, spSide, spIndex, spComplete);

  Tstate = record
    pos: TStatePos;
    functStartIndex: Integer;
    funct: TFunctType;
    files: TStringList;
    dir: String;
    sFileIndex: String;
    prefix, postfix: String; // a string to add before/after each output
                             // (for functions giving output of multiple strings)
  end;

var
  index: Integer;
  leftFiles: TStringList = nil;
  rightFiles: TStringList = nil;
  activeFiles: TStringList;
  activeDir: String;
  state: Tstate;
  sOutput: String = '';
  parseStartIndex: Integer;

  procedure BuildSelectedFilesList(var fileNames: TStringList; panel: TFilePanel);
  var
    pfr: PFileRecItem;
    i: Integer;
  begin
    for i := 0 to panel.FileList.Count - 1 do
    begin
      pfr := panel.FileList.GetItem(i);
      if pfr^.bSelected then
        fileNames.Add(pfr^.sName);
    end;

    // If no files selected add active file.
    if fileNames.Count = 0 then
    begin
      pfr := panel.GetActiveItem;
      if Assigned(pfr) then
        fileNames.Add(pfr^.sName);
    end;
  end;

  function BuildName(fileName: String): String;
  begin
    Result := state.prefix;
    case state.funct of
      ftName:
        Result := Result + QuoteStr(ExtractFileName(fileName));
      ftDir, ftSingleDir:
        Result := Result + QuoteStr(ExcludeTrailingPathDelimiter(state.dir));
      ftPath:
        Result := Result + QuoteStr(state.dir + ExtractFileName(fileName));
      else
        Exit('');
    end;
    Result := Result + state.postfix;
  end;

  function BuildAllNames: String;
  var
    i: Integer;
  begin
    Result := '';
    for i := 0 to state.files.Count - 1 do
    begin
      if i > 0 then
        Result := Result + ' ';
      Result := Result + BuildName(state.files.Strings[i]);
    end;
  end;

  procedure ResetState(var aState: TState);
  begin
    with aState do
    begin
      pos := spNone;
      files := activeFiles;
      dir := activeDir;
      sFileIndex := '';
      funct := ftNone;
      functStartIndex := 0;
      prefix := '';
      postfix := '';
    end;
  end;

  procedure AddParsedText(limit: Integer);
  begin
    // Copy [parseStartIndex .. limit - 1].
    if limit > parseStartIndex then
      sOutput := sOutput + Copy(sCmd, parseStartIndex, limit - parseStartIndex);
    parseStartIndex := index;
  end;

  procedure DoFunction;
  var
    fileIndex: Integer = -1;
  begin
    AddParsedText(state.functStartIndex);

    if state.sFileIndex <> '' then
    try
      fileIndex := StrToInt(state.sFileIndex);
      fileIndex := fileIndex - 1; // Files are counted from 0, but user enters 1..n.
    except
      on EConvertError do
        fileIndex := -1;
    end;

    if fileIndex <> -1 then
    begin
      if (fileIndex >= 0) and (fileIndex < state.files.Count) then
        sOutput := sOutput + BuildName(state.files.Strings[fileIndex]);
    end
    else
    begin
      if state.funct in [ftName, ftPath, ftDir] then
        sOutput := sOutput + BuildAllNames
      else if state.funct in [ftSingleDir] then // only single current dir
        sOutput := sOutput + BuildName('');
    end;

    ResetState(state);
  end;

  procedure ProcessNumber;
  begin
    if state.funct = ftSingleDir then
      // Numbers not allowed for %D
      state.pos := spComplete
    else
    begin
      state.sFileIndex := state.sFileIndex + sCmd[index];
      state.pos := spIndex;
    end;
  end;

  procedure ProcessOpenBracket; // '{'
  begin
    if state.pos <> spGotPrefix then
      state.pos := spPrefix
    else
      state.pos := spPostfix;
  end;

begin
  sCmd:= GetCmdDirFromEnvVar(sCmd);

  try
    leftFiles := TStringList.Create;
    rightFiles := TStringList.Create;
    if (not Assigned(leftFiles)) or (not Assigned(rightFiles)) then
       Exit;

    BuildSelectedFilesList(leftFiles, leftPanel.pnlFile);
    BuildSelectedFilesList(rightFiles, rightPanel.pnlFile);

    if activePanel = leftPanel then
    begin
      activeFiles := leftFiles;
      activeDir := leftPanel.ActiveDir;
    end
    else
    begin
      activeFiles := rightFiles;
      activeDir := rightPanel.ActiveDir;
    end;

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
            'f':
              begin
                state.funct := ftName;
                state.pos := spFunction;
              end;
            'd':
              begin
                state.funct := ftDir;
                state.pos := spFunction;
              end;
            'D':
              begin
                state.funct := ftSingleDir;
                state.pos := spFunction;
              end;
            'p':
              begin
                state.funct := ftPath;
                state.pos := spFunction;
              end;
            else
              ResetState(state);
          end;

        spFunction:
          case sCmd[index] of
            'l':
              begin
                state.files := leftFiles;
                state.dir := leftpanel.ActiveDir;
                state.pos := spSide;
              end;

            'r':
              begin
                state.files := rightFiles;
                state.dir := rightPanel.ActiveDir;
                state.pos := spSide;
              end;

            '0'..'9':
              ProcessNumber;

            '{':
              ProcessOpenBracket;

            else
              state.pos := spComplete;
          end;

        spSide:
          case sCmd[index] of
            '0'..'9':
              ProcessNumber;
            '{':
              ProcessOpenBracket;
            else
              state.pos := spComplete;
          end;

        spIndex:
          case sCmd[index] of
            '0'..'9':
              ProcessNumber;
            '{':
              ProcessOpenBracket;
            else
              state.pos := spComplete;
          end;

        spPrefix, spPostfix:
          case sCmd[index] of
            '}':
              begin
                if state.pos = spPostfix then
                begin
                  Inc(index); // include closing bracket in the function
                  state.pos := spComplete;
                end
                else
                  state.pos := spGotPrefix;
              end;
            else
              begin
                case state.pos of
                  spPrefix:
                    state.prefix := state.prefix + sCmd[index];
                  spPostfix:
                    state.postfix := state.postfix + sCmd[index];
                end;
              end;
          end;

        spGotPrefix:
          case sCmd[index] of
            '{':
              ProcessOpenBracket;
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
    if state.pos in [spFunction, spSide, spIndex, spGotPrefix] then
      DoFunction
    else
      AddParsedText(index);

    sCmd := sOutput;

  finally
    if Assigned(leftFiles) then
      FreeAndNil(leftFiles);
    if Assigned(rightFiles) then
      FreeAndNil(rightFiles);
  end;
end;

procedure ReplaceExtCommand(var sCmd:String; pfr:PFileRecItem; ActiveDir: String);
var
  sDir: String;
  iStart,
  iCount: Integer;
  Process: TProcessUTF8;
begin
  with pfr^ do
  begin
    sDir:= IfThen(sPath<>'', sPath, ActiveDir);
    sCmd:= GetCmdDirFromEnvVar(sCmd);
    sCmd:= StringReplace(sCmd,'%f',QuoteStr(ExtractFileName(sName)),[rfReplaceAll]);
    sCmd:= StringReplace(sCmd,'%d',QuoteStr(sDir),[rfReplaceAll]);
    sCmd:= StringReplace(sCmd,'%p',QuoteStr(sDir+ExtractFileName(sName)),[rfReplaceAll]);
    sCmd:= Trim(sCmd);
    // get output from command between '<?' and '?>'
    if Pos('<?', sCmd) <> 0 then
      begin
        iStart:= Pos('<?', sCmd) + 2;
        iCount:= Pos('?>', sCmd) - iStart;
        sDir:= GetTempFolder + ExtractFileName(sName) + '.tmp';
        Process:= TProcessUTF8.Create(nil);
        Process.CommandLine:= Format(fmtRunInShell, [GetShell, Copy(sCmd, iStart, iCount) + ' > ' + sDir]);
        Process.Options:= [poNoConsole, poWaitOnExit];
        Process.Execute;
        Process.Free;
        sCmd:= Copy(sCmd, 1, iStart-3) + sDir;
//        DebugLn('"'+sCmd+'"');
      end;
  end;
end;

function ProcessExtCommand(sCmd:String; ActiveDir: String): Boolean;
var
  bTerm: Boolean;
begin
  Result:= False;
  bTerm:= False;
  if Pos('{!SHELL}', sCmd) > 0 then
  begin
    sCmd:= StringReplace(sCmd,'{!SHELL}','',[rfReplaceAll]);
    bTerm:= True;
  end;
  if Pos('{!EDITOR}',sCmd) > 0 then
  begin
    sCmd:= Trim(StringReplace(sCmd,'{!EDITOR}','',[rfReplaceAll]));
    uShowForm.ShowEditorByGlob(RemoveQuotation(sCmd));
    Result:= True;
    Exit;
  end;
  if Pos('{!VIEWER}',sCmd) > 0 then
  begin
    sCmd:= Trim(StringReplace(sCmd,'{!VIEWER}','',[rfReplaceAll]));
    uShowForm.ShowViewerByGlob(RemoveQuotation(sCmd));
    Result:= True;
    Exit;
  end;
  mbSetCurrentDir(ActiveDir);
  Result:= ExecCmdFork(sCmd, bTerm, gRunInTerm);
end;

function ShellExecuteEx(sCmd, sFileName, sActiveDir: String): Boolean;
var
  FileRecItem: TFileRecItem;
  sCommand: String;
begin
  Result:= False;
  FillChar(FileRecItem, SizeOf(FileRecItem), #0);
  with FileRecItem do
  begin
    sName:= ExtractFileName(sFileName);
    sPath:= ExtractFilePath(sFileName);
    sExt:= ExtractFileExt(sFileName);
    sCommand:= gExts.GetExtActionCmd(FileRecItem, sCmd);
  end;
  if sCommand <> '' then
    begin
      ReplaceExtCommand(sCommand, @FileRecItem, sActiveDir);
      Result:= ProcessExtCommand(sCommand, sActiveDir);
    end;
  if not Result then
    begin
      mbSetCurrentDir(sActiveDir);
      Result:= ShellExecute(sFileName);
    end;
end;

end.

