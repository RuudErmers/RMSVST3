{

a couple of def for the Fruity Plugin SDK

(00) gol

}


unit FP_Def;


interface

uses MMSystem;


const WaveT_Bits =14;  // 14 bits for the length of the wavetable
      WaveT_Size =1 shl WaveT_Bits;  // length of the wavetable
      WaveT_Shift=32-WaveT_Bits;  // shift for full DWORD conversion
      WaveT_Step =1 shl WaveT_Shift;  // speed for 1 sample in the wavetable
      WaveT_PMask=$FFFFFFFF shr WaveT_Shift;  // mask to limit the position to the range of the wavetable
      WaveT_FMask=$FFFFFFFF shr WaveT_Bits;  // mask to get the frac part of the position

      MIDIMsg_PortMask=$FFFFFF;
      MIDIMsg_Null    =$FFFFFFFF;

      FromMIDI_Max=65536;  // see REC_FromMIDI
      FromMIDI_Half=FromMIDI_Max shr 1;




type  // published wavetables
      TWaveT=Array[0..WaveT_Size-1] of Single;
      PWaveT=^TWaveT;

      // interlaced stereo 32Bit float buffer
      TWAV32FS=Array[0..0,0..1] of Single;
      PWAV32FS=^TWAV32FS;

      TWAV32FM=Array[0..0] of Single;
      PWAV32FM=^TWAV32FM;

      // MIDI out message structure (3 bytes standard MIDI message + port)
      TMIDIOutMsg=Packed Record
          Status,Data1,Data2,Port:Byte;
        End;
      PMIDIOutMsg=^TMIDIOutMsg;  

      // for the wrapper only
      TWrappedPluginID=Packed Record
          PlugClass:Integer;
          Name,FileName:PAnsiChar;
          ID:PGUID;
        End;
      PWrappedPluginID=^TWrappedPluginID;

      // extended wav format
      PWaveFormatExtensible=^TWaveFormatExtensible;
      TWaveFormatExtensible=Packed Record
          WaveFormatEx:TWaveFormatEx;
          Case Integer of
               0:(
                 wValidBitsPerSample:Word;    // bits of precision
                 dwChannelMask:LongWord;         // which channels are present in stream
                 SubFormat:TGUID;
                 );
               1:(wSamplesPerBlock:Word);     // valid if wBitsPerSample==0
               2:(wReserved:Word);            // if neither applies, set to zero
        End;

      // Bar:Step:Tick
      TSongTime=Record
          Bar,Step,Tick:Integer;
        End;
      PSongTime=^TSongTime;

      // time sig info (easily converted to standard x/x time sig, but more powerful)
      TTimeSigInfo=Record
          StepsPerBar,StepsPerBeat,PPQ:Integer;
        End;
      PTimeSigInfo=^TTimeSigInfo;




implementation


end.
