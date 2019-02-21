unit UMyVst;

interface

uses UVST3Instrument,UVST3Base,Forms;
type TOnParameterChanged = procedure (id:integer;value:double) of object;

type TMyVSTPlugin = class (TVST3Instrument)
  FGain:double;
  procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);override;
  procedure OnAutomationReceived(queue: TVST3AutomationQueue);override;
  procedure OnInitialize;override;
  procedure UpdateEditorParameter(id:integer;value:double);override;
  procedure OnEditOpen; override;
  procedure OnPresetChange(prgm:integer);override;
end;

function GetVST3InstrumentInfo:TVST3InstrumentInfo;
implementation

{ TmyVST }

uses UMyVSTForm;

{$POINTERMATH ON}

const ID_GAIN = 17;


procedure TMyVSTPlugin.OnAutomationReceived(queue: TVST3AutomationQueue);
begin
  if queue.id = ID_GAIN then
     FGain:=queue.last;
end;

procedure TMyVSTPlugin.Process32(samples, channels: integer; inputp, outputp: PPSingle);
VAR i,channel:integer;
begin
    for channel:=0 to 1 do
      for i:=0 to samples-1 do
        outputp[channel][i]:=FGain*inputp[channel][i];
end;

procedure TMyVSTPlugin.OnInitialize;
begin
  AddParameter(ID_GAIN,'Volume','Volume','Db',0,100,60);
  AddParameter(ID_GAIN+1,'Volume2','Volume2','Db',0,100,60);
end;

procedure TMyVSTPlugin.OnPresetChange(prgm: integer);
begin
  if EditorForm<>NIL then
    TFormMyVST(EditorForm).SetPreset(prgm);
end;

procedure TMyVSTPlugin.OnEditOpen;
begin
  ResendParameters;
  TFormMyVST(EditorForm).UpdateHostParameter:=UpdateHostParameter;
end;

procedure TMyVSTPlugin.UpdateEditorParameter(id: integer;  value: double);
begin
  TFormMyVST(EditorForm).UpdateEditorParameter(id,value);
end;

const UID_CMyVSTPlugin: TGUID = '{4be90c10-36f7-46f2-b931-076a0f8bdca7}';
function GetVST3InstrumentInfo:TVST3InstrumentInfo;
begin
  with result do
  begin
    with PluginDef do
    begin
      uid := UID_CMyVSTPlugin;
      cl  := TMyVSTPlugin;
      name:= 'Ermers Gain';
      ecl := TFormMyVST;
      isSynth:=false;
    end;
    with factoryDef do
    begin
      vendor:='Ermers Consultancy';
      url:='www.ermers.org';
      email:='ruud@ermers.org';
    end;
  end;
end;


end.
