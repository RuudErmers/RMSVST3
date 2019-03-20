unit UCPluginFactory;

interface

////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//  Version: MPL 1.1 or LGPL 2.1 with linking exception                       //
//                                                                            //
//  The contents of this file are subject to the Mozilla Public License       //
//  Version 1.1 (the "License"); you may not use this file except in          //
//  compliance with the License. You may obtain a copy of the License at      //
//  http://www.mozilla.org/MPL/                                               //
//                                                                            //
//  Software distributed under the License is distributed on an "AS IS"       //
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the   //
//  License for the specific language governing rights and limitations under  //
//  the License.                                                              //
//                                                                            //
//  Alternatively, the contents of this file may be used under the terms of   //
//  the Free Pascal modified version of the GNU Lesser General Public         //
//  License Version 2.1 (the "FPC modified LGPL License"), in which case the  //
//  provisions of this license are applicable instead of those above.         //
//  Please see the file LICENSE.txt for additional information concerning     //
//  this license.                                                             //
//                                                                            //
//  The code is part of the Delphi ASIO & VST Project                         //
//                                                                            //
//  The initial developer of this code is Christian-W. Budde, additional      //
//  coding and refactoring done by Maik Menz                                  //
//                                                                            //
//  Portions created by Christian-W. Budde are Copyright (C) 2003-2011        //
//  by Christian-W. Budde. All Rights Reserved.                               //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// This unit implements the basic VST-Plugin <--> Host communications
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

uses
  Classes, Forms, Sysutils,  DAV_VSTEffect,CodeSiteLogging,UVSTBase;

{$define DebugLog}

