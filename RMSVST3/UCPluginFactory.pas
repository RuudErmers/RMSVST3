unit UCPluginFactory;

interface

uses Vst3Base,Generics.Collections,UVSTBase;

type CPluginFactory = class(TInterfacedObject,IPluginFactory,IPluginFactory2)
private
  factoryInfo:TPFactoryInfo;
  fClassInfo2:TPClassInfo2;
  fpluginInfo:TVSTInstrumentInfo;
  function GetFactoryInfo(var info: TPFactoryInfo): TResult;  stdcall;
  function CountClasses: int32;  stdcall;
  function GetClassInfo(index: int32; var info: TPClassInfo): TResult;  stdcall;
  function CreateInstance(cid, iid: PAnsiChar; var obj: pointer): TResult;  stdcall;
  function GetClassInfo2(index: int32; var info: TPClassInfo2): TResult; stdcall;
// IPluginFactory3  function GetClassInfoUnicode(index: int32; var info: TPClassInfoW): TResult;  stdcall;
// IPluginFactory3  function SetHostContext(context: FUnknown): TResult;  stdcall;
public
  constructor Create(pluginInfo:TVSTInstrumentInfo);
end;

function CreatePlugin(pluginInfo:TVSTInstrumentInfo): pointer;stdcall;

implementation

{ CPluginFactory }

uses UCodeSiteLogger,SysUtils,UCEditController,UVST3Utils ;

const CLTYPE_CONTROLLER = 28;
const CLTYPE_PROCESSOR = 27;

function CPluginFactory.CountClasses: int32;
begin
  WriteLog('CPluginFactory.CountClasses');
  result:=1;  //
end;

constructor CPluginFactory.Create(pluginInfo:TVSTInstrumentInfo);
begin
  WriteLog('CPluginFactory.Create:');

  inherited create;
  fPluginInfo:=pluginInfo;
  with fPlugInInfo.factoryDef do
  begin
    AssignString(factoryInfo.vendor,vendor);
    AssignString(factoryInfo.url,url);
    AssignString(factoryInfo.email,email);
    factoryInfo.flags:=kUnicode; //kNoFlags;
  end;

  with fClassInfo2 do
  begin
      cid := TUID(pluginInfo.PluginDef.vst3id);
      cardinality:=     kManyInstances;
      AssignString(category,kVstAudioEffectClass);  // Changed..
      AssignString(name,    pluginInfo.PluginDef.name);
      classFlags:=      0;
      if pluginInfo.PluginDef.isSynth then
        subCategories:= kInstrumentSynth
      else
        subCategories:= kFx;
      AssignString(sdkVersion,     kVstVersionString); // Changed
  end;
  _addRef;
end;

function CPluginFactory.CreateInstance(cid, iid: PAnsiChar;  var obj: pointer): TResult;
VAR instance:FUnknown;
    guid:TGUID;
    found:boolean;
    res:integer;
    fPlugin:TVSTBase;
begin
  WriteLog('CPluginFactory.CreateInstance IID:'+UIDPCharToNiceString(iid));
  WriteLog('CPluginFactory.CreateInstance CID:'+UIDPCharToNiceString(cid));
  found:=false;
  if UIDMatch(TUID(fPluginInfo.PluginDef.vst3id),cid) then
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
      instance._release;  // OK, I think this must be...
      result:=kResultOk;
      WriteLog('CPluginFactory.CreateInstance OK.');
      exit;
    end
    else
    begin
      instance._release;
       WriteLog('CPluginFactory.CreateInstance NOK.');
    end;
  end;
  obj:=NIL;
  result:=kNoInterface;
  WriteLog('CPluginFactory.CreateInstance Done.');
end;

function CPluginFactory.GetClassInfo(index: int32; var info: TPClassInfo): TResult;
VAR i:integer;
begin
  WriteLog('CPluginFactory.GetClassInfo:'+inttostr(index));
  with fClassInfo2 do
  begin
    info.cid:=cid;
    info.cardinality:=cardinality;
    WriteLog('CPluginFactory.cardinality:'+inttostr(cardinality));
    for i:=0 to kClassInfoNameSize-1 do
      info.name[i]:=name[i];
    WriteLog('CPluginFactory.kClassInfoNameSize:'+inttostr(kClassInfoNameSize));
    for i:=0 to kClassInfoCategorySize-1 do
      info.category[i]:=category[i];
  end;
  result:=kResultOK;
end;

function CPluginFactory.GetClassInfo2(index: int32;  var info: TPClassInfo2): TResult;
begin
  WriteLog('CPluginFactory.GetClassInfo2:'+' '+IntToStr(index));
  info:=fClassInfo2;
  result:=kResultOK;
end;

function CPluginFactory.GetFactoryInfo(var info: TPFactoryInfo): TResult;
begin
  WriteLog('CPluginFactory.GetFactoryInfo:');
  info:=factoryInfo;
  result:=kResultOK;
end;

function CreatePlugin(pluginInfo:TVSTInstrumentInfo): pointer;stdcall;
begin
  WriteLog('CPluginFactory.CreatePlugin:');
  result:=IPluginFactory(CPluginFactory.Create(pluginInfo));
end;




end.
