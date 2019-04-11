unit UVSTInstrument;

interface

uses Vst3Base,Forms,Generics.Collections,UCDataLayer,UVST3Processor,UVST3Controller;

type

// For state flow see VST 3 API Documentation :: Communication between the components
// On Load, Reaper calls CComponent::SetState, CEditController::SetComponentState and CEditController::SetState
// After that it calls CComponent::GetState and CEditController::GetState
// Since the model is the same for Component and Controller, I will NOT honor requests for SetState/GetState from the Component.
// However, when SetState called for CEditController.SetState all parameters will be send to the Host, which passes this to the Component
// The advantage of this is that the EditController can do the preset management
// This works with Reaper
// If you want this different, be my guest :}


   TVST3Instrument = class(TVST3Controller,IComponent,IAudioProcessor,IEditController,IMidiMapping,IUnitInfo)
protected
  FAudioProcessor:IAudioProcessor;
  FComponent:IComponent;
  FEditController:IEditController;
  FMidiMapping:IMidiMapping;
  FUnitInfo: IUnitInfo;
  property AudioProcessor: IAudioProcessor read FAudioProcessor implements IAudioProcessor;
  property Component: IComponent read FComponent implements IComponent;
  property EditController: IEditController read FEditController implements IEditController;
  property MidiMapping:IMidiMapping read FMidiMapping implements IMidiMapping;
  property UnitInfo:IUnitInfo read FUnitInfo implements IUnitInfo;
public
  constructor Create; override;
end;

type TVSTInstrument = TVST3Instrument;  // don't expand this type with own methods, but inherit!


implementation

uses UCAudioProcessor,UCComponent,UCEditController,UCMidiMapping,UCUnitInfo,UCodeSiteLogger;

constructor TVST3Instrument.Create;
begin
  WriteLog('TVST3Instrument.Create');

  inherited;
  FAudioProcessor:=CAudioProcessor.Create(self);
  FComponent:=CComponent.Create(self);
  FEditController:=CEditController.Create(self);
  FMidiMapping:=CMidiMapping.Create(self);
  FUnitInfo:=CUnitInfo.Create(self);
end;


end.
