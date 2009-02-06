{

   DRAGDROP.PAS -- simple realization of OLE drag and drop.

   Author: Jim Mischel

   Last modification date: 30/05/97

   Add some changes for compatibility with FPC/Lazarus

   Copyright (C) 2009 Alexander Koblov (Alexx2000@mail.ru)

}

unit uOleDragDrop;

{$mode delphi}{$H+}

interface

uses
  Windows, ActiveX, Classes;

type
  { TFormatList -- ������ ������� TFormatEtc }

  PFormatList = ^TFormatList;

  TFormatList = array[0..1] of TFormatEtc;

  { IEnumFormatEtc }

  TEnumFormatEtc = class(TInterfacedObject, IEnumFormatEtc)

  private

    FFormatList: PFormatList;

    FFormatCount: Integer;

    FIndex: Integer;

  public

    constructor Create(FormatList: PFormatList; FormatCount, Index: Integer);

    function Next(celt: LongWord; out elt: FormatEtc;
      pceltFetched: pULong): HResult; stdcall;

    function Skip(celt: LongWord): HResult; stdcall;

    function Reset: HResult; stdcall;

    function Clone(out enum: IEnumFormatEtc): HResult; stdcall;

  end;

  { TDragDropInfo }

  TDragDropInfo = class(TObject)

  private

    FInClientArea: boolean;

    FDropPoint: TPoint;

    FFileList: TStringList;

  public

    constructor Create(ADropPoint: TPoint; AInClient: boolean);

    destructor Destroy; override;

    procedure Add(const s: string);

    function CreateHDrop: HGlobal;

    property InClientArea: boolean Read FInClientArea;

    property DropPoint: TPoint Read FDropPoint;

    property Files: TStringList Read FFileList;

  end;


  TFileDropEvent = procedure(DDI: TDragDropInfo) of object;


  { TFileDropTarget �����, ��� ��������� ���������� ����� }

  TFileDropTarget = class(TInterfacedObject, IDropTarget)

  private

    FHandle: HWND;

    FOnFilesDropped: TFileDropEvent;

  public

    constructor Create(Handle: HWND; AOnDrop: TFileDropEvent);

    destructor Destroy; override;



    { �� IDropTarget }

    function DragEnter(const dataObj: IDataObject; grfKeyState: LongWord;
      pt: TPoint; var dwEffect: LongWord): HResult; stdcall;

    function DragOver(grfKeyState: LongWord; pt: TPoint;
      var dwEffect: LongWord): HResult; stdcall;

    function DragLeave: HResult; stdcall;

    function Drop(const dataObj: IDataObject; grfKeyState: LongWord;
      pt: TPoint; var dwEffect: LongWord): HResult; stdcall;

    property OnFilesDropped: TFileDropEvent Read FOnFilesDropped Write FOnFilesDropped;

  end;

  { TFileDropSource - ��������

  ��� �������������� ������ }

  TFileDropSource = class(TInterfacedObject, IDropSource)

    constructor Create;

    function QueryContinueDrag(fEscapePressed: BOOL;
      grfKeyState: longint): HResult; stdcall;

    function GiveFeedback(dwEffect: longint): HResult; stdcall;

  end;


  { THDropDataObject - ������ ������ �

  ����������� � ��������������� ������ }

  THDropDataObject = class(TInterfacedObject, IDataObject)

  private

    FDropInfo: TDragDropInfo;

  public

    constructor Create(ADropPoint: TPoint; AInClient: boolean);

    destructor Destroy; override;

    procedure Add(const s: string);

    { �� IDataObject }

    function GetData(const formatetcIn: TFormatEtc;
      out medium: TStgMedium): HResult; stdcall;

    function GetDataHere(const formatetc: TFormatEtc;
      out medium: TStgMedium): HResult; stdcall;

    function QueryGetData(const formatetc: TFormatEtc): HResult; stdcall;

    function GetCanonicalFormatEtc(const formatetc: TFormatEtc;
      out formatetcOut: TFormatEtc): HResult; stdcall;

    function SetData(const formatetc: TFormatEtc; const medium: TStgMedium;
      fRelease: BOOL): HResult; stdcall;

    function EnumFormatEtc(dwDirection: LongWord;
      out enumFormatEtc: IEnumFormatEtc): HResult; stdcall;

    function DAdvise(const formatetc: TFormatEtc; advf: LongWord;
      const advSink: IAdviseSink; out dwConnection: LongWord): HResult; stdcall;

    function DUnadvise(dwConnection: LongWord): HResult; stdcall;

    function EnumDAdvise(out enumAdvise: IEnumStatData): HResult; stdcall;

  end;


  { Query DROPFILES structure for [BOOL fWide] parameter }
  function DragQueryWide( hGlobalDropInfo: HDROP ): boolean;

