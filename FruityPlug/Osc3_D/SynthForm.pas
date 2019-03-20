// the plugin interface

unit SynthForm;

interface

uses
  Windows, Messages, SysUtils, Graphics, Classes, Controls, Forms,
  FP_PlugClass, FP_DelphiPlug, ComCtrls, StdCtrls, ExtCtrls,
  TestPlug, SynthRes;



type
  TSynthEditorForm = class(TForm)
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label1: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    TrackBar2: TTrackBar;
    TrackBar3: TTrackBar;
    TrackBar7: TTrackBar;
    TrackBar4: TTrackBar;
    TrackBar5: TTrackBar;
    TrackBar6: TTrackBar;
    TrackBar8: TTrackBar;
    TrackBar12: TTrackBar;
    TrackBar11: TTrackBar;
    TrackBar10: TTrackBar;
    TrackBar9: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure CutoffWheelChange(Sender: TObject);

  private
    { Private declarations }

  public
    { Public declarations }
    FruityPlug:TDelphiFruityPlug;
    ParamCtrl:Array[0..NumParamsConst-1] of TControl;

  end;




implementation

{$R *.DFM}




procedure TSynthEditorForm.FormCreate(Sender: TObject);
var   n:Integer;
      Component:TComponent;
begin
if not Assigned(SynthResModule) then SynthResModule:=TSynthResModule.Create(Nil);

  // controls
  for n:=0 to ComponentCount-1 do
    Begin
    Component:=Components[n];
    if (Component.Tag>=0) and (Component is TTrackBar) then
       ParamCtrl[Component.Tag]:=TTrackBar(Component);
    End;
end;


procedure TSynthEditorForm.CutoffWheelChange(Sender: TObject);
var
   Track: TTrackBar;
begin
  Track := TTrackBar(Sender);
  with FruityPlug do
  Begin
  ProcessParam(Track.Tag,Track.Position,REC_UpdateValue or REC_ShowHint);
  PlugHost.OnParamChanged(FruityPlug.HostTag,Track.Tag,Track.Position);
  End;
end;



end.





