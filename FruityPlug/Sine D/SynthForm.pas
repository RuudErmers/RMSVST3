unit SynthForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, TestPlug;

type
  TSynthEditorForm = class(TForm)
    VolumeBar: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure VolumeBarChange(Sender: TObject);
  private
    { Private declarations }
  public
    FruityPlug : TTestPlug;
    ParamCtrl  : array[0..NumParamsConst-1] of TControl;
  end;

var
  SynthEditorForm: TSynthEditorForm;

implementation

uses
    FP_PlugClass;

{$R *.DFM}

procedure TSynthEditorForm.FormCreate(Sender: TObject);
var
   i: integer;
begin
  // fill the ParamCtrl array
  for i := 0 to ControlCount-1 do
    if Controls[i].Tag >= 0 then
      ParamCtrl[i] := Controls[i];
end;

procedure TSynthEditorForm.VolumeBarChange(Sender: TObject);
begin
  with FruityPlug, TTrackBar(Sender) do
  begin
    ProcessParam(Tag, Position, REC_UpdateValue or REC_ShowHint);
    PlugHost.OnParamChanged(HostTag, Tag, Position);
  end;
end;

end.
