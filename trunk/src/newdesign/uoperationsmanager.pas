unit uOperationsManager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, LCLIntf, uLng,
  uOperationThread, uFileSourceOperation, lclproc;

type

  {en Handle to OperationsManager's operation.}
  TOperationHandle = Longint;

const
  InvalidOperationHandle = TOperationHandle(0);

type

  {en
     Possible options when adding a new operation.
  }
  TOperationStartingState =
    (ossInvalid,
     ossManualStart,    //<en Don't start automatically. Must be explicitly started.
     ossAutoStart,      //<en Start automatically, regardless if any operations are currently running.
     ossQueueFirst,     //<en Don't start automatically,
                        //<en unless there are no other operations working.
                        //<en Will be started when there are no operation running.
                        //<en This option will put the operation to the head of the queue.
     ossQueueLast,      //<en Same as ossQueueFirst, but this option will put the
                        //<en operation to the back of the queue.
     ossQueueIn         //<en insert operation to queue.
    );

const
  OperationStartingStateText: array[TOperationStartingState] of string =
    ('', rsOperManualStart, rsOperAutoStart, rsOperQueue, rsOperQueue, rsOperQueue);

type

  POperationsManagerEntry = ^TOperationsManagerEntry;
  TOperationsManagerEntry = record
    Thread       : TOperationThread;
    Operation    : TFileSourceOperation;
    Handle       : TOperationHandle;
    StartingState: TOperationStartingState;
    Form         : Boolean;
    PauseRunning : Boolean;

  end;

  TOperationManagerEvent =
    (omevOperationAdded,
     omevOperationRemoved,
     omevOperationStarted,
     omevOperationFinished);

  TOperationManagerEvents = set of TOperationManagerEvent;

  TOperationManagerEventNotify = procedure(Operation: TFileSourceOperation;
                                           Event: TOperationManagerEvent) of object;

  {en
     Manages file source operations.
     Executes them, stores threads, allows querying active operations
     (meaning operations being executed).
  }

  { TOperationsManager }

  TOperationsManager = class
  private
    FOperations: TFPList;         //<en List of TOperationsManagerEntry
    FLastUsedHandle: TOperationHandle;
    FEventsListeners: array[TOperationManagerEvent] of TFPList;

    procedure ThreadTerminatedEvent(Sender: TObject);

    function GetOperationsCount: Integer;

    function GetNextUnusedHandle: TOperationHandle;

    function GetEntryByHandle(Handle: TOperationHandle): POperationsManagerEntry;
    function GetEntryByOperation(Operation: TFileSourceOperation): POperationsManagerEntry;



    {en
       Returns @true if there is at least one operation currently running.
    }
    function AreOperationsRunning: Boolean;

    procedure StartOperation(Entry: POperationsManagerEntry);

    procedure AddOperationListeners(Operation: TFileSourceOperation);
    procedure RemoveOperationListeners(Operation: TFileSourceOperation);

    procedure OperationStateChangedEvent(Operation: TFileSourceOperation;
                                         State: TFileSourceOperationState);

    {en
       Notifies all listeners that an event has occurred (or multiple events).
    }
    procedure NotifyEvents(Operation: TFileSourceOperation; Events: TOperationManagerEvents);

  public
    constructor Create;
    destructor Destroy; override;

    {en
       Checks if there is any queued operation and if all other operations
       are stopped, then the next queued operations is started.
    }
    procedure CheckQueuedOperations;



    {ru
       ��������� �������� � ������� �� �� Handle
    }

    procedure SetToQueue (Handle: TOperationHandle);

    procedure SetFormCreate (Handle: TOperationHandle; setForm: boolean);
    procedure SetPauseRunning (Handle: TOperationHandle; setForm: boolean);

    function AddOperation(Operation: TFileSourceOperation;
                          StartingState: TOperationStartingState): TOperationHandle;

    {en
       Operations retrieved this way can be safely used from the main GUI thread.
       But they should not be stored for longer use, because they
       may be destroyed by the Operations Manager when they finish.
       Operation handle can always be used to safely query OperationsManager
       for a specific operation.
       Also OperationExists function can be used to query OperationsManager
       if the given pointer to a operation is still registered (and thus not
       yet destroyed).
    }
    function GetOperationByIndex(Index: Integer): TFileSourceOperation;
    function GetOperationByHandle(Handle: TOperationHandle): TFileSourceOperation;
    function GetHandleById(Index: Integer): TOperationHandle;
    function GetStartingState(Handle: TOperationHandle): TOperationStartingState;
    function GetFormCreate (Handle: TOperationHandle): boolean;
    function GetPauseRunning (Handle: TOperationHandle): boolean;
    {en
       Changes the entry's (and thus operation's) position in the list.
       It is used to change the order of execution of queued operations.
       @param(FromIndex is an index in the operations list of the entry that should be moved.)
       @param(ToIndex is an index in the operations list where the entry should be moved to.)
    }
    procedure MoveOperation(FromIndex: Integer; ToIndex: Integer);

    procedure CancelAll;
    procedure StartAll;
    procedure PauseAll;
    procedure PauseRunning;
    procedure StartRunning;
    function  AllProgressPoint: Integer;

    {en
       This function is used to check if the pointer to an operation is still
       valid. If an operation is registered in OperationsManager the function
       returns @true.
       @param(Operation is the pointer which should be checked.)
    }
    function OperationExists(Operation: TFileSourceOperation): Boolean;

    {en
       Adds a function to call on specific events.
    }
    procedure AddEventsListener(Events: TOperationManagerEvents;
                                FunctionToCall: TOperationManagerEventNotify);

    {en
       Removes a registered function callback for events.
    }
    procedure RemoveEventsListener(Events: TOperationManagerEvents;
                                   FunctionToCall: TOperationManagerEventNotify);

    property OperationsCount: Integer read GetOperationsCount;
  end;

