unit
    TestPlug;


interface

uses
    Windows, Forms, SysUtils, Classes, Controls,
    FP_Extra, FP_DelphiPlug, ActiveX, FP_PlugClass, FP_Def, ComCtrls;


const
     // params
     NumParamsConst = 3*4-1;

     pOsc1Level    = -1;
     pOsc1Shape    =  0;
     pOsc1Coarse   =  1;
     pOsc1Fine     =  2;
     pOsc2Level    =  3;
     pOsc3Level    =  7;


     StateSize = NumParamsConst * 4;  // params + switches

     nOsc = 3;


var
   PlugInfo: TFruityPlugInfo = (
     SDKVersion  : CurrentSDKVersion;
     LongName    : 'osc3_d';
     ShortName   : 'FOsc3_d';
     Flags       : FPF_Type_FullGen;
     NumParams   : NumParamsConst;
     DefPoly     : 0  // infinite
   );


type
    TOsc = record
      ShapeP : PWaveT;
      Pitch  : integer;
      Level  : single;
    end;

    TTestPlug = class(TDelphiFruityPlug)
    public
      ParamValue : array[0..NumParamsConst-1] of integer;
      Osc        : array[0..nOsc-1] of TOsc;
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
      procedure KillAllVoices;
      constructor Create(SetTag:Integer; Host: TFruityPlugHost);
      function Voice_Render_Internal(Handle:TVoiceHandle;DestBuffer:PWaveT;var Length:Integer):Integer;
    end;



function CreatePlugInstance(Host:TFruityPlugHost;Tag:TPluginTag): TFruityPlug; stdcall;




implementation

uses
    SynthForm;


const
     nMaxGrains  = 24;
     GrainLength = 512;  // samples per grain


type
    // voice
    TPlugVoice = record
      HostTag : integer;
      Params  : PVoiceParams;
      Pos     : array[0..nOsc-1] of longword;
      State   : integer;
    end;
    PPlugVoice = ^TPlugVoice;


var
   SineWaveP : PWaveT;




// create an initialized plugin & return a pointer to the struct
function CreatePlugInstance;
begin
  Result := TTestPlug.Create(Tag, Host);
end;


// create the object
constructor TTestPlug.Create;
var
   n : integer;
begin
  inherited Create(SetTag, Host);

  Info := @PlugInfo;

  // init
  SineWaveP := PlugHost.WaveTables[0];
  VoiceList := TList.Create;

  EditorForm := TSynthEditorForm.Create(nil);
  with TSynthEditorForm(EditorForm) do
  begin
    FruityPlug := Self;
    for n := 0 to NumParamsConst-1 do
      if ParamCtrl[n] is TTrackBar then
        ParamValue[n] := TTrackBar(ParamCtrl[n]).Position;
    ProcessAllParams;
  end;
end;


// destroy the object
procedure TTestPlug.DestroyObject;
begin
  KillAllVoices;
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


// save/restore the state to/from a stream
procedure TTestPlug.SaveRestoreState;
begin
  if Save then
    Stream.Write(@ParamValue, NumParamsConst * 4, nil)
  else
  begin
    Stream.Read(@ParamValue, NumParamsConst * 4, nil);
    ProcessAllParams;
  end;
end;


// params
function TTestPlug.ProcessParam(ThisIndex, ThisValue, RECFlags: integer): integer;
var
   o, i : integer;
   v    : single;
begin
  if ThisIndex < NumParamsConst then with TSynthEditorForm(EditorForm) do
  begin
    with TTrackBar(ParamCtrl[ThisIndex]) do
    begin
      if RECFlags and REC_FromMIDI <> 0 then
        ThisValue:=TranslateMIDI(ThisValue, Min, Max);

      if RECFlags and REC_UpdateValue <> 0 then
        ParamValue[ThisIndex] := ThisValue
      else if RECFlags and REC_GetValue <> 0 then
        ThisValue := ParamValue[ThisIndex];

      inc(ThisIndex);
      o := ThisIndex shr 2;
      i := (ThisIndex and 3) - 1;
      case i of
        // shape
        pOsc1Shape:  Osc[o].ShapeP := PlugHost.WaveTables[ThisValue];
        // level
        pOsc1Level:
          begin
            Osc[2].Level := ParamValue[pOsc3Level]*Div128;
            v := 1-Osc[2].Level;
            Osc[1].Level := v*ParamValue[pOsc2Level]*Div128;
            Osc[0].Level := v-Osc[1].Level;
            if RECFlags and REC_ShowHint <> 0 then
              ShowHintMsg_Percent(ThisValue, 128);
          end;
        // pitch
        pOsc1Coarse..pOsc1Fine:
          begin
            Osc[o].Pitch := ParamValue[pOsc1Coarse+o*4]*100+ParamValue[pOsc1Fine+o*4];
            if RECFlags and REC_ShowHint<>0 then
              ShowHintMsg_Pitch(ThisValue, i-pOsc1Coarse);
          end;
      end;

      if RECFlags and REC_UpdateControl<>0 then
        Position := ThisValue;
    end;
  end;

  Result := ThisValue;
end;


procedure TTestPlug.GetName(Section, Index, Value: integer; Name: PAnsiChar);
begin
  case Section of
    FPN_Param:
      StrPCopy(Name, GetLongHint(TSynthEditorForm(EditorForm).ParamCtrl[Index].Hint));
  end;
end;





// create a new voice
function TTestPlug.TriggerVoice(VoiceParams: PVoiceParams; SetTag: TPluginTag): TVoiceHandle;
var
   Voice : PPlugVoice;
   n     : integer;
