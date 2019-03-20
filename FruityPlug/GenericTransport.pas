{

generic transport, mainly for FL Studio

(07) gol

}


unit GenericTransport;


interface

uses Windows;


type  TTransportMsg=Packed Record
          Msg   :Cardinal;
          Index :Longint;
          Value :Longint;
          Result:Longint;  // 1 if handled
        End;


const // see FPD_Transport
      // (button) means: 0 for release, 1 for switch (if release is not supported), 2 for hold (if release should be expected)
      // (hold) means: 0 for release, 2 for hold
      // (jog) means: value is an integer increment
      // if FPT_Jog, FPT_StripJog, FPT_MarkerJumpJog, FPT_MarkerSelJog, FPT_Previous or FPT_Next don't answer, FPT_PreviousNext will be tried. So it's best to implement at least FPT_PreviousNext
      // if FPT_PunchIn or FPT_PunchOut don't answer, FPT_Punch will be tried
      // if FPT_UndoUp doesn't answer, FPT_UndoJog will be tried
      // if FPT_AddAltMarker doesn't answer, FPT_AddMarker will be tried
      // if FPT_Cut, FPT_Copy, FPT_Paste, FPT_Insert, FPT_Delete, FPT_NextWindow, FPT_Enter, FPT_Escape, FPT_Yes, FPT_No, FPT_Fx don't answer, standard keystrokes will be simulated
      FPT_Jog               =0;     // (jog) generic jog (can be used to select stuff)
      FPT_Jog2              =1;     // (jog) alternate generic jog (can be used to relocate stuff)
      FPT_Strip             =2;     // touch-sensitive jog strip, value will be in -65536..65536 for leftmost..rightmost
      FPT_StripJog          =3;     // (jog) touch-sensitive jog in jog mode
      FPT_StripHold         =4;     // value will be 0 for release, 1,2 for 1,2 fingers centered mode, -1,-2 for 1,2 fingers jog mode (will then send FPT_StripJog)
      FPT_Previous          =5;     // (button)
      FPT_Next              =6;     // (button)
      FPT_PreviousNext      =7;     // (jog) generic track selection
      FPT_MoveJog           =8;     // (jog) used to relocate items

      FPT_Play              =10;    // (button) play/pause
      FPT_Stop              =11;    // (button)
      FPT_Record            =12;    // (button)
      FPT_Rewind            =13;    // (hold)
      FPT_FastForward       =14;    // (hold)
      FPT_Loop              =15;    // (button)
      FPT_Mute              =16;    // (button)
      FPT_Mode              =17;    // (button) generic or record mode

      FPT_Undo              =20;    // (button) undo/redo last, or undo down in history
      FPT_UndoUp            =21;    // (button) undo up in history (no need to implement if no undo history)
      FPT_UndoJog           =22;    // (jog) undo in history (no need to implement if no undo history)

      FPT_Punch             =30;    // (hold) live selection
      FPT_PunchIn           =31;    // (button)
      FPT_PunchOut          =32;    // (button)
      FPT_AddMarker         =33;    // (button)
      FPT_AddAltMarker      =34;    // (button) add alternate marker
      FPT_MarkerJumpJog     =35;    // (jog) marker jump
      FPT_MarkerSelJog      =36;    // (jog) marker selection

      FPT_Up                =40;    // (button)
      FPT_Down              =41;    // (button)
      FPT_Left              =42;    // (button)
      FPT_Right             =43;    // (button)
      FPT_HZoomJog          =44;    // (jog)
      FPT_VZoomJog          =45;    // (jog)
      FPT_Snap              =48;    // (button) snap on/off
      FPT_SnapMode          =49;    // (jog) snap mode

      FPT_Cut               =50;    // (button)
      FPT_Copy              =51;    // (button)
      FPT_Paste             =52;    // (button)
      FPT_Insert            =53;    // (button)
      FPT_Delete            =54;    // (button)
      FPT_NextWindow        =58;    // (button) TAB
      FPT_WindowJog         =59;    // (jog) window selection

      FPT_F1                =60;    // button
      FPT_F2                =61;    // button
      FPT_F3                =62;    // button
      FPT_F4                =63;    // button
      FPT_F5                =64;    // button
      FPT_F6                =65;    // button
      FPT_F7                =66;    // button
      FPT_F8                =67;    // button
      FPT_F9                =68;    // button
      FPT_F10               =69;    // button

      FPT_Enter             =80;    // (button) enter/accept
      FPT_Escape            =81;    // (button) escape/cancel
      FPT_Yes               =82;    // (button) yes
      FPT_No                =83;    // (button) no

      FPT_Menu              =90;    // (button) generic menu
      FPT_ItemMenu          =91;    // (button) item edit/tool/contextual menu
      FPT_Save              =92;    // (button)
      FPT_SaveNew           =93;    // (button) save as new version




      FPTToVK_Arrows:Array[FPT_Up..FPT_Right] of Integer=(VK_Up,VK_Down,VK_Left,VK_Right);








implementation

end.