var
  OperationsManager: TOperationsManager = nil;

implementation

type
  PEventsListEntry = ^TEventsListEntry;
  TEventsListEntry = record
    EventFunction: TOperationManagerEventNotify;
  end;

constructor TOperationsManager.Create;
var
  Event: TOperationManagerEvent;
begin
  FOperations := TFPList.Create;
  FLastUsedHandle := 0;

  for Event := Low(FEventsListeners) to High(FEventsListeners) do
    FEventsListeners[Event] := TFPList.Create;

  inherited Create;
end;

destructor TOperationsManager.Destroy;
var
  i: Integer;
  Entry: POperationsManagerEntry;
  Event: TOperationManagerEvent;
begin
  inherited Destroy;

  // If any operations still exist, remove listeners as we're destroying the object.
  for i := 0 to FOperations.Count - 1 do
  begin
    Entry := POperationsManagerEntry(FOperations.Items[i]);
    RemoveOperationListeners(Entry^.Operation);
  end;

  for Event := Low(FEventsListeners) to High(FEventsListeners) do
  begin
    for i := 0 to FEventsListeners[Event].Count - 1 do
      Dispose(PEventsListEntry(FEventsListeners[Event].Items[i]));

    FreeAndNil(FEventsListeners[Event]);
  end;

  FreeAndNil(FOperations);
end;

function TOperationsManager.AddOperation(Operation: TFileSourceOperation;
                                         StartingState: TOperationStartingState): TOperationHandle;
var
  Thread: TOperationThread;
  Entry: POperationsManagerEntry;
begin
  Result := InvalidOperationHandle;

  if Assigned(Operation) then
  begin
    Entry := New(POperationsManagerEntry);
    if Assigned(Entry) then
    try
      Thread := TOperationThread.Create(True, Operation);

      if Assigned(Thread) then
      begin
        if Assigned(Thread.FatalException) then
          raise Thread.FatalException;

        Entry^.Operation := Operation;
        Entry^.Thread := Thread;
        Entry^.Handle := GetNextUnusedHandle;
        Entry^.StartingState := StartingState;
        Entry^.Form := True;
        Entry^.PauseRunning := False;

        if StartingState = ossQueueFirst then
          FOperations.Insert(0, Entry)  // Insert at the top of the queue.
        else
          FOperations.Add(Entry);       // Add at the back of the queue.

        AddOperationListeners(Operation);

        Result := Entry^.Handle;

        // Set OnTerminate event so that we can cleanup when thread finishes.
        // Or instead of this create a timer for each thread and do:
        //  Thread.WaitFor  (or WaitForThreadTerminate(Thread.ThreadID))
        Thread.OnTerminate := @ThreadTerminatedEvent;

        NotifyEvents(Operation, [omevOperationAdded]);

        case StartingState of
          ossAutoStart:
            begin
              StartOperation(Entry);
            end;

          ossQueueFirst, ossQueueLast, ossQueueIn:
            begin
              if not AreOperationsRunning then
                StartOperation(Entry)
              else
              begin
                // It will be started later when currently running operations finish.
                Operation.PreventStart;
              end;
            end;

          else
            // It will be started by some user trigger.
            Operation.PreventStart;
        end;

        Thread.Resume;
      end
      else
        Dispose(Entry);

    except
      Dispose(Entry);
    end;
  end;
