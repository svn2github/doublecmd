{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit KASComp; 

interface

uses
  KASToolBar, KASBarMenu, KASBarFiles, KASProgressBar, KASPathEdit, 
  LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('KASToolBar', @KASToolBar.Register); 
  RegisterUnit('KASBarMenu', @KASBarMenu.Register); 
  RegisterUnit('KASProgressBar', @KASProgressBar.Register); 
  RegisterUnit('KASPathEdit', @KASPathEdit.Register); 
end; 

initialization
  RegisterPackage('KASComp', @Register); 
end.
