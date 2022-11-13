{
  I like the Scaler VST3 plugin, but I can't afford the price.
  I plan to create a alternative open source version for everyone else like me.

  Roadmap

  Create GUI to support drag and drop chord suggestions
}


unit UAthenaVst;

interface

uses UVSTInstrument, Forms, Classes, UVSTBase, UAthenaVSTDSP;

const ID_CUTOFF = 17;
const ID_RESONANCE = 18;
const ID_PULSEWIDTH = 19;

type TAthenaVSTPlugin = class (TVSTInstrument)
private
  FSimpleSynth:TSimpleSynth;
    procedure DoUpdateHostParameter(id: integer; value: double);
protected
  procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);override;
  procedure UpdateProcessorParameter(id:integer;value:double);override;
  procedure OnInitialize;override;
  procedure UpdateEditorParameter(id:integer;value:double);override;
  procedure OnEditOpen;override;
  procedure OnProgramChange(prgm:integer);override;
  procedure OnMidiEvent(byte0, byte1, byte2: integer);override;
  procedure onKeyEvent(key: integer; _on: boolean); // called from Host
  procedure doKeyEvent(key: integer; _on: boolean); // called from UI
public
end;

function GetVSTInstrumentInfo:TVSTInstrumentInfo;
implementation

{ TmyVST }

uses UAthenaVSTForm,SysUtils,Windows,ULogger;

{$POINTERMATH ON}
{$define DebugLog}

procedure TAthenaVSTPlugin.UpdateProcessorParameter(id:integer;value:double);
begin
  FSimpleSynth.UpdateParameter(id,value);
end;

procedure TAthenaVSTPlugin.Process32(samples, channels: integer; inputp, outputp: PPSingle);
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

procedure TAthenaVSTPlugin.OnInitialize;
begin
  FSimpleSynth:=TSimpleSynth.Create(44100); // a simple synth...
  AddParameter(ID_CUTOFF,'Cutoff','Cutoff','Hz',20,20000,10000);
  AddParameter(ID_RESONANCE,'Resonance','Resonance','',0,1,0);
  AddParameter(ID_PULSEWIDTH,'Pulse Width','PWM','%',0,100,50);
//  AddProgram('Program 1');
//  AddProgram('Program 2');
//  AddProgram('Program 3');
end;

procedure TAthenaVSTPlugin.OnMidiEvent(byte0, byte1, byte2: integer);
  procedure KeyEvent(key:integer;_on:boolean);
  begin
    OnKeyEvent(key,_on);
// don't do this with Cubase!    TFormAthenaVST(EditorForm).SetKey(key,_on);
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
  WriteLog('TAthenaVSTPlugin.OnMidiEvent:'+byte0.ToString+' '+byte1.ToString+' '+byte2.ToString);

  status:=byte0 and $F0;
  if status=MIDI_NOTE_ON then KeyEvent(byte1,byte2>0)
  else if status=MIDI_NOTE_OFF then KeyEvent(byte1,false)
  else if (status=MIDI_CC) and (byte1=74) then
    UpdateHostParameter(ID_CUTOFF,byte2/127); // this also updates UI
end;

procedure TAthenaVSTPlugin.OnProgramChange(prgm: integer);
begin
  if EditorForm<>NIL then
    TFormAthenaVST(EditorForm).SetProgram(prgm);
end;

procedure TAthenaVSTPlugin.OnEditOpen;
begin
  ResendParameters;
  TFormAthenaVST(EditorForm).HostUpdateParameter:=DoUpdateHostParameter;
  TFormAthenaVST(EditorForm).HostKeyEvent:=DoKeyEvent;
  TFormAthenaVST(EditorForm).HostPrgmChange:=DoProgramChange;
end;

procedure TAthenaVSTPlugin.onKeyEvent(key:integer;_on:boolean); // from Host
const MIDI_NOTE_ON = $90;
      MIDI_NOTE_OFF = $80;
begin
  FSimpleSynth.OnKeyEvent(key,_on);
end;

procedure TAthenaVSTPlugin.doKeyEvent(key:integer;_on:boolean); // from UI
const MIDI_NOTE_ON = $90;
      MIDI_NOTE_OFF = $80;
begin
  FSimpleSynth.OnKeyEvent(key,_on);
  DoMidiEvent(MIDI_NOTE_ON,key,127*ord(_on));   // just a test
end;


procedure TAthenaVSTPlugin.DoUpdateHostParameter(id: integer; value: double);
const MIDI_CC = $B0;
begin
  UpdateHostParameter(id,value);
  DoMidiEvent(MIDI_CC,id,round(127*value));   // just a test
end;

procedure TAthenaVSTPlugin.UpdateEditorParameter(id: integer;  value: double);
begin
  TFormAthenaVST(EditorForm).UpdateEditorParameter(id,value);
end;

const UID_CAthenaVSTPlugin: TGUID = '{4be90c10-36f7-46f2-b666-076a0f8bdca7}';     //unique TGUID??   OLD: '{4be90c10-36f7-46f2-b931-076a0f8bdca7}'
function GetVSTInstrumentInfo:TVSTInstrumentInfo;
begin
  with result do
  begin
    with PluginDef do
    begin
      vst3id := UID_CAthenaVSTPlugin;
      cl  := TAthenaVSTPlugin;
      name:= 'Athena';
      ecl := TFormAthenaVST;
      isSynth:=true;
      vst2id:='ATNA';    //ERMS must be 4 characters
    end;
    with factoryDef do
    begin
      vendor:='Greg Timmons';
      url:='https://www.timmons.pro';
      email:='greg@timmons.pro';
    end;
  end;
end;

end.
