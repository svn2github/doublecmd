{
   Seksi Commander
   ----------------------------

   Class for storing list of files

   Licence   : GNU GPL 2
   Copyright : (2003)Radek Cervinka, Peter Cernoch
   Contact   : pcernoch@volny.cz
              radek.cervinka@centrum.cz

   contributors:

   Copyright (C) 2006-2007 Alexander Koblov (Alexx2000@mail.ru)

   TODO:
   maybe protect Sort with TCriticalSection, because
   in multithreaded program global variable
   bSortNegative can be rewriten by other thread,
   but Sort is Called only from main thread and
   it is safe
}

unit uFileList;

{$mode objfpc}{$H+}
interface
uses
  SysUtils, Classes, uTypes;

const

  //sort by specific field
  //ToDo:
  //  in future may be using enumerated values {sf_ByName, sf_ByExt,...} ?
  SF_BYNAME       = 0; //en< Sorting by name
  SF_BYEXT        = 1; //en< Sorting by extension
  SF_BYSIZE       = 2; //en< Sorting by file size
  SF_BYDATE       = 3; //en< Sorting by date
  SF_BYATTRIB     = 4; //en< Sorting by attributes

Type
  {en
     Class for storing list of files
  }
  TFileList = class
  private
    sortIn          : Integer;      //column for sorting
    negatSort       : Boolean;
    fDir : String;
    function GetCount:Integer;
  protected
    {en
       Internal TList class for storing pointers
       to TFileRecItem strucrures
    }
    fList: TList;
  public
    {en
       Create TFileList
    }
    Constructor Create;
    {en
       Destroy TFileList
    }
    Destructor  Destroy; override;
    {en
       Clear file list
    }
    procedure   Clear;
    {en
       Add new item to file list
       @param(fi Pointer to TFileRecItem strucrure)
       @returns(Index of added item)
    }
    function  AddItem(fi: PFileRecItem):Integer;
    {en
       Delete item from file list
       @param(iIndex Index of deleting item)
    }
    procedure DeleteItem(iIndex: Integer);
    {en
       Return item by index
       @param(iIndex Item index)
       @returns(Pointer to TFileRecItem strucrure)
    }
    procedure LoadFromFileNames(const FileNamesList: TStringList);
    {en
       Clears the filelist and fills it with file records using
       a list of filenames with full paths. It is used generally
       to convert a list of file paths from external applications.
       @param(FileNamesList List of filenames with full paths)
    }
    function  GetItem(iIndex: Integer) : PFileRecItem;
    {en
       Return full file name of item by index
       @param(iIndex Item index)
       @returns(File name)
    }
    function  GetFileName(iIndex: Integer): String;
    {en
       Return item index by file name
       @param(sFileName File name)
       @returns(Item index if item found, -1 otherwise)
    }
    function  CheckFileName(const sFileName:String):Integer;
    {en
       Update icon index information
       @param(PanelMode Current panel mode)
    }
    procedure  UpdateFileInformation(PanelMode: TPanelMode);
    {en
       Sort file list
       @param(SortBy Field, see SF_* constants)
       @param(bCaseSensitive Set @true for case sensitive sorting)
    }
    procedure Sort(SortBy:Integer; bDirection, bCaseSensitive:Boolean); overload;
    {en
       Indicates the number of items in the file list
    }
    property Count      : Integer read GetCount;
    {en
       Contain current file list directory
    }
    property CurrentDirectory : String read fDir write fDir;
  end;

{ this function couldn't be a method > type of parametr TList.Sort
  is function and not a method
}
  function ICompareByName(item1, item2:Pointer):Integer;
  function ICompareByExt (item1, item2:Pointer):Integer;
  function ICompareBySize(item1, item2:Pointer):Integer;
  function ICompareByDate(item1, item2:Pointer):Integer;
  function ICompareByAttr(item1, item2:Pointer):Integer;

  procedure CopyListSelectedExpandNames(srcFileList, dstFileList:TFileList; sPath:String; bFullName : Boolean = True);

implementation

