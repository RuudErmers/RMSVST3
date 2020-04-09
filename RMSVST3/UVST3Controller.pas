unit UVST3Controller;

interface

uses Forms,UVST3Processor,Vst3Base,UVSTBase,UCDataLayer,Generics.Collections,ExtCtrls,Types;

const PROGRAMCOUNT = 16;
const IDPARMProgram = 4788;

// I REFUSE to use the word Component, because
// 1. This is a 'reserved' word in many applications
// 2. On Page 1 of the VST3 docs there is a picture where the correct name is used: Processor
type  IProcessorHandler = IComponentHandler;

type TVST3Parameter  = record
                        id,steps:integer;
                        title,shorttitle,units:string;
                        min,max,defVal,value:double;
                        automate,isProgram,dirty:boolean;
                      end;
     TVST3ParameterArray = TArray<TVST3Parameter>;
     TVST3Program = class
                    strict private
                      values:array of double;
                    public
                      // retrieves value from sl, using paramDEF.IDs as key
                      procedure SetState(const paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
                      // copies values to sl, using paramDEF.ID as key
                      procedure GetState(const paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
                      // copies paramFROM.Values to values, with a maximum of numParams values
                      procedure SaveParams(paramFROM:TVST3ParameterArray;numParams:integer);
                      // retrieves values[index]
                      function getParam (index:integer):double;
                    end;

 IVST3Controller = interface
        function CreateForm(parent:pointer):Tform;
        procedure EditOpen(form:TForm);
        procedure EditClose;
        procedure OnSize(newSize: TRect);
        function GetParameterCount:integer;
        function GetParameterInfo(paramIndex: integer;VAR info: TParameterInfo):boolean;
        function getParameterValue(id:integer):double;
        function GetParamStringByValue(id: integer; valueNormalized: double): string;
        function GetEditorState:string;
        procedure SetEditorState(state:string);
        procedure ControllerSetProcessorState(state:string);
        procedure ControllerInitialize;
        function NormalizedParamToPlain(id:integer;  valueNormalized: double): double;
        function PlainParamToNormalized(id:integer; plainValue: double): double;
        procedure ControllerTerminate;
        procedure SetProcessorHandler( handler: IProcessorHandler);
        procedure ControllerParameterSetValue(id:integer;value:double);
        function GetMidiCCParamID(channel,midiControllerNumber:integer):integer;
        function GetNumPrograms:integer;
        function GetProgramName(index:integer):string;
     end;
   TVST3Controller = class(TVST3Processor,IVST3Controller,IVST3Processor)
   private
        FCurProgram:integer;
        FPrograms: TList<TVST3Program>;
        Fparameters:TVST3ParameterArray;
        FeditorForm:TForm;
        FnumUserParameters:integer;
        FInitialized,fFinalized:boolean;
        FProcessorHandler:IProcessorHandler;
        FIdleTimer:TTimer;
        FSomethingDirty:boolean;
        FMidiEventQueue:TArray<integer>;
        procedure saveCurrentToProgram(prgm:integer);
        procedure SetProgram(prgm:integer;saveCurrent:boolean;updateProcessor:boolean);
        function ParmLookup(id: integer): integer;
        function CreateForm(parent:pointer):Tform;
        procedure EditOpen(form:TForm);
        procedure EditClose;
        function GetParameterCount:integer;
        function GetParameterInfo(paramIndex: integer;VAR info: TParameterInfo):boolean;
        function GetParamStringByValue(id: integer; valueNormalized: double): string;

        function GetEditorState:string;
        procedure SetEditorState(state:string);
        procedure ControllerSetProcessorState(state:string);
        procedure Initialize;
        procedure Terminate;
        procedure ControllerInitialize;
        procedure ControllerTerminate;
        function NormalizedParamToPlain(id:integer;  valueNormalized: double): double;
        function PlainParamToNormalized(id:integer; plainValue: double): double;
        procedure SetProcessorHandler( handler: IProcessorHandler);
        procedure ControllerParameterSetValue(id:integer;value:double);
        procedure UpdateCurrentFromProgram(prgm: integer;updateProcessor:boolean);
        function GetMidiCCParamID(channel,midiControllerNumber:integer):integer;
        function GetNumPrograms:integer;
        function GetProgramName(index:integer):string;
        function  getParameterValue(id:integer):double;
        procedure SetIdleTimer(enabled: boolean);
        procedure TimerOnIdle(Sender: TObject);
        procedure InternalSetParameter(const Index: Integer;  const Value: Single;updateProcessor:boolean);

   protected
        procedure ProcessorInitialize;override;final;
        procedure ProcessorTerminate;override;final;
        procedure ProcessorParameterSetValue(id:integer;value:double);override;final;
        procedure AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;ProgramChange:boolean=false);
        procedure ResendParameters;
        procedure UpdateHostParameter(id:integer;value:double);
        property  EditorForm: TForm read FEditorForm;
        function getParameterAsString(id: integer; value: double): string; virtual;
        procedure OnProgramChange(prgm:integer);virtual;
        function  GetEditorClass: TFormClass;virtual;
        function GetMidiOutputEvents:TArray<integer>;override;final;
        procedure OnEditOpen;virtual;
        procedure OnEditClose;virtual;
        procedure OnEditIdle;virtual;
        procedure UpdateEditorParameter(id:integer;value:double);virtual;
        procedure OnInitialize;virtual;
        procedure OnFinalize;virtual;
        procedure DoMidiEvent(byte0, byte1, byte2: integer);
        procedure doProgramChange(prgm:integer);
        procedure OnSize(newSize:TRect);virtual;

   public
        constructor Create; override;
   end;

implementation

uses SysUtils,UCodeSiteLogger,Windows,Math, UVst3Utils;

constructor TVST3Controller.Create;
begin
  WriteLog('TVST3Controller.Create');
  inherited;
  FPrograms:=TList<TVST3Program>.Create;
end;

function TVST3Controller.GetProgramName(index: integer): string;
begin
  result:='Program '+format('%.2d',[index+1]);
end;

function TVST3Controller.GetEditorState:string;
VAR i,n:integer;
    sl,ssl:TDataLayer;
begin
  saveCurrentToProgram(FCurProgram);
  WriteLog('Get State Called with Program='+ FCurProgram.ToString);
  sl:=TDataLayer.Create;
  sl.setAttributeI('CurProgram',FCurProgram);
  ssl:=TDataLayer.Create;
  for i:=0 to PROGRAMCOUNT-1 do
  begin
    ssl.Clear;
    FPrograms[i].GetState(FParameters,FnumUserParameters,ssl);
    sl.SaveSection('Program'+i.ToString,ssl);
  end;
  ssl.Free;
  result:=sl.Text;
  sl.Free;
end;

procedure TVST3Controller.DoMidiEvent(byte0, byte1, byte2: integer);
VAR l:integer;
begin
  l:=length(FMidiEventQueue);
  SetLength(FMidiEventQueue,l+1);
  FMidiEventQueue[l]:=byte0+byte1 SHL 8 + byte2 SHL 16;
end;

procedure TVST3Controller.doProgramChange(prgm: integer);
begin
  SetProgram(prgm,true,true);
end;

function TVST3Controller.GetMidiOutputEvents: TArray<integer>;
begin
  result:=FMidiEventQueue;
  SetLength(FMidiEventQueue,0);
end;

procedure TVST3Controller.SetEditorState(state:string);
VAR i,TempProgram:integer;
    sl,ssl:TDataLayer;
begin
  WriteLog('Set State: LOADING...');
  sl:=TDataLayer.Create;
  sl.Text:=state;
  TempProgram:=sl.getAttributeI('CurProgram');
  ssl:=TDataLayer.Create;
  for i:=0 to PROGRAMCOUNT-1 do
  begin
    sl.LoadSection('Program'+i.ToString,ssl);
    FPrograms[i].SetState(FParameters,FnumUserParameters,ssl);
  end;
  ssl.free;
  sl.free;
  SetProgram(TempProgram,false,true);
end;

procedure TVST3Controller.saveCurrentToProgram(prgm:integer);
begin
  FPrograms[prgm].saveParams(FParameters,FnumUserParameters);
end;

procedure TVST3Controller.UpdateCurrentFromProgram(prgm:integer;updateProcessor:boolean);
VAR i:integer;
    value:double;
begin
  for i:=0 to FnumUserParameters-1 do
  begin
    value:=FPrograms[prgm].getParam(i);
      InternalSetParameter(i,value,updateProcessor);
  end;
end;

procedure TVST3Controller.SetProcessorHandler(handler: IProcessorHandler);
begin
  FProcessorHandler:=handler;
end;

procedure TVST3Controller.ControllerSetProcessorState(state:string);
begin
// nothing to do...
end;

procedure TVST3Controller.Terminate;
begin
  if fFinalized then exit;
  fFinalized:=true;
  OnFinalize;
end;

procedure TVST3Controller.Initialize;
VAR title:string;
    i:integer;
begin
  if fInitialized then exit;
  fInitialized:=true;
  for i:=0 to PROGRAMCOUNT-1 do
    FPrograms.Add(TVST3Program.Create);
  OnInitialize;
  FnumUserParameters:=length(FParameters);
  // Copy initial Parameters to ALL Programs
  for i:=0 to PROGRAMCOUNT-1 do
    saveCurrentToProgram(i);
  //////////////////////////////////////////
  WriteLog('INIT: NumParams = '+FnumUserParameters.ToString);
  AddParameter(IDPARMProgram, 'Program','Program','',0,PROGRAMCOUNT-1,0,false,PROGRAMCOUNT-1,true);
  for i:=0 to 127 do
  begin
    title:='CCSIM_'+i.ToString;
    AddParameter(MIDICC_SIMULATION_START+i,title,title,'CC',0,127,0.3,false);
  end;
  SetProgram(0,false,true);
end;

function TVST3Controller.GetMidiCCParamID(channel,midiControllerNumber: integer): integer;
begin
  if (channel=0) and (midiControllerNumber<128) then
    result:=MIDICC_SIMULATION_START+midiControllerNumber+channel*128
  else
    result:=-1;
end;

function TVST3Controller.GetNumPrograms: integer;
begin
  result:=PROGRAMCOUNT;
end;

function TVST3Controller.getParameterAsString(id: integer;  value: double): string;
begin
  result:='';
end;

procedure TVST3Controller.ControllerInitialize;
begin
  Initialize;
end;

procedure TVST3Controller.ControllerTerminate;
begin
  Terminate;
end;

procedure TVST3Controller.SetProgram(prgm:integer;saveCurrent:boolean;updateProcessor:boolean);
begin
  if saveCurrent then
   saveCurrentToProgram(FCurProgram);
  FCurProgram:=prgm;
  UpdateCurrentFromProgram(prgm,updateProcessor);
  OnProgramChange(prgm);
end;

function TVST3Controller.GetParameterCount: integer;
begin
  result:=length(Fparameters);
end;

function TVST3Controller.GetEditorClass:TFormClass;
begin
  result:=NIL;
end;

function TVST3Controller.CreateForm(parent:pointer):TForm;
VAR FeditorFormClass:TFormClass;
begin
  FeditorFormClass:=GetEditorClass;
  if FeditorFormClass = NIL then FeditorFormClass:=GetPluginInfo.PluginDef.ecl;
  if FeditorFormClass = NIL then result:=NIL
  else result:=FeditorFormClass.CreateParented(HWND(parent));
end;

function TVST3Controller.GetParameterInfo(paramIndex: integer; var info: TParameterInfo): boolean;
begin
  if paramIndex>=length(Fparameters) then
  begin
    result:=false;
    exit;
  end;
  info.id:=Fparameters[paramIndex].id;
  AssignString(info.Title,Fparameters[paramIndex].Title);
  AssignString(info.shortTitle,Fparameters[paramIndex].shortTitle);
  AssignString(info.units,Fparameters[paramIndex].units);
  info.stepCount:=Fparameters[paramIndex].steps;
  info.defaultNormalizedValue:=Fparameters[paramIndex].defVal;
  info.unitId:= kRootUnitId;
  info.flags:= ifthen(Fparameters[paramIndex].automate,kCanAutomate,0)
                + ifthen(Fparameters[paramIndex].isProgram,kIsProgramChange,0);
  result:=true;
end;

function TVST3Controller.getParameterValue(id: integer): double;
VAR index:integer;
begin
  result:=0;
  index:=ParmLookup(id);
  if index < 0 then exit;
  result:=Fparameters[index].value;
end;

function isMidiCCId(id:integer):boolean;
begin
  result:=(id>=MIDICC_SIMULATION_START) and (id<=MIDICC_SIMULATION_LAST);
end;

function TVST3Controller.GetParamStringByValue(id: integer;valueNormalized: double): string;
VAR v:double;
    index:integer;
begin
  result:='';
  index:=ParmLookup(id);
  if (index >= 0) and (index<FnumUserParameters) then
    result:=getParameterAsString(id,valueNormalized);
  if result='' then
  begin
    v:=NormalizedParamToPlain(id,valueNormalized);
    if abs(v-round(v))<0.001 then
       result:=round(v).ToString
    else
       result:=Copy(FloatToStr(v),1,6);
     end;
end;

function TVST3Controller.NormalizedParamToPlain(id: integer;valueNormalized: double): double;
VAR index:integer;
begin
  result:=0;
  index:=ParmLookup(id);
  if index < 0 then exit;
  with Fparameters[index] do
    result:=min+(max-min)*valueNormalized;
end;

function TVST3Controller.PlainParamToNormalized(id: integer;plainValue: double): double;
VAR index:integer;
begin
  result:=0;
  index:=ParmLookup(id);
  if index < 0 then exit;
  with Fparameters[index] do
    result:=(plainValue-min)/(max-min);
end;

procedure TVST3Controller.ProcessorInitialize;
begin
  inherited;
  WriteLog('TVST3Controller.ProcessorInitialize');
  Initialize;
end;

procedure TVST3Controller.ProcessorTerminate;
begin
  Terminate;
end;

procedure TVST3Controller.EditClose;
begin
  SetIdleTimer(false);
  OnEditClose;
  FeditorForm:=NIL;
end;

procedure TVST3Controller.EditOpen(form: TForm);
begin
  FeditorForm:=form;
  OnEditOpen;
  SetIdleTimer(true);
  ResendParameters;
end;

procedure TVST3Controller.ResendParameters;
VAR i,id,count:integer;
begin
  if FeditorForm=NIL then exit;
  count:=FnumUserParameters;
  for i:=0 to count-1 do
  begin
    id:=Fparameters[i].id;
    if isMidiCCId(id) then continue;  // better safe than sorry
    if id = IDPARMProgram then continue;  // better safe than sorry
    UpdateEditorParameter(id,Fparameters[i].value);
    Fparameters[i].dirty:=false
  end;
end;

procedure TVST3Controller.TimerOnIdle(Sender:TObject);
VAR i,count:integer;
begin
  OnEditIdle;
  if not FSomethingDirty then exit;
  count:=FnumUserParameters;
  for i:=0 to count-1 do
    if Fparameters[i].dirty then
    begin
      UpdateEditorParameter(Fparameters[i].id,Fparameters[i].value);
      Fparameters[i].dirty:=false
    end;
  FSomethingDirty:=false;
end;

procedure TVST3Controller.InternalSetParameter(const Index: Integer;  const Value: Single;updateProcessor:boolean);
begin
  FParameters[index].value:=value;
  FParameters[index].dirty:=true;
  FSomethingDirty:=true;
// See Document OnAutomateUpdateParameter
//  if FeditorForm<>NIL then
//    UpdateEditorParameter(FParameters[index].id,value);
  if updateProcessor then
    updateProcessorParameter(FParameters[index].id,value);
end;

procedure TVST3Controller.SetIdleTimer(enabled:boolean);
begin
  if enabled then
  begin
    if FIdleTimer=NIL then
      FIdleTimer:=TTimer.Create(NIL);
    FIdleTimer.Interval:=100;
    FIdleTimer.OnTimer:=TimerOnIdle;
    FIdleTimer.Enabled:=true;
  end
  else
    if FIdleTimer<>NIL then
      FreeAndNIL(FidlEtimer);
end;

procedure TVST3Controller.UpdateEditorParameter(id: integer;  value: double);
begin
// virtual;
end;

function TVST3Controller.ParmLookup(id:integer):integer;
VAR i:integer;
begin
  for i:=0 to length(Fparameters)-1 do
    if FParameters[i].id = id then begin result:=i; exit; end;
  result:=-1;
end;

procedure TVST3Controller.UpdateHostParameter(id: integer; value: double);
VAR index:integer;
begin
  index:=ParmLookup(id);
  if index<>-1 then
  begin
    if FProcessorHandler<>NIL then
      FProcessorHandler.PerformEdit(id,value);
    InternalSetParameter(index,value,false);
  end;
end;

procedure TVST3Controller.OnEditClose;
begin

end;

procedure TVST3Controller.OnEditIdle;
begin
// virtual
end;

procedure TVST3Controller.OnEditOpen;
begin
//
end;

procedure TVST3Controller.OnFinalize;
begin

end;

procedure TVST3Controller.OnInitialize;
begin

end;

procedure TVST3Controller.OnProgramChange(prgm: integer);
begin
// virtual
end;

procedure TVST3Controller.OnSize(newSize: TRect);
begin
  if FeditorForm<>NIL then with newSize do
    FeditorForm.SetBounds(left,top,width,height);

end;

procedure TVST3Controller.ControllerParameterSetValue(id: integer; value: double);
{ this is called: From Host: ParameterSetValue}
// All CC's for MIdi are called
VAR index:integer;
const   MIDI_CC = $B0;
begin
  WriteLog('ControllerParameterSetValue:'+id.ToString+' '+value.ToString);
  if isMidiCCId(id) then
  begin
    WriteLog('ParameterSetValue MIDI ???:'+id.ToString+' '+value.ToString);
    exit;
  end;

  index:=ParmLookup(id);
  if index=-1 then exit;
  if (value<0) or (value>1) then exit;
  if id = IDPARMProgram then
  begin
    WriteLog('Program Change');
    SetProgram(round(value*(PROGRAMCOUNT-1)),true,true);
  end
  else
    InternalSetParameter(index,value,false);
end;

procedure TVST3Controller.ProcessorParameterSetValue(id:integer;value:double);
VAR index:integer;
const   MIDI_CC = $B0;
begin
// not from ui.. !! WriteLog('ProcessorOnUpdateParameter: '+id.ToString+' '+value.ToString);
  if isMidiCCId(id) then
  begin
    index:=id-MIDICC_SIMULATION_START;
    OnMidiEvent(index DIV 128 + MIDI_CC,index MOD 128,round(127*value))
  end
  else
  begin // do some validation on the input..
    index:=ParmLookup(id);
    if index=-1 then exit;
    if id<> IDPARMProgram then
      UpdateProcessorParameter(id,value);
    end;
end;


procedure TVST3Controller.AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;ProgramChange:boolean=false);

