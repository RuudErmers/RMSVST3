{$J-,H+,T-P+,X+,B-,V-,O+,A+,W-,U-,R-,I-,Q-,D-,L-,Y-,C-}
library RMSMyVST;

{$E vst3}

uses
  UCPluginFactory in '..\UCPluginFactory.pas',
  Vst3Base in '..\Vst3Base.pas',
  UUIDHelper in '..\UUIDHelper.pas',
  UCEditController in '..\UCEditController.pas',
  UCAudioProcessor in '..\UCAudioProcessor.pas',
  UCComponent in '..\UCComponent.pas',
  UCPlugView in '..\UCPlugView.pas',
  UMyVSTForm in 'UMyVSTForm.pas' {FormMyVST},
  UMyVst in 'UMyVst.pas',
  UCMidiMapping in '..\UCMidiMapping.pas',
  UVST3Instrument in '..\UVST3Instrument.pas',
  UCUnitInfo in '..\UCUnitInfo.pas',
  UCDataLayer in '..\UCDataLayer.pas',
  UVST3Processor in '..\UVST3Processor.pas',
  UVST3Controller in '..\UVST3Controller.pas',
  UVST3Base in '..\UVST3Base.pas';

function InitDLL:boolean; cdecl; export;
begin
 Result := true;
end;

function ExitDLL:boolean; cdecl; export;
begin
 Result := true;
end;

function GetPluginFactory: pointer;stdcall; export;
begin
  result:=CreatePlugin(GetVST3InstrumentInfo);
end;


exports
  InitDLL name 'InitDLL',
  ExitDLL name 'ExitDLL',
  GetPluginFactory name 'GetPluginFactory';

begin
end.

