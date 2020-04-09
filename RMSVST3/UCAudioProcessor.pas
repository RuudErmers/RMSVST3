unit UCAudioProcessor;

interface

uses Vst3Base,UVST3Processor;

type CAudioProcessor = class(TAggregatedObject,IAudioProcessor)
private
  FHostContext:FUnknown;
  IVST3:IVST3Processor;
  FSamplerate,Ftempo:single;
  FPPQ:integer;
  FPlaying:boolean;
public
  function SetBusArrangements(inputs: PSpeakerArrangement; numIns: int32; outputs: PSpeakerArrangement; numOuts: int32): TResult; stdcall;
  function GetBusArrangement(dir: TBusDirection; index: int32; var arr: TSpeakerArrangement): TResult; stdcall;
  function CanProcessSampleSize(symbolicSampleSize: int32): TResult; stdcall;
  function GetLatencySamples: uint32; stdcall;
  function SetupProcessing(var setup: TProcessSetup): TResult; stdcall;
  function SetProcessing(state: TBool): TResult; stdcall;
  function Process(var data: TProcessData): TResult; stdcall;
  function GetTailSamples: uint32; stdcall;
  constructor Create(const Controller:  IVST3Processor);
end;

implementation

{ CAudioProcessor }

uses UCodeSiteLogger, SysUtils, UVSTBase;

function CAudioProcessor.CanProcessSampleSize( symbolicSampleSize: int32): TResult;
begin
  WriteLog('CAudioProcessor.CanProcessSampleSize:'+symbolicSampleSize.ToString);
  result:=kResultFalse;
  if symbolicSampleSize=kSample32 then
     result:=kResultTrue;
end;

constructor CAudioProcessor.Create(const Controller: IVST3Processor);
begin
  WriteLog('CAudioProcessor.Create');
  inherited Create(controller);
  IVST3:=Controller;
  FhostContext:=NIL;
end;

function CAudioProcessor.GetBusArrangement(dir: TBusDirection; index: int32;  var arr: TSpeakerArrangement): TResult;
begin
  WriteLog('CAudioProcessor.GetBusArrangement');
  arr:=3; //
(* JUCE Version
        if (auto* bus = pluginInstance->getBus (dir == Vst::kInput, index))
        {
            arr = getVst3SpeakerArrangement (bus->getLastEnabledLayout());
            return kResultTrue;
        }

        return kResultFalse;
   JUCE Version *)
	result:=kResultTrue;
end;


function CAudioProcessor.GetLatencySamples: uint32;
begin
//  WriteLog('CAudioProcessor.GetLatencySamples');
  result:=0;
end;

function CAudioProcessor.GetTailSamples: uint32;
begin
  WriteLog('CAudioProcessor.GetTailSamples');
  result:=kNoTail;
end;

{$POINTERMATH ON}

