unit uWcxArchiveListOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceListOperation,
  uWcxArchiveFileSource;

type

  TWcxArchiveListOperation = class(TFileSourceListOperation)
  private
    FWcxArchiveFileSource: TWcxArchiveFileSource;
  public
    constructor Create(var aFileSource: TWcxArchiveFileSource); reintroduce;
    procedure Execute; override;
  end;

implementation

uses
  LCLProc, uFileSystemFile, uFindEx, uOSUtils, uDCUtils, uWcxArchiveFile, uFile;

constructor TWcxArchiveListOperation.Create(var aFileSource: TWcxArchiveFileSource);
begin
  FFiles := TFiles.Create;
  FWcxArchiveFileSource := aFileSource;
  inherited Create(aFileSource);
end;

procedure TWcxArchiveListOperation.Execute;
var
  I : Integer;
  CurrFileName : String;  // Current file name
  ArcFileList: TList;
  aFile: TWcxArchiveFile;
begin
  FFiles.Clear;
  FFiles.Path := IncludeTrailingPathDelimiter(FileSource.CurrentPath);

  if not FileSource.IsAtRootPath then
  begin
    aFile := TWcxArchiveFile.Create;
    aFile.Path := FileSource.CurrentPath;
    aFile.Name := '..';
    aFile.Attributes := faFolder;
    FFiles.Add(AFile);
  end;

  ArcFileList := FWcxArchiveFileSource.ArchiveFileList;
  for I := 0 to ArcFileList.Count - 1 do
    begin
      CurrFileName := PathDelim + TWCXHeader(ArcFileList.Items[I]).FileName;

      if not IsInPath(FileSource.CurrentPath, CurrFileName, False) then
        Continue;

      aFile := TWcxArchiveFile.Create(TWCXHeader(ArcFileList.Items[I]));
      aFile.Path := FileSource.CurrentPath;
      FFiles.Add(AFile);
    end;
end;

end.