implementation

uses
  SysUtils, ShellAPI, ShlObj;

{ TEnumFormatEtc }

constructor TEnumFormatEtc.Create(FormatList: PFormatList; FormatCount, Index: Integer);

begin

  inherited Create;

  FFormatList := FormatList;

  FFormatCount := FormatCount;

  FIndex := Index;

end;

{

  Next ��������� �������� ����������

  �������� TFormatEtc

  � ������������ ������ elt.

  ����������� celt ���������, ������� �

  ������� ������� � ������.

}

function TEnumFormatEtc.Next(celt: LongWord; out elt: FormatEtc;
  pceltFetched: pULong): HResult;

var

  i: Integer;

  eltout: TFormatList absolute elt;

begin

  i := 0;



  while (i < celt) and (FIndex < FFormatCount) do

  begin

    eltout[i] := FFormatList[FIndex];

    Inc(FIndex);

    Inc(i);

  end;



  if (pceltFetched <> nil) then

    pceltFetched^ := i;



  if (I = celt) then

    Result := S_OK

  else

    Result := S_FALSE;

end;

{

  Skip ���������� celt ��������� ������,

  ������������ ������� �������

  �� (CurrentPointer + celt) ��� �� �����

  ������ � ������ ������������.

}

function TEnumFormatEtc.Skip(celt: LongWord): HResult;

begin

  if (celt <= FFormatCount - FIndex) then

  begin

    FIndex := FIndex + celt;

    Result := S_OK;

  end
  else

  begin

    FIndex := FFormatCount;

    Result := S_FALSE;

  end;

end;

{ Reset ������������� ��������� �������

������� �� ������ ������ }

function TEnumFormatEtc.Reset: HResult;

begin

  FIndex := 0;

  Result := S_OK;

end;

{ Clone �������� ������ �������� }

function TEnumFormatEtc.Clone(out enum: IEnumFormatEtc): HResult;

begin

  enum := TEnumFormatEtc.Create(FFormatList, FFormatCount, FIndex);

  Result := S_OK;

end;


{ TDragDropInfo }

constructor TDragDropInfo.Create(ADropPoint: TPoint; AInClient: boolean);

begin

  inherited Create;

  FFileList := TStringList.Create;

  FDropPoint := ADropPoint;

  FInClientArea := AInClient;

end;

destructor TDragDropInfo.Destroy;

begin

  FFileList.Free;

  inherited Destroy;

end;

procedure TDragDropInfo.Add(const s: string);

begin

  Files.Add(s);

end;

function TDragDropInfo.CreateHDrop: HGlobal;

var

  RequiredSize: Integer;

  I: Integer;

  hGlobalDropInfo: HGlobal;

  DropFiles: PDropFiles;

  wsFileList: WideString;