end;

function TOperationsManager.GetOperationsCount: Integer;
begin
  Result := FOperations.Count;
end;

function TOperationsManager.GetEntryByHandle(Handle: TOperationHandle): POperationsManagerEntry;
var
  Entry: POperationsManagerEntry = nil;
  i: Integer;
begin
  Result := nil;

  if (Handle <> InvalidOperationHandle) then
  begin
    // Search for operation identified by given handle.
    for i := 0 to FOperations.Count - 1 do
    begin
      Entry := POperationsManagerEntry(FOperations.Items[i]);
      if Entry^.Handle = Handle then
      begin
        Result := Entry;
        break;
      end;
    end;
  end;
end;

function TOperationsManager.GetEntryByOperation(Operation: TFileSourceOperation): POperationsManagerEntry;
var
  Entry: POperationsManagerEntry;
  i: Integer;
begin
  Result := nil;

  for i := 0 to FOperations.Count - 1 do
  begin
    Entry := POperationsManagerEntry(FOperations.Items[i]);
    if Entry^.Operation = Operation then
    begin
      Result := Entry;
      Exit;
    end
  end;
end;

function TOperationsManager.GetOperationByIndex(Index: Integer): TFileSourceOperation;
var
  Entry: POperationsManagerEntry = nil;
begin
  if (Index >= 0) and (Index < FOperations.Count) then
  begin
    Entry := POperationsManagerEntry(FOperations.Items[Index]);
    if Assigned(Entry^.Operation) then
      Result := Entry^.Operation;
  end
  else
    Result := nil;
end;

function TOperationsManager.GetOperationByHandle(Handle: TOperationHandle): TFileSourceOperation;
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Result := Entry^.Operation
  else
    Result := nil;
end;

function TOperationsManager.GetHandleById(Index: Integer): TOperationHandle;
var
  Entry: POperationsManagerEntry = nil;
begin
  if (Index >= 0) and (Index < FOperations.Count) then
  begin
    Entry := POperationsManagerEntry(FOperations.Items[Index]);
    Result := Entry^.Handle;
  end
  else
    Result := InvalidOperationHandle;
end;

function TOperationsManager.GetStartingState(Handle: TOperationHandle): TOperationStartingState;
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Result := Entry^.StartingState
  else
    Result := ossInvalid;
end;

function TOperationsManager.GetFormCreate (Handle: TOperationHandle): boolean;
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Result := Entry^.Form;
end;

function TOperationsManager.GetPauseRunning (Handle: TOperationHandle): boolean;
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Result := Entry^.PauseRunning;
end;

procedure TOperationsManager.SetPauseRunning (Handle: TOperationHandle; setForm: boolean);
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Entry^.PauseRunning := setForm;
end;

procedure TOperationsManager.SetFormCreate (Handle: TOperationHandle; setForm: boolean);
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Entry^.Form := setForm;
end;

procedure  TOperationsManager.SetToQueue (Handle: TOperationHandle);
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByHandle(Handle);
  if Assigned(Entry) then
    Entry^.StartingState := ossQueueIn;
end;



function TOperationsManager.GetNextUnusedHandle: TOperationHandle;
begin
  // Handles are consecutively incremented.
  // Even if they overflow there is little probability that
  // there will be that many operations.
  Result := InterLockedIncrement(FLastUsedHandle);
  if Result = InvalidOperationHandle then
    Result := InterLockedIncrement(FLastUsedHandle);
end;

procedure TOperationsManager.ThreadTerminatedEvent(Sender: TObject);
var
  Thread: TOperationThread;
  Entry: POperationsManagerEntry = nil;
  Index: Integer = -1;
