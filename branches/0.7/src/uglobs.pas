{
   Double Commander
   ------------------------------------------------------------
   Seksi Commander
   ----------------------------
   Licence  : GNU GPL v 2.0
   Author   : radek.cervinka@centrum.cz

   Globals variables and some consts

   contributors:

   Copyright (C) 2008  Dmitry Kolomiets (B4rr4cuda@rambler.ru)
   Copyright (C) 2008  Vitaly Zotov (vitalyzotov@mail.ru)
   Copyright (C) 2006-2016 Alexander Koblov (alexx2000@mail.ru)

}

unit uGlobs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Grids, Types, uExts, uColorExt, Graphics,
  DCClassesUtf8, uMultiArc, uColumns, uHotkeyManager, uSearchTemplate,
  uFileSourceOperationOptions, uWFXModule, uWCXModule, uWDXModule, uwlxmodule,
  udsxmodule, DCXmlConfig, uInfoToolTip, fQuickSearch, uTypes, uClassesEx,
  uHotDir, uSpecialDir, uVariableMenuSupport, SynEdit, uFavoriteTabs;

type
  { Configuration options }
  TSortConfigurationOptions = (scoClassicLegacy, scoAlphabeticalButLanguage);

  { Log options }
  TLogOptions = set of (log_cp_mv_ln, log_delete, log_dir_op, log_arc_op,
                        log_vfs_op, log_success, log_errors, log_info,
                        log_start_shutdown, log_commandlineexecution);
  { Watch dirs options }
  TWatchOptions = set of (watch_file_name_change, watch_attributes_change,
                          watch_only_foreground, watch_exclude_dirs);
  { Tabs options }
  TTabsOptions = set of (tb_always_visible, tb_multiple_lines, tb_same_width,
                         tb_text_length_limit, tb_confirm_close_all,
                         tb_close_on_dbl_click, tb_open_new_in_foreground,
                         tb_open_new_near_current, tb_show_asterisk_for_locked,
                         tb_activate_panel_on_click, tb_show_close_button,
                         tb_close_duplicate_when_closing,
                         tb_close_on_doubleclick, tb_show_drive_letter,
                         tb_reusing_tab_when_possible,
                         tb_confirm_close_locked_tab,
                         tb_keep_renamed_when_back_normal);

  TTabsOptionsDoubleClick = (tadc_Nothing, tadc_CloseTab, tadc_FavoriteTabs, tadc_TabsPopup);

  TTabsPosition = (tbpos_top, tbpos_bottom);
  { Show icons mode }
  TShowIconsMode = (sim_none, sim_standart, sim_all, sim_all_and_exe);
  TScrollMode = (smLineByLineCursor, smLineByLine, smPageByPage);
  { Sorting directories mode }
  TSortFolderMode = (sfmSortNameShowFirst, sfmSortLikeFileShowFirst, sfmSortLikeFile);
  { Where to insert new files in the filelist }
  TNewFilesPosition = (nfpTop, nfpTopAfterDirectories, nfpSortedPosition, nfpBottom);
  { Where to move updated files in the filelist }
  TUpdatedFilesPosition = (ufpSameAsNewFiles, ufpSortedPosition, ufpNoChange);
  { How initially progress is shown for file operations }
  TFileOperationsProgressKind = (fopkSeparateWindow, fopkSeparateWindowMinimized, fopkOperationsPanel);
  { Operations with confirmation }
  TFileOperationsConfirmation = (focCopy, focMove, focDelete, focDeleteToTrash);
  TFileOperationsConfirmations = set of TFileOperationsConfirmation;
  { Internal Associations}
  //What the use wish for the context menu
  // uwcmComplete : DEFAULT, or user specifically wish the "Windows' one + the actions".
  // uwcmJustDCAction : User specifically wish only the actions, even if default set is not it.
  TUserWishForContextMenu = (uwcmComplete, uwcmJustDCAction);

  TExternalTool = (etViewer, etEditor, etDiffer);
  TExternalToolOptions = record
    Enabled: Boolean;
    Path: String;
    Parameters: String;
    RunInTerminal: Boolean;
    KeepTerminalOpen: Boolean;
  end;
  TExternalToolsOptions = array[TExternalTool] of TExternalToolOptions;
  TResultingFramePositionAfterCompare = (rfpacActiveOnLeft, rfpacLeftOnLeft);

  TDCFont = (dcfMain, dcfViewer, dcfEditor, dcfLog, dcfViewerBook, dcfConsole, dcfFileSearchResults, dcFileViewHeader);
  TDCFontOptions = record
    Name: String;
    Size: Integer;
    Style: TFontStyles;
    Quality: TFontQuality;
  end;
  TDCFontsOptions = array[TDCFont] of TDCFontOptions;

  // fswmPreventDelete - prevents deleting watched directories
  // fswmAllowDelete   - does not prevent deleting watched directories
  // fswmWholeDrive    - watch whole drives instead of single directories to omit problems with deleting watched directories
  TWatcherMode = (fswmPreventDelete, fswmAllowDelete, fswmWholeDrive);

  TDrivesListButtonOption = (dlbShowLabel, dlbShowFileSystem, dlbShowFreeSpace);
  TDrivesListButtonOptions = set of TDrivesListButtonOption;

  TKeyTypingModifier = (ktmNone, ktmAlt, ktmCtrlAlt);
  TKeyTypingAction = (ktaNone, ktaCommandLine, ktaQuickSearch, ktaQuickFilter);

  tDesiredDropTextFormat=record
    Name:string;
    DesireLevel:longint;
  end;

  tDuplicatedRename = (drLegacyWithCopy, drLikeWindows7, drLikeTC);

  TBriefViewMode = (bvmFixedWidth, bvmFixedCount, bvmAutoSize);

const
  { Default hotkey list version number }
  hkVersion     = 38;  // 26

  // Previously existing names if reused must check for ConfigVersion >= X.
  // History:
  // 2   - removed Layout/SmallIcons
  //       renamed Layout/SmallIconSize to Layout/IconSize
  // 3   - Layout/DriveMenuButton -> Layout/DrivesListButton and added subnodes:
  //         ShowLabel, ShowFileSystem, ShowFreeSpace
  // 4   - changed QuickSearch/Enabled, QuickSearch/Mode and same for QuickFilter
  //       to Keyboard/Typing.
  // 5   - changed Behaviours/SortCaseSensitive to FilesViews/Sorting/CaseSensitivity
  //       changed Behaviours/SortNatural to FilesViews/Sorting/NaturalSorting
  // 6   - changed Behaviours/ShortFileSizeFormat to Behaviours/FileSizeFormat
  // 7   - changed Viewer/SaveThumbnails to Thumbnails/Save
  // 8   - changed Behaviours/BriefViewFileExtAligned to FilesViews/BriefView/FileExtAligned
  // 9   - few new options regarding tabs
  ConfigVersion = 9;

  TKeyTypingModifierToShift: array[TKeyTypingModifier] of TShiftState =
    ([], [ssAlt], [ssCtrl, ssAlt]);

  { Related with the drop of text over panels}
  NbOfDropTextFormat = 4;
  DropTextRichText_Index=0;
  DropTextHtml_Index=1;
  DropTextUnicode_Index=2;
  DropTextSimpleText_Index=3;

  { Global font sizes limitations }

  MAX_FONT_SIZE_MAIN=50;
  MIN_FONT_SIZE_MAIN=6;

  MAX_FONT_SIZE_EDITOR=70;
  MIN_FONT_SIZE_EDITOR=6;

  MAX_FONT_SIZE_VIEWER=70;
  MIN_FONT_SIZE_VIEWER=6;

  MAX_FONT_SIZE_FILE_SEARCH_RESULTS=70;
  MIN_FONT_SIZE_FILE_SEARCH_RESULTS=6;

  MAX_FONT_SIZE_FILEVIEWHEADER=20;
  MIN_FONT_SIZE_FILEVIEWHEADER=8;



var
  { For localization }
  gPOFileName,
  gHelpLang: String;

  { DSX plugins }
  gDSXPlugins: TDSXModuleList;
  { WCX plugins }
  gWCXPlugins: TWCXModuleList;
  { WDX plugins }
  gWDXPlugins:TWDXModuleList;
  { WFX plugins }
  gWFXPlugins: TWFXModuleList;
  { WLX plugins }
  gWLXPlugins: TWLXModuleList;
  { MultiArc addons }
  gMultiArcList: TMultiArcList;

  { Columns Set }
  ColSet:TPanelColumnsList;
  
  { Layout page }
  gMainMenu,
  gButtonBar,
  gToolBarFlat,
  gDriveBar1,
  gDriveBar2,
  gDriveBarFlat,
  gDrivesListButton,
  gDirectoryTabs,
  gCurDir,
  gTabHeader,
  gStatusBar,
  gCmdLine,
  gLogWindow,
  gTermWindow,
  gKeyButtons,
  gInterfaceFlat,
  gDriveInd,
  gDriveFreeSpace,
  gProgInMenuBar,
  gPanelOfOp,
  gHorizontalFilePanels,
  gShortFormatDriveInfo: Boolean;
  gDrivesListButtonOptions: TDrivesListButtonOptions;
  gSeparateTree: Boolean;

  { Toolbar }
  gToolBarButtonSize,
  gToolBarIconSize: Integer;
  gToolbarReportErrorWithCommands: boolean;

  gRepeatPassword:Boolean;  // repeat password when packing files
  gDirHistoryCount:Integer; // how many history we remember
  gShowSystemFiles:Boolean;
  gRunInTermStayOpenCmd: String;
  gRunInTermStayOpenParams: String;
  gRunInTermCloseCmd: String;
  gRunInTermCloseParams: String;
  gRunTermCmd: String;
  gRunTermParams: String;
  gSortCaseSensitivity: TCaseSensitivity;
  gSortNatural: Boolean;
  gSortFolderMode: TSortFolderMode;
  gNewFilesPosition: TNewFilesPosition;
  gUpdatedFilesPosition: TUpdatedFilesPosition;
  gLynxLike:Boolean;
  gFirstTextSearch: Boolean;

  gMouseSelectionEnabled: Boolean;
  gMouseSelectionButton: Integer;

  gAutoFillColumns: Boolean;
  gAutoSizeColumn: Integer;
  gColumnsAutoSaveWidth: Boolean;
  gColumnsTitleStyle: TTitleStyle;
  gCustomColumnsChangeAllColumns: Boolean;
  

  gSupportForVariableHelperMenu:TSupportForVariableHelperMenu=nil;
  gSpecialDirList:TSpecialDirList=nil;
  gDirectoryHotlist:TDirectoryHotlist;
  gHotDirAddTargetOrNot: Boolean;
  gHotDirFullExpandOrNot: Boolean;
  gShowPathInPopup: boolean;
  gShowOnlyValidEnv: boolean = TRUE;
  gWhereToAddNewHotDir: TPositionWhereToAddHotDir;
  glsDirHistory:TStringListEx;
  glsCmdLineHistory: TStringListEx;
  glsMaskHistory : TStringListEx;
  glsSearchHistory : TStringListEx;
  glsSearchPathHistory : TStringListEx;
  glsReplaceHistory : TStringListEx;
  glsReplacePathHistory : TStringListEx;
  glsSearchExcludeFiles: TStringList;
  glsSearchExcludeDirectories: TStringList;
  glsIgnoreList : TStringListEx;
  gOnlyOneAppInstance,
  gCutTextToColWidth : Boolean;
  gSpaceMovesDown: Boolean;
  gScrollMode: TScrollMode;
  gWheelScrollLines: Integer;
  gAlwaysShowTrayIcon: Boolean;
  gMinimizeToTray: Boolean;
  gFileSizeFormat: TFileSizeFormat;
  gDateTimeFormat : String;
  gDriveBlackList: String;
  gDriveBlackListUnmounted: Boolean; // Automatically black list unmounted devices
  gListFilesInThread: Boolean;
  gLoadIconsSeparately: Boolean;
  gDelayLoadingTabs: Boolean;
  gHighlightUpdatedFiles: Boolean;
  gLastUsedPacker: String;
  gLastDoAnyCommand: String;

  { Favorite Tabs }
  gFavoriteTabsUseRestoreExtraOptions: boolean;
  gFavoriteTabsList: TFavoriteTabsList;
  gWhereToAddNewFavoriteTabs: TPositionWhereToAddFavoriteTabs;
  gFavoriteTabsFullExpandOrNot: boolean;
  gFavoriteTabsGoToConfigAfterSave: boolean;
  gFavoriteTabsGoToConfigAfterReSave: boolean;
  gDefaultTargetPanelLeftSaved: TTabsConfigLocation;
  gDefaultTargetPanelRightSaved: TTabsConfigLocation;
  gDefaultExistingTabsToKeep: TTabsConfigLocation;
  gFavoriteTabsSaveDirHistory: boolean;

  { Brief view page }
  gBriefViewFixedWidth: Integer;
  gBriefViewFixedCount: Integer;
  gBriefViewMode: TBriefViewMode;
  gBriefViewFileExtAligned: Boolean;

  { Tools page }
  gExternalTools: TExternalToolsOptions;

  gResultingFramePositionAfterCompare:TResultingFramePositionAfterCompare;
  gLuaLib:String;
  gExts:TExts;
  gColorExt:TColorExt;
  gFileInfoToolTip: TFileInfoToolTip;

  { Fonts page }
  gFonts: TDCFontsOptions;

  { File panels color page }
  gUseCursorBorder: Boolean;
  gCursorBorderColor: TColor;
  gUseFrameCursor: Boolean;
  gForeColor,  //text color
  gBackColor, //Background color
  gBackColor2, //Background color 2
  gMarkColor,  // Mark color
  gCursorColor, //Cursor color
  gCursorText,  //text color under cursor
  gInactiveCursorColor, //Inactive cursor color
  gInactiveMarkColor: TColor; //Inactive Mark color
  gUseInvertedSelection: Boolean;
  gUseInactiveSelColor: Boolean;
  gAllowOverColor: Boolean;

  gInactivePanelBrightness: Integer; // 0 .. 100 (black .. full color)
  gIndUseGradient : Boolean; // use gradient on drive label
  gIndForeColor, // foreColor of use space on drive label
  gIndBackColor: TColor; // backColor of free space on drive label

  gShowIcons: TShowIconsMode;
  gShowIconsNew: TShowIconsMode;
  gIconOverlays : Boolean;
  gIconsSize,
  gIconsSizeNew : Integer;
  gFiOwnDCIcon : PtrInt;
  gIconsExclude: Boolean;
  gIconsExcludeDirs: String;
  gCustomDriveIcons : Boolean; // for use custom drive icons under windows
  gIconsInMenus: Boolean;
  gIconsInMenusSize,
  gIconsInMenusSizeNew: Integer;

  { Keys page }
  gKeyTyping: array[TKeyTypingModifier] of TKeyTypingAction;

  { File operations page }
  gCopyBlockSize : Integer;
  gHashBlockSize : Integer;
  gUseMmapInSearch : Boolean;
  gPartialNameSearch: Boolean;
  gSkipFileOpError: Boolean;
  gTypeOfDuplicatedRename: tDuplicatedRename;
  gDropReadOnlyFlag : Boolean;
  gWipePassNumber: Integer;
  gProcessComments: Boolean;
  gShowCopyTabSelectPanel:boolean;
  gUseTrash : Boolean; // if using delete to trash by default
  gRenameSelOnlyName:boolean;
  gShowDialogOnDragDrop: Boolean;
  gDragAndDropDesiredTextFormat:array[0..pred(NbOfDropTextFormat)] of tDesiredDropTextFormat;
  gDragAndDropAskFormatEachTime: Boolean;
  gDragAndDropTextAutoFilename: Boolean;
  gDragAndDropSaveUnicodeTextInUFT8: Boolean;
  gOverwriteFolder: Boolean;
  gNtfsHourTimeDelay: Boolean;
  gFileOperationsProgressKind: TFileOperationsProgressKind;
  gFileOperationsConfirmations: TFileOperationsConfirmations;

  { Folder tabs page }
  gDirTabOptions : TTabsOptions;
  gDirTabActionOnDoubleClick : TTabsOptionsDoubleClick;
  gDirTabLimit : Integer;
  gDirTabPosition : TTabsPosition;

  { Log page }
  gLogFile : Boolean;
  gLogFileWithDateInName : Boolean;
  gLogFileName : String;
  gLogOptions : TLogOptions;

  { Configuration page }
  gUseConfigInProgramDir,
  gUseConfigInProgramDirNew,
  gSaveConfiguration,
  gSaveSearchReplaceHistory,
  gSaveDirHistory,
  gSaveCmdLineHistory,
  gSaveFileMaskHistory : Boolean;
  gSortOrderOfConfigurationOptionsTree:TSortConfigurationOptions;
  
  { Quick Search page }
  gQuickSearchOptions: TQuickSearchOptions;
  gQuickFilterAutoHide: Boolean;
  gQuickFilterSaveSessionModifications: Boolean;

  { Misc page }
  gGridVertLine,
  gGridHorzLine,
  gShowWarningMessages,
  gDirBrackets,
  gInplaceRename,
  gGoToRoot: Boolean;
  gShowToolTipMode: Boolean;
  gThumbSize: TSize;
  gThumbSave: Boolean;
  gSearchDefaultTemplate: String;
  gSearchTemplateList: TSearchTemplateList;

  { Auto refresh page }
  gWatchDirs: TWatchOptions;
  gWatchDirsExclude: String;
  gWatcherMode: TWatcherMode;

  { Ignore list page }
  gIgnoreListFileEnabled: Boolean;
  gIgnoreListFile: String;

  {HotKey Manager}
  HotMan:THotKeyManager;
  gNameSCFile: string;
  
  {Copy/Move operation options}
  gOperationOptionSymLinks: TFileSourceOperationOptionSymLink;
  gOperationOptionCorrectLinks: Boolean;
  gOperationOptionFileExists: TFileSourceOperationOptionFileExists;
  gOperationOptionDirectoryExists: TFileSourceOperationOptionDirectoryExists;
  gOperationOptionSetPropertyError: TFileSourceOperationOptionSetPropertyError;
  gOperationOptionReserveSpace: Boolean;
  gOperationOptionCheckFreeSpace: Boolean;
  gOperationOptionCopyAttributes: Boolean;
  gOperationOptionCopyTime: Boolean;
  gOperationOptionCopyOwnership: Boolean;
  gOperationOptionCopyPermissions: Boolean;

  {Error file}
  gErrorFile: String;

  {Viewer}
  gPreviewVisible,
  gImageStretch: Boolean;
  gImageStretchOnlyLarge: Boolean;
  gImageCenter: Boolean;
  gCopyMovePath1,
  gCopyMovePath2,
  gCopyMovePath3,
  gCopyMovePath4,
  gCopyMovePath5,
  gImagePaintMode: String;
  gImagePaintWidth,
  gColCount,
  gViewerMode: Integer;
  gImagePaintColor,
  gBookBackgroundColor,
  gBookFontColor: TColor;
  gTextPosition:PtrInt;

  { Editor }
  gEditWaitTime: Integer;
  gEditorSynEditOptions: TSynEditorOptions;

  {SyncDirs}
  gSyncDirsSubdirs,
  gSyncDirsByContent,
  gSyncDirsIgnoreDate,
  gSyncDirsShowFilterCopyRight,
  gSyncDirsShowFilterEqual,
  gSyncDirsShowFilterNotEqual,
  gSyncDirsShowFilterCopyLeft,
  gSyncDirsShowFilterDuplicates,
  gSyncDirsShowFilterSingles: Boolean;
  gSyncDirsFileMask: string;

  { Internal Associations}
  gUseShellForFileOperations: Boolean;
  gFileAssociationLastCustomAction: string;
  gOfferToAddToFileAssociations: boolean;
  gExtendedContextMenu: boolean;
  gOpenExecuteViaShell: boolean;
  gExecuteViaTerminalClose: boolean;
  gExecuteViaTerminalStayOpen: boolean;
  gIncludeFileAssociation: boolean;

  crArrowCopy: Integer = 1;
  crArrowMove: Integer = 2;
  crArrowLink: Integer = 3;

  { TotalCommander Import/Export }
  {$IFDEF MSWINDOWS}
  gTotalCommanderExecutableFilename:string;
  gTotalCommanderConfigFilename:string;
  gTotalCommanderToolbarPath:string;
  {$ENDIF}

