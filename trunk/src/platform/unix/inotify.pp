unit inotify;

{$mode delphi}
{$packrecords c}

interface

uses
  InitC, CTypes;

type
  {en Structure describing an inotify event. }
  inotify_event = record
    wd:     cint32;      //en< Watch descriptor.
    mask:   cuint32;     //en< Watch mask.
    cookie: cuint32;     //en< Cookie to synchronize two events.
    len:    cuint32;     //en< Length (including NULs) of name.
    name:   record end;  //en< Stub for possible name (doesn't add to event size).
  end;
  {en Pointer to structure describing an inotify event. }
  pinotify_event = ^inotify_event;

const
  { Supported events suitable for MASK parameter of INOTIFY_ADD_WATCH. }
  IN_ACCESS    = $00000001;     {en< File was accessed. }
  IN_MODIFY    = $00000002;     {en< File was modified. }
  IN_ATTRIB    = $00000004;     {en< Metadata changed. }
  IN_CLOSE_WRITE = $00000008;   {en< Writtable file was closed. }
  IN_CLOSE_NOWRITE = $00000010; {en< Unwrittable file closed. }
  IN_CLOSE     = IN_CLOSE_WRITE or IN_CLOSE_NOWRITE;     {en< Close. }
  IN_OPEN      = $00000020;     {en< File was opened.   }
  IN_MOVED_FROM = $00000040;    {en< File was moved from X. }
  IN_MOVED_TO  = $00000080;     {en< File was moved to Y. }
  IN_MOVE      = IN_MOVED_FROM or IN_MOVED_TO;     {en< Moves. }
  IN_CREATE    = $00000100;     {en< Subfile was created. }
  IN_DELETE    = $00000200;     {en< Subfile was deleted. }
  IN_DELETE_SELF = $00000400;   {en< Self was deleted. }
  IN_MOVE_SELF = $00000800;     {en< Self was moved. }
  { Events sent by the kernel. }
  IN_UNMOUNT   = $00002000;     {en< Backing fs was unmounted. }
  IN_Q_OVERFLOW = $00004000;    {en< Event queued overflowed. }
  IN_IGNORED   = $00008000;     {en< File was ignored. }
  { Special flags. }
  IN_ONLYDIR   = $01000000;     {en< Only watch the path if it is a directory. }
  IN_DONT_FOLLOW = $02000000;   {en< Do not follow a sym link. }
  IN_MASK_ADD  = $20000000;     {en< Add to the mask of an already existing watch. }
  IN_ISDIR     = $40000000;     {en< Event occurred against dir. }
  IN_ONESHOT   = $80000000;     {en< Only send event once. }
  {en All events which a program can wait on. }
  IN_ALL_EVENTS =
    ((((((((((IN_ACCESS or IN_MODIFY) or IN_ATTRIB) or IN_CLOSE_WRITE) or
    IN_CLOSE_NOWRITE) or IN_OPEN) or IN_MOVED_FROM) or IN_MOVED_TO) or IN_CREATE) or
    IN_DELETE) or IN_DELETE_SELF) or IN_MOVE_SELF;

{en
   Create and initialize inotify instance.
 }
function fpinotify_init: cint;
{en
   Add watch of object NAME to inotify instance FD. Notify about events specified by MASK.
}
function fpinotify_add_watch(fd: cint; pathname: string; mask: cuint32): cint;
{en
   Remove the watch specified by WD from the inotify instance FD.
}
function fpinotify_rm_watch(fd: cint; wd: cuint32): cint;

implementation

uses
  BaseUnix, DCConvertEncoding;

function inotify_init: cint; cdecl; external clib;
function inotify_rm_watch(__fd: cint; __wd: cuint32): cint; cdecl; external clib;
function inotify_add_watch(__fd: cint; __name: pansichar; __mask: cuint32): cint; cdecl; external clib;

function fpinotify_init: cint;
begin
  Result:= inotify_init;
  if Result = -1 then fpseterrno(fpgetCerrno);
end;

function fpinotify_add_watch(fd: cint; pathname: string; mask: cuint32): cint;
begin
  Result:= inotify_add_watch(fd, PAnsiChar(CeUtf8ToSys(pathname)), mask);
  if Result = -1 then fpseterrno(fpgetCerrno);
end;

function fpinotify_rm_watch(fd: cint; wd: cuint32): cint;
begin
  Result:= inotify_rm_watch(fd, wd);
  if Result = -1 then fpseterrno(fpgetCerrno);
end;

end.