begin

  {

    �������� ��������� TDropFiles � ������,

    ���������� �����

    GlobalAlloc. ������� ������ ������� ����������

    � ����������,

    ��������� ���, ��������, ����� ������������

    ������� ��������.

  }



  {
    Bring the filenames in a form,
    separated by #0 and ending with a double #0#0
  }

  for I := 0 to Self.Files.Count - 1 do

    begin

      wsFileList:= wsFileList + UTF8Decode(Self.Files[I]) + #0;

    end;

  wsFileList:= wsFileList + #0;

  { ���������� ����������� ������ ��������� }

  RequiredSize := SizeOf(TDropFiles) + Length(wsFileList) * 2;



  hGlobalDropInfo := GlobalAlloc((GMEM_SHARE or GMEM_MOVEABLE or GMEM_ZEROINIT),
    RequiredSize);

  if (hGlobalDropInfo <> 0) then

  begin

    { ����������� ������� ������, ����� � ���

      ����� ���� ����������

    }

    DropFiles := GlobalLock(hGlobalDropInfo);



    { �������� ���� ��������� DropFiles }

    {

      pFiles -- �������� �� ������

      ��������� �� ������� ����� �������

      � ������� ������.

    }

    DropFiles.pFiles := SizeOf(TDropFiles);

    DropFiles.pt := Self.FDropPoint;

    DropFiles.fNC := Self.InClientArea;

    DropFiles.fWide := True;



    {

      �������� ����� ������ � �����.

      ����� ���������� �� ��������

      DropFiles + DropFiles.pFiles,

      �� ���� ����� ���������� ���� ���������.

    }

    DropFiles := Pointer(DropFiles) + DropFiles.pFiles;

    CopyMemory(DropFiles, PWideChar(wsFileList), Length(wsFileList) * 2);



    { ������� ���������� }

    GlobalUnlock(hGlobalDropInfo);

  end;



  Result := hGlobalDropInfo;

end;


{ TFileDropTarget }

constructor TFileDropTarget.Create(Handle: HWND; AOnDrop: TFileDropEvent);

begin

  inherited Create;

  _AddRef;

  FHandle := Handle;

  FOnFilesDropped := AOnDrop;

  ActiveX.CoLockObjectExternal(Self,

    True, False);

  ActiveX.RegisterDragDrop(FHandle, Self);

end;

{ Destroy ������� ���������� � �������

� ��������� ����� � ��� }

destructor TFileDropTarget.Destroy;

var

  WorkHandle: HWND;

begin

  {

    ���� �������� FHandle �� ����� 0,

    ������, ����� � ����� ���

    ��� ����������. �������� ��������

    �� ��, ��� FHandle ����������

    ������ ����� ��������� 0, ������

    ��� CoLockObjectExternal �

    RevokeDragDrop �������� Release,

    ���, � ���� �������, �����

    �������� � ������ Free � ������������

    ���������.

    ����������, ��� ���� �������� ��

    ������ �������. ���� ������ �����

    ���������� �� ����, ���

    ������� ������ ������ �� 0,

    ����� ���������� ����������.

  }

  if (FHandle <> 0) then

  begin

    WorkHandle := FHandle;

    FHandle := 0;

    ActiveX.CoLockObjectExternal

    (Self, False, True);

    ActiveX.RevokeDragDrop(WorkHandle);

  end;



  inherited Destroy;

end;

function TFileDropTarget.DragEnter(const dataObj: IDataObject;
  grfKeyState: LongWord; pt: TPoint; var dwEffect: LongWord): HResult; stdcall;

begin

  dwEffect := DROPEFFECT_COPY;

  Result := S_OK;

end;

function TFileDropTarget.DragOver

  (grfKeyState: LongWord; pt: TPoint; var dwEffect: LongWord): HResult; stdcall;

begin

  dwEffect := DROPEFFECT_COPY;

  Result := S_OK;

end;

function TFileDropTarget.DragLeave: HResult; stdcall;

begin

  Result := S_OK;

end;

{

  ��������� ���������� ������.

}

function TFileDropTarget.Drop(const dataObj: IDataObject; grfKeyState: LongWord;
  pt: TPoint; var dwEffect: LongWord): HResult; stdcall;

