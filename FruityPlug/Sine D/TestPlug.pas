unit TestPlug;

interface

uses
    Windows, Classes, ActiveX, FP_PlugClass, FP_DelphiPlug, FP_Def, FP_Extra;

const
     NumParamsConst = 1;

var
   PlugInfo: TFruityPlugInfo = (
     SDKVersion  : CurrentSDKVersion;
     LongName    : 'Sine (Delphi)';
     ShortName   : 'Sine';
     Flags       : FPF_Type_FullGen;
     NumParams   : NumParamsConst;
     DefPoly     : 0  // infinite
   );

type
    PVoice = ^TVoice;
    TVoice = record
      Params       : PVoiceParams;
      HostTag      : TVoiceHandle;
      Gated        : boolean;
      Position     : integer;
      CurrentPitch : single;
      Speed        : integer;
      LastLVol     : single;
      LastRVol     : single;
    end;


    TTestPlug = class(TDelphiFruityPlug)
    public
      ParamValue : array[0..NumParamsConst-1] of integer;
      VoiceList  : TList;

      procedure DestroyObject; override;
      function Dispatcher(ID,Index,Value:IntPtr):IntPtr; override;
      procedure SaveRestoreState(const Stream:IStream;Save:LongBool); override;
      procedure GetName(Section,Index,Value:Integer;Name:PAnsiChar); override;
      function ProcessParam(ThisIndex,ThisValue,RECFlags:Integer):Integer; override;
      procedure Gen_Render(DestBuffer: PWAV32FS; var Length: integer); override;
      function TriggerVoice(VoiceParams:PVoiceParams;SetTag:TPluginTag):TVoiceHandle; override;
      procedure Voice_Release(Handle:TVoiceHandle); override;
      procedure Voice_Kill(Handle:TVoiceHandle); override;
      function Voice_ProcessEvent(Handle:TVoiceHandle;EventID,EventValue,Flags:Integer):Integer;  override;

      // internal
      constructor Create(SetTag:Integer; Host: TFruityPlugHost);
    end;


function CreatePlugInstance(Host:TFruityPlugHost;Tag:TPluginTag): TFruityPlug; stdcall;



implementation

uses
    SynthForm, SysUtils, Controls, ComCtrls;

// create an initialized plugin & return a pointer to the struct
function CreatePlugInstance(Host: TFruityPlugHost; Tag:TPluginTag): TFruityPlug;
begin
  Result := TTestPlug.Create(Tag, Host);
end;


{ TTestPlug }

constructor TTestPlug.Create(SetTag: Integer; Host: TFruityPlugHost);
var
   i: integer;
begin
  inherited Create(SetTag, Host);

  Info := @PlugInfo;
  VoiceList := TList.Create;

  EditorForm := TSynthEditorForm.Create(nil);
  with TSynthEditorForm(EditorForm) do
  begin
    FruityPlug := Self;
    for i := 0 to NumParamsConst-1 do
      ParamValue[i] := TTrackBar(ParamCtrl[i]).Position;
  end;
end;

procedure TTestPlug.DestroyObject;
begin
  VoiceList.Free;
  inherited;
end;

function TTestPlug.Dispatcher(ID, Index, Value: IntPtr): IntPtr;
begin
  Result := 0;

  case ID of
     // show the editor
     FPD_ShowEditor:
       with TSynthEditorForm(EditorForm) do
       begin
         if Value = 0 then
         begin
           ParentWindow := 0;
           Hide;
         end
         else
         begin
           ParentWindow := Value;
           Show;
         end;
         EditorHandle := Handle;
       end;

     FPD_SetSampleRate:
       begin
         SmpRate := Value;
         PitchMul := MiddleCMul/SmpRate;
       end;
  end;
end;

procedure TTestPlug.Gen_Render(DestBuffer: PWAV32FS; var Length: integer);
var
   i, j       : integer;
   voice      : PVoice;
   LVol, RVol : single;
   level      : single;
   Buffer     : PWAV32FM;
