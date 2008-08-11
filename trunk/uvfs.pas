{
   Double Commander
   -------------------------------------------------------------------------
   Implementation of Virtual File System

   Copyright (C) 2006-2008  Koblov Alexander (Alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

}

unit uVFS;


interface
uses
  Classes, uGlobs, uFileList, uVFSutil, uTypes, uVFSmodule, uWCXmodule, uWFXmodule;
type

  TVFSType = (vtWCX, vtWFX);

  { TVFS }

  TVFS = class
  private
    procedure SetVFSModule(Value : TVFSmodule);
  protected
    FCurrentPlugin : String;
    sLastArchive : String;
    FVFSType : TVFSType;
    FVFSModule : TVFSmodule;
  public
    constructor Create;
    destructor Destroy; override;
    
    function cdUpLevel(frp:PFileRecItem; var flist: TFileList) : Boolean;
    function cdDownLevel(frp:PFileRecItem; var flist: TFileList) : Boolean;
    {en
       Tries to find plugin for archive by content
       @param(sFileName Archive file name)
       @returns(@true if plugin found, @false otherwise)
    }
    function TryFindModule(const sFileName:String):Boolean;
    {en
       Tries to find plugin by file name
       @param(sFileName File name)
       @param(bLoadModule Load plugin module if found)
       @returns(@true if plugin found, @false otherwise)
    }
    function FindModule(const sFileName:String; bLoadModule : Boolean = True):Boolean;
    {en
       Load plugin module and open VFS
       @param(sFileName File name)
       @param(bGetOpenResult if @true then return VFSOpen result)
       @returns(@true if plugin module load, @false otherwise)
    }
    function LoadAndOpen(const sFileName:String; bGetOpenResult : Boolean = True) : Boolean;
    function LoadVFSList(var fl:TFileList) : Boolean;
    property VFSType : TVFSType read FVFSType;
    property VFSmodule : TVFSmodule read FVFSModule write SetVFSModule;
    property ArcFullName : String read sLastArchive write sLastArchive;
  end; //class TVFS

implementation

uses
  SysUtils, uGlobsPaths, uFindEx, uDCUtils, uOSUtils, LCLProc;

{ TVFS }

procedure TVFS.SetVFSModule(Value: TVFSmodule);
begin
  FVFSModule := Value;
  if FVFSModule is TWCXmodule then
    FVFSType := vtWCX;
  if FVFSModule is TWFXmodule then
    FVFSType := vtWFX;
end;

constructor TVFS.Create;
begin
  sLastArchive:='';  // nothing
end;

destructor TVFS.Destroy;
begin
  if Assigned(FVFSModule) then
     FVFSModule.Destroy;
  FVFSModule := nil;
  inherited
end;

function TVFS.cdUpLevel(frp: PFileRecItem; var flist: TFileList): Boolean;
var
  Folder : String;
begin
  Result := False;
  if frp^.sPath = '' then  // Exit from VFS
    Exit;
  Folder := frp^.sPath;
  FVFSModule.VFSList(Folder, flist);
  Result := True;
end;

function TVFS.cdDownLevel(frp: PFileRecItem; var flist: TFileList): Boolean;
var
  Folder : String;
begin
  Result := False;
  Folder := IncludeTrailingPathDelimiter(frp^.sPath + frp^.sName);
  FVFSModule.VFSList(Folder, flist);
  Result := True;
end;

function TVFS.TryFindModule(const sFileName: String): Boolean;
var
  I, iCount,
  Index : Integer;
  sPlugin : String;
begin
  if not mbFileExists(sFileName) then Exit(False);
  iCount := gWCXPlugins.Count - 1;
  for I := 0 to iCount do
    begin
      sPlugin := gWCXPlugins.ValueFromIndex[I];
      Index := Pos(',', sPlugin) + 1;
      FCurrentPlugin := GetCmdDirFromEnvVar(Copy(sPlugin, Index, Length(sPlugin)));

      FVFSModule := TWCXModule.Create;
      Result := FVFSModule.LoadModule(FCurrentPlugin);
      if Result then
        begin
          try
            Result := False;
            if FVFSModule.VFSOpen(sFileName, True) then // found
              begin
                sLastArchive := sFileName;
                Exit(True);
              end
            else
              FVFSModule.UnloadModule;
          except
            FVFSModule.UnloadModule;
          end;
        end;
    end; // for
end;


function TVFS.FindModule(const sFileName:String; bLoadModule : Boolean = True):Boolean;
var
  Count, i:Integer;
  sExt, tmp:String;
  Index : Integer;
begin
  Result := False;
  tmp := '';
  sExt := LowerCase(ExtractFileExt(sFileName));
  sExt := copy(sExt,2,length(sExt));
  DebugLN('sExt = ', sExt);
  tmp := gWCXPlugins.Values[sExt];
  

  //**************** Debug
     //DebugLN(FPlugins.Text);
     for i:=0 to gWCXPlugins.Count -1 do
     DebugLN(gWCXPlugins.ValueFromIndex[i]);
  //***************


  DebugLN('tmp = ', tmp);
  if tmp <> '' then
    begin
      Index := Pos(',', tmp) + 1;
      FCurrentPlugin := GetCmdDirFromEnvVar(Copy(tmp, Index, Length(tmp)));

      //DebugLN('FCurrentPlugin = ', FCurrentPlugin);

      //DebugLN('sLastArchive = ', sLastArchive);

      FVFSType := vtWCX;
      Result := True;
      if bLoadModule then
        begin
          sLastArchive := sFileName;
          Result := LoadAndOpen(sLastArchive);
        end;
    end
  else    // WFX Support
    if gWFXPlugins.IndexOfName(sFileName) >=0 then
      begin
        FCurrentPlugin := GetCmdDirFromEnvVar(gWFXPlugins.Values[sFileName]);

        FVFSType := vtWFX;
        Result := True;
        if bLoadModule then
          begin
            sLastArchive := '';
            Result := LoadAndOpen(sLastArchive);
            //*********************
            DebugLn(PChar(Pointer(FVFSModule.VFSMisc)));
            //*********************
          end;
      end;
end;

function TVFS.LoadAndOpen(const sFileName:String; bGetOpenResult : Boolean = True): Boolean;
begin
  sLastArchive := sFileName;
  case FVFSType of
    vtWCX:  FVFSModule := TWCXModule.Create;
    vtWFX:  FVFSModule := TWFXModule.Create;
  end;
  Result := FVFSModule.LoadModule(FCurrentPlugin);

  DebugLN(Format('After Module %s Load', [FCurrentPlugin]));

  if Result then
    begin
      if bGetOpenResult then
        Result := FVFSModule.VFSOpen(sLastArchive)
      else
        FVFSModule.VFSOpen(sLastArchive);
    end;
end;

function TVFS.LoadVFSList(var fl: TFileList) : Boolean;
var
  I, Count : Integer;
  sCurrPlugin : String;
  pfri : PFileRecItem;
begin
  Result := True;
  Count := gWFXPlugins.Count;
  if Count = 0 then
    begin
      Result := False;
      Exit;
    end;
  dec(Count);
  fl.Clear;
  for I := 0 to Count do
    begin
      if Pos('#', gWFXPlugins.Names[I]) = 0 then
        begin
          New(pfri);
          with pfri^ do
            begin
              sName := gWFXPlugins.Names[I];
              sNameNoExt := sName;
              iMode := faFolder;
              sModeStr := 'wfx';
              bSelected := False;
              bLinkIsDir := False;
              fl.AddItem(pfri);
            end;
        end
    end;
end;


initialization

end.
