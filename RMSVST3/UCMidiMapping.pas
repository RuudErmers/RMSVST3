unit UCMidiMapping;

interface

uses Vst3Base,UVST3Controller;

type CMidiMapping = class(TAggregatedObject,IMidiMapping)
      IVST3:IVST3Controller;
      function getMidiControllerAssignment(busIndex: int32; channel: int16; midiControllerNumber: TCtrlNumber; out tag: TParamID): TResult; stdcall;
      constructor Create(const Controller: IVST3Controller);
end;

implementation

uses CodeSiteLogging;

constructor CMidiMapping.Create(const Controller: IVST3Controller);
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