function LoadConfig: Boolean;
function InitGlobs: Boolean;
function LoadGlobs: Boolean;
procedure SaveGlobs;
procedure LoadIniConfig;
procedure LoadXmlConfig;
procedure SaveXmlConfig;
procedure ConvertIniToXml;

procedure LoadDefaultHotkeyBindings;

function InitPropStorage(Owner: TComponent): TIniPropStorageEx;

procedure FontToFontOptions(Font: TFont; out Options: TDCFontOptions);
procedure FontOptionsToFont(Options: TDCFontOptions; Font: TFont);


function GetKeyTypingAction(ShiftStateEx: TShiftState): TKeyTypingAction;
function IsFileSystemWatcher: Boolean;
function GetValidDateTimeFormat(const aFormat, ADefaultFormat: string): string;

procedure RegisterInitialization(InitProc: TProcedure);

const
  cMaxStringItems=50;
  
var
  gIni: TIniFileEx = nil;
  gConfig: TXmlConfig = nil;

implementation

uses
   LCLProc, Dialogs, XMLRead,
   uGlobsPaths, uLng, uShowMsg, uFileProcs, uOSUtils, uFindFiles,
   uDCUtils, fMultiRename, uFile, uDCVersion, uDebug, uFileFunctions,
   uDefaultPlugins, Lua, uKeyboard, DCOSUtils, DCStrUtils
   {$IF DEFINED(MSWINDOWS)}
    , ShlObj, win32proc
   {$ENDIF}
   ;

const
  TKeyTypingModifierToNodeName: array[TKeyTypingModifier] of String =
    ('NoModifier', 'Alt', 'CtrlAlt');

type
  TLoadConfigProc = function(var ErrorMessage: String): Boolean;

var
  DefaultDateTimeFormat: String;
  // Double Commander version
  // loaded from configuration file
  gPreviousVersion: String = '';
  FInitList: array of TProcedure;

function LoadConfigCheckErrors(LoadConfigProc: TLoadConfigProc;
                               ConfigFileName: String;
                               var ErrorMessage: String): Boolean;
  procedure AddMsg(Msg, eMsg: String);
  begin
    AddStrWithSep(ErrorMessage, Msg + ':', LineEnding + LineEnding);
    AddStrWithSep(ErrorMessage, ConfigFileName, LineEnding);
    if eMsg <> EmptyStr then
      AddStrWithSep(ErrorMessage, eMsg, LineEnding);
  end;
begin
  Result := False;
  try
    Result := LoadConfigProc(ErrorMessage);
  except
    // If the file does not exist or is empty,
    // simply default configuration is applied.
    on EXmlConfigNotFound do
      Result := True;
    on EXmlConfigEmpty do
      Result := True;
    on e: EFOpenError do
      AddMsg(rsMsgErrEOpen, e.Message);
    on e: EStreamError do
      AddMsg(rsMsgErrERead, e.Message);
    on e: EXMLReadError do
      AddMsg(rsMsgInvalidFormatOfConfigurationFile, e.Message);
  end;
end;

type
  TSaveCfgProc = procedure;

procedure SaveWithCheck(SaveProc: TSaveCfgProc; CfgDescription: String; var ErrMsg: String);
begin
  try
    SaveProc;
  except
    on E: EStreamError do
      ErrMsg := ErrMsg + 'Cannot save ' + CfgDescription + ': ' + e.Message;
  end;
end;

procedure SaveCfgIgnoreList;
var
  FileName: String;
begin
  if gIgnoreListFileEnabled then
  begin
    FileName:= ReplaceEnvVars(gIgnoreListFile);
    mbForceDirectory(ExtractFileDir(FileName));
    glsIgnoreList.SaveToFile(FileName);
  end;
end;

procedure SaveCfgMainConfig;
begin
  SaveXmlConfig;

  // Force saving config to file.
  gConfig.Save;
end;

function AskUserOnError(var ErrorMessage: String): Boolean;
begin
  // Show error messages.
  if ErrorMessage <> EmptyStr then
  begin
    Result := QuestionDlg(Application.Title + ' - ' + rsMsgErrorLoadingConfiguration,
                          ErrorMessage, mtWarning,
                          [1, rsDlgButtonContinue, 'isdefault',
                           2, rsDlgButtonExitProgram], 0) = 1;
    // Reset error message.
    ErrorMessage := '';
  end
  else
    Result := True;
end;

function LoadGlobalConfig(var {%H-}ErrorMessage: String): Boolean;
begin
  Result := gConfig.Load;
end;

function LoadExtsConfig(var {%H-}ErrorMessage: String): Boolean;
begin
  gExts.Load;
  Result := True;
end;

function LoadHotManConfig(var {%H-}ErrorMessage: String): Boolean;
begin
  HotMan.Load(gpCfgDir + gNameSCFile);
  Result := True;
end;

function LoadMultiArcConfig(var {%H-}ErrorMessage: String): Boolean;
begin
  gMultiArcList.LoadFromFile(gpCfgDir + 'multiarc.ini');
  Result := True;
end;

function LoadHistoryConfig(var {%H-}ErrorMessage: String): Boolean;
var
  Root: TXmlNode;
  History: TXmlConfig;

  procedure LoadHistory(const NodeName: String; HistoryList: TStrings);
  var
    Node: TXmlNode;
  begin
    Node := History.FindNode(Root, NodeName);
    if Assigned(Node) then
    begin
      HistoryList.Clear;
      Node := Node.FirstChild;
      while Assigned(Node) do
      begin
        if Node.CompareName('Item') = 0 then
        begin
          HistoryList.Add(History.GetContent(Node));
          if HistoryList.Count >= cMaxStringItems then Break;
        end;
        Node := Node.NextSibling;
      end;
    end;
  end;

begin
  Result:= False;
  History:= TXmlConfig.Create(gpCfgDir + 'history.xml', True);
  try
    Root:= History.FindNode(History.RootNode, 'History');
    if Assigned(Root) then
    begin
      LoadHistory('Navigation', glsDirHistory);
      LoadHistory('CommandLine', glsCmdLineHistory);
      LoadHistory('FileMask', glsMaskHistory);
      LoadHistory('SearchText', glsSearchHistory);
      LoadHistory('SearchTextPath', glsSearchPathHistory);
      LoadHistory('ReplaceText', glsReplaceHistory);
      LoadHistory('ReplaceTextPath', glsReplacePathHistory);
      LoadHistory('SearchExcludeFiles', glsSearchExcludeFiles);
      LoadHistory('SearchExcludeDirectories', glsSearchExcludeDirectories);
    end;
    Result:= True;
  finally
    History.Free;
  end;
end;

procedure SaveHistoryConfig;
var
  Root: TXmlNode;
  History: TXmlConfig;

  procedure SaveHistory(const NodeName: String; HistoryList: TStrings);
  var
    I: Integer;
    Node, SubNode: TXmlNode;
  begin
    Node := History.FindNode(Root, NodeName, True);
    History.ClearNode(Node);
    for I:= 0 to HistoryList.Count - 1 do
    begin
      SubNode := History.AddNode(Node, 'Item');
      History.SetContent(SubNode, HistoryList[I]);
      if I >= cMaxStringItems then Break;
    end;
  end;

begin
  History:= TXmlConfig.Create(gpCfgDir + 'history.xml');
  try
    Root:= History.FindNode(History.RootNode, 'History', True);
    if gSaveDirHistory then SaveHistory('Navigation', glsDirHistory);
    if gSaveCmdLineHistory then SaveHistory('CommandLine', glsCmdLineHistory);
    if gSaveFileMaskHistory then SaveHistory('FileMask', glsMaskHistory);
    if gSaveSearchReplaceHistory then
    begin
      SaveHistory('SearchText', glsSearchHistory);
      SaveHistory('SearchTextPath', glsSearchPathHistory);
      SaveHistory('ReplaceText', glsReplaceHistory);
      SaveHistory('ReplaceTextPath', glsReplacePathHistory);
      SaveHistory('SearchExcludeFiles', glsSearchExcludeFiles);
      SaveHistory('SearchExcludeDirectories', glsSearchExcludeDirectories);
    end;
    History.Save;
  finally
    History.Free;
  end;
end;

function GetValidDateTimeFormat(const aFormat, ADefaultFormat: string): string;
begin
  try
    SysUtils.FormatDateTime(aFormat, Now);
    Result := aFormat;
  except
    on EConvertError do
      Result := ADefaultFormat;
  end;
end;

procedure RegisterInitialization(InitProc: TProcedure);
begin
  SetLength(FInitList, Length(FInitList) + 1);
  FInitList[High(FInitList)]:= InitProc;
end;

procedure LoadDefaultHotkeyBindings;
var
  HMForm: THMForm;
  HMHotKey: THotkey;
  HMControl: THMControl;
