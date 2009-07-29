unit uFileSourceCopyOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, syncobjs,
  uFileSourceOperation,
  uFileSourceOperationTypes,
  uFileSource,
  uFile;

type

  // Statistics are the same for CopyIn and CopyOut operations.
  TFileSourceCopyOperationStatistics = record
    CurrentFileFrom: String;
    CurrentFileTo: String;
    CurrentFileTotalBytes: Int64;
    CurrentFileDoneBytes: Int64;
    TotalFiles: Int64;
    DoneFiles: Int64;
    TotalBytes: Int64;
    DoneBytes: Int64;
    BytesPerSecond: Int64;
    RemainingTime: TDateTime;
  end;

  {en
     Base class for CopyIn and CopyOut operations.
  }
  TFileSourceCopyOperation = class(TFileSourceOperation)

  private
    FStatistics: TFileSourceCopyOperationStatistics;
    FStatisticsAtStartTime: TFileSourceCopyOperationStatistics;
    FStatisticsLock: TCriticalSection;             //<en For synchronizing statistics.
    FSourceFileSource: TFileSource;
    FTargetFileSource: TFileSource;
    FSourceFiles: TFiles;
    FTargetPath: String;

  protected
    procedure UpdateStatistics(NewStatistics: TFileSourceCopyOperationStatistics);
    procedure UpdateStatisticsAtStartTime; override;
    procedure EstimateSpeedAndTime(var theStatistics: TFileSourceCopyOperationStatistics);

    property SourceFiles: TFiles read FSourceFiles;
    property TargetPath: String read FTargetPath;

  public
    {en
       @param(SourceFileSource
              File source from which the files will be copied.
              Class takes ownership of the pointer.)
       @param(Target file source
              File source to which the files will be copied.
              Class takes ownership of the pointer.)
       @param(SourceFiles
              Files which are to be copied.
              Class takes ownership of the pointer.)
    }
    constructor Create(var aSourceFileSource: TFileSource;
                       var aTargetFileSource: TFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String;
                       aRenameMask: String); virtual reintroduce;

    destructor Destroy; override;

    function RetrieveStatistics: TFileSourceCopyOperationStatistics;
  end;

  {en
     Operation that copies files from another file source into a file source of specific type
     (to file system for TFileSystemCopyInOperation,
      to network for TNetworkCopyInOperation, etc.).

     Source file source must be a file system file source.
     (Or is it enough if it's a file source with directly accessible files ? (DirectAccess flag))
     Target file source should match the class type.

     Example meaning of this operation:
     - archive: pack
     - network: upload
  }
  TFileSourceCopyInOperation = class(TFileSourceCopyOperation)

  protected
    function GetID: TFileSourceOperationType; override;

  end;

  {en
     Operation that copies files into another file source from a file source of specific type
     (from file system for TFileSystemCopyOutOperation,
      from network for TNetworkCopyOutOperation, etc.).

     Source file source should match the class type.
     Target file source must be a file system file source.
     (Or is it enough if it's a file source with directly accessible files ? (DirectAccess flag))

     Example meaning of this operation:
     - archive: unpack
     - network: download
  }
  TFileSourceCopyOutOperation = class(TFileSourceCopyOperation)

  protected
    function GetID: TFileSourceOperationType; override;

  end;

implementation

uses
  uDCUtils;

// -- TFileSourceCopyOperation ------------------------------------------------

constructor TFileSourceCopyOperation.Create(var aSourceFileSource: TFileSource;
                                            var aTargetFileSource: TFileSource;
                                            var theSourceFiles: TFiles;
                                            aTargetPath: String;
                                            aRenameMask: String);
begin
  with FStatistics do
  begin
    CurrentFileFrom := '';
    CurrentFileTo := '';

    TotalFiles := 0;
    DoneFiles := 0;
    TotalBytes := 0;
    DoneBytes := 0;
    CurrentFileTotalBytes := 0;
    CurrentFileDoneBytes := 0;
    BytesPerSecond := 0;
    RemainingTime := 0;
  end;

  FStatisticsLock := TCriticalSection.Create;

  case GetID of
    fsoCopyIn:
      // Copy into target - run on target (target is changed).
      inherited Create(aTargetFileSource, aTargetFileSource);
    fsoCopyOut:
      // Copy out from source - run on source (target is changed).
      inherited Create(aSourceFileSource, aTargetFileSource);
    else
      raise Exception.Create('Invalid file source type');
  end;

  FSourceFileSource := aSourceFileSource;
  aSourceFileSource := nil;
  FTargetFileSource := aTargetFileSource;
  aTargetFileSource := nil;
  FSourceFiles := theSourceFiles;
  theSourceFiles := nil;
  FTargetPath := aTargetPath;
end;

destructor TFileSourceCopyOperation.Destroy;
begin
  inherited Destroy;

  if Assigned(FStatisticsLock) then
    FreeAndNil(FStatisticsLock);
  if Assigned(FSourceFiles) then
    FreeAndNil(FSourceFiles);
  if Assigned(FSourceFileSource) then
    FreeAndNil(FSourceFileSource);
  if Assigned(FTargetFileSource) then
    FreeAndNil(FTargetFileSource);
end;

procedure TFileSourceCopyOperation.UpdateStatistics(NewStatistics: TFileSourceCopyOperationStatistics);
begin
  FStatisticsLock.Acquire;
  try
    Self.FStatistics := NewStatistics;
  finally
    FStatisticsLock.Release;
  end;
end;

procedure TFileSourceCopyOperation.UpdateStatisticsAtStartTime;
begin
  FStatisticsLock.Acquire;
  try
    Self.FStatisticsAtStartTime := Self.FStatistics;
  finally
    FStatisticsLock.Release;
  end;
end;

function TFileSourceCopyOperation.RetrieveStatistics: TFileSourceCopyOperationStatistics;
begin
  // Statistics have to be synchronized because there are multiple values
  // and they all have to be consistent at every moment.
  FStatisticsLock.Acquire;
  try
    Result := Self.FStatistics;
  finally
    FStatisticsLock.Release;
  end;
end;

procedure TFileSourceCopyOperation.EstimateSpeedAndTime(
              var theStatistics: TFileSourceCopyOperationStatistics);
begin
  FStatisticsLock.Acquire;
  try
    theStatistics.RemainingTime :=
        EstimateRemainingTime(FStatisticsAtStartTime.DoneBytes,
                              theStatistics.DoneBytes,
                              theStatistics.TotalBytes,
                              StartTime,
                              SysUtils.Now,
                              theStatistics.BytesPerSecond);
  finally
    FStatisticsLock.Release;
  end;
end;

// -- TFileSourceCopyInOperation ----------------------------------------------

function TFileSourceCopyInOperation.GetID: TFileSourceOperationType;
begin
  Result := fsoCopyIn;
end;

// -- TFileSourceCopyOutOperation ---------------------------------------------

function TFileSourceCopyOutOperation.GetID: TFileSourceOperationType;
begin
  Result := fsoCopyOut;
end;

end.

