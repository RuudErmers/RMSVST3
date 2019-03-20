unit SynthForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  TestPlug, ComCtrls, StdCtrls;

type
  TSynthEditorForm = class(TForm)
    ControllerBar: TTrackBar;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure ControllerBarChange(Sender: TObject);
  private
    { Private declarations }
  public
    FruityPlug  : TTestPlug;
    ParamCtrl   : array[0..NumParamsConst-1] of TControl;
    IsAutomated : boolean;
  end;

var
  SynthEditorForm: TSynthEditorForm;


implementation

uses
    FP_PlugClass, SynthRes;

{$R *.DFM}

procedure TSynthEditorForm.FormCreate(Sender: TObject);
var
   i: integer;
begin
  // get all the parameter controls into the ParamCtrl array
  // we look at the Tag property for this
  for i := 0 to ControlCount-1 do
  begin
    if (Controls[i].Tag >= 0) and (Controls[i].Tag < NumParamsConst) then
      ParamCtrl[Controls[i].Tag] := Controls[i];
  end;

  IsAutomated := FALSE;
end;

procedure TSynthEditorForm.ControllerBarChange(Sender: TObject);
begin
  // to avoid feedback when ProcessParam was called from the host
  if IsAutomated then
    Exit;

  with FruityPlug, TTrackBar(Sender) do
  begin
    // here we do two things:
    //   set the value of the parameter and show a hint by calling ProcessParam
    //   let the host know the parameter has changed by calling OnParamChanged
    ProcessParam(Tag, Position, REC_UpdateValue or REC_ShowHint);
    PlugHost.OnParamChanged(HostTag, Tag, Position);
  end;
end;

end.