uses
  LCLProc, uGlobs, uPixmapManager, uDCUtils, uOSUtils, uFileOp;

var
  bSortNegative : Boolean; // because implementation of TList.Sort
  bCaseSensSort : Boolean;

{
class constructor
}
Constructor TFileList.Create;
begin
  fList:=TList.Create;
  sortIn      := SF_BYNAME;
  negatSort   := FALSE;
end;


Destructor TFileList.Destroy;
begin
  Clear;
  FreeAndNil(fList);
  inherited;
end;


procedure TFileList.Clear;
var
  i:Integer;
begin
  if (Assigned(fList)) then
  begin
    for i:=fList.Count-1 downto 0 do
      DeleteItem(i);
    fList.Clear;
  end;
end;

Function TFileList.CheckFileName(const sFileName:String):Integer;
var
  i:Integer;
begin
  Result:=-1;
  for i:=0 to fList.Count-1 do
    if (GetItem(i)^.sName=sFileName) then
    begin
      Result:=i;
      Exit;
    end;
    DebugLN('GetItem(i)^.sName = ', GetItem(i)^.sName);
end;

procedure TFileList.DeleteItem(iIndex: Integer);
begin
  if (iIndex > (fList.Count - 1)) then exit;
  //delete items count
  dispose(PFileRecItem(fList.Items[iIndex]));
  fList.Delete(iIndex);
end;

{
add new item to file list
}
function TFileList.AddItem(fi : PFileRecItem): Integer;
var
  p: PFileRecItem;
begin
  new(p);

  p^.bIsLink := fi^.bIsLink;
  p^.bLinkIsDir:=fi^.bLinkIsDir;
  p^.sLinkTo := fi^.sLinkTo;
  p^.sName := fi^.sName;
  p^.sNameNoExt:=fi^.sNameNoExt;
  p^.sPath:= fi^.sPath;
  p^.sExt := fi^.sExt;
  p^.iSize := fi^.iSize;
  p^.fTimeI := fi^.fTimeI;
  p^.sTime := fi^.sTime;
  p^.iMode := fi^.iMode;
  p^.bSysFile := fi^.bSysFile;
  p^.bExecutable := fi^.bExecutable;
  p^.sModeStr := fi^.sModeStr;
  p^.iIconID:= fi^.iIconID;
  p^.bSelected:= fi^.bSelected;
  p^.sOwner:=fi^.sOwner;
  p^.sGroup:=fi^.sGroup;
  p^.iOwner:=fi^.iOwner; //[mate]
  p^.iGroup:=fi^.iGroup; //[mate]
  p^.iDirSize:= fi^.iDirSize;
  Result := fList.Add(p);
end;

procedure TFileList.LoadFromFileNames(const FileNamesList: TStringList);
var
  fr: TFileRecItem;
  i: Integer;
begin
  fList.Clear;

  if not Assigned(FileNamesList) or (FileNamesList.Count <= 0) then Exit;

  // TODO: File names can be from different directories.
  //       Maybe set individual sPath's instead.
  CurrentDirectory := ExtractFilePath(FileNamesList[0]);

  for i := 0 to FileNamesList.Count-1 do
    begin
      fr:= LoadFilebyName(FileNamesList[i]);
      fr.sName:= FileNamesList[i];
      fr.sNameNoExt:= ExtractFileName(FileNamesList[i]);
      AddItem(@fr);
    end;
end;

{
return item with index iIndex
}
function TFileList.GetItem(iIndex: Integer) : PFileRecItem;
begin
  if ((iIndex + 1) > fList.Count) then
    Raise Exception.Create('Bad index in GetItem');
  Result := fList.items[iIndex];
end;


{
return full file name of item with index iIndex;
 -> index starts from 0
}
function TFileList.GetFileName(iIndex: Integer): String;
var
  p : PFileRecItem;
begin
  if (iIndex >= Count) or (iIndex < 0) then
    Raise Exception.Create('Bad index GetFileName');
  p := fList.Items[iIndex];
  Result:=p^.sName;
end;

