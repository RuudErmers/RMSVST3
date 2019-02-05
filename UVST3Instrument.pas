unit UVST3Instrument;

interface

uses Vst3Base,Forms,Generics.Collections,UCDataLayer;

type PSingle           = ^single;
     PPSingle          = ^PSingle;

const MIDICC_SIMULATION_START = 1024;
const MIDICC_SIMULATION_LAST  = 1024+128*16-1;  // = 3071
const IDPARMPRESET = 4788;

const PROGRAMCOUNT = 32;

type
     TVST3Instrument = class;
     TVST3InstrumentClass = class of TVST3Instrument;
     TVST3PluginDef =  record
                              uid : TGUID;
                              cl  : TVST3InstrumentClass;
                              ecl :  TFormClass;
                              name:string;
                              isSynth:boolean;
                            end;
     TVST3FactoryDef =     record
                             vendor,url,email:string;
                           end;
     TVST3InstrumentInfo = record
                        PluginDef:TVST3PluginDef;
                        factoryDef:TVST3FactoryDef;
                      end;
     TVST3Parameter  = record
                        id,steps:integer;
                        title,shorttitle,units:string;
                        min,max,defVal,value:double;
                        automate,isPreset:boolean; // visible in Host ?
                      end;
     TVST3ParameterArray = TArray<TVST3Parameter>;
     TVST3AutomationItem = record sampleOffset:integer;value:double end;
     TVST3AutomationQueue = class
                           private
                             Fid:integer;
                             FList:TList<TVST3AutomationItem>;
                           public
                             procedure Add(sampleOffset:integer;value:double);
                             constructor Create(id:integer);
                             destructor Destroy;
                             property id: integer read FId;
                             function last:double;
                           end;
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
// 0: CComponent.SetState -> Valid
// 1: CEditController.SetComponentState -> Invalid
// 2: CEditController.SetState -> valid

// Since the model is the same for Component and Controller, I will NOT honor requests for SetState/GetState from the Component.
// However, when SetState called for CEditController.SetState both the Controller and Component will be notified.
// This works with Reaper
// If you want this different, be my guest :}

     TStateSource = (srcComponent,srcControllerComponent,srcController);
     IVST3Instrument = interface
        procedure ParameterSetValue(id:integer;value:double);
        procedure EditOpen(form:TForm);
        procedure EditClose;
        function GetParameterCount:integer;
        function GetParameterInfo(paramIndex: integer;VAR info: TParameterInfo):boolean;
        function getParameterValue(id:integer):double;
        function CreateForm(parent:pointer):Tform;
        procedure SetComponentHandler( handler: IComponentHandler);
        procedure SetState(stream:IBStream;source:TStateSource);
        procedure GetState(stream:IBStream;source:TStateSource);
        procedure OnCreate(pluginInfo:TVST3InstrumentInfo);
        function NormalizedParamToPlain(id:integer;  valueNormalized: double): double;
        function PlainParamToNormalized(id:integer; plainValue: double): double;
        function GetParamStringByValue(id: integer; valueNormalized: double): string;
        function GetPluginInfo:TVST3InstrumentInfo;
        procedure ControllerTerminate;
        procedure ControllerInitialize;
        procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);
        procedure AutomationReceive(queue:TVST3AutomationQueue);
        procedure NoteOn(channel,pitch,velocity:integer);
        procedure NoteOff(channel,pitch,velocity:integer);
        function GetMidiCCParamID(channel,midiControllerNumber:integer):integer;
        function GetNumPrograms:integer;
        function GetProgramName(index:integer):string;
        procedure SetActive(active:boolean);
        procedure SamplerateChanged(samplerate:single);
        procedure TempoChanged(tempo:single);
        procedure PlayStateChanged(playing:boolean;ppq:integer);
     end;

   TVST3Instrument = class(TInterfacedObject,IComponent,IAudioProcessor,IEditController,IMidiMapping,IVST3Instrument,IUnitInfo)