begin
  // This function is executed from the GUI thread (through Synchronize).

  Thread := Sender as TOperationThread;

  // Search the terminated thread in the operations list.
  for Index := 0 to FOperations.Count - 1 do
  begin
    Entry := POperationsManagerEntry(FOperations.Items[Index]);
    if Entry^.Thread = Thread then
    begin
      break;
    end;
  end;

  if Assigned(Entry) then
  begin
    NotifyEvents(Entry^.Operation, [omevOperationFinished]);

    FOperations.Delete(Index);

    NotifyEvents(Entry^.Operation, [omevOperationRemoved]);

    Entry^.Thread := nil;  // Thread frees himself automatically on terminate.

    // Here the operation should not be used anymore
    // (by the thread and by any operations viewer).
    FreeAndNil(Entry^.Operation);

    Dispose(Entry);
  end;

  CheckQueuedOperations;
end;

procedure TOperationsManager.CheckQueuedOperations;
var
  i: Integer;
  Entry: POperationsManagerEntry = nil;
begin
  // Should a queued operation start when there are paused operations?
  // How about operations that are waiting for input from user?

  if not AreOperationsRunning then
  begin
    for i := 0 to FOperations.Count - 1 do
    begin
      Entry := POperationsManagerEntry(FOperations.Items[i]);

      if (Entry^.StartingState in [ossQueueFirst, ossQueueLast, ossQueueIn]) then

      //  and  (Entry^.Operation.State = fsosNotStarted)
      begin
        StartOperation(Entry);
        Exit;
      end;
    end;
  end;
end;

function TOperationsManager.AreOperationsRunning: Boolean;
var
  Entry: POperationsManagerEntry = nil;
  Index: Integer = -1;
begin
  // Search for a running operation.
  for Index := 0 to FOperations.Count - 1 do
  begin
    Entry := POperationsManagerEntry(FOperations.Items[Index]);
           // (Entry^.Operation.State in [fsosNotStarted, fsosStopped])
    if  Entry^.Operation.State = fsosRunning then
      Exit(True);  // There is an operation running.
  end;
  Result := False;
end;

procedure TOperationsManager.StartOperation(Entry: POperationsManagerEntry);
begin
  Entry^.StartingState := ossManualStart; // Reset state.
  Entry^.Operation.Start;

  NotifyEvents(Entry^.Operation, [omevOperationStarted]);
end;

procedure TOperationsManager.MoveOperation(FromIndex: Integer; ToIndex: Integer);
var
  Entry: POperationsManagerEntry = nil;
begin
  if (FromIndex >= 0) and (FromIndex < FOperations.Count) and
     (ToIndex >= 0) and (ToIndex < FOperations.Count) then
  begin
    Entry := POperationsManagerEntry(FOperations.Items[FromIndex]);

    // This has to be in exactly this order: first delete then insert.
    FOperations.Delete(FromIndex);
    FOperations.Insert(ToIndex, Entry);
  end;
end;

procedure TOperationsManager.CancelAll;
var
  Operation: TFileSourceOperation;
  i: Integer;
begin
  // Cancell all operations
  for i := 0 to OperationsCount - 1 do
  begin
    Operation := OperationsManager.GetOperationByIndex(i);
    if Assigned(Operation) then
    begin
      Operation.Stop;
    end;
  end;
end;

procedure TOperationsManager.StartAll;
var
  Operation: TFileSourceOperation;
  i: Integer;
begin
  // Start all operations
  for i := 0 to OperationsCount - 1 do
  begin
    Operation := OperationsManager.GetOperationByIndex(i);
    if Assigned(Operation) then
    begin
      Operation.Start;
    end;
  end;
end;

procedure TOperationsManager.PauseAll;
var
  Operation: TFileSourceOperation;
  i: Integer;
begin
  // Pause all operations
  for i := 0 to OperationsCount do
  begin
    Operation := OperationsManager.GetOperationByIndex(i);
    if Assigned(Operation) then
    begin
      Operation.Pause;
    end;
  end;
end;

procedure TOperationsManager.PauseRunning;
var
  Operation: TFileSourceOperation;
  i: Integer;
       //true - operation was runnig
begin
  for i := 0 to OperationsCount - 1 do
  begin
    Operation := OperationsManager.GetOperationByIndex(i);
    if Assigned(Operation) then
      begin
        if Operation.State = fsosRunning then
          begin
            SetPauseRunning(OperationsManager.GetHandleById(i), True); //���������� ������ ������� �������������
            Operation.Pause;
          end;
      end;
  end;
end;

procedure TOperationsManager.StartRunning;
var
  Operation: TFileSourceOperation;
  I: Integer;
  StartOp: Boolean = False;
