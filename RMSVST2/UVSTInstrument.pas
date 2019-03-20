unit UVSTInstrument;

interface

uses
  Classes, Forms, Sysutils, DAV_VSTEffect,CodeSiteLogging,UVSTBase,UCPluginFactory,Generics.Collections,UCDataLayer;

{$define DebugLog}

const PROGRAMCOUNT = 32;


type TVST3Parameter  = record
                        id,steps:integer;
                        title,shorttitle,units:string;
                        min,max,defVal,value:double;
                        automate,isPreset,dirty:boolean; // visible in Host ?
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
type TVST2Instrument = class(TBasicVSTModule)
  private
    Fparameters:TVST3ParameterArray;
    FCurPreset:integer;
    FSomethingDirty:boolean;
    FEditorForm:TForm;
    FPrograms: TList<TVST3Program>;
    Fchunk: ^Byte;
    FChunkLength:integer;
    FEditorRect:ERect;
    procedure ControllerInitialize;
    procedure UpdateChunkSize(length:integer);
    function HostCallGetEffectName(const Index: Integer;
      const Value: TVstIntPtr; const ptr: Pointer;
      const opt: Single): TVstIntPtr;
    function HostCallGetVendorString(const Index: Integer;
      const Value: TVstIntPtr; const ptr: Pointer;
      const opt: Single): TVstIntPtr;
    function HostCallSetProcessPrecision(const Index: Integer;
      const Value: TVstIntPtr; const ptr: Pointer;
      const opt: Single): TVstIntPtr;
    function HostCallEditOpen(const Index: Integer; const Value: TVstIntPtr;
      const ptr: Pointer; const opt: Single): TVstIntPtr;
    function HostCallEditGetRect(const Index: Integer; const Value: TVstIntPtr;
      const ptr: Pointer; const opt: Single): TVstIntPtr;
    function HostCallEditClose(const Index: Integer; const Value: TVstIntPtr;
      const ptr: Pointer; const opt: Single): TVstIntPtr;
    function HostCallGetParamDisplay(const Index: Integer;
      const Value: TVstIntPtr; const ptr: pointer;
      const opt: Single): TVstIntPtr;
    function HostCallGetParamName(const Index: Integer; const Value: TVstIntPtr;
      const ptr: pointer; const opt: Single): TVstIntPtr;
    function ParmLookup(id: integer): integer;
    function HostCallGetProgramName(const Index: Integer;
      const Value: TVstIntPtr; const ptr: pointer;
      const opt: Single): TVstIntPtr;
    function HostCallSetProgram(const Index: Integer; const Value: TVstIntPtr;
      const ptr: pointer; const opt: Single): TVstIntPtr;
    function HostCallGetProgram(const Index: Integer; const Value: TVstIntPtr;
      const ptr: pointer; const opt: Single): TVstIntPtr;
    procedure saveCurrentToProgram(prgm:integer);
    procedure UpdateCurrentFromProgram(prgm: integer; updateComponent: boolean);
    function HostCallClose(const Index: Integer; const Value: TVstIntPtr;
      const ptr: pointer; const opt: Single): TVstIntPtr;
    function HostCallEditIdle(const Index: Integer; const Value: TVstIntPtr;
      const ptr: pointer; const opt: Single): TVstIntPtr;
    function HostCallProcessEvents(const Index: Integer;
      const Value: TVstIntPtr; const ptr: pointer;
      const opt: Single): TVstIntPtr;
    procedure ProcessMidiEvent(const MidiEvent: TVstMidiEvent);
    procedure ProcessMidiSysExEvent(const MidiSysExEvent: TVstMidiSysexEvent);
    procedure SetPreset(prgm:integer;saveCurrent:boolean;updateComponent:boolean);
    function HostCallGetChunk(const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; virtual;
    function HostCallSetChunk(const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; virtual;
    procedure HostCallProcess32Replacing(const Inputs, Outputs: PPSingle; const SampleFrames: Cardinal); override;
    function  HostCallGetParameter(const Index: Integer): Single; override;
    procedure HostCallSetParameter(const Index: Integer; const Value: Single); override;
    function  HostCallCanDo(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
    function  HostCallDispatchEffect(const Opcode: TDispatcherOpcode; const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; override;
    function HostCallGetParamLabel(const Index: Integer;
      const Value: TVstIntPtr; const ptr: pointer;
      const opt: Single): TVstIntPtr;
    procedure InternalSetParameter(const Index: Integer; const Value: Single);
    function getParameterValue(id: integer): double;
    function CreateEditor: TForm;
//////////////////////////
protected

    procedure AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;presetChange:boolean=false);
    procedure ResendParameters;
    function getParameterAsString(id: integer; value: double): string;virtual;
    procedure UpdateHostParameter(id:integer;value:double);
    procedure UpdateProcessorParameter(id:integer;value:double);virtual;
    procedure OnInitialize; virtual;
    procedure OnFinalize;virtual;
    procedure OnCreate(pluginInfo:TVSTInstrumentInfo);override;
    procedure OnEditOpen;virtual;
    procedure OnEditClose;virtual;
    procedure OnEditIdle;virtual;
    procedure OnPresetChange(prgm:integer);virtual;
    procedure OnMidiEvent(byte0,byte1,byte2:integer);virtual;
    procedure OnSysexEvent(s:string);virtual;
    procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);virtual;
    function  GetEditorClass: TFormClass;virtual;
    procedure UpdateEditorParameter(id:integer;value:double);virtual;
    procedure PlayStateChanged(playing:boolean;ppq:integer);override;
    procedure SamplerateChanged(samplerate:single);override;
    procedure TempoChanged(tempo: single);override;
    property EditorForm: TForm read FEditorForm;
    constructor create;override;
public

end;

type TVSTInstrument = TVST2Instrument;  // don't expand this type with own methods!

implementation

uses
  Math,  Windows;

{ TVST2Instrument }

{$POINTERMATH ON}

procedure TVST2Instrument.UpdateProcessorParameter(id:integer;value:double);
begin
// virtual
end;

procedure TVST2Instrument.OnCreate(pluginInfo: TVSTInstrumentInfo);
VAR i:integer;
begin
  inherited;
  with Effect^ do
  begin
    EffectFlags:=EffectFlags + [effFlagsHasEditor,effFlagsProgramChunks];
    if pluginInfo.PluginDef.isSynth then
      EffectFlags:=EffectFlags + [effFlagsIsSynth];

    for i:=0 to 3 do
      uniqueID[i] := AnsiChar(ord(pluginInfo.PluginDef.vst2id[i+1]));
  end;
  ControllerInitialize;
  with Effect^ do
    UpdateChunkSize(32*numPrograms*numParams);
end;

procedure TVST2Instrument.OnEditClose;
begin
// virtual
end;

procedure TVST2Instrument.OnEditIdle;
begin
// virtual
end;

procedure TVST2Instrument.OnEditOpen;
begin
// virtual
end;

procedure TVST2Instrument.OnFinalize;
begin
// virtual
end;

procedure TVST2Instrument.OnInitialize;
begin
// virtual
end;

procedure TVST2Instrument.OnMidiEvent(byte0, byte1, byte2: integer);
begin
// virtual
end;

procedure TVST2Instrument.OnPresetChange(prgm: integer);
begin
// virtual
end;

procedure TVST2Instrument.UpdateEditorParameter(id: integer; value: double);
begin
// virtual
end;

procedure TVST2Instrument.UpdateHostParameter(id: integer; value: double);
VAR index:integer;
begin
  index:=ParmLookup(id);
  if index<>-1 then
  begin
    SetParameterAutomated(index,value);
    InternalSetParameter(index,value);
  end;
end;

procedure TVST2Instrument.ControllerInitialize;
VAR i:integer;
begin
  for i:=0 to PROGRAMCOUNT-1 do
    FPrograms.Add(TVST3Program.Create);
  OnInitialize;
  Effect.numParams:=length(FParameters);
  Effect.numPrograms:=FPrograms.Count;
  for i:=0 to PROGRAMCOUNT-1 do
    saveCurrentToProgram(i);
  SetPreset(0,false,true);
end;

constructor TVST2Instrument.create;
VAR i:integer;
begin
  inherited;
  Fchunk:=NIL;
  FchunkLength:=0;
  FPrograms:=TList<TVST3Program>.Create;
end;

function TVST2Instrument.GetEditorClass: TFormClass;
begin
// virtual
  result:=NIL;
end;

function TVST2Instrument.ParmLookup(id:integer):integer;
VAR i:integer;
begin
  for i:=0 to length(Fparameters)-1 do
    if FParameters[i].id = id then begin result:=i; exit; end;
  result:=-1;
end;

procedure TVST2Instrument.PlayStateChanged(playing: boolean; ppq: integer);
begin
// virtual
end;

procedure TVST2Instrument.Process32(samples, channels: integer; inputp,  outputp: PPSingle);
begin
// virtual
end;

procedure TVST2Instrument.ResendParameters;
VAR i,id,count:integer;
    value:double;
begin
  if FeditorForm=NIL then exit;
  count:=length(Fparameters);
  for i:=0 to count-1 do
  begin
    id:=Fparameters[i].id;
    value:=Fparameters[i].value;
    UpdateEditorParameter(id,value);
  end;
end;

procedure TVST2Instrument.SamplerateChanged(samplerate: single);
begin
// virtual
end;

procedure TVST2Instrument.saveCurrentToProgram(prgm: integer);
begin
  FPrograms[prgm].saveParams(FParameters,length(FParameters));
end;

procedure TVST2Instrument.SetPreset(prgm: integer; saveCurrent,  updateComponent: boolean);
begin
  if saveCurrent then
   saveCurrentToProgram(FCurPreset);
  FCurPreset:=prgm;
  UpdateCurrentFromProgram(prgm,updateComponent);
  OnPresetChange(prgm);
end;

procedure TVST2Instrument.TempoChanged(tempo: single);
begin
// virtual
end;

procedure TVST2Instrument.OnSysexEvent(s: string);
begin
// virtual
end;

procedure TVST2Instrument.UpdateChunkSize(length: integer);
begin
  if length<FChunkLength then exit;
  if FChunk<>NIL then FreeMem(FChunk);
  FchunkLength:=length;
  GetMem(FChunk,length);
end;

procedure TVST2Instrument.UpdateCurrentFromProgram(prgm:integer;updateComponent:boolean);
VAR i:integer;
    value:double;
begin
  for i:=0 to length(FParameters)-1 do
  begin
    value:=FPrograms[prgm].getParam(i);
// TODO: remove at VST3 ?    if abs(value-FParameters[i].value) > 0.00001 then
      InternalSetParameter(i,value);
  end;
end;

procedure TVST2Instrument.AddParameter(id:integer;title,shorttitle,units:string;min,max,val:double;automate:boolean=true;steps:integer=0;presetChange:boolean=false);

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

function TVST2Instrument.HostCallCanDo(const Index: Integer;
  const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
 Result := 0;
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallCanDo (' + StrPas(PAnsiChar(ptr)) + ')'); {$ENDIF}
  if StrComp(PAnsiChar(ptr), 'receiveVstEvents')      = 0 then Result := 1 else
  if StrComp(PAnsiChar(ptr), 'receiveVstMidiEvent')   = 0 then Result := 1 else
  if StrComp(PAnsiChar(ptr), 'receiveVstTimeInfo')    = 0 then Result := 1 else
  if StrComp(PAnsiChar(ptr), 'sendVstMidiEvent')      = 0 then Result := 1 else
  if StrComp(PAnsiChar(ptr), '2in2out')               = 0 then Result :=  1 else
  if StrComp(PAnsiChar(ptr), 'midiProgramNames')      = 0 then Result := 1 else
    result:=-1;
end;

function TVST2Instrument.HostCallDispatchEffect(const Opcode: TDispatcherOpcode;
  const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer;
  const opt: Single): TVstIntPtr;
begin

 {$IFDEF DebugLog} if opCode<>effProcessEvents then CodeSite.Send('TVST2Instrument.HostCallDispatchEffect (' +ord(opCode).ToString+ ')'); {$ENDIF}
  case opcode of
    effCanDo:           Result := HostCallCanDo(Index, Value, PTR, opt);
    effClose:           Result := HostCallClose(Index, Value, PTR, opt);
    effEditOpen:        Result := HostCallEditOpen(Index, Value, PTR, opt);
    effEditClose:       Result := HostCallEditClose(Index, Value, PTR, opt);
    effEditGetRect:     Result := HostCallEditGetRect(Index, Value, PTR, opt);
    effGetParamLabel:   Result := HostCallGetParamLabel(Index, Value, PTR, opt);
    effGetParamDisplay: Result := HostCallGetParamDisplay(Index, Value, PTR, opt);
    effGetParamName:    Result := HostCallGetParamName(Index, Value, PTR, opt);
    effGetEffectName:   Result := HostCallGetEffectName(Index, Value, PTR, opt);
    effGetVendorString: Result := HostCallGetVendorString(Index, Value, PTR, opt);
    effGetChunk:        Result := HostCallGetChunk(Index, Value, PTR, opt);
    effSetChunk:        Result := HostCallSetChunk(Index, Value, PTR, opt);
    effGetProgramName:  Result := HostCallGetProgramName(Index, Value, PTR, opt);
    effSetProgram:      Result := HostCallSetProgram(Index, Value, PTR, opt);
    effGetProgram:      Result := HostCallGetProgram(Index, Value, PTR, opt);
    effEditIdle:        Result := HostCallEditIdle(Index, Value, PTR, opt);
    effProcessEvents:   Result := HostCallProcessEvents(Index, Value, PTR, opt);
    else                Result:=inherited;
  end;
end;

function TVST2Instrument.HostCallProcessEvents(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
  procedure ProcessEvents(const Events: TVstEvents);
  var
    Event: Integer;
  begin
   with Events do
    for Event := 0 to numEvents - 1 do
     case Events[Event]^.EventType of
      etMidi  : ProcessMidiEvent(PVstMidiEvent(Events[Event])^);
      etSysEx : ProcessMidiSysExEvent(PVstMidiSysExEvent(Events[Event])^);
 //       else ProcessEvent(Events[Event]^);
     end;
  end;

begin
// Called from NON - UI ?  {$IFDEF DebugLog} CodeSite.Send('HostCallProcessEvents'); {$ENDIF}
 if Assigned(ptr) then ProcessEvents(PVstEvents(ptr)^);
 Result:= 0
end;


procedure TVST2Instrument.ProcessMidiEvent(const MidiEvent: TVstMidiEvent);
begin
// MIDI Realtime Data is Not received...  CodeSite.Send('MIDI: '+m.Status.ToString);
  with MidiEvent do
    OnMidiEvent(MidiData[0],MidiData[1],MidiData[2]);
  if GetPluginInfo.PluginDef.softMidiThru then
    MidiOut(MidiEvent.MidiData[0],MidiEvent.MidiData[1],MidiEvent.MidiData[2],MidiEvent.MidiData[3]);
end;

procedure TVST2Instrument.ProcessMidiSysExEvent(const MidiSysExEvent: TVstMidiSysexEvent);
VAR i:integer;
    s:string;
begin
  s:='';
  for i:=0 to MidiSysExEvent.DumpBytes-1 do
    s:=s+MidiSysExEvent.SysExDump[i];
  OnSysExEvent(s);
end;

function TVST2Instrument.HostCallSetProgram(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallSetProgram'+inttostr(Value)); {$ENDIF}
 SetPreset(integer(value),true,false);
 Result := 0;
end;

function TVST2Instrument.HostCallEditIdle(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
VAR i:integer;
begin
  if FEditorForm<>NIL then
    OnEditIdle;
  if not FSomethingDirty then exit;
  for i:=0 to length(Fparameters)-1 do
    if Fparameters[i].dirty then
    begin
      UpdateEditorParameter(Fparameters[i].id,Fparameters[i].value);
      Fparameters[i].dirty:=false
    end;
  FSomethingDirty:=false;
  Result := 0;
end;

function TVST2Instrument.getParameterAsString(id:integer;value:double):string;
begin
// virtual
  result:=''
end;

function TVST2Instrument.HostCallGetParamDisplay(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
var
  Str : AnsiString;
  v:double;
begin
  v:=Fparameters[index].value;
  Str:=getParameterAsString(index,v);
  if Str='' then
     with Fparameters[index] do
     begin
       v:=min+v*(max-min);
       if abs(v-round(v))<0.001 then
         Str:=round(v).ToString
       else
         Str:=Copy(FloatToStr(v),1,6);
     end;
 StrPCopy(Ptr, Str);
end;

function TVST2Instrument.HostCallGetParamLabel(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
var
  Str : AnsiString;
begin
   Str:=Fparameters[index].units;
   StrPCopy(Ptr, Str);
end;

function TVST2Instrument.HostCallGetParamName(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
begin
  StrPCopy(Ptr, AnsiString(FParameters[Index].title));
end;

function TVST2Instrument.HostCallClose(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
begin
  OnFinalize;
end;


function TVST2Instrument.HostCallSetProcessPrecision(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
// {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallSetProcessPrecision'); {$ENDIF}
// Result := Integer(fProcessPrecisition); // [value]: @see VstProcessPrecision  @see AudioEffectX::setProcessPrecision
end;

function TVST2Instrument.HostCallGetProgramName(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallGetProgramName'+inttostr(Value)); {$ENDIF}
  StrPCopy(Ptr, AnsiString('Preset '+format('%.2d',[FCurPreset+1])));
  Result:=0;
end;

function TVST2Instrument.HostCallGetProgram(const Index: Integer; const Value: TVstIntPtr; const ptr: pointer; const opt: Single): TVstIntPtr;
begin
 Result := FCurPreset;
end;


function TVST2Instrument.HostCallEditClose(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallEditClose'); {$ENDIF}
   if Assigned(FEditorForm) then
   begin
     OnEditClose;
     FreeAndNil(FEditorForm);
   end;
   Result := 0;
end;

function TVST2Instrument.HostCallEditGetRect(const Index: Integer;
  const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
VAR form:TForm;
begin

 Result := 0;
 if Assigned(ptr) then
  begin
   PPERect(ptr)^ := @FEditorRect;
   FEditorRect.Top:=0;
   FEditorRect.Left:=0;
   FEditorRect.Bottom:=600;
   FEditorRect.Right:=600;
   form:=CreateEditor;
   if form<>NIL then
   begin
     FEditorRect.Bottom:=form.height;
     FEditorRect.Right:=form.width;
     form.free;
   end;
  end;
end;

function TVST2Instrument.CreateEditor:TForm;
VAR FeditorFormClass:TFormClass;
begin
  result:=NIL;
  FeditorFormClass:=GetEditorClass;
  if FeditorFormClass = NIL then FeditorFormClass:=GetPluginInfo.PluginDef.ecl;
  if FeditorFormClass = NIL then exit;
  result := FeditorFormClass.Create(NIL);
end;

function TVST2Instrument.HostCallEditOpen(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
  {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallEditOpen'); {$ENDIF}
  Result := 0;
  if Assigned(ptr) then
  begin
    FEditorForm := CreateEditor;
    if Assigned(FEditorForm) then
      try
       Result := 1;
       with FEditorForm do
        begin
         ParentWindow := HWnd(ptr);
         Visible := True;
         BorderStyle := bsNone;
         SetBounds(0, 0, Width, Height);
         Invalidate;
        end;
      except
      end;
    OnEditOpen;
  end;
end;

const STATE_MAGIC = 346523;
const MAGIC_DL =42977;
function TVST2Instrument.HostCallGetChunk(const Index: Integer;
  const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr;
VAR i,n:integer;
    sl,ssl:TDataLayer;

  procedure SaveTochunk(s:string);
  VAR i,l:integer;
  begin
    l:=length(s);
    UpdateChunkSize(l);
    for i:=0 to l-1 do
      Fchunk[i]:=ord(s[i+1]);
  end;
begin
  saveCurrentToProgram(FCurPreset);
  CodeSite.Send('HostCallGetChunk met preset='+ FCurPreset.ToString);
  sl:=TDataLayer.Create;
  sl.setAttributeI('Magick',STATE_MAGIC);
  ssl:=TDataLayer.Create;
  for i:=0 to PROGRAMCOUNT-1 do
  begin
    ssl.Clear;
    FPrograms[i].GetState(FParameters,length(FParameters),ssl);
    sl.SaveSection('Program'+i.ToString,ssl);
  end;
  ssl.Free;
  SaveTochunk(sl.Text);
//  sl.SaveToFile('c:\temp\chunk.txt');
  Pointer(ptr^):=Fchunk;
  result:=length(sl.Text);
  sl.Free;
end;

function TVST2Instrument.HostCallSetChunk(const Index: Integer;
  const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr;
VAR i:integer;
    sl,ssl:TDataLayer;
      function LoadFromChunk:string;
      VAR i:integer;
          p:^byte;
      begin
        p:=ptr;
        result:='';
        for i:=0 to Value-1 do
          result:=result+chr(p[i]);
      end;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallSetChunk'+inttostr(Index)); {$ENDIF}
  begin
    sl:=TDataLayer.Create;
    sl.Text:=LoadFromChunk;
    if STATE_MAGIC<>sl.getAttributeI('Magick') then
    begin
      CodeSite.Send('Set State Error: ');
      exit;
    end;

    ssl:=TDataLayer.Create;
    for i:=0 to PROGRAMCOUNT-1 do
    begin
      sl.LoadSection('Program'+i.ToString,ssl);
      FPrograms[i].SetState(FParameters,length(FParameters),ssl);
    end;
    ssl.free;
    sl.free;
  end;
  SetPreset(FCurPreset,false,true);
  result:=Value;
end;

function TVST2Instrument.HostCallGetEffectName(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallGetEffectName'); {$ENDIF}
 Result := 0;
 if Assigned(ptr) then
  begin
   StrPCopy(ptr, AnsiString(GetPluginInfo.PluginDef.name));
   Result := 1;
  end;
end;

function TVST2Instrument.HostCallGetVendorString(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallGetVendorString'); {$ENDIF}
 Result := 0;
 if Assigned(ptr) then
  begin
   StrPCopy(ptr,AnsiString(GetPluginInfo.factoryDef.vendor));
   Result := 1;
  end;
end;

function TVST2Instrument.getParameterValue(id: integer): double;
VAR index:integer;
begin
  result:=0;
  index:=ParmLookup(id);
  if index < 0 then exit;
  result:=Fparameters[index].value;
end;

procedure TVST2Instrument.HostCallProcess32Replacing(const Inputs,
  Outputs: PPSingle; const SampleFrames: Cardinal);
begin
  Process32(sampleFrames,2,inputs, outputs);
end;

function TVST2Instrument.HostCallGetParameter(const Index: Integer): Single;
begin
 {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallGetParameter:'+Index.ToString); {$ENDIF}
  result:=FParameters[index].value;
end;

procedure TVST2Instrument.HostCallSetParameter(const Index: Integer;  const Value: Single);
begin
  {$IFDEF DebugLog} CodeSite.Send('TVST2Instrument.HostCallSetParameter:'+Value.ToString); {$ENDIF}
  InternalSetParameter(index,value);
end;

procedure TVST2Instrument.InternalSetParameter(const Index: Integer;  const Value: Single);
begin
  FParameters[index].value:=value;
  FParameters[index].dirty:=true;
  FSomethingDirty:=true;
// See Document OnAutomateUpdateParameter
//  if FeditorForm<>NIL then
//    UpdateEditorParameter(FParameters[index].id,value);
  updateProcessorParameter(FParameters[index].id,value);
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