type
  TBasicVSTModuleClass = class of TBasicVSTModule;

  { TBasicVSTModule }

  TBasicVSTModule = class(TVSTBase)
  private
    FEffect             : TVSTEffect;
    FAudioMaster        : TAudioMasterCallbackFunc;
    FEffectIsOpen       : boolean;
    FVstEvents          : TVstEvents;
    FCurTempo,FSampleRate:single;


    function GetEffect: PVSTEffect;
    procedure CheckTempo;
    function HostCallSetSampleRate(const Index: Integer;
      const Value: TVstIntPtr; const ptr: Pointer;
      const opt: Single): TVstIntPtr;
    procedure SendMidi;
    function  SendVstEventsToHost(var Events: TVstEvents): Boolean;  // True: success
    function  GetTimeInfo(const Filter: TVstIntPtr): PVstTimeInfo; virtual;  // returns const VstTimeInfo* (or 0 if not supported) filter should contain a mask indicating which fields are requested (see valid masks in aeffectx.h), as some items may require extensive conversions
  protected
    function CallAudioMaster(const Opcode: TAudioMasterOpcode;
      const Index: Integer = 0; const Value: TVstIntPtr = 0;
      const PTR: Pointer = nil; const Opt: Single = 0): TVstIntPtr; virtual;

    procedure MidiOut(const byte0,byte1,byte2: Byte; b4: Byte = 0; const Offset: Integer = 0);

    procedure SetParameterAutomated(const Index: Integer; const Value: Single); virtual;
    function  BeginEdit(const Index: Integer): Boolean; virtual; // to be called before a setParameterAutomated with mouse move (one per Mouse Down)
    function  EndEdit(const Index: Integer): Boolean; virtual;   // to be called after a setParameterAutomated (on Mouse Up)
    function  HostCallOpen  (const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; virtual;
    function  HostCallClose (const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; virtual;

    procedure HostCallProcess(const Inputs, Outputs: PPSingle; const SampleFrames: Cardinal); virtual; abstract;
    procedure HostCallProcess32Replacing(const Inputs, Outputs: PPsingle; const SampleFrames: Cardinal); virtual; abstract;
    procedure HostCallProcess64Replacing(const Inputs, Outputs: PPDouble; const SampleFrames: Cardinal); virtual; abstract;

    function  HostCallDispatchEffect(const Opcode: TDispatcherOpcode; const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; virtual;
    function  HostCallGetParameter(const Index: Integer): Single; virtual; abstract;
    procedure HostCallSetParameter(const Index: Integer; const Value: Single); virtual; abstract;
    procedure PlayStateChanged(playing:boolean;ppq:integer);virtual;abstract;
    procedure SamplerateChanged(samplerate:single);virtual;abstract;
    procedure TempoChanged(tempo: single);virtual;abstract;


    property AudioMaster: TAudioMasterCallbackFunc read FAudioMaster write FAudioMaster;
  public
    constructor Create; override;
    destructor Destroy; override;
    property Effect: PVSTEffect read GetEffect;
  end;

  EVstError = class(Exception);

function DispatchEffectFuncUserPtr(Effect: PVSTEffect; OpCode : TDispatcherOpCode;
  const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer;
  const opt: Single): TVstIntPtr; cdecl;
function GetParameterFuncUserPtr(const Effect: PVSTEffect;
  const Index: Integer): Single; cdecl;
procedure SetParameterFuncUserPtr(const Effect: PVSTEffect; const Index: Integer;
  const Value: Single); cdecl;

procedure ProcessFuncUserPtr(const Effect: PVSTEffect;
  const Inputs, Outputs: PPsingle; const SampleFrames: Integer); cdecl;
procedure Process32ReplacingFuncUserPtr(const Effect: PVSTEffect;
  const Inputs, Outputs: PPsingle; const SampleFrames: Integer); cdecl;
procedure Process64ReplacingFuncUserPtr(const Effect: PVSTEffect;
  const Inputs, Outputs: PPDouble; const SampleFrames: Integer); cdecl;

function CreatePlugin(AudioMasterCallback: TAudioMasterCallbackFunc;
  VST3InstrumentInfo:TVSTInstrumentInfo): PVSTEffect;

implementation

uses
  Math,  UVSTInstrument;

const
  CMaxMidiEvents = 1024;


function CreatePlugin(AudioMasterCallback: TAudioMasterCallbackFunc;
  VST3InstrumentInfo:TVSTInstrumentInfo): PVSTEffect;
var
  VstBase : TVStBase;
begin
 try
  VstBase := VST3InstrumentInfo.PluginDef.cl.Create;
  with TVST2Instrument(VstBase) do
   begin
    OnCreate(VST3InstrumentInfo);
    AudioMaster := AudioMasterCallback;
    Result := Effect;
   end;
 except
  Result := nil;
 end;
end;

{ TBasicVSTModule }

constructor TBasicVSTModule.Create;
VAR i:integer;
begin
  FEffectIsOpen:=false;
 with FEffect do
  begin
   Magic           := 'PtsV';
   EffectFlags     := [effFlagsCanReplacing];
   ReservedForHost := nil;
   Resvd2          := nil;
   AudioEffectPtr  := nil;
   User            := Self;
   uniqueID        := 'fEoN';
   ioRatio         := 1;
   numParams       := 0;
   numPrograms     := 0;
   numInputs       := 2;
   numOutputs      := 2;

   Dispatcher         := @DispatchEffectFuncUserPtr;
   SetParameter       := @SetParameterFuncUserPtr;
   GetParameter       := @GetParameterFuncUserPtr;
   Process            := @ProcessFuncUserPtr;
   Process32Replacing := @Process32ReplacingFuncUserPtr;
   Process64Replacing := @Process64ReplacingFuncUserPtr;
  end;
  FVstEvents.numEvents := 0;

  for i := 0 to CMaxMidiEvents - 1 do
   begin
    GetMem(FVstEvents.Events[i], SizeOf(TVstMidiEvent));
    FillChar(FVstEvents.Events[i]^, SizeOf(TVstMidiEvent), 0);
    PVstMidiEvent(FVstEvents.Events[i])^.EventType := etMidi;
    PVstMidiEvent(FVstEvents.Events[i])^.ByteSize := 24;
   end;

end;

destructor TBasicVSTModule.Destroy;
var
  Index : Integer;
begin
 try
  {$IFDEF DebugLog}
  CodeSite.Send('TBasicVSTModule.Destroy');
  {$ENDIF}
 finally
   inherited;
 end;
end;

function TBasicVSTModule.GetEffect: PVSTEffect;
begin
 Result := @FEffect;
end;

function TBasicVSTModule.CallAudioMaster(const Opcode: TAudioMasterOpcode;
  const Index: Integer = 0; const Value: TVstIntPtr = 0;
  const PTR: Pointer = nil; const Opt: Single = 0): TVstIntPtr;
begin

// {$IFDEF DebugLog}
// can be called from non ui thread...CodeSite.Send('TBasicVSTModule.CallAudioMaster; Opcode: ' +
//   IntToStr(Integer(Opcode)));
// {$ENDIF}

 if Assigned(FAudioMaster)
  then Result := FAudioMaster(@FEffect, Opcode, Index, Value, PTR, Opt)
  else Result := 0;
end;


function TBasicVSTModule.GetTimeInfo(const Filter: TVstIntPtr): PVstTimeInfo;
begin
 Result := PVstTimeInfo(CallAudioMaster(amGetTime, 0, Filter));
end;

function TBasicVSTModule.SendVstEventsToHost(var Events: TVstEvents): Boolean;
begin
 Result := CallAudioMaster(amProcessEvents, 0, 0, @Events) = 1;
end;

procedure TBasicVSTModule.SetParameterAutomated(const Index: Integer; const Value: Single);
begin
 CallAudioMaster(amAutomate, Index, 0, nil, Value);
end;

function TBasicVSTModule.BeginEdit(const Index: Integer): Boolean;
begin
 Result := CallAudioMaster(amBeginEdit, Index) <> 0;
end;

function TBasicVSTModule.EndEdit(const Index: Integer): Boolean;
begin
 Result := CallAudioMaster(amEndEdit, Index) <> 0;
end;

// ------------------------------------------------------------------
// Calls from the host
// ------------------------------------------------------------------

function TBasicVSTModule.HostCallOpen(const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr;
begin
 Result := 0;
 FEffectIsOpen:=true;
end;

function TBasicVSTModule.HostCallClose(const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr;
begin
 try
  FEffectIsOpen:=false;
  Effect^.User := nil;
  {$IFNDEF FPC}
  Free;
  {$ENDIF}
  Result := 1;
 except
  Result := 0;
 end;
end;

function TBasicVSTModule.HostCallSetSampleRate(const Index: Integer; const Value: TVstIntPtr; const ptr: Pointer; const opt: Single): TVstIntPtr;
begin
 if FSampleRate <> opt then
  begin
   FSampleRate := opt;
   SampleRateChanged(FSampleRate);
  end;
 Result := 1;
end;


function TBasicVSTModule.HostCallDispatchEffect(const Opcode: TDispatcherOpcode; const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr;
begin
  result:=0;
  case OpCode of
    effOpen:            Result := HostCallOpen(Index, Value, PTR, opt);
    effClose:           Result := HostCallClose(Index, Value, PTR, opt);
    effSetSampleRate:   Result := HostCallSetSampleRate(Index, Value, PTR, opt);
  end;
end;

function DispatchEffectFuncUserPtr(Effect: PVSTEffect; OpCode: TDispatcherOpCode; const Index: Integer; const Value: TVstIntPtr; const PTR: Pointer; const opt: Single): TVstIntPtr; cdecl;
begin
  Result:=0;
 if Assigned(Effect) then
  if (TObject(Effect^.User) is TBasicVSTModule) then
   with TObject(Effect^.User) as TBasicVSTModule do
     Result := HostCallDispatchEffect(OpCode, Index, Value, PTR, opt)
end;

function GetParameterFuncUserPtr(const Effect: PVSTEffect; const Index: Integer): Single; cdecl;
begin
  Result:=0;
  Assert(Assigned(Effect));
  if (TObject(Effect^.User) is TBasicVSTModule) then
   with TObject(Effect^.User) as TBasicVSTModule do
     if FEffectIsOpen then Result := HostCallGetParameter(Index)
end;

procedure SetParameterFuncUserPtr(const Effect: PVSTEffect; const Index: Integer; const Value: Single); cdecl;
begin
  Assert(Assigned(Effect));
  if (TObject(Effect^.User) is TBasicVSTModule) then
   with TObject(Effect^.User) as TBasicVSTModule do
     if FEffectIsOpen then HostCallSetParameter(Index, Value);
end;

procedure TBasicVSTModule.CheckTempo;
var
  TimeInfo : PVstTimeInfo;
  Tempo:double;
begin
  TimeInfo := GetTimeInfo(32767);
  if vtiTransportChanged in TimeInfo^.flags then
      PlayStateChanged(vtiTransportPlaying in TimeInfo^.flags,round(TimeInfo^.PpqPos));
  if VtiTempoValid in TimeInfo^.flags then
    begin
      Tempo := TimeInfo^.Tempo;
      if FCurTempo<>Tempo then
      begin
        FCurTempo:=Tempo;
        TempoChanged(Tempo);
      end;
    end;
end;

procedure ProcessFuncUserPtr(const Effect: PVSTEffect; const Inputs,
  Outputs: PPSingle; const SampleFrames: Integer); cdecl;
begin
 // check consistency
 if not Assigned(Effect) or (SampleFrames <= 0) or ((Inputs = nil) and (Outputs = nil))
  then Exit;
  if (TObject(Effect^.User) is TBasicVSTModule) then
   with TObject(Effect^.User) as TBasicVSTModule do
     if FEffectIsOpen then
     begin
       CheckTempo;
       HostCallProcess(Inputs, Outputs, SampleFrames);
       SendMidi;
     end;
end;
procedure Process32ReplacingFuncUserPtr(const Effect: PVSTEffect; const Inputs,
  Outputs: PPSingle; const SampleFrames: Integer); cdecl;
begin
 // check consistency
 if not Assigned(Effect) or (SampleFrames <= 0) or ((Inputs = nil) and (Outputs = nil))
  then Exit;
  if (TObject(Effect^.User) is TBasicVSTModule) then
   with TObject(Effect^.User) as TBasicVSTModule do
     if FEffectIsOpen then
     begin
       CheckTempo;
       HostCallProcess32Replacing(Inputs, Outputs, SampleFrames);
       SendMidi;
     end;
end;

procedure Process64ReplacingFuncUserPtr(const Effect: PVSTEffect; const Inputs,
  Outputs: PPDouble; const SampleFrames: Integer); cdecl;
begin
 // check consistency
 if not Assigned(Effect) or (SampleFrames <= 0) or ((Inputs = nil) and (Outputs = nil))
  then Exit;
  if (TObject(Effect^.User) is TBasicVSTModule) then
   with TObject(Effect^.User) as TBasicVSTModule do
     if FEffectIsOpen then
     begin
       CheckTempo;
       HostCallProcess64Replacing(Inputs, Outputs, SampleFrames);
       SendMidi;
     end;
end;

procedure TBasicVSTModule.MidiOut(const byte0,byte1,byte2: Byte; b4: Byte = 0; const Offset: Integer = 0);
begin
 with PVstMidiEvent(FVstEvents.Events[FVstEvents.numEvents])^ do
  begin
   EventType := etMidi;
   MidiData[0] := byte0;
   MidiData[1] := byte1;
   MidiData[2] := byte2;
   MidiData[3] := b4;
   DeltaFrames := offset;
   if FVstEvents.numEvents < CMaxMidiEvents - 1 then Inc(FVstEvents.numEvents);
  end;
end;

procedure TBasicVSTModule.SendMidi;
begin
 if FVstEvents.numEvents > 0 then
  begin
   SendVstEventsToHost(FVstEvents);
   FVstEvents.numEvents := 0;
  end;
end;


end.