private
  FAudioProcessor:IAudioProcessor;
  FComponent:IComponent;
  FEditController:IEditController;
  FMidiMapping:IMidiMapping;
  FUnitInfo: IUnitInfo;
  Factive:boolean;
  FCurPreset,FnumUserParameters:integer;
  FPrograms: TList<TVST3Program>;
  fInitialized:boolean;
  Fparameters:TVST3ParameterArray;
  FeditorForm:TForm;
  FPluginInfo:TVST3InstrumentInfo;
  FComponentHandler:IComponentHandler;

  property AudioProcessor: IAudioProcessor read FAudioProcessor implements IAudioProcessor;
  property Component: IComponent read FComponent implements IComponent;
  property EditController: IEditController read FEditController implements IEditController;
  property MidiMapping:IMidiMapping read FMidiMapping implements IMidiMapping;
  property UnitInfo:IUnitInfo read FUnitInfo implements IUnitInfo;

  procedure ParameterSetValue(id:integer;value:double);

  procedure EditOpen(form:TForm);
  procedure EditClose;
  function GetParameterCount:integer;
  function GetParameterInfo(paramIndex: integer;VAR info: TParameterInfo):boolean;
  function getParameterValue(id:integer):double;
  function CreateForm(parent:pointer):Tform;
  function NormalizedParamToPlain(id:integer;  valueNormalized: double): double;
  function PlainParamToNormalized(id:integer; plainValue: double): double;
  function GetParamStringByValue(id: integer; valueNormalized: double): string;virtual;
  procedure ControllerTerminate;
  procedure ControllerInitialize;

  procedure SetComponentHandler( handler: IComponentHandler);
  function GetPluginInfo:TVST3InstrumentInfo;

  function ParmLookup(id: integer): integer;
  function GetMidiCCParamID(channel,midiControllerNumber:integer):integer;
  procedure AutomationReceive(queue:TVST3AutomationQueue);

  function GetNumPrograms:integer;
  function GetProgramName(index:integer):string;
  procedure SetActive(active:boolean);
  procedure SetState(stream:IBStream;source:TStateSource);
  procedure GetState(stream:IBStream;source:TStateSource);
  procedure SetPreset(prgm:integer;saveCurrent:boolean;updateComponent:boolean);
  procedure UpdateCurrentFromProgram(prgm: integer;updateComponent:boolean);
  procedure saveCurrentToProgram(prgm:integer);
  procedure UpdateProcessor(prgm: integer);
protected
  procedure AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;presetChange:boolean=false);
  procedure ResendParameters;
  procedure UpdateHostParameter(id:integer;value:double);
  property EditorForm: TForm read FEditorForm;

  procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);virtual;
  procedure OnAutomationReceived(queue:TVST3AutomationQueue);virtual;

  procedure OnInitialize;virtual;
  procedure OnFinalize;virtual;
  procedure NoteOn(channel,pitch,velocity:integer);virtual;
  procedure NoteOff(channel,pitch,velocity:integer);virtual;
  function GetEditorClass: TFormClass;virtual;
  procedure OnEditOpen;virtual;
  procedure OnEditClose;virtual;
  procedure OnMidiCC(channel,cc,value:integer);virtual;
  procedure OnPresetChange(prgm:integer);virtual;
  procedure UpdateEditorParameter(id:integer;value:double);virtual;
  procedure SamplerateChanged(samplerate:single);virtual;
  procedure TempoChanged(tempo:single);virtual;
  procedure PlayStateChanged(playing:boolean;ppq:integer);virtual;

public
  procedure OnCreate(pluginInfo:TVST3InstrumentInfo);
  constructor Create; virtual;
end;

procedure AssignStrToStr128(VAR target: TString128; source:string);

implementation

uses Windows,SysUtils,Math,UCAudioProcessor,UCComponent,UCEditController,UCMidiMapping,UCUnitInfo,CodeSiteLogging;

procedure TVST3AutomationQueue.Add(sampleOffset: integer; value: double);
VAR item:TVST3AutomationItem;
begin
  item.sampleOffset:=sampleOffset;
  item.value:=value;
  FList.Add(item);
end;

constructor TVST3AutomationQueue.Create(id: integer);
begin
  Fid:=id;
  Flist:=TList<TVST3AutomationItem>.Create;
end;

destructor TVST3AutomationQueue.Destroy;
begin
  Flist.Free;
end;

function TVST3AutomationQueue.last: double;
begin
  if FList.Count>0 then result:=FList[FList.Count-1].value else result:=0;
end;

procedure AssignStrToStr128(VAR target: TString128; source:string);
VAR i:integer;
begin
  for i:=0 to length(source)-1 do
    target[i]:=source[i+1];
  target[length(source)]:=#0;
end;

