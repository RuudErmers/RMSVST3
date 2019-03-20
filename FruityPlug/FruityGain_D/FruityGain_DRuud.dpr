library FruityGain_DRuud;

{$ifdef CPUX64}
  {$LIBSUFFIX '_x64'}
  {$EXCESSPRECISION OFF}
{$endif}

uses
  SysUtils,
  Classes,
  gain in 'gain.pas',
  Editor in 'Editor.pas' {EditorForm},
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
