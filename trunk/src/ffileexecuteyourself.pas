{
   Double Commander
   -------------------------------------------------------------------------
   Copy out, execute and delete files from non FileSystemFileSource

   Copyright (C) 2010  Koblov Alexander (Alexx2000@mail.ru)

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

unit fFileExecuteYourSelf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Buttons, uFile, uFileSource, uFileView;

type

  { TfrmFileExecuteYourSelf }

  TfrmFileExecuteYourSelf = class(TForm)
    btnClose: TBitBtn;
    lblFromPath: TLabel;
    lblFileName: TLabel;
    lblFromPathValue: TLabel;
    lblFileNameValue: TLabel;
    lblPrompt: TLabel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    FFileSource: IFileSource;
  public
    constructor Create(TheOwner: TComponent; aFileSource: IFileSource; const FileName, FromPath: UTF8String); reintroduce;
    destructor Destroy; override;
  end; 

function ShowFileExecuteYourSelf(aFileView: TFileView; aFile: TFile): Boolean;

implementation

{$R *.lfm}

uses
  LCLProc, uTempFileSystemFileSource, uFileSourceOperation, uShellExecute, uOSUtils;

function ShowFileExecuteYourSelf(aFileView: TFileView; aFile: TFile): Boolean;
var
  ActiveFile: TFile = nil;
  TempFiles: TFiles = nil;
  TempFileSource: ITempFileSystemFileSource = nil;
  Operation: TFileSourceOperation = nil;
  CurrentDir: UTF8String;
begin
  Result:= False;
  try
    ActiveFile:= aFile.Clone;
    TempFiles:= TFiles.Create(aFileView.CurrentPath);
    TempFiles.Add(aFile.Clone);
    TempFileSource:= TTempFileSystemFileSource.GetFileSource;
    Operation := aFileView.FileSource.CreateCopyOutOperation(
                            TempFileSource,
                            TempFiles,
                            TempFileSource.FileSystemRoot);

    if not Assigned(Operation) then Exit;

    Operation.Execute;
    FreeAndNil(Operation);

    CurrentDir:= mbGetCurrentDir;
    Result:= ShellExecuteEx('open', TempFileSource.FileSystemRoot + aFile.Name, TempFileSource.FileSystemRoot + aFile.Path);
    mbSetCurrentDir(CurrentDir);
    if Result then
    begin
      with TfrmFileExecuteYourSelf.Create(Application, TempFileSource, aFile.Name, aFileView.CurrentAddress + aFileView.CurrentPath) do
      Show;
    end;
  finally
    FreeThenNil(ActiveFile);
    FreeThenNil(TempFiles);
  end;
end;

{ TfrmFileExecuteYourSelf }

procedure TfrmFileExecuteYourSelf.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction:= caFree;
end;

constructor TfrmFileExecuteYourSelf.Create(TheOwner: TComponent;
  aFileSource: IFileSource; const FileName, FromPath: UTF8String);
begin
  inherited Create(TheOwner);
  FFileSource:= aFileSource;
  lblFileNameValue.Caption:= FileName;
  lblFromPathValue.Caption:= FromPath;
end;

destructor TfrmFileExecuteYourSelf.Destroy;
begin
  // Delete the temporary file source and all files inside.
  FFileSource:= nil;
  inherited Destroy;
end;

end.

