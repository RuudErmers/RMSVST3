{

FL Studio generator/effect plugins SDK
plugin & host classes

(99-13) gol


!!! Warnings:

-when multithreadable, a generator (not effect) adding to the output buffer, or a generator/effect adding to the send buffers, must lock the access in-between LockMix_Shared / UnlockMix_Shared




history:

(10/05/00)
- rewrote almost everything, a lot of changes & splits

(15/07/00)
- changed TVoiceParams & the way the levels are handled (Voice_Render)
- added FPF_TimeWarp

(26/07/00)
- added plugin flags combo's
- removed AlphaTable from TFruityPlugingHost

(27/07/00)
- DefPoly now used

(26/09/00)
- TFruityPlugHost.MIDIOut declaration has changed
- implemented FPF_MIDITick

(27/09/00)
- added TFruityPlugHost.MIDIOut_Delayed & FPF_MIDIOut, reorganized TFruityPlugHost
- defined UseCriticalSection in FP_DelphiPlug
- updated FPE_Tempo
- added FPE_MaxPoly & FPD_KillAVoice

(11/10/00)
- added FPE_MIDI_Pan & FPE_MIDI_Vol

(01/11/00)
- updated TFruityPlugHost.Voice_Kill(Sender:Integer;KillHandle:LongBool);
  (KillHandle forces Fruity to ask back the plugin to destroy its voice, in case the plugin is still using that voice handle, or has destroyed it already, use False)

(27/11/00)
- added FPN_VoiceLevel & FPN_VoiceLevelHint to allow the plugin to define the function of the 2 extra per-voice params (filter cutoff & resonance by default)
  added FPD_UseVoiceLevels

(29/11/00)
- added TempBuffers (TFruityPlugHost)
- added AddWave_32FM_32FS_Ramp

(13/12/00)
- updated FPE_MIDI_Vol
- added FHD_ActivateMIDI

(15/12/00)
- added FPF_MIDIIn, TFruityPlug.MIDIIn

(16/12/00)
- removed FPF_MIDIIn & FPF_MIDITick, added FHD_WantMIDIInput & FHD_WantMIDITick

(19/12/00)
- added FPD_WrapPlugin and FHD_LocatePlugin

(20/12/00)
- added FHD_KillAutomation
- added FPF_DemoVersion

(21/12/00)
- added FHD_SetNumPresets, FPN_Preset, FPD_SetPreset

(02/01/01)
- added noise wavetable
- updated PM_HQ

(15/02/01)
- added FHD_VSTiIdle
- now supports FPF_UseChanSample
- added FPD_SetCustomWaveTable

(19/03/01)
- updated FPD_WrapPlugin
- added FHD_ShowPlugSelector

(18/04/O1)
- added sample loading functions

(28/04/01)
- added timing functions (FHD_TicksToTime, FPD_SongPosChanged, FPD_SetEnabled, GetMixingTime, etc.)

(2/06/01)
- added FPN_OutCtrl, NumOutCtrls
- replaced FPF_EventController by FPF_WantNewTick (now implemented)

(12/07/01)
- added FHD_LocateDataFile
- fixed the implementation of TFruityPlugHost.Voice_Release in FruityLoops

(19/07/01)
- added FHD_GetParamMenuEntry
- (!) changed CurrentSDKVersion to 1

(24/07/01)
- added some info to WaveTables & TempBuffers

(29/07/01)
- added MsgIn, PlugMsg_Delayed, etc. (for the Fruity Vibrator)

(02/08/01)
- added FPF_Hybrid
- renamed FPF_UseChanSample to FPF_GetChanCustomShape & renamed FPD_SetCustomShape to FPD_ChanSampleChanged
- added FPF_GetChanSample (so that the plugin can get the sample as a custom 32FM shape, or a 16IS sample
- added FHLS_GetName
- changed & added processing mode flags (see PM_IsRendering)
- added GetSampleInfo

(13/02/02)
- removed MixingTick & MIDITick class variables

(10/07/02)
- added FPF_WantFitTime

(29/06/02)
- increased number of temp buffers to 4

(06/05/04)
- added FHLS_NoResampling

(18/07/04)
- added FPF_NewVoiceParams
  HOW TO UPDATE TO THIS:
  Step 1: Add FPF_NewVoiceParams to your plugin flags
  Step 2: Adapt your code so that you read the pitch & panning as floats instead of integers. Pitch is still in cents, and panning is in -1..1
  Note: ComputeLRVol was changed to ComputeLRVol_Old, and ComputeLRVol has been adapted to accept a -1..1 float panning parameter

(08/11/04)
- changed FPD_SetNumSends

(31/12/04)
- added FPD_SetSamplesPerTick

(21/03/05)
- added FPV_GetLength and FPV_GetColor for a plugin to retrieve voice color & length

(16/05/05)
- added (GM) and (G) comments telling from which thread(s) functions can be called
- added TFruityPlugHost.LockPlugin

(08/03/06)
- added FPF_IsDelphi

(02/11/06)
- added FPV_GetVelocity, FPV_GetRelVelocity, FPV_GetRelTime and FPV_SetLinkVelocity

(23/12/08)
- added FHD_GetNumInOut, GetInBuffer, GetOutBuffer, FPD_RoutingChanged
- GetInsBuffer now cannot use Ofs=0 (could bring problems)
So, GetInsBuffer, GetInBuffer & GetOutBuffer use Indexes that start at 1, 0 meaning the buffer during rendering

(27/01/09)
- added FHD_FloatAutomation, FPD_GetParamInfo, FPD_ProjLoaded, FPD_WrapperLoadState, FPD_ShowSettings, FPF_WantSettingsBtn

(02/11/11)
- MsgIn, PlugMsg_Delayed, PlugMsg_Kill are now deprecated. DO NOT USE THEM!

}




unit FP_PlugClass;


interface


uses Windows, ActiveX, FP_Def, GenericTransport;




type  // plugin info, common to all instances of the same plugin
      TFruityPlugInfo=Record
          SDKVersion  :Integer;        // =CurrentSDKVersion
          LongName,ShortName:PAnsiChar;    // full plugin name (should be the same as DLL name) & short version (for labels)
          Flags       :Integer;        // see FPF_Generator
          NumParams   :Integer;        // (maximum) number of parameters, can be overridden using FHD_SetNumParams
          DefPoly     :Integer;        // preferred (default) max polyphony (Fruity manages polyphony) (0=infinite)
          NumOutCtrls :Integer;        // number of internal output controllers
          NumOutVoices :Integer;        // number of internal output voices

          Reserved     :Array[2..31] of Integer;  // set to zero
        End;
      PFruityPlugInfo=^TFruityPlugInfo;


      // voice handle (can be an index or a memory pointer (must be unique, that is *not* just the semitone #))
      TVoiceHandle=IntPtr;
      TOutVoiceHandle=TVoiceHandle;
      TPluginTag=IntPtr;


      // sample handle
      TSampleHandle=IntPtr;

      // sample region
      TSampleRegion=Record
          SampleStart,SampleEnd:Integer;
          Name,Info   :Array[0..255] of AnsiChar;
          Time        :Single;         // beat position, mainly for loop dumping (-1 if not supported)
          KeyNum      :Integer;        // linked MIDI note number (-1 if not supported)
          Reserved    :Array[0..3] of Integer;
        End;
      PSampleRegion=^TSampleRegion;

      // sample info, FILL CORRECTLY
      TSampleInfo=Packed Record
          Size        :Integer;        // size of this structure, MUST BE SET BY THE PLUGIN
          Data        :Pointer;        // pointer to the samples
          Length      :Integer;        // length in samples
          SolidLength :Integer;        // length without ending silence
          LoopStart,LoopEnd:Integer;   // loop points (LoopStart=-1 if no loop points)
          SmpRateConv :Double;         // host sample rate*SmpRateConv = sample rate
          NumRegions  :Integer;        // number of regions in the sample (see GetSampleRegion)
          NumBeats    :Single;         // length in beats
          Tempo       :Single;
          NumChans    :Integer;        // 1=mono, 2=stereo, MUST BE SET BY THE PLUGIN, to -1 if all formats are accepted
          Format      :Integer;        // 0=16I, 1=32F, MUST BE SET BY THE PLUGIN, to -1 if all formats are accepted
          Reserved    :Array[0..12] of Integer;  // future use
        End;
      PSampleInfo=^TSampleInfo;

      // see FPV_GetInfo
      TVoiceInfo=Record
          Length:Integer;
          Color:Integer;
          Velocity:Single;
          Flags:Integer;
          Reserved:Array[0..7] of Integer;
        End;
      PVoiceInfo=^TVoiceInfo;

      // see FHD_GetMixingTime    
      TFPTime=Packed Record
          t,t2:Double;
        End;
      PFPTime=^TFPTime;

      // see FHD_GetInName
      TNameColor=Packed Record
          Name,VisName:Array[0..255] of AnsiChar;  // user-defined name (can be empty), visible name (can be guessed)
          Color:Integer;
          Index:Integer;  // real index of the item (can be used to translate plugin's own in/out into real mixer track #)
        End;
      PNameColor=^TNameColor;

      // see GetInBuffer/GetOutBuffer
      TIOBuffer=Packed Record
          Buffer:Pointer;
          //Filled:LongBool;  // only valid for GetInBuffer, indicates if buffer is not empty
          Flags:DWORD;  // see IO_Filled
        End;
      PIOBuffer=^TIOBuffer;


      // level params, used both for final voice levels (voice levels+parent channel levels) & original voice levels
      // note: all params can go outside their defined range

      // OLD, OBSOLETE VERSION, DO NOT USE!!!
      TLevelParams_Old=Record
          Pan         :Integer;        // panning (-64..64)
          Vol         :Single;         // volume/velocity (0..1)
          Pitch       :Integer;        // pitch (in cents) (semitone=Pitch/100)
          FCut,FRes   :Single;         // filter cutoff & Q (0..1)
        End;
      PLevelParams_Old=^TLevelParams_Old;
      TVoiceParams_Old=Record
          InitLevels,FinalLevels:TLevelParams_Old;
        End;

      // NEW VERSION (all floats), USE THESE
      TLevelParams=Record
          Pan         :Single;         // panning (-1..1)
          Vol         :Single;         // volume/velocity (0..1)
          Pitch       :Single;         // pitch (in cents) (semitone=Pitch/100)
          FCut,FRes   :Single;         // filter cutoff & Q (0..1)
        End;
      PLevelParams=^TLevelParams;
      TVoiceParams=Record
          InitLevels,FinalLevels:TLevelParams;
        End;
      PVoiceParams=^TVoiceParams;


      // to add notes to the piano roll (current pattern)
      TNoteParams=Packed Record
          Position,Length
                      :Integer;        // in PPQ
          // levels
          Pan         :Integer;        // default=0
          Vol         :Single;         // default=100/128
          Note        :SmallInt;       // default=60
          Color       :SmallInt;       // 0..15 (=MIDI channel)
          Pitch       :Integer;        // default=0
          FCut,FRes   :Single;         // default=0
        End;
      TNotesParams=Record
          Target      :Integer;        // 0=step seq (not supported yet), 1=piano roll
          Flags       :Integer;        // see NPF_EmptyFirst
          PatNum      :Integer;        // -1 for current
          ChanNum     :Integer;        // -1 for plugin's channel, or selected channel if plugin is an effect
          Count       :Integer;        // the # of notes in the structure
          NoteParams:Array[0..0] of TNoteParams;  // array of notes
        End;
      PNotesParams=^TNotesParams;


      // param menu entry
      TParamMenuEntry=Record
          Name :PAnsiChar;    // name of the menu entry (or menu separator if '-')
          Flags:Integer;  // checked or disabled, see FHP_Disabled
        End;
      PParamMenuEntry=^TParamMenuEntry;




      // plugin class
      TFruityPlug=class

          // *** params ***

          HostTag     :TPluginTag;     // free for the host to use (parent object reference, ...), passed as 'Sender' to the host
          Info        :PFruityPlugInfo;
          EditorHandle:HWnd;           // handle to the editor window panel (created by the plugin)

          MonoRender  :LongBool;       // last rendered voice rendered mono data (not used yet)

          Reserved    :Array[1..32] of Integer;  // for future use, set to zero


          // *** functions ***
          // (G) = called from GUI thread, (M) = called from mixer thread, (GM) = both, (S) = called from MIDI synchronization thread
          // (GM) calls are normally thread-safe 

          // messages (to the plugin)
          procedure   DestroyObject; virtual; stdcall;  // (G)
          function    Dispatcher(ID,Index,Value:IntPtr):IntPtr; virtual; stdcall; abstract;  // (GM)
          procedure   Idle_Public; virtual; stdcall; abstract;  // (G) (used to be Idle)
          procedure   SaveRestoreState(const Stream:IStream;Save:LongBool); virtual; stdcall; abstract;  // (G)

          // names (see FPN_Param) (Name has room for 256 chars)
          procedure   GetName(Section,Index,Value:Integer;Name:PAnsiChar); virtual; stdcall; abstract;  // (GM)

          // events
          function    ProcessEvent(EventID,EventValue,Flags:Integer):Integer; virtual; stdcall; abstract;  // (GM)
          function    ProcessParam(Index,Value,RECFlags:Integer):Integer; virtual; stdcall; abstract;  // (GM)

          // effect processing (source & dest can be the same)
          procedure   Eff_Render(SourceBuffer,DestBuffer:PWAV32FS;Length:Integer); virtual; stdcall; abstract;  // (M)
          // generator processing (can render less than length)
          procedure   Gen_Render(DestBuffer:PWAV32FS;var Length:Integer); virtual; stdcall; abstract;  // (M)

          // voice handling
          function    TriggerVoice(VoiceParams:PVoiceParams;SetTag:IntPtr):TVoiceHandle; virtual; stdcall; abstract;  // (GM)
          procedure   Voice_Release(Handle:TVoiceHandle); virtual; stdcall; abstract;  // (GM)
          procedure   Voice_Kill(Handle:TVoiceHandle); virtual; stdcall; abstract;  // (GM)
          function    Voice_ProcessEvent(Handle:TVoiceHandle;EventID,EventValue,Flags:Integer):Integer; virtual; stdcall; abstract;  // (GM)
          function    Voice_Render(Handle:TVoiceHandle;DestBuffer:PWAV32FS;var Length:Integer):Integer; virtual; stdcall; abstract;  // FPF_UseSampler only (GM)

          // (see FPF_WantNewTick) called before a new tick is mixed (not played)
          // internal controller plugins should call OnControllerChanged from here
          procedure   NewTick; virtual; stdcall; abstract;  // (M)

          // (see FHD_WantMIDITick) called when a tick is being played (not mixed) (not used yet)
          procedure   MIDITick; virtual; stdcall; abstract;  // (S)

          // MIDI input message (see FHD_WantMIDIInput & TMIDIOutMsg) (set Msg to MIDIMsg_Null if it has to be killed)
          procedure   MIDIIn(var Msg:Integer); virtual; stdcall; abstract;  // (GM)

          // buffered messages to itself (see PlugMsg_Delayed)
          procedure   MsgIn(Msg:IntPtr); virtual; stdcall; abstract;  // (S)

          // voice handling
          function    OutputVoice_ProcessEvent(Handle:TOutVoiceHandle;EventID,EventValue,Flags:Integer):Integer; virtual; stdcall; abstract;  // (GM)
          procedure   OutputVoice_Kill(Handle:TOutVoiceHandle); virtual; stdcall; abstract;  // (GM)

        End;




      // plugin host class
      TFruityPlugHost=class

          // *** params ***

          HostVersion :Integer;        // current FruityLoops version stored as 01002003 (integer) for 1.2.3
          Flags       :Integer;        // reserved

          // windows
          AppHandle   :THandle;        // application handle, for slaving windows

          // handy wavetables (32Bit float (-1..1), 16384 samples each)
          // 6 are currently defined (sine, triangle, square, saw, analog saw, noise)
          // those pointers are fixed
          // (obsolete, avoid)
          WaveTables  :Array[0..9] of PWaveT;

          // handy free buffers, guaranteed to be at least the size of the buffer to be rendered (float stereo)
          // those pointers are variable, please read & use while rendering only
          // those buffers are contiguous, so you can see TempBuffer[0] as a huge buffer
          TempBuffers :Array[0..3] of PWAV32FS;

          // reserved for future use
          Reserved    :Array[1..30] of Integer;  // set to zero


          // *** functions ***

          // messages (to the host) (Sender=plugin tag)
          function    Dispatcher(Sender:TPluginTag;ID,Index,Value:IntPtr):IntPtr; virtual; stdcall; abstract;
          // for the host to store changes
          procedure   OnParamChanged(Sender:TPluginTag;Index,Value:Integer); virtual; stdcall; abstract;
          // for the host to display hints
          procedure   OnHint(Sender:TPluginTag;Text:PAnsiChar); virtual; stdcall; abstract;

          // compute left & right levels using pan & volume info (OLD, OBSOLETE VERSION, USE ComputeLRVol INSTEAD)
          procedure   ComputeLRVol_Old(var LVol,RVol:Single;Pan:Integer;Volume:Single); virtual; stdcall; abstract;

          // voice handling (Sender=voice tag)
          procedure   Voice_Release(Sender:IntPtr); virtual; stdcall; abstract;
          procedure   Voice_Kill(Sender:IntPtr;KillHandle:LongBool); virtual; stdcall; abstract;
          function    Voice_ProcessEvent(Sender:IntPtr;EventID,EventValue,Flags:IntPtr):Integer; virtual; stdcall; abstract;

          // thread synchronisation / safety
          procedure   LockMix; virtual; stdcall; abstract;  // will prevent any new voice creation & rendering
          procedure   UnlockMix; virtual; stdcall; abstract;

          // delayed MIDI out message (see TMIDIOutMsg) (will be sent once the MIDI tick has reached the current mixer tick
          procedure   MIDIOut_Delayed(Sender:TPluginTag;Msg:IntPtr); virtual; stdcall; abstract;
          // direct MIDI out message
          procedure   MIDIOut(Sender:TPluginTag;Msg:IntPtr); virtual; stdcall; abstract;

          // handy macro functions

          // adds a mono float buffer to a stereo float buffer, with left/right levels & ramping if needed
          // how it works: define 2 float params for each voice: LastLVol & LastRVol. Make them match LVol & RVol before the *first* rendering of that voice (unless ramping will occur from 0 to LVol at the beginning).
          // then, don't touch them anymore, just pass them to the function.
          // he level will ramp from the last ones (LastLVol) to the new ones (LVol) & will adjust LastLVol accordingly
          // LVol & RVol are the result of the ComputeLRVol function
          // for a quick & safe fade out, you can set LVol & RVol to zero, & kill the voice when both LastLVol & LastRVol will reach zero
          procedure   AddWave_32FM_32FS_Ramp(SourceBuffer,DestBuffer:Pointer;Length:Integer;LVol,RVol:Single;var LastLVol,LastRVol:Single); virtual; stdcall; abstract;
          // same, but takes a stereo source
          // note that left & right channels are not mixed (not a true panning), but might be later
          procedure   AddWave_32FS_32FS_Ramp(SourceBuffer,DestBuffer:Pointer;Length:Integer;LVol,RVol:Single;var LastLVol,LastRVol:Single); virtual; stdcall; abstract;

          // sample loading functions (FruityLoops 3.1.1 & over)
          // load a sample (creates one if necessary)
          // FileName must have room for 256 chars, since it gets written with the file that has been 'located'
          // only 16Bit 44Khz Stereo is supported right now, but fill the format correctly!
          // see FHLS_ShowDialog
          function    LoadSample(var Handle:TSampleHandle;FileName:PAnsiChar;NeededFormat:PWaveFormatExtensible;Flags:Integer):Boolean; virtual; stdcall; abstract;
          function    GetSampleData(Handle:TSampleHandle;var Length:Integer):Pointer; virtual; stdcall; abstract;
          procedure   CloseSample(Handle:TSampleHandle); virtual; stdcall; abstract;

          // time info
          // obsolete, use FHD_GetMixingTime & FHD_GetPlaybackTime
          // get the current mixing time, in ticks (integer result)
          function    GetSongMixingTime:Integer; virtual; stdcall; abstract;
          // get the current mixing time, in ticks (more accurate, with decimals)
          function    GetSongMixingTime_A:Double; virtual; stdcall; abstract;
          // get the current playing time, in ticks (with decimals)
          function    GetSongPlayingTime:Double; virtual; stdcall; abstract;

          // internal controller
          procedure   OnControllerChanged(Sender:TPluginTag;Index,Value:IntPtr); virtual; stdcall; abstract;

          // get a pointer to one of the send buffers (see FPD_SetNumSends)
          // those pointers are variable, please read & use while processing only
          // the size of those buffers is the same as the size of the rendering buffer requested to be rendered
          function    GetSendBuffer(Num:IntPtr):Pointer; virtual; stdcall; abstract;

          // ask for a message to be dispatched to itself when the current mixing tick will be played (to synchronize stuff) (see MsgIn)
          // the message is guaranteed to be dispatched, however it could be sent immediately if it couldn't be buffered (it's only buffered when playing)
          procedure   PlugMsg_Delayed(Sender:TPluginTag;Msg:IntPtr); virtual; stdcall; abstract;
          // remove a buffered message, so that it will never be dispatched
          procedure   PlugMsg_Kill(Sender:TPluginTag;Msg:IntPtr); virtual; stdcall; abstract;

          // get more details about a sample
          procedure   GetSampleInfo(Handle:TSampleHandle;Info:PSampleInfo); virtual; stdcall; abstract;

          // distortion (same as TS404) on a piece of mono or stereo buffer
          // DistType in 0..1, DistThres in 1..10
          procedure   DistWave_32FM(DistType,DistThres:Integer;SourceBuffer:Pointer;Length:Integer;DryVol,WetVol,Mul:Single); virtual; stdcall; abstract;

          // same as GetSendBuffer, but Num is an offset to the mixer track assigned to the generator (Num=0 will then return the current rendering buffer)
          // to be used by generators ONLY, & only while processing
          function    GetMixBuffer(Num:Integer):Pointer; virtual; stdcall; abstract;

          // get a pointer to the insert (add-only) buffer following the buffer a generator is currently processing in
          // Ofs is the offset to the current buffer, +1 means next insert track, -1 means previous one, 0 is forbidden
          // only valid during Gen_Render
          // protect using LockMix_Shared
          function    GetInsBuffer(Sender:TPluginTag;Ofs:Integer):Pointer; virtual; stdcall; abstract;

          // ask the host to prompt the user for a piece of text (s has room for 256 chars)
          // set x & y to -1 to have the popup screen-centered
          // if false is returned, ignore the results
          // set c to -1 if you don't want the user to select a color
          function    PromptEdit(x,y:Integer;SetCaption,s:PAnsiChar;var c:Integer):Boolean; virtual; stdcall; abstract;

          // same as LockMix/UnlockMix, but stops the sound (to be used before lengthy operations)
          procedure   SuspendOutput; virtual; stdcall; abstract;
          procedure   ResumeOutput; virtual; stdcall; abstract;

          // get the region of a sample
          procedure   GetSampleRegion(Handle:TSampleHandle;RegionNum:Integer;Region:PSampleRegion); virtual; stdcall; abstract;

          // compute left & right levels using pan & volume info (USE THIS AFTER YOU DEFINED FPF_NewVoiceParams
          procedure   ComputeLRVol(var LVol,RVol:Single;Pan,Volume:Single); virtual; stdcall; abstract;

          // alternative to LockMix/UnlockMix that won't freeze audio
          // can only be called from the GUI thread
          // warning: not very performant, avoid using
          procedure   LockPlugin(Sender:TPluginTag); virtual; stdcall; abstract;
          procedure   UnlockPlugin(Sender:TPluginTag); virtual; stdcall; abstract;

          // multithread processing synchronisation / safety
          procedure   LockMix_Shared_Old; virtual; stdcall; abstract;
          procedure   UnlockMix_Shared_Old; virtual; stdcall; abstract;

          // multi-in/output (for generators & effects) (only valid during Gen/Eff_Render)
          // !!! Index starts at 1, to be compatible with GetInsBuffer (Index 0 would be Eff_Render's own buffer)
          procedure   GetInBuffer (Sender:TPluginTag;Index:IntPtr;IBuffer:PIOBuffer); virtual; stdcall; abstract;  // returns (read-only) input buffer Index (or Nil if not available).
          procedure   GetOutBuffer(Sender:TPluginTag;Index:IntPtr;OBuffer:PIOBuffer); virtual; stdcall; abstract;  // returns (add-only) output buffer Index (or Nil if not available). Use LockMix_Shared when adding to this buffer.

          // output voices (VFX "voice effects")
          function    TriggerOutputVoice(VoiceParams:PVoiceParams;SetIndex,SetTag:IntPtr):TOutVoiceHandle; virtual; stdcall; abstract;  // (GM)
          procedure   OutputVoice_Release(Handle:TOutVoiceHandle); virtual; stdcall; abstract;  // (GM)
          procedure   OutputVoice_Kill(Handle:TOutVoiceHandle); virtual; stdcall; abstract;  // (GM)
          function    OutputVoice_ProcessEvent(Handle:TOutVoiceHandle;EventID,EventValue,Flags:IntPtr):Integer; virtual; stdcall; abstract;  // (GM)

        End;




const // history:
      // 0: original version
      // 1: new popup menu system
      CurrentSDKVersion=1;


      // plugin flags
      FPF_Generator         =1;         // plugin is a generator (not effect)
      FPF_RenderVoice       =1 shl 1;   // generator will render voices separately (Voice_Render) (not used yet)
      FPF_UseSampler        =1 shl 2;   // 'hybrid' generator that will stream voices into the host sampler (Voice_Render)
      FPF_GetChanCustomShape=1 shl 3;   // generator will use the extra shape sample loaded in its parent channel (see FPD_ChanSampleChanged)
      FPF_GetNoteInput      =1 shl 4;   // plugin accepts note events (not used yet, but effects might also get note input later)
      FPF_WantNewTick       =1 shl 5;   // plugin will be notified before each mixed tick (& be able to control params (like a built-in MIDI controller) (see NewTick))
      FPF_NoProcess         =1 shl 6;   // plugin won't process buffers at all (FPF_WantNewTick, or special visual plugins (Fruity NoteBook))
      FPF_NoWindow          =1 shl 10;  // plugin will show in the channel settings window & not in its own floating window
      FPF_Interfaceless     =1 shl 11;  // plugin doesn't provide its own interface (not used yet)
      FPF_TimeWarp          =1 shl 13;  // supports timewarps, that is, can be told to change the playing position in a voice (direct from disk music tracks, ...) (not used yet)
      FPF_MIDIOut           =1 shl 14;  // plugin will send MIDI out messages (only those will be enabled when rendering to a MIDI file)
      FPF_DemoVersion       =1 shl 15;  // plugin is a demo version, & the host won't save its automation
      FPF_CanSend           =1 shl 16;  // plugin has access to the send tracks, so it can't be dropped into a send track or into the master
      FPF_MsgOut            =1 shl 17;  // plugin will send delayed messages to itself (will require the internal sync clock to be enabled)
      FPF_HybridCanRelease  =1 shl 18;  // plugin is a hybrid generator & can release its envelope by itself. If the host's volume envelope is disabled, then the sound will keep going when the voice is stopped, until the plugin has finished its own release
      FPF_GetChanSample     =1 shl 19;  // generator will use the sample loaded in its parent channel (see FPD_ChanSampleChanged)
      FPF_WantFitTime       =1 shl 20;  // fit to time selector will appear in channel settings window (see FPD_SetFitTime)
      FPF_NewVoiceParams    =1 shl 21;  // MUST BE USED - tell the host to use TVoiceParams instead of TVoiceParams_Old
      FPF_IsDelphi          =1 shl 22;  // tell if EditorHandle is a Delphi-made window, that can receive Delphi special messages (like CN_KeyDown for popup menus)
      FPF_CantSmartDisable  =1 shl 23;  // plugin can't be smart disabled
      FPF_WantSettingsBtn   =1 shl 24;  // plugin wants a settings button on the titlebar (mainly for the wrapper)


      // useful combo's
      FPF_Type_Effect       =0;     // for an effect (Eff_Render)
      FPF_Type_FullGen      =FPF_Generator or FPF_GetNoteInput or FPF_NewVoiceParams;  // for a full standalone generator (Gen_Render)
      FPF_Type_HybridGen    =FPF_Type_FullGen or FPF_UseSampler or FPF_NewVoiceParams;  // for an hybrid generator (Voice_Render)
      FPF_Type_Visual       =FPF_NoProcess;  // for a visual plugin that doesn't use the wave data


      // plugin dispatcher ID's
      // called from GUI thread unless specified
      FPD_ShowEditor        =0;     // shows the editor (ParentHandle in Value)
      FPD_ProcessMode       =1;     // sets processing mode flags (flags in value) (see PM_Normal) (can be ignored)
      FPD_Flush             =2;     // breaks continuity (empty delay buffers, filter mem, etc.) (warning: can be called from the mixing thread) (GM)
      FPD_SetBlockSize      =3;     // max processing length (samples) (in value)
      FPD_SetSampleRate     =4;     // sample rate in Value
      FPD_WindowMinMax      =5;     // allows the plugin to set the editor window resizable (min/max PRect in index, sizing snap PPoint in value)
      FPD_KillAVoice        =6;     // (in case the mixer was eating way too much CPU) the plugin is asked to kill its weakest voice & return 1 if it did something (not used yet)
      FPD_UseVoiceLevels    =7;     // return 0 if the plugin doesn't support the default per-voice level Index
                                    // return 1 if the plugin supports the default per-voice level Index (filter cutoff (0) or filter resonance (1))
                                    // return 2 if the plugin supports the per-voice level Index, but for another function (then check FPN_VoiceLevel)
      FPD_WrapPlugin        =8;     // (private message to the plugin wrapper) ask to open the plugin given in Value (PWrappedPluginID)
      FPD_SetPreset         =9;     // set internal preset Index (mainly for wrapper)
      FPD_ChanSampleChanged =10;    // (see FPF_GetChanCustomShape) sample has been loaded into the parent channel, & given to the plugin
                                    // either as a wavetable (FPF_GetChanCustomshape) (pointer to shape in Value, same format as WaveTables)
                                    // or as a sample (FPF_GetChanSample) (TSampleHandle in Index)
      FPD_SetEnabled        =11;    // the host has enabled/disabled the plugin (state in Value) (warning: can be called from the mixing thread) (GM)
      FPD_SetPlaying        =12;    // the host is playing (song pos info is valid when playing) (state in Value) (warning: can be called from the mixing thread) (GM)
      FPD_SongPosChanged    =13;    // song position has been relocated (by other means than by playing of course) (warning: can be called from the mixing thread) (GM)
      FPD_SetTimeSig        =14;    // PTimeSigInfo in Value (G)
      FPD_CollectFile       =15;    // let the plugin tell which files need to be collected or put in zip files. File # in Index, starts from 0 until no more filenames are returned (PAnsiChar in Result).
      FPD_SetInternalParam  =16;    // (private message to known plugins, ignore) tells the plugin to update a specific, non-automated param
      FPD_SetNumSends       =17;    // tells the plugin how many send tracks there are (fixed to 4, but could be set by the user at any time in a future update) (number in Value) (!!! will be 0 if the plugin is in the master or a send track, since it can't access sends)
      FPD_LoadFile          =18;    // when a file has been dropped onto the parent channel's button (filename in Value)
      FPD_SetFitTime        =19;    // set fit to time in beats (FLOAT time in value (need to typecast))
      FPD_SetSamplesPerTick =20;    // # of samples per tick (changes when tempo, PPQ or sample rate changes) (FLOAT in Value (need to typecast)) (warning: can be called from the mixing thread) (GM)
      FPD_SetIdleTime       =21;    // set the freq at which Idle is called (can vary), ms time in Value
      FPD_SetFocus          =22;    // the host has focused/unfocused the editor (focused in Value) (plugin can use this to steal keyboard focus)
      FPD_Transport         =23;    // special transport messages, from a controller. See GenericTransport.pas for Index. Must return 1 if handled.
      FPD_MIDIIn            =24;    // live MIDI input preview, allows the plugin to steal messages (mostly for transport purposes). Must return 1 if handled. Packed message (only note on/off for now) in Value.
      FPD_RoutingChanged    =25;    // mixer routing changed, must check FHD_GetInOuts if necessary
      FPD_GetParamInfo      =26;    // retrieves info about a parameter. Param number in Index, see PI_Float for the result
      FPD_ProjLoaded        =27;    // called after a project has been loaded, to leave a chance to kill automation (that could be loaded after the plugin is created) if necessary
      FPD_WrapperLoadState  =28;    // (private message to the plugin wrapper) load a (VST1, DX) plugin state, pointer in Index, length in Value
      FPD_ShowSettings      =29;    // called when the settings button on the titlebar is switched. On/off in Value (1=active). See FPF_WantSettingsBtn
      FPD_SetIOLatency      =30;    // input/output latency (Index,Value) of the output, in samples (only for information)
      FPD_WallpaperChanged  =31;    // sent on opening & whenever the host's background wallpaper has changed, window handle in Value, invalid if 0
      FPD_PreferredNumIO    =32;    // (message from Patcher) retrieves the preferred number (0=default, -1=none) of audio inputs (Index=0), audio outputs (Index=1) or voice outputs (Index=2)
      FPD_GetGUIColor       =33;    // retrieves the darkest background color of the GUI (Index=0 for background), for a nicer border around it


      // GetName sections
      FPN_Param             =0;     // retrieve name of param Index
      FPN_ParamValue        =1;     // retrieve text label of param Index for value Value (used in event editor)
      FPN_Semitone          =2;     // retrieve name of note Index (used in piano roll), for color (=MIDI channel) Value
      FPN_Patch             =3;     // retrieve name of patch Index (not used yet)
      FPN_VoiceLevel        =4;     // retrieve name of per-voice param Index (default is filter cutoff (0) & resonance (1)) (optional)
      FPN_VoiceLevelHint    =5;     // longer description for per-voice param (works like FPN_VoiceLevels)
      FPN_Preset            =6;     // for plugins that support internal presets (mainly for the wrapper plugin), retrieve the name for program Index
      FPN_OutCtrl           =7;     // for plugins that output controllers, retrieve the name of output controller Index
      FPN_VoiceColor        =8;     // retrieve name of per-voice color (MIDI channel) Index
      FPN_OutVoice          =9;     // for plugins that output voices, retrieve the name of output voice Index


      // processing mode flags
      PM_Normal             =0;     // realtime processing (default)
      PM_HQ_Realtime        =1;     // high quality, but still realtime processing
      PM_HQ_NonRealtime     =2;     // non realtime processing (CPU does not matter, quality does) (normally set when rendering only)
      PM_IsRendering        =16;    // is rendering if this flag is set
      //PM_IPMask             =7 shl 8;  // 3 bits value for interpolation quality (0=none (obsolete), 1=linear, 2=6 point hermite (default), 3=32 points sinc, 4=64 points sinc, 5=128 points sinc, 6=256 points sinc)
      PM_IPMask             =$FFFF shl 8;  // 16 bits value for interpolation number of points


      // ProcessParam flags
      REC_UpdateValue       =1;     // update the value
      REC_GetValue          =2;     // retrieves the value
      REC_ShowHint          =4;     // updates the hint (if any)
      REC_UpdateControl     =16;    // updates the wheel/knob
      REC_FromMIDI          =32;    // value from 0 to 65536 has to be translated (& always returned, even if REC_GetValue isn't set)
      REC_NoLink            =1024;  // don't check if wheels are linked (internal to plugins, useful for linked controls)
      REC_InternalCtrl      =2048;  // sent by an internal controller - internal controllers should pay attention to those, to avoid nasty feedbacks
      REC_PlugReserved      =4096;  // free to use by plugins

      // event ID's
      FPE_Tempo             =0;     // FLOAT tempo in value (need to typecast), & average samples per tick in Flags (DWORD) (warning: can be called from the mixing thread) (GM)
      FPE_MaxPoly           =1;     // max poly in value (infinite if <=0) (only interesting for standalone generators)
      // since MIDI plugins, or other plugin wrappers won't support the voice system, they should be notified about channel pan, vol & pitch changes
      FPE_MIDI_Pan          =2;     // MIDI channel panning (0..127) in EventValue + pan in -64..64 in Flags (warning: can be called from the mixing thread) (GM)
      FPE_MIDI_Vol          =3;     // MIDI channel volume (0..127) in EventValue + volume as normalized float in Flags (need to typecast) (warning: can be called from the mixing thread) (GM)
      FPE_MIDI_Pitch        =4;     // MIDI channel pitch in *cents* (to be translated according to current pitch bend range) in EventValue (warning: can be called from the mixing thread) (GM)

      // voice handles
      FVH_Null              =-1;

      // TFruityPlug.Voice_ProcessEvent ID's
      FPV_Retrigger         =0;     // monophonic mode can retrigger releasing voices (not used yet)

      // TFruityPlugHost.Voice_ProcessEvent ID's
      FPV_GetLength         =1;     // retrieve length in ticks (not reliable) in Result (-1 if undefined)
      FPV_GetColor          =2;     // retrieve color (0..15) in Result, can be mapped to MIDI channel
      FPV_GetVelocity       =3;     // retrieve note on velocity (0..1) in Result (typecast as a float) (this is computed from InitLevels.Vol)
      FPV_GetRelVelocity    =4;     // retrieve release velocity (0..1) in Result (typecast as a float) (to be called from Voice_Release) (use this if some release velocity mapping is involved)
      FPV_GetRelTime        =5;     // retrieve release time multiplicator (0..2) in Result (typecast as a float) (to be called from Voice_Release) (use this for direct release multiplicator)
      FPV_SetLinkVelocity   =6;     // set if velocity is linked to volume or not (in EventValue)
      FPV_GetInfo           =7;     // retrieve info about the voice (some of which also available above) (PVoiceInfo in EventValue)

      // TVoiceInfo.Flags
      VoiceInfo_FromPattern =1;     // voice is received from score, not played live

      // Voice_Render function results
      FVR_Ok                =0;
      FVR_NoMoreData        =1;     // for sample streaming, when there's no more sample data to fill any further buffer (the voice will then be killed by the host)




      // host dispatcher ID's
      FHD_ParamMenu         =0;     // the popup menu for each control (Index=param index, Value=popup item index (see FHP_EditEvents))
      FHD_GetParamMenuFlags =1;     // (OBSOLETE, see FHD_GetParamMenuEntry) before the popup menu is shown, you must ask the host to tell if items are checked or disabled (Index=param index, Value=popup item index, Result=flags (see FHP_Disabled))
      FHD_EditorResized     =2;     // to notify the host that the editor (EditorHandle) has been resized
      FHD_NamesChanged      =3;     // to notify the host that names (GetName function) have changed, with the type of names in Value (see FPN_Semitone)
      FHD_ActivateMIDI      =4;     // makes the host enable its MIDI output, useful when a MIDI out plugin is created (but not useful for plugin wrappers)
      FHD_WantMIDIInput     =5;     // plugin wants to be notified about MIDI messages (for processing or filtering) (switch in Value)
      FHD_WantMIDITick      =6;     // plugin wants to receive MIDITick events, allowing MIDI out plugins (not used yet)
      FHD_LocatePlugin      =7;     // (private msg from the plugin wrapper) ask the host to find a plugin back, pass the simple filename in Value, full path is returned as Result (both PAnsiChar). Set Index to 1 if you want host to show a warning if plugin could not be found.
      FHD_KillAutomation    =8;     // ask the host to kill the automation linked to the plugin, for params # between Index & Value (included) (can be used for a demo version of the plugin)
      FHD_SetNumPresets     =9;     // tell the host how many (Value) internal presets the plugin supports (mainly for wrapper)
      FHD_SetNewName        =10;    // sets a new short name for the parent (PAnsiChar in Value)
      FHD_VSTiIdle          =11;    // used by the VSTi wrapper, because the dumb VSTGUI needs idling for its knobs
      FHD_SelectChanSample  =12;    // ask the parent to open a selector for its channel sample (see FPF_UseChanSample)
      FHD_WantIdle          =13;    // plugin wants to receive the idle message (enabled by default) (Value=0 for disabled, 1 for enabled when UI is visible, 2 for always enabled)
      FHD_LocateDataFile    =14;    // ask the host to search for a file in its search paths, pass the simple filename in Value, full path is returned as Result (both PAnsiChar) (Result doesn't live long, please copy it asap). Set Index to 1 if you don't want FL to buffer the filename if it couldn't be found. 
      FHD_ShowPlugSelector  =15;    // (private msg from the plugin wrapper) ask the host to show the plugin selector (Index=1 to list effects, 2 to list generators)
      FHD_TicksToTime       =16;    // translate tick time (Value) into Bar:Step:Tick (PSongTime in Index) (warning: it's *not* Bar:Beat:Tick)
      FHD_AddNotesToPR      =17;    // add a note to the piano roll, PNotesParams in Value
      FHD_GetParamMenuEntry =18;    // before the popup menu is shown, you must fill it with the entries set by the host (Index=param index, Value=popup item index (starting from 0), Result=PParamMenuEntry, or null pointer if no more entry)
      FHD_MsgBox            =19;    // make FL show a message box (PAnsiChar in Index [formatted as 'Title|Message'], flags in Value (MB_OkCancel, MB_IconWarning, etc.), result in IDOk, IDCancel format (as in TApplication.MessageBox)
      FHD_NoteOn            =20;    // preview note on (semitone in Index low word, color in index high word (0=default), velocity in Value)
      FHD_NoteOff           =21;    // preview note off (semitone in Index)
      FHD_OnHint_Direct     =22;    // same as OnHint, but show it immediately (to show a progress while you're doing something) (PAnsiChar in Value)
      FHD_SetNewColor       =23;    // sets a new color for the parent (color in Value) (see FHD_SetNewName);
      FHD_GetInstance       =24;    // (Windows) returns the module instance of the host (could be an exe or a DLL, so not the process itself)
      FHD_KillIntCtrl       =25;    // ask the host to kill anything linked to an internal controller, for # between Index & Value (included) (used when undeclaring internal controllers)
      FHD_CheckProdCode     =26;    // reserved
      FHD_SetNumParams      =27;    // override the # of parameters (for plugins that have a different set of parameters per instance) (number of parameters in Value)
      FHD_PackDataFile      =28;    // ask the host to pack an absolute filename into a local filemane, pass the simple filename in Value, packed path is returned as Result (both PAnsiChar) (Result doesn't live long, please copy it asap)
      FHD_GetProgPath       =29;    // ask the host where the engine is, which may NOT be where the executable is, but where the data path will be (returned as Result)
      FHD_SetLatency        =30;    // set plugin latency, if any (samples in Value)
      FHD_CallDownloader    =31;    // call the presets downloader (optional plugin name PAnsiChar in Value)
      FHD_EditSample        =32;    // edits sample in Edison (PAnsiChar in Value, Index=1 means an existing Edison can be re-used)
      FHD_SetThreadSafe     =33;    // plugin is thread-safe, doing its own thread-sync using LockMix_Shared (switch in Value)
      FHD_SmartDisable      =34;    // plugin asks FL to exit or enter smart disabling (if currently active), mainly for generators when they get MIDI input (switch in Value)
      FHD_SetUID            =35;    // sets a unique identifying AnsiString for this plugin. This will be used to save/restore custom data related to this plugin. Handy for wrapper plugins. (PAnsiChar in Value)
      FHD_GetMixingTime     =36;    // get mixer time, Index is the time format required (0 for Beats, 1 for absolute ms, 2 for running ms, 3 for ms since soundcard restart), Value is a pointer to a TFPTime, which is filled with an optional offset in samples
      FHD_GetPlaybackTime   =37;    // get playback time, same as above
      FHD_GetSelTime        =38;    // get selection time in t & t2, same as above. Returns 0 if no selection (t & t2 are then filled with full song length).
      FHD_GetTimeMul        =39;    // get current tempo multiplicator, that's not part of the song but used for fast-forward
      FHD_Captionize        =40;    // captionize the plugin (useful when dragging) (captionized in Value)
      FHD_SendSysEx         =41;    // send a SysEx AnsiString (pointer to array in Value, the first integer being the length of the AnsiString, the rest being the AnsiString), through port Index, immediately (do not abuse)
      FHD_LoadAudioClip     =42;    // send an audio file to the playlist as an audio clip, starting at the playlist selection (mainly for Edison), FileName as PAnsiChar in Value
      FHD_LoadInChannel     =43;    // send a file to the selected channel(s) (mainly for Edison), FileName as PAnsiChar in Value
      FHD_ShowInBrowser     =44;    // locates the file in the browser & jumps to it (PAnsiChar in Value)
      FHD_DebugLogMsg       =45;    // adds message to the debug log (PAnsiChar in Value)
      FHD_GetMainFormHandle =46;    // gets the handle of the main form (HWND in Value, 0 if none)
      FHD_GetProjDataPath   =47;    // ask the host where the project data is, to store project data (returned as Result)
      FHD_SetDirty          =48;    // mark project as dirty (not required for automatable parameters, only for tweaks the host can't be aware of)
      FHD_AddToRecent       =49;    // add file to recent files (PAnsiChar in Value)
      FHD_GetNumInOut       =50;    // ask the host how many inputs (Index=0) are routed to this effect (see GetInBuffer), or how many outputs (Index=1) this effect is routed to (see GetOutBuffer)
      FHD_GetInName         =51;    // ask the host the name of the input Index (!!! first = 1), in Value as a PNameColor, Result=0 if failed (Index out of range)
      FHD_GetOutName        =52;    // ask the host the name of the ouput Index (!!! first = 1), in Value as a PNameColor, Result=0 if failed (Index out of range)
      FHD_ShowEditor        =53;    // make host bring plugin's editor (visibility in Value, -1 to toggle)
      FHD_FloatAutomation   =54;    // (for the plugin wrapper only) ask the host to turn 0..65536 automation into 0..1 float, for params # between Index & Value (included)
      FHD_ShowSettings      =55;    // called when the settings button on the titlebar should be updated switched. On/off in Value (1=active). See FPF_WantSettingsBtn
      FHD_NoteOnOff         =56;    // note on/off (semitone in Index low word, color in index high word, NOT recorded in bit 30, velocity in Value (<=0 = note off))
      FHD_ShowPicker        =57;    // show picker (mode [0=plugins, 1=project] in Index, categories [gen=0/FX=1/both=-1/Patcher (includes VFX)=-2] in Value)
      FHD_GetIdleOverflow   =58;    // ask the host for the # of extra frames Idle should process, generally 0 if no overflow/frameskip occured
      FHD_ModalIdle         =59;    // used by FL plugins, when idling from a modal window, mainly for the smoothness hack
      FHD_RenderProject     =60;    // prompt the rendering dialog in song mode
      FHD_GetProjectInfo    =61;    // get project title, author, comments, URL (Index), (returned as Result as a *PWideChar*)


      // param popup menu item indexes (same order as param menu in FruityLoops)
      // note that it can be a Windows popup menu or anything else
      // OBSOLETE (compatibility only): now the plugin doesn't know about those menu entries, that can be freely changed by the host
      {
      FHP_Edit              =0;     // Edit events
      FHP_EditNewWindow     =1;     // Edit events in new window
      FHP_Init              =2;     // Init with this position
      FHP_Link              =3;     // Link to MIDI controller
      }

      // param popup menu item flags
      FHP_Disabled          =1;
      FHP_Checked           =2;

      // sample loading flags
      FHLS_ShowDialog       =1;     // tells the sample loader to show an open box, for the user to select a sample
      FHLS_ForceReload      =2;     // force it to be reloaded, even if the filename is the same (in case you modified the sample)
      FHLS_GetName          =4;     // don't load the sample, instead get its filename & make sure that the format is correct (useful after FPD_ChanSampleChanged)
      FHLS_NoResampling     =8;     // don't resample to the host sample rate

      // TNotesParams flags
      NPF_EmptyFirst        =1;     // delete everything before adding the notes
      NPF_UseSelection      =2;     // dump inside piano roll selection if any

      // param flags (see FPD_GetParamInfo)
      PI_CantInterpolate    =1;     // makes no sense to interpolate parameter values (when values are not levels)
      PI_Float              =2;     // parameter is a normalized (0..1) single float. (Integer otherwise)
      PI_Centered           =4;     // parameter appears centered in event editors

      // GetInBuffer / GetOutBuffer flags
      // input
      IO_Lock               =0;     // GetOutBuffer, before adding to the buffer
      IO_Unlock             =1;     // GetOutBuffer, after adding to the buffer
      // output
      IO_Filled             =1;     // GetInBuffer, tells if the buffer is filled








implementation


// destroy the object
procedure TFruityPlug.DestroyObject;
Begin
Destroy;
End;




end.




