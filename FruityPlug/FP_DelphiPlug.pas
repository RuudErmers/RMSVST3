{

FruityLoops/FL Studio generator/effect plugins SDK
Delphi object extension
handy functions for easier implementation of a Fruity plugin under Delphi

(99-14) gol


notes:
-define UseCriticalSection if you need it

!!! warning: DO NOT ever set the ShowHint property to True for *any* windowed component in a Fruity plugin !!!

}


{{$DEFINE UseCriticalSection}


unit FP_DelphiPlug;


interface

uses Windows, Forms, Controls, SysUtils, ActiveX, Classes, Menus,
     FP_PlugClass;




type  TDelphiFruityPlug=class(TFruityPlug)
          PlugHost    :TFruityPlugHost;
          EditorForm  :TForm;
          SmpRate     :Integer;
          MaxPoly     :Integer;
          PitchMul    :Single;
          LastOnHint  :TNotifyEvent;
          ProgPath    :AnsiString;

          {$IFDEF UseCriticalSection}
          ThreadSafeCS:TRTLCriticalSection;
          {$ENDIF}

          procedure   DestroyObject; override;
          procedure   Idle_Public; override;  // obsolete, the plugin now does its own idling
          function    ProcessEvent(EventID,EventValue,Flags:Integer):Integer; override;

          // internal
          function    GetStep_Cents(Pitch:Integer):Integer;
          function    GetStep_Cents_S(Pitch:Single):Integer;
          function    GetStep_Freq (Freq :Integer):Integer;
          procedure   ProcessAllParams; inline;
          procedure   SkipRendering(SourceBuffer,DestBuffer:Pointer;Length:Integer);
          constructor Create(SetHostTag:Integer;SetPlugHost:TFruityPlugHost);

          // hints
          procedure   OnHint(Sender:TObject);

          procedure   ShowHintMsg(const Msg:AnsiString); virtual;
          procedure   ShowHintMsg_Direct(const Msg:AnsiString);
          procedure   ShowHintMsg_Percent(Value,Max:Integer);
          procedure   ShowHintMsg_Pitch(Value,PitchType:Integer); overload;
          procedure   ShowHintMsg_Pitch(Value:Single;PitchType:Integer;Digits:Integer=2); overload;
          procedure   ShowHintMsg_Pan(Value:Integer);
          procedure   ShowHintMsg_Time(Value:Integer);
          procedure   ShowHintMsg_Gauge(const Msg:AnsiString;Value,Max:Integer);

          // param popup
          procedure   AdjustParamPopup(PopupItem:TMenuItem;ParamNum,FirstItemIndex:Integer;SetOnClick:TNotifyEvent);
          // in/out
          procedure   AdjustInOutPopup(PopupItem:TMenuItem;Flags,CurrentIndex,FirstItemIndex:Integer;SetOnClick:TNotifyEvent);

          {$IFDEF UseCriticalSection}
          // thread synchronisation / safety
          function    TryLock:Boolean; inline;
          procedure   Lock; inline;
          procedure   Unlock; inline;
          {$ENDIF}

          procedure LockMix_Shared;
          procedure UnlockMix_Shared;

          procedure   Idle; virtual;
        End;




var   PluginPath:AnsiString;  // path to this DLL plugin (for loading of resources)

const AbsPPN=192 div 4;  // 192 PPQ

      // see ShowHintMsg_Pitch
      PT_Octaves  =-1;
      PT_Semitones=0;
      PT_Cents    =1;
      PT_Hz       =2;


procedure GetPluginPath;
procedure Stream_ReadString(const Stream:IStream;var s:AnsiString);
procedure Stream_ReadUString(const Stream:IStream;var s:String);
procedure Stream_StoreString(const Stream:IStream;const s:AnsiString);
procedure Stream_StoreUString(const Stream:IStream;const s:String);
procedure TStream_ReadUString(const Stream:TStream;var s:String);
procedure TStream_StoreUString(const Stream:TStream;const s:String);
function  TranslateMIDI(Value,Min,Max:Integer):Integer;
function  CleanHintStr(const s:AnsiString):AnsiString;








implementation

uses FP_Extra;

{ TDelphiFruityPlug }

// create the object
constructor TDelphiFruityPlug.Create;
Begin
Inherited Create;

HostTag :=SetHostTag;
PlugHost:=SetPlugHost;

with Application do
  Begin
  Handle:=PlugHost.AppHandle;
  LastOnHint:=OnHint;
  OnHint:=Self.OnHint;
  End;

{$IFDEF UseCriticalSection}
InitializeCriticalSection(ThreadSafeCS);
{$ENDIF}

SmpRate:=MixSmpRate_Default;
ProgPath:=PAnsiChar(PlugHost.Dispatcher(HostTag,FHD_GetProgPath,0,0));
End;


procedure TDelphiFruityPlug.DestroyObject;
Begin
{$IFDEF UseCriticalSection}
DeleteCriticalSection(ThreadSafeCS);
{$ENDIF}
Application.OnHint:=LastOnHint;
if EditorForm <> nil then
    Begin
    EditorForm.Free;
    EditorForm := nil;
    End;
Inherited;
End;


// events
function TDelphiFruityPlug.ProcessEvent(EventID,EventValue,Flags:Integer):Integer;
Begin
Result:=0;
Case EventID of
     FPE_MaxPoly:MaxPoly:=EventValue;
  End;
End;


procedure TDelphiFruityPlug.ProcessAllParams;
var   n:Integer;
Begin
for n:=0 to Info^.NumParams-1 do
  ProcessParam(n,ProcessParam(n,0,REC_GetValue),REC_UpdateValue or REC_UpdateControl);
End;


// to safely skip a rendering (for plugins that don't render)
procedure TDelphiFruityPlug.SkipRendering(SourceBuffer,DestBuffer:Pointer;Length:Integer);
Begin
if SourceBuffer<>DestBuffer then MoveMemory(DestBuffer, SourceBuffer, Length shl 3);
End;


// get the speed step to go through the LFO table at a given pitch (cents) (tuned around C5)
function TDelphiFruityPlug.GetStep_Cents(Pitch:Integer):Integer;
Begin
Result:=Round(PitchMul*Exp(Pitch*NoteMul));
End;

// get the speed step to go through the LFO table at a given pitch (cents) (tuned around C5)
function TDelphiFruityPlug.GetStep_Cents_S(Pitch:Single):Integer;
Begin
Result:=Round(PitchMul*Exp(Pitch*NoteMul));
End;

{$IFDEF CPUX64}
function GetStep_Freq_Asm1(n,freq : integer) : integer;
Asm
    XOR   EAX,EAX
    DIV   ECX
End;
{$ENDIF}

function TDelphiFruityPlug.GetStep_Freq(Freq:Integer):Integer;
var   n:Integer;
Begin
n:=SmpRate;
{$IFDEF CPUX64}
n := GetStep_Freq_Asm1(n,freq);
{$ELSE}
Asm
    MOV   ECX,n
    XOR   EAX,EAX
    MOV   EDX,Freq
    DIV   ECX
    MOV   n,EAX
End;
{$ENDIF}
Result:=n;
End;




{$IFDEF UseCriticalSection}
// thread synchronization for safety
function TDelphiFruityPlug.TryLock:Boolean;
Begin
Result:=TryEnterCriticalSection(ThreadSafeCS);
End;

procedure TDelphiFruityPlug.Lock;
Begin
EnterCriticalSection(ThreadSafeCS);
End;

procedure TDelphiFruityPlug.Unlock;
Begin
LeaveCriticalSection(ThreadSafeCS);
End;
{$ENDIF}


// hints
procedure TDelphiFruityPlug.ShowHintMsg(const Msg:AnsiString);
Begin
PlugHost.OnHint(HostTag,PAnsiChar(Msg));
End;

procedure TDelphiFruityPlug.ShowHintMsg_Direct(const Msg:AnsiString);
Begin
PlugHost.Dispatcher(HostTag,FHD_OnHint_Direct,0,IntPtr(PAnsiChar(Msg)));
End;

procedure TDelphiFruityPlug.ShowHintMsg_Percent(Value,Max:Integer);
Begin
ShowHintMsg(IntToStr(Value*100 div Max)+'%');
End;

const PitchTypeT:Array[-1..2] of AnsiString=(' octave',' semitone',' cent',' Hz');

procedure TDelphiFruityPlug.ShowHintMsg_Pitch(Value,PitchType:Integer);
var   Msg:string;
Begin
Msg:=IntToStr(Value)+PitchTypeT[PitchType];
if Value>=0 then Msg:='+'+Msg;
if (Abs(Value)>1) and (PitchType<2) then Msg:=Msg+'s';
ShowHintMsg(Msg);
End;

procedure TDelphiFruityPlug.ShowHintMsg_Pitch(Value:Single;PitchType:Integer;Digits:Integer=2);
var   Msg:string;
Begin
Msg:=FloatToStrF(Value,ffFixed,15,Digits)+PitchTypeT[PitchType];
if Value>=0 then Msg:='+'+Msg;
if (Abs(Value)>1) and (PitchType<2) then Msg:=Msg+'s';
ShowHintMsg(Msg);
End;

procedure TDelphiFruityPlug.ShowHintMsg_Pan(Value:Integer);
var   Msg:AnsiString;
      n:Integer;
begin
n:=Round(Value*(100/64));
if n=0 then Msg:='Centered'
       else
   Begin
   Msg:=IntToStr(Abs(n))+'% ';
   if n<0 then Msg:=Msg+'left'
          else Msg:=Msg+'right';
   End;
ShowHintMsg(Msg);
End;

// show the time in 0:00 format at 192 PPQ
procedure TDelphiFruityPlug.ShowHintMsg_Time(Value:Integer);
var   Msg:AnsiString;
Begin
Msg:=IntToStr(Value div AbsPPN)+':'+Zeros(Value mod AbsPPN,2);
ShowHintMsg(Msg);
End;

// show a progression gauge
const HintPBMax  =20;  // 20 steps for the hint progress bar
      HintPBFirst=Ord('a');
      HintPBLast =HintPBFirst+HintPBMax;

procedure TDelphiFruityPlug.ShowHintMsg_Gauge(const Msg:AnsiString;Value,Max:Integer);
var   s:AnsiString;
Begin
s:='^.'+Char(HintPBFirst+MulDiv64(Value,HintPBMax,MaxOf(Max,1)))+Msg;
ShowHintMsg_Direct(s);
End;




// adjust a common param popup
// changed in SDK version 1
procedure TDelphiFruityPlug.AdjustParamPopup(PopupItem:TMenuItem;ParamNum,FirstItemIndex:Integer;SetOnClick:TNotifyEvent);
var   n:Integer;
      MenuEntry:PParamMenuEntry;
      NewItem:TMenuItem;
Begin
with PopupItem do
  Begin
  // we don't need the first separator anymore
  if (FirstItemIndex>0) and Items[FirstItemIndex-1].IsLine then Items[FirstItemIndex-1].Visible:=False;

  // delete the old entries
  while Count>FirstItemIndex do Delete(Count-1);
  // add (append) new ones
  n:=0;
  Repeat
      // get menu entry
      MenuEntry:=PParamMenuEntry(PlugHost.Dispatcher(HostTag,FHD_GetParamMenuEntry,ParamNum,n));
      if Assigned(MenuEntry) then with MenuEntry^ do
         Begin
         // create, fill & add item
         NewItem:=TMenuItem.Create(PopupItem);
         NewItem.Caption:=Name;
         NewItem.Tag    :=n;
         NewItem.Checked:=Flags and FHP_Checked<>0;
         NewItem.Enabled:=Flags and FHP_Disabled=0;
         NewItem.OnClick:=SetOnClick;
         Add(NewItem);
         inc(n);
         End;
    Until not Assigned(MenuEntry);
  End;
End;


// adjust an input/output popup
// flags=0 for input, 1 for output
// CurrentIndex is existing in/out index, or zero if none
procedure TDelphiFruityPlug.AdjustInOutPopup(PopupItem:TMenuItem;Flags,CurrentIndex,FirstItemIndex:Integer;SetOnClick:TNotifyEvent);
var   n,m,nMax:Integer;
      NameColor:TNameColor;
      NewItem:TMenuItem;
Begin
with PopupItem do
  Begin
  // delete the old entries
  while Count>FirstItemIndex do Delete(Count-1);
  // add (append) new ones
  nMax:=PlugHost.Dispatcher(HostTag,FHD_GetNumInOut,Flags,0);
  for n:=-nMax to nMax do
    Begin
    // get in/out info
    if n=0 then
       Begin
       NameColor.Name:='(none)';
       NameColor.VisName:=NameColor.Name;
       m:=1;
       End
           else
       m:=PlugHost.Dispatcher(HostTag,FHD_GetInName+Flags,n,IntPtr(@NameColor));
    if m>0 then
       Begin
       // create, fill & add item
       NewItem:=TMenuItem.Create(PopupItem);
       NewItem.Caption:=NameColor.VisName;
       NewItem.Tag    :=n;
       NewItem.Default:=n=CurrentIndex;
       NewItem.OnClick:=SetOnClick;
       Add(NewItem);
       End;
    End;
  End;
End;


procedure TDelphiFruityPlug.Idle_Public;
Begin
End;

procedure TDelphiFruityPlug.Idle;
Begin
End;


procedure TDelphiFruityPlug.OnHint(Sender:TObject);
var   s:AnsiString;
Begin
s:=GetLongHint(Application.Hint);
PlugHost.OnHint(HostTag,PAnsiChar(s));
End;


procedure TDelphiFruityPlug.LockMix_Shared;
var   OBuffer:TIOBuffer;
Begin
OBuffer.Flags:=IO_Lock;
PlugHost.GetOutBuffer(HostTag,0,@OBuffer);
End;

procedure TDelphiFruityPlug.UnlockMix_Shared;
var   OBuffer:TIOBuffer;
Begin
OBuffer.Flags:=IO_Unlock;
PlugHost.GetOutBuffer(HostTag,0,@OBuffer);
End;


// getting the current plugin's path
procedure GetPluginPath;
var   p:Array[0..Max_Path] of AnsiChar;
Begin
GetModuleFileNameA(HInstance,@p,Max_Path);   // reflex (11): use 'A' version
PluginPath:=ExtractFilePath(p);
End;


// storing strings in the plugin's state
procedure Stream_ReadString(const Stream:IStream;var s:AnsiString);
var   l:DWORD;
      b:Byte;
Begin
Stream.Read(@b,1,Nil);
if b=255 then Stream.Read(@l,4,Nil)
         else l:=b;
SetLength(s,l);
if s<>'' then
   Begin
   Stream.Read(Pointer(s),l,Nil);
   s[l+1]:=#0;  // ensure null-terminated (yes s[l+1] is valid)
   // because of an old bug, check the integrity of the AnsiString
   while (Length(s)>0) and (s[Length(s)]<#32) do SetLength(s,Length(s)-1);
   End;
End;

procedure Stream_ReadUString(const Stream:IStream;var s:String);
var   l:DWORD;
      b:Byte;
Begin
Stream.Read(@b,1,Nil);
if b=255 then Stream.Read(@l,4,Nil)
         else l:=b;
SetLength(s,l);
if s<>'' then
   Begin
   Stream.Read(Pointer(s),l*SizeOf(Char),Nil);
   s[l+1]:=#0;  // ensure null-terminated (yes s[l+1] is valid)
   End;
End;

procedure Stream_StoreString(const Stream:IStream;const s:AnsiString);
var   l:DWORD;
      b:Byte;
Begin
l:=Length(s);
if l>=255 then
   Begin
   b:=255;
   Stream.Write(@b,1,Nil);  // tells that a 32Bit length follows
   Stream.Write(@l,4,Nil);  // 32Bit length
   End
          else
   Stream.Write(@l,1,Nil);  // 8Bit length
Stream.Write(Pointer(s),l,Nil);
End;

procedure Stream_StoreUString(const Stream:IStream;const s:String);
var   l:DWORD;
      b:Byte;
Begin
l:=Length(s);
if l>=255 then
   Begin
   b:=255;
   Stream.Write(@b,1,Nil);  // tells that a 32Bit length follows
   Stream.Write(@l,4,Nil);  // 32Bit length
   End
          else
   Stream.Write(@l,1,Nil);  // 8Bit length
Stream.Write(Pointer(s),l*SizeOf(Char),Nil);
End;


procedure TStream_ReadUString(const Stream:TStream;var s:String);
var   l:DWORD;
      b:Byte;
Begin
Stream.Read(b,1);
if b=255 then Stream.Read(l,4)
         else l:=b;
SetLength(s,l);
if s<>'' then
   Begin
   Stream.Read(s[1],l*SizeOf(Char));
   s[l+1]:=#0;  // ensure null-terminated (yes s[l+1] is valid)
   End;
End;

procedure TStream_StoreUString(const Stream:TStream;const s:String);
var   l:DWORD;
      b:Byte;
Begin
l:=Length(s);
if l>=255 then
   Begin
   b:=255;
   Stream.Write(b,1);  // tells that a 32Bit length follows
   Stream.Write(l,4);  // 32Bit length
   End
          else
   Stream.Write(l,1);  // 8Bit length
Stream.Write(s[1],l*SizeOf(Char));
End;


// translate a controller value (0..65536)
function TranslateMIDI(Value,Min,Max:Integer):Integer;
Begin
Result:=MinOf(Min+MulShift16(Value,Max-Min+1),Max);
End;


// clean the control chars in a hint AnsiString
function CleanHintStr(const s:AnsiString):AnsiString;
var   c,p:Integer;
const SCChar='^';  // special command (followed by one of the chars listed below)
      KSChar='^';  // keyboard shortcut
      BMChar='_';  // big hint bar message (will not appear on the normal hint bar)
      LMChar='`';  // long hint bar message (will not appear on the normal hint bar)
Begin
Result:=s;
while (Length(Result)>=2) and (Result[1]=SCChar) do
  Begin
  c:=Ord(Result[2]);
  Case c of
       // keyboard shortcut
       Ord(KSChar),Ord(BMChar),Ord(LMChar):
         Begin
         Delete(Result,1,2);
         p:=Pos(SCChar,Result);
         if p>0 then Delete(Result,1,p);
         End;
       // icons
       Else
         Delete(Result,1,2);
    End;
  End;
End;



initialization
IsMultiThread:=True;
SetMinimumBlockAlignment(mba16Byte);  // needed for some SSE stuff
GetPluginPath;
FormatSettings.DecimalSeparator:='.';

finalization
Application.Handle:=0;  // does something weird (minimizes the host app) without this

end.
