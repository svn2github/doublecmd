{ $threading on}
program doublecmd;
// uGlobs must be first in uses, uLng must be before any form;
{%File 'doc/changelog.txt'}

{.$APPTYPE GUI}
uses
  {$IFDEF UNIX}
  cthreads,
  //cwstring,
  {$ENDIF}
  Interfaces,
  LCLProc,
  uGlobsPaths,
  uGlobs,
  uLng,
  SysUtils,
  Forms,
  fHackForm,
  fMain,
  fAbout,
  uFileList,
  uFilePanel,
  uFileOp,
  uTypes,
  framePanel,
  uFileOpThread,
  uFileProcs,
  fFileOpDlg,
  uCopyThread,
  uDeleteThread,
  fMkDir,
  uCompareFiles,
  uHighlighterProcs,
  fEditor,
  uMoveThread,
  fMsg,
  uSpaceThread,
  fHotDir,
  fHardLink,
  fFindView,
  uPathHistory,
  uExts,
  uLog,
  uShowForm,
  fEditSearch,
  uColorExt,
  fEditorConf,
  uFindMmap,
  {$IFDEF UNIX}
  fFileProperties,
  uUsersGroups,
  {$ENDIF}
  fLinker,
  fCompareFiles,
  dmHigh, dmHelpManager,
  uPixMapManager, uVFS, fFileAssoc,
  KASComp, fconfigtoolbar, uWCXprototypes, uDCUtils, uOSUtils,
  dmDialogs, fViewer, fOptions, fCopyDlg, fMoveDlg, fFindDlg,
  fSymLink, fMultiRename, fSplitter, fPackDlg, fExtractDlg, uDescr, fDescrEdit,
  LResources;
  
const
  dcBuildDate = {$I %DATE%};
  dcVersion = '0.4 alpha';
  fpcVersion = {$I %FPCVERSION%};

{$IFDEF WINDOWS}{$R doublecmd.rc}{$ENDIF}

begin
  {$I doublecmd.lrs}
  Application.Title:='Double Commander';
  Application.Initialize;
  ThousandSeparator:=' ';
  DebugLn(Format('Double commander %s - Free Pascal', [dcVersion]));
  DebugLn('Build: ' + dcBuildDate);
  DebugLn('This program is free software released under terms of GNU GPL 2');
  DebugLn('(C)opyright 2006-2008 Koblov Alexander (Alexx2000@mail.ru)');
  DebugLn('  and contributors (see about dialog)');

  fAbout.dcBuildDate := dcBuildDate;
  fAbout.dcVersion:= dcVersion;
  fAbout.fpcVersion:= fpcVersion;

  LoadPaths; // must be first
  if LoadGlobs then
     begin
       LoadPixMapManager;
       Application.CreateForm(TfrmHackForm, frmHackForm);
       Application.CreateForm(TfrmMain, frmMain); // main form
       Application.CreateForm(TdmHighl, dmHighl); // highlighters
       Application.CreateForm(TdmDlg, dmDlg); // dialogs
       Application.CreateForm(TdmHelpManager, dmHelpMgr); // help manager
       Application.Run;
     end;
end.
