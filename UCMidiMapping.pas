unit UCMidiMapping;

interface

uses Vst3Base,UVST3Instrument;

type CMidiMapping = class(TAggregatedObject,IMidiMapping)
      IVST3:IVST3Instrument;
      function getMidiControllerAssignment(busIndex: int32; channel: int16; midiControllerNumber: TCtrlNumber; out tag: TParamID): TResult; stdcall;
      constructor Create(const Controller: TVST3Instrument);
end;

implementation

uses CodeSiteLogging;

constructor CMidiMapping.Create(const Controller: TVST3Instrument);
begin
  inherited Create(controller);
  IVST3:=Controller;
  CodeSite.Send('CMidiMapping.Create');
end;

function CMidiMapping.getMidiControllerAssignment(busIndex: int32;  channel: int16; midiControllerNumber: TCtrlNumber;  out tag: TParamID): TResult;
begin
  Tag:=IVST3.GetMidiCCParamID(channel,midiControllerNumber);
  Result:= kResultOk;
end;

end.
