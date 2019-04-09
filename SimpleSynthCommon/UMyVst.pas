unit UMyVst;

interface

uses UVSTInstrument,Forms, Classes,UVSTBase,UMyVSTDSP;
type TOnParameterChanged = procedure (id:integer;value:double) of object;

const ID_CUTOFF = 17;
const ID_RESONANCE = 18;
const ID_PULSEWIDTH = 19;

type TMyVSTPlugin = class (TVSTInstrument)
private
  FSimpleSynth:TSimpleSynth;
protected
  procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);override;
  procedure UpdateProcessorParameter(id:integer;value:double);override;
  procedure OnInitialize;override;
  procedure UpdateEditorParameter(id:integer;value:double);override;
  procedure OnEditOpen;override;
  procedure OnPresetChange(prgm:integer);override;
  procedure OnMidiEvent(byte0, byte1, byte2: integer);override;
  procedure onKeyEvent(key: integer; _on: boolean);
public
end;

function GetVSTInstrumentInfo:TVSTInstrumentInfo;
implementation

{ TmyVST }

uses UMyVSTForm,SysUtils,Windows,CodeSiteLogging;

{$POINTERMATH ON}
{$define DebugLog}

procedure TMyVSTPlugin.UpdateProcessorParameter(id:integer;value:double);
begin
  FSimpleSynth.UpdateParameter(id,value);
end;

procedure TMyVSTPlugin.Process32(samples, channels: integer; inputp, outputp: PPSingle);
VAR i,channel:integer;
    sample:single;
begin
  for i:=0 to samples-1 do
  begin
    sample:=FSimpleSynth.process;
    for channel:=0 to 1 do
      outputp[channel][i]:=sample;
  end;
end;

procedure TMyVSTPlugin.OnInitialize;
begin
  FSimpleSynth:=TSimpleSynth.Create(44100); // a simple synth...
  AddParameter(ID_CUTOFF,'Cutoff','Cutoff','Hz',20,20000,10000);
  AddParameter(ID_RESONANCE,'Resonance','Resonance','',0,1,0);
  AddParameter(ID_PULSEWIDTH,'Pulse Width','PWM','%',0,100,50);
end;

procedure TMyVSTPlugin.OnMidiEvent(byte0, byte1, byte2: integer);
  procedure KeyEvent(key:integer;_on:boolean);
  begin
    OnKeyEvent(key,_on);
    TFormMyVST(EditorForm).SetKey(key,_on);
  end;
VAR status:integer;
const MIDI_NOTE_ON = $90;
      MIDI_NOTE_OFF = $80;
      MIDI_CC = $B0;
begin
  // careful:
  // OnMidiEvent can be called from NON-UI thread. (in VST3)
  // Update UI on own risk
  // in this case we need to update the keyboard in the form
  // note that for parameter based changed, you only have to update the processor
  // we COULD make an extra method in the fw OnMidiEventEditor, but that should be discussed
  // this is perhaps one of the reasons Steinberg chose to 'depricate' midi stuff
  status:=byte0 and $F0;
  if status=MIDI_NOTE_ON then KeyEvent(byte1,byte2>0)
  else if status=MIDI_NOTE_OFF then KeyEvent(byte1,false)
  else if (status=MIDI_CC) and (byte1=74) then
    UpdateHostParameter(ID_CUTOFF,byte2/127); // this also updates UI
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
  TFormMyVST(EditorForm).OnKeyEvent:=OnKeyEvent;
end;

procedure TMyVSTPlugin.onKeyEvent(key:integer;_on:boolean);
begin
  FSimpleSynth.OnKeyEvent(key,_on);
end;

procedure TMyVSTPlugin.UpdateEditorParameter(id: integer;  value: double);
begin
  TFormMyVST(EditorForm).UpdateEditorParameter(id,value);
end;

const UID_CMyVSTPlugin: TGUID = '{4be90c10-36f7-46f2-b931-076a0f8bdca7}';
function GetVSTInstrumentInfo:TVSTInstrumentInfo;
begin
  with result do
  begin
    with PluginDef do
    begin
      vst3id := UID_CMyVSTPlugin;
      cl  := TMyVSTPlugin;
      name:= 'SimpleSynth';
      ecl := TFormMyVST;
      isSynth:=true;
      vst2id:='ERMS';
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
