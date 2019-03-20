unit UMyVSTForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,UMyVST,UPianoKeyboard;

type
  TonMyKeyEvent = procedure (key:integer;_on:boolean) of object;
  TFormMyVST = class(TForm)
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ScrollBar2: TScrollBar;
    ScrollBar3: TScrollBar;
    procedure ScrollBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    FScrollBars:array[0..2] of TScrollBar;
    Fkeyboard:TRMSKeyboard;
    procedure CBOnKeyEvent(Sender: TObject; key: integer; _on,
      infinite: boolean);
  public
    { Public declarations }
    { property } OnKeyEvent: TonMyKeyEvent;
    { property } UpdateHostParameter:TOnParameterChanged;
    procedure UpdateEditorParameter(index:integer;value: double);
    procedure SetPreset(prgm:integer);
    procedure SetKey(key:integer;_on:boolean);
  end;

var
  FormMyVST: TFormMyVST;

implementation

{$R *.dfm}

procedure TFormMyVST.FormCreate(Sender: TObject);
begin
  Fkeyboard:=TRMSKeyboard.Create(self);
  Fkeyboard.Parent:=self;
  Fkeyboard.Align:=alBottom;
  Fkeyboard.Height:=80;
  FScrollBars[0]:=ScrollBar1;
  FScrollBars[1]:=ScrollBar2;
  FScrollBars[2]:=ScrollBar3;
  Fkeyboard.OnKeyEvent:=CBOnKeyEvent;
end;

procedure TFormMyVST.ScrollBar1Change(Sender: TObject);
VAR isb:integer;
begin
  for isb:=0 to 2 do
  if Sender = FScrollBars[isb] then
    if assigned(UpdateHostParameter) then
    UpdateHostParameter(ID_CUTOFF+isb,FScrollBars[isb].Position / 100);
end;

procedure TFormMyVST.CBOnKeyEvent(Sender:TObject;key:integer;_on,infinite:boolean);
begin
  if assigned(OnKeyEvent) then
    OnKeyEvent(key,_on);
end;

procedure TFormMyVST.SetKey(key: integer; _on: boolean);
begin
  Fkeyboard.SetKeyPressed(key,_on);
end;

procedure TFormMyVST.SetPreset(prgm: integer);
begin
  Label2.Caption:='Preset:'+prgm.toString;
end;

procedure TFormMyVST.UpdateEditorParameter(index:integer;value: double);
VAR isb:integer;
begin
  for isb:=0 to 2 do
    if index = ID_CUTOFF+isb then
      FScrollBars[isb].Position:=round(100*value);
end;

end.
