unit UVST3Controller;

interface

uses Forms,UVST3Processor,Vst3Base,UVST3Base,UCDataLayer,Generics.Collections;

const PROGRAMCOUNT = 32;
const IDPARMPRESET = 4788;

type TVST3Parameter  = record
                        id,steps:integer;
                        title,shorttitle,units:string;
                        min,max,defVal,value:double;
                        automate,isPreset:boolean; // visible in Host ?
                      end;
     TVST3ParameterArray = TArray<TVST3Parameter>;
     TVST3Program = class
                    strict private
                      values:array of double;
                    public
                      // retrieves value from sl, using paramDEF.IDs as key
                      procedure SetState(paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
                      // copies values to sl, using paramDEF.ID as key
                      procedure GetState(paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
                      // copies paramFROM.Values to values, with a maximum of numParams values
                      procedure SaveParams(paramFROM:TVST3ParameterArray;numParams:integer);
                      // retrieves values[index]
                      function getParam (index:integer):double;
                    end;

 IVST3Controller = interface
        function CreateForm(parent:pointer):Tform;
        procedure EditOpen(form:TForm);
        procedure EditClose;
        function GetParameterCount:integer;
        function GetParameterInfo(paramIndex: integer;VAR info: TParameterInfo):boolean;
        function getParameterValue(id:integer):double;
        function GetParamStringByValue(id: integer; valueNormalized: double): string;
        procedure GetEditorState(stream:IBStream);
        procedure SetEditorState(stream:IBStream);
        procedure SetProcessorState(stream:IBStream);
        procedure ControllerInitialize;
        function NormalizedParamToPlain(id:integer;  valueNormalized: double): double;
        function PlainParamToNormalized(id:integer; plainValue: double): double;
        procedure ControllerTerminate;
        procedure SetProcessorHandler( handler: IProcessorHandler);
        procedure ParameterSetValue(id:integer;value:double);
        function GetMidiCCParamID(channel,midiControllerNumber:integer):integer;
        function GetNumPrograms:integer;
        function GetProgramName(index:integer):string;
     end;
   TVST3Controller = class(TVST3Processor,IVST3Controller)
   private
        FCurPreset:integer;
        FPrograms: TList<TVST3Program>;
        Fparameters:TVST3ParameterArray;
        FeditorForm:TForm;
        FnumUserParameters:integer;
        FInitialized:boolean;
        FProcessorHandler:IProcessorHandler;
        procedure saveCurrentToProgram(prgm:integer);
        procedure SetPreset(prgm:integer;saveCurrent:boolean;updateComponent:boolean);
        function ParmLookup(id: integer): integer;
        function CreateForm(parent:pointer):Tform;
        procedure EditOpen(form:TForm);
        procedure EditClose;
        function GetParameterCount:integer;
        function GetParameterInfo(paramIndex: integer;VAR info: TParameterInfo):boolean;

        function GetParamStringByValue(id: integer; valueNormalized: double): string;
        procedure GetEditorState(stream:IBStream);
        procedure SetEditorState(stream:IBStream);
        procedure SetProcessorState(stream:IBStream);
        procedure ControllerInitialize;
        function NormalizedParamToPlain(id:integer;  valueNormalized: double): double;
        function PlainParamToNormalized(id:integer; plainValue: double): double;
        procedure ControllerTerminate;
        procedure SetProcessorHandler( handler: IProcessorHandler);
        procedure ParameterSetValue(id:integer;value:double);
        procedure UpdateCurrentFromProgram(prgm: integer;updateComponent:boolean);
        function GetMidiCCParamID(channel,midiControllerNumber:integer):integer;
        procedure OnCreate(pluginInfo:TVST3InstrumentInfo);override;
        function GetNumPrograms:integer;
        function GetProgramName(index:integer):string;
   protected
        function  getParameterValue(id:integer):double;
        procedure AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;presetChange:boolean=false);
        procedure ResendParameters;
        procedure UpdateHostParameter(id:integer;value:double);
        property  EditorForm: TForm read FEditorForm;

        procedure OnPresetChange(prgm:integer);virtual;
        function  GetEditorClass: TFormClass;virtual;
        procedure OnEditOpen;virtual;
        procedure OnEditClose;virtual;
        procedure UpdateEditorParameter(id:integer;value:double);virtual;
        procedure OnInitialize;virtual;
        procedure OnFinalize;virtual;
   public
        constructor Create; override;
   end;

implementation

uses SysUtils,CodeSiteLogging,Windows,Math;

constructor TVST3Controller.Create;
begin
  inherited;
  FPrograms:=TList<TVST3Program>.Create;
end;

function TVST3Controller.GetProgramName(index: integer): string;
begin
  result:='Preset '+format('%.2d',[index+1]);
end;

const STATE_MAGIC = 346523;
procedure TVST3Controller.GetEditorState(stream: IBStream);
VAR i,n:integer;
    sl,ssl:TDataLayer;
begin
  saveCurrentToProgram(FCurPreset);
  CodeSite.Send('Get State Called with Preset='+ FCurPreset.ToString);
  n:=STATE_MAGIC;
  stream.Write(@n,sizeof(integer));
  sl:=TDataLayer.Create;
  sl.setAttributeI('CurPreset',FCurPreset);
  ssl:=TDataLayer.Create;
  for i:=0 to PROGRAMCOUNT-1 do
  begin
    ssl.Clear;
    FPrograms[i].GetState(FParameters,FnumUserParameters,ssl);
    sl.SaveSection('Program'+i.ToString,ssl);
  end;
  ssl.Free;
  sl.SaveToIBStream(stream);
  sl.Free;
end;


procedure TVST3Controller.SetEditorState(stream: IBStream);
VAR i,n,TempPreset:integer;
    sl,ssl:TDataLayer;
begin
  begin
    stream.read(@n,sizeof(integer));
    if n<>STATE_MAGIC then
    begin
        CodeSite.Send('Set State Error: ');
      exit;
    end;
    CodeSite.Send('Set State: LOADING...');
    sl:=TDataLayer.Create;
    sl.LoadFromIBStream(stream);
    TempPreset:=sl.getAttributeI('CurPreset');
    ssl:=TDataLayer.Create;
    for i:=0 to PROGRAMCOUNT-1 do
    begin
      sl.LoadSection('Program'+i.ToString,ssl);
      FPrograms[i].SetState(FParameters,FnumUserParameters,ssl);
    end;
    ssl.free;
    sl.free;
  end;
  SetPreset(TempPreset,false,true);
end;


procedure TVST3Controller.saveCurrentToProgram(prgm:integer);
begin
  FPrograms[prgm].saveParams(FParameters,FnumUserParameters);
end;

procedure TVST3Controller.UpdateCurrentFromProgram(prgm:integer;updateComponent:boolean);
VAR i:integer;
    value:double;
    queue:TVST3AutomationQueue;
begin
  for i:=0 to FnumUserParameters-1 do
  begin
    value:=FPrograms[prgm].getParam(i);
    if abs(value-FParameters[i].value) > 0.00001 then
    begin
      ParameterSetValue(FParameters[i].id,value);
      if updateComponent then
      begin
        queue:=TVST3AutomationQueue.Create(FParameters[i].id);
        queue.Add(0,value);
        OnAutomationReceived(queue);
        queue.free;
      end;
    end;
  end;
end;

procedure TVST3Controller.SetProcessorHandler(handler: IProcessorHandler);
begin
  FProcessorHandler:=handler;
end;

procedure TVST3Controller.SetProcessorState(stream: IBStream);
begin
// nothing to do...
end;

procedure TVST3Controller.ControllerInitialize;
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
  CodeSite.Send('INIT: NumParams = '+FnumUserParameters.ToString);
  AddParameter(IDPARMPRESET, 'Preset','Preset','',0,31,0,false,31,true);
  for i:=0 to 127 do
  begin
    title:='CCSIM_'+i.ToString;
    AddParameter(MIDICC_SIMULATION_START+i,title,title,'CC',0,127,0.3,false);
  end;
end;

function TVST3Controller.GetMidiCCParamID(channel,midiControllerNumber: integer): integer;
begin
  result:=MIDICC_SIMULATION_START+midiControllerNumber+channel*128;
end;

function TVST3Controller.GetNumPrograms: integer;
begin
  result:=16;
end;

procedure TVST3Controller.ControllerTerminate;
begin
  OnFinalize;
end;

procedure TVST3Controller.SetPreset(prgm:integer;saveCurrent:boolean;updateComponent:boolean);
begin
  if saveCurrent then
   saveCurrentToProgram(FCurPreset);
  FCurPreset:=prgm;
  UpdateCurrentFromProgram(prgm,updateComponent);
  OnPresetChange(prgm);
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
  if FeditorFormClass = NIL then FeditorFormClass:=FPluginInfo.PluginDef.ecl;
  if FeditorFormClass = NIL then result:=NIL
  else result:=FeditorFormClass.CreateParented(HWND(parent));
end;

function TVST3Controller.GetParameterInfo(paramIndex: integer; var info: TParameterInfo): boolean;
begin
  info.id:=Fparameters[paramIndex].id;
  AssignStrToStr128(info.Title,Fparameters[paramIndex].Title);
  AssignStrToStr128(info.shortTitle,Fparameters[paramIndex].shortTitle);
  AssignStrToStr128(info.units,Fparameters[paramIndex].units);
  info.stepCount:=Fparameters[paramIndex].steps;
  info.defaultNormalizedValue:=Fparameters[paramIndex].defVal;
  info.unitId:= kRootUnitId;
  info.flags:= ifthen(Fparameters[paramIndex].automate,kCanAutomate,0)
                + ifthen(Fparameters[paramIndex].ispreset,kIsProgramChange,0);
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

function TVST3Controller.GetParamStringByValue(id: integer;valueNormalized: double): string;
begin
  result:=FloatToStr(NormalizedParamToPlain(id,valueNormalized)); // TODO: improve on this
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

procedure TVST3Controller.EditClose;
begin
  OnEditClose;
  FeditorForm:=NIL;
end;

procedure TVST3Controller.EditOpen(form: TForm);
begin
  FeditorForm:=form;
  OnEditOpen;
  ResendParameters;
end;

function isMidiCCId(id:integer):boolean;
begin
  result:=(id>=MIDICC_SIMULATION_START) and (id<=MIDICC_SIMULATION_LAST);
end;

procedure TVST3Controller.ResendParameters;
VAR i,id,count:integer;
    value:double;
begin
  if FeditorForm=NIL then exit;
  count:=GetParameterCount;
  for i:=0 to count-1 do
  begin
    id:=Fparameters[i].id;
    if isMidiCCId(id) then continue;
    value:=GetParameterValue(id);
    UpdateEditorParameter(id,value);
  end;
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
  if index < 0 then exit;
  Fparameters[index].value:=value;
  if FProcessorHandler<>NIL then
    FProcessorHandler.PerformEdit(id,value);
end;

procedure TVST3Controller.OnCreate(pluginInfo: TVST3InstrumentInfo);
begin
  inherited;
  ControllerInitialize;
end;

procedure TVST3Controller.OnEditClose;
begin

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

procedure TVST3Controller.OnPresetChange(prgm: integer);
begin
// virtual
end;

procedure TVST3Controller.ParameterSetValue(id: integer; value: double);
{ this is called: From Host: ParameterSetValue}
// All CC's for MIdi are called
VAR index,ind:integer;
begin
  index:=ParmLookup(id);
  if index=-1 then exit;
  if (value<0) or (value>1) then exit;
  Fparameters[index].value:=value;
  if isMidiCCId(id) then EXIT // cc's are processed from AudioProcessor
(*
  begin
    if Factive then
    begin
//      CodeSite.Send('Midi CC:'+ (id-MIDICC_SIMULATION_START).ToString);
      ind:=id-MIDICC_SIMULATION_START;
      OnMidiCC(ind DIV 128, ind MOD 128,round(value*127))
    end
    else
        CodeSite.Send('Skipping MIDI CC [ not Active ] ');
  end
  *)
  else if id = IDPARMPRESET then
  begin
    CodeSite.Send('Program Change');
    SetPreset(round(value*31),true,false);
  end
  else if EditorForm<>NIL then
    UpdateEditorParameter(id,value);
end;

procedure TVST3Controller.AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;presetChange:boolean=false);

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
  params.isPreset:=presetChange;
  n:=Length(Fparameters);
  SetLength(Fparameters,n+1);
  FParameters[n]:=params;
end;


{ TVST3Program }

// copies values to sl, using paramDEF.ID as key
procedure TVST3Program.GetState(paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
VAR i,len:integer;
begin
  sl.setAttributeI('MAGIC',2136);
  len:=min(numParams,length(values));
  for i:=0 to len-1 do
    sl.SetAttributeI('PARAM'+paramdef[i].id.ToString,round(values[i]*16384));
end;

// retrieves value from sl, using paramDEF.IDs as key
// adjusts length(values) if needed
procedure TVST3Program.SetState(paramDEF:TVST3ParameterArray;numParams:integer;sl:TDataLayer);
VAR i,dummy:integer;
begin
  // Copy To self
  if sl.getAttributeI('MAGIC')<>2136 then
  begin
    CodeSite.Send('SetState; Invalid magic UNEXPECTED');
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