constructor TVST3Instrument.Create;
begin
  FPrograms:=TList<TVST3Program>.Create;
  FAudioProcessor:=CAudioProcessor.Create(self);
  FComponent:=CComponent.Create(self);
  FEditController:=CEditController.Create(self);
  FMidiMapping:=CMidiMapping.Create(self);
  FUnitInfo:=CUnitInfo.Create(self);

  fInitialized:=false;
end;

function TVST3Instrument.GetPluginInfo: TVST3InstrumentInfo;
begin
  result:=FPluginInfo;
end;

function TVST3Instrument.GetProgramName(index: integer): string;
begin
  result:='Preset '+format('%.2d',[index+1]);
end;

const STATE_MAGIC = 346523;
procedure TVST3Instrument.GetState(stream: IBStream;source:TStateSource);
VAR i,n:integer;
    sl,ssl:TDataLayer;
begin
  if source<>srcController then exit;
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


procedure TVST3Instrument.SetState(stream: IBStream;source:TStateSource);
VAR i,n,TempPreset:integer;
    sl,ssl:TDataLayer;
const sSource:array[TStateSource] of string = ('CComponent.SetState ','CEditController.SetComponentState','CEditController.SetState');
begin
  if source<>srcController then exit;
  begin
    stream.read(@n,sizeof(integer));
    if n<>STATE_MAGIC then
    begin
        CodeSite.Send('Set State Error: '+sSource[source]);
      exit;
    end;
    CodeSite.Send('Set State: LOADING...'+sSource[source]);
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
// Update Current Preset
//  if source=srcController then
    SetPreset(TempPreset,false,true);
//  else
//    UpdateProcessor(TempPreset);
end;

procedure TVST3Instrument.TempoChanged(tempo: single);
begin
// virtual
end;

procedure TVST3Instrument.UpdateProcessor(prgm:integer);
VAR i:integer;
    value:double;
    queue:TVST3AutomationQueue;
begin
  for i:=0 to FnumUserParameters-1 do
  begin
    value:=FPrograms[i].getParam(i);
    queue:=TVST3AutomationQueue.Create(FParameters[i].id);
    queue.Add(0,value);
    OnAutomationReceived(queue);
    queue.free;
  end;
end;


procedure TVST3Instrument.saveCurrentToProgram(prgm:integer);
begin
  FPrograms[prgm].saveParams(FParameters,FnumUserParameters);
end;

procedure TVST3Instrument.UpdateCurrentFromProgram(prgm:integer;updateComponent:boolean);
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

procedure TVST3Instrument.SetActive(active: boolean);
begin
  Factive:=active;
end;

procedure TVST3Instrument.SetComponentHandler(handler: IComponentHandler);
begin
  FComponentHandler:=handler;
end;

procedure TVST3Instrument.OnCreate(pluginInfo: TVST3InstrumentInfo);
begin
  FPluginInfo:=pluginInfo;
  ControllerInitialize;
end;

function isMidiCCId(id:integer):boolean;
begin
  result:=(id>=MIDICC_SIMULATION_START) and (id<=MIDICC_SIMULATION_LAST);
end;

procedure TVST3Instrument.AutomationReceive(queue: TVST3AutomationQueue);
VAR i,index:integer;
begin
  if isMidiCCId(queue.id) then
  begin
    index:=queue.id-MIDICC_SIMULATION_START;
    for i:=0 to queue.FList.Count-1 do
      OnMidiCC(index DIV 128, index MOD 128,round(127*queue.Flist[i].value))
  end
  else
    OnAutomationReceived(queue);
end;

procedure TVST3Instrument.ControllerInitialize;
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

function TVST3Instrument.GetMidiCCParamID(channel,midiControllerNumber: integer): integer;
begin
  result:=MIDICC_SIMULATION_START+midiControllerNumber+channel*128;
end;

function TVST3Instrument.GetNumPrograms: integer;
begin
  result:=16;
end;

procedure TVST3Instrument.ControllerTerminate;
begin
  OnFinalize;
end;

procedure TVST3Instrument.SetPreset(prgm:integer;saveCurrent:boolean;updateComponent:boolean);
begin
  if saveCurrent then
   saveCurrentToProgram(FCurPreset);
  FCurPreset:=prgm;
  UpdateCurrentFromProgram(prgm,updateComponent);
  OnPresetChange(prgm);
end;

procedure TVST3Instrument.Process32(samples, channels: integer; inputp,  outputp: PPSingle);
begin
end;

function TVST3Instrument.GetParameterCount: integer;
begin
  result:=length(Fparameters);
