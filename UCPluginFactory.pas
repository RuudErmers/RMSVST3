unit UCPluginFactory;

interface

uses Vst3Base,Generics.Collections,UVST3Instrument;

type CPluginFactory = class(TInterfacedObject,IPluginFactory,IPluginFactory2)
private
  factoryInfo:TPFactoryInfo;
  fClassInfo2:TPClassInfo2;
  fpluginInfo:TVST3InstrumentInfo;
  function MYGetFactoryInfo(var info: TPFactoryInfo): TResult;  stdcall;
  function CountClasses: int32;  stdcall;
  function GetClassInfo(index: int32; var info: TPClassInfo): TResult;  stdcall;
  function CreateInstance(cid, iid: PAnsiChar; var obj: pointer): TResult;  stdcall;
  function GetClassInfoUnicode(index: int32; var info: TPClassInfoW): TResult;  stdcall;
  function SetHostContext(context: FUnknown): TResult;  stdcall;
  function GetClassInfo2(index: int32; var info: TPClassInfo2): TResult; stdcall;
public
  constructor Create(pluginInfo:TVST3InstrumentInfo);
end;

function CreatePlugin(pluginInfo:TVST3InstrumentInfo): pointer;stdcall;

implementation

{ CPluginFactory }

uses CodeSiteLogging,SysUtils,UCEditController,UUIDHelper ;

const CLTYPE_CONTROLLER = 28;
const CLTYPE_PROCESSOR = 27;

function CPluginFactory.CountClasses: int32;
begin
  CodeSite.Send('CPluginFactory.CountClasses');
  result:=1;  // TODO !! goed opletten bij mergen...
end;

constructor CPluginFactory.Create(pluginInfo:TVST3InstrumentInfo);
begin
  inherited create;
  fPluginInfo:=pluginInfo;
  with fPlugInInfo.factoryDef do
  begin
    StrPCopy(factoryInfo.vendor,vendor);
    StrPCopy(factoryInfo.url,url);
    StrPCopy(factoryInfo.email,email);
  end;

  with fClassInfo2 do
  begin
      cid := TUID(pluginInfo.PluginDef.uid);
      cardinality:=     kManyInstances;
      category:=        kVstAudioEffectClass;
      StrPCopy(name,    pluginInfo.PluginDef.name);
      classFlags:=      0;
      if pluginInfo.PluginDef.isSynth then
        subCategories:= kInstrument
      else
        subCategories:= kFx;
      sdkVersion:=      kVstVersionString;
  end;
  _addRef;
end;

function CPluginFactory.CreateInstance(cid, iid: PAnsiChar;  var obj: pointer): TResult;
VAR instance:FUnknown;
    guid:TGUID;
    found:boolean;
    res:integer;
    fPlugin:TVST3Instrument;
begin
  CodeSite.Send('CPluginFactory.CreateInstance:'+UIDPCharToNiceString(iid));
  found:=false;
  if UIDMatch(TUID(fPluginInfo.PluginDef.uid),cid) then
  begin
    fPlugin:=fPluginInfo.PluginDef.cl.Create;
    fPlugin.OnCreate(fPluginInfo);
    instance:=fPlugin;
    instance._addRef;
    found:=true;
  end;
  if found then
  begin
    guid:=PAnsiCharToTGUID(iid);
    res:=instance.queryInterface(guid,obj);
    if res=kResultOk then
    begin
      instance._release;
      result:=kResultOk;
      exit;
    end
    else
      instance._release;
  end;
  obj:=NIL;
  result:=kNoInterface;
end;

function CPluginFactory.GetClassInfo(index: int32; var info: TPClassInfo): TResult;
VAR i:integer;
begin
  CodeSite.Send('CPluginFactory.GetClassInfo:'+inttostr(index));
  with fClassInfo2 do
  begin
    info.cid:=cid;
    info.cardinality:=cardinality;
    for i:=0 to kClassInfoNameSize-1 do
      info.name[i]:=name[i];
    for i:=0 to kClassInfoCategorySize-1 do
    info.category[i]:=category[i];
  end;
  result:=kResultOK;
end;

function CPluginFactory.GetClassInfo2(index: int32;  var info: TPClassInfo2): TResult;
begin
  CodeSite.Send('CPluginFactory.GetClassInfo2:'+' '+IntToStr(index));
  info:=fClassInfo2;
  result:=kResultOK;
end;

function CPluginFactory.GetClassInfoUnicode(index: int32; var info: TPClassInfoW): TResult;
begin
  CodeSite.Send('GetClassInfoUnicode');
end;

function CPluginFactory.MYGetFactoryInfo(var info: TPFactoryInfo): TResult;
begin
  info:=factoryInfo;
  result:=kResultOK;
end;

function CPluginFactory.SetHostContext(context: FUnknown): TResult;
begin
(* JUCE Version
        host.loadFrom (context);

        if (host != nullptr)
        {
            Vst::String128 name;
            host->getName (name);

            return kResultTrue;
        }

        return kNotImplemented;
   JUCE Version *)
  result:=kResultTrue;
end;

//uses UCPluginFactory,CodeSiteLogging,SysUtils,UMyVST;

VAR gPluginFactory:CPluginFactory;

function CreatePlugin(pluginInfo:TVST3InstrumentInfo): pointer;stdcall;
begin
  if gPluginFactory=NIL then
    gPluginFactory:=CPluginFactory.Create(pluginInfo)
   else
     IPluginFactory(gPluginFactory)._addRef;
  result:=IPluginFactory(gPluginFactory);
end;




end.
