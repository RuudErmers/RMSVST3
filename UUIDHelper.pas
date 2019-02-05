unit UUIDHelper;

interface

uses Vst3Base;

function UIDMatch(tud:TUID;iid:PAnsiChar):boolean;
function UIDPCharToNiceString(iid: PAnsiChar):string;
function PAnsiCharToTGUID(iid:PAnsiChar):TGUID;

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


end.