begin
  // create & init
  New(Voice);
  with Voice^ do
  begin
    HostTag := SetTag;
    for n := 0 to nOsc-1 do
      Pos[n] := 0;
    Params := VoiceParams;
    State := 1;    // we're going to use this field for a simple envelope
  end;

  // add to the list
  VoiceList.Add(Voice);
  Result := TVoiceHandle(Voice);
end;


procedure TTestPlug.Voice_Release(Handle: TVoiceHandle);
begin
  PPlugVoice(Handle)^.State := -1;  // releasing
end;


// free a voice
procedure TTestPlug.Voice_Kill(Handle: TVoiceHandle);
begin
  VoiceList.Remove(pointer(Handle));
  Dispose(pointer(Handle));
end;


function TTestPlug.Voice_ProcessEvent(Handle: TVoiceHandle; EventID, EventValue, Flags: integer): integer;
begin
  Result := 0;
end;


procedure TTestPlug.KillAllVoices;
begin
  while VoiceList.Count > 0 do
    PlugHost.Voice_Kill(PPlugVoice(VoiceList.Items[0])^.HostTag, TRUE);
end;




// add an osc
function AddOsc(SourceBuffer, DestBuffer: PWaveT; Length, Pos: longword; Speed: integer; Level: single): longword;
var
   n        : integer;
   i        : single;
begin
  for n := 0 to Length - 1 do
  begin
    // get input
    i := SourceBuffer^[Pos shr WaveT_Shift] * Level;

    // store output
    DestBuffer^[n] := DestBuffer^[n] + i;

    // !!! make sure to disable the overflow thingy in Delphi's compiler, as this is based on an overflow trick
    {$Q-}   // shutting of overflow checking
    inc(Pos, Speed);
  end;

  Result := Pos;
end;

// add an osc (replace)
function PutOsc(SourceBuffer, DestBuffer: PWaveT; Length, Pos: longword; Speed: integer; Level: single): longword;
var
   n        : integer;
   i        : single;
begin
  for n := 0 to Length - 1 do
  begin
    // get input
    i := SourceBuffer^[Pos shr WaveT_Shift] * Level;

    // store output
    DestBuffer^[n] := i;

    // !!! make sure to disable the overflow thingy in Delphi's compiler, as this is based on an overflow trick
    {$Q-}   // shutting off overflow checking
    inc(Pos, Speed);
  end;

  Result := Pos;
end;

procedure CopyMonoToStereo(SourceBuffer: PWaveT; DestBuffer: PWAV32FS; Length: integer; Pan: single);
var
   i        : integer;
   LeftPan  : single;
   RightPan : single;
begin
  // calculate the pan
  LeftPan := 1;
  RightPan := 1;
  if Pan < 0 then
    RightPan := (Pan+64) / 64
  else if Pan > 0 then
    LeftPan := (64-Pan) / 64;

  for i := 0 to Length-1 do
  begin
    DestBuffer^[i, 0] := DestBuffer^[i, 0] + SourceBuffer^[i] * LeftPan;
    DestBuffer^[i, 1] := DestBuffer^[i ,1] + SourceBuffer^[i] * RightPan;
  end;
end;

procedure ApplyEnvelope(Buffer: PWaveT; Length: integer; var State: integer);
var
   i        : integer;
   envelope : single;
begin
  if State = 0 then   // nothing to do if we have to sustain
    Exit;

  envelope := 1;
  for i := 0 to Length-1 do
  begin
    if State = 1 then  // apply an attacking envelope
      envelope := i / Length
    else if State = -1 then
      envelope := (Length-i) / Length;

    Buffer^[i] := Buffer^[i] * envelope;
  end;

  if State = 1 then
    State := 0     // proceed to sustain
  else if State = -1 then
    State := -2;   // next pass we kill the voice
end;



function TTestPlug.Voice_Render_Internal(Handle: TVoiceHandle; DestBuffer: PWaveT; var Length: integer): integer;
var
   o         : integer;
   p         : single;
   Speed     : integer;
   Replace   : boolean;
begin
  with PPlugVoice(Handle)^ do
  begin
    // compute osc speed & add them
    p := Params^.FinalLevels.Pitch;
    Replace := TRUE;
    for o := 0 to nOsc-1 do with Osc[o] do
    begin
      Speed := GetStep_Cents_S(p + Pitch);
      if T32Bit(Level).I = 0 then
        inc(Pos[o], Speed*Length)
      else if Replace then
      begin
        Pos[o] := PutOsc(ShapeP, DestBuffer, Length, Pos[o], Speed, Level * Params^.FinalLevels.Vol);
        Replace := FALSE;
      end
      else
        Pos[o] := AddOsc(ShapeP, DestBuffer, Length, Pos[o], Speed, Level * Params^.FinalLevels.Vol);
    end;
  end;

  Result := FVR_Ok;
end;



procedure TTestPlug.Gen_Render(DestBuffer: PWAV32FS; var Length: integer);
var
   n     : integer;
   temp  : PWaveT;
   voice : PPlugVoice;
begin
  with VoiceList do
  begin
    if Count = 0 then
      Length := 0  // nothing to render, so tell it
    else
    begin
      GetMem(temp, Length shl 2);
      for n := Count-1 downto 0 do
      begin
        voice := PPlugVoice(List[n]);

        if voice^.State = -2 then
          PlugHost.Voice_Kill(voice^.HostTag, TRUE)  // let the host kill the voice
        else
        begin
          Voice_Render_Internal(integer(voice), temp, Length);   // render it
          ApplyEnvelope(temp, Length, voice^.State);
          CopyMonoToStereo(temp, DestBuffer, Length, voice^.Params^.FinalLevels.Pan);
        end;
      end;
      FreeMem(temp);
    end;
  end;
end;

end.




