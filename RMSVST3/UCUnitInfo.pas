unit UCUnitInfo;

interface

uses Vst3Base,UCPlugView,UVST3Controller;

type CUnitInfo = class(TAggregatedObject,IUnitInfo)
private
  IVST3:IVST3Controller;
      // Returns the flat count of units.
      function GetUnitCount: int32; stdcall;
      // Gets UnitInfo for a given index in the flat list of unit.
      function getUnitInfo(unitIndex: int32; out info: TUnitInfo): TResult; stdcall;

      // Component intern program structure --
      // Gets the count of Program List.
      function GetProgramListCount: int32; stdcall;
      // Gets for a given index the Program List Info.
      function GetProgramListInfo(listIndex: int32; out info: TProgramListInfo): TResult; stdcall;
      // Gets for a given program list ID and program index its program name.
      function GetProgramName(listId: TProgramListID; programIndex: int32; name: PString128): TResult; stdcall;
      // Gets for a given program list ID, program index and attributeId the associated attribute value.
      function GetProgramInfo (listId: TProgramListID; programIndex: int32; attributeId: CString; attributeValue: PString128): TResult; stdcall;
      // Returns kResultTrue if the given program index of a given program list ID supports PitchNames.
      function HasProgramPitchNames(listId: TProgramListID; programIndex: int32): TResult; stdcall;
      // Gets the PitchName for a given program list ID, program index and pitch.
		  // If PitchNames are changed the Plug-in should inform the host with IUnitHandler::notifyProgramListChange.
      function GetProgramPitchName(listId: TProgramListID; programIndex: int32; midiPitch: int16; name: PString128): TResult; stdcall;

      // units selection --------------------
      // Gets the current selected unit.
      function GetSelectedUnit: TUnitID; stdcall;
      // Sets a new selected unit.
      function SelectUnit(unitId: TUnitID): TResult; stdcall;
      // Gets the according unit if there is an unambiguous relation between a channel or a bus and a unit.
	    // This method mainly is intended to find out which unit is related to a given MIDI input channel.
      function GetUnitByBus(aType: TMediaType; dir: TBusDirection; busIndex, channel: int32; out unitId: TUnitID): TResult; stdcall;

      // Receives a preset data stream.
      // - If the component supports program list data (IProgramListData), the destination of the data
      //   stream is the program specified by list-Id and program index (first and second parameter)
      // - If the component supports unit data (IUnitData), the destination is the unit specified by the first
      //   parameter - in this case parameter programIndex is < 0).
      function SetUnitProgramData(listOrUnitId: TProgramListID; programIndex: int32; data: IBStream): TResult; stdcall;

public
  constructor Create(const Controller: IVST3Controller);
end;

implementation

{ CUnitInfo }

uses CodeSiteLogging;

constructor CUnitInfo.Create(const Controller: IVST3Controller);
begin
  inherited Create(controller);
  IVST3:=Controller;
end;

function CUnitInfo.GetProgramInfo(listId: TProgramListID; programIndex: int32;
  attributeId: CString; attributeValue: PString128): TResult;
begin
  result:=kNotImplemented;
end;

function CUnitInfo.GetProgramListCount: int32;
begin
  result:=1;
end;

function CUnitInfo.GetProgramListInfo(listIndex: int32;  out info: TProgramListInfo): TResult;
begin
  if listIndex=0 then
  begin
    info.id := IDPARMPRESET;
    info.programCount := IVST3.GetNumPrograms;
    AssignStrToStr128 (info.name, 'Factory Presets');
    result:=kResultTrue;
  end
  else
    result:=kResultFalse;
end;

function CUnitInfo.GetProgramName(listId: TProgramListID; programIndex: int32;  name: PString128): TResult;
begin
   AssignStrToStr128(name^,IVST3.GetProgramName(programIndex));
  result:=kResultOk;
end;

function CUnitInfo.GetProgramPitchName(listId: TProgramListID;
  programIndex: int32; midiPitch: int16; name: PString128): TResult;
begin
  result:=kNotImplemented;
end;

function CUnitInfo.GetSelectedUnit: TUnitID;
begin
  result:=kRootUnitId;
end;

function CUnitInfo.GetUnitByBus(aType: TMediaType; dir: TBusDirection; busIndex,  channel: int32; out unitId: TUnitID): TResult;
begin
  result:=kNotImplemented;
end;

function CUnitInfo.GetUnitCount: int32;
begin
  result:=1;
end;

function CUnitInfo.getUnitInfo(unitIndex: int32; out info: TUnitInfo): TResult;
begin
  if (unitIndex = 0) then
  begin
    info.id             := kRootUnitId;
    info.parentUnitId   := kNoParentUnitId;
    info.programListId  := kNoProgramListId;
    AssignStrToStr128(info.name,'Root Unit');
    result:=kResultTrue;
  end
  else
    result:=kResultFalse;
end;

function CUnitInfo.HasProgramPitchNames(listId: TProgramListID;  programIndex: int32): TResult;
begin
  result:=kNotImplemented;
end;

function CUnitInfo.SelectUnit(unitId: TUnitID): TResult;
begin
  result:=kNotImplemented;
end;

function CUnitInfo.SetUnitProgramData(listOrUnitId: TProgramListID;  programIndex: int32; data: IBStream): TResult;
begin
  CodeSite.Send('CUnitInfo.SetUnitProgramData');
  result:=kResultTrue;
end;

end.
