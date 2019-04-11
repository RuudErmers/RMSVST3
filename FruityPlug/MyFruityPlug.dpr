library MyFruityPlug;

{$ifdef CPUX64}
  {$LIBSUFFIX '_x64'}
  {$EXCESSPRECISION OFF}
{$endif}

uses
  SysUtils,
  Classes,
  UVSTInstrument in 'UVSTInstrument.pas',
  FP_PlugClass in 'FP_PlugClass.pas',
  FP_DelphiPlug in 'FP_DelphiPlug.pas',
  FP_Extra in 'FP_Extra.pas',
  FP_Def in 'FP_Def.pas',
  GenericTransport in 'GenericTransport.pas',
  UMyVst in '..\SimpleSynthCommon\UMyVst.pas',
  UVSTBase in '..\FrameworkCommon\UVSTBase.pas',
  UMyVSTForm in '..\SimpleSynthCommon\UMyVSTForm.pas' {FormMyVST},
  UPianoKeyboard in '..\SimpleSynthCommon\UPianoKeyboard.pas',
  UMyVstDSP in '..\SimpleSynthCommon\UMyVstDSP.pas',
  UCodeSiteLogger in '..\FrameworkCommon\UCodeSiteLogger.pas';

{$R *.RES}

function CreatePlugInstance(Host:TFruityPlugHost;Tag:TPluginTag): TFruityPlug; stdcall;
begin
  result:=CreatePlugin(Host,Tag,GetVSTInstrumentInfo);
end;

exports
  CreatePlugInstance;

begin
end.