{
Sort files by the default value in SortCol (e.g. SortIn) variable.
}
procedure TFileList.Sort(SortBy:Integer; bDirection, bCaseSensitive:Boolean);
begin
  bSortNegative:=bDirection;
  bCaseSensSort := bCaseSensitive;
  if fList.Count=0 then Exit;
  case SortBy of
    SF_BYNAME:   fList.Sort(@ICompareByName);
    SF_BYEXT:    fList.Sort(@ICompareByExt);
    SF_BYSIZE:   fList.Sort(@ICompareBySize);
    SF_BYDATE:   fList.Sort(@ICompareByDate);
    SF_BYATTRIB: fList.Sort(@ICompareByAttr);
  else
    Raise Exception.Create('Unknow sort parametr - fix me');
  end;
end;


function TFileList.GetCount:Integer;
begin
  Result:=flist.Count;
end;

{ Return Values for ICompareByxxxx function

> 0 (positive)   Item1 is less than Item2
  0              Item1 is equal to Item2
< 0 (negative)  Item1 is greater than Item2
}

{
  This function is simples support of sorting
  directory (handle uglobs.gDirSortFirst)

  Result is 0 if both parametres is directory and equal
  or not a directory (both).

  Else return +/- as ICompare****
  > 0 (positive)   Item1 is less than Item2
  < 0 (negative)  Item1 is greater than Item2
}

function ICompareCheckDir(item1, item2: PFileRecItem; bCompareByName:Boolean=True):Integer;
begin
  Result:=0;
  if item1=item2 then Exit;

  if (not (FPS_ISDIR(item1^.iMode) or item1^.bLinkIsDir)) and  (not (FPS_ISDIR(item2^.iMode) or item2^.bLinkIsDir)) then  Exit;
  if (not (FPS_ISDIR(item1^.iMode) or item1^.bLinkIsDir)) and (FPS_ISDIR(item2^.iMode) or item2^.bLinkIsDir) then
  begin
    Result:=+1;
    Exit;
  end;
  if (FPS_ISDIR(item1^.iMode) or item1^.bLinkIsDir) and (not (FPS_ISDIR(item2^.iMode) or item2^.bLinkIsDir)) then
  begin
    Result:=-1;
    Exit;
  end;
// both is directory, compare it
//  if item1.fName=item2.fName then Exit;
  // handle .. first
  if item1^.sName='..' then
  begin
    Result:=-1;
    Exit;
  end;
  if item2^.sName='..' then
  begin
    Result:=+1;
    Exit;
  end;

  if not bCompareByName then
  begin
    Result:=0; // used in by Attr, or Date
    Exit;
  end;
  if bCaseSensSort then
    Result:=StrComp(PChar(item1^.sName), PChar(item2^.sName))
  else
    Result := StrIComp(PChar(item1^.sName), PChar(item2^.sName));
  if bSortNegative then
    Result:=-Result;
end;

function ICompareByName(item1, item2:Pointer):Integer;
begin
{> 0 (positive)   Item1 is less than Item2
  0              Item1 is equal to Item2
< 0 (negative)  Item1 is greater than Item2}
  Result:=0;
  if item1=item2 then Exit;;
  Result:= ICompareCheckDir(PFileRecItem(item1),PFileRecItem(item2));
  if Result<>0 then Exit;

  if bCaseSensSort then
    Result:=StrComp(PChar(PFileRecItem(item1)^.sName),PChar(PFileRecItem(item2)^.sName))
  else
    Result:=StrIComp(PChar(PFileRecItem(item1)^.sName),PChar(PFileRecItem(item2)^.sName));
{  if FileRecPtr(item1)^.fName = FileRecPtr(item2)^.fName then
    Exit;

  if FileRecPtr(item1)^.fName > FileRecPtr(item2)^.fName then
    Result:=-1
  else
    Result:=+1;
}
  if bSortNegative then
    Result:=-Result;

end;

