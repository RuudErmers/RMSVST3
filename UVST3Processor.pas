unit UVST3Processor;

interface

uses UVST3Base, Vst3Base, Generics.Collections;

type
     IVST3Processor = interface(IVST3Base)
        procedure NoteOn(channel,pitch,velocity:integer);
        procedure NoteOff(channel,pitch,velocity:integer);
        procedure SysexEvent(s:string);
        procedure AutomationReceive(queue:TVST3AutomationQueue);
        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);
        procedure SamplerateChanged(samplerate:single);
        procedure TempoChanged(tempo:single);
        procedure PlayStateChanged(playing:boolean;ppq:integer);
        procedure GetProcessorState(stream:IBStream);
        procedure SetProcessorState(stream:IBStream);
        procedure SetActive(active:boolean);
     end;
     TVST3Processor = class(TVST3Base,IVST3Processor)
      protected
        Factive:boolean;
        procedure GetProcessorState(stream:IBStream);virtual;
        procedure SetProcessorState(stream:IBStream);virtual;
        procedure SetActive(active:boolean);virtual;
        procedure AutomationReceive(queue:TVST3AutomationQueue);

        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);virtual;
        procedure NoteOn(channel,pitch,velocity:integer);virtual;
        procedure NoteOff(channel,pitch,velocity:integer);virtual;
        procedure SysexEvent(s:string);virtual;
        procedure SamplerateChanged(samplerate:single);virtual;
        procedure TempoChanged(tempo:single);virtual;
        procedure PlayStateChanged(playing:boolean;ppq:integer);virtual;
        procedure OnAutomationReceived(queue:TVST3AutomationQueue);virtual;
        procedure OnMidiCC(channel,cc,value:integer);virtual;
   end;


implementation

procedure TVST3Processor.TempoChanged(tempo: single);
begin
// virtual
end;

procedure TVST3Processor.SetActive(active: boolean);
begin
  Factive:=active;
end;

function isMidiCCId(id:integer):boolean;
begin
  result:=(id>=MIDICC_SIMULATION_START) and (id<=MIDICC_SIMULATION_LAST);
end;

procedure TVST3Processor.AutomationReceive(queue: TVST3AutomationQueue);
VAR i,index:integer;
begin
  if isMidiCCId(queue.id) then
  begin
    index:=queue.id-MIDICC_SIMULATION_START;
    for i:=0 to queue.Count-1 do
      OnMidiCC(index DIV 128, index MOD 128,round(127*queue.get(i).value))
  end
  else
    OnAutomationReceived(queue);
end;

procedure TVST3Processor.Process32(samples, channels: integer; inputp,  outputp: PPSingle);
begin
end;

procedure TVST3Processor.SamplerateChanged(samplerate: single);
begin
// virtual;
end;

procedure TVST3Processor.OnAutomationReceived(queue: TVST3AutomationQueue);
begin
//  virtual;
end;

procedure TVST3Processor.OnMidiCC(channel,cc, value: integer);
begin
//  virtual;
end;

procedure TVST3Processor.GetProcessorState(stream: IBStream);
begin
//  virtual;
end;

procedure TVST3Processor.SetProcessorState(stream: IBStream);
begin
//  virtual;
end;

procedure TVST3Processor.SysexEvent(s: string);
begin

end;

procedure TVST3Processor.PlayStateChanged(playing: boolean; ppq: integer);
begin
// virtual
end;

procedure TVST3Processor.NoteOff(channel, pitch, velocity: integer);
begin
// virtual...
end;

procedure TVST3Processor.NoteOn(channel, pitch, velocity: integer);
begin
// virtual...
end;

end.
