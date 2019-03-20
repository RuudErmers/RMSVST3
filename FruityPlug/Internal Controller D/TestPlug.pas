unit TestPlug;

interface

uses
    Windows, ActiveX, FP_PlugClass, FP_DelphiPlug, FP_Def, FP_Extra;


const
     NumParamsConst = 1;    // the amount of parameters
     StateSizeConst = NumParamsConst * SizeOf(integer);  // the size of all parameters together


var   PlugInfo:TFruityPlugInfo=(
          SDKVersion  : CurrentSDKVersion;
          LongName    : 'Internal Controller';
          ShortName   : 'IC';
          Flags       : FPF_Type_Effect or FPF_Type_Visual;   // FPF_Type_Visual means we don't process any sound
          NumParams   : NumParamsConst;
          DefPoly     : 0;
          NumOutCtrls : 1               // we have one internal controller
                               );


type
    TTestPlug = class(TDelphiFruityPlug)
    public
      ParamValue : array[0..NumParamsConst-1] of integer;

      constructor Create(Tag: integer; Host: TFruityPlugHost);

      function    Dispatcher(ID,Index,Value:IntPtr):IntPtr; override;
      procedure   Idle; override;
      procedure   SaveRestoreState(const Stream:IStream; Save:LongBool); override;
      procedure   GetName(Section,Index,Value:Integer;Name:PAnsiChar); override;
      function    ProcessParam(ThisIndex,ThisValue,RECFlags:Integer):Integer; override;
      procedure   Eff_Render(SourceBuffer,DestBuffer:PWAV32FS;Length:Integer); override;
    end;


function CreatePlugInstance(Host:TFruityPlugHost;Tag:TPluginTag): TFruityPlug; stdcall;



implementation

uses
    SysUtils, Controls, SynthForm, ComCtrls, SynthRes;

function CreatePlugInstance(Host:TFruityPlugHost;Tag:TPluginTag): TFruityPlug;
begin
  Result := TTestPlug.Create(Tag, Host); // create the plugin
end;


{ TTestPlug }

constructor TTestPlug.Create(Tag: integer; Host: TFruityPlugHost);
var
   i: integer;
begin
  inherited Create(Tag, Host);

  Info := @PlugInfo;

  // create the resource module
  // but only if it hasn't been created by a previous instance
  if SynthResModule = nil then
    SynthResModule := TSynthResModule.Create(nil); 

  // create the editor form
  EditorForm := TSynthEditorForm.Create(nil);

  with TSynthEditorForm(EditorForm) do
  begin
    FruityPlug := Self;

    // set the parameters to their default values
    // (read from the initial values of the controls)
    for i := 0 to NumParamsConst-1 do
      ParamValue[i] := TTrackBar(ParamCtrl[i]).Position;
  end;
end;

function TTestPlug.Dispatcher(ID, Index, Value: IntPtr): IntPtr;
begin
  Result := 0;

  case ID of
    // show or hide the editor
    FPD_ShowEditor:
      begin
        if Value = 0 then    // hide
        begin
          EditorForm.Hide;
          EditorForm.ParentWindow := 0;
        end
        else                 // show
        begin
          EditorForm.ParentWindow := Value;
          EditorForm.Show;
        end;
        
        EditorHandle := EditorForm.Handle;
      end;
    end;
end;

procedure TTestPlug.Eff_Render(SourceBuffer, DestBuffer: PWAV32FS; Length: Integer);
begin
  // we don't process any sound (see FPF_Type_Visual)
  // so Eff_Render will normally not get called
end;

procedure TTestPlug.GetName(Section, Index, Value: Integer; Name: PAnsiChar);
begin
  StrPCopy(Name, '');

  case Section of
    // for the parameter names, we look at the (long) hint of the parameter control
    FPN_Param :  StrPCopy(Name, GetLongHint(TSynthEditorForm(EditorForm).ParamCtrl[Index].Hint));

    // the name of our only internal controller
    FPN_OutCtrl :  if Index = 0 then
                     StrCopy(Name, 'Example controller');
  end;
end;

procedure TTestPlug.Idle;
begin
  inherited;

  // do any idle processing you want here
  // but don't forget to call inherited
end;

function TTestPlug.ProcessParam(ThisIndex, ThisValue, RECFlags: Integer): Integer;
begin
  with TSynthEditorForm(EditorForm), TTrackBar(ParamCtrl[ThisIndex]) do
  begin
    // translate from 0..65536 to the parameter's range
    if (RECFlags and REC_FromMIDI <> 0) then
      ThisValue := TranslateMidi(ThisValue, Min, Max);

    // update the value in the ParamValue array
    if (RECFlags and REC_UpdateValue <> 0) then
    begin
      ParamValue[ThisIndex] := ThisValue;

      // if the parameter value has changed,
      // then we notify the host that the controller has changed
      // (!) beware of messages that are sent by (other ?) internal controllers
      // (!) convert the value from its own range to 0..65536
      if not (RECFlags and REC_InternalCtrl <> 0) then
        PlugHost.OnControllerChanged(HostTag, ThisIndex, Round((ThisValue-Min)/(Max-Min+1) * 65536));
    end
    // retrieve the value from the ParamValue array
    else if (RECFlags and REC_GetValue <> 0) then
      ThisValue := ParamValue[ThisIndex];

    // update the parameter control's value
    if (RECFlags and REC_UpdateControl <> 0) then
    begin
      IsAutomated := TRUE;     // to make sure we don't get another call to this function
      Position := ThisValue;
      IsAutomated := FALSE;
    end;

    // we show the parameter value as a hint
    if (RECFlags and REC_ShowHint <> 0) then
      ShowHintMsg_Percent(ThisValue-Min, Max-Min+1);
  end;

  // make sure we return the value
  Result := ThisValue;
end;

procedure TTestPlug.SaveRestoreState(const Stream: IStream; Save: LongBool);
begin
  if Save then
    Stream.Write(@ParamValue, StateSizeConst, nil)
  else
  begin
    Stream.Read(@ParamValue, StateSizeConst, nil);
    ProcessAllParams;
  end;
end;

end.
