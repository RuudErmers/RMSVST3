unit
    UVSTInstrument;


interface

uses
    Windows, Forms, SysUtils, Classes, Controls,UVSTBase,
    FP_Extra, FP_DelphiPlug, ActiveX, FP_PlugClass, FP_Def, ComCtrls;


var
   PlugInfo: TFruityPlugInfo = (
     SDKVersion  : CurrentSDKVersion;
     LongName    : 'MyFruityPlug';
     ShortName   : 'ruudje';
     Flags       : FPF_Type_FullGen;
     NumParams   : 0;
     DefPoly     : 0  // infinite
   );

type
    TVSTInstrument = class;
    TFPVoice = record
                 pitch,tag:integer;
               end;
    TVST3Parameter  = record
                        id,steps:integer;
                        title,shorttitle,units:string;
                        min,max,defVal,value:double;
                        dirty:boolean;
                      end;
    TVST3ParameterArray = TArray<TVST3Parameter>;

    TRMSFruityPlug = class(TDelphiFruityPlug)
      FLongName,FShortName:array[0..127] of AnsiChar;
      FPlugin    : TVSTInstrument;
      FVoiceCounter:integer;
      FVoiceTag:array[0..31] of TFPVoice;
      FinputP,FoutputP:PPsingle;
      FBufferLength:integer;
      FEditorOpen:boolean;
  private
    procedure CheckBuffers(length: integer);
    public
      procedure DestroyObject; override;
      function Dispatcher(ID,Index,Value:IntPtr):IntPtr; override;
      procedure SaveRestoreState(const Stream:IStream;Save:LongBool); override;
      procedure GetName(Section,Index,Value:Integer;Name:PAnsiChar); override;
      function ProcessParam(ThisIndex,ThisValue,RECFlags:Integer):Integer; override;
      procedure Gen_Render(DestBuffer: PWAV32FS; var Length: integer); override;
      function  TriggerVoice(VoiceParams:PVoiceParams;SetTag:TPluginTag):TVoiceHandle; override;
      procedure Voice_Release(Handle:TVoiceHandle); override;
      procedure Voice_Kill(Handle:TVoiceHandle); override;
      function  Voice_ProcessEvent(Handle:TVoiceHandle;EventID,EventValue,Flags:Integer):Integer;  override;
      procedure MIDIIn(var Msg:Integer); override;  // (GM)
      procedure Idle_Public; override;
      // internal
      constructor Create(SetTag:Integer; Host: TFruityPlugHost;pluginInfo:TVSTInstrumentInfo);

    end;
   TVSTInstrument = class(TVSTBase)
   private
      Fparameters:TVST3ParameterArray;
      FFruityPlug:TRMSFruityPlug;
      FSomethingDirty:boolean;
      procedure ControllerInitialize(fruityPlug:TRMSFruityPlug);
      procedure InternalSetParameter(const Index: Integer; const Value: Single);
      function ParmLookup(id: integer): integer;
      function getParameterValue(index:integer):double;
      procedure OnIdle;
  protected
      procedure AddParameter(id:integer;title, shorttitle,units:string;min,max,val:double);
      procedure UpdateHostParameter(id:integer;value:double);
      procedure ResendParameters;
      function getEditorClass:TformClass;virtual;
      procedure OnEditOpen;virtual;
      procedure OnEditClose;virtual;
      procedure OnEditIdle;virtual;
      procedure SamplerateChanged(samplerate:single);virtual;
      procedure Process32(samples,channels:integer;inputp, outputp: PPSingle);virtual;
      procedure UpdateProcessorParameter(id:integer;value:double);virtual;
      procedure OnInitialize;virtual;
      procedure UpdateEditorParameter(id:integer;value:double);virtual;
      procedure OnProgramChange(prgm:integer);virtual;
      function  EditorForm: TForm;
      function getParameterAsString(id: integer; value: double): string; virtual;
      procedure OnSysexEvent(s:string);virtual;
      procedure OnMidiEvent(byte0,byte1,byte2:integer);virtual;
      procedure TempoChanged(tempo:single);virtual;
      procedure PlayStateChanged(playing:boolean;ppq:integer);virtual;
      procedure OnFinalize;virtual;
  public

   end;

function CreatePlugin(Host:TFruityPlugHost;Tag:TPluginTag;pluginInfo:TVSTInstrumentInfo): TFruityPlug;

