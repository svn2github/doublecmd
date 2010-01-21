unit uWfxPluginMoveOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceMoveOperation,
  uFileSource,
  uFileSourceOperation,
  uFileSourceOperationOptions,
  uFile,
  uFileSystemFile,
  uWfxPluginFile,
  uWfxPluginFileSource,
  uWfxPluginUtil;

type

  { TWfxPluginMoveOperation }

  TWfxPluginMoveOperation = class(TFileSourceMoveOperation)

  private
    FWfxPluginFileSource: IWfxPluginFileSource;
    FOperationHelper: TWfxPluginOperationHelper;
    FCallbackDataClass: TCallbackDataClass;
    FFullFilesTreeToCopy: TFileSystemFiles;  // source files including all files/dirs in subdirectories
    FStatistics: TFileSourceMoveOperationStatistics; // local copy of statistics
    FCurrentFileSize: Int64;
    // Options
    FInternal: Boolean;
    FFileExistsOption: TFileSourceOperationOptionFileExists;
  protected
    function UpdateProgress(SourceName, TargetName: UTF8String; PercentDone: Integer): Integer;

  public
    constructor Create(aFileSource: IFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;

    property FileExistsOption: TFileSourceOperationOptionFileExists read FFileExistsOption write FFileExistsOption;

  end;

implementation

uses
  uOSUtils, FileUtil, LCLProc, uGlobs, WfxPlugin, uFileSystemUtil;

// -- TWfxPluginMoveOperation ---------------------------------------------

function TWfxPluginMoveOperation.UpdateProgress(SourceName, TargetName: UTF8String;
                                                PercentDone: Integer): Integer;
begin
  Result := 0;

  //DebugLn('SourceName=', SourceName, #32, 'TargetName=', TargetName, #32, 'PercentDone=', IntToStr(PercentDone));

  if State = fsosStopping then  // Cancel operation
    Exit(1);

  with FStatistics do
  begin
    FStatistics.CurrentFileFrom:= SourceName;
    FStatistics.CurrentFileTo:= TargetName;

    CurrentFileDoneBytes:= CurrentFileTotalBytes * PercentDone div 100;
    DoneBytes := DoneBytes + CurrentFileDoneBytes;

    UpdateStatistics(FStatistics);
  end;
end;

constructor TWfxPluginMoveOperation.Create(aFileSource: IFileSource;
                                           var theSourceFiles: TFiles;
                                           aTargetPath: String);
begin
  FWfxPluginFileSource:= aFileSource as IWfxPluginFileSource;
  FCallbackDataClass:= TCallbackDataClass.Create(FWfxPluginFileSource, @UpdateProgress);
  FInternal:= True;
  inherited Create(aFileSource, theSourceFiles, aTargetPath);
end;

destructor TWfxPluginMoveOperation.Destroy;
begin
  if Assigned(FCallbackDataClass) then
    FreeAndNil(FCallbackDataClass);
  inherited Destroy;
end;

procedure TWfxPluginMoveOperation.Initialize;
begin
  with FWfxPluginFileSource do
  begin
    WfxModule.WfxStatusInfo(SourceFiles.Path, FS_STATUS_START, FS_STATUS_OP_PUT_MULTI);
    WfxOperationList.Objects[PluginNumber]:= FCallbackDataClass;
    // Get initialized statistics; then we change only what is needed.
    FStatistics := RetrieveStatistics;

    FillAndCount(SourceFiles, False,
                 FFullFilesTreeToCopy,
                 FStatistics.TotalFiles,
                 FStatistics.TotalBytes);     // gets full list of files (recursive)
  end;

  // Make filenames relative to current directory.
  FFullFilesTreeToCopy.Path := SourceFiles.Path;

  if Assigned(FOperationHelper) then
    FreeAndNil(FOperationHelper);

  FOperationHelper := TWfxPluginOperationHelper.Create(
                        FWfxPluginFileSource,
                        @AskQuestion,
                        @RaiseAbortOperation,
                        @CheckOperationState,
                        @UpdateStatistics,
                        Thread,
                        wpohmMoveIn,
                        TargetPath,
                        FStatistics);

  FOperationHelper.RenameMask := RenameMask;
  FOperationHelper.FileExistsOption := FileExistsOption;

  FOperationHelper.Initialize(FInternal);
end;

procedure TWfxPluginMoveOperation.MainExecute;
begin
  FOperationHelper.ProcessFiles(FFullFilesTreeToCopy);
end;

procedure TWfxPluginMoveOperation.Finalize;
begin
  with FWfxPluginFileSource do
  begin
    WfxModule.WfxStatusInfo(SourceFiles.Path, FS_STATUS_END, FS_STATUS_OP_PUT_MULTI);
    WfxOperationList.Objects[PluginNumber]:= nil;
  end;
end;

end.

