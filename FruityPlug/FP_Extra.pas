unit
    FP_Extra;

interface

// to handle 32Bit int & float
type
    T32Bit = record
      case boolean of
        true  :  (i: integer);
        false :  (s: single);
    end;



const
     // mixer sample rate
     MixSmpRate_Default=44100;

var
   NoteMul : single;


const
     // freq for middle C5
     MiddleCFreq = 523.251130601197;
     MiddleCMul  = $10000000 * MiddleCFreq * $10;


const
     MaxPath = 1024;


const
     Div2 = 0.5;
     Div4 = 0.25;
     Div8 = 0.125;
     Div10 = 0.1;
     Div100 = 0.01;
     Div128 = 1.0/128;
     Div256 = 1.0/256;
     Div1024 = 1.0/1024;


function MulShift16(a,b:Integer):Integer;
function Zeros(value,nZeros:Integer):AnsiString;
function MulDiv64(a,b,c:Integer):Integer;
function MinOf(a,b:Integer):Integer;
function MaxOf(a,b:Integer):Integer;

function TicksToSamples(time:Integer;RecSPP:Single):Integer;

// translate FL voice volume to linear velocity (0..1)
function VolumeToVelocity(Volume: single): single;
// translate FL voice volume to linear velocity (0..127)
function VolumeToMIDIVelocity(Volume: single): single;


implementation

uses
    SysUtils;

// mul & shift by 16
{$IFDEF CPUX64}
function  MulShift16(a,b:Integer):Integer;
asm
    MOV   EAX,ECX
    IMUL  EDX
    SHRD  EAX,EDX,16
end;
{$ELSE}
function  MulShift16(a,b:Integer):Integer;
asm
    IMUL  EDX
    SHRD  EAX,EDX,16
end;
{$ENDIF}


// IntToStr but align with zeros
function zeros(value,nZeros:Integer):AnsiString;
const n=1000000000;
begin
  zeros:=copy(IntToStr(n+value),11-nZeros,nZeros);
end;

// faster version of MulDiv (signed version)
{$IFDEF CPUX64}
function MulDiv64(a,b,c:Integer):Integer;
asm
    MOV   EAX,ECX
    IMUL  EDX
    IDIV  R8D
  end;
{$ELSE}
function MulDiv64(a,b,c:Integer):Integer;
asm
    IMUL  EDX
    IDIV  ECX
  end;
{$ENDIF}


// get the lower value
{$IFDEF CPUX64}
function MinOf(a,b:Integer):Integer;
asm
    MOV   EAX,ECX
    CMP   EAX,EDX
    CMOVG EAX,EDX
end;
{$ELSE}
function MinOf(a,b:Integer):Integer;
asm
    CMP   EAX,EDX
    CMOVG EAX,EDX
  end;
{$ENDIF}

// get the greater value
{$IFDEF CPUX64}
function MaxOf(a,b:Integer):Integer;
asm
    MOV   EAX,ECX
    CMP   EAX,EDX
    CMOVL EAX,EDX
  end;
{$ELSE}
function MaxOf(a,b:Integer):Integer;
asm
    CMP   EAX,EDX
    CMOVL EAX,EDX
  end;
{$ENDIF}

function InvLogVol(Value, MaxValue: single): single;
begin
  Result := Ln(Value+1)/Ln(MaxValue+1);
end;

function TicksToSamples(time:Integer;RecSPP:Single):Integer;
{$IFDEF CPUX64}
begin
  Result := Round(Time * RecSPP);
end;
{$ELSE}
asm
  PUSH  EAX
  FILD  DWORD PTR [ESP]
  FMUL  RecSPP
  FISTP DWORD PTR [ESP]
  POP   EAX
end;
{$ENDIF}

function VolumeToVelocity(Volume: single): single;
const
     MaxV : single = 261*10/127;
begin
  Result := InvLogVol(Volume*10, MaxV);
end;

function VolumeToMIDIVelocity(Volume: single): single;
const
     MaxV : single = 261*10/127;
begin
  Result := InvLogVol(Volume*10, MaxV) * 127;
end;

initialization
  NoteMul := Ln(2) / 1200;  // Ln(2) (for Power(2,n)) /12 (semitones per octave) /100 (cents)
end.