implementation

uses UCodeSiteLogger;

// create an initialized plugin & return a pointer to the struct
function CreatePlugin(Host:TFruityPlugHost;Tag:TPluginTag;pluginInfo:TVSTInstrumentInfo): TFruityPlug;
begin
  Result := TRMSFruityPlug.Create(Tag, Host,pluginInfo);
end;

// Two deprecated AnsiString constructions..
procedure AssignString(ptr:pAnsiChar;s:string);overload;
VAR i:integer;
begin
  for i:=1 to length(s) do
  begin
    ptr^:=AnsiChar(s[i]);
    inc(ptr);
  end;
  ptr^:=#0
end;

function AssignString(ptr:pAnsiChar):string;overload;
begin
  result:='';
  while ptr^<>#0 do
  begin
    result:=result+Char(ptr^);
    inc(ptr);
  end;
end;


// create the object
constructor TRMSFruityPlug.Create(SetTag:Integer; Host: TFruityPlugHost;pluginInfo:TVSTInstrumentInfo);
VAR FeditorFormClass:TFormClass;
begin
  inherited Create(SetTag, Host);
  CheckBuffers(2000);
  FPlugin:=TVSTInstrument(pluginInfo.PluginDef.cl.Create);
  fPlugin.OnCreate(pluginInfo);
  fPlugin.ControllerInitialize(self);
  PlugInfo.NumParams:=length(fPlugin.FParameters);
  AssignString(FLongName,pluginInfo.PluginDef.name+'('+pluginInfo.factoryDef.vendor+')');
  AssignString(FShortName,pluginInfo.PluginDef.name);
  Info := @PlugInfo;
  PlugInfo.LongName:=@FLongName[0];
  PlugInfo.ShortName:=@FShortName[0];

  FeditorFormClass := fPlugin.getEditorClass;
  if FeditorFormClass = NIL then FeditorFormClass:=PluginInfo.PluginDef.ecl;
  if FeditorFormClass = NIL then EditorForm:=NIL
  else EditorForm:=FeditorFormClass.Create(NIL);
  Host.Dispatcher(SetTag,FHD_WantMIDIInput,0,1);
  Host.Dispatcher(SetTag,FHD_WantIdle,0,1);
  fPlugin.ResendParameters;
end;

procedure TRMSFruityPlug.DestroyObject;
begin
  fPlugin.OnFinalize;
  inherited;

  WriteLog('TRMSFruityPlug.DestroyObject ');
end;


function TRMSFruityPlug.Dispatcher(ID, Index, Value: IntPtr): IntPtr;
begin
  Result := 0;
//  WriteLog('Dispatcher ('+Id.ToString+' ' + Index.ToString+' '+Value.ToString + ')');
  case ID of
     // show the editor
     FPD_ShowEditor:
       with EditorForm do
       begin
         if Value = 0 then
         begin
           FEditorOpen:=false;
           fPlugin.OnEditClose;
           Hide;  // I've swapped this line with the next
           ParentWindow := 0;
         end
         else
         begin
           ParentWindow := Value;
           FEditorOpen:=true;
           Show;
           fPlugin.OnEditOpen;
         end;
         EditorHandle := Handle;
       end;

     FPD_SetSampleRate:
       begin
         fPlugin.SamplerateChanged(Value);
       end;
  end;
end;


// save/restore the state to/from a stream
procedure TRMSFruityPlug.SaveRestoreState;
begin
  if Save then
//    Stream.Write(@ParamValue, NumParamsConst * 4, nil)
  else
  begin
//    Stream.Read(@ParamValue, NumParamsConst * 4, nil);
//    ProcessAllParams;
  end;
end;

const MIDI_NOTE_ON = $90;
      MIDI_NOTE_OFF = $80;

function TRMSFruityPlug.TriggerVoice(VoiceParams: PVoiceParams; SetTag: IntPtr): TVoiceHandle;
VAR pitch,velocity:integer;
begin
// if you want to create a 'midievent' from this use VoiceParams.FinalLevels.Pitch
  WriteLog('TRMSFruityPlug.TriggerVoice (' + VoiceParams.FinalLevels.Pitch.ToString + ')');

  pitch:=round(60+VoiceParams.FinalLevels.Pitch/100);
  if pitch<=0 then pitch:=0;
  if pitch>=127 then pitch:=127;
  velocity:=127*round(VoiceParams.FinalLevels.Vol);
  result:=TVoiceHandle(FVoiceCounter);
  FVoiceTag[FVoiceCounter].tag:=SetTag;
  FVoiceTag[FVoiceCounter].pitch:=pitch;
  FVoiceCounter:=(FVoiceCounter+1) MOD 32;
  fPlugin.OnMidiEvent(MIDI_NOTE_ON,pitch,velocity);