end;

function TVST3Instrument.GetEditorClass:TFormClass;
begin
  result:=NIL;
end;

function TVST3Instrument.CreateForm(parent:pointer):TForm;
VAR FeditorFormClass:TFormClass;
begin
  FeditorFormClass:=GetEditorClass;
  if FeditorFormClass = NIL then FeditorFormClass:=FPluginInfo.PluginDef.ecl;
  if FeditorFormClass = NIL then result:=NIL
  else result:=FeditorFormClass.CreateParented(HWND(parent));
end;

function TVST3Instrument.GetParameterInfo(paramIndex: integer; var info: TParameterInfo): boolean;
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

function TVST3Instrument.getParameterValue(id: integer): double;
VAR index:integer;
begin
  index:=ParmLookup(id);
  if index < 0 then exit;
  result:=Fparameters[index].value;
end;

function TVST3Instrument.GetParamStringByValue(id: integer;valueNormalized: double): string;
begin
  result:=FloatToStr(NormalizedParamToPlain(id,valueNormalized)); // TODO: improve on this
end;

function TVST3Instrument.NormalizedParamToPlain(id: integer;valueNormalized: double): double;
VAR index:integer;
begin
  result:=0;
  index:=ParmLookup(id);
  if index < 0 then exit;
  with Fparameters[index] do
    result:=min+(max-min)*valueNormalized;
end;

function TVST3Instrument.PlainParamToNormalized(id: integer;plainValue: double): double;
VAR index:integer;
begin
  result:=0;
  index:=ParmLookup(id);
  if index < 0 then exit;
  with Fparameters[index] do
    result:=(plainValue-min)/(max-min);
end;

procedure TVST3Instrument.PlayStateChanged(playing: boolean; ppq: integer);
begin
// virtual
end;

procedure TVST3Instrument.NoteOff(channel, pitch, velocity: integer);
begin
// virtual...
end;

procedure TVST3Instrument.NoteOn(channel, pitch, velocity: integer);
begin
// virtual...
end;

procedure TVST3Instrument.EditClose;
begin
  OnEditClose;
  FeditorForm:=NIL;
end;

procedure TVST3Instrument.EditOpen(form: TForm);
begin
  FeditorForm:=form;
  OnEditOpen;
  ResendParameters;
end;

procedure TVST3Instrument.ResendParameters;
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

procedure TVST3Instrument.SamplerateChanged(samplerate: single);
begin
// virtual;
end;

procedure TVST3Instrument.UpdateEditorParameter(id: integer;  value: double);
begin
// virtual;
end;

function TVST3Instrument.ParmLookup(id:integer):integer;
VAR i:integer;
begin
  for i:=0 to length(Fparameters)-1 do
    if FParameters[i].id = id then begin result:=i; exit; end;
  result:=-1;
end;

procedure TVST3Instrument.UpdateHostParameter(id: integer; value: double);
VAR index:integer;
begin
  index:=ParmLookup(id);
  if index < 0 then exit;
  Fparameters[index].value:=value;
  if FComponentHandler<>NIL then
    FComponentHandler.PerformEdit(id,value);
end;

procedure TVST3Instrument.OnAutomationReceived(queue: TVST3AutomationQueue);
begin
//  virtual;
end;

procedure TVST3Instrument.OnEditClose;
begin

end;

procedure TVST3Instrument.OnEditOpen;
begin
//
end;

procedure TVST3Instrument.OnFinalize;
begin

end;

procedure TVST3Instrument.OnInitialize;
begin

end;

procedure TVST3Instrument.OnMidiCC(channel,cc, value: integer);
begin

end;

procedure TVST3Instrument.OnPresetChange(prgm: integer);
begin
// virtual
end;

procedure TVST3Instrument.ParameterSetValue(id: integer; value: double);
{ this is called: From Host: ParameterSetValue}
// All CC's for MIdi are called
VAR index,ind:integer;
begin
  index:=ParmLookup(id);
  if index=-1 then exit;
  if (value<0) or (value>1) then exit;
  Fparameters[index].value:=value;
  if isMidiCCId(id) then
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
  else if id = IDPARMPRESET then
  begin
    CodeSite.Send('Program Change');
    SetPreset(round(value*31),true,false);
  end
  else if EditorForm<>NIL then
    UpdateEditorParameter(id,value);
end;

procedure TVST3Instrument.AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;presetChange:boolean=false);

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
