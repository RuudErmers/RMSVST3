unit UMyVstDSP;

interface

type TBaseOscillator = class(TObject)
  private
    FSampleRate : double;
    FSampleReci : double;
    FFrequency  : double;
    procedure SetFrequency(const Value: double);
    procedure SetSampleRate(const Value: double);
  protected
    function ValueAt(FxPos:double): double;virtual; // FxPos: 0..1
  public
    constructor Create(const SampleRate: double); virtual;
    property Frequency: double read FFrequency write SetFrequency;
    property SampleRate: double read FSampleRate write SetSampleRate;
  end;

type TOscillatorBlep = class(TBaseOscillator)
  protected
    function ValueAt(FxPos:double): double;override; // FxPos: 0..1
  private
    function PolyBlep(t: double): double;
end;

type
     TOscillator = class(TOscillatorBlep)
  private
    FXpos       : single;
    FPulseWidth : double;
    function PulseWidthAdjusted(FxPos:double): double;
    procedure SetPulseWidth(value:double);
  protected
    function ValueAt(FxPos:double): double;override;
  public
    property PulseWidth:double read FPulseWidth write SetPulseWidth;
    function Process:single;
    constructor Create(const SampleRate: double);override;
end;

type TMusicDspMoog = class
private
  FCutoff,FResonance, FSampleRate:single;
	stage,delay:array[0..3] of single;
	p, k, t1, t2:single;
  procedure SetSampleRate(value:single);
  procedure SetCutoff(cutoff:single;resonance:single);overload;
  procedure SetCutoff(cutoff:single);overload;
  procedure SetResonance(value:single);
  procedure Reset;
public
  property Cutoff: single  write SetCutoff;      // 0..20000
  function Process(input:single):single;
  property Resonance: single  write SetResonance; // 0..1
  property SampleRate: single write SetSampleRate;
  constructor Create(samplerate:single);
end;

type TSimpleSynth = class
private
  FOscillator:TOscillator;
  FFilter:TMusicDspMoog;
  FKey:integer;
public
  procedure UpdateParameter(id:integer;value:single);
  function Process:single;
  constructor Create(SampleRate: single);
  procedure onKeyEvent(pitch:integer;_on:boolean);
end;

implementation

uses Math;

{ TOscillator }

constructor TBaseOscillator.Create(const SampleRate: double);
begin
  FFrequency  := 1000;
  Randomize;
  Self.SampleRate := SampleRate;
end;

function TBaseOscillator.ValueAt(FxPos:double):double;
begin
  if FXPos<0.5 then result:=1 else result:=-1;
end;

procedure TBaseOscillator.SetFrequency(const Value: double);
begin
  FFrequency := Value;
end;

procedure TBaseOscillator.SetSampleRate(const Value: double);
begin
 if FSampleRate <> Value then
  begin
   FSampleRate := Value;
   if FSampleRate>0 then
     FSampleReci := 1 / FSampleRate;
  end;
end;

{ TOscillatorBlep }

// http://www.martin-finke.de/blog/articles/audio-plugins-018-polyblep-oscillator/

function TOscillatorBlep.ValueAt(FxPos:double): double;
function fmod(s:double): double;
begin
  result:=s-trunc(s);
end;
begin
  result:=inherited;
  result:=result + PolyBlep(FxPos);
  result:=result - PolyBlep(fmod(FxPos + 1-0.5));
end;

constructor TOscillator.Create(const SampleRate: double);
begin
  inherited;
  FPulseWidth:=0.5;
end;

function TOscillator.Process:single;
begin
  Fxpos:=Fxpos+ FSampleReci* FFrequency;
  if Fxpos>=1 then Fxpos:=Fxpos-1;
  result:=ValueAt(FxPos);
end;

function TOscillator.PulseWidthAdjusted(fxPos:double):double;
begin
  if fxPos<=fPulseWidth then
    result:=fxpos*0.5 / fPulseWidth
  else
    result:=0.5+ 0.5*(fxPos-fPulseWidth) / (1 - fPulseWidth);
end;

function TOscillator.ValueAt(FxPos: double): double;
begin
  result:=inherited ValueAt(PulseWidthAdjusted(FxPos));
end;

procedure TOscillator.SetPulseWidth(value: double);
begin
  if value<0.05 then value:=0.05;
  if value>0.95 then value:=0.95;
  FPulseWidth:=value;
end;