function ICompareByExt(item1, item2:Pointer):Integer;
begin
{> 0 (positive)   Item1 is less than Item2
  0              Item1 is equal to Item2
< 0 (negative)  Item1 is greater than Item2}
  Result:=0;
  if item1=item2 then Exit;

  Result:= ICompareCheckDir(PFileRecItem(item1),PFileRecItem(item2));
  if Result<>0 then Exit;

  if PFileRecItem(item1)^.sExt = PFileRecItem(item2)^.sExt then
    Exit;

  if PFileRecItem(item1)^.sExt > PFileRecItem(item2)^.sExt then
    Result:=-1
  else
    Result:=+1;

  if bSortNegative then
    Result:=-Result;

end;

function ICompareByDate(item1, item2:Pointer):Integer;
begin
{> 0 (positive)   Item1 is less than Item2
  0              Item1 is equal to Item2
< 0 (negative)  Item1 is greater than Item2}
  Result:=0;
  if item1=item2 then Exit;
  Result:= ICompareCheckDir(PFileRecItem(item1),PFileRecItem(item2), False);
  if Result<>0 then Exit;

  if PFileRecItem(item1)^.fTimeI = PFileRecItem(item2)^.fTimeI then
    Exit;

  if PFileRecItem(item1)^.fTimeI > PFileRecItem(item2)^.fTimeI then
    Result:=-1
  else
    Result:=+1;
  if bSortNegative then
    Result:=-Result;
end;

function ICompareByAttr(item1, item2:Pointer):Integer;
begin
  Result:=0;
  if item1=item2 then Exit;
  Result:= ICompareCheckDir(PFileRecItem(item1),PFileRecItem(item2), False);
  if Result<>0 then Exit;

  if PFileRecItem(item1)^.iMode = PFileRecItem(item2)^.iMode then
    Exit;

  if PFileRecItem(item1)^.iMode > PFileRecItem(item2)^.iMode then
    Result:=-1
  else
    Result:=+1;
  if bSortNegative then
    Result:=-Result;
end;

function ICompareBySize(item1, item2:Pointer):Integer;
begin
{> 0 (positive)   Item1 is less than Item2
  0              Item1 is equal to Item2
< 0 (negative)  Item1 is greater than Item2}
  Result:=0;
  if item1=item2 then Exit;
  Result:= ICompareCheckDir(PFileRecItem(item1),PFileRecItem(item2){, False});
  if Result<>0 then Exit;

  if PFileRecItem(item1)^.iSize = PFileRecItem(item2)^.iSize then
    Exit;

  if PFileRecItem(item1)^.iSize > PFileRecItem(item2)^.iSize then
    Result:=-1
  else
    Result:=+1;

  if bSortNegative then
    Result:=-Result;

end;

procedure TFileList.UpdateFileInformation(PanelMode: TPanelMode);
var
  i:Integer;
  frp:PFileRecItem;
begin
  for i:=0 to fList.Count-1 do
  begin
    frp:=PFileRecItem(Flist.Items[i]);
    frp^.iIconID:=PixMapManager.GetIconByFile(frp, PanelMode);
  end;
end;

procedure CopyListSelectedExpandNames(srcFileList, dstFileList:TFileList; sPath:String; bFullName : Boolean = True);
var
  xIndex:Integer;
  p:TFileRecItem;
begin
  Assert(srcFileList <> nil,'CopyListExpandNames: srcFileList=nil');
  Assert(dstFileList <> nil,'CopyListExpandNames: dstFileList=nil');
  dstFileList.Clear;
  for xIndex:=0 to srcFileList.Count-1 do
  begin
    p:=srcFileList.GetItem(xIndex)^;
    if (not p.bSelected) or (p.sName = '..') then Continue;
    if bFullName then
      begin
        p.sNameNoExt:=p.sName; //dstname
        p.sName := GetSplitFileName(p.sNameNoExt, sPath);
        p.sPath:='';
      end
    else
      begin
        GetSplitFileName(p.sName, sPath);
        p.sPath := sPath;
      end;
    DebugLN(p.sName);
    dstFileList.AddItem(@p);
  end;
end;

end.

