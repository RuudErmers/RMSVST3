unit UVST3Base;

interface

uses Forms,Vst3Base,Generics.Collections;

type PSingle           = ^single;
     PPSingle          = ^PSingle;

const MIDICC_SIMULATION_START = 1024;
const MIDICC_SIMULATION_LAST  = 1024+128*16-1;  // = 3071

// I REFUSE to use the word Component, because
// 1. This is a 'reserved' word in many applications
// 2. On Page 1 of the VST3 docs there is a picture where the correct name is used: Processor
type  IProcessorHandler = IComponentHandler;

type
     TVST3Base = class;
     TVST3InstrumentClass = class of TVST3Base;
     TVST3PluginDef =  record
                              uid : TGUID;
                              cl  : TVST3InstrumentClass;
                              ecl :  TFormClass;
                              name:string;
                              isSynth:boolean;
                            end;
     TVST3FactoryDef =     record
                             vendor,url,email:string;
                           end;
     TVST3InstrumentInfo = record
                        PluginDef:TVST3PluginDef;
                        factoryDef:TVST3FactoryDef;
                      end;
     TVST3AutomationItem = record sampleOffset:integer;value:double end;
     TVST3AutomationQueue = class
                           private
                             Fid:integer;
                             FList:TList<TVST3AutomationItem>;
                             function get(index:integer):TVST3AutomationItem;
                           public
                             procedure Add(sampleOffset:integer;value:double);
                             constructor Create(id:integer);
                             destructor Destroy;
                             property id: integer read FId;
                             function last:double;
                             function count:integer;
                             property value[index:integer]:TVST3AutomationItem read get;default;
                           end;
    IVST3Base = interface
        function GetPluginInfo:TVST3InstrumentInfo;
        procedure OnCreate(pluginInfo:TVST3InstrumentInfo);
     end;
     TVST3Base = class(TInterfacedObject,IVST3Base)
        FPluginInfo:TVST3InstrumentInfo;
     public
        function GetPluginInfo:TVST3InstrumentInfo;
        procedure OnCreate(pluginInfo:TVST3InstrumentInfo); virtual;
        constructor Create; virtual;
     end;

procedure AssignStrToStr128(VAR target: TString128; source:string);

implementation



procedure AssignStrToStr128(VAR target: TString128; source:string);
VAR i:integer;
begin
  for i:=0 to length(source)-1 do
    target[i]:=source[i+1];
  target[length(source)]:=#0;
end;

constructor TVST3Base.Create;
begin

end;

function TVST3Base.GetPluginInfo: TVST3InstrumentInfo;
begin
  result:=FPluginInfo;
end;

procedure TVST3Base.OnCreate(pluginInfo: TVST3InstrumentInfo);
begin
  FPluginInfo:=pluginInfo;
end;

procedure TVST3AutomationQueue.Add(sampleOffset: integer; value: double);
VAR item:TVST3AutomationItem;
begin
  item.sampleOffset:=sampleOffset;
  item.value:=value;
  FList.Add(item);
end;

function TVST3AutomationQueue.count: integer;
begin
  result:=FList.Count;
end;

constructor TVST3AutomationQueue.Create(id: integer);
begin
  Fid:=id;
  Flist:=TList<TVST3AutomationItem>.Create;
end;

destructor TVST3AutomationQueue.Destroy;
begin
  Flist.Free;
end;

function TVST3AutomationQueue.get(index: integer): TVST3AutomationItem;
begin
  result:=Flist[index];
end;

function TVST3AutomationQueue.last: double;
begin
  if FList.Count>0 then result:=FList[FList.Count-1].value else result:=0;
end;



end.
