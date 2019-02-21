unit UCAudioProcessor;

interface

uses Vst3Base,UVST3Base,UVST3Processor;

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

uses CodeSiteLogging, SysUtils;

function CAudioProcessor.CanProcessSampleSize( symbolicSampleSize: int32): TResult;
begin
  CodeSite.Send('CAudioProcessor.CanProcessSampleSize');
  result:=kResultFalse;
  if symbolicSampleSize=kSample32 then result:=kResultTrue;
end;

constructor CAudioProcessor.Create(const Controller: IVST3Processor);
begin
  inherited Create(controller);
  IVST3:=Controller;
  CodeSite.Send('CAudioProcessor.Create');
  FhostContext:=NIL;
end;

function CAudioProcessor.GetBusArrangement(dir: TBusDirection; index: int32;  var arr: TSpeakerArrangement): TResult;
begin
  CodeSite.Send('CAudioProcessor.GetBusArrangement');
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
//  CodeSite.Send('CAudioProcessor.GetLatencySamples');
  result:=0;
end;

function CAudioProcessor.GetTailSamples: uint32;
begin
  CodeSite.Send('CAudioProcessor.GetTailSamples');
  result:=kNoTail;
end;

{$POINTERMATH ON}

function CAudioProcessor.Process(var data: TProcessData): TResult;
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
          kNoteOnEvent       : with event.noteOn do IVST3.NoteOn(channel,pitch,round(127*velocity));
          kNoteOffEvent      :  with event.noteOff do IVST3.NoteOff(channel,pitch,round(127*velocity));
          kDataEvent         : IVST3.SysExEvent(ToSysEx);
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
        FQueue:TVST3AutomationQueue;
        value:TParamValue;
    begin
      numParamsChanged := data.inputParameterChanges.getParameterCount;
      for index := 0 to numParamsChanged-1 do
      begin
        paramQueue:=data.inputParameterChanges.getParameterData(index);
        if (paramQueue<>NIL) then
        begin
          paramQueue._AddRef; // ??? TODO: I am truly not sure on this...
          numPoints := paramQueue.getPointCount;
          FQueue:=TVST3AutomationQueue.Create(paramQueue.getParameterId);
          for j:=0 to numPoints-1 do
                  if (paramQueue.getPoint (j, sampleOffset, value) = kResultTrue) then
                    FQueue.Add(sampleOffset,value);
          IVST3.AutomationReceive(FQueue);
          FQueue.Free;
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
//  CodeSite.Send('CAudioProcessor.Process');
  if (data.inputEvents<>NIL) then ProcessEvents;
  if (data.inputParameterChanges<>NIL) then ProcessParameters;
  if (data.numSamples>0) then ProcessAudio;
  if data.processContext<>NIL then ProcessContext;
	result:=kResultTrue;
end;


function CAudioProcessor.SetBusArrangements(inputs: PSpeakerArrangement;  numIns: int32; outputs: PSpeakerArrangement; numOuts: int32): TResult;
begin
  CodeSite.Send('CAudioProcessor.SetBusArrangement');
	result:=kResultTrue;
end;

function CAudioProcessor.SetProcessing(state: TBool): TResult;
begin
  CodeSite.Send('CAudioProcessor.SetProcessing');
	result:=kResultTrue;
end;


function CAudioProcessor.SetupProcessing(var setup: TProcessSetup): TResult;
begin
  CodeSite.Send('CAudioProcessor.SetupProcessing');
	result:=kResultTrue;
(* JUCE Version
   if (canProcessSampleSize (newSetup.symbolicSampleSize) != kResultTrue)
            return kResultFalse;

        processSetup = newSetup;
        processContext.sampleRate = processSetup.sampleRate;

        getPluginInstance().setProcessingPrecision (newSetup.symbolicSampleSize == Vst::kSample64
                                                        ? AudioProcessor::doublePrecision
                                                        : AudioProcessor::singlePrecision);

        preparePlugin (processSetup.sampleRate, processSetup.maxSamplesPerBlock);

        return kResultTrue;
   JUCE Version *)
end;


end.
