unit UCDataLayer;

interface

uses Classes;

type TDataLayer = class(TStringList)
  private
  protected
  public
    procedure SetAttribute(attrib,value:string);
    procedure SetAttributeI(attrib:string;value:integer);
    procedure SetAttributeB(attrib:string;value:boolean);
    function GetAttribute(attrib:string):string;
    function GetAttributeI(attrib:string;defValue:integer=0):integer;
    function GetAttributeB(attrib:string):boolean;
    function LoadSection(SectionName:string;sl:Tstrings):boolean;
    function SaveSection(SectionName:string;sl:Tstrings):boolean;
    constructor create(sl:TStringlist);overload;
end;

implementation

uses SysUtils,CodeSiteLogging;

procedure RemoveSection(data:TStringList;sectionname:string);
VAR i, istart,istop:integer;
begin
  istart:=-1;
  istop:=0;
  for i:=0 to data.Count-1 do
  begin
    if data.Strings[i]='['+sectionname+']' then Istart:=i;
    if data.Strings[i]='[~'+sectionname+']' then IStop:=i;
  end;
  if istart=-1 then exit;
  for i:=istop downto istart do data.Delete(i);
end;

procedure AddSection(data:TStringList;sectionname:string;sl:Tstrings);
VAR i:integer;
begin
  data.Add('['+sectionname+']');
  for i:=0 to sl.Count-1 do
    data.Add(sl[i]);
  data.Add('[~'+sectionname+']')
end;

function SlLoadSection(data:TStringList;sectionname: string;sl:Tstrings): boolean;
Var i:integer;
    InSection:Boolean;
begin
  sl.Clear;
  InSection:=false;
  for i:=0 to data.Count-1 do
  begin
    if UpperCase(data.Strings[i])=UpperCase('['+sectionname+']') then InSection:=true
    else if UpperCase(data.Strings[i])=UpperCase('[~'+sectionname+']') then InSection:=false
    else if InSection then sl.Add(data.Strings[i]);
  end;
end;

function SlSaveSection(data:TStringList;sectionname: string;sl:Tstrings): boolean;
begin
  RemoveSection(data,sectionname);
  AddSection(data,sectionname,sl);
end;

constructor TDataLayer.create(sl: TStringlist);
begin
  inherited create;
  assign(sl);
end;


function TDataLayer.LoadSection(SectionName:string;sl:Tstrings):boolean;
begin
  SlLoadSection(self,SectionName,sl);
end;

function TDataLayer.SaveSection(SectionName: string;  sl: Tstrings): boolean;
begin
  SlSaveSection(self,SectionName,sl);
end;

procedure TDataLayer.SetAttribute(attrib,value:string);
VAR i:integer;
    InSection:boolean;
begin
  InSection:=false;
  for i:=0 to count-1 do
  begin
    if 1 = pos('[',self[i]) then
      InSection:= 1 <> pos('[~',self[i]);
    if not InSection and (1 = pos(UpperCase(attrib+'='),UpperCase(self[i]))) then
    begin
      self[i]:=attrib+'='+value;
      exit;
    end;
  end;
  Add(attrib+'='+value);
end;

procedure TDataLayer.SetAttributeB(attrib: string; value: boolean);
begin
  SetAttribute(attrib,inttostr(ord(value)));
end;

procedure TDataLayer.SetAttributeI(attrib: string; value: integer);
begin
  SetAttribute(attrib,inttostr(value));
end;

function TDataLayer.GetAttribute(attrib: string): string;
Var i:integer;
begin
  result:='';
  for i:=0 to count-1 do if
   1 = pos(UpperCase(attrib+'='),UpperCase(self[i])) then
   begin
     result:=Copy(self[i],length(attrib)+2);
     exit;
   end;
end;


function TDataLayer.GetAttributeB(attrib: string): boolean;
begin
  result:=GetAttribute(attrib)='1';
end;

function TDataLayer.GetAttributeI(attrib: string;
  defValue: integer): integer;
begin
  result:=StrToIntDef(GetAttribute(attrib),defValue)
end;

end.


