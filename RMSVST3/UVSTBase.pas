unit UVSTBase;

interface

uses Forms,  Generics.Collections;

type PSingle           = ^single;
     PPSingle          = ^PSingle;

const MIDICC_SIMULATION_START = 1024;
const MIDICC_SIMULATION_LAST  = 1024+128*16-1;  // = 3071

type
     TVSTBase = class;
     TVSTInstrumentClass = class of TVSTBase;
     TVSTPluginDef =  record
                              uid : TGUID;
                              vst2uniqueid:string; // must be 4 characters;
                              cl  : TVSTInstrumentClass;
                              ecl :  TFormClass;
                              name:string;
                              isSynth:boolean;
                            end;
     TVSTFactoryDef =     record
                             vendor,url,email:string;
                           end;
     TVSTInstrumentInfo = record
                        PluginDef:TVSTPluginDef;
                        factoryDef:TVSTFactoryDef;
                      end;
     TVSTAutomationItem = record sampleOffset:integer;value:double end;
     TVSTAutomationQueue = class
                           private
                             Fid:integer;
                             FList:TList<TVSTAutomationItem>;
                             function get(index:integer):TVSTAutomationItem;
                           public
                             procedure Add(sampleOffset:integer;value:double);
                             constructor Create(id:integer);
                             destructor Destroy;
                             property id: integer read FId;
                             function last:double;
                             function count:integer;
                             property value[index:integer]:TVSTAutomationItem read get;default;
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

procedure TVSTAutomationQueue.Add(sampleOffset: integer; value: double);
VAR item:TVSTAutomationItem;
begin
  item.sampleOffset:=sampleOffset;
  item.value:=value;
  FList.Add(item);
end;

function TVSTAutomationQueue.count: integer;
begin
  result:=FList.Count;
end;

constructor TVSTAutomationQueue.Create(id: integer);
begin
  Fid:=id;
  Flist:=TList<TVSTAutomationItem>.Create;
end;

destructor TVSTAutomationQueue.Destroy;
begin
  Flist.Free;
end;

function TVSTAutomationQueue.get(index: integer): TVSTAutomationItem;
begin
  result:=Flist[index];
end;

function TVSTAutomationQueue.last: double;
begin
  if FList.Count>0 then result:=FList[FList.Count-1].value else result:=0;
end;



end.
