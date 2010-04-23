{
   Double Commander
   -------------------------------------------------------------------------
   Filepanel columns implementation unit

   Copyright (C) 2008  Dmitry Kolomiets (B4rr4cuda@rambler.ru)

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

unit uFileFunctions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, uFile, uFileProperty, uFileSource;

type
  TFileFunction = (fsfName,
                   fsfExtension,
                   fsfSize,
                   fsfAttr,
                   fsfPath,
                   fsfGroup,
                   fsfOwner,
                   fsfModificationTime,
                   fsfCreationTime,
                   fsfLastAccessTime,
                   fsfLinkTo,
                   fsfNameNoExtension,
                   fsfType,
                   fsfInvalid);

  TFileFunctions = array of TFileFunction;

  const TFileFunctionStrings: array [TFileFunction] of string
            = ('GETFILENAME',
               'GETFILEEXT',
               'GETFILESIZE',
               'GETFILEATTR',
               'GETFILEPATH',
               'GETFILEGROUP',
               'GETFILEOWNER',
               'GETFILETIME',
               'GETFILECREATIONTIME',
               'GETFILELASTACCESSTIME',
               'GETFILELINKTO',
               'GETFILENAMENOEXT',
               'GETFILETYPE',
               ''                 // fsfInvalid
               );

  // Which file properties must be supported for each file function to work.
  const TFileFunctionToProperty: array [TFileFunction] of TFilePropertiesTypes
            = ([fpName],
               [fpName],
               [fpSize],
               [fpAttributes],
               [] { path },
               [fpOwner],
               [fpOwner],
               [fpModificationTime],
               [fpCreationTime],
               [fpLastAccessTime],
               [fpLink],
               [fpName],
               [fpType],
               [] { invalid });

  function FormatFileFunction(FuncS: string; AFile: TFile; const AFileSource: IFileSource): string;
  function GetFileFunctionByName(FuncS: string): TFileFunction;

const
  sFuncTypeDC     = 'DC';
  sFuncTypePlugin = 'PLUGIN';

var
  FileFunctionsStr: TStringList;

implementation

uses
  uGlobs, uDefaultFilePropertyFormatter, uFileSourceProperty;

//Return type (Script or DC or Plugin etc)
function GetModType(str: String): String;
begin
  if pos('(', Str) > 0 then
    Result := Copy(Str, 1, pos('(', Str) - 1)
  else
    Result := EmptyStr;
end;

//Return name in (). (SriptName or PluginName etc)
function GetModName(str: String): String;
var
  s: String;
begin
  s := str;
  if pos('(', S) > 0 then
    Delete(s, 1, pos('(', S))
  else
    Exit(EmptyStr);

  if pos(')', s) > 0 then
    Result := Copy(s, 1, pos(')', s) - 1);
end;

//Return function name (DCFunction,PluginFunction etc)
function GetModFunctionName(str: String): String;
var
  s: String;
begin
  s := str;
  if pos('.', S) > 0 then
    Delete(s, 1, pos('.', S))
  else
    Exit(EmptyStr);

  if pos('{', S) > 0 then
    Result := Copy(s, 1, pos('{', S) - 1);
end;

// Return function parameters
function GetModFunctionParams(str: String): String;
var
  I: Integer;
  S: String;
begin
  S := str;
  I := pos('{', S);
  if I < 0 then
    Exit(EmptyStr);
  Delete(S, 1, I);
  I := pos('}', S);
  if I < 0 then
    Exit(EmptyStr);
  Result := Copy(S, 1, I - 1);
end;

function FormatFileFunction(FuncS: String; AFile: TFile; const AFileSource: IFileSource): String;
var
  AType, AName, AFunc, AParam: String;
begin
  Result := EmptyStr;
  //---------------------
  AType  := upcase(GetModType(FuncS));
  AName  := upcase(GetModName(FuncS));
  AFunc  := upcase(GetModFunctionName(FuncS));
  AParam := upcase(GetModFunctionParams(FuncS));
  //---------------------
  //Internal doublecmd function
  //------------------------------------------------------
  if AType = sFuncTypeDC then
  begin
    case TFileFunction(FileFunctionsStr.IndexOf(AFunc)) of
      fsfName:
        begin
          // Show square brackets around directories
          if gDirBrackets and (AFile.IsDirectory or
            AFile.IsLinkToDirectory) then
            Result := '[' + AFile.Name + ']'
          else
            Result := AFile.Name;
        end;

      fsfExtension:
        begin
          if AFile.Extension <> '' then
            Result := '.' + AFile.Extension;
        end;

      fsfSize:
        begin
          if (AFile.IsDirectory or AFile.IsLinkToDirectory) and
            ((not (fpSize in AFile.SupportedProperties)) or (AFile.Size = 0))
          then
            Result := '<DIR>'
          else if fpSize in AFile.SupportedProperties then
            Result := AFile.Properties[fpSize].Format(DefaultFilePropertyFormatter);
        end;

      fsfAttr:
        if fpAttributes in AFile.SupportedProperties then
          Result := AFile.Properties[fpAttributes].Format(DefaultFilePropertyFormatter);

      fsfPath:
        Result := AFile.Path;

      fsfGroup:
        if fpOwner in AFile.SupportedProperties then
          Result := AFile.OwnerProperty.GroupStr;

      fsfOwner:
        if fpOwner in AFile.SupportedProperties then
          Result := AFile.OwnerProperty.OwnerStr;

      fsfModificationTime:
        if fpModificationTime in AFile.SupportedProperties then
          Result := AFile.Properties[fpModificationTime].Format(
            DefaultFilePropertyFormatter);

      fsfCreationTime:
        if fpCreationTime in AFile.SupportedProperties then
          Result := AFile.Properties[fpCreationTime].Format(
            DefaultFilePropertyFormatter);

      fsfLastAccessTime:
        if fpLastAccessTime in AFile.SupportedProperties then
          Result := AFile.Properties[fpLastAccessTime].Format(
            DefaultFilePropertyFormatter);

      fsfLinkTo:
        if fpLink in AFile.SupportedProperties then
          Result := AFile.LinkProperty.LinkTo;

      fsfNameNoExtension:
        begin
          // Show square brackets around directories
          if gDirBrackets and (AFile.IsDirectory or
            AFile.IsLinkToDirectory) then
            Result := '[' + AFile.NameNoExt + ']'
          else
            Result := AFile.NameNoExt;
        end;

      fsfType:
        if fpType in AFile.SupportedProperties then
          Result := AFile.TypeProperty.Format(DefaultFilePropertyFormatter);
    end;
  end
  //------------------------------------------------------
  //Plugin function
  //------------------------------------------------------
  else if AType = sFuncTypePlugin then
  begin
    if fspDirectAccess in AFileSource.Properties then
    begin
      if not gWdxPlugins.IsLoaded(AName) then
        if not gWdxPlugins.LoadModule(AName) then
          Exit;
      if gWdxPlugins.GetWdxModule(AName).FileParamVSDetectStr(AFile) then
      begin
        Result := gWdxPlugins.GetWdxModule(AName).CallContentGetValue(
          AFile.FullPath, AFunc, AParam, 0);
      end;
    end;
  end;
  //------------------------------------------------------
end;

function GetFileFunctionByName(FuncS: String): TFileFunction;
var
  AType, AFunc: String;
begin
  AType := upcase(GetModType(FuncS));
  AFunc := upcase(GetModFunctionName(FuncS));

  // Only internal DC functions.
  if AType = sFuncTypeDC then
    Result := TFileFunction(FileFunctionsStr.IndexOf(AFunc))
  else
    Result := fsfInvalid;
end;

var
  i: TFileFunction;

initialization
  FileFunctionsStr := TStringList.Create;
  for i := Low(TFileFunction) to Pred(fsfInvalid) do
    FileFunctionsStr.Add(TFileFunctionStrings[i]);

finalization
  FreeAndNil(FileFunctionsStr);

end.

