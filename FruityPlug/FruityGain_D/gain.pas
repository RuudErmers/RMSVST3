unit
    Gain;

interface

uses
    FP_Def, FP_Extra, FP_PlugClass, FP_DelphiPlug, ActiveX, Forms, Editor;


const
     // the number of parameters
     NumParams   = 2;

     // the parameter indexes
     prmGainLeft  = 0;
     prmGainRight = 1;

     // minimum and maximum values of the gain parameters
     GainMinimum = 0;
     GainMaximum = 20;

     
// the information structure describing this plugin to the host
var
   PlugInfo:TFruityPlugInfo=(
     SDKVersion  : CurrentSDKVersion;
     LongName    : 'FruityGain_D';
     ShortName   : 'F.Gain D';
     Flags       : FPF_Type_Effect;
     NumParams   : NumParams;
     DefPoly     : 0  // infinite
     );

     

type
    TFruityGain = class (TDelphiFruityPlug)
    public
      GainLeftInt  : integer;
      GainRightInt : integer;
      GainLeft     : single;
      GainRight    : single;

      constructor Create(Tag: integer; Host: TFruityPlugHost);
      
      function    Dispatcher(ID,Index,Value:IntPtr):IntPtr; override;
      procedure   SaveRestoreState(const Stream:IStream; Save:LongBool); override;

      // names (see FPN_Param) (Name must be at least 256 chars long)
      procedure   GetName(Section,Index,Value:Integer;Name:PAnsiChar); override;

      // events
      function    ProcessParam(Index,Value,RECFlags:Integer):Integer; override;

      // effect processing (source & dest can be the same)
      procedure   Eff_Render(SourceBuffer,DestBuffer:PWAV32FS;Length:Integer); override;

      // specific to this plugin
      procedure GainIntToSingle;
      procedure ResetParams;
    end;


function CreatePlugInstance(Host:TFruityPlugHost;Tag:Integer):TFruityPlug; stdcall;



implementation

uses
    SysUtils, Controls, Windows;


function CreatePlugInstance(Host:TFruityPlugHost;Tag:Integer):TFruityPlug;
begin
  Result := TFruityGain.Create(Tag, Host);
end;


{ TFruityGain }

constructor TFruityGain.Create(Tag: integer; Host: TFruityPlugHost);
begin
  inherited Create(Tag, Host);

  Info := @PlugInfo;
  HostTag := Tag;

  EditorForm := TEditorForm.Create(nil);
  with TEditorForm(EditorForm) do
  begin
    Plugin := Self;
    LeftGainTrack.Min := GainMinimum;
    LeftGainTrack.Max := GainMaximum;
    RightGainTrack.Min := GainMinimum;
    RightGainTrack.Max := GainMaximum;
  end;

  ResetParams;
end;

function TFruityGain.Dispatcher(ID,Index,Value:IntPtr):IntPtr;
begin
  Result := 0;

  case ID of

    // show the editor
    FPD_ShowEditor:
      begin
        if Value = 0 then
        begin
          EditorForm.Hide;
          EditorForm.ParentWindow := 0;
        end
        else
        begin
          EditorForm.ParentWindow := Value;
          EditorForm.Show;
        end;
        EditorHandle := EditorForm.Handle;
      end;
    end;
end;

procedure TFruityGain.Eff_Render(SourceBuffer, DestBuffer: PWAV32FS;
  Length: Integer);
var
   left, right : single;
   i           : integer;
begin
  left := GainLeft;
  right := GainRight;

  for i := 0 to Length-1 do
  begin
    DestBuffer^[i, 0] := SourceBuffer^[i, 0] * left;
    DestBuffer^[i, 1] := SourceBuffer^[i, 1] * right;
  end;
end;

procedure TFruityGain.GainIntToSingle;
begin
  {$IFDEF UseCriticalSection}
  // for safety when we update the actual value, we lock the mixing thread
  Lock;
  try
  {$ENDIF}
    GainLeft := (GainLeftInt / 4) + 1;
    GainRight := (GainRightInt / 4) + 1;
  {$IFDEF UseCriticalSection}
  finally
    Unlock;  // and unlock it again when we're through (very important !)
  end;
  {$ENDIF}
end;

procedure TFruityGain.GetName(Section, Index, Value: Integer; Name: PAnsiChar);
var
   tempsingle : single;
begin
  case Section of
    FPN_Param :
      begin
        case Index of
          prmGainLeft  :  StrPCopy(Name, 'Left Gain');
          prmGainRight :  StrPCopy(Name, 'Right Gain');
        end;
      end;

    FPN_ParamValue :
      begin
        tempsingle := (Value / 4) + 1;
        StrPCopy(Name, Format('%.2fx', [tempsingle]));
      end;
  end;
end;

function TFruityGain.ProcessParam(Index, Value, RECFlags: Integer): Integer;
begin
  if Index < NumParams then with TEditorForm(EditorForm) do
  begin
    if RECFlags and REC_FromMIDI <> 0 then
      Value := TranslateMidi(Value, GainMinimum, GainMaximum);

    if RECFlags and REC_UpdateValue <> 0 then
    begin
      case Index of
        prmGainLeft  :  GainLeftInt := Value;
        prmGainRight :  GainRightInt := Value;
      end;
      GainIntToSingle;
    end

    else if RECFlags and REC_GetValue <> 0 then
      case Index of
        prmGainLeft  :  Value := GainLeftInt;
        prmGainRight :  Value := GainRightInt;
      end;

     if RECFlags and REC_UpdateControl <> 0 then
       ParamsToControls;
  end;

  Result := Value;
end;

procedure TFruityGain.ResetParams;
begin
  // start with a gain of 1.5 of both channels
  GainLeftInt := 2;
  GainRightInt := 2;
  GainIntToSingle;  // translate the int gain to floating point value

  TEditorForm(EditorForm).ParamsToControls;
end;

procedure TFruityGain.SaveRestoreState(const Stream: IStream;
  Save: LongBool);
var
   templong : longint;
   written  : longint;
   read     : longint;
begin
  if Save then
  begin
    templong := GainLeftInt;
    Stream.Write(@templong, sizeof(longint), @written);
    templong := GainRightInt;
    Stream.Write(@templong, sizeof(longint), @written);
  end
  else
  begin
    Stream.Read(@templong, sizeof(longint), @read);
    GainLeftInt := templong;
    Stream.Read(@templong, sizeof(longint), @read);
    GainRightInt := templong;
    
    GainIntToSingle;
    ProcessAllParams;
  end;
end;


end.
