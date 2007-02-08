//***************************************************************
// This file is part of RPMWCX, a archiver plugin for
// Windows Commander.
// Copyright (C) 2000 Mandryka Yurij  e-mail:braingroup@hotmail.ru
//***************************************************************

//***************************************************************
// This code based on Christian Ghisler (support@ghisler.com) sources
//***************************************************************

library cpio;

uses
  SysUtils,
  Classes,
  wcx in 'wcx.pas',
  cpio_io in 'cpio_io.pas',
  cpio_def in 'cpio_def.pas',
  cpio_archive in 'cpio_archive.pas';

{$E wcx}

{$R *.RES}

exports
  CloseArchive       name 'CloseArchive',
  GetPackerCaps      name 'GetPackerCaps',
  OpenArchive        name 'OpenArchive',
  ProcessFile        name 'ProcessFile',
  ReadHeader         name 'ReadHeader',
  SetChangeVolProc   name 'SetChangeVolProc',
  SetProcessDataProc name 'SetProcessDataProc';
  
begin
end.