begin
  Buffer := pointer(PlugHost.TempBuffers[0]);  // get our temporary buffer from the host
  level := ParamValue[0] * 0.01 * 0.5;         // divide by 100 (0..1.27) and only take half of that (too loud otherwise)

  for i := 0 to VoiceList.Count-1 do
  begin
    voice := VoiceList[i];

    // ramp to zero if the voice was released
    if voice^.Gated then
    begin
      LVol := 0;
      RVol := 0;
    end
    // let the host compute volumes taking into account the per-voice pan and volume
    else
      PlugHost.ComputeLRVol(LVol, RVol, voice^.Params^.FinalLevels.Pan, voice^.Params^.FinalLevels.Vol);

    // change the pitch if necessary (slides)
    if voice^.Params^.FinalLevels.Pitch <> voice^.CurrentPitch then
    begin
      voice^.CurrentPitch := voice^.Params^.FinalLevels.Pitch;
      voice^.Speed := GetStep_Cents_S(voice^.CurrentPitch);
    end;

    // copy samples from the sine wavetable to the destination buffer
    for j := 0 to Length-1 do
    begin
      Buffer^[j] := PlugHost.Wavetables[0]^[voice^.Position shr WaveT_Shift] * level;
      // !!! make sure to disable the overflow thingy in Delphi's compiler, as this is based on an overflow trick
      {$Q-}   // shutting off overflow checking
      inc(voice^.Position, voice^.Speed);
    end;

    // add the temporary buffer to the output buffer with ramping
    PlugHost.AddWave_32FM_32FS_Ramp(Buffer, DestBuffer, Length, LVol, RVol, voice^.LastLVol, voice^.LastRVol);
  end;

  // kill voices that were released
  for i := VoiceList.Count-1 downto 0 do
  begin
    voice := VoiceList[i];
    if voice^.Gated then
      PlugHost.Voice_Kill(voice^.HostTag, TRUE);
  end;
end;

procedure TTestPlug.GetName(Section, Index, Value: Integer; Name: PAnsiChar);
begin
  case Section of
    FPN_Param :  StrPCopy(Name, GetLongHint(TSynthEditorForm(EditorForm).ParamCtrl[Index].Hint));
  end;
end;

function TTestPlug.ProcessParam(ThisIndex, ThisValue, RECFlags: Integer): Integer;
begin
  if ThisIndex < NumParamsConst then with TSynthEditorForm(EditorForm) do with TTrackBar(ParamCtrl[ThisIndex]) do
  begin
    if RECFlags and REC_FromMIDI <> 0 then
      ThisValue := TranslateMIDI(ThisValue, Min, Max);

    if RECFlags and REC_UpdateValue <> 0 then
      ParamValue[ThisIndex] := ThisValue
    else if RECFlags and REC_GetValue <> 0 then
      ThisValue := ParamValue[ThisIndex];

    if RECFlags and REC_ShowHint <> 0 then
      ShowHintMsg_Percent(Position, Max);

    if RECFlags and REC_UpdateControl<>0 then
      Position := ThisValue;
  end;

  Result := ThisValue;
end;

procedure TTestPlug.SaveRestoreState(const Stream: IStream; Save: LongBool);
begin
  if Save then
    Stream.Write(@ParamValue, SizeOf(ParamValue), nil)
  else
  begin
    Stream.Read(@ParamValue, SizeOf(ParamValue), nil);
    ProcessAllParams;
  end;
end;

function TTestPlug.TriggerVoice(VoiceParams: PVoiceParams; SetTag: TPluginTag): TVoiceHandle;
var
   Voice : PVoice;
begin
  // create & init
  New(Voice);
  with Voice^ do
  begin
    HostTag := SetTag;
    Params := VoiceParams;
    Gated := FALSE;
    Position := 0;
    CurrentPitch := VoiceParams^.FinalLevels.Pitch;
    Speed := GetStep_Cents_S(CurrentPitch);
    LastLVol := 0;
    LastRVol := 0;
  end;

  // add to the list
  VoiceList.Add(Voice);
  Result := TVoiceHandle(Voice);
end;

procedure TTestPlug.Voice_Kill(Handle: TVoiceHandle);
begin
  VoiceList.Remove(pointer(Handle));
  Dispose(pointer(Handle));
end;

function TTestPlug.Voice_ProcessEvent(Handle: TVoiceHandle; EventID, EventValue, Flags: Integer): Integer;
begin
  Result := 0;
end;

procedure TTestPlug.Voice_Release(Handle: TVoiceHandle);
begin
  PVoice(Handle)^.Gated := TRUE;  // releasing
end;

end.
