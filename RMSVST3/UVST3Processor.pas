unit UVST3Processor;

interface

uses UVSTBase, Vst3Base, UVst3Utils,Generics.Collections;

type
     IVST3Processor = interface(IVSTBase)
        procedure OnSysexEvent(s:string);
        procedure OnMidiEvent(byte0,byte1,byte2:integer);
        procedure ProcessorParameterSetValue(id:integer;value:double);
        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);
        procedure SamplerateChanged(samplerate:single);
        procedure TempoChanged(tempo:single);
        procedure PlayStateChanged(playing:boolean;ppq:integer);
        function GetProcessorState:string;
        procedure SetProcessorState(state:string);
        procedure SetActive(active:boolean);
        procedure ProcessorInitialize;
        procedure ProcessorTerminate;
     end;
     TVST3Processor = class(TVSTBase,IVST3Processor)
      private
        Factive:boolean;
        function GetProcessorState:string;
        procedure SetProcessorState(state:string);
        procedure SetActive(active:boolean);
      protected
        procedure ProcessorInitialize;virtual; // will be overridden in Controller
        procedure ProcessorTerminate;virtual;  // will be overridden in Controller
        procedure ProcessorParameterSetValue(id:integer;value:double);virtual; // will be overridden in Controller
        procedure OnSysexEvent(s:string);virtual;
        procedure OnMidiEvent(byte0,byte1,byte2:integer);virtual;
        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);virtual;
        procedure SamplerateChanged(samplerate:single);virtual;
        procedure PlayStateChanged(playing:boolean;ppq:integer);virtual;
        procedure TempoChanged(tempo:single);virtual;
        procedure UpdateProcessorParameter(id:integer;value:double);virtual;
      public
   end;


implementation

uses CodeSiteLogging,SysUtils;

procedure TVST3Processor.TempoChanged(tempo: single);
begin
// virtual
end;

procedure TVST3Processor.UpdateProcessorParameter(id: integer; value: double);
begin
// virtual
end;

procedure TVST3Processor.SetActive(active: boolean);
begin
  Factive:=active;
end;

procedure TVST3Processor.ProcessorParameterSetValue(id:integer;value:double);
begin
// virtual;
end;

procedure TVST3Processor.Process32(samples, channels: integer; inputp,  outputp: PPSingle);
begin
// virtual;
end;

procedure TVST3Processor.ProcessorInitialize;
begin
// virtual
end;

procedure TVST3Processor.ProcessorTerminate;
begin
// virtual
end;

procedure TVST3Processor.SamplerateChanged(samplerate: single);
begin
// virtual;
end;

procedure TVST3Processor.OnMidiEvent(byte0, byte1, byte2: integer);
begin
// virtual
end;

function TVST3Processor.GetProcessorState:string;
begin
// Not implemented, no need for
end;

procedure TVST3Processor.SetProcessorState(state:string);
begin
// Not implemented, no need for
end;

procedure TVST3Processor.OnSysexEvent(s: string);
begin
// virtual;
end;

procedure TVST3Processor.PlayStateChanged(playing: boolean; ppq: integer);
begin
// virtual
end;


end.
