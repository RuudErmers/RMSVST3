unit UMyVSTForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,UMyVST;

type
  TSBChange = procedure (Value:double) of object;
  TFormMyVST = class(TForm)
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    procedure ScrollBar1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    { property } UpdateHostParameter:TOnParameterChanged;
    procedure UpdateEditorParameter(index:integer;value: double);
    procedure SetPreset(prgm:integer);
  end;

var
  FormMyVST: TFormMyVST;

implementation

{$R *.dfm}

const ID_GAIN = 17;

procedure TFormMyVST.ScrollBar1Change(Sender: TObject);
begin
  if assigned(UpdateHostParameter) then
    UpdateHostParameter(ID_GAIN,ScrollBar1.Position / 100);
end;

procedure TFormMyVST.SetPreset(prgm: integer);
begin
  Label2.Caption:='Preset:'+prgm.toString;
end;

procedure TFormMyVST.UpdateEditorParameter(index:integer;value: double);
begin
  if index=ID_GAIN then
    ScrollBar1.Position:=round(100*value);
end;

end.
