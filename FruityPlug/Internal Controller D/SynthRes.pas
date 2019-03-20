unit SynthRes;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus;

type
  TSynthResModule = class(TDataModule)
    ControlMenu: TPopupMenu;
    mnuControlReset: TMenuItem;
    N1: TMenuItem;
    procedure ControlMenuPopup(Sender: TObject);
    procedure mnuControlResetClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ControlMenuClick(Sender: TObject);
  end;

var
  SynthResModule: TSynthResModule;


implementation

uses
    SynthForm, FP_PlugClass, ComCtrls;

{$R *.DFM}

procedure TSynthResModule.ControlMenuClick(Sender: TObject);
var
   ParamIndex: integer;
begin
  // this method will be called when the user clicks one of the menu items
  // managed by the host

  if (ControlMenu.PopupComponent <> nil) and (ControlMenu.PopupComponent.Owner <> nil) then
    with TSynthEditorForm(ControlMenu.PopupComponent.Owner) do
    begin
      ParamIndex := ControlMenu.PopupComponent.Tag;
      FruityPlug.PlugHost.Dispatcher(FruityPlug.HostTag, FHD_ParamMenu, ParamIndex, TMenuItem(Sender).Tag);
    end;
end;

procedure TSynthResModule.ControlMenuPopup(Sender: TObject);
var
   ParamIndex: integer;
begin
  // here we fill the popup menu with items managed by the host

  if (ControlMenu.PopupComponent <> nil) and (ControlMenu.PopupComponent.Owner <> nil) then
    with TSynthEditorForm(ControlMenu.PopupComponent.Owner) do
    begin
      ParamIndex := ControlMenu.PopupComponent.Tag;
      FruityPlug.AdjustParamPopup(ControlMenu.Items, ParamIndex, 2, ControlMenuClick);
    end;
end;

procedure TSynthResModule.mnuControlResetClick(Sender: TObject);
var
   ParamIndex: integer;
begin
  // here we reset the parameter to its default value

  if (ControlMenu.PopupComponent <> nil) and (ControlMenu.PopupComponent.Owner <> nil) then
    with TSynthEditorForm(ControlMenu.PopupComponent.Owner) do
    begin
      ParamIndex := ControlMenu.PopupComponent.Tag;

      // only one parameter, we set the value to half
      TTrackBar(ControlMenu.PopupComponent).Position := 500;
      FruityPlug.ProcessParam(ParamIndex, 500, REC_UpdateValue);
      FruityPlug.PlugHost.OnParamChanged(FruityPlug.HostTag, ParamIndex, 500);
    end;
end;

initialization
finalization
  // free the resource module when all instances of the plugin have been
  // destroyed
  SynthResModule.Free;
end.