begin
  // Note: Increase hkVersion if you change default hotkeys list

  // Shortcuts that can conflict with default OS shortcuts for some controls
  // should be put only to Files Panel.
  // For a list of such possible shortcuts see THotKeyManager.IsShortcutConflictingWithOS.
  // If adding multiple shortcuts for the same command use:
  //  AddIfNotExists([Shortcut1, Param1, Shortcut2, Param2, ...], Command);
  //
  // Shortcuts Ctrl+Alt+<letter> should not be added as the combinations may be
  // used to enter international characters on Windows (where Ctrl+Alt = AltGr).

  HMForm := HotMan.Forms.FindOrCreate('Main');
  with HMForm.Hotkeys do
    begin
      AddIfNotExists(['F1'],[],'cm_About');
      AddIfNotExists(['F2','','',
                      'Shift+F6','',''],'cm_RenameOnly');
      AddIfNotExists(['F3'],[],'cm_View');
      AddIfNotExists(['F4'],[],'cm_Edit');
      AddIfNotExists(['F5'],[],'cm_Copy');
      AddIfNotExists(['F6'],[],'cm_Rename');
      AddIfNotExists(['F7'],[],'cm_MakeDir');
      AddIfNotExists(['F8','','',
                      'Shift+F8','','trashcan=reversesetting',''], 'cm_Delete');
      AddIfNotExists(['F9'],[],'cm_RunTerm');
      AddIfNotExists(['Ctrl+7'],[],'cm_ShowCmdLineHistory');
      AddIfNotExists(['Ctrl+Down'],'cm_ShowCmdLineHistory',['Ctrl+7'],[]); //Historic backward support reason...
      AddIfNotExists(['Ctrl+B'],[],'cm_FlatView');
      AddIfNotExists(['Ctrl+D'],[],'cm_DirHotList');
      AddIfNotExists(['Ctrl+F'],[],'cm_QuickFilter');
      AddIfNotExists(['Ctrl+H'],[],'cm_DirHistory');
      AddIfNotExists(['Alt+Down'],'cm_DirHistory',['Ctrl+H'],[]); //Historic backward support reason...
      AddIfNotExists(['Ctrl+L'],[],'cm_CalculateSpace');
      AddIfNotExists(['Ctrl+M'],[],'cm_MultiRename');
      AddIfNotExists(['Ctrl+O'],[],'cm_ToggleFullscreenConsole');
      AddIfNotExists(['Ctrl+P'],[],'cm_AddPathToCmdLine');
      AddIfNotExists(['Ctrl+Q'],[],'cm_QuickView');
      AddIfNotExists(['Ctrl+S'],[],'cm_QuickSearch');
      AddIfNotExists(['Ctrl+R'],[],'cm_Refresh');
      AddIfNotExists(['Ctrl+T'],[],'cm_NewTab');
      AddIfNotExists(['Ctrl+U'],[],'cm_Exchange');
      AddIfNotExists(['Ctrl+W'],[],'cm_CloseTab');
      AddIfNotExists(['Ctrl+F1'],[],'cm_BriefView');
      AddIfNotExists(['Ctrl+F2'],[],'cm_ColumnsView');
      AddIfNotExists(['Ctrl+F3'],[],'cm_SortByName');
      AddIfNotExists(['Ctrl+F4'],[],'cm_SortByExt');
      AddIfNotExists(['Ctrl+F5'],[],'cm_SortByDate');
      AddIfNotExists(['Ctrl+F6'],[],'cm_SortBySize');
      AddIfNotExists(['Ctrl+Enter'],[],'cm_AddFilenameToCmdLine');
      AddIfNotExists(['Ctrl+PgDn'],[],'cm_OpenArchive');
      AddIfNotExists(['Ctrl+PgUp'],[],'cm_ChangeDirToParent');
      AddIfNotExists(['Ctrl+Alt+Enter'],[],'cm_ShellExecute');
      AddIfNotExists(['Ctrl+Shift+C'],[],'cm_CopyFullNamesToClip');
      AddIfNotExists(['Ctrl+Shift+D'],[],'cm_ConfigDirHotList');
      AddIfNotExists(['Ctrl+Shift+H'],[],'cm_HorizontalFilePanels');
      AddIfNotExists(['Ctrl+Shift+X'],[],'cm_CopyNamesToClip');
      AddIfNotExists(['Ctrl+Shift+F1'],[],'cm_ThumbnailsView');
      AddIfNotExists(['Ctrl+Shift+Enter'],[],'cm_AddPathAndFilenameToCmdLine');
      AddIfNotExists(['Ctrl+Shift+Tab'],[],'cm_PrevTab');
      AddIfNotExists(['Ctrl+Shift+F8'],[],'cm_TreeView');
      AddIfNotExists(['Ctrl+Tab'],[],'cm_NextTab');
      AddIfNotExists(['Ctrl+Up'],[],'cm_OpenDirInNewTab');
      AddIfNotExists(['Ctrl+\'],[],'cm_ChangeDirToRoot');
      AddIfNotExists(['Ctrl+.'],[],'cm_ShowSysFiles');
      AddIfNotExists(['Shift+F2'],[],'cm_FocusCmdLine');
      AddIfNotExists(['Shift+F4'],[],'cm_EditNew');
      AddIfNotExists(['Shift+F5'],[],'cm_CopySamePanel');
      AddIfNotExists(['Shift+F10'],[],'cm_ContextMenu');
      AddIfNotExists(['Shift+F12'],[],'cm_DoAnyCmCommand');
      AddIfNotExists(['Alt+V'],[],'cm_OperationsViewer');
      AddIfNotExists(['Alt+X'],[],'cm_Exit');
      AddIfNotExists(['Alt+Z'],[],'cm_TargetEqualSource');
      AddIfNotExists(['Alt+F1'],[],'cm_LeftOpenDrives');
      AddIfNotExists(['Alt+F2'],[],'cm_RightOpenDrives');
      AddIfNotExists(['Alt+F5'],[],'cm_PackFiles');
      AddIfNotExists(['Alt+F7'],[],'cm_Search');
      AddIfNotExists(['Alt+F9'],[],'cm_ExtractFiles');
      AddIfNotExists(['Alt+Del'],[],'cm_Wipe');
      AddIfNotExists(['Alt+Enter'],[],'cm_FileProperties');
      AddIfNotExists(['Alt+Left'],[],'cm_ViewHistoryPrev');
      AddIfNotExists(['Alt+Right'],[],'cm_ViewHistoryNext');
      AddIfNotExists(['Alt+Shift+Enter'],[],'cm_CountDirContent');
      AddIfNotExists(['Alt+Shift+F9'],[],'cm_TestArchive');

      if HotMan.Version < 38 then
      begin
        HMHotKey:= FindByCommand('cm_EditComment');
        if Assigned(HMHotKey) and HMHotKey.SameShortcuts(['Ctrl+Z']) then
          Remove(HMHotKey);
      end;
    end;

  HMControl := HMForm.Controls.FindOrCreate('Files Panel');
  with HMControl.Hotkeys do
    begin
      AddIfNotExists(['Del','','',
                      'Shift+Del','','trashcan=reversesetting',''], 'cm_Delete');
      AddIfNotExists(['Ctrl+A','','',
                      'Ctrl+Num+','',''],'cm_MarkMarkAll', ['Ctrl+A'], []);
      AddIfNotExists(['Num+'],[],'cm_MarkPlus');
      AddIfNotExists(['Shift+Num+'],[],'cm_MarkCurrentExtension');
      AddIfNotExists(['Ctrl+Num-'],[],'cm_MarkUnmarkAll');
      AddIfNotExists(['Num-'],[],'cm_MarkMinus');
      AddIfNotExists(['Shift+Num-'],[],'cm_UnmarkCurrentExtension');
      AddIfNotExists(['Num*'],[],'cm_MarkInvert');
      AddIfNotExists(['Ctrl+C'],[],'cm_CopyToClipboard');
      AddIfNotExists(['Ctrl+V'],[],'cm_PasteFromClipboard');
      AddIfNotExists(['Ctrl+X'],[],'cm_CutToClipboard');
      AddIfNotExists(['Ctrl+Z'],[],'cm_EditComment');
      AddIfNotExists(['Ctrl+Home'],[],'cm_ChangeDirToHome');
      AddIfNotExists(['Ctrl+Left'],[],'cm_TransferLeft');
      AddIfNotExists(['Ctrl+Right'],[],'cm_TransferRight');
      AddIfNotExists(['Shift+Tab'],[],'cm_NextGroup');
    end;

  HMForm := HotMan.Forms.FindOrCreate('Viewer');
  with HMForm.Hotkeys do
    begin
      AddIfNotExists(['F1'],[],'cm_About');
      AddIfNotExists(['F2'],[],'cm_Reload');
      AddIfNotExists(['N'],[],'cm_LoadNextFile');
      AddIfNotExists(['P'],[],'cm_LoadPrevFile');
    end;

  HMForm := HotMan.Forms.FindOrCreate('Differ');
  with HMForm.Hotkeys do
    begin
      AddIfNotExists(['Ctrl+R'],[],'cm_Reload');
      AddIfNotExists(['Alt+Down'],[],'cm_NextDifference');
      AddIfNotExists(['Alt+Up'],[],'cm_PrevDifference');
      AddIfNotExists(['Alt+Home'],[],'cm_FirstDifference');
      AddIfNotExists(['Alt+End'],[],'cm_LastDifference');
      AddIfNotExists(['Alt+X'],[],'cm_Exit');
      AddIfNotExists(['Alt+Left'],[],'cm_CopyRightToLeft');
      AddIfNotExists(['Alt+Right'],[],'cm_CopyLeftToRight');
    end;

  HMForm := HotMan.Forms.FindOrCreate('Copy/Move Dialog');
  with HMForm.Hotkeys do
    begin
      AddIfNotExists(['F2'],[],'cm_AddToQueue');
    end;

  HMForm := HotMan.Forms.FindOrCreate('Edit Comment Dialog');
  with HMForm.Hotkeys do
    begin
      AddIfNotExists(['F2'],[],'cm_SaveDescription');
    end;

  if not mbFileExists(gpCfgDir + gNameSCFile) then
    gNameSCFile := 'shortcuts.scf';
  HotMan.Save(gpCfgDir + gNameSCFile);
end;

function InitPropStorage(Owner: TComponent): TIniPropStorageEx;
var
  sWidth, sHeight: String;
begin
  Result:= TIniPropStorageEx.Create(Owner);
  Result.IniFileName:= gpCfgDir + 'session.ini';
  if Owner is TCustomForm then
  with Owner as TCustomForm do
  begin
    if (Monitor = nil) then
      Result.IniSection:= ClassName
    else begin
      sWidth:= IntToStr(Monitor.Width);
      sHeight:= IntToStr(Monitor.Height);
      Result.IniSection:= ClassName + '(' + sWidth + 'x' + sHeight + ')';
    end;
  end;
end;

procedure FontToFontOptions(Font: TFont; out Options: TDCFontOptions);
begin
  with Options do
  begin
    Name    := Font.Name;
    Size    := Font.Size;
    Style   := Font.Style;
    Quality := Font.Quality;
  end;
end;

procedure FontOptionsToFont(Options: TDCFontOptions; Font: TFont);
begin
  with Options do
  begin
    Font.Name    := Name;
    Font.Size    := Size;
    Font.Style   := Style;
    Font.Quality := Quality;
  end;
end;


procedure OldKeysToNew(ActionEnabled: Boolean; ShiftState: TShiftState; Action: TKeyTypingAction);
var
  Modifier: TKeyTypingModifier;
begin
  if ActionEnabled then
  begin
    for Modifier in TKeyTypingModifier do
    begin
      if TKeyTypingModifierToShift[Modifier] = ShiftState then
        gKeyTyping[Modifier] := Action
      else if gKeyTyping[Modifier] = Action then
        gKeyTyping[Modifier] := ktaNone;
    end;
  end
  else
  begin
    for Modifier in TKeyTypingModifier do
    begin
      if gKeyTyping[Modifier] = Action then
      begin
        gKeyTyping[Modifier] := ktaNone;
        Break;
      end;
    end;
  end;
end;

function LoadStringsFromFile(var list: TStringListEx; const sFileName:String;
                             MaxStrings: Integer = 0): Boolean;
var
  i:Integer;
begin
  Assert(list <> nil,'LoadStringsFromFile: list=nil');
  list.Clear;
  Result:=False;
  if mbFileExists(sFileName) then
  begin
    list.LoadFromFile(sFileName);
    if MaxStrings > 0 then
    begin
      for i:=list.Count-1 downto 0 do
        if i>MaxStrings then
          list.Delete(i)
        else
          Break;
    end;
    Result:=True;
  end;
end;

procedure ConvertIniToXml;
var
  MultiRename: TfrmMultiRename = nil;
  tmpFiles: TFiles = nil;
begin
  SaveXmlConfig;

  // Force loading Multi-rename config if it wasn't used yet.
  tmpFiles := TFiles.Create(mbGetCurrentDir);
  MultiRename := TfrmMultiRename.Create(nil, nil, tmpFiles);
  try
    MultiRename.LoadPresetsIni(gIni);
    MultiRename.PublicSavePresets;
  finally
    FreeThenNil(MultiRename);
    FreeThenNil(tmpFiles);
  end;

  FreeAndNil(gIni);

  if mbFileExists(gpGlobalCfgDir + 'doublecmd.ini') then
    mbRenameFile(gpGlobalCfgDir + 'doublecmd.ini', gpGlobalCfgDir + 'doublecmd.ini.obsolete');
  if mbFileExists(gpCfgDir + 'doublecmd.ini') then
    mbRenameFile(gpCfgDir + 'doublecmd.ini', gpCfgDir + 'doublecmd.ini.obsolete');
end;

procedure CopySettingsFiles;
begin
  { Create default configuration files if need }
  if gpCfgDir <> gpGlobalCfgDir then
    begin
      // extension file
      if not mbFileExists(gpCfgDir + gcfExtensionAssociation) then
        CopyFile(gpGlobalCfgDir + 'extassoc.xml', gpCfgDir + 'ExtAssoc.xml');
      // pixmaps file
      if not mbFileExists(gpCfgDir + 'pixmaps.txt') then
        CopyFile(gpGlobalCfgDir + 'pixmaps.txt', gpCfgDir + 'pixmaps.txt');
      // multiarc configuration file
      if not mbFileExists(gpCfgDir + 'multiarc.ini') then
        CopyFile(gpGlobalCfgDir + 'multiarc.ini', gpCfgDir + 'multiarc.ini');
    end;
end;

procedure CreateGlobs;
begin
  gExts := TExts.Create;
  gColorExt := TColorExt.Create;
  gFileInfoToolTip := TFileInfoToolTip.Create;
  gDirectoryHotlist := TDirectoryHotlist.Create;
  gFavoriteTabsList := TFavoriteTabsList.Create;
  glsDirHistory := TStringListEx.Create;
  glsCmdLineHistory := TStringListEx.Create;
  glsMaskHistory := TStringListEx.Create;
  glsSearchHistory := TStringListEx.Create;
  glsSearchPathHistory := TStringListEx.Create;
  glsReplaceHistory := TStringListEx.Create;
  glsReplacePathHistory := TStringListEx.Create;
  glsIgnoreList := TStringListEx.Create;
  glsSearchExcludeFiles:= TStringList.Create;
  glsSearchExcludeDirectories:= TStringList.Create;
  gSearchTemplateList := TSearchTemplateList.Create;
  gDSXPlugins := TDSXModuleList.Create;
  gWCXPlugins := TWCXModuleList.Create;
  gWDXPlugins := TWDXModuleList.Create;
  gWFXPlugins := TWFXModuleList.Create;
  gWLXPlugins := TWLXModuleList.Create;
  gMultiArcList := TMultiArcList.Create;
  ColSet := TPanelColumnsList.Create;
  HotMan := THotKeyManager.Create;
end;

procedure DestroyGlobs;
begin
  FreeThenNil(gColorExt);
  FreeThenNil(gFileInfoToolTip);
  FreeThenNil(glsDirHistory);
  FreeThenNil(glsCmdLineHistory);
  FreeThenNil(gSupportForVariableHelperMenu);
  FreeThenNil(gSpecialDirList);
  FreeThenNil(gDirectoryHotlist);
  FreeThenNil(gFavoriteTabsList);
  FreeThenNil(glsMaskHistory);
  FreeThenNil(glsSearchHistory);
  FreeThenNil(glsSearchPathHistory);
  FreeThenNil(glsReplaceHistory);
  FreeThenNil(glsReplacePathHistory);
  FreeThenNil(glsIgnoreList);
  FreeThenNil(glsSearchExcludeFiles);
  FreeThenNil(glsSearchExcludeDirectories);
  FreeThenNil(gExts);
  FreeThenNil(gIni);
  FreeThenNil(gConfig);
  FreeThenNil(gSearchTemplateList);
  FreeThenNil(gDSXPlugins);
  FreeThenNil(gWCXPlugins);
  FreeThenNil(gWDXPlugins);
  FreeThenNil(gWFXPlugins);
  FreeThenNil(gMultiArcList);
  FreeThenNil(gWLXPlugins);
  FreeThenNil(ColSet);
  FreeThenNil(HotMan);
end;

{$IFDEF MSWINDOWS}
function GetPathNameIfItMatch(SpecialConstant:integer; FilenameSearched:string):string;
var
  MaybePath:string;
  FilePath: array [0..Pred(MAX_PATH)] of WideChar = '';
begin
  result:='';

  FillChar(FilePath, MAX_PATH, 0);
  SHGetSpecialFolderPathW(0, @FilePath[0], SpecialConstant, FALSE);
  if FilePath<>'' then
  begin
    MaybePath:=IncludeTrailingPathDelimiter(UTF16ToUTF8(WideString(FilePath)));
    if mbFileExists(MaybePath+FilenameSearched) then result:=MaybePath+FilenameSearched;
  end;
end;
{$ENDIF}

procedure SetDefaultConfigGlobs;

  procedure SetDefaultExternalTool(var ExternalToolOptions: TExternalToolOptions);
  begin
    with ExternalToolOptions do
    begin
      Enabled := False;
      Path := '';
      Parameters := '';
      RunInTerminal := False;
      KeepTerminalOpen := False;
    end;
  end;

begin
  { Language page }
  gPOFileName := '';

  { Behaviours page }
  gRunInTermStayOpenCmd := RunInTermStayOpenCmd;
  gRunInTermStayOpenParams := RunInTermStayOpenParams;
  gRunInTermCloseCmd := RunInTermCloseCmd;
  gRunInTermCloseParams := RunInTermCloseParams;
  gRunTermCmd := RunTermCmd;
  gRunTermParams := RunTermParams;
  gOnlyOneAppInstance := False;
  gLynxLike := True;
  gSortCaseSensitivity := cstNotSensitive;
  gSortNatural := False;
  gSortFolderMode := sfmSortNameShowFirst;
  gNewFilesPosition := nfpSortedPosition;
  gUpdatedFilesPosition := ufpNoChange;
  gFileSizeFormat := fsfFloat;
  gMinimizeToTray := False;
  gAlwaysShowTrayIcon := False;
  gMouseSelectionEnabled := True;
  gMouseSelectionButton := 0;  // Left
  gScrollMode := smLineByLine;
  gWheelScrollLines:= Mouse.WheelScrollLines;
  gAutoFillColumns := False;
  gAutoSizeColumn := 1;
  gColumnsAutoSaveWidth := True;
  gColumnsTitleStyle := {$IFDEF LCLWIN32}tsNative{$ELSE}tsStandard{$ENDIF};
  gCustomColumnsChangeAllColumns := False;
  gDateTimeFormat := DefaultDateTimeFormat;
  gCutTextToColWidth := True;
  gShowSystemFiles := False;
  // Under Mac OS X loading file list in separate thread are very very slow
  // so disable and hide this option under Mac OS X Carbon
  gListFilesInThread := {$IFDEF LCLCARBON}False{$ELSE}True{$ENDIF};
  gLoadIconsSeparately := True;
  gDelayLoadingTabs := True;
  gHighlightUpdatedFiles := True;
  gDriveBlackList := '';
  gDriveBlackListUnmounted := False;

  { Brief view page }
  gBriefViewFixedCount := 2;
  gBriefViewFixedWidth := 100;
  gBriefViewMode := bvmAutoSize;
  gBriefViewFileExtAligned := False;

  { Tools page }
  SetDefaultExternalTool(gExternalTools[etViewer]);
  SetDefaultExternalTool(gExternalTools[etEditor]);
  SetDefaultExternalTool(gExternalTools[etDiffer]);

  { Differ related}
  gResultingFramePositionAfterCompare := rfpacActiveOnLeft;

  { Fonts page }
  gFonts[dcfMain].Name := 'default';
  gFonts[dcfMain].Size := 10;
  gFonts[dcfMain].Style := [fsBold];
  gFonts[dcfMain].Quality := fqDefault;
  gFonts[dcfEditor].Name := MonoSpaceFont;
  gFonts[dcfEditor].Size := 14;
  gFonts[dcfEditor].Style := [];
  gFonts[dcfEditor].Quality := fqDefault;
  gFonts[dcfViewer].Name := MonoSpaceFont;
  gFonts[dcfViewer].Size := 14;
  gFonts[dcfViewer].Style := [];
  gFonts[dcfViewer].Quality := fqDefault;
  gFonts[dcfLog].Name := MonoSpaceFont;
  gFonts[dcfLog].Size := 12;
  gFonts[dcfLog].Style := [];
  gFonts[dcfLog].Quality := fqDefault;
  gFonts[dcfViewerBook].Name := 'default';
  gFonts[dcfViewerBook].Size := 16;
  gFonts[dcfViewerBook].Style := [fsBold];
  gFonts[dcfViewerBook].Quality := fqDefault;
  gFonts[dcfConsole].Name := MonoSpaceFont;
  gFonts[dcfConsole].Size := 12;
  gFonts[dcfConsole].Style := [];
  gFonts[dcfConsole].Quality := fqDefault;

  { Colors page }
  gUseCursorBorder := False;
  gCursorBorderColor := clHighlight;
  gUseFrameCursor := False;
  gForeColor := clWindowText;
  gBackColor := clWindow;
  gBackColor2 := clWindow;
  gMarkColor := clRed;
  gCursorColor := clHighlight;
  gCursorText := clHighlightText;
  gInactiveCursorColor := clInactiveCaption;
  gInactiveMarkColor := clMaroon;
  gUseInvertedSelection := False;
  gUseInactiveSelColor := False;
  gAllowOverColor := True;

  gInactivePanelBrightness := 100; // Full brightness
  gIndUseGradient := True;
  gIndForeColor := clBlack;
  gIndBackColor := clWhite;

  { Layout page }
  gMainMenu := True;
  gButtonBar := True;
  gToolBarFlat := True;
  gToolBarButtonSize := 24;
  gToolBarIconSize := 16;
  gToolbarReportErrorWithCommands := FALSE;
  gDriveBar1 := True;
  gDriveBar2 := True;
  gDriveBarFlat := True;
  gDrivesListButton := True;
  gDirectoryTabs := True;
  gCurDir := True;
  gTabHeader := True;
  gStatusBar := True;
  gCmdLine := True;
  gLogWindow := False;
  gTermWindow := False;
  gKeyButtons := True;
  gInterfaceFlat := True;
  gDriveInd := False;
  gDriveFreeSpace := True;
  gProgInMenuBar := False;
  gPanelOfOp := True;
  gShortFormatDriveInfo := True;
  gHorizontalFilePanels := False;
  gDrivesListButtonOptions := [dlbShowLabel, dlbShowFileSystem, dlbShowFreeSpace];
  gSeparateTree := False;

  { Keys page }
  gKeyTyping[ktmNone]    := ktaQuickSearch;
  gKeyTyping[ktmAlt]     := ktaNone;
  gKeyTyping[ktmCtrlAlt] := ktaQuickFilter;

  { File operations page }
  gCopyBlockSize := 524288;
  gHashBlockSize := 8388608;
  gUseMmapInSearch := False;
  gPartialNameSearch := True;
  gWipePassNumber := 1;
  gDropReadOnlyFlag := False;
  gProcessComments := False;
  gRenameSelOnlyName := False;
  gShowCopyTabSelectPanel := False;
  gUseTrash := True;
  gSkipFileOpError := False;
  gTypeOfDuplicatedRename := drLegacyWithCopy;
  gShowDialogOnDragDrop := False;
  gDragAndDropDesiredTextFormat[DropTextRichText_Index].Name:='Richtext format';
  gDragAndDropDesiredTextFormat[DropTextRichText_Index].DesireLevel:=0;
  gDragAndDropDesiredTextFormat[DropTextHtml_Index].Name:='HTML format';
  gDragAndDropDesiredTextFormat[DropTextHtml_Index].DesireLevel:=1;
  gDragAndDropDesiredTextFormat[DropTextUnicode_Index].Name:='Unicode format';
  gDragAndDropDesiredTextFormat[DropTextUnicode_Index].DesireLevel:=2;
  gDragAndDropDesiredTextFormat[DropTextSimpleText_Index].Name:='Simple text format';
  gDragAndDropDesiredTextFormat[DropTextSimpleText_Index].DesireLevel:=3;
  gDragAndDropAskFormatEachTime := False;
  gDragAndDropTextAutoFilename := False;
  gDragAndDropSaveUnicodeTextInUFT8 := True;
  gOverwriteFolder := False;
  gNtfsHourTimeDelay := False;
  gFileOperationsProgressKind := fopkSeparateWindow;
  gFileOperationsConfirmations := [focCopy, focMove, focDelete, focDeleteToTrash];

  // Operations options
  gOperationOptionSymLinks := fsooslNone;
  gOperationOptionCorrectLinks := False;
  gOperationOptionFileExists := fsoofeNone;
  gOperationOptionDirectoryExists := fsoodeNone;
  gOperationOptionSetPropertyError := fsoospeNone;
  gOperationOptionReserveSpace := False;
  gOperationOptionCheckFreeSpace := True;
  gOperationOptionCopyAttributes := True;
  gOperationOptionCopyTime := True;
  gOperationOptionCopyOwnership := False;
  gOperationOptionCopyPermissions := False;


  { Tabs page }
  gDirTabOptions := [tb_always_visible,
                     tb_confirm_close_all,
                     tb_show_asterisk_for_locked,
                     tb_activate_panel_on_click,
                     tb_close_on_doubleclick,
                     tb_reusing_tab_when_possible,
                     tb_confirm_close_locked_tab];
  gDirTabActionOnDoubleClick := tadc_FavoriteTabs;
  gDirTabLimit := 32;
  gDirTabPosition := tbpos_top;

  { Favorite Tabs}
  gFavoriteTabsUseRestoreExtraOptions := False;
  gWhereToAddNewFavoriteTabs := afte_Last;
  gFavoriteTabsFullExpandOrNot := True;
  gFavoriteTabsGoToConfigAfterSave := False;
  gFavoriteTabsGoToConfigAfterReSave := False;
  gDefaultTargetPanelLeftSaved := tclLeft;
  gDefaultTargetPanelRightSaved := tclRight;
  gDefaultExistingTabsToKeep := tclNone;
  gFavoriteTabsSaveDirHistory := False;

  { Log page }
  gLogFile := False;
  gLogFileWithDateInName := FALSE;
  gLogFileName := EnvVarConfigPath + PathDelim + 'doublecmd.log';
  gLogOptions := [log_cp_mv_ln, log_delete, log_dir_op, log_arc_op,
                  log_vfs_op, log_success, log_errors, log_info,
                  log_start_shutdown, log_commandlineexecution];

  { Configuration page }
  gSaveConfiguration := True;
  gSaveSearchReplaceHistory := True;
  gSaveDirHistory := True;
  gSaveCmdLineHistory := True;
  gSaveFileMaskHistory := True;

  { Quick Search/Filter page }
  gQuickSearchOptions.Match := [qsmBeginning, qsmEnding];
  gQuickSearchOptions.Items := qsiFilesAndDirectories;
  gQuickSearchOptions.SearchCase := qscInsensitive;
  gQuickFilterAutoHide := True;
  gQuickFilterSaveSessionModifications := False; //Legacy...

  { Miscellaneous page }
  gGridVertLine := False;
  gGridHorzLine := False;
  gShowWarningMessages := True;
  gSpaceMovesDown := False;
  gDirBrackets := True;
  gInplaceRename := False;
  gHotDirAddTargetOrNot := False;
  gHotDirFullExpandOrNot:=False;
  gShowPathInPopup:=FALSE;
  gShowOnlyValidEnv:=TRUE;
  gWhereToAddNewHotDir := ahdSmart;
  gShowToolTipMode := True;
  gThumbSave := True;
  gThumbSize.cx := 128;
  gThumbSize.cy := 128;
  gSearchDefaultTemplate := EmptyStr;

  { Auto refresh page }
  gWatchDirs := [watch_file_name_change, watch_attributes_change];
  gWatchDirsExclude := '';
  gWatcherMode := fswmAllowDelete;

  { Icons page }
  gShowIcons := sim_all_and_exe;
  gShowIconsNew := gShowIcons;
  gIconOverlays := False;
  gIconsSize := 16;
  gIconsSizeNew := gIconsSize;
  gIconsExclude := False;
  gIconsExcludeDirs := EmptyStr;
  gCustomDriveIcons := False;
  gIconsInMenus := False;
  gIconsInMenusSize := 16;
  gIconsInMenusSizeNew := gIconsInMenusSize;

  { Ignore list page }
  gIgnoreListFileEnabled := False;
  gIgnoreListFile := EnvVarConfigPath + PathDelim + 'ignorelist.txt';

  {Viewer}
  gImageStretch := False;
  gImageStretchOnlyLarge := False;
  gImageCenter := True;
  gPreviewVisible := False;
  gCopyMovePath1 := '';
  gCopyMovePath2 := '';
  gCopyMovePath3 := '';
  gCopyMovePath4 := '';
  gCopyMovePath5 := '';
  gImagePaintMode := 'Pen';
  gImagePaintWidth := 5;
  gColCount := 1;
  gImagePaintColor := clRed;
  gBookBackgroundColor := clBlack;
  gBookFontColor := clWhite;
  gTextPosition:= 0;
  gViewerMode:= 0;

  { Editor }
  gEditWaitTime := 2000;
  gEditorSynEditOptions := SYNEDIT_DEFAULT_OPTIONS;

  {SyncDirs}
  gSyncDirsSubdirs := False;
  gSyncDirsByContent := False;
  gSyncDirsIgnoreDate := False;
  gSyncDirsShowFilterCopyRight := True;
  gSyncDirsShowFilterEqual := True;
  gSyncDirsShowFilterNotEqual := True;
  gSyncDirsShowFilterCopyLeft := True;
  gSyncDirsShowFilterDuplicates := True;
  gSyncDirsShowFilterSingles := True;
  gSyncDirsFileMask := '*';

  { Internal Associations}
  gFileAssociationLastCustomAction := rsMsgDefaultCustomActionName;
  gOfferToAddToFileAssociations := False;
  gExtendedContextMenu := False;
  gOpenExecuteViaShell := False;
  gExecuteViaTerminalClose := False;
  gExecuteViaTerminalStayOpen := False;
  gIncludeFileAssociation := False;

  { - Other - }
  gGoToRoot := False;
  gLuaLib := LuaDLL;
  gNameSCFile := 'shortcuts.scf';
  gLastUsedPacker := 'zip';
  gUseShellForFileOperations :=
    {$IF DEFINED(MSWINDOWS)}WindowsVersion >= wvVista{$ELSE}False{$ENDIF};
  gLastDoAnyCommand := 'cm_Refresh';

  { TotalCommander Import/Export }
  //Will search minimally where TC could be installed so the default value would have some chances to be correct.
  {$IFDEF MSWINDOWS}
  gTotalCommanderExecutableFilename:='';
  gTotalCommanderConfigFilename:='';
  gTotalCommanderToolbarPath:='';

  if mbFileExists('c:\totalcmd\TOTALCMD.EXE') then gTotalCommanderExecutableFilename:='c:\totalcmd\TOTALCMD.EXE';
  if (gTotalCommanderExecutableFilename='') AND  (mbFileExists('c:\totalcmd\TOTALCMD64.EXE')) then gTotalCommanderExecutableFilename:='c:\totalcmd\TOTALCMD64.EXE';
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_COMMON_PROGRAMS,'totalcmd\TOTALCMD.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_PROGRAMS,'totalcmd\TOTALCMD.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_PROGRAM_FILESX86,'totalcmd\TOTALCMD.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_PROGRAM_FILES_COMMON,'totalcmd\TOTALCMD.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_PROGRAM_FILES_COMMONX86,'totalcmd\TOTALCMD.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_COMMON_PROGRAMS,'totalcmd\TOTALCMD64.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_PROGRAMS,'totalcmd\TOTALCMD64.EXE');
  if gTotalCommanderExecutableFilename='' then gTotalCommanderExecutableFilename:=GetPathNameIfItMatch(CSIDL_PROGRAM_FILES_COMMON,'totalcmd\TOTALCMD64.EXE');

  if mbFileExists('c:\totalcmd\wincmd.ini') then gTotalCommanderConfigFilename:='c:\totalcmd\wincmd.ini';
  if gTotalCommanderConfigFilename='' then gTotalCommanderConfigFilename:=GetPathNameIfItMatch(CSIDL_APPDATA,'GHISLER\wincmd.ini');
  if gTotalCommanderConfigFilename='' then gTotalCommanderConfigFilename:=GetPathNameIfItMatch(CSIDL_PROFILE,'wincmd.ini');
  if gTotalCommanderConfigFilename='' then gTotalCommanderConfigFilename:=GetPathNameIfItMatch(CSIDL_WINDOWS,'wincmd.ini'); //Don't laugh. The .INI file were originally saved in windows folder for many programs!

  if gTotalCommanderConfigFilename<>'' then gTotalCommanderToolbarPath:=ExtractFilePath(gTotalCommanderConfigFilename);
  {$ENDIF}

  gExts.Clear;
  gColorExt.Clear;
  gFileInfoToolTip.Clear;
  gDirectoryHotlist.Clear;
  gFavoriteTabsList.Clear;
  glsDirHistory.Clear;
  glsMaskHistory.Clear;
  glsSearchHistory.Clear;
  glsSearchPathHistory.Clear;
  glsReplaceHistory.Clear;
  glsReplacePathHistory.Clear;
  glsIgnoreList.Clear;
  gSearchTemplateList.Clear;
  gDSXPlugins.Clear;
  gWCXPlugins.Clear;
  gWDXPlugins.Clear;
  gWFXPlugins.Clear;
  gWLXPlugins.Clear;
  gMultiArcList.Clear;
  ColSet.Clear;
end;

procedure SetDefaultNonConfigGlobs;
begin
  { - Not in config - }
  gHelpLang := '';
  gRepeatPassword := True;
  gDirHistoryCount := 30;
  gFirstTextSearch := True;
  gErrorFile := gpCfgDir + ExtractOnlyFileName(Application.ExeName) + '.err';
  DefaultDateTimeFormat := FormatSettings.ShortDateFormat + ' hh:nn:ss';
end;

function OpenConfig(var ErrorMessage: String): Boolean;
begin
  if Assigned(gConfig) then
    Exit(True);

  // Check global directory for XML config.
  if (gpCmdLineCfgDir = EmptyStr) and
     mbFileExists(gpGlobalCfgDir + 'doublecmd.xml') then
  begin
    gConfig := TXmlConfig.Create(gpGlobalCfgDir + 'doublecmd.xml');
    gUseConfigInProgramDir := True;
    if mbFileAccess(gpGlobalCfgDir + 'doublecmd.xml', fmOpenRead or fmShareDenyWrite) then
    begin
      LoadConfigCheckErrors(@LoadGlobalConfig, gpGlobalCfgDir + 'doublecmd.xml', ErrorMessage);
      gUseConfigInProgramDir := gConfig.GetValue(gConfig.RootNode, 'Configuration/UseConfigInProgramDir', False);
      if not gUseConfigInProgramDir then
      begin
        if mbFileExists(gpCfgDir + 'doublecmd.xml') then
          // Close global config so that the local config is opened below.
          FreeAndNil(gConfig)
        else
          // Local config is used but it doesn't exist. Use global config that has just
          // been read but set file name accordingly and later save to local config.
          gConfig.FileName := gpCfgDir + 'doublecmd.xml';
      end;
    end
    else
    begin
      // Configuration file is not readable.
      AddStrWithSep(ErrorMessage,
          'Config file "' + gpGlobalCfgDir + 'doublecmd.xml' +
          '" exists but is not readable.',
          LineEnding);
      Exit(False);
    end;
  end;

  // Check user directory for XML config.
  if not Assigned(gConfig) and mbFileExists(gpCfgDir + 'doublecmd.xml') then
  begin
    gConfig := TXmlConfig.Create(gpCfgDir + 'doublecmd.xml');
    gUseConfigInProgramDir := False;
    if mbFileAccess(gpCfgDir + 'doublecmd.xml', fmOpenRead or fmShareDenyWrite) then
    begin
      LoadConfigCheckErrors(@LoadGlobalConfig, gpCfgDir + 'doublecmd.xml', ErrorMessage);
    end
    else
    begin
      // Configuration file is not readable.
      AddStrWithSep(ErrorMessage,
          'Config file "' + gpCfgDir + 'doublecmd.xml' +
          '" exists but is not readable.',
          LineEnding);
      Exit(False);
    end;
  end;

  if not Assigned(gConfig) then
  begin
    // Open INI config if present.

    // Check global directory for INI config.
    if not Assigned(gIni) and mbFileAccess(gpGlobalCfgDir + 'doublecmd.ini', fmOpenRead or fmShareDenyWrite) then
    begin
      gIni := TIniFileEx.Create(gpGlobalCfgDir + 'doublecmd.ini', fmOpenRead or fmShareDenyWrite);
      gUseConfigInProgramDir := gIni.ReadBool('Configuration', 'UseIniInProgramDir', False);
      if not gUseConfigInProgramDir then
        FreeAndNil(gIni)
      else
      begin
        if mbFileAccess(gpGlobalCfgDir + 'doublecmd.ini', fmOpenWrite or fmShareDenyWrite) then
        begin
          FreeAndNil(gIni);
          gIni := TIniFileEx.Create(gpGlobalCfgDir + 'doublecmd.ini', fmOpenWrite or fmShareDenyWrite);
        end
        else begin
          DCDebug('Warning: Config file "' + gpGlobalCfgDir + 'doublecmd.ini' +
                  '" is not accessible for writing. Configuration will not be saved.');
        end;
      end;
    end;

    // Check user directory for INI config.
    if not Assigned(gIni) and mbFileAccess(gpCfgDir + 'doublecmd.ini', fmOpenRead or fmShareDenyWrite) then
    begin
      gIni := TIniFileEx.Create(gpCfgDir + 'doublecmd.ini', fmOpenRead or fmShareDenyWrite);
      gUseConfigInProgramDir := False;
    end;

    if Assigned(gIni) then
    begin
      DebugLn('Converted old configuration from ' + gIni.FileName);
      if gUseConfigInProgramDir then
        gConfig := TXmlConfig.Create(gpGlobalCfgDir + 'doublecmd.xml')
      else
        gConfig := TXmlConfig.Create(gpCfgDir + 'doublecmd.xml');
    end;
  end;

  // By default use config in user directory.
  if not Assigned(gConfig) then
  begin
    gConfig := TXmlConfig.Create(gpCfgDir + 'doublecmd.xml');
    gUseConfigInProgramDir := False;
  end;

  gUseConfigInProgramDirNew := gUseConfigInProgramDir;

  // If global config is used then set config directory as global config directory.
  if gUseConfigInProgramDir then
  begin
    gpCfgDir := gpGlobalCfgDir;
    UpdateEnvironmentVariable;
  end;

  if mbFileExists(gpCfgDir + 'doublecmd.xml') and
     (not mbFileAccess(gpCfgDir + 'doublecmd.xml', fmOpenWrite or fmShareDenyWrite)) then
  begin
    DCDebug('Warning: Config file "' + gpCfgDir + 'doublecmd.xml' +
            '" is not accessible for writing. Configuration will not be saved.');
  end;

  if not mbDirectoryExists(gpCfgDir) then
    mbForceDirectory(gpCfgDir);

  Result := True;
end;

function LoadGlobs: Boolean;
var
  ErrorMessage: String = '';
begin
  Result := False;
  if not OpenConfig(ErrorMessage) then
    Exit;

  DCDebug('Loading configuration from ', gpCfgDir);

  SetDefaultConfigGlobs;
  if Assigned(gIni) then
    LoadIniConfig
  else if Assigned(gConfig) then
    LoadXmlConfig
  else
  begin
    DCDebug('Error: No config created.');
    Exit(False);
  end;

  { Favorite Tabs }
  gFavoriteTabsList.LoadAllListFromXml;

  // Update plugins if DC version is changed
  if (gPreviousVersion <> dcVersion) then UpdatePlugins;

  // Set secondary variables for options that need restart.
  gShowIconsNew := gShowIcons;
  gIconsSizeNew := gIconsSize;
  gIconsInMenusSizeNew := gIconsInMenusSize;

  CopySettingsFiles;

  { Internal associations }
  //"LoadExtsConfig" checks itself if file is present or not
  LoadConfigCheckErrors(@LoadExtsConfig, gpCfgDir + gcfExtensionAssociation, ErrorMessage);

  if mbFileExists(gpCfgDir + 'dirhistory.txt') then
  begin
    LoadStringsFromFile(glsDirHistory, gpCfgDir + 'dirhistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'dirhistory.txt', gpCfgDir + 'dirhistory.txt.obsolete');
  end;
  if mbFileExists(gpCfgDir + 'cmdhistory.txt') then
  begin
    LoadStringsFromFile(glsCmdLineHistory, gpCfgDir + 'cmdhistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'cmdhistory.txt', gpCfgDir + 'cmdhistory.txt.obsolete');
  end;
  if mbFileExists(gpCfgDir + 'maskhistory.txt') then
  begin
    LoadStringsFromFile(glsMaskHistory, gpCfgDir + 'maskhistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'maskhistory.txt', gpCfgDir + 'maskhistory.txt.obsolete');
  end;
  if mbFileExists(gpCfgDir + 'searchpathhistory.txt') then
  begin
    LoadStringsFromFile(glsSearchPathHistory, gpCfgDir + 'searchpathhistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'searchpathhistory.txt', gpCfgDir + 'searchpathhistory.txt.obsolete');
  end;
  if mbFileExists(gpCfgDir + 'searchhistory.txt') then
  begin
    LoadStringsFromFile(glsSearchHistory, gpCfgDir + 'searchhistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'searchhistory.txt', gpCfgDir + 'searchhistory.txt.obsolete');
  end;
  if mbFileExists(gpCfgDir + 'replacehistory.txt') then
  begin
    LoadStringsFromFile(glsReplaceHistory, gpCfgDir + 'replacehistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'replacehistory.txt', gpCfgDir + 'replacehistory.txt.obsolete');
  end;
  if mbFileExists(gpCfgDir + 'replacehpathhistory.txt') then
  begin
    LoadStringsFromFile(glsReplacePathHistory, gpCfgDir + 'replacepathhistory.txt', cMaxStringItems);
    mbRenameFile(gpCfgDir + 'replacepathhistory.txt', gpCfgDir + 'replacepathhistory.txt.obsolete');
  end;
  LoadStringsFromFile(glsIgnoreList, ReplaceEnvVars(gIgnoreListFile));

  { Hotkeys }
  if not mbFileExists(gpCfgDir + gNameSCFile) then
    gNameSCFile := 'shortcuts.scf';
  // Rename old shortcuts file to new name.
  if mbFileExists(gpCfgDir + 'shortcuts.ini') and
     not mbFileExists(gpCfgDir + gNameSCFile) then
       mbRenameFile(gpCfgDir + 'shortcuts.ini', gpCfgDir + gNameSCFile);
  LoadConfigCheckErrors(@LoadHotManConfig, gpCfgDir + gNameSCFile, ErrorMessage);

  { MultiArc addons }
  if mbFileExists(gpCfgDir + 'multiarc.ini') then
    LoadConfigCheckErrors(@LoadMultiArcConfig, gpCfgDir + 'multiarc.ini', ErrorMessage);

  { Various history }
  if mbFileExists(gpCfgDir + 'history.xml') then
    LoadConfigCheckErrors(@LoadHistoryConfig, gpCfgDir + 'history.xml', ErrorMessage);

  { Localization }
  msgLoadLng;

  FillFileFuncList;

  { Specialdir }
  if gShowOnlyValidEnv=FALSE then gSpecialDirList.PopulateSpecialDir;  //We must reload it if user has included the unsignificant environment variable. But anyway, this will not happen often.

  Result := AskUserOnError(ErrorMessage);
end;

procedure SaveGlobs;
var
  TmpConfig: TXmlConfig;
  Ini: TIniFileEx = nil;
  ErrMsg: String = '';
begin
  if (gUseConfigInProgramDirNew <> gUseConfigInProgramDir) and
     (gpCmdLineCfgDir = EmptyStr) then
    begin
      LoadPaths;
      if gUseConfigInProgramDirNew then
      begin
        gpCfgDir := gpGlobalCfgDir;
        UpdateEnvironmentVariable;
      end;

      { Save location of configuration files }

      if Assigned(gIni) then
      begin
        // Still using INI config.
        FreeThenNil(gIni);
        try
          Ini:= TIniFileEx.Create(gpGlobalCfgDir + 'doublecmd.ini');
          Ini.WriteBool('Configuration', 'UseIniInProgramDir', gUseConfigInProgramDirNew);
          Ini.UpdateFile;
        finally
          FreeThenNil(Ini);
        end;
        gIni := TIniFileEx.Create(gpCfgDir + 'doublecmd.ini');
      end;

      if mbFileAccess(gpGlobalCfgDir + 'doublecmd.xml', fmOpenWrite or fmShareDenyWrite) then
      begin
        TmpConfig := TXmlConfig.Create(gpGlobalCfgDir + 'doublecmd.xml', True);
        try
          TmpConfig.SetValue(TmpConfig.RootNode, 'Configuration/UseConfigInProgramDir', gUseConfigInProgramDirNew);
          TmpConfig.Save;
        finally
          TmpConfig.Free;
        end;
      end;

      gConfig.FileName := gpCfgDir + 'doublecmd.xml';
    end;

  if mbFileAccess(gpCfgDir, fmOpenWrite or fmShareDenyNone) then
  begin
    SaveWithCheck(@SaveCfgIgnoreList, 'ignore list', ErrMsg);
    SaveWithCheck(@SaveCfgMainConfig, 'main configuration', ErrMsg);
    SaveWithCheck(@SaveHistoryConfig, 'various history', ErrMsg);

    if ErrMsg <> EmptyStr then
      DebugLn(ErrMsg);
  end
  else
    DebugLn('Not saving configuration - no write access to ', gpCfgDir);
end;

procedure LoadIniConfig;
var
  oldQuickSearch: Boolean = True;
  oldQuickFilter: Boolean = False;
  oldQuickSearchMode: TShiftState = [ssCtrl, ssAlt];
  oldQuickFilterMode: TShiftState = [];
  glsHotDirTempoLegacyConversion:TStringListEx;
  LocalHotDir: THotDir;
  IndexHotDir: integer;
begin
  { Layout page }

  gButtonBar := gIni.ReadBool('Layout', 'ButtonBar', True);
  gToolBarFlat := gIni.ReadBool('ButtonBar', 'FlatIcons', True);
  gToolBarButtonSize := gIni.ReadInteger('ButtonBar', 'ButtonHeight', 16);
  gToolBarIconSize := gIni.ReadInteger('ButtonBar', 'SmallIconSize', 16);
  gDriveBar1 := gIni.ReadBool('Layout', 'DriveBar1', True);
  gDriveBar2 := gIni.ReadBool('Layout', 'DriveBar2', True);
  gDriveBarFlat := gIni.ReadBool('Layout', 'DriveBarFlat', True);
  gDrivesListButton := gIni.ReadBool('Layout', 'DriveMenuButton', True);
  gDirectoryTabs := gIni.ReadBool('Layout', 'DirectoryTabs', True);
  gCurDir := gIni.ReadBool('Layout', 'CurDir', True);
  gTabHeader := gIni.ReadBool('Layout', 'TabHeader', True);
  gStatusBar := gIni.ReadBool('Layout', 'StatusBar', True);
  gCmdLine := gIni.ReadBool('Layout', 'CmdLine', True);
  gLogWindow := gIni.ReadBool('Layout', 'LogWindow', True);
  gTermWindow := gIni.ReadBool('Layout', 'TermWindow', False);
  gKeyButtons := gIni.ReadBool('Layout', 'KeyButtons', True);
  gInterfaceFlat := gIni.ReadBool('Layout', 'InterfaceFlat', True);

  gShowSystemFiles := gIni.ReadBool('Configuration', 'ShowSystemFiles', False);
  gPOFileName := gIni.ReadString('Configuration', 'Language', '?');

  DoLoadLng;

  gRunInTermStayOpenCmd := gIni.ReadString('Configuration', 'RunInTerm', gRunInTermStayOpenCmd);
  gOnlyOneAppInstance:= gIni.ReadBool('Configuration', 'OnlyOnce', False);
  if gIni.ReadBool('Configuration', 'CaseSensitiveSort', False) = False then
    gSortCaseSensitivity := cstNotSensitive
  else
    gSortCaseSensitivity := cstLocale;
  gLynxLike := gIni.ReadBool('Configuration', 'LynxLike', True);
  if gIni.ValueExists('Configuration', 'ShortFileSizeFormat') then
  begin
    if gIni.ReadBool('Configuration', 'ShortFileSizeFormat', True) then
      gFileSizeFormat := fsfFloat
    else
      gFileSizeFormat := fsfB;
  end
  else
    gFileSizeFormat := TFileSizeFormat(gIni.ReadInteger('Configuration', 'FileSizeFormat', Ord(fsfFloat)));
  gScrollMode := TScrollMode(gIni.ReadInteger('Configuration', 'ScrollMode', Integer(gScrollMode)));
  gMinimizeToTray := gIni.ReadBool('Configuration', 'MinimizeToTray', False);
  gAlwaysShowTrayIcon := gIni.ReadBool('Configuration', 'AlwaysShowTrayIcon', False);
  gDateTimeFormat := GetValidDateTimeFormat(gIni.ReadString('Configuration', 'DateTimeFormat', DefaultDateTimeFormat), DefaultDateTimeFormat);
  gDriveBlackList:= gIni.ReadString('Configuration', 'DriveBlackList', '');
  gSpaceMovesDown := gIni.ReadBool('Configuration', 'SpaceMovesDown', False);

  {$IFNDEF LCLCARBON}
  // Under Mac OS X loading file list in separate thread are very very slow
  // so disable and hide this option under Mac OS X Carbon
  gListFilesInThread := gIni.ReadBool('Configuration', 'ListFilesInThread', gListFilesInThread);
  {$ENDIF}
  gLoadIconsSeparately := gIni.ReadBool('Configuration', 'LoadIconsSeparately', gLoadIconsSeparately);

  gMouseSelectionEnabled:= gIni.ReadBool('Configuration', 'MouseSelectionEnabled', True);
  gMouseSelectionButton := gIni.ReadInteger('Configuration', 'MouseSelectionButton', 0);

  gAutoFillColumns:= gIni.ReadBool('Configuration', 'AutoFillColumns', False);
  gAutoSizeColumn := gIni.ReadInteger('Configuration', 'AutoSizeColumn', 1);
  gCustomColumnsChangeAllColumns := gIni.ReadBool('Configuration', 'CustomColumnsChangeAllColumns', gCustomColumnsChangeAllColumns);

  // Loading tabs relating option respecting legacy order of options setting and wanted default values.
  // The legacy default choice will still be to close on double click if it was set to that before. But if it was not, let's set to Favorite Tabs, then, by default of first start of new version.
  gDirTabOptions := TTabsOptions(gIni.ReadInteger('Configuration', 'DirTabOptions', Integer(gDirTabOptions)))+[tb_close_on_doubleclick, tb_reusing_tab_when_possible, tb_confirm_close_locked_tab];
  gDirTabLimit :=  gIni.ReadInteger('Configuration', 'DirTabLimit', 32);
  gDirTabPosition := TTabsPosition(gIni.ReadInteger('Configuration', 'DirTabPosition', Integer(gDirTabPosition)));
  gDirTabActionOnDoubleClick := tadc_CloseTab;

  gExternalTools[etEditor].Enabled := gIni.ReadBool('Configuration', 'UseExtEdit', False);
  gExternalTools[etViewer].Enabled := gIni.ReadBool('Configuration', 'UseExtView', False);
  gExternalTools[etDiffer].Enabled := gIni.ReadBool('Configuration', 'UseExtDiff', False);
  gExternalTools[etEditor].Path := gIni.ReadString('Configuration', 'ExtEdit', '');
  gExternalTools[etViewer].Path := gIni.ReadString('Configuration', 'ExtView', '');
  gExternalTools[etDiffer].Path := gIni.ReadString('Configuration', 'ExtDiff', '');

  gRunTermCmd := gIni.ReadString('Configuration', 'RunTerm', RunTermCmd);

  gLuaLib:=gIni.ReadString('Configuration', 'LuaLib', gLuaLib);

  { Fonts }
  gFonts[dcfMain].Name:=gIni.ReadString('Configuration', 'Font.Name', 'default');
  gFonts[dcfEditor].Name:=gIni.ReadString('Editor', 'Font.Name', MonoSpaceFont);
  gFonts[dcfViewer].Name:=gIni.ReadString('Viewer', 'Font.Name', MonoSpaceFont);
  gFonts[dcfMain].Size:=gIni.ReadInteger('Configuration', 'Font.Size', 10);
  gFonts[dcfEditor].Size:=gIni.ReadInteger('Editor', 'Font.Size', 14);
  gFonts[dcfViewer].Size:=gIni.ReadInteger('Viewer', 'Font.Size', 14);
  gFonts[dcfMain].Style := TFontStyles(gIni.ReadInteger('Configuration', 'Font.Style', 1));
  gFonts[dcfEditor].Style := TFontStyles(gIni.ReadInteger('Editor', 'Font.Style', 0));
  gFonts[dcfViewer].Style := TFontStyles(gIni.ReadInteger('Viewer', 'Font.Style', 0));

  { Colors }
  gUseCursorBorder := gIni.ReadBool('(Colors', 'UseCursorBorder', gUseCursorBorder);
  gCursorBorderColor := gIni.ReadInteger('Colors', 'CursorBorderColor', gCursorBorderColor);
  gUseFrameCursor := gIni.ReadBool('Colors', 'UseFrameCursor', gUseFrameCursor);
  gForeColor  := gIni.ReadInteger('Colors', 'ForeColor', gForeColor);
  gBackColor := gIni.ReadInteger('Colors', 'BackColor', gBackColor);
  gBackColor2 := gIni.ReadInteger('Colors', 'BackColor2', gBackColor2);
  gMarkColor := gIni.ReadInteger('Colors', 'MarkColor', gMarkColor);
  gCursorColor := gIni.ReadInteger('Colors', 'CursorColor', gCursorColor);
  gCursorText := gIni.ReadInteger('Colors', 'CursorText', gCursorText);
  gInactiveCursorColor := gIni.ReadInteger('Colors', 'InactiveCursorColor', gInactiveCursorColor);
  gInactiveMarkColor := gIni.ReadInteger('Colors', 'InactiveMarkColor', gInactiveMarkColor);
  gUseInvertedSelection := gIni.ReadBool('Colors', 'UseInvertedSelection', gUseInvertedSelection);
  gUseInactiveSelColor := gIni.ReadBool('Colors', 'UseInactiveSelColor', gUseInactiveSelColor);
  gAllowOverColor := gIni.ReadBool('Colors', 'AllowOverColor', gAllowOverColor);
  gInactivePanelBrightness := gIni.ReadInteger('Colors', 'InactivePanelBrightness', gInactivePanelBrightness);

  { File operations }
  gCopyBlockSize := gIni.ReadInteger('Configuration', 'CopyBlockSize', 65536);
  gSkipFileOpError:= gIni.ReadBool('Configuration', 'SkipFileOpError', False);
  gDropReadOnlyFlag := gIni.ReadBool('Configuration', 'DropReadOnlyFlag', True);
  gUseMmapInSearch := gIni.ReadBool('Configuration', 'UseMmapInSearch', False);
  gWipePassNumber:= gIni.ReadInteger('Configuration', 'WipePassNumber', 1);
  gProcessComments := gIni.ReadBool('Configuration', 'ProcessComments', True);
  gRenameSelOnlyName:= gIni.ReadBool('Configuration', 'RenameSelOnlyName', false);
  gShowCopyTabSelectPanel:= gIni.ReadBool('Configuration', 'ShowCopyTabSelectPanel', false);
  gUseTrash := gIni.ReadBool('Configuration', 'UseTrash', True); // 05.05.2009 - read global trash option from configuration file
  gShowDialogOnDragDrop := gIni.ReadBool('Configuration', 'ShowDialogOnDragDrop', gShowDialogOnDragDrop);

  { Log }
  gLogFile := gIni.ReadBool('Configuration', 'LogFile', True);
  gLogFileWithDateInName := gIni. ReadBool('Configuration', 'LogFileWithDateInName', FALSE);
  gLogFileName := gIni.ReadString('Configuration', 'LogFileName', gLogFileName);
  gLogOptions := TLogOptions(gIni.ReadInteger('Configuration', 'LogOptions', Integer(gLogOptions)));
  { Configuration page }
  gSaveDirHistory := gIni.ReadBool('Configuration', 'SaveDirHistory', True);
  gSaveCmdLineHistory := gIni.ReadBool('Configuration', 'SaveCmdLineHistory', True);
  gSaveFileMaskHistory := gIni.ReadBool('Configuration', 'SaveFileMaskHistory', True);
  { Quick Search page}
  oldQuickSearch := gIni.ReadBool('Configuration', 'QuickSearch', oldQuickSearch);
  oldQuickSearchMode := TShiftState(gIni.ReadInteger('Configuration', 'QuickSearchMode', Integer(oldQuickSearchMode)));
  OldKeysToNew(oldQuickSearch, oldQuickSearchMode, ktaQuickSearch);
  oldQuickFilter := gIni.ReadBool('Configuration', 'QuickFilter', oldQuickFilter);
  oldQuickFilterMode := TShiftState(gIni.ReadInteger('Configuration', 'QuickFilterMode', Integer(oldQuickFilterMode)));
  OldKeysToNew(oldQuickFilter, oldQuickFilterMode, ktaQuickFilter);
  if gIni.ReadBool('Configuration', 'QuickSearchMatchBeginning', qsmBeginning in gQuickSearchOptions.Match) then
    Include(gQuickSearchOptions.Match, qsmBeginning)
  else
    Exclude(gQuickSearchOptions.Match, qsmBeginning);
  if gIni.ReadBool('Configuration', 'QuickSearchMatchEnding', qsmEnding in gQuickSearchOptions.Match) then
    Include(gQuickSearchOptions.Match, qsmEnding)
  else
    Exclude(gQuickSearchOptions.Match, qsmEnding);
  { Misc page }
  gGridVertLine:= gIni.ReadBool('Configuration', 'GridVertLine', False);
  gGridHorzLine:= gIni.ReadBool('Configuration', 'GridHorzLine', False);
  gShowWarningMessages := gIni.ReadBool('Configuration', 'ShowWarningMessages', True);
  gDirBrackets:= gIni.ReadBool('Configuration', 'DirBrackets', True);
  gShowToolTipMode:= gIni.ReadBool('Configuration', 'ShowToolTipMode', gShowToolTipMode);
  { Auto refresh page }
  gWatchDirs := TWatchOptions(gIni.ReadInteger('Configuration', 'WatchDirs', Integer(gWatchDirs)));
  gWatchDirsExclude := gIni.ReadString('Configuration', 'WatchDirsExclude', '');
  { Icons page }
  gShowIcons := TShowIconsMode(gIni.ReadInteger('Configuration', 'ShowIcons', Integer(gShowIcons)));
  gIconOverlays:= gIni.ReadBool('Configuration', 'IconOverlays', True);
  gIconsSize := gIni.ReadInteger('Configuration', 'IconsSize', 16);
  gCustomDriveIcons := gIni.ReadBool('Configuration', 'CustomDriveIcons', False);
  { Ignore list page }
  gIgnoreListFileEnabled:= gIni.ReadBool('Configuration', 'IgnoreListFileEnabled', False);
  gIgnoreListFile:= gIni.ReadString('Configuration', 'IgnoreListFile', gIgnoreListFile);

  gCutTextToColWidth := gIni.ReadBool('Configuration', 'CutTextToColWidth', True);

  gImageStretch:=  gIni.ReadBool('Viewer', 'Image.Stretch', False);

  { Operations options }
  gOperationOptionSymLinks := TFileSourceOperationOptionSymLink(
                                gIni.ReadInteger('Operations', 'Symlink', Integer(gOperationOptionSymLinks)));
  gOperationOptionCorrectLinks := gIni.ReadBool('Operations', 'CorrectLinks', gOperationOptionCorrectLinks);
  gOperationOptionFileExists := TFileSourceOperationOptionFileExists(
                                  gIni.ReadInteger('Operations', 'FileExists', Integer(gOperationOptionFileExists)));
  gOperationOptionDirectoryExists := TFileSourceOperationOptionDirectoryExists(
                                       gIni.ReadInteger('Operations', 'DirectoryExists', Integer(gOperationOptionDirectoryExists)));
  gOperationOptionCheckFreeSpace := gIni.ReadBool('Operations', 'CheckFreeSpace', gOperationOptionCheckFreeSpace);

  //Let's take the time to do the conversion for those loading from INI file
  { Hot dir }
  glsHotDirTempoLegacyConversion:=TStringListEx.Create;
  gIni.ReadSectionRaw('DirectoryHotList', glsHotDirTempoLegacyConversion);
  for IndexHotDir:=0 to pred(glsHotDirTempoLegacyConversion.Count) do
  begin
    LocalHotDir:=THotDir.Create;
    LocalHotDir.HotDirName:=glsHotDirTempoLegacyConversion.Names[IndexHotDir];
    LocalHotDir.HotDirPath:=glsHotDirTempoLegacyConversion.ValueFromIndex[IndexHotDir];
    LocalHotDir.HotDirTarget:='';
    gDirectoryHotlist.Add(LocalHotDir);
  end;
  FreeAndNil(glsHotDirTempoLegacyConversion); //Thank you, good bye!
  gColorExt.LoadIni;

  { Search template list }
  gSearchTemplateList.LoadFromIni(gIni);

  { Columns sets }
  ColSet.Load(gIni);

  { Plugins }
  gDSXPlugins.Load(gIni);
  gWCXPlugins.Load(gIni);
  gWDXPlugins.Load(gIni);
  gWFXPlugins.Load(gIni);
  gWLXPlugins.Load(gIni);
end;

procedure LoadContentPlugins;
var
  I: Integer;
  Module: TWdxModule;
  Template: TSearchTemplate;
  Content: TPluginSearchRec;
begin
  for I:= 0 to gSearchTemplateList.Count - 1 do
  begin
    Template:= gSearchTemplateList.Templates[I];
    if Template.SearchRecord.ContentPlugin then
    begin
      for Content in Template.SearchRecord.ContentPlugins do
      begin
        Module:= gWDXPlugins.GetWdxModule(Content.Plugin);
        if Assigned(Module) and (Module.IsLoaded = False) then
        begin
          Module.LoadModule;
        end;
      end;
    end;
  end;
end;

procedure LoadXmlConfig;

  procedure GetExtTool(Node: TXmlNode; var ExternalToolOptions: TExternalToolOptions);
  begin
    if Assigned(Node) then
      with ExternalToolOptions do
      begin
        Enabled          := gConfig.GetAttr(Node, 'Enabled', Enabled);
        Path             := gConfig.GetValue(Node, 'Path', Path);
        Parameters       := gConfig.GetValue(Node, 'Parameters', Parameters);
        RunInTerminal    := gConfig.GetValue(Node, 'RunInTerminal', RunInTerminal);
        KeepTerminalOpen := gConfig.GetValue(Node, 'KeepTerminalOpen', KeepTerminalOpen);
      end;
  end;
  procedure GetDCFont(Node: TXmlNode; var FontOptions: TDCFontOptions);
  begin
    if Assigned(Node) then
      gConfig.GetFont(Node, '', FontOptions.Name, FontOptions.Size, Integer(FontOptions.Style), Integer(FontOptions.Quality),
                                FontOptions.Name, FontOptions.Size, Integer(FontOptions.Style), Integer(FontOptions.Quality));
  end;
  procedure LoadOption(Node: TXmlNode; var Options: TDrivesListButtonOptions; Option: TDrivesListButtonOption; AName: String);
  var
    Value: Boolean;
  begin
    if gConfig.TryGetValue(Node, AName, Value) then
    begin
      if Value then
        Include(Options, Option)
      else
        Exclude(Options, Option);
    end;
  end;
var
  Root, Node, SubNode: TXmlNode;
  LoadedConfigVersion: Integer;
  oldQuickSearch: Boolean = True;
  oldQuickFilter: Boolean = False;
  oldQuickSearchMode: TShiftState = [ssCtrl, ssAlt];
  oldQuickFilterMode: TShiftState = [];
  KeyTypingModifier: TKeyTypingModifier;
begin
  with gConfig do
  begin
    Root := gConfig.RootNode;

    { Double Commander Version }
    gPreviousVersion:= GetAttr(Root, 'DCVersion', EmptyStr);
    LoadedConfigVersion := GetAttr(Root, 'ConfigVersion', ConfigVersion);

    { Language page }
    gPOFileName := GetValue(Root, 'Language/POFileName', gPOFileName);

    DoLoadLng;

    { Behaviours page }
    Node := Root.FindNode('Behaviours');
    if Assigned(Node) then
    begin
      gGoToRoot := GetValue(Node, 'GoToRoot', gGoToRoot);

      //Trick to split initial legacy command for terminal
      //  Initial name in config was "RunInTerminal".
      //  If it is still present in config, it means we're running from an older version.
      //  So if it's different than our setting, let's split it to get actual "cmd" and "params".
      //  New version uses "RunInTerminalCloseCmd" from now on.
      //  ALSO, in the case of Windows, installation default was "cmd.exe /K ..." which means Run-and-stayopen
      //        in the case of Unix, installation default was "xterm -e sh -c ..." which means Run-and-close
      //  So because of these two different behavior, transition is done slightly differently.
      {$IF DEFINED(MSWINDOWS)}
      gRunInTermStayOpenCmd := GetValue(Node, 'RunInTerminal', gRunInTermStayOpenCmd);
      if gRunInTermStayOpenCmd<>RunInTermCloseCmd then
      begin
        SplitCmdLineToCmdParams(gRunInTermStayOpenCmd, gRunInTermStayOpenCmd, gRunInTermStayOpenParams);
        if gRunInTermStayOpenParams<>'' then gRunInTermStayOpenParams:=gRunInTermStayOpenParams+' {command}' else gRunInTermStayOpenParams:='{command}';
      end
      else
      begin
        gRunInTermStayOpenCmd := GetValue(Node, 'RunInTerminalStayOpenCmd', RunInTermStayOpenCmd);
        gRunInTermStayOpenParams := GetValue(Node, 'RunInTerminalStayOpenParams', RunInTermStayOpenParams);
      end;
      gRunInTermCloseCmd := GetValue(Node, 'RunInTerminalCloseCmd', RunInTermCloseCmd);
      gRunInTermCloseParams := GetValue(Node, 'RunInTerminalCloseParams', RunInTermCloseParams);
      {$ELSE}
      gRunInTermCloseCmd := GetValue(Node, 'RunInTerminal', gRunInTermCloseCmd);
      if gRunInTermCloseCmd<>RunInTermCloseCmd then
      begin
        SplitCmdLineToCmdParams(gRunInTermCloseCmd, gRunInTermCloseCmd, gRunInTermCloseParams);
        if gRunInTermCloseParams<>'' then gRunInTermCloseParams:=gRunInTermCloseParams+' {command}' else gRunInTermStayOpenParams:='{command}';
      end
      else
      begin
        gRunInTermCloseCmd := GetValue(Node, 'RunInTerminalCloseCmd', RunInTermCloseCmd);
        gRunInTermCloseParams := GetValue(Node, 'RunInTerminalCloseParams', RunInTermCloseParams);
      end;
      gRunInTermStayOpenCmd := GetValue(Node, 'RunInTerminalStayOpenCmd', RunInTermStayOpenCmd);
      gRunInTermStayOpenParams := GetValue(Node, 'RunInTerminalStayOpenParams', RunInTermStayOpenParams);
      {$ENDIF}

      // Let's try to be backward comptible and re-load possible old values for terminal launch command
      gRunTermCmd := GetValue(Node, 'JustRunTerminal', '');
      if gRunTermCmd = '' then
      begin
        gRunTermCmd := GetValue(Node, 'RunTerminal', RunTermCmd);
        SplitCmdLineToCmdParams(gRunTermCmd, gRunTermCmd,gRunTermParams);
      end
      else
      begin
        gRunTermParams := GetValue(Node, 'JustRunTermParams', RunTermParams);
      end;

      gOnlyOneAppInstance := GetValue(Node, 'OnlyOneAppInstance', gOnlyOneAppInstance);
      gLynxLike := GetValue(Node, 'LynxLike', gLynxLike);
      if LoadedConfigVersion < 5 then
      begin
        if GetValue(Node, 'SortCaseSensitive', False) = False then
          gSortCaseSensitivity := cstNotSensitive
        else
          gSortCaseSensitivity := cstLocale;
        gSortNatural := GetValue(Node, 'SortNatural', gSortNatural);
      end;
      if LoadedConfigVersion < 6 then
      begin
        if GetValue(Node, 'ShortFileSizeFormat', True) then
          gFileSizeFormat := fsfFloat
        else
          gFileSizeFormat := fsfB;
      end
      else
      begin
        gFileSizeFormat := TFileSizeFormat(GetValue(Node, 'FileSizeFormat', Ord(gFileSizeFormat)));
      end;
      gMinimizeToTray := GetValue(Node, 'MinimizeToTray', gMinimizeToTray);
      gAlwaysShowTrayIcon := GetValue(Node, 'AlwaysShowTrayIcon', gAlwaysShowTrayIcon);
      gMouseSelectionEnabled := GetAttr(Node, 'Mouse/Selection/Enabled', gMouseSelectionEnabled);
      gMouseSelectionButton := GetValue(Node, 'Mouse/Selection/Button', gMouseSelectionButton);
      gScrollMode := TScrollMode(GetValue(Node, 'Mouse/ScrollMode', Integer(gScrollMode)));
      gWheelScrollLines:= GetValue(Node, 'Mouse/WheelScrollLines', gWheelScrollLines);
      gAutoFillColumns := GetValue(Node, 'AutoFillColumns', gAutoFillColumns);
      gAutoSizeColumn := GetValue(Node, 'AutoSizeColumn', gAutoSizeColumn);
      gDateTimeFormat := GetValidDateTimeFormat(GetValue(Node, 'DateTimeFormat', gDateTimeFormat), DefaultDateTimeFormat);
      gCutTextToColWidth := GetValue(Node, 'CutTextToColumnWidth', gCutTextToColWidth);
      gShowSystemFiles := GetValue(Node, 'ShowSystemFiles', gShowSystemFiles);
      {$IFNDEF LCLCARBON}
      // Under Mac OS X loading file list in separate thread are very very slow
      // so disable and hide this option under Mac OS X Carbon
      gListFilesInThread := GetValue(Node, 'ListFilesInThread', gListFilesInThread);
      {$ENDIF}
      gLoadIconsSeparately := GetValue(Node, 'LoadIconsSeparately', gLoadIconsSeparately);
      gDelayLoadingTabs := GetValue(Node, 'DelayLoadingTabs', gDelayLoadingTabs);
      gHighlightUpdatedFiles := GetValue(Node, 'HighlightUpdatedFiles', gHighlightUpdatedFiles);
      gDriveBlackList := GetValue(Node, 'DriveBlackList', gDriveBlackList);
      gDriveBlackListUnmounted := GetValue(Node, 'DriveBlackListUnmounted', gDriveBlackListUnmounted);
      if LoadedConfigVersion < 8 then begin
        gBriefViewFileExtAligned := GetValue(Node, 'BriefViewFileExtAligned', gBriefViewFileExtAligned);
      end;
    end;

    { Tools page }
    GetExtTool(gConfig.FindNode(Root, 'Tools/Viewer'), gExternalTools[etViewer]);
    GetExtTool(gConfig.FindNode(Root, 'Tools/Editor'), gExternalTools[etEditor]);
    GetExtTool(gConfig.FindNode(Root, 'Tools/Differ'), gExternalTools[etDiffer]);

    { Differ related}
    Node := Root.FindNode('Tools');
    SubNode := FindNode(Node, 'Differ', TRUE);
    gResultingFramePositionAfterCompare := TResultingFramePositionAfterCompare(GetValue(SubNode, 'FramePosAfterComp', Integer(gResultingFramePositionAfterCompare)));

    { Fonts page }
    GetDCFont(gConfig.FindNode(Root, 'Fonts/Main'), gFonts[dcfMain]);
    GetDCFont(gConfig.FindNode(Root, 'Fonts/Editor'), gFonts[dcfEditor]);
    GetDCFont(gConfig.FindNode(Root, 'Fonts/Viewer'), gFonts[dcfViewer]);
    GetDCFont(gConfig.FindNode(Root, 'Fonts/Log'), gFonts[dcfLog]);
    GetDCFont(gConfig.FindNode(Root, 'Fonts/ViewerBook'), gFonts[dcfViewerBook]);
    GetDCFont(gConfig.FindNode(Root, 'Fonts/Console'), gFonts[dcfConsole]);

    { Colors page }
    Node := Root.FindNode('Colors');
    if Assigned(Node) then
    begin
      gUseCursorBorder := GetValue(Node, 'UseCursorBorder', gUseCursorBorder);
      gCursorBorderColor := GetValue(Node, 'CursorBorderColor', gCursorBorderColor);
      gUseFrameCursor := GetValue(Node, 'UseFrameCursor', gUseFrameCursor);
      gForeColor := GetValue(Node, 'Foreground', gForeColor);
      gBackColor := GetValue(Node, 'Background', gBackColor);
      gBackColor2 := GetValue(Node, 'Background2', gBackColor2);
      gMarkColor := GetValue(Node, 'Mark', gMarkColor);
      gCursorColor := GetValue(Node, 'Cursor', gCursorColor);
      gCursorText := GetValue(Node, 'CursorText', gCursorText);
      gInactiveCursorColor := GetValue(Node, 'InactiveCursor', gInactiveCursorColor);
      gInactiveMarkColor := GetValue(Node, 'InactiveMark', gInactiveMarkColor);
      gUseInvertedSelection := GetValue(Node, 'UseInvertedSelection', gUseInvertedSelection);
      gUseInactiveSelColor := GetValue(Node, 'UseInactiveSelColor', gUseInactiveSelColor);
      gAllowOverColor := GetValue(Node, 'AllowOverColor', gAllowOverColor);

      gInactivePanelBrightness := GetValue(Node, 'InactivePanelBrightness', gInactivePanelBrightness);
      gIndUseGradient := GetValue(Node, 'FreeSpaceIndicator/UseGradient', gIndUseGradient);
      gIndForeColor := GetValue(Node, 'FreeSpaceIndicator/ForeColor', gIndForeColor);
      gIndBackColor := GetValue(Node, 'FreeSpaceIndicator/BackColor', gIndBackColor);
      gColorExt.Load(gConfig, Node);
    end;

    { ToolTips page }
    Node := Root.FindNode('ToolTips');
    if Assigned(Node) then
    begin
      gShowToolTipMode := GetValue(Node, 'ShowToolTipMode', gShowToolTipMode);
      gFileInfoToolTip.Load(gConfig, Node);
    end;

    { Layout page }
    Node := Root.FindNode('Layout');
    if Assigned(Node) then
    begin
      gMainMenu := GetValue(Node, 'MainMenu', gMainMenu);
      SubNode := Node.FindNode('ButtonBar');
      if Assigned(SubNode) then
      begin
        gButtonBar := GetAttr(SubNode, 'Enabled', gButtonBar);
        gToolBarFlat := GetValue(SubNode, 'FlatIcons', gToolBarFlat);
        gToolBarButtonSize := GetValue(SubNode, 'ButtonHeight', gToolBarButtonSize);
        if LoadedConfigVersion <= 1 then
          gToolBarIconSize := GetValue(SubNode, 'SmallIconSize', gToolBarIconSize)
        else
          gToolBarIconSize := GetValue(SubNode, 'IconSize', gToolBarIconSize);
        gToolbarReportErrorWithCommands := GetValue(SubNode,'ReportErrorWithCommands',gToolbarReportErrorWithCommands);
      end;
      gDriveBar1 := GetValue(Node, 'DriveBar1', gDriveBar1);
      gDriveBar2 := GetValue(Node, 'DriveBar2', gDriveBar2);
      gDriveBarFlat := GetValue(Node, 'DriveBarFlat', gDriveBarFlat);
      if LoadedConfigVersion < 3 then
        gDrivesListButton := GetValue(Node, 'DriveMenuButton', gDrivesListButton)
      else
      begin
        SubNode := Node.FindNode('DrivesListButton');
        if Assigned(SubNode) then
        begin
          gDrivesListButton := GetAttr(SubNode, 'Enabled', gDrivesListButton);
          LoadOption(SubNode, gDrivesListButtonOptions, dlbShowLabel, 'ShowLabel');
          LoadOption(SubNode, gDrivesListButtonOptions, dlbShowFileSystem, 'ShowFileSystem');
          LoadOption(SubNode, gDrivesListButtonOptions, dlbShowFreeSpace, 'ShowFreeSpace');
        end;
      end;
      gSeparateTree := GetValue(Node, 'SeparateTree', gSeparateTree);
      gDirectoryTabs := GetValue(Node, 'DirectoryTabs', gDirectoryTabs);
      gCurDir := GetValue(Node, 'CurrentDirectory', gCurDir);
      gTabHeader := GetValue(Node, 'TabHeader', gTabHeader);
      gStatusBar := GetValue(Node, 'StatusBar', gStatusBar);
      gCmdLine := GetValue(Node, 'CmdLine', gCmdLine);
      gLogWindow := GetValue(Node, 'LogWindow', gLogWindow);
      gTermWindow := GetValue(Node, 'TermWindow', gTermWindow);
      gKeyButtons := GetValue(Node, 'KeyButtons', gKeyButtons);
      gInterfaceFlat := GetValue(Node, 'InterfaceFlat', gInterfaceFlat);
      gDriveFreeSpace := GetValue(Node, 'DriveFreeSpace', gDriveFreeSpace);
      gDriveInd := GetValue(Node, 'DriveIndicator', gDriveInd);
      gProgInMenuBar := GetValue(Node, 'ProgressInMenuBar', gProgInMenuBar);
      gPanelOfOp := GetValue(Node, 'PanelOfOperationsInBackground', gPanelOfOp);
      gHorizontalFilePanels := GetValue(Node, 'HorizontalFilePanels', gHorizontalFilePanels);
      gShortFormatDriveInfo := GetValue(Node, 'ShortFormatDriveInfo', gShortFormatDriveInfo);
    end;

    { Files views }
    Node := Root.FindNode('FilesViews');
    if Assigned(Node) then
    begin
      SubNode := Node.FindNode('Sorting');
      if Assigned(SubNode) then
      begin
        gSortCaseSensitivity := TCaseSensitivity(GetValue(SubNode, 'CaseSensitivity', Integer(gSortCaseSensitivity)));
        gSortNatural := GetValue(SubNode, 'NaturalSorting', gSortNatural);
        gSortFolderMode:= TSortFolderMode(GetValue(SubNode, 'SortFolderMode', Integer(gSortFolderMode)));
        gNewFilesPosition := TNewFilesPosition(GetValue(SubNode, 'NewFilesPosition', Integer(gNewFilesPosition)));
        gUpdatedFilesPosition := TUpdatedFilesPosition(GetValue(SubNode, 'UpdatedFilesPosition', Integer(gUpdatedFilesPosition)));
      end;
      SubNode := FindNode(Node, 'ColumnsView');
      if Assigned(SubNode) then
      begin
        gColumnsAutoSaveWidth := GetValue(SubNode, 'AutoSaveWidth', gColumnsAutoSaveWidth);
        gColumnsTitleStyle := TTitleStyle(GetValue(SubNode, 'TitleStyle', Integer(gColumnsTitleStyle)));
      end;
      SubNode := Node.FindNode('BriefView');
      if Assigned(SubNode) then
      begin
        gBriefViewFileExtAligned := GetValue(SubNode, 'FileExtAligned', gBriefViewFileExtAligned);
        SubNode := SubNode.FindNode('Columns');
        if Assigned(SubNode) then
        begin
          gBriefViewFixedWidth := GetValue(SubNode, 'FixedWidth', gBriefViewFixedWidth);
          gBriefViewFixedCount := GetValue(SubNode, 'FixedCount', gBriefViewFixedCount);
          gBriefViewMode := TBriefViewMode(GetValue(SubNode, 'AutoSize', Integer(gBriefViewMode)));
        end;
      end;
    end;

    { Keys page }
    Node := Root.FindNode('Keyboard');
    if Assigned(Node) then
    begin
      SubNode := FindNode(Node, 'Typing/Actions');
      if Assigned(SubNode) then
      begin
        for KeyTypingModifier in TKeyTypingModifier do
          gKeyTyping[KeyTypingModifier] := TKeyTypingAction(GetValue(SubNode,
            TKeyTypingModifierToNodeName[KeyTypingModifier], Integer(gKeyTyping[KeyTypingModifier])));
      end;
    end;

    { File operations page }
    Node := Root.FindNode('FileOperations');
    if Assigned(Node) then
    begin
      gCopyBlockSize := GetValue(Node, 'BufferSize', gCopyBlockSize);
      gHashBlockSize := GetValue(Node, 'HashBufferSize', gHashBlockSize);
      gUseMmapInSearch := GetValue(Node, 'UseMmapInSearch', gUseMmapInSearch);
      gPartialNameSearch := GetValue(Node, 'PartialNameSearch', gPartialNameSearch);
      gWipePassNumber := GetValue(Node, 'WipePassNumber', gWipePassNumber);
      gDropReadOnlyFlag := GetValue(Node, 'DropReadOnlyFlag', gDropReadOnlyFlag);
      gProcessComments := GetValue(Node, 'ProcessComments', gProcessComments);
      gRenameSelOnlyName := GetValue(Node, 'RenameSelOnlyName', gRenameSelOnlyName);
      gShowCopyTabSelectPanel := GetValue(Node, 'ShowCopyTabSelectPanel', gShowCopyTabSelectPanel);
      gUseTrash := GetValue(Node, 'UseTrash', gUseTrash);
      gSkipFileOpError := GetValue(Node, 'SkipFileOpError', gSkipFileOpError);
      gTypeOfDuplicatedRename := tDuplicatedRename(GetValue(Node, 'TypeOfDuplicatedRename', Integer(gTypeOfDuplicatedRename)));
      gShowDialogOnDragDrop := GetValue(Node, 'ShowDialogOnDragDrop', gShowDialogOnDragDrop);
      gDragAndDropDesiredTextFormat[DropTextRichText_Index].DesireLevel := GetValue(Node, 'DragAndDropTextRichtextDesireLevel', gDragAndDropDesiredTextFormat[DropTextRichText_Index].DesireLevel);
      gDragAndDropDesiredTextFormat[DropTextHtml_Index].DesireLevel := GetValue(Node, 'DragAndDropTextHtmlDesireLevel',gDragAndDropDesiredTextFormat[DropTextHtml_Index].DesireLevel);
      gDragAndDropDesiredTextFormat[DropTextUnicode_Index].DesireLevel := GetValue(Node, 'DragAndDropTextUnicodeDesireLevel',gDragAndDropDesiredTextFormat[DropTextUnicode_Index].DesireLevel);
      gDragAndDropDesiredTextFormat[DropTextSimpleText_Index].DesireLevel := GetValue(Node, 'DragAndDropTextSimpletextDesireLevel',gDragAndDropDesiredTextFormat[DropTextSimpleText_Index].DesireLevel);
      gDragAndDropAskFormatEachTime := GetValue(Node,'DragAndDropAskFormatEachTime', gDragAndDropAskFormatEachTime);
      gDragAndDropTextAutoFilename := GetValue(Node, 'DragAndDropTextAutoFilename', gDragAndDropTextAutoFilename);
      gDragAndDropSaveUnicodeTextInUFT8 := GetValue(Node, 'DragAndDropSaveUnicodeTextInUFT8', gDragAndDropSaveUnicodeTextInUFT8);
      gOverwriteFolder := GetValue(Node, 'OverwriteFolder', gOverwriteFolder);
      gNtfsHourTimeDelay := GetValue(Node, 'NtfsHourTimeDelay', gNtfsHourTimeDelay);
      gSearchDefaultTemplate := GetValue(Node, 'SearchDefaultTemplate', gSearchDefaultTemplate);
      gFileOperationsProgressKind := TFileOperationsProgressKind(GetValue(Node, 'ProgressKind', Integer(gFileOperationsProgressKind)));
      gFileOperationsConfirmations := TFileOperationsConfirmations(GetValue(Node, 'Confirmations', Integer(gFileOperationsConfirmations)));
      // Operations options
      SubNode := Node.FindNode('Options');
      if Assigned(SubNode) then
      begin
        gOperationOptionSymLinks := TFileSourceOperationOptionSymLink(GetValue(SubNode, 'Symlink', Integer(gOperationOptionSymLinks)));
        gOperationOptionCorrectLinks := GetValue(SubNode, 'CorrectLinks', gOperationOptionCorrectLinks);
        gOperationOptionFileExists := TFileSourceOperationOptionFileExists(GetValue(SubNode, 'FileExists', Integer(gOperationOptionFileExists)));
        gOperationOptionDirectoryExists := TFileSourceOperationOptionDirectoryExists(GetValue(SubNode, 'DirectoryExists', Integer(gOperationOptionDirectoryExists)));
        gOperationOptionSetPropertyError := TFileSourceOperationOptionSetPropertyError(GetValue(SubNode, 'SetPropertyError', Integer(gOperationOptionSetPropertyError)));
        gOperationOptionReserveSpace := GetValue(SubNode, 'ReserveSpace', gOperationOptionReserveSpace);
        gOperationOptionCheckFreeSpace := GetValue(SubNode, 'CheckFreeSpace', gOperationOptionCheckFreeSpace);
        gOperationOptionCopyAttributes := GetValue(SubNode, 'CopyAttributes', gOperationOptionCopyAttributes);
        gOperationOptionCopyTime := GetValue(SubNode, 'CopyTime', gOperationOptionCopyTime);
        gOperationOptionCopyOwnership := GetValue(SubNode, 'CopyOwnership', gOperationOptionCopyOwnership);
        gOperationOptionCopyPermissions := GetValue(SubNode, 'CopyPermissions', gOperationOptionCopyPermissions);
      end;
    end;

    { Tabs page }
    Node := Root.FindNode('Tabs');
    if Assigned(Node) then
    begin
      // Loading tabs relating option respecting legacy order of options setting and wanted default values.
      // The default action on double click is to close tab simply to respect legacy of what it was doing hardcoded before.
      gDirTabOptions := TTabsOptions(GetValue(Node, 'Options', Integer(gDirTabOptions)));
      if LoadedConfigVersion<9 then
      begin
        gDirTabOptions := gDirTabOptions + [tb_close_on_doubleclick , tb_reusing_tab_when_possible, tb_confirm_close_locked_tab]; //The "tb_close_on_doubleclick" is useless but anyway... :-)
        gDirTabActionOnDoubleClick:=tadc_CloseTab;
      end;
      gDirTabLimit := GetValue(Node, 'CharacterLimit', gDirTabLimit);
      gDirTabPosition := TTabsPosition(GetValue(Node, 'Position', Integer(gDirTabPosition)));
      gDirTabActionOnDoubleClick := TTabsOptionsDoubleClick(GetValue(Node, 'ActionOnDoubleClick', Integer(tadc_CloseTab)));
    end;

    { Log page }
    Node := Root.FindNode('Log');
    if Assigned(Node) then
    begin
      gLogFile := GetAttr(Node, 'Enabled', gLogFile);
      gLogFileWithDateInName := GetAttr(Node, 'LogFileWithDateInName', gLogFileWithDateInName);
      gLogFileName := GetValue(Node, 'FileName', gLogFileName);
      gLogOptions := TLogOptions(GetValue(Node, 'Options', Integer(gLogOptions)));
    end;

    { Configuration page }
    gSaveConfiguration := GetAttr(Root, 'Configuration/Save', gSaveConfiguration);
    gSaveSearchReplaceHistory:= GetAttr(Root, 'History/SearchReplaceHistory/Save', gSaveSearchReplaceHistory);
    gSaveDirHistory := GetAttr(Root, 'History/DirHistory/Save', gSaveDirHistory);
    gSaveCmdLineHistory := GetAttr(Root, 'History/CmdLineHistory/Save', gSaveCmdLineHistory);
    gSaveFileMaskHistory := GetAttr(Root, 'History/FileMaskHistory/Save', gSaveFileMaskHistory);
    gSortOrderOfConfigurationOptionsTree := TSortConfigurationOptions(GetAttr(Root, 'Configuration/SortOrder', Integer(scoClassicLegacy)));

    { Quick Search/Filter page }
    Node := Root.FindNode('QuickSearch');
    if Assigned(Node) then
    begin
      if LoadedConfigVersion < 4 then
      begin
        oldQuickSearch := GetAttr(Node, 'Enabled', oldQuickSearch);
        oldQuickSearchMode := TShiftState(GetValue(Node, 'Mode', Integer(oldQuickSearchMode)));
        OldKeysToNew(oldQuickSearch, oldQuickSearchMode, ktaQuickSearch);
      end;
      if GetValue(Node, 'MatchBeginning', qsmBeginning in gQuickSearchOptions.Match) then
        Include(gQuickSearchOptions.Match, qsmBeginning)
      else
        Exclude(gQuickSearchOptions.Match, qsmBeginning);
      if GetValue(Node, 'MatchEnding', qsmEnding in gQuickSearchOptions.Match) then
        Include(gQuickSearchOptions.Match, qsmEnding)
      else
        Exclude(gQuickSearchOptions.Match, qsmEnding);
      gQuickSearchOptions.SearchCase := TQuickSearchCase(GetValue(Node, 'Case', Integer(gQuickSearchOptions.SearchCase)));
      gQuickSearchOptions.Items := TQuickSearchItems(GetValue(Node, 'Items', Integer(gQuickSearchOptions.Items)));
    end;
    Node := Root.FindNode('QuickFilter');
    if Assigned(Node) then
    begin
      if LoadedConfigVersion < 4 then
      begin
        oldQuickFilter := GetAttr(Node, 'Enabled', oldQuickFilter);
        oldQuickFilterMode := TShiftState(GetValue(Node, 'Mode', Integer(oldQuickFilterMode)));
        OldKeysToNew(oldQuickFilter, oldQuickFilterMode, ktaQuickFilter);
      end;
      gQuickFilterAutoHide := GetValue(Node, 'AutoHide', gQuickFilterAutoHide);
      gQuickFilterSaveSessionModifications := GetValue(Node, 'SaveSessionModifications', gQuickFilterSaveSessionModifications);
    end;

    { Miscellaneous page }
    Node := Root.FindNode('Miscellaneous');
    if Assigned(Node) then
    begin
      gGridVertLine := GetValue(Node, 'GridVertLine', gGridVertLine);
      gGridHorzLine := GetValue(Node, 'GridHorzLine', gGridHorzLine);
      gShowWarningMessages := GetValue(Node, 'ShowWarningMessages', gShowWarningMessages);
      gSpaceMovesDown := GetValue(Node, 'SpaceMovesDown', gSpaceMovesDown);
      gDirBrackets := GetValue(Node, 'DirBrackets', gDirBrackets);
      gInplaceRename := GetValue(Node, 'InplaceRename', gInplaceRename);
      gHotDirAddTargetOrNot:=GetValue(Node, 'HotDirAddTargetOrNot', gHotDirAddTargetOrNot);
      gHotDirFullExpandOrNot:=GetValue(Node, 'HotDirFullExpandOrNot', gHotDirFullExpandOrNot);
      gShowPathInPopup:=GetValue(Node, 'ShowPathInPopup', gShowPathInPopup);
      gShowOnlyValidEnv:=GetValue(Node, 'ShowOnlyValidEnv', gShowOnlyValidEnv);
      gWhereToAddNewHotDir:=TPositionWhereToAddHotDir(GetValue(Node, 'WhereToAddNewHotDir', Integer(gWhereToAddNewHotDir)));
    end;

    { Thumbnails }
    Node := Root.FindNode('Thumbnails');
    if Assigned(Node) then
    begin
      gThumbSave := GetAttr(Node, 'Save', gThumbSave);
      gThumbSize.cx := GetValue(Node, 'Width', gThumbSize.cx);
      gThumbSize.cy := GetValue(Node, 'Height', gThumbSize.cy);
    end;

    { Auto refresh page }
    Node := Root.FindNode('AutoRefresh');
    if Assigned(Node) then
    begin
      gWatchDirs := TWatchOptions(GetValue(Node, 'Options', Integer(gWatchDirs)));
      gWatchDirsExclude := GetValue(Node, 'ExcludeDirs', gWatchDirsExclude);
      gWatcherMode := TWatcherMode(GetValue(Node, 'Mode', Integer(gWatcherMode)));
    end;

    { Icons page }
    Node := Root.FindNode('Icons');
    if Assigned(Node) then
    begin
      gShowIcons := TShowIconsMode(GetValue(Node, 'ShowMode', Integer(gShowIcons)));
      gIconOverlays := GetValue(Node, 'ShowOverlays', gIconOverlays);
      gIconsSize := GetValue(Node, 'Size', gIconsSize);
      gIconsExclude := GetValue(Node, 'Exclude', gIconsExclude);
      gIconsExcludeDirs := GetValue(Node, 'ExcludeDirs', gIconsExcludeDirs);
      gCustomDriveIcons := GetValue(Node, 'CustomDriveIcons', gCustomDriveIcons);
      gIconsInMenus := GetAttr(Node, 'ShowInMenus/Enabled', gIconsInMenus);
      gIconsInMenusSize := GetValue(Node, 'ShowInMenus/Size', gIconsInMenusSize);
    end;

    { Ignore list page }
    Node := Root.FindNode('IgnoreList');
    if Assigned(Node) then
    begin
      gIgnoreListFileEnabled:= GetAttr(Node, 'Enabled', gIgnoreListFileEnabled);
      gIgnoreListFile:= GetValue(Node, 'IgnoreListFile', gIgnoreListFile);
    end;

    { Directories HotList }
    gDirectoryHotlist.LoadFromXML(gConfig, Root);

    { Viewer }
    Node := Root.FindNode('Viewer');
    if Assigned(Node) then
    begin
      gImageStretch := GetValue(Node, 'ImageStretch', gImageStretch);
      gImageStretchOnlyLarge := GetValue(Node, 'ImageStretchLargeOnly', gImageStretchOnlyLarge);
      gImageCenter := GetValue(Node, 'ImageCenter', gImageCenter);
      gPreviewVisible := GetValue(Node, 'PreviewVisible', gPreviewVisible);
      gCopyMovePath1 := GetValue(Node, 'CopyMovePath1', gCopyMovePath1);
      gCopyMovePath2 := GetValue(Node, 'CopyMovePath2', gCopyMovePath2);
      gCopyMovePath3 := GetValue(Node, 'CopyMovePath3', gCopyMovePath3);
      gCopyMovePath4 := GetValue(Node, 'CopyMovePath4', gCopyMovePath4);
      gCopyMovePath5 := GetValue(Node, 'CopyMovePath5', gCopyMovePath5);
      gImagePaintMode := GetValue(Node, 'PaintMode', gImagePaintMode);
      gImagePaintWidth := GetValue(Node, 'PaintWidth', gImagePaintWidth);
      gColCount := GetValue(Node, 'NumberOfColumns', gColCount);
      gViewerMode := GetValue(Node, 'ViewerMode', gViewerMode);
      gImagePaintColor := GetValue(Node, 'PaintColor', gImagePaintColor);
      gBookBackgroundColor := GetValue(Node, 'BackgroundColor', gBookBackgroundColor);
      gBookFontColor := GetValue(Node, 'FontColor', gBookFontColor);
      gTextPosition := GetValue(Node, 'TextPosition',  gTextPosition);
      if LoadedConfigVersion < 7 then
      begin
        gThumbSave := GetValue(Node, 'SaveThumbnails', gThumbSave);
      end;
    end;

    { Editor }
    Node := Root.FindNode('Editor');
    if Assigned(Node) then
    begin
      gEditWaitTime := GetValue(Node, 'EditWaitTime', gEditWaitTime);
      gEditorSynEditOptions := TSynEditorOptions(GetValue(Node, 'SynEditOptions', Integer(gEditorSynEditOptions)));
    end;

    { SyncDirs }
    Node := Root.FindNode('SyncDirs');
    if Assigned(Node) then
    begin
      gSyncDirsSubdirs := GetValue(Node, 'Subdirs', gSyncDirsSubdirs);
      gSyncDirsByContent := GetValue(Node, 'ByContent', gSyncDirsByContent);
      gSyncDirsIgnoreDate := GetValue(Node, 'IgnoreDate', gSyncDirsIgnoreDate);
      gSyncDirsShowFilterCopyRight := GetValue(Node, 'FilterCopyRight', gSyncDirsShowFilterCopyRight);
      gSyncDirsShowFilterEqual := GetValue(Node, 'FilterEqual', gSyncDirsShowFilterEqual);
      gSyncDirsShowFilterNotEqual := GetValue(Node, 'FilterNotEqual', gSyncDirsShowFilterNotEqual);
      gSyncDirsShowFilterCopyLeft := GetValue(Node, 'FilterCopyLeft', gSyncDirsShowFilterCopyLeft);
      gSyncDirsShowFilterDuplicates := GetValue(Node, 'FilterDuplicates', gSyncDirsShowFilterDuplicates);
      gSyncDirsShowFilterSingles := GetValue(Node, 'FilterSingles', gSyncDirsShowFilterSingles);
      gSyncDirsFileMask := GetValue(Node, 'FileMask', gSyncDirsFileMask);
    end;

    { Internal Associations}
    Node := Root.FindNode('InternalAssociations');
    if Assigned(Node) then
    begin
      gOfferToAddToFileAssociations := GetValue(Node, 'OfferToAddNewFileType', gOfferToAddToFileAssociations);
      gFileAssociationLastCustomAction := GetValue(Node, 'LastCustomAction', gFileAssociationLastCustomAction);
      gExtendedContextMenu := GetValue(Node, 'ExpandedContextMenu', gExtendedContextMenu);
      gOpenExecuteViaShell := GetValue(Node,'ExecuteViaShell', gOpenExecuteViaShell);
      gExecuteViaTerminalClose := GetValue(Node,'OpenSystemWithTerminalClose', gExecuteViaTerminalClose);
      gExecuteViaTerminalStayOpen := GetValue(Node,'OpenSystemWithTerminalStayOpen', gExecuteViaTerminalStayOpen);
      gIncludeFileAssociation := GetValue(Node,'IncludeFileAssociation',gIncludeFileAssociation);
    end;

    { Favorite Tabs }
    Node := Root.FindNode('FavoriteTabsOptions');
    if Assigned(Node) then
    begin
      gFavoriteTabsUseRestoreExtraOptions := GetValue(Node, 'FavoriteTabsUseRestoreExtraOptions', gFavoriteTabsUseRestoreExtraOptions);
      gWhereToAddNewFavoriteTabs := TPositionWhereToAddFavoriteTabs(GetValue(Node, 'WhereToAdd', Integer(gWhereToAddNewFavoriteTabs)));
      gFavoriteTabsFullExpandOrNot := GetValue(Node, 'Expand', gFavoriteTabsFullExpandOrNot);
      gFavoriteTabsGoToConfigAfterSave := GetValue(Node, 'GotoConfigAftSav', gFavoriteTabsGoToConfigAfterSave);
      gFavoriteTabsGoToConfigAfterReSave := GetValue(Node, 'GotoConfigAftReSav', gFavoriteTabsGoToConfigAfterReSave);
      gDefaultTargetPanelLeftSaved := TTabsConfigLocation(GetValue(Node, 'DfltLeftGoTo', Integer(gDefaultTargetPanelLeftSaved)));
      gDefaultTargetPanelRightSaved := TTabsConfigLocation(GetValue(Node, 'DfltRightGoTo', Integer(gDefaultTargetPanelRightSaved)));
      gDefaultExistingTabsToKeep := TTabsConfigLocation(GetValue(Node, 'DfltKeep', Integer(gDefaultExistingTabsToKeep)));
      gFavoriteTabsSaveDirHistory := GetValue(Node, 'DfltSaveDirHistory', gFavoriteTabsSaveDirHistory);
      gFavoriteTabsList.LastFavoriteTabsLoadedUniqueId := StringToGUID(GetValue(Node,'FavTabsLastUniqueID',GUIDtoString(GetNewUniqueID)));
    end;

    { - Other - }
    gLuaLib := GetValue(Root, 'Lua/PathToLibrary', gLuaLib);
    gNameSCFile:= GetValue(Root, 'NameShortcutFile', gNameSCFile);
    gLastUsedPacker:= GetValue(Root, 'LastUsedPacker', gLastUsedPacker);
    gUseShellForFileOperations:= GetValue(Root, 'UseShellForFileOperations', gUseShellForFileOperations);
    gLastDoAnyCommand:=GetValue(Root, 'LastDoAnyCommand', gLastDoAnyCommand);

    { TotalCommander Import/Export }
    {$IFDEF MSWINDOWS}
    Node := Root.FindNode('TCSection');
    if Assigned(Node) then
    begin
      gTotalCommanderExecutableFilename := GetValue(Node, 'TCExecutableFilename', gTotalCommanderExecutableFilename);
      gTotalCommanderConfigFilename := GetValue(Node, 'TCConfigFilename', gTotalCommanderConfigFilename);
      gTotalCommanderToolbarPath:=GetValue(Node,'TCToolbarPath',gTotalCommanderToolbarPath);
    end;
    {$ENDIF}
  end;

  { Search template list }
  gSearchTemplateList.LoadFromXml(gConfig, Root);

  { Columns sets }
  ColSet.Load(gConfig, Root);

  { Plugins }
  Node := gConfig.FindNode(Root, 'Plugins');
  if Assigned(Node) then
  begin
    gDSXPlugins.Load(gConfig, Node);
    gWCXPlugins.Load(gConfig, Node);
    gWDXPlugins.Load(gConfig, Node);
    gWFXPlugins.Load(gConfig, Node);
    gWLXPlugins.Load(gConfig, Node);
  end;

  { Load content plugins used in search templates }
  LoadContentPlugins;
end;

procedure SaveXmlConfig;

  procedure SetExtTool(Node: TXmlNode; const ExternalToolOptions: TExternalToolOptions);
  begin
    if Assigned(Node) then
      with ExternalToolOptions do
      begin
        gConfig.SetAttr(Node, 'Enabled', Enabled);
        gConfig.SetValue(Node, 'Path', Path);
        gConfig.SetValue(Node, 'Parameters', Parameters);
        gConfig.SetValue(Node, 'RunInTerminal', RunInTerminal);
        gConfig.SetValue(Node, 'KeepTerminalOpen', KeepTerminalOpen);
      end;
  end;
  procedure SetDCFont(Node: TXmlNode; const FontOptions: TDCFontOptions);
  begin
    if Assigned(Node) then
      gConfig.SetFont(Node, '', FontOptions.Name, FontOptions.Size, Integer(FontOptions.Style), Integer(FontOptions.Quality));
  end;
var
  Root, Node, SubNode: TXmlNode;
  KeyTypingModifier: TKeyTypingModifier;
begin
  with gConfig do
  begin
    Root := gConfig.RootNode;

    SetAttr(Root, 'DCVersion', dcVersion);
    SetAttr(Root, 'ConfigVersion', ConfigVersion);

    SetValue(Root, 'Configuration/UseConfigInProgramDir', gUseConfigInProgramDirNew);

    { Language page }
    SetValue(Root, 'Language/POFileName', gPOFileName);

    { Behaviours page }
    Node := FindNode(Root, 'Behaviours', True);
    ClearNode(Node);
    SetValue(Node, 'GoToRoot', gGoToRoot);
    SetValue(Node, 'RunInTerminalStayOpenCmd', gRunInTermStayOpenCmd);
    SetValue(Node, 'RunInTerminalStayOpenParams', gRunInTermStayOpenParams);
    SetValue(Node, 'RunInTerminalCloseCmd', gRunInTermCloseCmd);
    SetValue(Node, 'RunInTerminalCloseParams', gRunInTermCloseParams);
    SetValue(Node, 'JustRunTerminal', gRunTermCmd);
    SetValue(Node, 'JustRunTermParams', gRunTermParams);

    SetValue(Node, 'OnlyOneAppInstance', gOnlyOneAppInstance);
    SetValue(Node, 'LynxLike', gLynxLike);
    SetValue(Node, 'FileSizeFormat', Ord(gFileSizeFormat));
    SetValue(Node, 'MinimizeToTray', gMinimizeToTray);
    SetValue(Node, 'AlwaysShowTrayIcon', gAlwaysShowTrayIcon);
    SubNode := FindNode(Node, 'Mouse', True);
    SetAttr(SubNode, 'Selection/Enabled', gMouseSelectionEnabled);
    SetValue(SubNode, 'Selection/Button', gMouseSelectionButton);
    SetValue(SubNode, 'ScrollMode', Integer(gScrollMode));
    SetValue(SubNode, 'WheelScrollLines', gWheelScrollLines);
    SetValue(Node, 'AutoFillColumns', gAutoFillColumns);
    SetValue(Node, 'AutoSizeColumn', gAutoSizeColumn);
    SetValue(Node, 'CustomColumnsChangeAllColumns', gCustomColumnsChangeAllColumns);
    SetValue(Node, 'BriefViewFileExtAligned', gBriefViewFileExtAligned);
    SetValue(Node, 'DateTimeFormat', gDateTimeFormat);
    SetValue(Node, 'CutTextToColumnWidth', gCutTextToColWidth);
    SetValue(Node, 'ShowSystemFiles', gShowSystemFiles);
    {$IFNDEF LCLCARBON}
    // Under Mac OS X loading file list in separate thread are very very slow
    // so disable and hide this option under Mac OS X Carbon
    SetValue(Node, 'ListFilesInThread', gListFilesInThread);
    {$ENDIF}
    SetValue(Node, 'LoadIconsSeparately', gLoadIconsSeparately);
    SetValue(Node, 'DelayLoadingTabs', gDelayLoadingTabs);
    SetValue(Node, 'HighlightUpdatedFiles', gHighlightUpdatedFiles);
    SetValue(Node, 'DriveBlackList', gDriveBlackList);
    SetValue(Node, 'DriveBlackListUnmounted', gDriveBlackListUnmounted);

    { Tools page }
    SetExtTool(gConfig.FindNode(Root, 'Tools/Viewer', True), gExternalTools[etViewer]);
    SetExtTool(gConfig.FindNode(Root, 'Tools/Editor', True), gExternalTools[etEditor]);
    SetExtTool(gConfig.FindNode(Root, 'Tools/Differ', True), gExternalTools[etDiffer]);

    { Differ related}
    Node := Root.FindNode('Tools');
    SubNode := FindNode(Node, 'Differ', TRUE);
    SetValue(SubNode, 'FramePosAfterComp', Integer(gResultingFramePositionAfterCompare));

    { Fonts page }
    SetDCFont(gConfig.FindNode(Root, 'Fonts/Main', True), gFonts[dcfMain]);
    SetDCFont(gConfig.FindNode(Root, 'Fonts/Editor', True), gFonts[dcfEditor]);
    SetDCFont(gConfig.FindNode(Root, 'Fonts/Viewer', True), gFonts[dcfViewer]);
    SetDCFont(gConfig.FindNode(Root, 'Fonts/Log', True), gFonts[dcfLog]);
    SetDCFont(gConfig.FindNode(Root, 'Fonts/ViewerBook', True), gFonts[dcfViewerBook]);
    SetDCFont(gConfig.FindNode(Root, 'Fonts/Console', True), gFonts[dcfConsole]);

    { Colors page }
    Node := FindNode(Root, 'Colors', True);
    SetValue(Node, 'UseCursorBorder', gUseCursorBorder);
    SetValue(Node, 'CursorBorderColor', gCursorBorderColor);
    SetValue(Node, 'UseFrameCursor', gUseFrameCursor);
    SetValue(Node, 'Foreground', gForeColor);
    SetValue(Node, 'Background', gBackColor);
    SetValue(Node, 'Background2', gBackColor2);
    SetValue(Node, 'Cursor', gCursorColor);
    SetValue(Node, 'CursorText', gCursorText);
    SetValue(Node, 'Mark', gMarkColor);
    SetValue(Node, 'InactiveCursor', gInactiveCursorColor);
    SetValue(Node, 'InactiveMark', gInactiveMarkColor);
    SetValue(Node, 'UseInvertedSelection', gUseInvertedSelection);
    SetValue(Node, 'UseInactiveSelColor', gUseInactiveSelColor);
    SetValue(Node, 'AllowOverColor', gAllowOverColor);

    SetValue(Node, 'InactivePanelBrightness', gInactivePanelBrightness);
    SetValue(Node, 'FreeSpaceIndicator/UseGradient', gIndUseGradient);
    SetValue(Node, 'FreeSpaceIndicator/ForeColor', gIndForeColor);
    SetValue(Node, 'FreeSpaceIndicator/BackColor', gIndBackColor);
    gColorExt.Save(gConfig, Node);

    { ToolTips page }
    Node := FindNode(Root, 'ToolTips', True);
    SetValue(Node, 'ShowToolTipMode', gShowToolTipMode);
    gFileInfoToolTip.Save(gConfig, Node);

    { Layout page }
    Node := FindNode(Root, 'Layout', True);
    ClearNode(Node);
    SetValue(Node, 'MainMenu', gMainMenu);
    SubNode := FindNode(Node, 'ButtonBar', True);
    SetAttr(SubNode, 'Enabled', gButtonBar);
    SetValue(SubNode, 'FlatIcons', gToolBarFlat);
    SetValue(SubNode, 'ButtonHeight', gToolBarButtonSize);
    SetValue(SubNode, 'IconSize', gToolBarIconSize);
    SetValue(SubNode, 'ReportErrorWithCommands', gToolbarReportErrorWithCommands);
    SetValue(Node, 'DriveBar1', gDriveBar1);
    SetValue(Node, 'DriveBar2', gDriveBar2);
    SetValue(Node, 'DriveBarFlat', gDriveBarFlat);
    SubNode := FindNode(Node, 'DrivesListButton', True);
    SetAttr(SubNode, 'Enabled', gDrivesListButton);
    SetValue(SubNode, 'ShowLabel', dlbShowLabel in gDrivesListButtonOptions);
    SetValue(SubNode, 'ShowFileSystem', dlbShowFileSystem in gDrivesListButtonOptions);
    SetValue(SubNode, 'ShowFreeSpace', dlbShowFreeSpace in gDrivesListButtonOptions);
    SetValue(Node, 'SeparateTree', gSeparateTree);
    SetValue(Node, 'DirectoryTabs', gDirectoryTabs);
    SetValue(Node, 'CurrentDirectory', gCurDir);
    SetValue(Node, 'TabHeader', gTabHeader);
    SetValue(Node, 'StatusBar', gStatusBar);
    SetValue(Node, 'CmdLine', gCmdLine);
    SetValue(Node, 'LogWindow', gLogWindow);
    SetValue(Node, 'TermWindow', gTermWindow);
    SetValue(Node, 'KeyButtons', gKeyButtons);
    SetValue(Node, 'InterfaceFlat', gInterfaceFlat);
    SetValue(Node, 'DriveFreeSpace', gDriveFreeSpace);
    SetValue(Node, 'DriveIndicator', gDriveInd);
    SetValue(Node, 'ProgressInMenuBar', gProgInMenuBar);
    SetValue(Node, 'PanelOfOperationsInBackground', gPanelOfOp);
    SetValue(Node, 'HorizontalFilePanels', gHorizontalFilePanels);
    SetValue(Node, 'ShortFormatDriveInfo', gShortFormatDriveInfo);

    { Files views }
    Node := FindNode(Root, 'FilesViews', True);
    SubNode := FindNode(Node, 'Sorting', True);
    SetValue(SubNode, 'CaseSensitivity', Integer(gSortCaseSensitivity));
    SetValue(SubNode, 'NaturalSorting', gSortNatural);
    SetValue(SubNode, 'SortFolderMode', Integer(gSortFolderMode));
    SetValue(SubNode, 'NewFilesPosition', Integer(gNewFilesPosition));
    SetValue(SubNode, 'UpdatedFilesPosition', Integer(gUpdatedFilesPosition));
    SubNode := FindNode(Node, 'ColumnsView', True);
    SetValue(SubNode, 'AutoSaveWidth', gColumnsAutoSaveWidth);
    SetValue(SubNode, 'TitleStyle', Integer(gColumnsTitleStyle));
    SubNode := FindNode(Node, 'BriefView', True);
    SetValue(SubNode, 'FileExtAligned', gBriefViewFileExtAligned);
    SubNode := FindNode(SubNode, 'Columns', True);
    SetValue(SubNode, 'FixedWidth', gBriefViewFixedWidth);
    SetValue(SubNode, 'FixedCount', gBriefViewFixedCount);
    SetValue(SubNode, 'AutoSize', Integer(gBriefViewMode));

    { Keys page }
    Node := FindNode(Root, 'Keyboard', True);
    SubNode := FindNode(Node, 'Typing/Actions', True);
    for KeyTypingModifier in TKeyTypingModifier do
      SetValue(SubNode, TKeyTypingModifierToNodeName[KeyTypingModifier],
        Integer(gKeyTyping[KeyTypingModifier]));

    { File operations page }
    Node := FindNode(Root, 'FileOperations', True);
    SetValue(Node, 'BufferSize', gCopyBlockSize);
    SetValue(Node, 'HashBufferSize', gHashBlockSize);
    SetValue(Node, 'UseMmapInSearch', gUseMmapInSearch);
    SetValue(Node, 'PartialNameSearch', gPartialNameSearch);
    SetValue(Node, 'WipePassNumber', gWipePassNumber);
    SetValue(Node, 'DropReadOnlyFlag', gDropReadOnlyFlag);
    SetValue(Node, 'ProcessComments', gProcessComments);
    SetValue(Node, 'RenameSelOnlyName', gRenameSelOnlyName);
    SetValue(Node, 'ShowCopyTabSelectPanel', gShowCopyTabSelectPanel);
    SetValue(Node, 'UseTrash', gUseTrash);
    SetValue(Node, 'SkipFileOpError', gSkipFileOpError);
    SetValue(Node, 'TypeOfDuplicatedRename', Integer(gTypeOfDuplicatedRename));
    SetValue(Node, 'ShowDialogOnDragDrop', gShowDialogOnDragDrop);
    SetValue(Node, 'DragAndDropTextRichtextDesireLevel', gDragAndDropDesiredTextFormat[DropTextRichText_Index].DesireLevel);
    SetValue(Node, 'DragAndDropTextHtmlDesireLevel',gDragAndDropDesiredTextFormat[DropTextHtml_Index].DesireLevel);
    SetValue(Node, 'DragAndDropTextUnicodeDesireLevel',gDragAndDropDesiredTextFormat[DropTextUnicode_Index].DesireLevel);
    SetValue(Node, 'DragAndDropTextSimpletextDesireLevel',gDragAndDropDesiredTextFormat[DropTextSimpleText_Index].DesireLevel);
    SetValue(Node, 'DragAndDropAskFormatEachTime', gDragAndDropAskFormatEachTime);
    SetValue(Node, 'DragAndDropTextAutoFilename', gDragAndDropTextAutoFilename);
    SetValue(Node, 'DragAndDropSaveUnicodeTextInUFT8', gDragAndDropSaveUnicodeTextInUFT8);
    SetValue(Node, 'OverwriteFolder', gOverwriteFolder);
    SetValue(Node, 'NtfsHourTimeDelay', gNtfsHourTimeDelay);
    SetValue(Node, 'SearchDefaultTemplate', gSearchDefaultTemplate);
    SetValue(Node, 'ProgressKind', Integer(gFileOperationsProgressKind));
    SetValue(Node, 'Confirmations', Integer(gFileOperationsConfirmations));
    // Operations options
    SubNode := FindNode(Node, 'Options', True);
    SetValue(SubNode, 'Symlink', Integer(gOperationOptionSymLinks));
    SetValue(SubNode, 'CorrectLinks', gOperationOptionCorrectLinks);
    SetValue(SubNode, 'FileExists', Integer(gOperationOptionFileExists));
    SetValue(SubNode, 'DirectoryExists', Integer(gOperationOptionDirectoryExists));
    SetValue(SubNode, 'SetPropertyError', Integer(gOperationOptionSetPropertyError));
    SetValue(SubNode, 'ReserveSpace', gOperationOptionReserveSpace);
    SetValue(SubNode, 'CheckFreeSpace', gOperationOptionCheckFreeSpace);
    SetValue(SubNode, 'CopyAttributes', gOperationOptionCopyAttributes);
    SetValue(SubNode, 'CopyTime', gOperationOptionCopyTime);
    SetValue(SubNode, 'CopyOwnership', gOperationOptionCopyOwnership);
    SetValue(SubNode, 'CopyPermissions', gOperationOptionCopyPermissions);

    { Tabs page }
    Node := FindNode(Root, 'Tabs', True);
    SetValue(Node, 'Options', Integer(gDirTabOptions));
    SetValue(Node, 'CharacterLimit', gDirTabLimit);
    SetValue(Node, 'Position', Integer(gDirTabPosition));
    SetValue(Node, 'ActionOnDoubleClick',Integer(gDirTabActionOnDoubleClick));

    { Log page }
    Node := FindNode(Root, 'Log', True);
    SetAttr(Node, 'Enabled', gLogFile);
    SetAttr(Node, 'LogFileWithDateInName', gLogFileWithDateInName);
    SetValue(Node, 'FileName', gLogFileName);
    SetValue(Node, 'Options', Integer(gLogOptions));

    { Configuration page }
    SetAttr(Root, 'Configuration/Save', gSaveConfiguration);
    SetAttr(Root, 'History/SearchReplaceHistory/Save', gSaveSearchReplaceHistory);
    SetAttr(Root, 'History/DirHistory/Save', gSaveDirHistory);
    SetAttr(Root, 'History/CmdLineHistory/Save', gSaveCmdLineHistory);
    SetAttr(Root, 'History/FileMaskHistory/Save', gSaveFileMaskHistory);
    SetAttr(Root, 'Configuration/SortOrder', Integer(gSortOrderOfConfigurationOptionsTree));

    { Quick Search/Filter page }
    Node := FindNode(Root, 'QuickSearch', True);
    SetValue(Node, 'MatchBeginning', qsmBeginning in gQuickSearchOptions.Match);
    SetValue(Node, 'MatchEnding', qsmEnding in gQuickSearchOptions.Match);
    SetValue(Node, 'Case', Integer(gQuickSearchOptions.SearchCase));
    SetValue(Node, 'Items', Integer(gQuickSearchOptions.Items));
    Node := FindNode(Root, 'QuickFilter', True);
    SetValue(Node, 'AutoHide', gQuickFilterAutoHide);
    SetValue(Node, 'SaveSessionModifications', gQuickFilterSaveSessionModifications);

    { Misc page }
    Node := FindNode(Root, 'Miscellaneous', True);
    SetValue(Node, 'GridVertLine', gGridVertLine);
    SetValue(Node, 'GridHorzLine', gGridHorzLine);
    SetValue(Node, 'ShowWarningMessages', gShowWarningMessages);
    SetValue(Node, 'SpaceMovesDown', gSpaceMovesDown);
    SetValue(Node, 'DirBrackets', gDirBrackets);
    SetValue(Node, 'InplaceRename', gInplaceRename);
    SetValue(Node, 'HotDirAddTargetOrNot',gHotDirAddTargetOrNot);
    SetValue(Node, 'HotDirFullExpandOrNot', gHotDirFullExpandOrNot);
    SetValue(Node, 'ShowPathInPopup', gShowPathInPopup);
    SetValue(Node, 'ShowOnlyValidEnv', gShowOnlyValidEnv);
    SetValue(Node, 'WhereToAddNewHotDir', Integer(gWhereToAddNewHotDir));

    { Thumbnails }
    Node := FindNode(Root, 'Thumbnails', True);
    SetAttr(Node, 'Save', gThumbSave);
    SetValue(Node, 'Width', gThumbSize.cx);
    SetValue(Node, 'Height', gThumbSize.cy);

    { Auto refresh page }
    Node := FindNode(Root, 'AutoRefresh', True);
    SetValue(Node, 'Options', Integer(gWatchDirs));
    SetValue(Node, 'ExcludeDirs', gWatchDirsExclude);
    SetValue(Node, 'Mode', Integer(gWatcherMode));

    { Icons page }
    Node := FindNode(Root, 'Icons', True);
    SetValue(Node, 'ShowMode', Integer(gShowIconsNew));
    SetValue(Node, 'ShowOverlays', gIconOverlays);
    SetValue(Node, 'Size', gIconsSizeNew);
    SetValue(Node, 'Exclude', gIconsExclude);
    SetValue(Node, 'ExcludeDirs', gIconsExcludeDirs);
    SetValue(Node, 'CustomDriveIcons', gCustomDriveIcons);
    SetAttr(Node, 'ShowInMenus/Enabled', gIconsInMenus);
    SetValue(Node, 'ShowInMenus/Size', gIconsInMenusSizeNew);

    { Ignore list page }
    Node := FindNode(Root, 'IgnoreList', True);
    SetAttr(Node, 'Enabled', gIgnoreListFileEnabled);
    SetValue(Node, 'IgnoreListFile', gIgnoreListFile);

    { Directories HotList }
    gDirectoryHotlist.SaveToXml(gConfig, Root, TRUE);

    { Viewer }
    Node := FindNode(Root, 'Viewer',True);
    SetValue(Node, 'PreviewVisible',gPreviewVisible);
    SetValue(Node, 'ImageStretch',gImageStretch);
    SetValue(Node, 'ImageStretchLargeOnly',gImageStretchOnlyLarge);
    SetValue(Node, 'ImageCenter',gImageCenter);
    SetValue(Node, 'CopyMovePath1', gCopyMovePath1);
    SetValue(Node, 'CopyMovePath2', gCopyMovePath2);
    SetValue(Node, 'CopyMovePath3', gCopyMovePath3);
    SetValue(Node, 'CopyMovePath4', gCopyMovePath4);
    SetValue(Node, 'CopyMovePath5', gCopyMovePath5);
    SetValue(Node, 'PaintMode', gImagePaintMode);
    SetValue(Node, 'PaintWidth', gImagePaintWidth);
    SetValue(Node, 'NumberOfColumns', gColCount);
    SetValue(Node, 'ViewerMode', gViewerMode);
    SetValue(Node, 'PaintColor', gImagePaintColor);
    SetValue(Node, 'BackgroundColor', gBookBackgroundColor);
    SetValue(Node, 'FontColor', gBookFontColor);
    SetValue(Node, 'TextPosition', gTextPosition);

    { Editor }
    Node := FindNode(Root, 'Editor',True);
    SetValue(Node, 'EditWaitTime', gEditWaitTime);
    SetValue(Node, 'SynEditOptions', Integer(gEditorSynEditOptions));

    { SyncDirs }
    Node := FindNode(Root, 'SyncDirs', True);
    SetValue(Node, 'Subdirs', gSyncDirsSubdirs);
    SetValue(Node, 'ByContent', gSyncDirsByContent);
    SetValue(Node, 'IgnoreDate', gSyncDirsIgnoreDate);
    SetValue(Node, 'FilterCopyRight', gSyncDirsShowFilterCopyRight);
    SetValue(Node, 'FilterEqual', gSyncDirsShowFilterEqual);
    SetValue(Node, 'FilterNotEqual', gSyncDirsShowFilterNotEqual);
    SetValue(Node, 'FilterCopyLeft', gSyncDirsShowFilterCopyLeft);
    SetValue(Node, 'FilterDuplicates', gSyncDirsShowFilterDuplicates);
    SetValue(Node, 'FilterSingles', gSyncDirsShowFilterSingles);
    SetValue(Node, 'FileMask', gSyncDirsFileMask);

    { Internal Associations}
    Node := FindNode(Root, 'InternalAssociations', True);
    SetValue(Node, 'OfferToAddNewFileType', gOfferToAddToFileAssociations);
    SetValue(Node, 'LastCustomAction', gFileAssociationLastCustomAction);
    SetValue(Node, 'ExpandedContextMenu', gExtendedContextMenu);
    SetValue(Node, 'ExecuteViaShell', gOpenExecuteViaShell);
    SetValue(Node, 'OpenSystemWithTerminalClose', gExecuteViaTerminalClose);
    SetValue(Node, 'OpenSystemWithTerminalStayOpen', gExecuteViaTerminalStayOpen);
    SetValue(Node, 'IncludeFileAssociation', gIncludeFileAssociation);

    { Favorite Tabs }
    Node := FindNode(Root, 'FavoriteTabsOptions', True);
    SetValue(Node, 'FavoriteTabsUseRestoreExtraOptions', gFavoriteTabsUseRestoreExtraOptions);
    SetValue(Node, 'WhereToAdd', Integer(gWhereToAddNewFavoriteTabs));
    SetValue(Node, 'Expand', gFavoriteTabsFullExpandOrNot);
    SetValue(Node, 'GotoConfigAftSav', gFavoriteTabsGoToConfigAfterSave);
    SetValue(Node, 'GotoConfigAftReSav', gFavoriteTabsGoToConfigAfterReSave);
    SetValue(Node, 'DfltLeftGoTo', Integer(gDefaultTargetPanelLeftSaved));
    SetValue(Node, 'DfltRightGoTo', Integer(gDefaultTargetPanelRightSaved));
    SetValue(Node, 'DfltKeep', Integer(gDefaultExistingTabsToKeep));
    SetValue(Node, 'DfltSaveDirHistory', gFavoriteTabsSaveDirHistory);
    SetValue(Node, 'FavTabsLastUniqueID',GUIDtoString(gFavoriteTabsList.LastFavoriteTabsLoadedUniqueId));

    { - Other - }
    SetValue(Root, 'Lua/PathToLibrary', gLuaLib);
    SetValue(Root, 'NameShortcutFile', gNameSCFile);
    SetValue(Root, 'LastUsedPacker', gLastUsedPacker);
    SetValue(Root, 'UseShellForFileOperations', gUseShellForFileOperations);
    SetValue(Root, 'LastDoAnyCommand', gLastDoAnyCommand);

    {$IFDEF MSWINDOWS}
    { TotalCommander Import/Export }
    //We'll save the last TC executable filename AND TC configuration filename ONLY if both has been set
    if (gTotalCommanderExecutableFilename<>'') AND (gTotalCommanderConfigFilename<>'') then
    begin
      Node := FindNode(Root, 'TCSection', True);
      if Assigned(Node) then
      begin
        SetValue(Node, 'TCExecutableFilename', gTotalCommanderExecutableFilename);
        SetValue(Node, 'TCConfigFilename', gTotalCommanderConfigFilename);
        SetValue(Node,'TCToolbarPath',gTotalCommanderToolbarPath);
      end;
    end;
    {$ENDIF}
  end;

  { Search template list }
  gSearchTemplateList.SaveToXml(gConfig, Root);

  { Columns sets }
  ColSet.Save(gConfig, Root);

  { Plugins }
  Node := gConfig.FindNode(Root, 'Plugins', True);
  gDSXPlugins.Save(gConfig, Node);
  gWCXPlugins.Save(gConfig, Node);
  gWDXPlugins.Save(gConfig, Node);
  gWFXPlugins.Save(gConfig, Node);
  gWLXPlugins.Save(gConfig, Node);
end;

function LoadConfig: Boolean;
var
  ErrorMessage: String = '';
begin
  Result := LoadConfigCheckErrors(@LoadGlobalConfig, gConfig.FileName, ErrorMessage);
  if not Result then
    Result := AskUserOnError(ErrorMessage);
end;

function InitGlobs: Boolean;
var
  InitProc: TProcedure;
  ErrorMessage: String = '';
begin
  CreateGlobs;
  if not OpenConfig(ErrorMessage) then
  begin
    if not AskUserOnError(ErrorMessage) then
      Exit(False);
  end;

  SetDefaultNonConfigGlobs;

  if not LoadGlobs then
  begin
    if not AskUserOnError(ErrorMessage) then
      Exit(False);
  end;

  for InitProc in FInitList do
    InitProc();

  Result := AskUserOnError(ErrorMessage);
end;

function GetKeyTypingAction(ShiftStateEx: TShiftState): TKeyTypingAction;
var
  Modifier: TKeyTypingModifier;
begin
  for Modifier in TKeyTypingModifier do
    if ShiftStateEx * KeyModifiersShortcutNoText = TKeyTypingModifierToShift[Modifier] then
      Exit(gKeyTyping[Modifier]);
  Result := ktaNone;
end;

function IsFileSystemWatcher: Boolean;
begin
  Result := ([watch_file_name_change, watch_attributes_change] * gWatchDirs <> []);
end;

initialization

finalization
  DestroyGlobs;
end.
