unit UCComponent;

interface

uses Vst3Base,UVST3Processor;

type CComponent = class(TAggregatedObject,IComponent,IPluginBase)
private
  FHostContext:FUnknown;
  IVST3:IVST3Processor;
public
  function GetControllerClassId(var classId: TUID): TResult; stdcall;
  // Called before 'initialize' to set the component usage (optional).
  function SetIoMode(mode: TIoMode): TResult; stdcall;
  // Called after the plug-in is initialized.
  function GetBusCount(vType: TMediaType; dir: TBusDirection): int32; stdcall;
  // Called after the plug-in is initialized.
  function GetBusInfo(vType: TMediaType; dir: TBusDirection; index: int32; var bus: TBusInfo): TResult; stdcall;
  // Retrieve routing information (to be implemented when more than one regular input or output bus exists).
  // The inInfo always refers to an input bus while the returned outInfo must refer to an output bus!
  function GetRoutingInfo(var inInfo: TRoutingInfo; var outInfo: TRoutingInfo): TResult; stdcall;
  // Called upon (de-)activating a bus in the host application.
  function ActivateBus(vType: TMediaType; dir: TBusDirection; index: int32; state: TBool): TResult; stdcall;
  // Activate / deactivate the component.
  function SetActive(state: TBool): TResult; stdcall;
  // Set complete state of component.
  function SetState(state: IBStream): TResult; stdcall;
  // Retrieve complete state of component.
  function GetState(state: IBStream): TResult; stdcall;

  function Initialize(context: FUnknown): TResult; stdcall;

  (** This function is called, before the plugin is unloaded and can be used for
  cleanups. You have to release all references to any host application interfaces. *)
  function Terminate: TResult; stdcall;
  constructor Create(const Controller: IVST3Processor);
end;


implementation

{ CComponent }

uses UCodeSiteLogger,UVST3Utils;

function CComponent.ActivateBus(vType: TMediaType; dir: TBusDirection;  index: int32; state: TBool): TResult;
begin
//  WriteLog('CComponent.ActivateBus');
  result:=kResultOk;
end;

constructor CComponent.Create(const Controller: IVST3Processor);
begin
  inherited Create(controller);
  IVST3:=Controller;
end;

function CComponent.GetBusCount(vType: TMediaType; dir: TBusDirection): int32;
begin
//  WriteLog('CComponent.GetBusCount');
  result:=1; // just one in and out
end;

function CComponent.GetBusInfo(vType: TMediaType; dir: TBusDirection; index: int32; var bus: TBusInfo): TResult;
begin
 // WriteLog('CComponent.GetBusInfo');
  bus.mediaType:=vType;
  bus.direction:=dir;
  bus.name:='RMS Bus';
  bus.channelCount :=2;           // number of channels
  bus.busType      :=0;        // main or aux
  bus.flags        :=0;          // flags
  result:=kResultOk;
end;

function CComponent.GetControllerClassId(var classId: TUID): TResult;
begin
  WriteLog('CComponent.GetControllerClassId');
  classId:=TUID(IVST3.GetPluginInfo.PluginDef.vst3id);
  result:=kResultOk;
end;

function CComponent.GetRoutingInfo(var inInfo, outInfo: TRoutingInfo): TResult;
begin
  WriteLog('CComponent.GetRoutingInfo');
  result:=kResultOk;
end;

function CComponent.GetState(state: IBStream): TResult;
begin
  WriteLog('CComponent.GetState');
// In reaper,and with a combined Component, EditController it is not needed to Getstate/SetState
  WriteStream(state,STREAMMAGIC_PROCESSOR,IVST3.GetProcessorState);
  result:=kResultOk;
end;

function CComponent.Initialize(context: FUnknown): TResult;
begin
  result:=kResultOk;
  WriteLog('CComponent.Initialize');
  if FhostContext <> NIL then exit;
  FHostContext:=context;
  FHostContext._addRef;
  IVST3.ProcessorInitialize;
end;

function CComponent.SetActive(state: TBool): TResult;
begin
  WriteLog('CComponent.SetActive');
  IVST3.SetActive(state<>0);
  result:=kResultOk;
end;

function CComponent.SetIoMode(mode: TIoMode): TResult;
begin
  WriteLog('CComponent.SetIoMode');
  result:=kNotImplemented;
end;

function CComponent.SetState(state: IBStream): TResult;
begin
  WriteLog('CComponent.SetState');
// In reaper,and with a combined Component, EditController is not needed to Getstate/SetState
  IVST3.SetProcessorState(ReadStream(state,STREAMMAGIC_PROCESSOR));
  result:=kResultTrue;
end;

function CComponent.Terminate: TResult;
begin
  WriteLog('CComponent.Terminate');
  IVST3.ProcessorTerminate;
  result:=kResultOk;
end;

end.
