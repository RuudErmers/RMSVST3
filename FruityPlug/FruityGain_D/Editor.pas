unit Editor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls, StdCtrls, FP_PlugClass, Menus, FP_DelphiPlug;

type
  TEditorForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    LeftGainTrack: TTrackBar;
    RightGainTrack: TTrackBar;
    Popup: TPopupMenu;
    mnuReset: TMenuItem;
    mnuBreak1: TMenuItem;
    mnuEditEvents: TMenuItem;
    mnuEditEventsInNewWindow: TMenuItem;
    mnuEditEventsWithThisPosition: TMenuItem;
    mnuBreak2: TMenuItem;
    mnuLinkToMidiController: TMenuItem;
    procedure GainTrackChange(Sender: TObject);
    procedure PopupClick(Sender: TObject);
    procedure mnuResetClick(Sender: TObject);
    procedure PopupPopup(Sender: TObject);
  private
    { Private declarations }
  public
    Plugin: TDelphiFruityPlug;
    procedure ControlsToParams(left: boolean);
    procedure ParamsToControls;
  end;



implementation

uses
    Gain;

{$R *.DFM}

{ TEditorForm }

procedure TEditorForm.ControlsToParams(left: boolean);
begin
  with TFruityGain(Plugin) do
  begin
    if left then
    begin
      GainLeftInt := LeftGainTrack.Position;
      PlugHost.OnParamChanged(HostTag, prmGainLeft, GainLeftInt);
    end
    else
    begin
      GainRightInt := RightGainTrack.Position;
      PlugHost.OnParamChanged(HostTag, prmGainRight, GainRightInt);
    end;
    GainIntToSingle;
  end;
end;

procedure TEditorForm.ParamsToControls;
begin
  with TFruityGain(Plugin) do
  begin
    LeftGainTrack.Position := GainLeftInt;
    RightGainTrack.Position := GainRightInt;
  end;
end;

procedure TEditorForm.GainTrackChange(Sender: TObject);
var
   C: TControl;
   s: AnsiString;
begin
  C := TControl(Sender);
  ControlsToParams(C.Tag = 0);

  with TFruityGain(Plugin) do
  begin
    if C.Tag = 0 then
      s := Format('%.2fx', [GainLeft])
    else
      s := Format('%.2fx', [GainRight]);

    ShowHintMsg(PAnsiChar(s));
  end;
end;

procedure TEditorForm.PopupClick(Sender: TObject);
var
   Comp : TComponent;
   Menu : TMenuItem;
begin
  Menu := TMenuItem(Sender);
  Comp := TPopupMenu(Menu.Parent.Owner).PopupComponent;

  Plugin.PlugHost.Dispatcher(Plugin.HostTag, FHD_ParamMenu, Comp.Tag, Menu.Tag);
end;

procedure TEditorForm.mnuResetClick(Sender: TObject);
begin
  TFruityGain(Plugin).ResetParams;
end;

procedure TEditorForm.PopupPopup(Sender: TObject);
begin
  TDelphiFruityPlug(Plugin).AdjustParamPopup(Popup.Items, Popup.PopupComponent.Tag, 2, PopupClick);
end;

end.
