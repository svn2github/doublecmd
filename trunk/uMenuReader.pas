unit uMenuReader;

interface
uses
  Windows, SysUtils, Classes, Graphics, Menus, ExtCtrls, ShellAPI, DOM, xmlread;



type
  // ���������� ������� ���� ����� ����� ���������� � ��������� AddItemsToMenu
  TMenuClick = procedure(Sender: TObject; FileName, Params: string;
                         AddParamCount: Integer);



// � ������� ������ ��������� �� ������ �������� � ������ MenuItem ������
// ����, ��������� � xml-����� XMLFileName. ���� ���� �� ������, ��� � ���
// ���������� �����-���� ������, �� ��������� ����� �������� ���� ������.
// � �������� ����������� ������ ������ ���� �� ��������� ���������������
// ��������� MenuClickPerformer(), ����������� ����
procedure AddItemsToMenu(MenuItem: TMenuItem; XMLFileName: string;
  ClickPerformer: TMenuClick = nil);

// ��������! �� ������ �������� ���� ��������� ��������� � ������ �� �����������
// � ������� �� � �������� ClickPerformer ��� ������ ������� AddItemsToMenu
// �������� ������ ���� �� ������� ������� � ������� ������ ����:
// S := StripHotkey(TMenuItem(Sender).Caption);
// ������ ������� �� ��������� �������� ������� ShellExecute()
procedure MenuClickPerformer(Sender: TObject; Command, Params: string;
                             ParamId: Integer);

implementation
type
  // Delphi �������, ����� ��� ����������� ���������� � �������, �������
  // �������� ����������� ����� � ����� ������������ ����������
  TEventOperate = class
    procedure MenuItemClick(Sender: TObject);
  end;

  TMenuItemRec = packed record
    Caption,             // �������� ������ ����
    Command,             // ��� ������������ �����
    IconFile,            // ��� ����� � �������
    Params: string;      // ������������ ���������
    ParamId,             // ����� ������ ����������
    IconIndex: Integer;  // ������ ������
  end;

var
  recList: TList; // ������ ����������
  ClickPerf: TMenuClick = MenuClickPerformer; // ���������� �� ���������
  EvOp: TEventOperate; // ���������� ������ TEventOperate
  PMenuItem: ^TMenuItemRec;

procedure MenuClickPerformer(Sender: TObject; Command, Params: string;
                             ParamId: Integer);
  function GetDir: string;
  begin
    if Pos(PathDelim, Command) = 0 then Result := '' else
      Result := ExtractFilePath(ExpandFileName(Command));
  end;
begin
  ShellExecute(GetActiveWindow, 'open', PChar(ExtractFileName(Command)),
    PChar(Params), PChar(GetDir), SW_SHOWNORMAL);
end;

procedure AddItemsToMenu(MenuItem: TMenuItem; XMLFileName: string; ClickPerformer: TMenuClick);
var
  Doc: TXMLDocument;

  procedure GetChildNodes(vNode: TDOMNode; vMItem: TMenuItem);
  var
    I: Integer;
    Node1: TDOMNode;
    Mi1: TMenuItem;
    Caption: string;
    mir: ^TMenuItemRec;
    Ic: TIcon;

    procedure ReadData();
    var
    k: Integer;
    ChildNode: TDOMNode;
    begin
      if Caption <> '' then
      begin
        New(mir);
        FillChar(mir^, SizeOf(TMenuItemRec), 0);
        mir^.Caption := Caption;
        recList.Add(mir);
        Mi1.Tag := Integer(mir);
        for k := 0 to Node1.ChildNodes.Count -1 do
          begin
            ChildNode := Node1.ChildNodes.Item[k];
            // Get command
            if ChildNode.NodeName = 'command' then
              begin
                mir^.Command := ChildNode.FirstChild.NodeValue;
              end;

            // Get file and icon index
            if ChildNode.NodeName = 'icon' then
            begin
              mir^.IconFile := ChildNode.FirstChild.NodeValue;
              if ChildNode.attributes.length > 0 then
                mir^.IconIndex := StrToInt(ChildNode.attributes[0].NodeValue);
            end;

            // ���������� ����� ���������� � ��� �����
            if ChildNode.NodeName = 'params' then
            begin
              mir^.Params := ChildNode.FirstChild.NodeValue;
              if ChildNode.attributes.length > 0 then
                mir^.ParamId := StrToInt(ChildNode.attributes[0].NodeValue);
            end;
          end; //for k
        
        if mir^.Command <> '' then
          Mi1.OnClick := EvOp.MenuItemClick;

        if mir^.IconFile <> '' then
        begin
          Ic := TIcon.Create;
          Ic.Handle := ExtractIcon(HInstance, PChar(mir^.IconFile), mir^.IconIndex);
          if Ic.Handle <> 0 then
          with TImage.Create(nil) do begin
            Width := Ic.Width;
            Height := Ic.Height;
            Canvas.Draw(0, 0, Ic);
            Mi1.Bitmap.Assign(Picture.Bitmap);
            Free;
          end;
          Ic.Free;
        end; // Icon
      end;
    end;

  begin
    for I := 0 to vNode.childNodes.Count - 1 do
    begin
      Node1 := vNode.childNodes.item[I];
      if Node1.nodeName = 'item' then
      begin
        Caption := Node1.attributes.item[0].NodeValue;
        if Caption = '' then Continue;

        if (Caption <> '-') and (vMItem.IndexOfCaption(Caption) > 0) then
        begin
          if Node1.childNodes.Count > 0 then
            GetChildNodes(Node1, vMItem.Items[vMItem.IndexOfCaption(Caption)]);
        end else
        begin
          Mi1 := TMenuItem.Create(vMItem);
          Mi1.Caption := Caption;

          ReadData();

          // ��������� �������� ������
          if (Caption <> '-') and (Node1.childNodes.Count > 0) then
            GetChildNodes(Node1, Mi1);
          vMItem.Add(Mi1);
        end;
      end;
    end; // of for I
  end;

begin
  if @ClickPerformer <> nil then ClickPerf := ClickPerformer;
  Doc := TXMLDocument.Create;
  ReadXMLFile(Doc, XMLFileName);
  MenuItem.Clear;
  if (Doc.documentElement <> nil) and (MenuItem <> nil) then
    GetChildNodes(Doc.documentElement, MenuItem);
end;

{ TEventOperate }

procedure TEventOperate.MenuItemClick(Sender: TObject);
begin
  PMenuItem := Pointer(TMenuItem(Sender).Tag);
  ClickPerf(Sender, PMenuItem^.Command, PMenuItem^.Params, PMenuItem^.ParamId);
end;

procedure FreeRecList;
var
  I: Integer;
  mir: ^TMenuItemRec;
begin
  for I := 0 to recList.Count - 1 do
  begin
    mir := recList.Items[I];
    Dispose(mir);
  end;
  recList.Free;
end;

initialization
  recList := TList.Create;
  EvOp := TEventOperate.Create;
finalization
  FreeRecList();
  EvOp.Free;
end.