var

  Medium: TSTGMedium;

  Format: TFormatETC;

  NumFiles: Integer;

  i: Integer;

  rslt: Integer;

  DropInfo: TDragDropInfo;

  szFilename: array [0..MAX_PATH] of char;

  InClient: boolean;

  DropPoint: TPoint;

  bWideStrings: boolean;

begin

  dataObj._AddRef;

  {

    �������� ������.  ��������� TFormatETC

    ��������

    dataObj.GetData, ��� �������� ������

    � � ����� �������

    ��� ������ ��������� (��� ����������

    ���������� �

    ��������� TSTGMedium).

  }

  Format.cfFormat := CF_HDROP;

  Format.ptd := nil;

  Format.dwAspect := DVASPECT_CONTENT;

  Format.lindex := -1;

  Format.tymed := TYMED_HGLOBAL;



  { ������� ������ � ��������� Medium }

  rslt := dataObj.GetData(Format, Medium);



  {

    ���� ��� ������ �������, �����

    ���������, ��� ��� �������� ���������

    �������������� FMDD.

  }

  if (rslt = S_OK) then

  begin

    { �������� ���������� ������ �

    ������ �������� }

    NumFiles := DragQueryFile(Medium.hGlobal, $FFFFFFFF, nil, 0);

    InClient := DragQueryPoint(Medium.hGlobal, @DropPoint);

    bWideStrings := DragQueryWide( Medium.hGlobal );


    { ������� ������ TDragDropInfo }

    DropInfo := TDragDropInfo.Create(DropPoint, InClient);



    { ������� ��� ����� � ������ }

    for i := 0 to NumFiles - 1 do

    begin

      DragQueryFile(Medium.hGlobal, i,

        szFilename,

        sizeof(szFilename));

      // If Wide strings, then do Wide to UTF-8 transform
      if( bWideStrings ) then
        DropInfo.Add( UTF8Encode( szFileName ) )
      else
        DropInfo.Add(szFilename);

    end;

    { ���� ������ ����������, �������� ��� }

    if (Assigned(FOnFilesDropped)) then

    begin

      FOnFilesDropped(DropInfo);

    end;



    DropInfo.Free;

  end;

  { Release memory allocated on DoDragDrop }
  DragFinish( Medium.hGlobal );

  if (Medium.PUnkForRelease = nil) then

    ReleaseStgMedium(@Medium);



  dataObj._Release;

  dwEffect := DROPEFFECT_COPY;

  Result := S_OK;

end;


{ TFileDropSource }

constructor TFileDropSource.Create;

begin

  inherited Create;

  _AddRef;

end;

{

QueryContinueDrag ���������� ����������� ��������.

}

function TFileDropSource.QueryContinueDrag(fEscapePressed: BOOL;
  grfKeyState: longint): HResult;

begin

  if (fEscapePressed) then

  begin

    Result := DRAGDROP_S_CANCEL;

  end

  else if ((grfKeyState and (MK_LBUTTON or MK_RBUTTON)) = 0) then

  begin

    Result := DRAGDROP_S_DROP;

  end

  else

  begin

    Result := S_OK;

  end;

end;

function TFileDropSource.GiveFeedback(dwEffect: longint): HResult;

begin

  case dwEffect of

    DROPEFFECT_NONE,

    DROPEFFECT_COPY,

    DROPEFFECT_MOVE,

    DROPEFFECT_LINK,

    DROPEFFECT_SCROLL: Result :=

        DRAGDROP_S_USEDEFAULTCURSORS;

    else

      Result := S_OK;

  end;

end;


{ THDropDataObject }

constructor THDropDataObject.Create(ADropPoint: TPoint; AInClient: boolean);

begin

  inherited Create;

  _AddRef;

  FDropInfo := TDragDropInfo.Create(ADropPoint, AInClient);

end;

destructor THDropDataObject.Destroy;