begin
  for I := 0 to OperationsCount - 1 do
  begin
    Operation := GetOperationByIndex(I);
    if Assigned(Operation) then
      begin
        if GetPauseRunning (OperationsManager.GetHandleById(I)) = True  then //���������� ������������� ������ � ���������
          begin
            Operation.Start;
            StartOp:= True; //�������, ��� ���� ���������� ��������
          end;
      end;
  end;
  if not StartOp then OperationsManager.GetOperationByIndex(0).Start;  //���� ��� �� ����� ����������, �� ��������� ������
end;

function TOperationsManager.AllProgressPoint: Integer;
var
  Operation: TFileSourceOperation;
  i, n, AllProgressCur: Integer;
begin
  n:= 0;
  for i := 0 to OperationsCount - 1 do
  begin
    Operation := OperationsManager.GetOperationByIndex(i);
    if Assigned(Operation) then
      n:= n + Operation.Progress  // calculate allProgressBar
    else
      AllProgressCur:= 0 ;   // ���� ������� �������� ���, �� ��������� ���� ���
  end;

  if OperationsManager.OperationsCount<>0 then
    AllProgressCur:= Round(n / OperationsManager.OperationsCount);  // ���������� ������� ��������

  Result := AllProgressCur;
end;

function TOperationsManager.OperationExists(Operation: TFileSourceOperation): Boolean;
var
  Entry: POperationsManagerEntry = nil;
begin
  Entry := GetEntryByOperation(Operation);
  Result := Assigned(Entry);
end;

procedure TOperationsManager.AddOperationListeners(Operation: TFileSourceOperation);
begin
  Operation.AddStateChangedListener([fsosStarting], @OperationStateChangedEvent);
end;

procedure TOperationsManager.RemoveOperationListeners(Operation: TFileSourceOperation);
begin
  Operation.RemoveStateChangedListener(fsosAllStates, @OperationStateChangedEvent);
end;

procedure TOperationsManager.OperationStateChangedEvent(Operation: TFileSourceOperation;
                                                        State: TFileSourceOperationState);
var
  Entry: POperationsManagerEntry;
begin
  Entry := GetEntryByOperation(Operation);
  if Assigned(Entry) then
  begin
    if State = fsosStarting then
    begin
      // Remove 'queue' flag, because the operation was manually started by the user.
      Entry^.StartingState := ossManualStart;
      // Listener is not needed anymore.
      Operation.RemoveStateChangedListener(fsosAllStates, @OperationStateChangedEvent);
    end;
  end;
end;

procedure TOperationsManager.AddEventsListener(Events: TOperationManagerEvents;
                                               FunctionToCall: TOperationManagerEventNotify);
var
  Entry: PEventsListEntry;
  Event: TOperationManagerEvent;
begin
  for Event := Low(TOperationManagerEvent) to High(TOperationManagerEvent) do
  begin
    if Event in Events then
    begin
      Entry := New(PEventsListEntry);
      Entry^.EventFunction := FunctionToCall;
      FEventsListeners[Event].Add(Entry);
    end;
  end;
end;

procedure TOperationsManager.RemoveEventsListener(Events: TOperationManagerEvents;
                                                  FunctionToCall: TOperationManagerEventNotify);
var
  Entry: PEventsListEntry;
  Event: TOperationManagerEvent;
  i: Integer;
begin
  for Event := Low(TOperationManagerEvent) to High(TOperationManagerEvent) do
  begin
    if Event in Events then
    begin
      for i := 0 to FEventsListeners[Event].Count - 1 do
      begin
        Entry := PEventsListEntry(FEventsListeners[Event].Items[i]);
        if Entry^.EventFunction = FunctionToCall then
        begin
          FEventsListeners[Event].Delete(i);
          Dispose(Entry);
          break;  // break from one for only
        end;
      end;
    end;
  end;
end;

procedure TOperationsManager.NotifyEvents(Operation: TFileSourceOperation;
                                          Events: TOperationManagerEvents);
var
  Entry: PEventsListEntry;
  Event: TOperationManagerEvent;
  i: Integer;
begin
  for Event := Low(TOperationManagerEvent) to High(TOperationManagerEvent) do
  begin
    if Event in Events then
    begin
      // Call each listener function.
      for i := 0 to FEventsListeners[Event].Count - 1 do
      begin
        Entry := PEventsListEntry(FEventsListeners[Event].Items[i]);
        Entry^.EventFunction(Operation, Event);
      end;
    end;
  end;
end;

initialization

  OperationsManager := TOperationsManager.Create;

finalization

  FreeAndNil(OperationsManager);

end.

