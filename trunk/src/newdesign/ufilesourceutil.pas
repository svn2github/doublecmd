unit uFileSourceUtil;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSource, uFileView, uFile;

procedure ChooseFile(aFileView: TFileView; aFile: TFile);
function RenameFile(aFileSource: TFileSource; aFile: TFile; NewFileName: UTF8String): Boolean;

implementation

uses
  uFileSystemFileSource, uGlobs, uShellExecute, uOSUtils,
  uFileSourceOperation, uFileSourceExecuteOperation, uFileSourceMoveOperation,
  uVfsFileSource, uWcxArchiveFileSource, uWfxPluginFileSource, uFileSourceOperationTypes, LCLProc;

procedure ChooseFile(aFileView: TFileView; aFile: TFile);
var
  sOpenCmd: String;
  FileSource: TFileSource;
  Operation: TFileSourceExecuteOperation;
begin
  // For now work only for FileSystem until temporary file system is done.
  if aFileView.FileSource is TFileSystemFileSource then
  begin
    // Check if it is registered plugin (for archives).
    FileSource := TWcxArchiveFileSource.CreateByArchiveName(aFile.Path + aFile.Name);
    if Assigned(FileSource) then
    begin
      aFileView.AddFileSource(FileSource);
      Exit;
    end;

    //now test if exists Open command in doublecmd.ext :)
    sOpenCmd:= gExts.GetExtActionCmd(aFile, 'open');
    if (sOpenCmd<>'') then
    begin
{
      if Pos('{!VFS}',sOpenCmd)>0 then
      begin
        if fVFS.FindModule(sName) then
        begin
          LoadPanelVFS(pfri);
          Exit;
        end;
      end;
}
      ReplaceExtCommand(sOpenCmd, aFile, aFileView.FileSource.CurrentPath);
      if ProcessExtCommand(sOpenCmd, aFileView.FileSource.CurrentPath) then
        Exit;
    end;
  end;

  // Work only for TVfsFileSource.
  if aFileView.FileSource is TVfsFileSource then
  begin
    // Check if it is registered plugin by file system root name.
    FileSource := TWfxPluginFileSource.CreateByRootName(aFile.Name);
    if Assigned(FileSource) then
    begin
      aFileView.AddFileSource(FileSource);
      Exit;
    end;
  end;

  if (fsoExecute in aFileView.FileSource.GetOperationsTypes) then
    begin
      Operation := aFileView.FileSource.CreateExecuteOperation(aFile.Name, 'open') as TFileSourceExecuteOperation;
      if Assigned(Operation) then
        try
          Operation.Execute;
          case Operation.ExecuteOperationResult of
          fseorError:
            // Show error message
            DebugLn('Execution error!');
          fseorYourSelf:
            begin
              // CopyOut file to temp file system and execute
            end;
          fseorSymLink:
            // change directory to new path (returned in Operation.ExecutablePath)
            DebugLn('Change directory to ', Operation.ExecutablePath);
          end;
        finally
          FreeAndNil(Operation);
          aFileView.Reload;
        end;
    end;
end;

function RenameFile(aFileSource: TFileSource; aFile: TFile; NewFileName: UTF8String): Boolean;
var
  aFiles: TFiles;
  sDestPath: UTF8String;
  Operation: TFileSourceMoveOperation;
begin
  Result:= False;
  with aFileSource.GetFiles do
  begin
    aFiles:= CreateObjectOfSameType;
    Free;
  end;
  aFiles.Add(aFile);
  sDestPath:= ExtractFilePath(NewFileName);
  Operation := aFileSource.CreateMoveOperation(
                         aFiles, sDestPath) as TFileSourceMoveOperation;
  if Assigned(Operation) then
    try
      Operation.RenameMask := ExtractFileName(NewFileName);
      Operation.Execute;
      Result:= True;
    finally
      FreeAndNil(Operation);
    end;
  FreeThenNil(aFiles);
end;

end.

