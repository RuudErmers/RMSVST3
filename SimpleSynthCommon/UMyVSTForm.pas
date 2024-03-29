unit UMyVSTForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,UMyVST,UPianoKeyboard;

type
  THostKeyEvent = procedure (key:integer;_on:boolean) of object;
  THostUpdateParameter = procedure (id:integer;value:double) of object;
  THostPrgmChange= procedure(prgm:integer) of object;

  TFormMyVST = class(TForm)
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    ScrollBar2: TScrollBar;
    ScrollBar3: TScrollBar;
    Button1: TButton;
    procedure ScrollBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FScrollBars:array[0..2] of TScrollBar;
    Fkeyboard:TRMCKeyboard;
    procedure CBOnKeyEvent(Sender: TObject; key: integer; _on, infinite: boolean);
  public
    { Public declarations }
    { property } HostKeyEvent: THostKeyEvent;
    { property } HostUpdateParameter:THostUpdateParameter;
    { property } HostPrgmChange:THostPrgmChange;
    procedure UpdateEditorParameter(index:integer;value: double);
    procedure SetProgram(prgm:integer);
    procedure SetKey(key:integer;_on:boolean);
  end;

var
  FormMyVST: TFormMyVST;

implementation

{$R *.dfm}

procedure TFormMyVST.FormCreate(Sender: TObject);
begin
  Fkeyboard:=TRMCKeyboard.Create(self);
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
    if assigned(HostUpdateParameter) then
    HostUpdateParameter(ID_CUTOFF+isb,FScrollBars[isb].Position / 100);
end;

procedure TFormMyVST.Button1Click(Sender: TObject);
begin
  if assigned(HostPrgmChange) then
    HostPrgmChange(1);
end;

procedure TFormMyVST.CBOnKeyEvent(Sender:TObject;key:integer;_on,infinite:boolean);
begin
  if assigned(HostKeyEvent) then
    HostKeyEvent(key,_on);
end;

procedure TFormMyVST.SetKey(key: integer; _on: boolean);
begin
  Fkeyboard.SetKeyPressed(key,_on);
end;

procedure TFormMyVST.SetProgram(prgm: integer);
begin
  Label2.Caption:='Program:'+prgm.toString;
end;

procedure TFormMyVST.UpdateEditorParameter(index:integer;value: double);
VAR isb:integer;
begin
  for isb:=0 to 2 do
    if index = ID_CUTOFF+isb then
      FScrollBars[isb].Position:=round(100*value);
end;

end.