function TOscillatorBlep.PolyBlep(t:double):double;
VAR dt:double;
begin

    dt := FSampleReci* FFrequency;
    if dt=0 then begin result:=0; exit; end;

    // 0 <= t < 1
    if (t < dt) then
    begin
        t :=t / dt;
        result:= 2*t - t*t - 1.0;
    end
    // -1 < t < 0
    else if (t > 1.0 - dt) then
    begin
        t := (t - 1.0) / dt;
        result:= t*t + 2*t + 1.0;
    end
    // 0 otherwise
    else result:=0.0;
end;


(*********************************************************************************)

constructor TMusicDspMoog.Create(samplerate: single);
begin
  FSampleRate:=samplerate;
  FCutoff:=1000;
  Fresonance:=0;
  Reset;
end;

function TMusicDspMoog.Process(input:single):single;
VAR x:single;
begin
  x:=input;
  if x>1 then x:=1;
  if x<-1 then x:=-1;
  x := x - Fresonance * stage[3];
  // Four cascaded one-pole filters (bilinear transform)
  stage[0] := x * p + delay[0]  * p - k * stage[0];
  stage[1] := stage[0] * p + delay[1] * p - k * stage[1];
  stage[2] := stage[1] * p + delay[2] * p - k * stage[2];
  stage[3] := stage[2] * p + delay[3] * p - k * stage[3];

  // Clipping band-limited sigmoid
  stage[3] :=stage[3]- (stage[3] * stage[3] * stage[3]) / 6.0;

  delay[0] := x;
  delay[1] := stage[0];
  delay[2] := stage[1];
  delay[3] := stage[2];
  // result is in stage[3];
  result:=stage[3];
end;

procedure TMusicDspMoog.Reset;
VAR i:integer;
begin
  for i:=0 to 3 do
    begin
       stage[i]:=0;
       delay[i]:=0;
    end;
  p:=0;
  SetCutoff(FCutoff);
end;

procedure TMusicDspMoog.SetCutoff(cutoff,resonance: single);
begin
  if cutoff<=5 then exit; // raise Exception.Create('Negative Cutoff?');
  if cutoff>=20000 then cutoff:=20000; // raise Exception.Create('Negative Cutoff?');
  cutoff:=2.0 * cutoff / FsampleRate;
  if FCutoff<>cutoff then
  begin
   	Fcutoff := cutoff;
		p := Fcutoff * (1.8 - 0.8 * Fcutoff);
		k := 2.0 * sin(Fcutoff * pi * 0.5) - 1.0;
		t1 := (1.0 - p) * 1.386249;
		t2 := 12.0 + t1 * t1;
    if resonance>=0 then Fresonance:=resonance;
    SetResonance(Fresonance);
  end
  else if resonance>=0 then SetResonance(resonance);
end;

procedure TMusicDspMoog.SetCutoff(cutoff: single);
begin
  SetCutoff(cutoff,-1);
end;

procedure TMusicDspMoog.SetResonance(value: single);
begin
  if (value>0.99) then value := 0.99;
  Fresonance := value * (t2 + 6.0 * t1) / (t2 - 6.0 * t1);
end;

procedure TMusicDspMoog.SetSampleRate(value: single);
begin
  FSampleRate:=value;
  SetCutoff(Fcutoff,-1);
end;

{ TSimpleSynth }

constructor TSimpleSynth.Create(SampleRate: single);
begin
  FOscillator:=TOscillator.Create(samplerate);
  FFilter:=TMusicDspMoog.Create(Samplerate);
end;

procedure TSimpleSynth.onKeyEvent(pitch: integer; _on: boolean);
begin
  if _on then
  begin
    FKey:=pitch;
    FOscillator.Frequency:=8.18*Power(13289 / 8.18,pitch/128);
  end
  else
    FKey:=0;
end;

function TSimpleSynth.Process: single;
begin
  result:=0;
  if Fkey<>0 then
    result:=FFilter.Process(FOscillator.Process);
end;

const ID_CUTOFF = 17;
const ID_RESONANCE = 18;
const ID_PULSEWIDTH = 19;


procedure TSimpleSynth.UpdateParameter(id: integer; value: single);
begin
  case id of
    ID_CUTOFF:  FFilter.Cutoff:=200*Power(20000/200,value);
    ID_RESONANCE: FFilter.Resonance:=value;
    ID_PULSEWIDTH:FOscillator.PulseWidth:=value;
  end;
end;

end.