begin

  if (FDropInfo <> nil) then

    FDropInfo.Free;

  inherited Destroy;

end;

procedure THDropDataObject.Add(const s: string);

begin

  FDropInfo.Add(s);

end;

function THDropDataObject.GetData(const formatetcIn: TFormatEtc;
  out medium: TStgMedium): HResult;

begin

  Result := DV_E_FORMATETC;

  { ���������� �������� ��� ���� medium

  �� ������ ������}

  medium.tymed := 0;

  medium.hGlobal := 0;

  medium.PUnkForRelease := nil;



  { ���� ������ ��������������, �������

  � ���������� ������ }

  if (QueryGetData(formatetcIn) = S_OK) then

  begin

    if (FDropInfo <> nil) then

    begin

      medium.tymed := TYMED_HGLOBAL;

      { �� ������������ ��������

      ���������� �������! }

      medium.hGlobal := FDropInfo.CreateHDrop;

      Result := S_OK;

    end;

  end;

end;

function THDropDataObject.GetDataHere(const formatetc: TFormatEtc;
  out medium: TStgMedium): HResult;

begin

  Result := DV_E_FORMATETC;  { � ���������,

  �� �������������� }

end;

function THDropDataObject.QueryGetData(const formatetc: TFormatEtc): HResult;

begin

  Result := DV_E_FORMATETC;

  with formatetc do

    if dwAspect = DVASPECT_CONTENT then

      if (cfFormat = CF_HDROP) and (tymed = TYMED_HGLOBAL) then

        Result := S_OK;

end;

function THDropDataObject.GetCanonicalFormatEtc(const formatetc: TFormatEtc;
  out formatetcOut: TFormatEtc): HResult;

begin

  formatetcOut.ptd := nil;

  Result := E_NOTIMPL;

end;

function THDropDataObject.SetData(const formatetc: TFormatEtc;
  const medium: TStgMedium; fRelease: BOOL): HResult;

begin

  Result := E_NOTIMPL;

end;


{ EnumFormatEtc ���������� ������ �������������� �������� }

function THDropDataObject.EnumFormatEtc(dwDirection: LongWord;
  out enumFormatEtc: IEnumFormatEtc): HResult;

const

  DataFormats: array [0..0] of TFormatEtc =

    (

    (

    cfFormat: CF_HDROP;

    ptd: nil;

    dwAspect: DVASPECT_CONTENT;

    lindex: -1;

    tymed: TYMED_HGLOBAL;

    )

    );

  DataFormatCount = 1;

begin

  { �������������� ������ Get. ������

  ���������� ������ ������ }

  if dwDirection = DATADIR_GET then

  begin

    enumFormatEtc := TEnumFormatEtc.Create(@DataFormats, DataFormatCount, 0);

    Result := S_OK;

  end
  else

  begin

    enumFormatEtc := nil;

    Result := E_NOTIMPL;

  end;

end;

{ ������� Advise �� �������������� }

function THDropDataObject.DAdvise(const formatetc: TFormatEtc;
  advf: LongWord; const advSink: IAdviseSink; out dwConnection: LongWord): HResult;

begin

  Result := OLE_E_ADVISENOTSUPPORTED;

end;

function THDropDataObject.DUnadvise(dwConnection: LongWord): HResult;

begin

  Result := OLE_E_ADVISENOTSUPPORTED;

end;

function THDropDataObject.EnumDAdvise(out enumAdvise: IEnumStatData): HResult;

begin

  Result := OLE_E_ADVISENOTSUPPORTED;

end;

function DragQueryWide( hGlobalDropInfo: HDROP ): boolean;
var DropFiles: PDropFiles;
begin
  DropFiles := GlobalLock( hGlobalDropInfo );
  Result := DropFiles^.fWide;
  GlobalUnlock( hGlobalDropInfo );
end;

initialization

  OleInitialize(nil);


finalization

  OleUninitialize;

end.

