library FruityPlug;

{$ifdef CPUX64}
  {$LIBSUFFIX '_x64'}
  {$EXCESSPRECISION OFF}
{$endif}

uses
  SysUtils,
  Classes,
  TestPlug in 'TestPlug.pas',
  FP_PlugClass in '..\FP_PlugClass.pas',
  FP_DelphiPlug in '..\FP_DelphiPlug.pas',
  FP_Extra in '..\FP_Extra.pas',
  FP_Def in '..\FP_Def.pas',
  SynthForm in 'SynthForm.pas' {SynthEditorForm},
  GenericTransport in '..\GenericTransport.pas';

{$R *.RES}


exports
       CreatePlugInstance;

begin
end.
