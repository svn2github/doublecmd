{ $threading on}
program doublecmd;
{%File 'doc/changelog.txt'}

{.$APPTYPE GUI}
uses
  {$IFDEF DARWIN}
  uAppleMagnifiedModeFix,
  {$ENDIF}
  {$IFDEF WIN64}
  uExceptionHandlerFix,
  {$ENDIF}
  {$IFDEF UNIX}
  cthreads,
  //cwstring,
  clocale,
  {$IFDEF LCLGTK2}
  uOverlayScrollBarFix,
  gtk2,
  Gtk2Int,
  {$ENDIF}
  {$ENDIF}
  Interfaces,
  LCLProc,
  SysUtils,
  Forms,
  LCLVersion,
  {$IF DEFINED(NIGHTLY_BUILD)}
  un_lineinfo,
  {$ENDIF}
  uGlobsPaths,
  uGlobs,
  fHackForm,
  fMain,
  fMkDir,
  dmHigh, dmHelpManager, dmCommonData,
  uShowMsg,
  uCryptProc,
  uPixMapManager,
  uKeyboard,
  uUniqueInstance,
  uDCVersion,
  uCmdLineParams,
  uDebug,
  uOSUtils,
  uspecialdir,
  fstartingsplash,
  ulog
  {$IFDEF MSWINDOWS}
  , uMyWindows
  {$ENDIF}
  {$IFDEF UNIX}
  , uMyUnix
  {$ENDIF}
  ;

{$R *.res}

{$IFDEF HEAPTRC}
var
  LogPath: String;
{$ENDIF}

begin
  DCDebug('Starting Double Commander');

  // Initialize random number generator
  Randomize;

  {$IF DEFINED(NIGHTLY_BUILD)}
  InitLineInfo;
  AddLineInfoPath(ExtractFileDir(ParamStr(0)));
  {$ENDIF}

  {$IFDEF HEAPTRC}
  LogPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'logs';
  CreateDir(LogPath);
  SetHeapTraceOutput(LogPath + '/heaptrc-' + FormatDateTime('yyyy-mm-dd hh.mm.ss', Now) + '.log');
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  uMyWindows.InitErrorMode;
  FileNameCaseSensitive:= False;
  uMyWindows.FixCommandLineToUTF8;
  {$ENDIF}

  Application.Title:= 'Double Commander';
  Application.Initialize;
  uDCVersion.InitializeVersionInfo;
  // Initializing keyboard module on GTK needs GTKProc.InitKeyboardTables
  // which is called by Application.Initialize.
  uKeyboard.InitializeKeyboard;

  // Use only current directory separator
  AllowDirectorySeparators:= [DirectorySeparator];
  {$IF lcl_fullversion >= 093100}
  // Disable because we set a few of our own format settings and we don't want
  // them to be changed. There's no way currently to react to Application.IntfSettingsChange.
  // If in future we move to a Unicode RTL this could be removed.
  {$PUSH}{$WARN SYMBOL_PLATFORM OFF}
  Application.UpdateFormatSettings := False;
  {$POP}
  {$ENDIF}
  DefaultFormatSettings.ThousandSeparator:= ' ';
  {$IFDEF UNIX}
  uMyUnix.FixDateTimeSeparators;
  {$ENDIF}
  FixDateNamesToUTF8;

  DCDebug('Double Commander ' + dcVersion);
  DCDebug('Revision: ' + dcRevision);
  DCDebug('Build: ' + dcBuildDate);
  DCDebug('Lazarus: ' + lazVersion);
  DCDebug('Free Pascal: ' + fpcVersion);
  DCDebug('Platform: ' + TargetCPU + '-' + TargetOS + '-' + TargetWS);
  DCDebug('System: ' + OSVersion);
  {$IF DEFINED(UNIX) AND NOT DEFINED(DARWIN)}
  DCDebug('Desktop Environment: ' + DesktopName[DesktopEnv]);
  {$ENDIF}
  if WSVersion <> EmptyStr then
    DCDebug('Widgetset library: ' + WSVersion);
  DCDebug('This program is free software released under terms of GNU GPL 2');
  DCDebug('(C)opyright 2006-2015 Alexander Koblov (alexx2000@mail.ru)');
  DCDebug('   and contributors (see about dialog)');

  Application.ShowMainForm:= False;
  Application.CreateForm(TfrmHackForm, frmHackForm);

  //Let's show the starting slash screen to confirm user application has been started
  Application.CreateForm(TfrmStartingSplash, frmStartingSplash);
  frmStartingSplash.Show;

  ProcessCommandLineParams; // before load paths
  LoadPaths; // before loading config
  LoadWindowsSpecialDir; // Load the list with special path. *Must* be located AFTER "LoadPaths" and BEFORE "InitGlobs"

  if InitGlobs then
    //-- NOTE: before, only IsInstanceAllowed was called, and all the magic on creation
    //         new instance or sending params to the existing server happened inside 
    //         IsInstanceAllowed() function as a side effect.
    //         Functions with side effects are generally bad, so,
    //         new function was added to explicitly initialize instance.
    InitInstance;
    if IsInstanceAllowed then
    begin
      if (log_start_shutdown in gLogOptions) then logWrite('Program start ('+GetCurrentUserName+'/'+GetComputerNetName+')');

      InitPasswordStore;
      LoadPixMapManager;
      Application.CreateForm(TfrmMain, frmMain); // main form
      Application.CreateForm(TdmHighl, dmHighl); // highlighters
      Application.CreateForm(TdmComData, dmComData); // common data
      Application.CreateForm(TdmHelpManager, dmHelpMgr); // help manager
      Application.CreateForm(TfrmMkDir, frmMkDir);  // 21.05.2009 - makedir form

      {$IF DEFINED(LCLGTK2) AND (lcl_fullversion >= 093100)}
      // LCLGTK2 uses Application.MainForm as the clipboard widget, however our
      // MainForm is TfrmHackForm and it never gets realized. GTK2 doesn't
      // seem to allow a not realized widget to have clipboard ownership.
      // We switch to frmMain instead which will be realized at some point.
      GTK2WidgetSet.SetClipboardWidget(PGtkWidget(frmMain.Handle));
      {$ENDIF}

      // Hooking on QT needs the handle of the main form which is created
      // in Application.CreateForm above.
      uKeyboard.HookKeyboardLayoutChanged;

      //We may now remove the starting splash screen, mot of the application has been started now
      frmStartingSplash.Close;
      frmStartingSplash.Release;

      Application.Run;

      if not UniqueInstance.isAnotherDCRunningWhileIamRunning then
        DeleteTempFolderDeletableAtTheEnd;

      if (log_start_shutdown in gLogOptions) then logWrite('Program shutdown ('+GetCurrentUserName+'/'+GetComputerNetName+')');
    end
    else
    begin
      DCDebug('Another instance of DC is already running. Exiting.');
    end;

  uKeyboard.CleanupKeyboard;
  DCDebug('Finished Double Commander');
end.
