{$J-,H+,T-P+,X+,B-,V-,O+,A+,W-,U-,R-,I-,Q-,D-,L-,Y-,C-}
library RMSMyVST2;

uses
  UMyVSTForm in '..\SimpleSynthCommon\UMyVSTForm.pas' {FormMyVST},
  UVSTInstrument in 'UVSTInstrument.pas',
  UMyVst in '..\SimpleSynthCommon\UMyVst.pas',
  UVSTBase in '..\FrameworkCommon\UVSTBase.pas',
  UCPluginFactory in 'UCPluginFactory.pas',
  UCDataLayer in '..\FrameworkCommon\UCDataLayer.pas',
  UMyVstDSP in '..\SimpleSynthCommon\UMyVstDSP.pas',
  UPianoKeyboard in '..\SimpleSynthCommon\UPianoKeyboard.pas',
  DAVVstEffect in 'DAVVstEffect.pas';

function VstPluginMain(AudioMasterCallback: TAudioMasterCallbackFunc): PVSTEffect; cdecl; export;
begin
  Result := CreatePlugin(AudioMasterCallback, GetVSTInstrumentInfo);
end;

exports
  VstPluginMain name 'main',
  VstPluginMain name 'VSTPluginMain';

begin
end.