end;

procedure TRMSFruityPlug.Voice_Release(Handle: TVoiceHandle);
VAR pitch:integer;
begin
  WriteLog('TRMSFruityPlug.Voice_Release (' + Handle.ToString + ')');
  pitch:=FVoiceTag[Handle].pitch;
  fPlugin.OnMidiEvent(MIDI_NOTE_OFF,pitch,64);
  PlugHost.Voice_Kill(FVoiceTag[Handle].Tag, TRUE)
end;

// free a voice
procedure TRMSFruityPlug.Voice_Kill(Handle: TVoiceHandle);
begin
  WriteLog('TRMSFruityPlug.Voice_Kill (' + Handle.ToString + ')');
  // make sure this method is not abstract
end;


function TRMSFruityPlug.Voice_ProcessEvent(Handle: TVoiceHandle; EventID, EventValue, Flags: integer): integer;
begin
  Result := 0;
end;


procedure TVSTInstrument.AddParameter(id: integer; title, shorttitle,  units: string; min, max, val: double);
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
  n:=Length(Fparameters);
  SetLength(Fparameters,n+1);
  FParameters[n]:=params;
end;

procedure TVSTInstrument.UpdateEditorParameter(id: integer; value: double);
begin

end;

function TVSTInstrument.ParmLookup(id:integer):integer;
VAR i:integer;
begin
  for i:=0 to length(Fparameters)-1 do
    if FParameters[i].id = id then begin result:=i; exit; end;
  result:=-1;
end;

procedure TVSTInstrument.UpdateHostParameter(id: integer; value: double);
VAR index:integer;
begin
  index:=ParmLookup(id);
  if index<>-1 then
  begin
  // todo: host update  SetParameterAutomated(index,value);
    InternalSetParameter(index,value);
  end;
end;

procedure TVSTInstrument.UpdateProcessorParameter(id: integer; value: double);
begin

end;


procedure TVSTInstrument.PlayStateChanged(playing: boolean; ppq: integer);
begin

end;

procedure TVSTInstrument.Process32(samples, channels: integer; inputp, outputp: PPSingle);
begin

end;

// params
function TRMSFruityPlug.ProcessParam(ThisIndex, ThisValue, RECFlags: integer): integer;
begin
  if RECFlags and REC_FromMIDI <> 0 then
       ThisValue:=TranslateMIDI(ThisValue, 0, 65535);
  if RECFlags and REC_UpdateValue <> 0 then
  begin
    WriteLog('ProcessParam UPDATE (' + ThisIndex.ToString + ' '+ThisValue.ToString + ')');
    fPlugin.InternalSetParameter(ThisIndex, ThisValue/65536);
  end;
  if RECFlags and REC_GetValue <> 0 then
  begin
   WriteLog('ProcessParam GET (' + ThisIndex.ToString + ' '+ThisValue.ToString + ')');
   ThisValue:=round(fPlugin.getParameterValue(ThisIndex)*65536);
  end;
  Result:=ThisValue;
end;

procedure TVSTInstrument.OnIdle;
VAR i:integer;
begin
  if not FSomethingDirty then exit;
  for i:=0 to length(Fparameters)-1 do
    if Fparameters[i].dirty then
    begin
      UpdateEditorParameter(Fparameters[i].id,Fparameters[i].value);
      Fparameters[i].dirty:=false
    end;
  FSomethingDirty:=false;
end;

procedure TVSTInstrument.InternalSetParameter(const Index: Integer;  const Value: Single);
begin
  FParameters[index].value:=value;
  FParameters[index].dirty:=true;
  FSomethingDirty:=true;
// See Document OnAutomateUpdateParameter
//  if FeditorForm<>NIL then
//    UpdateEditorParameter(FParameters[index].id,value);
  updateProcessorParameter(FParameters[index].id,value);
end;


procedure TVSTInstrument.ResendParameters;
VAR i,id,count:integer;
    value:double;
