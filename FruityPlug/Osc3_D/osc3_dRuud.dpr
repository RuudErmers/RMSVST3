library osc3_dRuud;

{$ifdef CPUX64}
  {$LIBSUFFIX '_x64'}
  {$EXCESSPRECISION OFF}
{$endif}

uses
  SysUtils,
  Classes,
  TestPlug in 'TestPlug.pas',
  SynthRes in 'SynthRes.pas' {SynthResModule: TDataModule},
  SynthForm in 'SynthForm.pas' {SynthEditorForm},
  FP_PlugClass in '..\FP_PlugClass.pas',
  FP_DelphiPlug in '..\FP_DelphiPlug.pas',
  FP_Extra in '..\FP_Extra.pas',
  FP_Def in '..\FP_Def.pas',
  GenericTransport in '..\GenericTransport.pas';

{$R *.RES}

exports
       CreatePlugInstance;

begin
end.