VAR n:integer;
    params:TVST3Parameter;
begin
  params.id:=id;
  params.title:=title;
  params.shorttitle:=shorttitle;
  params.units:=units;
  params.min:=min;
  params.max:=max;
  if (max<=min) then params.max:=params.min+1;
  if (val<params.min) then val:=params.min;
  if (val>params.max) then val:=params.max;
  val:=(val-min)/(max-min);
  params.defval:=val;
  params.value:=val;
  params.automate:=automate;
  params.steps:=steps;
  params.isProgram:=ProgramChange;
  n:=Length(Fparameters);
  SetLength(Fparameters,n+1);
  FParameters[n]:=params;
end;


{ TVST3Program }

// copies values to sl, using paramDEF.ID as key
procedure TVST3Program.GetState(const paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
VAR i,len:integer;
begin
  sl.setAttributeI('MAGIC',2136);
  len:=min(numParams,length(values));
  for i:=0 to len-1 do
    sl.SetAttributeI('PARAM'+paramdef[i].id.ToString,round(values[i]*16384));
end;

// retrieves value from sl, using paramDEF.IDs as key
// adjusts length(values) if needed
procedure TVST3Program.SetState(const paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
VAR i:integer;
begin
  // Copy To self
  if sl.getAttributeI('MAGIC')<>2136 then
  begin
    WriteLog('SetState; Invalid magic UNEXPECTED');
    exit;
  end;
  setLength(values,numParams);
  for i:=0 to numParams-1 do
    values[i]:=sl.GetAttributeI('PARAM'+paramdef[i].id.ToString)/16384;
end;

// copies paramFROM.Values to values, with a maximum of numParams values
procedure TVST3Program.SaveParams(paramFROM:TVST3ParameterArray;numParams:integer);
VAR i:integer;
begin
  SetLength(values,numParams);
  for i:=0 to numParams-1 do
    values[i]:=paramFROM[i].value;
end;

// retrieves values[index]
function TVST3Program.getParam (index:integer):double;
begin
  result:=0;
  if index<length(values) then
    result:=values[index];
end;


end.

