unit UVST3Utils;

interface

uses Vst3Base;

function UIDMatch(tud:TUID;iid:PAnsiChar):boolean;
function UIDPCharToNiceString(iid: PAnsiChar):string;
function PAnsiCharToTGUID(iid:PAnsiChar):TGUID;
procedure AssignString(VAR target: array of AnsiChar; source:string);overload;
procedure AssignString(VAR target: array of TChar; source:string);overload;
procedure WriteStream(stream:IBStream;magic:integer;s:string);
function  ReadStream(stream:IBStream;magic:integer):string;

const STREAMMAGIC_CONTROLLER = 34873946;
const STREAMMAGIC_PROCESSOR =  84333967;

implementation

uses SysUtils;

function PAnsiCharToTGUID(iid:PAnsiChar):TGUID;
VAR tud:TUID;
    i:integer;
begin
  for i:=0 to 15 do tud[i]:=ord(iid[i]);
  result:=TGUID(tud);
end;

function UIDPCharToString(iid:PAnsiChar):string;
VAR i:integer;
begin
  result:='';
  for i:=0 to 15 do result:=result+IntToHex(ord(iid[i]));
end;

function UIDMatch(tud:TUID;iid:PAnsiChar):boolean;
   VAR i:integer;
begin
  result:=false;
  for i:=0 to 15 do if ord(iid[i])<>tud[i] then exit;
  result:=true;
end;

function UIDPCharToNiceString(iid: PAnsiChar):string;
begin
  result:=UIDPCharToString(iid);
  if UIDMatch(TUID(UID_IComponent),iid) then result:='UID_IComponent';
  if UIDMatch(TUID(UID_IAudioProcessor),iid) then result:='UID_IAudioProcessor';
  if UIDMatch(TUID(UID_IEditController),iid) then result:='UID_IEditController';

  if UIDMatch(TUID(UID_IConnectionPoint),iid) then result:='UID_IConnectionPoint';
  if UIDMatch(TUID(UID_IUnitData),iid) then result:='UID_IUnitData';
  if UIDMatch(TUID(UID_IProgramListData),iid) then result:='UID_IProgramListData';
end;

procedure AssignString(VAR target: array of TChar; source:string);
VAR i,l:integer;
begin
  l:=length(source);
  if l>=high(target) then l:=high(target)-1;
  for i:=0 to l-1 do
    target[i]:=source[i+1];
  target[l]:=#0;
end;

procedure AssignString(VAR target: array of AnsiChar; source:string);
VAR i,l:integer;
begin
  l:=length(source);
  if l>=high(target) then l:=high(target)-1;
  for i:=0 to l-1 do
    target[i]:=AnsiChar(source[i+1]);
  target[l]:=#0;
end;

procedure WriteStream(stream:IBStream;magic:integer;s:string);
VAR buffer:TBytes;
    i,l:integer;
begin
  l:=magic;
  stream.write(@l,sizeof(integer));
  l:=Length(s);
  stream.write(@l,sizeof(integer));
  SetLength(buffer,l);
  for i:=0 to l-1 do
     buffer[i]:=ord(s[i+1]);
  stream.Write(Buffer, l);
end;

function  ReadStream(stream:IBStream;magic:integer):string;
VAR buffer:TBytes;
    s:string;
    i,l:integer;
begin
  stream.read(@l,sizeof(integer));
  result:='';
  if l<>magic then exit;
  stream.read(@l,sizeof(integer));
  SetLength(buffer,l);
  stream.read(buffer,l);
    for i:=0 to l-1 do
      result:=result+chr(buffer[i]);
end;

end.