function CAudioProcessor.Process(var data: TProcessData): TResult;
const MIDI_NOTE_ON = $90;
      MIDI_NOTE_OFF = $80;
      MIDI_CC = $B0;
    procedure ProcessMidiOut;
    VAR buffer:TArray<integer>;
    VAR event:TVstEvent;
        i,status,midichannel,data1,data2:integer;
        doAdd:boolean;
    begin
      buffer:=IVST3.GetMidiOutputEvents;
      for i:=0 to length(buffer)-1 do
      begin
       	event.busIndex := 0;
	      event.sampleOffset := 0;
    	  event.ppqPosition := 0;
    	  event.flags := 0;
        status:=buffer[i] and $F0;
        midichannel:=buffer[i] and $F;
        data1:= (buffer[i] SHR 8) and $7F;
        data2:= (buffer[i] SHR 16) and $7F;
        doAdd:=true;
        case status of
          MIDI_NOTE_ON:  begin
                           event.eventType := kNoteOnEvent;
                     	     event.noteOn.channel:= midichannel;
                      	   event.noteOn.pitch := data1;
                     	     event.noteOn.velocity := data2/127;
                         end;
          MIDI_NOTE_OFF: begin
                           event.eventType := kNoteOffEvent;
                     	     event.noteOn.channel:= midichannel;
                      	   event.noteOn.pitch := data1;
                     	     event.noteOn.velocity := data2/127;
                         end;
          MIDI_CC:       begin
    	                     event.eventType := kLegacyMIDICCOutEvent;
                     	     event.midiCCOut.channel := midichannel;
                      	   event.midiCCOut.controlNumber := data1;
                     	     event.midiCCOut.value := data2;
                         end;
          else doAdd:=false;
        end;
        if doAdd then data.outputEvents.AddEvent(event);
      end;
    end;
    procedure ProcessEvents;
    VAR numEvents,index:integer;
        event:TVstEvent;
    function ToSysEx:string;
    VAR i:integer;
    begin
      result:='';
      for i:=0 to event.data.size-1 do result:=result+chr(event.data.bytes[i]);
    end;

    begin
      numEvents:=data.inputEvents.GetEventCount;

      for index:=0 to numEvents-1 do
      begin
        data.inputEvents.GetEvent(index,event);
        case event.eventType of
          kNoteOnEvent       : with event.noteOn do IVST3.OnMidiEvent(channel+MIDI_NOTE_ON,pitch,round(127*velocity));
          kNoteOffEvent      :  with event.noteOff do IVST3.OnMidiEvent(channel+MIDI_NOTE_OFF,pitch,round(127*velocity));
          kDataEvent         : IVST3.OnSysExEvent(ToSysEx);
  (* not implemented...
          kPolyPressureEvent : (poly: TPolyPressureEvent);
          kNoteExpressionValueEvent : (exprValue: TNoteExpressionValueEvent);
          kNoteExpressionTextEvent  : (exprText: TNoteExpressionTextEvent);  *)
        end;
      end;
    end;
    procedure ProcessParameters;
    VAR index,numParamsChanged,numPoints,j:integer;
        paramQueue:IParamValueQueue;
     		sampleOffset:integer;
        value:TParamValue;
    begin
      numParamsChanged := data.inputParameterChanges.getParameterCount;
      for index := 0 to numParamsChanged-1 do
      begin
        paramQueue:=data.inputParameterChanges.getParameterData(index);
        if (paramQueue<>NIL) then
        begin
          WriteLog('CAudioProcessor.ProcessParameters');

          paramQueue._AddRef; // ??? TODO: I am truly not sure on this...
          numPoints := paramQueue.getPointCount;
          for j:=0 to numPoints-1 do
                  if (paramQueue.getPoint (j, sampleOffset, value) = kResultTrue) then
                     IVST3.ProcessorParameterSetValue(paramQueue.getParameterId,value);
         end;
      end;
    end;
    procedure ProcessAudio;
    VAR inputbus,outputbus:TAudioBusBuffers;
        inputp,outputp:PPSingle;
    begin
      inputbus:=data.inputs[0];
      outputbus:=data.outputs[0];
      inputp:=PPSingle(inputbus.channelBuffers32);
      outputp:=PPSingle(outputbus.channelBuffers32);
      IVST3.Process32(data.numSamples,2,inputp,outputp);
    end;
    procedure ProcessContext;
    VAR newTempo,newSampleRate:single;
        newPPQ:integer;
        newPlaying,playStateChanged:boolean;
        state:TStatesAndFlags;
    begin
      state:=data.processContext.state;
      newSamplerate:=data.processContext.sampleRate;
      if (newSamplerate<>FSampleRate)  then
      begin
        FSampleRate:=NewSampleRate;
        IVST3.SamplerateChanged(FSamplerate);
      end;
      newTempo:=data.processContext.tempo;
      if (newTempo<>FTempo) and (state and kTempoValid <> 0) then
      begin
        FTempo:=NewTempo;
        IVST3.TempoChanged(FTempo);
      end;
      playstateChanged:=false;
      newPPQ:=trunc(data.processContext.projectTimeMusic);
      if (newPPQ<>FPPQ) then
      begin
        FPPQ:=NewPPQ;
        playStateChanged:=true;
      end;
      newPlaying:=state and kPlaying <> 0;
      if (newPlaying<>FPlaying) then
      begin
        FPlaying:=NewPlaying;
        playStateChanged:=true;
      end;
      if playstateChanged then IVST3.PlayStateChanged(FPlaying,FPPQ);
    end;
begin

  try
    if (data.inputEvents<>NIL) then ProcessEvents;
    if (data.inputParameterChanges<>NIL) then ProcessParameters;
    if (data.numSamples>0) then ProcessAudio;
    if data.processContext<>NIL then ProcessContext;
    if data.outputEvents<>NIL then ProcessMidiOut;
  except end;
	result:=kResultTrue;
end;


function CAudioProcessor.SetBusArrangements(inputs: PSpeakerArrangement;  numIns: int32; outputs: PSpeakerArrangement; numOuts: int32): TResult;
begin
  WriteLog('CAudioProcessor.SetBusArrangement');
	result:=kResultTrue;
end;

function CAudioProcessor.SetProcessing(state: TBool): TResult;
begin
  WriteLog('CAudioProcessor.SetProcessing');
	result:=kResultTrue;
end;


function CAudioProcessor.SetupProcessing(var setup: TProcessSetup): TResult;
begin
  WriteLog('CAudioProcessor.SetupProcessing');
	result:=kResultTrue;
end;


end.
