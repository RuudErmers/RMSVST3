unit UVSTBase;

interface

uses Forms,  Generics.Collections;

type PSingle           = ^single;
     PPSingle          = ^PSingle;
     PDouble           = ^double;
     PPDouble          = ^PDouble;
const MIDICC_SIMULATION_START = 1024;
const MIDICC_SIMULATION_LAST  = 1024+128*16-1;  // = 3071

type
     TVSTBase = class;
     TVSTInstrumentClass = class of TVSTBase;
     TVSTPluginDef =  record
                              vst3id:TGUID;
                              vst2id:string; // must be 4 characters;
                              cl  : TVSTInstrumentClass;
                              ecl :  TFormClass;
                              name:string;
                              isSynth,softMidiThru:boolean;
                            end;
     TVSTFactoryDef =     record
                             vendor,url,email:string;
                           end;
     TVSTInstrumentInfo = record
                        PluginDef:TVSTPluginDef;
                        factoryDef:TVSTFactoryDef;
                      end;
    IVSTBase = interface
        function GetPluginInfo:TVSTInstrumentInfo;
        procedure OnCreate(pluginInfo:TVSTInstrumentInfo);
     end;
     TVSTBase = class(TInterfacedObject,IVSTBase)
     private
        FPluginInfo:TVSTInstrumentInfo;
     public
        function GetPluginInfo:TVSTInstrumentInfo;
        procedure OnCreate(pluginInfo:TVSTInstrumentInfo); virtual;
        constructor Create; virtual;
     end;

implementation

constructor TVSTBase.Create;
begin

end;

function TVSTBase.GetPluginInfo: TVSTInstrumentInfo;
begin
  result:=FPluginInfo;
end;

procedure TVSTBase.OnCreate(pluginInfo: TVSTInstrumentInfo);
begin
  FPluginInfo:=pluginInfo;
end;


end.
