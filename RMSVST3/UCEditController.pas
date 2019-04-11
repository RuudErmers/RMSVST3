unit UCEditController;

interface

uses Vst3Base,UCPlugView,UVST3Controller;

type CEditController = class(TAggregatedObject,IEditController)
      FPlugView:CPlugView;
      IVST3:IVST3Controller;
      // Receive the component state.
      function SetComponentState(state: IBStream): TResult; stdcall;
      // Set the controller state.
      function SetState(state: IBStream): TResult; stdcall;
      // Gets the controller state.
      function GetState(state: IBStream): TResult; stdcall;

      // parameters -------------------------
      // Returns the number of parameter exported.
      function GetParameterCount: int32; stdcall;
      // Gets for a given index the parameter information.
      function GetParameterInfo(paramIndex: int32; out info: TParameterInfo): TResult; stdcall;
      // Gets for a given paramID and normalized value its associated AnsiString representation.
      function GetParamStringByValue(tag: TParamID; valueNormalized: TParamValue; text: PString128): TResult; stdcall;
      // Gets for a given paramID and AnsiString its normalized value.
      function GetParamValueByString(tag: TParamID; text: PTChar; out valueNormalized: TParamValue): TResult; stdcall;
      // Returns for a given paramID and a normalized value its plain representation (for example 1000 for 1000Hz).
      function NormalizedParamToPlain(tag: TParamID; valueNormalized: TParamValue): TParamValue; stdcall;
      // Returns for a given paramID and a plain value its normalized value.
      function PlainParamToNormalized(tag: TParamID; plainValue: TParamValue): TParamValue; stdcall;
      // Returns the normalized value of the parameter associated to the paramID.
      function GetParamNormalized(tag: TParamID): TParamValue; stdcall;
      // Sets the normalized value to the parameter associated to the paramID. The controller must never
      // pass this value change back to the host via the IComponentHandler. It should update the according
      // GUI element(s) only!
      function SetParamNormalized(tag: TParamID; value: TParamValue): TResult; stdcall;

      // handler ----------------------------
      // Gets from host a handler.
      function SetComponentHandler(handler: IComponentHandler): TResult; stdcall;

      // view -------------------------------
      (* Creates the editor view of the Plug-in, currently only "editor" is supported, see \ref ViewType.
         The life time of the editor view will never exceed the life time of this controller instance. *)
      function CreateView(name: PAnsiChar): pointer; stdcall;
      (** The host passes a number of interfaces as context to initialize the plugin class.
      @note Extensive memory allocations etc. should be performed in this method rather than in the class constructor!
      If the method does NOT return kResultOk, the object is released immediately. In this case terminate is not called! *)
      function Initialize(context: FUnknown): TResult; stdcall;

      (** This function is called, before the plugin is unloaded and can be used for
      cleanups. You have to release all references to any host application interfaces. *)
      function Terminate: TResult; stdcall;

      constructor Create(const Controller: IVST3Controller);

  private
end;

implementation

{ CEditController }

uses UCodeSiteLogger,SysUtils,UVST3Utils;

constructor CEditController.Create(const Controller: IVST3Controller);
begin
  inherited Create(controller);
  IVST3:=Controller;
end;

function CEditController.CreateView(name: PAnsiChar): pointer;
begin
  WriteLog('CEditController.CreateView');
  FPlugView:=CPlugView.Create(IVST3);
  result:=IPlugView(FPlugView);
end;

function CEditController.GetParameterCount: int32;
begin
  result:=IVST3.GetParameterCount;
end;

function CEditController.GetParameterInfo(paramIndex: int32;  out info: TParameterInfo): TResult;
begin
  if IVST3.GetParameterInfo(paramIndex,info) then result:=kResultOk else result:=kResultFalse;
end;

function CEditController.GetParamNormalized(tag: TParamID): TParamValue;
begin
  result:=IVST3.getParameterValue(tag);
end;

function CEditController.GetParamStringByValue(tag: TParamID;  valueNormalized: TParamValue; text: PString128): TResult;
begin
  AssignString(text^,IVST3.GetParamStringByValue(tag,valueNormalized));
  result:=kResultOk;
end;

function CEditController.GetParamValueByString(tag: TParamID; text: PTChar;  out valueNormalized: TParamValue): TResult;
begin
  result:=kResultFalse;
end;

function CEditController.GetState(state: IBStream): TResult;
begin
  WriteLog('CEditController.GetState');
  WriteStream(state,STREAMMAGIC_CONTROLLER,IVST3.GetEditorState);
  result:=kResultOk;
end;

function CEditController.SetState(state: IBStream): TResult;
begin
  WriteLog('CEditController.SetState');
  IVST3.SetEditorState(ReadStream(state,STREAMMAGIC_CONTROLLER));
  result:=kResultOk;
end;

function CEditController.Initialize(context: FUnknown): TResult;
begin
  WriteLog('CEditController.Initialize !!!!!');
  IVST3.ControllerInitialize;     // not called in reaper ??
  result:=kResultOk;
end;

function CEditController.NormalizedParamToPlain(tag: TParamID;  valueNormalized: TParamValue): TParamValue;
begin
  WriteLog('CEditController.NormalizedParamToPlain');
  result:=IVST3.NormalizedParamToPlain(tag,valueNormalized);
end;

function CEditController.PlainParamToNormalized(tag: TParamID; plainValue: TParamValue): TParamValue;
begin
  WriteLog('CEditController.PlainParamToNormalized');
  result:=IVST3.PlainParamToNormalized(tag,plainValue);
end;

function CEditController.SetComponentHandler( handler: IComponentHandler): TResult;
begin
  WriteLog('CEditController.SetComponentHandler');
  IVST3.SetProcessorHandler(handler);
  result:=kResultOk;
end;

function CEditController.SetComponentState(state: IBStream): TResult;
begin
  WriteLog('CEditController.SetComponentState');
  IVST3.ControllerSetProcessorState(ReadStream(state,STREAMMAGIC_PROCESSOR));
  result:=kResultOk;
end;

function CEditController.SetParamNormalized(tag: TParamID;  value: TParamValue): TResult;
// from Host
begin
  WriteLog('CEditController.SetParamNormalized');
  IVST3.ControllerParameterSetValue(tag,value);
  result:=kResultOk;
end;

function CEditController.Terminate: TResult;
begin
  WriteLog('CEditController.Terminate');
  IVST3.ControllerTerminate;
  result:=kResultOk;
end;

end.
