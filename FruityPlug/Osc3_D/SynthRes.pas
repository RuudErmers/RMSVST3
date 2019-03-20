// resources shared by all the instances of the plugin interface

unit SynthRes;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ImgList;

type
  TSynthResModule = class(TDataModule)
    WheelMenu: TPopupMenu;
    ResetMenu: TMenuItem;
    N19: TMenuItem;
    EditEventsMenu: TMenuItem;
    EditEventsNewMenu: TMenuItem;
    InitEvents: TMenuItem;
    N23: TMenuItem;
    MIDIControlMenu: TMenuItem;
    procedure WheelMenuPopup(Sender: TObject);
    procedure ResetMenuClick(Sender: TObject);
    procedure EditEventsMenuClick(Sender: TObject);
  private
    { Private declarations }
  public
  end;

var
  SynthResModule: TSynthResModule;




implementation

{$R *.DFM}

uses SynthForm, FP_PlugClass, FP_DelphiPlug;

const ArtworkPath='Artwork\';



procedure TSynthResModule.WheelMenuPopup(Sender: TObject);
begin
with TPopupMenu(Sender) do
  Begin
  Items.Tag:=PopupComponent.Tag;
  TSynthEditorForm(PopupComponent.Owner).FruityPlug.AdjustParamPopup(Items,Items.Tag,2,EditEventsMenuClick);
  End;
end;


procedure TSynthResModule.ResetMenuClick(Sender: TObject);
begin
  { here you should reset the parameter's value } 
end;


procedure TSynthResModule.EditEventsMenuClick(Sender: TObject);
var   n:Integer;
      Comp:TComponent;
begin
with TMenuItem(Sender) do
  Begin
  n:=Tag;
  Comp:=TPopupMenu(TMenuItem(Sender).Parent.Owner).PopupComponent;
  with TSynthEditorForm(Comp.Owner) do
    FruityPlug.PlugHost.Dispatcher(FruityPlug.HostTag,FHD_ParamMenu,Comp.Tag,n);
  End;
End;


initialization
finalization
SynthResModule.Free;

end.
