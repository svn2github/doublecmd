{ Этот файл был автоматически создан Lazarus. Н�
  � редактировать!
  Исходный код используется только для комп�
    �ляции и установки пакета.
 }

unit KASComp; 

interface

uses
  KASEdit, KASToolBar, KASBarMenu, KASBarFiles, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('KASEdit', @KASEdit.Register); 
  RegisterUnit('KASToolBar', @KASToolBar.Register); 
  RegisterUnit('KASBarMenu', @KASBarMenu.Register); 
end; 

initialization
  RegisterPackage('KASComp', @Register); 
end.