begin
  count:=length(Fparameters);
  for i:=0 to count-1 do
  begin
    id:=Fparameters[i].id;
    value:=Fparameters[i].value;
    UpdateEditorParameter(id,value);
    InternalSetParameter(i,value);
  end;
end;

procedure TVSTInstrument.TempoChanged(tempo: single);
begin

end;

procedure TRMSFruityPlug.GetName(Section, Index, Value: integer; Name: PAnsiChar);
begin
  case Section of
    FPN_Param:
      AssignString(Name, fPlugin.FParameters[index].shorttitle);
// todo.. someday...     FPN_ParamValue: fPlugin.getParameterAsString()
  end;
end;

procedure TRMSFruityPlug.Idle_Public;
begin
  fPlugin.OnIdle;
  if FeditorOpen then
    fPlugin.OnEditIdle;
end;

procedure TRMSFruityPlug.MIDIIn(var Msg: Integer);
VAR i,saveMsg:integer;
    b:array[0..3] of byte;
const  MIDI_CC = $B0;
begin
  WriteLog('TRMSFruityPlug.MIDIIn'+ Msg.ToString + ')');
// For now, I will only react to MIDI_CC
// We could use this to process Noteon/Off as well, but then midi thru does not work
  saveMsg:=msg;
  for i:=0 to 3 do
  begin
    b[i]:=saveMsg and $FF;
    saveMsg:=savemsg SHR 8;
  end;
  if (b[0] and $F0) = MIDI_CC then
    fPlugin.OnMidiEvent(b[0],b[1],b[2]);
end;

procedure TVSTInstrument.ControllerInitialize;
begin
  FFruityPlug:=FruityPlug;
  OnInitialize;
end;

procedure TVSTInstrument.OnEditClose;
begin
// virtual
end;

procedure TVSTInstrument.OnEditIdle;
begin
// virtual
end;

procedure TVSTInstrument.OnEditOpen;
begin
// virtual
end;

procedure TVSTInstrument.OnFinalize;
begin

end;

procedure TVSTInstrument.OnInitialize;
begin

end;

procedure TVSTInstrument.OnMidiEvent(byte0, byte1, byte2: integer);
begin

end;

procedure TVSTInstrument.OnProgramChange(prgm: integer);
begin

end;

procedure TVSTInstrument.SamplerateChanged(samplerate: single);
begin
// virtual
end;

procedure TVSTInstrument.OnSysexEvent(s: string);
begin

end;

{$POINTERMATH ON}
procedure TRMSFruityPlug.CheckBuffers(length:integer);
VAR i:integer;
begin
  if ( length>FBufferLength) then
  begin
    if FinputP<>NIL then
    begin
      for i:=0 to 1 do
        FreeMem(FinputP[i]);
      FreeMem(FinputP);
    end;
    FBufferLength:=2*length;
    GetMem(FinputP,2*sizeof(PSingle));
    for i:=0 to 1 do
      GetMem(FInputP[i],FBufferLength*sizeof(single));

    if FoutputP<>NIL then
    begin
      for i:=0 to 1 do
        FreeMem(FoutputP[i]);
      FreeMem(FoutputP);
    end;
    FBufferLength:=2*length;
    GetMem(FoutputP,2*sizeof(PSingle));
    for i:=0 to 1 do
      GetMem(FoutputP[i],FBufferLength*sizeof(single));
  end
end;

procedure TRMSFruityPlug.Gen_Render(DestBuffer: PWAV32FS; var Length: integer);
VAR i:integer;
begin
  // if there is nothing to do then...
  // Length:=0;
  // else Process and Deinterlase
  CheckBuffers(length);
  fPlugin.Process32(length,2,FinputP,FOutputP);
  for i:=0 to length-1 do
  begin
    DestBuffer[i,0]:=FoutputP[0][i];
    DestBuffer[i,1]:=FoutputP[1][i];
  end;
end;

function TVSTInstrument.EditorForm: TForm;
begin
  result:=FFruityPlug.EditorForm;
end;

function TVSTInstrument.getEditorClass: TformClass;
begin
  result:=NIL;
end;

function TVSTInstrument.getParameterAsString(id: integer;  value: double): string;
begin

end;

function TVSTInstrument.getParameterValue(index: integer): double;
begin
  result:=0;
  if (index>=0) and (index<length(fParameters)) then
    result:=fParameters[index].value;
end;

end.




