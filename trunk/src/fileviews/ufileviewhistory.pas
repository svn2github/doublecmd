{
   Double Commander
   -------------------------------------------------------------------------
   History of visited paths, file sources for a file view.

   Copyright (C) 2010  Przemyslaw Nagay (cobines@gmail.com)

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

unit uFileViewHistory;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uFileSource;

type

  { TFileViewHistory }

  TFileViewHistory = class
  private
    FCurrentFileSource: Integer;
    FCurrentPath: Integer;
    FHistory: TFPList; // of PFileViewHistoryEntry

    procedure Delete(Index: Integer);
    {en
       Delete history after current indexes.
    }
    procedure DeleteAfterCurrent;
    function GetCount: Integer; // = FileSourcesCount
    function GetCurrentFileSource: IFileSource;
    function GetCurrentPath: String;
    function GetCurrentFilename: String;
    function GetFileSource(Index: Integer): IFileSource;
    function GetPath(FileSourceIndex, PathIndex: Integer): String;
    function GetFilename(FileSourceIndex, FilenameIndex: Integer): String;
    function GetPathsCount(Index: Integer): Integer;

  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    {$IFDEF DEBUG_HISTORY}
    procedure DebugShow;
    {$ENDIF}
    procedure Add(aFileSource: IFileSource; aPath: String);
    procedure AddFileSource(aFileSource: IFileSource);
    procedure AddPath(aPath: String);
    procedure SetFilenameForCurrentPath(aFilename: String);
    procedure Assign(otherHistory: TFileViewHistory);
    procedure DeleteFromCurrentFileSource;
    procedure SetIndexes(aFileSourceIndex: Integer; aCurrentPathIndex: Integer);

    property Count: Integer read GetCount;
    property CurrentFileSource: IFileSource read GetCurrentFileSource;
    property CurrentFileSourceIndex: Integer read FCurrentFileSource write FCurrentFileSource;
    property CurrentPath: String read GetCurrentPath;
    property CurrentFilename: String read GetCurrentFilename;
    property CurrentPathIndex: Integer read FCurrentPath write FCurrentPath;
    property FileSource[Index: Integer]: IFileSource read GetFileSource;
    property Path[FileSourceIndex, PathIndex: Integer]: String read GetPath;
    property Filename[FileSourceIndex, FilenameIndex: Integer]: String read GetFilename;
    property PathsCount[Index: Integer]: Integer read GetPathsCount;
  end;

implementation

type
  PFileViewHistoryEntry = ^TFileViewHistoryEntry;
  TFileViewHistoryEntry = record
    FileSource: IFileSource;
    PathsList : TStringList; // paths always include trailing path delimiter
    FilenamesList : TStringList;
    //TODO: refactor this!
    //      it's much better to store list of objects each of them contain
    //      both path and filename, instead of keeping two separate lists.
    //      (right now, quick-n-dirty solution was applied)
  end;

{ TFileViewHistory }

constructor TFileViewHistory.Create;
begin
  FHistory := TFPList.Create;
  FCurrentFileSource := -1;
  FCurrentPath := -1;
end;

destructor TFileViewHistory.Destroy;
begin
  inherited Destroy;
  Clear;
  FreeAndNil(FHistory);
end;

procedure TFileViewHistory.Clear;
var
  i: Integer;
begin
  for i := FHistory.Count - 1 downto 0 do
    Delete(i);
  FCurrentFileSource := -1;
  FCurrentPath := -1;
end;

{$IFDEF DEBUG_HISTORY}
procedure TFileViewHistory.DebugShow;
var
  i, j: Integer;
  HistEntry: PFileViewHistoryEntry;
begin
  for i := 0 to FHistory.Count - 1 do
  begin
    HistEntry := PFileViewHistoryEntry(FHistory.Items[i]);
    WriteLn('--------------------------------------');
    WriteLn('   ', HistEntry^.FileSource.ClassName);
    for j := 0 to HistEntry^.PathsList.Count - 1 do
    begin
      if (i = FCurrentFileSource) and (j = FCurrentPath) then
        Write('=>   ')
      else
        Write('     ');
      WriteLn(HistEntry^.PathsList.Strings[j]);
    end;
  end;
end;
{$ENDIF}

function TFileViewHistory.GetCount: Integer;
begin
  Result := FHistory.Count;
end;

function TFileViewHistory.GetCurrentFileSource: IFileSource;
begin
  if FCurrentFileSource >= 0 then
    Result := PFileViewHistoryEntry(FHistory[FCurrentFileSource])^.FileSource
  else
    Result := nil;
end;

function TFileViewHistory.GetCurrentPath: String;
begin
  if (FCurrentFileSource >= 0) and (FCurrentPath >= 0) then
    Result := PFileViewHistoryEntry(FHistory[FCurrentFileSource])^.PathsList[FCurrentPath]
  else
    Result := EmptyStr;
end;

function TFileViewHistory.GetCurrentFilename: String;
begin
  if (FCurrentFileSource >= 0) and (FCurrentPath >= 0) then
    Result := PFileViewHistoryEntry(FHistory[FCurrentFileSource])^.FilenamesList[FCurrentPath]
  else
    Result := EmptyStr;
end;

function TFileViewHistory.GetFileSource(Index: Integer): IFileSource;
begin
  Result := PFileViewHistoryEntry(FHistory.Items[Index])^.FileSource;
end;

function TFileViewHistory.GetPath(FileSourceIndex, PathIndex: Integer): String;
begin
  Result := PFileViewHistoryEntry(FHistory.Items[FileSourceIndex])^.PathsList.Strings[PathIndex];
end;

function TFileViewHistory.GetFilename(FileSourceIndex, FilenameIndex: Integer): String;
begin
  Result := PFileViewHistoryEntry(FHistory.Items[FileSourceIndex])^.FilenamesList.Strings[FilenameIndex];
end;

function TFileViewHistory.GetPathsCount(Index: Integer): Integer;
begin
  Result := PFileViewHistoryEntry(FHistory.Items[Index])^.PathsList.Count;
end;

procedure TFileViewHistory.Add(aFileSource: IFileSource; aPath: String);
begin
  AddFileSource(aFileSource);
  AddPath(aPath);
end;

procedure TFileViewHistory.AddFileSource(aFileSource: IFileSource);
var
  HistEntry: PFileViewHistoryEntry;
begin
  if FCurrentFileSource >= 0 then
  begin
    DeleteAfterCurrent;

    HistEntry := PFileViewHistoryEntry(FHistory.Items[FCurrentFileSource]);

    // Don't add if the current file source is the same.
    if HistEntry^.FileSource.Equals(aFileSource) then
      Exit;
  end;

  New(HistEntry);
  FHistory.Add(HistEntry);
  HistEntry^.FileSource := aFileSource;
  HistEntry^.PathsList := TStringList.Create;
  HistEntry^.FilenamesList := TStringList.Create;
  Inc(FCurrentFileSource);
  FCurrentPath := -1;
end;

procedure TFileViewHistory.SetFilenameForCurrentPath(aFilename: String);
var
  aFilenames: TStringList;
begin
  aFilenames := PFileViewHistoryEntry(FHistory.Items[FCurrentFileSource])^.FilenamesList;

  if (FCurrentPath >= 0) then
  begin
    aFilenames[FCurrentPath] := aFilename;
  end
end;

procedure TFileViewHistory.AddPath(aPath: String);
var
  aPaths: TStringList;
  aFilenames: TStringList;
begin
  if FCurrentFileSource >= 0 then
  begin
    DeleteAfterCurrent;

    aPaths     := PFileViewHistoryEntry(FHistory.Items[FCurrentFileSource])^.PathsList;
    aFilenames := PFileViewHistoryEntry(FHistory.Items[FCurrentFileSource])^.FilenamesList;

    if aPath <> '' then
      aPath := IncludeTrailingPathDelimiter(aPath);

    if (aPaths.Count = 0) or (aPaths.Strings[FCurrentPath] <> aPath) then
    begin
      aPaths.Add(aPath);
      aFilenames.Add('');
      if aPaths.Count > 50 then
      begin
        aPaths.Delete(0);
        aFilenames.Delete(0);
      end
      else
        Inc(FCurrentPath);
    end;
  end;
end;

procedure TFileViewHistory.Assign(otherHistory: TFileViewHistory);
var
  i: Integer;
  HistEntry, otherHistEntry: PFileViewHistoryEntry;
begin
  Clear;

  for i := 0 to otherHistory.FHistory.Count - 1 do
  begin
    otherHistEntry := PFileViewHistoryEntry(otherHistory.FHistory.Items[i]);
    New(HistEntry);
    FHistory.Add(HistEntry);
    HistEntry^.FileSource := otherHistEntry^.FileSource;
    HistEntry^.PathsList := TStringList.Create;
    HistEntry^.PathsList.AddStrings(otherHistEntry^.PathsList);
    HistEntry^.FilenamesList := TStringList.Create;
    HistEntry^.FilenamesList.AddStrings(otherHistEntry^.FilenamesList);
  end;

  FCurrentFileSource := otherHistory.FCurrentFileSource;
  FCurrentPath := otherHistory.FCurrentPath;
end;

procedure TFileViewHistory.Delete(Index: Integer);
var
  HistEntry: PFileViewHistoryEntry;
begin
  HistEntry := PFileViewHistoryEntry(FHistory.Items[Index]);
  FHistory.Delete(Index);
  HistEntry^.FileSource := nil;
  HistEntry^.PathsList.Free;
  HistEntry^.FilenamesList.Free;
  Dispose(HistEntry);
end;

procedure TFileViewHistory.DeleteAfterCurrent;
var
  i: Integer;
  aPaths: TStringList;
  aFilenames: TStringList;
begin
  if FHistory.Count > 0 then
  begin
    for i := FHistory.Count - 1 downto FCurrentFileSource + 1 do
      Delete(i);
    aPaths := PFileViewHistoryEntry(FHistory.Items[FCurrentFileSource])^.PathsList;
    aFilenames := PFileViewHistoryEntry(FHistory.Items[FCurrentFileSource])^.FilenamesList;
    for i := aPaths.Count - 1 downto FCurrentPath + 1 do
    begin
      aPaths.Delete(i);
      aFilenames.Delete(i);
    end;
  end;
end;

procedure TFileViewHistory.DeleteFromCurrentFileSource;
var
  i: Integer;
begin
  if FHistory.Count > 0 then
  begin
    for i := FHistory.Count - 1 downto FCurrentFileSource do
      Delete(i);
    Dec(FCurrentFileSource);

    if FCurrentFileSource >= 0 then
      // Set to last entry.
      FCurrentPath := PathsCount[FCurrentFileSource] - 1
    else
      FCurrentFileSource := -1;
  end;
end;

procedure TFileViewHistory.SetIndexes(aFileSourceIndex: Integer; aCurrentPathIndex: Integer);
begin
  FCurrentFileSource := aFileSourceIndex;
  FCurrentPath := aCurrentPathIndex;
end;

end.

