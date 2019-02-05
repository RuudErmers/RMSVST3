//-----------------------------------------------------------------------------
// Project     : SDK Core
// Version     : 3.5.2
//
// Category    : SDK Core Interfaces
// Created by  : Steinberg, 08/2012
// Description : Basic Interface
//
//-----------------------------------------------------------------------------
// LICENSE
// © 2012, Steinberg Media Technologies GmbH, All Rights Reserved
//-----------------------------------------------------------------------------
// This Software Development Kit may not be distributed in parts or its entirety
// without prior written agreement by Steinberg Media Technologies GmbH.
// This SDK must not be used to re-engineer or manipulate any technology used
// in any Steinberg or Third-party application or software module,
// unless permitted by law.
// Neither the name of the Steinberg Media Technologies nor the names of its
// contributors may be used to endorse or promote products derived from this
// software without specific prior written permission.
//
// THIS SDK IS PROVIDED BY STEINBERG MEDIA TECHNOLOGIES GMBH "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//
// IN NO EVENT SHALL STEINBERG MEDIA TECHNOLOGIES GMBH BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
// OF THE POSSIBILITY OF SUCH DAMAGE.
//------------------------------------------------------------------------------
//
//  Translation to Delphi
//  Version         :  1.2.0
//  VST sdk version :  3.5.2
//  Date            :  2013/09/20
//  Author          :  Frederic Vanmol
//  Web             :  www.axiworld.be
//  E-mail          :  info@axiworld.be
//
//  Translated files
//  - ftypes.h
//  - funknown.h
//  - ibstream.h
//  - ipluginbase.h
//  - iplugview.h
//  - ivstaudioprocessor.h
//  - ivstcomponent.h
//  - ivstcontextmenu.h
//  - ivsteditcontroller.h
//  - ivstevents.h
//  - ivsthostapplication.h
//  - ivstmessage.h
//  - ivstmidicontrollers.h
//  - ivstnoteexpression.h
//  - ivstparameterchanges.h
//  - ivstprocesscontext.h
//  - ivstrepresentation.h
//  - ivstunits.h
//  - keycodes.h
//  - ustring.h
//  - vstpresetkeys.h
//  - vsttypes.h
//
//------------------------------------------------------------------------------

{$IFDEF FPC}
  {$INTERFACES Corba}
{$ENDIF}

unit Vst3Base;

interface
{$ALIGN 8}  // sdk uses 16 for x64, but it works like this???
            // IMPORTANT: also change specific alignments further down if this one changes!

(***************
    FTYPES.H
****************)

// intergral types
// -----------------------------------------------------------------
type
    int8    = shortint;
    uint8   = byte;
    uchar   = AnsiChar;
    char8   = AnsiChar;
    int16   = smallint;
    uint16  = word;
    int32   = longint;
    uint32  = longword;
    //int64   = int64;
    uint64  = int64;   // no unsigned int64 in Delphi, right?

    // pointers
    pint8    = ^int8;
    puint8   = ^uint8;
    puchar   = ^uchar;
    pchar8   = ^char8;
    pint16   = ^int16;
    puint16  = ^uint16;
    pint32   = ^int32;
    puint32  = ^uint32;
    pint64   = ^int64;
    puint64  = ^int64;

const
	   kMaxLong   = $7fffffff;
     kMinLong   = -$7fffffff-1;
     kMaxInt32  = kMaxLong;
     kMinInt32  = kMinLong;
     kMaxInt32u = $ffffffff;
     kMaxInt64  = 9223372036854775807;
     kMinInt64  = -9223372036854775807-1;
     kMaxInt64u = $ffffffffffffffff;



// -----------------------------------------------------------------
// other Semantic Types
type
    TSize   = int64;   // byte (or other) sizes
    TResult = uint32;   // result code
// -----------------------------------------------------------------

const
     kMaxFloat = 3.40282346638528860e+38;

type
    {$IFDEF PLATFORM_64}   // no idea how to see if Delphi is 64 bit (doesn't exist yet)
	  TPtrInt = uint64;
    {$ELSE}
	  TPtrInt = uint32;
    {$ENDIF}

//------------------------------------------------------------------
// boolean
type
    TBool = uint8;

//------------------------------------------------------------------
// strings
type
    char16 = WideChar;
    pchar16 = PWideChar;

type
    FIDString = PAnsiChar;

//------------------------------------------------------------------------
// Coordinates
type
    TUCoord = int32;

const
     kMaxCoord = $7FFFFFFF;
     kMinCoord = -$7FFFFFFF;

// Byte-order Conversion Macros
//----------------------------------------------------------------------------



(***************
    FUNKNOWN.H
****************)

//------------------------------------------------------------------------
//  Result Codes
//------------------------------------------------------------------------

//------------------------------------------------------------------------
const
     kNoInterface     = $80004002;    // E_NOINTERFACE
     kResultOk	      = $00000000;    // S_OK
     kResultTrue      = kResultOk;
     kResultFalse     = $00000001;    // S_FALSE
     kInvalidArgument = $80070057;    // E_INVALIDARG
     kNotImplemented  = $80004001;    // E_NOTIMPL
     kInternalError   = $80004005;    // E_FAIL
     kNotInitialized  = $8000FFFF;    // E_UNEXPECTED
     kOutOfMemory     = $8007000E;    // E_OUTOFMEMORY



//------------------------------------------------------------------------
//	FUID class declaration
//------------------------------------------------------------------------
type
    PUID = ^TUID;
    TUID = array[0..15] of byte;

type
    TUIDPrintStyle = uint32;

const
     kINLINE_UID  = 0;  ///< "INLINE_UID (0x00000000, 0x00000000, 0x00000000, 0x00000000)"
     kDECLARE_UID = 1;  ///< "DECLARE_UID (0x00000000, 0x00000000, 0x00000000, 0x00000000)"
     kFUID        = 2;  ///< "FUID (0x00000000, 0x00000000, 0x00000000, 0x00000000)"
     kCLASS_UID   = 3;  ///< "DECLARE_CLASS_IID (Interface, 0x00000000, 0x00000000, 0x00000000, 0x00000000)"


//------------------------------------------------------------------------
// FUnknown
//------------------------------------------------------------------------
(**	The basic interface of all interfaces.

- The FUnknown::queryInterface method is used to retrieve pointers to other
  interfaces of the object.
- FUnknown::addRef and FUnknown::release manage the lifetime of the object.
  If no more references exist, the object is destroyed in memory.

Interfaces are identified by 16 byte Globally Unique Identifiers.
The SDK provides a class called FUID for this purpose.

\sa \ref howtoClass *)
//------------------------------------------------------------------------
const UID_FUnknown : TGUID =   '{00000000-0000-0000-C000-000000000046}';

type
    PByte = byte;
    TQueryInterfaceFunc = function(iid: PByte; var obj: pointer): TResult of object;
    FUnknown = IUnknown;
    FakeUnknown = class
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual;stdcall;abstract;
    function _AddRef: Integer; virtual;stdcall;abstract;
    function _Release: Integer; virtual;stdcall;abstract;
end;


(**********************
    IPLUGINBASE.H
***********************)

//------------------------------------------------------------------------
(*  Basic interface to a plugin component.
[plug imp]
- initialize/terminate the plugin component

The host uses this interface to initialize and to terminate the plugin component.
The context that is passed to the initialize method
contains any interface to the host that the plugin will need to work.
The number of interfaces may vary from category to category, but any context
contains a number of standard
										\htmlonly <a href="group__hostInterfacesBasic.html" target=content>
Host Interfaces
										</a>\endhtmlonly.
*)
const
     UID_IPluginBase: TGUID = '{22888DDB-156E-45AE-8358-B34808190625}';
//DECLARE_CLASS_IID (IPluginBase, 0x22888DDB, 0x156E45AE, 0x8358B348, 0x08190625)

type
    IPluginBase = interface(FUnknown)
      (** The host passes a number of interfaces as context to initialize the plugin class.
      @note Extensive memory allocations etc. should be performed in this method rather than in the class constructor!
      If the method does NOT return kResultOk, the object is released immediately. In this case terminate is not called! *)
      function Initialize(context: FUnknown): TResult; stdcall;

      (** This function is called, before the plugin is unloaded and can be used for
      cleanups. You have to release all references to any host application interfaces. *)
      function Terminate: TResult; stdcall;
    end;



//------------------------------------------------------------------------
// Basic Information about the class factory of the plugin
//------------------------------------------------------------------------
type
    TFactoryFlags = int32;

const
     kNoFlags                 = 0;        // Nothing
     kClassesDiscardable      = 1 shl 0;  // The number of exported classes can change each time the Module is loaded. If this flag is set, the host does not cache class information. This leads to a longer startup time because the host always has to load the Module to get the current class information.
     kLicenseCheck            = 1 shl 1;  // Class IDs of components are interpreted as Syncrosoft-License (LICENCE_UID). Loaded in a Steinberg host, the module will not be loaded when the license is not valid
     kComponentNonDiscardable = 1 shl 3;  // Component won't be unloaded until process exit
     kUnicode                 = 1 shl 4;  // Components have entirely unicode encoded strings. (True for VST3 plugins so far)

const
     kFactoryURLSize   = 256;
     kFactoryEmailSize = 128;
     kFactoryNameSize  = 64;

type
    PPFactoryInfo = ^TPFactoryInfo;
    TPFactoryInfo = record
      vendor : array[0..kFactoryNameSize-1] of AnsiChar;   // e.g. "Steinberg Media Technologies"
      url    : array[0..kFactoryURLSize-1] of AnsiChar;    // e.g. "http://www.steinberg.de"
      email  : array[0..kFactoryEmailSize-1] of AnsiChar;  // e.g. "info@steinberg.de"
      flags  : int32;                           // (see above)
    end;

//------------------------------------------------------------------------
//  Basic Information about a class provided by the plugin
//------------------------------------------------------------------------
type
    TClassCardinality = int32;

const
     kManyInstances = $7FFFFFFF;

const
     kClassInfoCategorySize = 32;
     kClassInfoNameSize     = 64;

type
    PPClassInfo = ^TPClassInfo;
    TPClassInfo = record
      cid         : TUID;                              // Changed by RE Class ID 16 Byte class GUID
      cardinality : TClassCardinality;                             // currently ignored, set to kManyInstances
      category    : array[0..kClassInfoCategorySize-1] of AnsiChar;    // class category, host uses this to categorize interfaces
      name        : array[0..kClassInfoNameSize-1] of AnsiChar;			   // class name, visible to the user
    end;

(*
#define LICENCE_UID(l1, l2, l3, l4) \
{ \
	(AnsiChar)((l1 & 0xFF000000) >> 24), (AnsiChar)((l1 & 0x00FF0000) >> 16), \
	(AnsiChar)((l1 & 0x0000FF00) >>  8), (AnsiChar)((l1 & 0x000000FF)      ), \
	(AnsiChar)((l2 & 0xFF000000) >> 24), (AnsiChar)((l2 & 0x00FF0000) >> 16), \
	(AnsiChar)((l2 & 0x0000FF00) >>  8), (AnsiChar)((l2 & 0x000000FF)      ), \
	(AnsiChar)((l3 & 0xFF000000) >> 24), (AnsiChar)((l3 & 0x00FF0000) >> 16), \
	(AnsiChar)((l3 & 0x0000FF00) >>  8), (AnsiChar)((l3 & 0x000000FF)      ), \
	(AnsiChar)((l4 & 0xFF000000) >> 24), (AnsiChar)((l4 & 0x00FF0000) >> 16), \
	(AnsiChar)((l4 & 0x0000FF00) >>  8), (AnsiChar)((l4 & 0x000000FF)      )  \
}
*)


//------------------------------------------------------------------------
//  Version 2 of Basic Information about a class provided by the plugin
//------------------------------------------------------------------------
const
     kClassInfo2VendorSize        = 64;
     kClassInfo2VersionSize       = 64;
     kClassInfo2SubCategoriesSize = 128;

type
    PPClassInfo2 = ^TPClassInfo2;
    TPClassInfo2 = record
      cid           : TUID;                               // @see PClassInfo
      cardinality   : TClassCardinality;                                                  // @see PClassInfo
      category      : array[0..kClassInfoCategorySize-1] of AnsiChar;         // @see PClassInfo
      name          : array[0..kClassInfoNameSize-1] of AnsiChar;             // @see PClassInfo
      classFlags    : uint32;                                                 // flags used for a specific category, must be defined where category is defined
      subCategories : array[0..kClassInfo2SubCategoriesSize-1] of AnsiChar;   // module specific subcategories, can be more than one, separated by '|'
      vendor        : array[0..kClassInfo2VendorSize-1] of AnsiChar;          // overwrite vendor information from factory info
      version       : array[0..kClassInfo2VersionSize-1] of AnsiChar;         // Version AnsiString (e.g. "1.0.0.512" with Major.Minor.Subversion.Build)
      sdkVersion    : array[0..kClassInfo2VersionSize-1] of AnsiChar;         // SDK version used to build this class (e.g. "VST 3.0")
    end;

//------------------------------------------------------------------------
//  Unicode Version of Basic Information about a class provided by the plugin
//------------------------------------------------------------------------
const
     kClassInfoWVendorSize        = 64;
     kClassInfoWVersionSize       = 64;
     kClassInfoWSubCategoriesSize = 128;

type
    PPClassInfoW = ^TPClassInfoW;
    TPClassInfoW = record
      cid           : array[0..15] of AnsiChar;                               // @see PClassInfo
      cardinality   : int32;                                                  // @see PClassInfo
      category      : array[0..kClassInfoCategorySize-1] of AnsiChar;         // @see PClassInfo
      name          : array[0..kClassInfoNameSize-1] of Char;                 // @see PClassInfo
      classFlags    : uint32;                                                 // flags used for a specific category, must be defined where category is defined
      subCategories : array[0..kClassInfoWSubCategoriesSize-1] of AnsiChar;   // module specific subcategories, can be more than one, separated by '|'
      vendor        : array[0..kClassInfoWVendorSize-1] of Char;              // overwrite vendor information from factory info
      version       : array[0..kClassInfoWVersionSize-1] of Char;             // Version AnsiString (e.g. "1.0.0.512" with Major.Minor.Subversion.Build)
      sdkVersion    : array[0..kClassInfoWVersionSize-1] of Char;             // SDK version used to build this class (e.g. "VST 3.0")
    end;



//------------------------------------------------------------------------
//  IPluginFactory interface declaration
//------------------------------------------------------------------------
(**	Class factory that any plugin defines for creating class instances.
[plug imp] \n

From the host's point of view a Plug-In Module is a factory which can create
a certain kind of object(s). The interface IPluginFactory provides methods
to get information about the classes exported by the Plug-In and a
mechanism to create instances of these classes (that usually define the IPluginBase interface).

<b> An implementation is provided in public.sdk/source/common/pluginfactory.cpp </b>
\see GetPluginFactory
*)
//------------------------------------------------------------------------
const
     UID_IPluginFactory: TGUID = '{7A4D811C-5211-4A1F-AED9-D2EE0B43BF9F}';

type
    IPluginFactory = interface(FUnknown)
      [ '{7A4D811C-5211-4A1F-AED9-D2EE0B43BF9F}' ]
      // Fill a PFactoryInfo structure with information about the Plug-In vendor.
      function MYGetFactoryInfo(var info: TPFactoryInfo): TResult; stdcall;
      // Returns the number of exported classes by this factory.
      // If you are using the CPluginFactory implementation provided by the SDK, it returns the number of classes you registered with CPluginFactory::registerClass.
      function CountClasses: int32; stdcall;
      // Fill a PClassInfo structure with information about the class at the specified index.
      function GetClassInfo(index: int32; var info: TPClassInfo): TResult; stdcall;
      // Create a new class instance.
      function CreateInstance(cid, iid: PAnsiChar; var obj: pointer): TResult; stdcall;
    end;

//------------------------------------------------------------------------
//  IPluginFactory2 interface declaration
//------------------------------------------------------------------------
const
     UID_IPluginFactory2: TGUID = '{0007B650-F24B-4C0B-A464-EDB9F00B2ABB}';

type
    IPluginFactory2 = interface(IPluginFactory)
    [ '{0007B650-F24B-4C0B-A464-EDB9F00B2ABB}' ]
      // Returns the class info (version 2) for a given index.
      function GetClassInfo2(index: int32; var info: TPClassInfo2): TResult; stdcall;
    end;

//------------------------------------------------------------------------
//  IPluginFactory3 interface declaration
//------------------------------------------------------------------------
const
     UID_IPluginFactory3 (*: TGUID *) = '{4555A2AB-C123-4E57-9B12-291036878931}';

type
    IPluginFactory3 = interface(IPluginFactory2)
      // Returns the unicode class info for a given index.
      function GetClassInfoUnicode(index: int32; var info: TPClassInfoW): TResult; stdcall;
      // Receives information about host
      function SetHostContext(context: FUnknown): TResult; stdcall;
    end;

//------------------------------------------------------------------------
type
    TGetFactoryProc = function: IPluginFactory; stdcall;



//------------------------------------------------------------------------
// Base class for streams.
// - read / write binary data into/from stream
// - get/set stream read-write position (read and write position is the same)
//
//------------------------------------------------------------------------
type
    TIStreamSeekMode = int32;

const
     kIBSeekSet = 0;  // set absolute seek position
     kIBSeekCur = 1;  // set seek position relative to current position
     kIBSeekEnd = 2;  // set seek position relative to stream end


const
     UID_IBStream: TGUID = '{C3BF6EA2-3099-4752-9B6B-F9901EE33E9B}';

type
    IBStream = interface(FUnknown)
      (* Read binary from stream.
      \param buffer : destination buffer
      \param numBytes : amount of bytes to be read
      \param numBytesRead : result - how many bytes have been read from stream (can be 0 if this is of no interest) *)
      function Read(buffer: pointer; numBytes: int32; numBytesRead: pint32 = nil): TResult; stdcall;

      (* Write binary to stream.
      \param buffer : source buffer
      \param numBytes : amount of bytes to write
      \param numBytesWritten : result - how many bytes have been written to stream (can be 0 if this is of no interest) *)
      function Write(buffer: pointer; numBytes: int32; numBytesWritten: pint32 = nil): TResult; stdcall;

      (* Set stream read-write position.
      \param pos : new stream position (dependent on mode)
      \param mode : value of enum IStreamSeekMode
      \param newPosition : new seek position (can be 0 if this is of no interest)  *)
      function Seek(pos: int64; mode: int32; newPosition: pint64 = nil): TResult; stdcall;

      (* Get current stream read-write position.
      \param pos : Is assigned the current position if function succeeds*)
      function Tell(var pos: int64): TResult; stdcall;
    end;

//------------------------------------------------------------------------
// Stream with a size.
// [extends IBStream] when stream type supports it (like file and memory stream)
//------------------------------------------------------------------------

const
     UID_ISizeableStream: TGUID = '{04F9549E-E02F-4E6E-87E8-6A8747F4E17F}';

type
    ISizeableStream = interface(FUnknown)
      // Return the stream size
      function getStreamSize(var Size: int64): TResult; stdcall;
      // Set the steam size. File streams can only be resized if they are write enabled.
      function setStreamSize(Size: int64): TResult; stdcall;
    end;



(******************
    KEYCODES.H
*******************)

//------------------------------------------------------------------------------
// Virtual Key Codes.
// OS-independent enumeration of virtual keycodes.
//------------------------------------------------------------------------------
type
    TVirtualKeyCodes = int32;

const
     KEY_BACK        = 1;
     KEY_TAB         = 2;
     KEY_CLEAR       = 3;
     KEY_RETURN      = 4;
     KEY_PAUSE       = 5;
     KEY_ESCAPE      = 6;
     KEY_SPACE       = 7;
     KEY_NEXT        = 8;
     KEY_END         = 9;
     KEY_HOME        = 10;

     KEY_LEFT        = 11;
     KEY_UP          = 12;
     KEY_RIGHT       = 13;
     KEY_DOWN        = 14;
     KEY_PAGEUP      = 15;
     KEY_PAGEDOWN    = 16;

     KEY_SELECT      = 17;
     KEY_PRINT       = 18;
     KEY_ENTER       = 19;
     KEY_SNAPSHOT    = 20;
     KEY_INSERT      = 21;
     KEY_DELETE      = 22;
     KEY_HELP        = 23;
     KEY_NUMPAD0     = 24;
     KEY_NUMPAD1     = 25;
     KEY_NUMPAD2     = 26;
     KEY_NUMPAD3     = 27;
     KEY_NUMPAD4     = 28;
     KEY_NUMPAD5     = 29;
     KEY_NUMPAD6     = 30;
     KEY_NUMPAD7     = 31;
     KEY_NUMPAD8     = 32;
     KEY_NUMPAD9     = 33;
     KEY_MULTIPLY    = 34;
     KEY_ADD         = 35;
     KEY_SEPARATOR   = 36;
     KEY_SUBTRACT    = 37;
     KEY_DECIMAL     = 38;
     KEY_DIVIDE      = 39;
     KEY_F1          = 40;
     KEY_F2          = 41;
     KEY_F3          = 42;
     KEY_F4          = 43;
     KEY_F5          = 44;
     KEY_F6          = 45;
     KEY_F7          = 46;
     KEY_F8          = 47;
     KEY_F9          = 48;
     KEY_F10         = 49;
     KEY_F11         = 50;
     KEY_F12         = 51;
     KEY_NUMLOCK     = 52;
     KEY_SCROLL      = 53;

     KEY_SHIFT       = 54;
     KEY_CONTROL     = 55;
     KEY_ALT         = 56;

     KEY_EQUALS			 = 57;   // only occurs on a mac
     KEY_CONTEXTMENU = 58;   // windows only

    // multimedia keys
     KEY_MEDIA_PLAY  = 59;
     KEY_MEDIA_STOP  = 60;
     KEY_MEDIA_PREV  = 61;
     KEY_MEDIA_NEXT  = 62;
     KEY_VOLUME_UP   = 63;
     KEY_VOLUME_DOWN = 64;

    VKEY_FIRST_CODE  = KEY_BACK;
    VKEY_LAST_CODE   = KEY_VOLUME_DOWN;

    VKEY_FIRST_ASCII = 128;

    // KEY_0 - KEY_9 are the same as ASCII '0' - '9' (0x30 - 0x39) + FIRST_ASCII
    // KEY_A - KEY_Z are the same as ASCII 'A' - 'Z' (0x41 - 0x5A) + FIRST_ASCII


//------------------------------------------------------------------------------
type
    TKeyModifier = int32;

const
     kShiftKey     = 1 shl 0;
     kAlternateKey = 1 shl 1;
     kCommandKey   = 1 shl 2;
     kControlKey   = 1 shl 3;



(******************
    IPLUGVIEW.H
*******************)

//------------------------------------------------------------------------
//  Graphical rectangle structure. Used with IPlugView.
//------------------------------------------------------------------------
type
    PViewRect = ^TViewRect;
    TViewRect = record
      left   : int32;
      top    : int32;
      right  : int32;
      bottom : int32;
    end;

//------------------------------------------------------------------------
// List of Platform UI types for IPlugView
// - kPlatformTypeHWND:    the parent parameter is a HWND handle. You should attach a child window to it.
// - kPlatformTypeHIView:  the parent parameter is a WindowRef. You should attach a HIViewRef to the content view of the window.
// - kPlatformTypeNSView:  the parent parameter is an NSView pointer. You should attach an NSView to it.
//------------------------------------------------------------------------
const
     kPlatformTypeHWND   = 'HWND';    // HWND handle. (Microsoft Windows)
     kPlatformTypeHIView = 'HIView';  // HIViewRef. (Mac OS X)
     kPlatformTypeNSView = 'NSView';  // NSView pointer. (Mac OS X)


const
     UID_IPlugView  : TGUID = '{5BC32507-D060-49EA-A615-1B522B755B29}';
     UID_IPlugFrame : TGUID = '{367FAF01-AFA9-4693-8D4D-A2A0ED0882A3}';

type
    IPlugFrame = interface;

    IPlugView = interface(FUnknown)
       [ '{5BC32507-D060-49EA-A615-1B522B755B29}' ]
      (* Is Platform UI Type supported
         - type : IDString of \ref platformUIType *)
      function IsPlatformTypeSupported(aType: FIDString): TResult; stdcall;
      (* The parent window of the view has been created, the
         (platform) representation of the view should now be created as well.
       	 Note that the parent is owned by the caller and you are not allowed to alter it in any way other than adding your own views.
         - parent : platform handle of the parent window or view
         - type : platformUIType which should be created *)
      function Attached(parent: pointer; aType: FIDString): TResult; stdcall;
      (* The parent window of the view is about to be destroyed.
      	 You have to remove all your own views from the parent window or view. *)
      function Removed: TResult; stdcall;
      (* Handling of mouse wheel. *)
      function OnWheel(distance: single): TResult; stdcall;
      (* Handling of keyboard events : Key Down.
         - key : unicode code of key
         - keyCode : virtual keycode for non ascii keys - \see VirtualKeyCodes in keycodes.h
         - modifiers : any combination of KeyModifier - \see keycodes.h *)
      function OnKeyDown(key: char16; keyCode, modifiers: int16): TResult; stdcall;
      (* Handling of keyboard events : Key Up.
         - key : unicode code of key
         - keyCode : virtual keycode for non ascii keys - \see VirtualKeyCodes in keycodes.h
         - modifiers : any combination of KeyModifier - \see keycodes.h *)
      function OnKeyUp(key: char16; keyCode, modifiers: int16): TResult; stdcall;
      (* return the size of the platform representation of the view. *)
      function GetSize(size: PViewRect): TResult; stdcall;
      (* Resize the platform representation of the view to the given rect. *)
      function OnSize(newSize: PViewRect): TResult; stdcall;
      (* Focus changed message. *)
      function OnFocus(state: TBool): TResult; stdcall;
      (* Sets IPlugFrame object to allow the plug-in to inform the host about resizing. *)
      function SetFrame(frame: IPlugFrame): TResult; stdcall;
      (* Is view sizable by user. *)
      function CanResize: TResult; stdcall;
      (* On live resize this is called to check if the view can be resized to the given rect, if not adjust the rect to the allowed size. *)
      function CheckSizeConstraint(rect: PViewRect): TResult; stdcall;
    end;

    IPlugFrame = interface(FUnknown)
      (** Called to inform the host about the resize of a given view. *)
      function ResizeView(view: IPlugView; newSize: PViewRect): TResult; stdcall;
    end;



(*****************
    VSTTYPES.H
******************)

const
     kVstVersionString = 'VST 3.5.2';  // SDK version for PClassInfo2

     kVstVersionMajor = 3;
     kVstVersionMinor = 5;
     kVstVersionSub   = 2;

     VST_VERSION = (kVstVersionMajor shl 16) or (kVstVersionMinor shl 8) or kVstVersionSub;

//------------------------------------------------------------------------
// AnsiString types
//------------------------------------------------------------------------
type
    TChar = char16;
    PTChar = pchar16;

    TString128 = array[0..127] of TChar;   // 128 character UTF-16 AnsiString
    PString128 = ^TString128;
    CString    = pchar8;                    // C-AnsiString

//------------------------------------------------------------------------
// general
//------------------------------------------------------------------------
type
    TMediaType     = int32;  // media type
    TBusDirection  = int32;  // bus direction
    TBusType       = int32;  // bus type
    TIoMode        = int32;  // I/O mode
    TUnitID        = int32;  // unit identifier
    PUnitID        = ^TUnitID;
    TParamValue    = double; // parameter value type
    TParamID       = int32;  // parameter identifier
    TProgramListID = int32;  // program list identifier
    TCtrlNumber    = int16;  // MIDI controller number

    TQuarterNotes  = double; // time expressed in quarter notes
    TSamples       = int64;  // time expressed in audio samples

    PProgramListID = ^TProgramListID;

//------------------------------------------------------------------------
// audio types
//------------------------------------------------------------------------
type
    TSample32           = single;   // 32-bit precision audio sample
    TSample64           = double;   // 64-bit precision audio sample
    TSampleRate         = double;   // sample rate

    PSample32           = ^TSample32;
    PPSample32          = ^PSample32;
    PSample64           = ^TSample64;
    PPSample64          = ^PSample64;

    TPSample32Array = array[0..0] of PSample32;
    PPSample32Array = ^TPSample32Array;
    TPSample64Array = array[0..0] of PSample64;
    PPSample64Array = ^TPSample64Array;

    TSpeakerArrangement = uint64;   // Bitset of speakers
    PSpeakerArrangement = ^TSpeakerArrangement;
    TSpeaker = uint64;              // Bit for one speaker
    PSpeaker = ^TSpeaker;

    TSpeakerArrangementArray = array[0..0] of TSpeakerArrangement;
    PSpeakerArrangementArray = ^TSpeakerArrangementArray;

//------------------------------------------------------------------------
// Speaker definition
//------------------------------------------------------------------------
type
    TSpeakerEnum = int32;

const
     kSpeakerL    = 1 shl 0;		// Left (L)
     kSpeakerR    = 1 shl 1;		// Right (R)
     kSpeakerC    = 1 shl 2;		// Center (C)
     kSpeakerLfe  = 1 shl 3;		// Subbass (Lfe)
     kSpeakerLs   = 1 shl 4;		// Left Surround (Ls)
     kSpeakerRs   = 1 shl 5;		// Right Surround (Rs)
     kSpeakerLc   = 1 shl 6;		// Left of Center (Lc)
     kSpeakerRc   = 1 shl 7;		// Right of Center (Rc)
     kSpeakerS    = 1 shl 8;		// Surround (S)
     kSpeakerCs   = kSpeakerS;	// Center of Surround (Cs) = Surround (S)
     kSpeakerSl   = 1 shl 9;		// Side Left (Sl)
     kSpeakerSr   = 1 shl 10;		// Side Right (Sr)
     kSpeakerTm   = 1 shl 11;		// Top Middle - Center Over-head (Tm)
     kSpeakerTfl  = 1 shl 12;		// Top Front Left (Tfl)
     kSpeakerTfc  = 1 shl 13;		// Top Front Center (Tfc)
     kSpeakerTfr  = 1 shl 14;		// Top Front Right (Tfr)
     kSpeakerTrl  = 1 shl 15;		// Top Rear Left (Trl)
     kSpeakerTrc  = 1 shl 16;		// Top Rear Center (Trc)
     kSpeakerTrr  = 1 shl 17;		// Top Rear Right (Trr)
     kSpeakerLfe2 = 1 shl 18;		// Subbass 2 (Lfe2)
     kSpeakerM    = 1 shl 19;		// Mono (M)

     kSpeakerW	  = 1 shl 20;		// B-Format W
     kSpeakerX	  = 1 shl 21;		// B-Format X
     kSpeakerY	  = 1 shl 22;		// B-Format Y
     kSpeakerZ	  = 1 shl 23;		// B-Format Z

     kSpeakerTsl	= 1 shl 24;		// Top Side Left (Tsl)
     kSpeakerTsr	= 1 shl 25;		// Top Side Right (Tsr)
     kSpeakerLcs  = 1 shl 26;		// Left of Center Surround (Lcs)
     kSpeakerRcs  = 1 shl 27;   // Right of Center Surround (Rcs)

//------------------------------------------------------------------------
// Speaker Arrangements
//------------------------------------------------------------------------
//namespace SpeakerArr

const
     kSpkEmpty        = 0;          // empty arrangement (already defined above, so changed the name)
     kMono			      = kSpeakerM;  // M
     kStereo		      = kSpeakerL  or kSpeakerR;    // L R
     kStereoSurround  = kSpeakerLs or kSpeakerRs;	  // Ls Rs
     kStereoCenter	  = kSpeakerLc or kSpeakerRc;   // Lc Rc
     kStereoSide	    = kSpeakerSl or kSpeakerSr;	  // Sl Sr
     kStereoCLfe	    = kSpeakerC  or kSpeakerLfe;  // C Lfe
     k30Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC;  // L R C
     k30Music		      = kSpeakerL  or kSpeakerR or kSpeakerS;  // L R S
     k31Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe;  // L R C   Lfe
     k31Music		      = kSpeakerL  or kSpeakerR or kSpeakerLfe or kSpeakerS;    // L R Lfe S
     k40Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerS;    // L R C   S (LCRS)
     k40Music		      = kSpeakerL  or kSpeakerR or kSpeakerLs  or kSpeakerRs;   // L R Ls  Rs (Quadro)
     k41Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerS;	 // L R C   Lfe S (LCRS+Lfe)
     k41Music		      = kSpeakerL  or kSpeakerR or kSpeakerLfe or kSpeakerLs  or kSpeakerRs;  // L R Lfe Ls Rs (Quadro+Lfe)
     k50			        = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs;	 // L R C   Ls Rs
     k51			        = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs;  // L R C  Lfe Ls Rs
     k60Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerCs;  // L R C  Ls  Rs Cs
     k60Music		      = kSpeakerL  or kSpeakerR or kSpeakerLs  or kSpeakerRs  or kSpeakerSl or kSpeakerSr;  // L R Ls Rs  Sl Sr
     k61Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerCs;  // L R C   Lfe Ls Rs Cs
     k61Music		      = kSpeakerL  or kSpeakerR or kSpeakerLfe or kSpeakerLs  or kSpeakerRs or kSpeakerSl or kSpeakerSr;  // L R Lfe Ls  Rs Sl Sr
     k70Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerLc or kSpeakerRc;  // L R C   Ls  Rs Lc Rc
     k70Music		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerSl or kSpeakerSr;  // L R C   Ls  Rs Sl Sr
     k71Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerLc or kSpeakerRc; 	// L R C Lfe Ls Rs Lc Rc
     k71Music		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerSl or kSpeakerSr;	// L R C Lfe Ls Rs Sl Sr
     k80Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerLc or kSpeakerRc or kSpeakerCs;  // L R C Ls  Rs Lc Rc Cs
     k80Music		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerCs or kSpeakerSl or kSpeakerSr;	// L R C Ls  Rs Cs Sl Sr
     k80Cube          = kSpeakerL  or kSpeakerR or kSpeakerLs  or kSpeakerRs  or kSpeakerTfl or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R Ls Rs Tfl Tfr Trl Trr
     k81Cine		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerLc or kSpeakerRc or kSpeakerCs;	 // L R C Lfe Ls Rs Lc Rc Cs
     k81Music		      = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerCs or kSpeakerSl or kSpeakerSr;	 // L R C Lfe Ls Rs Cs Sl Sr
     k102			        = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs	or kSpeakerTfl or kSpeakerTfc or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr or kSpeakerLfe2;	// L R C Lfe Ls Rs Tfl Tfc Tfr Trl Trr Lfe2
     k122			        = kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs	or kSpeakerLc or kSpeakerRc or kSpeakerTfl or kSpeakerTfc or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr or kSpeakerLfe2;	///< L R C Lfe Ls Rs Lc Rc Tfl Tfc Tfr Trl Trr Lfe2
     kBFormat1stOrder = kSpeakerW  or kSpeakerX or kSpeakerY   or kSpeakerZ;  ///< W X Y Z (First Order)
     kBFormat         = kBFormat1stOrder;

     kBFormat2		     = kSpeakerW  or kSpeakerX or kSpeakerY   or kSpeakerZ;  // W X Y Z
     k71CineTopCenter  = kSpeakerL or kSpeakerR or kSpeakerC  or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerCs or kSpeakerTm; 		// L R C Lfe Ls Rs Cs Tm
     k71CineCenterHigh = kSpeakerL or kSpeakerR or kSpeakerC  or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerCs or kSpeakerTfc; 	// L R C Lfe Ls Rs Cs Tfc
     k71CineFrontHigh  = kSpeakerL or kSpeakerR or kSpeakerC  or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerTfl or kSpeakerTfr; 	// L R C Lfe Ls Rs Tfl Tfl
     k71CineSideHigh   = kSpeakerL or kSpeakerR or kSpeakerC  or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerTsl or kSpeakerTsr; 	// L R C Lfe Ls Rs Tsl Tsl
     k71CineSideFill   = k61Music;
     k71CineFullRear   = kSpeakerL or kSpeakerR or kSpeakerC  or kSpeakerLfe or kSpeakerLs or kSpeakerRs or kSpeakerLcs or kSpeakerRcs; 	// L R C Lfe Ls Rs Lcs Rcs
     k71CineFullFront  = k71Cine;

     k90	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerTfl or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R C Ls Rs Tfl Tfr Trl Trr
     k91	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs	 or kSpeakerTfl or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R C Lfe Ls Rs Tfl Tfr Trl Trr
     k100	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerTm  or kSpeakerTfl or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R C Ls Rs Tm Tfl Tfr Trl Trr
     k101	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs	 or kSpeakerTm  or kSpeakerTfl or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R C Lfe Ls Rs Tm Tfl Tfr Trl Trr
     k110	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerTm  or kSpeakerTfl or kSpeakerTfc or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R C Ls Rs Tm Tfl Tfc Tfr Trl Trr
     k111	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs	 or kSpeakerTm  or kSpeakerTfl or kSpeakerTfc or kSpeakerTfr or kSpeakerTrl or kSpeakerTrr;	///< L R C Lfe Ls Rs Tm Tfl Tfc Tfr Trl Trr
     k130	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLs  or kSpeakerRs or kSpeakerCs  or kSpeakerTm  or kSpeakerTfl or kSpeakerTfc or kSpeakerTfr or kSpeakerTrl or kSpeakerTrc or kSpeakerTrr;	///< L R C Ls Rs Cs Tm Tfl Tfc Tfr Trl Trc Trr
     k131	= kSpeakerL  or kSpeakerR or kSpeakerC   or kSpeakerLfe or kSpeakerLs or kSpeakerRs	 or kSpeakerCs  or kSpeakerTm  or kSpeakerTfl or kSpeakerTfc or kSpeakerTfr or kSpeakerTrl or kSpeakerTrc or kSpeakerTrr;	///< L R C Lfe Ls Rs Cs Tm Tfl Tfc Tfr Trl Trc Trr



//------------------------------------------------------------------------
// Speaker Arrangement String Representation.
const
     kStringEmpty	           = '';
     kStringMono		         = 'Mono';
     kStringStereo		       = 'Stereo';
     kStringStereoR	         = 'Stereo (Ls Rs)';
     kStringStereoC	         = 'Stereo (Lc Rc)';
     kStringStereoSide	     = 'Stereo (Sl Sr)';
     kStringStereoCLfe	     = 'Stereo (C Lfe)';

     kString30Cine		       = 'LRC';
     kString30Music	         = 'LRS';
     kString31Cine		       = 'LRC+Lfe';
     kString31Music	         = 'LRS+Lfe';
     kString40Cine		       = 'LRCS';
     kString40Music	         = 'Quadro';
     kString41Cine		       = 'LRCS+Lfe';
     kString41Music	         = 'Quadro+Lfe';
     kString50			         = '5.0';
     kString51			         = '5.1';
     kString60Cine		       = '6.0 Cine';
     kString60Music	         = '6.0 Music';
     kString61Cine		       = '6.1 Cine';
     kString61Music	         = '6.1 Music';
     kString70Cine		       = '7.0 Cine';
     kString70Music	         = '7.0 Music';
     kString71Cine		       = '7.1 Cine';
     kString71Music	         = '7.1 Music';
     kString71CineTopCenter	 = '7.1 Cine Top Center';
     kString71CineCenterHigh = '7.1 Cine Center High';
     kString71CineFrontHigh  = '7.1 Cine Front High';
     kString71CineSideHigh   = '7.1 Cine Side High';
     kString71CineFullRear   = '7.1 Cine Full Rear';
     kString80Cine		       = '8.0 Cine';
     kString80Music	         = '8.0 Music';
     kString80Cube		       = '8.0 Cube';
     kString81Cine		       = '8.1 Cine';
     kString81Music	         = '8.1 Music';
     kString102		           = '10.2';
     kString122		           = '12.2';
     kString90			         = '9.0';
     kString91			         = '9.1';
     kString100		           = '10.0';
     kString101		           = '10.1';
     kString110		           = '11.0';
     kString111		           = '11.1';
     kString130		           = '13.0';
     kString131		           = '13.1';
     kStringBFormat1stOrder	 = 'BFormat';

//------------------------------------------------------------------------
// Speaker Arrangement String Representation with Speakers Name.
const
     kStringMonoS		    = 'M';
     kStringStereoS	    = 'L R';
     kStringStereoRS	  = 'Ls Rs';
     kStringStereoCS	  = 'Lc Rc';
     kStringStereoSS	  = 'Sl Sr';
     kStringStereoCLfeS = 'C Lfe';
     kString30CineS	    = 'L R C';
     kString30MusicS	  = 'L R S';
     kString31CineS	    = 'L R C Lfe';
     kString31MusicS	  = 'L R Lfe S';
     kString40CineS     = 'L R C S';
     kString40MusicS	  = 'L R Ls Rs';
     kString41CineS     = 'L R C Lfe S';
     kString41MusicS	  = 'L R Lfe Ls Rs';
     kString50S		      = 'L R C Ls Rs';
     kString51S		      = 'L R C Lfe Ls Rs';
     kString60CineS	    = 'L R C Ls Rs Cs';
     kString60MusicS	  = 'L R Ls Rs Sl Sr';
     kString61CineS	    = 'L R C Lfe Ls Rs Cs';
     kString61MusicS	  = 'L R Lfe Ls Rs Sl Sr';
     kString70CineS	    = 'L R C Ls Rs Lc Rc';
     kString70MusicS	  = 'L R C Ls Rs Sl Sr';
     kString71CineS	    = 'L R C Lfe Ls Rs Lc Rc';
     kString71MusicS	  = 'L R C Lfe Ls Rs Sl Sr';
     kString80CineS	    = 'L R C Ls Rs Lc Rc Cs';
     kString80MusicS	  = 'L R C Ls Rs Cs Sl Sr';
     kString81CineS	    = 'L R C Lfe Ls Rs Lc Rc Cs';
     kString81MusicS	  = 'L R C Lfe Ls Rs Cs Sl Sr';
     kString80CubeS	    = 'L R Ls Rs Tfl Tfr Trl Trr';

     kStringBFormat1stOrderS  = 'W X Y Z';
     kString71CineTopCenterS  = 'L R C Lfe Ls Rs Cs Tm';
     kString71CineCenterHighS = 'L R C Lfe Ls Rs Cs Tfc';
     kString71CineFrontHighS = 'L R C Lfe Ls Rs Tfl Tfl';
     kString71CineSideHighS  = 'L R C Lfe Ls Rs Tsl Tsl';
     kString71CineFullRearS  = 'L R C Lfe Ls Rs Lcs Rcs';
     kString90S		           = 'L R C Ls Rs Tfl Tfr Trl Trr';
     kString91S		           = 'L R C Lfe Ls Rs Tfl Tfr Trl Trr';
     kString100S		         = 'L R C Ls Rs Tm Tfl Tfr Trl Trr';
     kString101S		         = 'L R C Lfe Ls Rs Tm Tfl Tfr Trl Trr';
     kString110S		         = 'L R C Ls Rs Tm Tfl Tfc Tfr Trl Trr';
     kString111S		         = 'L R C Lfe Ls Rs Tm Tfl Tfc Tfr Trl Trr';
     kString130S		         = 'L R C Ls Rs Cs Tm Tfl Tfc Tfr Trl Trc Trr';
     kString131S		         = 'L R C Lfe Ls Rs Cs Tm Tfl Tfc Tfr Trl Trc Trr';
     kString102S		         = 'L R C Lfe Ls Rs Tfl Tfc Tfr Trl Trr Lfe2';
     kString122S		         = 'L R C Lfe Ls Rs Lc Rc Tfl Tfc Tfr Trl Trr Lfe2';



// Returns number of channels used in speaker arrangement.



//------------------------------------------------------------------------
// IAttributeList Interface
//------------------------------------------------------------------------
(**  Attribute List Interface
[host imp]
Attribute list.
*)
const
     UID_IAttributeList: TGUID = '{1E5F0AEB-CC7F-4533-A254-401138AD5EE4}';

type
    TAttrID = PAnsiChar;

    IAttributeList = interface(FUnknown)
      // Set integer value.
      function setInt(id: TAttrID; value: int64): TResult; stdcall;
      // Gets integer value.
      function getInt(id: TAttrID; var value: int64): TResult; stdcall;
      // Set float value.
      function setFloat (id: TAttrID; value: double): TResult; stdcall;
      // Gets float value.
      function getFloat (id: TAttrID; var value: double): TResult; stdcall;
      // Set AnsiString value (UTF16).
      function setString(id: TAttrID; str: PTChar): TResult; stdcall;
      // Gets AnsiString value (UTF16).
      function getString(id: TAttrID; str: PTChar; size: uint32): TResult; stdcall;
      // Set binary data.
      function setBinary(id: TAttrID; data: pointer; size: uint32): TResult; stdcall;
      // Gets binary data.
      function getBinary(id: TAttrID; var data: pointer; var size: uint32): TResult; stdcall;
    end;



(**********************
    IVSTCOMPONENT.H
***********************)

const
     kDefaultFactoryFlags = kUnicode;   ///< Standard value for PFactoryInfo::flags

(*
#define BEGIN_FACTORY_DEF(vendor,url,email) using namespace Steinberg; \
	EXPORT_FACTORY IPluginFactory* PLUGIN_API GetPluginFactory () { \
	if (!gPluginFactory) \
	{	static PFactoryInfo factoryInfo = { vendor,url,email,Vst::kDefaultFactoryFlags }; \
		gPluginFactory = new CPluginFactory (factoryInfo);
*)

//------------------------------------------------------------------------
// Bus media types
//------------------------------------------------------------------------
type
    TMediaTypes = int32;

const
     kAudio         = 0;   // audio
     kEvent         = 1;   // events
     kNumMediaTypes = 2;

//------------------------------------------------------------------------
// Bus directions
//------------------------------------------------------------------------
type
    TBusDirections = int32;

const
     kInput  = 0;  // input bus
     kOutput = 1;  // output bus

//------------------------------------------------------------------------
// Bus types
//------------------------------------------------------------------------
type
    TBusTypes = int32;

const
     kMain = 0;    // main bus
     kAux  = 1;    // auxilliary bus (sidechain)


//------------------------------------------------------------------------
// I/O modes
//------------------------------------------------------------------------
type
    TIoModes = int32;

const
     kSimple   = 0;    // 1:1 Input/Output
     kAdvanced = 1;    // n:n I/O


//------------------------------------------------------------------------
(* Basic I/O Bus Description.

A bus can be understood as 'collection of data channels' belonging together.
It describes a data input or a data output of the plug-in.
A VST component can define any desired number of buses, but this number \b never must change.
Dynamic usage of buses is handled in the host by activating and deactivating
buses. The component has to define the maximum of supported buses and it has
to define which of them are active by default. A host that can handle multiple
buses, allows the user to activate buses that were initially inactive. *)
//------------------------------------------------------------------------
type
    TBusFlags = int32;

const
     kDefaultActive = 1 shl 0;   // bus active per default

type
    PBusInfo = ^TBusInfo;
    TBusInfo = record
      mediaType    : TMediaType;      // Media type - has to be a value of MediaTypes
      direction    : TBusDirection;   // input or output
      channelCount : int32;           // number of channels
      name         : TString128;      // name
      busType      : TBusType;        // main or aux
      flags        : uint32;          // flags
    end;

//------------------------------------------------------------------------
// Routing Information.
//------------------------------------------------------------------------
type
    PRoutingInfo = ^TRoutingInfo;
    TRoutingInfo = record
      mediaType : TMediaType;    // media type
      busIndex  : int32;         // bus index
      channel   : int32;         // channel (-1 for all channels)
    end;

//------------------------------------------------------------------------
// IComponent Interface
//------------------------------------------------------------------------
(**  Component Base Interface
[plug imp]
IComponent describes a basic plug-in and must always be supported.
*)
const
     UID_IComponent: TGUID = '{E831FF31-F2D5-4301-928E-BBEE25697802}';

type
    IComponent = interface(IPluginBase)
    [ '{E831FF31-F2D5-4301-928E-BBEE25697802}' ]
      // Called before initializing the component to get information about the controller class.
      function GetControllerClassId(var classId: TUID): TResult; stdcall;
      // Called before 'initialize' to set the component usage (optional).
      function SetIoMode(mode: TIoMode): TResult; stdcall;
      // Called after the plug-in is initialized.
      function GetBusCount(vType: TMediaType; dir: TBusDirection): int32; stdcall;
      // Called after the plug-in is initialized.
      function GetBusInfo(vType: TMediaType; dir: TBusDirection; index: int32; var bus: TBusInfo): TResult; stdcall;
      // Retrieve routing information (to be implemented when more than one regular input or output bus exists).
	    // The inInfo always refers to an input bus while the returned outInfo must refer to an output bus!
      function GetRoutingInfo(var inInfo: TRoutingInfo; var outInfo: TRoutingInfo): TResult; stdcall;
      // Called upon (de-)activating a bus in the host application.
      function ActivateBus(vType: TMediaType; dir: TBusDirection; index: int32; state: TBool): TResult; stdcall;
      // Activate / deactivate the component.
      function SetActive(state: TBool): TResult; stdcall;
      // Set complete state of component.
      function SetState(state: IBStream): TResult; stdcall;
      // Retrieve complete state of component.
      function GetState(state: IBStream): TResult; stdcall;
    end;



(******************************
    IVSTMIDICONTROLLERS.H
*******************************)

//------------------------------------------------------------------------
// MIDI Controller Number
//------------------------------------------------------------------------
type
    TControllerNumbers = int32;

const
     kCtrlBankSelectMSB     = 0;  // Bank Select MSB
     kCtrlModWheel          = 1;	// Modulation Wheel
     kCtrlBreath            = 2;	// Breath controller

     kCtrlFoot              = 4;	// Foot Controller
     kCtrlPortaTime         = 5;	// Portamento Time
     kCtrlDataEntryMSB      = 6;	// Data Entry MSB
     kCtrlVolume            = 7;	// Channel Volume (formerly Main Volume)
     kCtrlBalance           = 8;	// Balance

     kCtrlPan               = 10;	// Pan
     kCtrlExpression        = 11;	// Expression
     kCtrlEffect1           = 12;	// Effect Control 1
     kCtrlEffect2           = 13;	// Effect Control 2

     //---General Purpose Controllers #1 to #4---
     kCtrlGPC1              = 16;	// General Purpose Controller #1
     kCtrlGPC2              = 17;	// General Purpose Controller #2
     kCtrlGPC3              = 18;	// General Purpose Controller #3
     kCtrlGPC4              = 19;	// General Purpose Controller #4

     kCtrlBankSelectLSB     = 32;	// Bank Select LSB

     kCtrlDataEntryLSB      = 38;	// Data Entry LSB

     kCtrlSustainOnOff      = 64;	// Damper Pedal On/Off (Sustain)
     kCtrlPortaOnOff        = 65;	// Portamento On/Off
     kCtrlSustenutoOnOff    = 66;	// Sustenuto On/Off
     kCtrlSoftPedalOnOff    = 67;	// Soft Pedal On/Off
     kCtrlLegatoFootSwOnOff = 68;	// Legato Footswitch On/Off
     kCtrlHold2OnOff        = 69;	// Hold 2 On/Off


     //---Sound Controllers #1 to #10---
     kCtrlSoundVariation    = 70; // Sound Variation
     kCtrlFilterCutoff      = 71;	// Filter Cutoff (Timbre/Harmonic Intensity)
     kCtrlReleaseTime       = 72;	// Release Time
     kCtrlAttackTime        = 73;	// Attack Time
     kCtrlFilterResonance   = 74;	// Filter Resonance (Brightness)
     kCtrlDecayTime         = 75;	// Decay Time
     kCtrlVibratoRate       = 76;	// Vibrato Rate
     kCtrlVibratoDepth      = 77;	// Vibrato Depth
     kCtrlVibratoDelay      = 78;	// Vibrato Delay
     kCtrlSoundCtrler10     = 79; // undefined

     //---General Purpose Controllers #5 to #8---
     kCtrlGPC5              = 80;	// General Purpose Controller #5
     kCtrlGPC6              = 81;	// General Purpose Controller #6
     kCtrlGPC7              = 82;	// General Purpose Controller #7
     kCtrlGPC8              = 83;	// General Purpose Controller #8

     kCtrlPortaControl      = 84;	// Portamento Control

     //---Effect Controllers---
     kCtrlEff1Depth         = 91;	// Effect 1 Depth (Reverb Send Level)
     kCtrlEff2Depth         = 92;	// Effect 2 Depth
     kCtrlEff3Depth         = 93;	// Effect 3 Depth (Chorus Send Level)
     kCtrlEff4Depth         = 94;	// Effect 4 Depth (Delay/Variation Level)
     kCtrlEff5Depth         = 95;	// Effect 5 Depth

     kCtrlDataIncrement     = 96;	// Data Increment (+1)
     kCtrlDataDecrement     = 97;	// Data Decrement (-1)
     kCtrlNRPNSelectLSB     = 98; // NRPN Select LSB
     kCtrlNRPNSelectMSB     = 99; // NRPN Select MSB
     kCtrlRPNSelectLSB      = 100; // RPN Select LSB
     kCtrlRPNSelectMSB      = 101; // RPN Select MSB

     //---Other Channel Mode Messages---
     kCtrlAllSoundsOff      = 120; // All Sounds Off
     kCtrlResetAllCtrlers   = 121; // Reset All Controllers
     kCtrlLocalCtrlOnOff    = 122; // Local Control On/Off
     kCtrlAllNotesOff       = 123; // All Notes Off
     kCtrlOmniModeOff       = 124; // Omni Mode Off + All Notes Off
     kCtrlOmniModeOn        = 125; // Omni Mode On  + All Notes Off
     kCtrlPolyModeOnOff     = 126; // Poly Mode On/Off + All Sounds Off
     kCtrlPolyModeOn        = 127; // Poly Mode On

     //---Extra--------------------------
     kAfterTouch            = 128; // After Touch
     kPitchBend             = 129; // Pitch Bend

     kCountCtrlNumber       = 130;



(******************************
    IVSTPARAMETERCHANGES.H
*******************************)

//----------------------------------------------------------------------
(* IParamValueQueue Interface
 Queue of changes for a specific parameter.
- [host imp]

The change queue can be interpreted as segment of an automation curve. For each
processing block a segment in the size of the block is transmitted to the processor.
The curve is expressed as sampling points of a linear approximation of
the original automation curve. If the original IS a linear curve it can
be transmitted precisely. A non-linear curve has to be converted to a linear
approximation by the host. Every point of the value queue defines a linear
section of the curve as a straight line from the previous point of a block to
the new one. So the plug-in can calculate the value of the curve for any sample
position in the block.

<b>Implicit Points:</b> \n
In order to reduce the amount of transmitted points, the first point at block
position 0 can be omitted. When the queue does not contain an initial point,
the processor can assumes an implicit point with the current value of the
parameter at position 0. So when the curve has a slope of 1 no points have to
be transmitted. If the curve has a constant slope other than 1 over the period
of several blocks, only the value for the last sample of the block has to be transmitted.

<b>Jumps:</b> \n
A jump in the automation curve has to be transmitted as two points: one with the
old value and one with the new value at the next sample position. *)
//----------------------------------------------------------------------
const
     UID_IParamValueQueue: TGUID = '{01263A18-ED07-4F6F-98C9-D3564686F9BA}';

type
    IParamValueQueue = class(FAkeUnknown)//interface(FUnknown)
      // Returns its associated ID.
      function GetParameterId: TParamID; virtual;stdcall;abstract;
      // Returns count of Point in the queue.
      function GetPointCount: int32; virtual;stdcall;abstract;
      // Gets the value and offset at a given index.
      function GetPoint(index: int32; out sampleOffset: int32; out value: TParamValue): TResult; virtual;stdcall;abstract;
      // Adds a new value at the end of the queue, its index is returned.
      function AddPoint(sampleOffset: int32; value: TParamValue; out index: int32): TResult; virtual;stdcall;abstract;
    end;



//----------------------------------------------------------------------
(* IParameterChanges Interface
This interface is used to transmit any changes that should happen to paramaters
in the current processing block. A change can be caused by GUI interaction as
well as automation. They are transmitted as a list of queues (IParamValueQueue)
containing only queues for paramaters that actually changed. *)
//----------------------------------------------------------------------
const
     UID_IParameterChanges: TGUID = '{A4779663-0BB6-4A56-B443-84A8466FEB9D}';

type
    IParameterChanges = interface(FUnknown)
      // Returns count of Parameter changes in the list.
      function GetParameterCount: int32; stdcall;
      // Returns the queue at a given index.
      function GetParameterData(index: int32): pointer{IParamValueQueue}; stdcall;     // TODO: Try to change this to IParamValueQueue -> Nop, does not work..
      (* Adds a new parameter queue with a given ID at the end of the list,
      returns it and its index in the parameter changes list. *)
      function AddParameterData(var id: TParamID; out index: int32): pointer{IParamValueQueue}; stdcall;
    end;

(****************************
    IVSTPROCESSCONTEXT.H
*****************************)

//------------------------------------------------------------------------
// Frame Rate
//------------------------------------------------------------------------
type
    TFrameRateFlags = int32;

const
     kPullDownRate = 1 shl 0;   // for ex. HDTV: 23.976 fps with 24 as frame rate
     kDropRate     = 1 shl 1;   // for ex. 29.97 fps drop with 30 as frame rate

type
    TFrameRate = record
      framesPerSecond : uint32;  // frame rate
      flags           : uint32;  // flags #FrameRateFlags
    end;


//------------------------------------------------------------------------
(** Musical info
	Notes on chordMask:\n
    1st bit set: minor second; 2nd bit set: major second, and so on.
    There is *no* bit set for the keynote ("bit 0").\n
	Examples:\n
    XXXX 0000 0100 1000 (= 0x0048) -> major chord\n
    XXXX 0000 0100 0100 (= 0x0044) -> minor chord\n
    XXXX 0010 0100 0100 (= 0x0244) -> minor chord with minor seventh *)
//------------------------------------------------------------------------
type
    TChordMask = int16;

const
     kChordMask    = $0FFF;   // mask for chordMask
     kReservedMask = $F000;   // reserved for future used

type
    TChord = record
      keyNote   : uint8;  // key note in chord
      rootNote  : uint8;  // lowest note in chord
      chordMask : TChordMask;  // bitmask of a chord
    end;

//------------------------------------------------------------------------
// Audio processing context
//------------------------------------------------------------------------

// transport states & flags
type
    TStatesAndFlags = uint32;

const
     kPlaying               = 1 shl 1;    // currently playing
     kCycleActive           = 1 shl 2;    // cycle is active
     kRecording             = 1 shl 3;    // currently recording

     kSystemTimeValid       = 1 shl 8;    // systemTime contains valid information
     kContTimeValid         = 1 shl 17;   // continousTimeSamples contains valid information

     kProjectTimeMusicValid = 1 shl 9;    // projectTimeMusic contains valid information
     kBarPositionValid      = 1 shl 11;   // barPositionMusic contains valid information
     kCycleValid            = 1 shl 12;   // cycleStartMusic and barPositionMusic contain valid information

     kTempoValid            = 1 shl 10;   // tempo contains valid information
     kTimeSigValid          = 1 shl 13;   // timeSigNumerator and timeSigDenominator contain valid information
     kChordValid            = 1 shl 18;   // chord contains valid information

     kSmpteValid            = 1 shl 14;   // smpteOffset and frameRate contain valid information
     kClockValid            = 1 shl 15;   // samplesToNextClock valid

type
    PProcessContext = ^TProcessContext;
    TProcessContext = record
      state                : TStatesAndFlags;      // transport state (@see TransportStates)
      sampleRate           : double;               // current sample rate (always valid)
      projectTimeSamples   : TSamples;             // project time in samples (always valid)
      systemTime           : int64;                // system time in nanoseconds (optional)
      continousTimeSamples : TSamples;             // project time, without loop (optional)
      projectTimeMusic     : TQuarterNotes;        // musical position in quarter notes (1.0 equals 1 quarter note)
      barPositionMusic     : TQuarterNotes;        // last bar start position, in quarter notes
      cycleStartMusic      : TQuarterNotes;        // cycle start in quarter notes
      cycleEndMusic        : TQuarterNotes;        // cycle end in quarter notes
      tempo                : double;               // tempo in BPM (Beats Per Minute)
      timeSigNumerator     : int32;                // time signature numerator (e.g. 3 for 3/4)
      timeSigDenominator   : int32;                // time signature denominator (e.g. 4 for 3/4)
      chord                : TChord;               // musical info
      smpteOffsetSubframes : int32;                // SMPTE (sync) offset in subframes (1/80 of frame)
      frameRate            : TFrameRate;           // frame rate
      samplesToNextClock   : int32;                // MIDI Clock Resolution (24 Per Quarter Note), can be negative (nearest)
    end;



(************************
    IVSTNOTEEXPRESSION.H
*************************)

type
    TNoteExpressionTypeID = uint32;
    TNoteExpressionValue = double;

//------------------------------------------------------------------------
// NoteExpressionTypeIDs describes the type of the note expression.
// VST predefines some types like volume, pan, tuning by defining their ranges and curves.
// Used by NoteExpressionEvent::typeId and NoteExpressionTypeID::typeId
//------------------------------------------------------------------------
type
    TNoteExpressionTypeIDs = longint;

const
     kVolumeTypeID    = 0;     // Volume, plain range [0 = -oo , 0.25 = 0dB, 0.5 = +6dB, 1 = +12dB]: plain = 20 * log (4 * norm)
     kPanTypeID       = 1;     // Panning (L-R), plain range [0 = left, 0.5 = center, 1 = right]
     kTuningTypeID    = 2;     // Tuning, plain range [0 = -120.0 (ten octaves down), 0.5 none, 1 = +120.0 (ten octaves up)]
                               // plain = 240 * (norm - 0.5) and norm = plain / 240 + 0.5
                               // oneOctave is 12.0 / 240.0; oneHalfTune = 1.0 / 240.0;
     kVibratoTypeID    = 3;    // Vibrato
     kExpressionTypeID = 4;    // Expression
     kBrightnessTypeID = 5;    // Brightness
     kTextTypeID       = 6;    // TODO:
     kPhonemeTypeID    = 7;    // TODO:

     kCustomStart      = 100000;  // custom note change type ids must start from here

//------------------------------------------------------------------------
// Description of a Note Expression Type
// This structure is part of the NoteExpressionTypeInfo structure, it describes for given NoteExpressionTypeID its default value
// (for example 0.5 for a kTuningTypeID (kIsBipolar: centered)), its minimum and maximum (for predefined NoteExpressionTypeID the full range is predefined too)
// and a stepCount when the given NoteExpressionTypeID is limited to discrete values (like on/off state).
//------------------------------------------------------------------------
type
    PNoteExpressionValueDescription = ^TNoteExpressionValueDescription;
    TNoteExpressionValueDescription = record
      defaultValue : TNoteExpressionValue;	 // default normalized value [0,1]
      minimum      : TNoteExpressionValue;	 // minimum normalized value [0,1]
      maximum      : TNoteExpressionValue;	 // maximum normalized value [0,1]
      stepCount    : int32;				           // number of discrete steps (0: continuous, 1: toggle, discrete value otherwise - see vst3parameterIntro)
    end;

{$IFNDEF CPUx64}
  {$ALIGN 4}
{$ENDIF}
//------------------------------------------------------------------------
// Note Expression Value event. Used in \ref Event (union)
// A note expression event affects one single playing note (referring its noteId).
// This kind of event is send from host to the Plug-in like other events (NoteOnEvent, NoteOffEvent,...) in \ref ProcessData during the process call.
// Note expression events for a specific noteId can only occur after a NoteOnEvent. The host must take care that the event list (\ref IEventList) is properly sorted.
// Expression events are always absolute normalized values [0.0, 1.0].
// The predefined types have a predefined mapping of the normalized values (see \ref NoteExpressionTypeIDs)
//------------------------------------------------------------------------
type
    PNoteExpressionValueEvent = ^TNoteExpressionValueEvent;
    TNoteExpressionValueEvent = record
      typeId : TNoteExpressionTypeID;   // see NoteExpressionTypeID
      noteId : int32;                   // associated note identifier to apply the change
      value  : TNoteExpressionValue;    // normalized value [0.0, 1.0].
    end;

//------------------------------------------------------------------------
// Note Expression Text event. Used in Event (union)
// A Expression event affects one single playing note. \sa INoteExpressionController
//------------------------------------------------------------------------
type
    PNoteExpressionTextEvent = ^TNoteExpressionTextEvent;
    TNoteExpressionTextEvent = record
      typeId : TNoteExpressionTypeID;   // see NoteExpressionTypeID (kTextTypeID or kPhoneticTypeID)
      noteId : int32;                   //associated note identifier to apply the change
      size   : uint32;                  // number of bytes in text (includes null byte)
      text   : pchar16;                 // UTF-16, null terminated
    end;

{$IFNDEF CPUx64}
  {$ALIGN 8}
{$ENDIF}

//------------------------------------------------------------------------
// NoteExpressionTypeInfo is the structure describing a note expression supported by the Plug-in.
// This structure is used by the method \ref INoteExpressionController::getNoteExpressionInfo.
//------------------------------------------------------------------------
type
    TNoteExpressionTypeFlags = longint;

const
     kIsBipolar                  = 1 shl 0;   // event is bipolar (centered), otherwise unipolar
     kIsOneShot                  = 1 shl 1;   // event occurs only one time for its associated note (at begin of the noteOn)
     kIsAbsolute                 = 1 shl 2;   // This note expression will apply an absolute change to the sound (not relative (offset))
     kAssociatedParameterIDValid = 1 shl 3;   // indicates that the associatedParameterID is valid and could be used

type
    PNoteExpressionTypeInfo = ^TNoteExpressionTypeInfo;
    TNoteExpressionTypeInfo = record
      typeId                : TNoteExpressionTypeID;             // unique identifier of this note Expression type
      title                 : TString128;                        // note Expression type title (e.g. "Volume")
      shortTitle            : TString128;                        // note Expression type short title (e.g. "Vol")
      units                 : TString128;                        // note Expression type unit (e.g. "dB")
      unitId                : int32;                             // id of unit this NoteExpression belongs to (see \ref vst3UnitsIntro), in order to sort the note expression, it is possible to use unitId like for parameters. -1 means no unit used.
      valueDesc             : TNoteExpressionValueDescription;   // value description see \ref NoteExpressionValueDescription
      associatedParameterId : TParamID;                          // optional associated parameter ID (for mapping from note expression to global (using the parameter automation for example) and back). Only used when kAssociatedParameterIDValid is set in flags.
      flags                 : int32;                             // NoteExpressionTypeFlags (see below)
    end;

//------------------------------------------------------------------------
// Extended IEditController interface for note expression event support.
//
// With this Plug-in interface, the host can retrieve all necessary note expression information supported by the Plug-in.
// Note expression information (NoteExpressionTypeInfo) are specific for given channel and event bus.
//
// Note that there is only one NoteExpressionTypeID per given channel of an event bus.
//
// The method getNoteExpressionStringByValue allows conversion from a normalized value to a string representation
// and the getNoteExpressionValueByString method from a string to a normalized value.
//
// When the note expression state changes (per example when switching presets) the Plug-in needs
// to inform the host about it via \ref IComponentHandler::restartComponent (kNoteExpressionChanged).
//------------------------------------------------------------------------
const
     UID_INoteExpressionController: TGUID = '{B7F8F859-4123-4872-9116-95814F3721A3}';

type
    INoteExpressionController = interface(FUnknown)
      // Returns number of supported note change types for event bus index and channel.
      function getNoteExpressionCount(busIndex: int32; channel: int16): int32; stdcall;
      // Returns note change type info.
      function getNoteExpressionInfo(busIndex: int32; channel: int16; noteExpressionIndex: int32; var info: TNoteExpressionTypeInfo): TResult; stdcall;
      // Gets a user readable representation of the normalized note change value.
      function getNoteExpressionStringByValue(busIndex: int32; channel: int16; id: TNoteExpressionTypeID; valueNormalized: TNoteExpressionValue; text: PString128): TResult; stdcall;
      // Converts the user readable representation to the normalized note change value.
      function getNoteExpressionValueByString(busIndex: int32; channel: int16; id: TNoteExpressionTypeID; text: PTChar; var valueNormalized: TNoteExpressionValue): TResult; stdcall;
    end;

//------------------------------------------------------------------------
// KeyswitchTypeIDs describes the type of a key switch
type
    TKeyswitchTypeIDs = longint;
    TKeyswitchTypeID  = uint32;

const
     kNoteOnKeyswitchTypeID    = 0;  // press before noteOn is played
     kOnTheFlyKeyswitchTypeID  = 1;  // press while noteOn is played
     kOnReleaseKeyswitchTypeID = 2;  // press before entering release
     kKeyRangeTypeID					 = 3;  // key should be maintained pressed for playing

//------------------------------------------------------------------------
// KeyswitchInfo is the structure describing a key switch
// This structure is used by the method \ref IKeyswitchController::getKeyswitchInfo.
type
    PKeyswitchInfo = ^TKeyswitchInfo;
    TKeyswitchInfo = record
      typeId       : TKeyswitchTypeID;  // see KeyswitchTypeID
      title        : TString128;        // name of key switch (e.g. "Accentuation")
      shortTitle   : TString128;        // short title (e.g. "Acc")
      keyswitchMin : int32;             // associated main key switch min (value between [0, 127])
      keyswitchMax : int32;             // associated main key switch max (value between [0, 127])
      keyRemapped  : int32;             // optional remapped key switch (default -1), the Plug-in could provide one remapped key for a key switch (allowing better location on the keyboard of the key switches)
      unitId       : int32;             // id of unit this key switch belongs to (see \ref vst3UnitsIntro), -1 means no unit used.
      flags        : int32;             // not yet used (set to 0)
    end;

//------------------------------------------------------------------------
// Extended IEditController interface for key switches support.
//
// When a (instrument) Plug-in supports such interface, the host could get from the Plug-in the current set
// of used key switches (megatrig/articulation) for a given channel of a event bus and then automatically use them (like in Cubase 6) to
// create VST Expression Map (allowing to associated symbol to a given articulation / key switch).
//------------------------------------------------------------------------
const
     UID_IKeyswitchController: TGUID = '{1F2F76D3-BFFB-4B96-B995-27A55EBCCEF4}';

type
    IKeyswitchController = interface(FUnknown)
      // Returns number of supported key switches for event bus index and channel.
      function getKeyswitchCount(busIndex: int32; channel: int16): int32; stdcall;
      // Returns key switch info.
      function getKeyswitchInfo(busIndex: int32; channel: int16; keySwitchIndex: int32; var info: TKeyswitchInfo): TResult; stdcall;
    end;



(************************
    IVSTEVENTS.H
*************************)

//------------------------------------------------------------------------
// Event
//------------------------------------------------------------------------

// event Flags
type
    TEventFlags = uint16;

const
     kIsLive        = 1 shl 0;   // indicates that the event is played live (direct from keyboard)

     kUserReserved1 = 1 shl 14;  // reserved for user (for internal use)
     kUserReserved2 = 1 shl 15;  // reserved for user (for internal use)

// event Types
type
    TEventTypes = uint16;

const
     kNoteOnEvent       = 0;         // Note On event
     kNoteOffEvent      = 1;         // Note Off event
     kDataEvent         = 2;         // Data event
     kPolyPressureEvent = 3;         // Poly Pressure event
     kNoteExpressionValueEvent = 4;  // Note Expression Value event
     kNoteExpressionTextEvent  = 5;  // Note Expression Text event

// data Types for kDataEvent
type
    TDataTypes = int32;

const
     kMidiSysEx = 0;   // for MIDI system exclusive message

type
    TNoteOnEvent = record
      channel  : int16;     // channel index in event bus
      pitch    : int16;     // range [0, 127] = [C-2, G8] with A3=440Hz
      tuning   : single;    // 1.f = +1 cent, -1.f = -1 cent
      velocity : single;    // range [0.0, 1.0]
      length   : int32;     // in sample frames (optional, Note Off has to follow in any case!)
      noteId   : int32;     // note identifier
    end;

    TNoteOffEvent = record
      channel  : int16;    // channel index in event bus
      pitch    : int16;    // range [0, 127] = [C-2, G8] with A3=440Hz
      velocity : single;   // range [0.0, 1.0]
      noteId   : int32;    // note identifier
    end;

    TDataEvent = record
      size  : uint32;    // size of the bytes
      vType : uint32;    // type of this data block (@see DataTypes)
      bytes : puint8;    // pointer to the data block
    end;

    TPolyPressureEvent = record
      channel  : int16;			///< channel index in event bus
      pitch    : int16;			///< range [0, 127] = [C-2, G8] with A3=440Hz
      pressure : single;		///< range [0.0, 1.0]
      noteId   : int32;			///< event should be applied to the noteId (if not -1)
    end;

type
    TVstEvent = record
      busIndex     : int32;         // event bus index
      sampleOffset : int32;         // sample frames related to the current block start sample position
      ppqPosition  : TQuarterNotes; // position in project
      flags        : TEventFlags;	  // see EventFlags
      eventType    : TEventTypes;   // see EventTypes
      case TEventTypes of
        kNoteOnEvent       : (noteOn: TNoteOnEvent);
        kNoteOffEvent      : (noteOff: TNoteOffEvent);
        kDataEvent         : (data: TDataEvent);
        kPolyPressureEvent : (poly: TPolyPressureEvent);
        kNoteExpressionValueEvent : (exprValue: TNoteExpressionValueEvent);
        kNoteExpressionTextEvent  : (exprText: TNoteExpressionTextEvent);
    end;


//------------------------------------------------------------------------
//  IEventList Interface
//------------------------------------------------------------------------
const
     UID_IEventList: TGUID = '{3A2C4214-3463-49FE-B2C4-F397B9695A44}';

type
    IEventList = interface(FUnknown)
      // Returns the count of events.
      function GetEventCount: int32; stdcall;
      // Gets parameter by index.
      function GetEvent(index: int32; out e: TVstEvent): TResult; stdcall;
      // Adds a new event.
      function AddEvent(var e: TVstEvent): TResult; stdcall;
    end;



(***************************
    IVSTAUDIOPROCESSOR.H
****************************)

//------------------------------------------------------------------------
// Class Categories
//------------------------------------------------------------------------
const
     kVstAudioEffectClass = 'Audio Module Class';

//------------------------------------------------------------------------
// Component Types used as subCategories in PClassInfo2 */
//------------------------------------------------------------------------
const
     kFxAnalyzer	         = 'Fx|Analyzer';             // Scope, FFT-Display,...
     kFxDelay		           = 'Fx|Delay';                // Delay, Multi-tap Delay, Ping-Pong Delay...
     kFxDistortion		     = 'Fx|Distortion';           // Amp Simulator, Sub-Harmonic, SoftClipper...
     kFxDynamics		       = 'Fx|Dynamics';             // Compressor, Expander, Gate, Limiter, Maximizer, Tape Simulator, EnvelopeShaper...
     kFxEQ				         = 'Fx|EQ';	                  // Equalization, Graphical EQ...
     kFxFilter			       = 'Fx|Filter';	              // WahWah, ToneBooster, Specific Filter,...
     kFx				           = 'Fx';			                // others type (not categorized)
     kFxInstrument		     = 'Fx|Instrument';           // Fx which could be loaded as Instrument too
     kFxInstrumentExternal = 'Fx|Instrument|External';  // Fx which could be loaded as Instrument too and is external (wrapped Hardware)
     kFxSpatial		         = 'Fx|Spatial';              // MonoToStereo, StereoEnhancer,...
     kFxGenerator		       = 'Fx|Generator';            // Tone Generator, Noise Generator...
     kFxMastering		       = 'Fx|Mastering';            // Dither, Noise Shaping,...
     kFxModulation		     = 'Fx|Modulation';           // Phaser, Flanger, Chorus, Tremolo, Vibrato, AutoPan, Rotary, Cloner...
     kFxPitchShift		     = 'Fx|Pitch Shift';          // Pitch Processing, Pitch Correction,...
     kFxRestoration	       = 'Fx|Restoration';          // Denoiser, Declicker,...
     kFxReverb			       = 'Fx|Reverb';               // Reverberation, Room Simulation, Convolution Reverb...
     kFxSurround		       = 'Fx|Surround';             // dedicated to surround processing: LFE Splitter, Bass Manager...
     kFxTools	             = 'Fx|Tools';                // Volume, Mixer, Tuner...

     kInstrument			       = 'Instrument';	              // Effect used as instrument (sound generator), not as insert
     kInstrumentDrum         = 'Instrument|Drum';           // Instrument for Drum sounds
     kInstrumentSampler      = 'Instrument|Sampler';        // Instrument based on Samples
     kInstrumentSynth        = 'Instrument|Synth';          // Instrument based on Synthesis
     kInstrumentSynthSampler = 'Instrument|Synth|Sampler';  // Instrument based on Synthesis and Samples
     kInstrumentExternal	   = 'Instrument|External';       // External Instrument (wrapped Hardware)

     kSpatial            = 'Spatial';              // used for SurroundPanner
     kOnlyRealTime		   = 'OnlyRT';	             // indicates that it supports only realtime process call, no processing faster than realtime
     kOnlyOfflineProcess = 'OnlyOfflineProcess';   // used for offline processing Plug-in (will not work as normal insert Plug-in)
     kUpDownMix			     = 'Up-Downmix';		       // used for Mixconverter/Up-Mixer/Down-Mixer
     kAnalyzer			     = 'Analyzer';	           // Meter, Scope, FFT-Display, not selectable as insert plugin

     kCatMono		  = 'Mono';		   // used for Mono only Plug-in [optional]
     kCatStereo		= 'Stereo';	   // used for Stereo only Plug-in [optional]
     kCatSurround	= 'Surround';	 // used for Surround only Plug-in [optional]


//------------------------------------------------------------------------
/// Component Flags used as classFlags in PClassInfo2
//------------------------------------------------------------------------
type
    TComponentFlags = int32;

const
     kDistributable       = 1 shl 0;   // Component can be run on remote computer
     kSimpleModeSupported = 1 shl 1;   // Component supports simple io mode (or works in simple mode anyway)

//------------------------------------------------------------------------
/// Symbolic sample size
//------------------------------------------------------------------------
type
    TSymbolicSampleSizes = int32;

const
     kSample32 = 0;   // 32-bit precision
     kSample64 = 1;   // 64-bit precision


//------------------------------------------------------------------------
// Processing mode informs the Plug-in about the context and at which frequency the process call is called.
// VST3 defines 3 modes:
// - kRealtime: each process call is called at a realtime frequency (defined by [numSamples of ProcessData] / samplerate).
//              The Plug-in should always try to process as fast as possible in order to let enough time slice to other Plug-ins.
// - kPrefetch: each process call could be called at a variable frequency (jitter, slower / faster than realtime),
//              the Plug-in should process at the same quality level than realtime, Plug-in must not slow down to realtime (e.g. disk streaming)!
//              The host should avoid to process in kPrefetch mode such sampler based Plug-in.
// - kOffline:  each process call could be faster than realtime or slower, higher quality than realtime could be used.
//              Plug-ins using disk streaming should be sure that they have enough time in the process call for streaming,
// 			 if needed by slowing down to realtime or slower.
//
// Note about Process Modes switching:
// 	-Switching between kRealtime and kPrefetch process modes are done in realtime thread without need of calling
// 	 IAudioProcessor::setupProcessing, the Plug-in should check in process call the member processMode of ProcessData
// 	 in order to know in which mode it is processed.
// 	-Switching between kRealtime (or kPrefetch) and kOffline requires that the host calls IAudioProcessor::setupProcessing
// 	 in order to inform the Plug-in about this mode change.
//
//------------------------------------------------------------------------

type
    TProcessModes = int32;

const
     kRealtime = 0;   // realtime processing
     kPrefetch = 1;   // prefetch processing
     kOffline  = 2;   // offline processing

//------------------------------------------------------------------------
// Tail enum.
// see IAudioProcessor::getTailSamples
//------------------------------------------------------------------------
const
     kNoTail		   = 0;			     // to be returned by getTailSamples when no tail is wanted
     kInfiniteTail = $ffffffff;	 // to be returned by getTailSamples when infinite tail is wanted

//------------------------------------------------------------------------
// Audio processing setup.
//------------------------------------------------------------------------
type
    PProcessSetup = ^TProcessSetup;
    TProcessSetup = record
      processMode        : int32;         // see TProcessModes
      symbolicSampleSize : int32;         // see TSymbolicSampleSize
      maxSamplesPerBlock : int32;         // maximum number of samples per audio block
      sampleRate         : TSampleRate;   // sample rate
    end;

//------------------------------------------------------------------------
(* /** Processing buffers of an audio bus.
This structure contains the processing buffer for each channel of an audio bus.
- The number of channels (numChannels) must always match the current bus arrangement.
- The size of the channel buffer array must always match the number of channels. So the host
  must always supply an array for the channel buffers, regardless if the
  bus is active or not. However, if an audio bus is currently inactive, the actual sample
  buffer addresses are safe to be null.
- The silent flag is set when every sample of the according buffer has the value '0'. It is
  intended to be used as help for optimizations allowing a plug-in to reduce processing activities.
  But even if this flag is set for a channel, the channel buffers must still point to valid memory!
  This flag is optional. A host is free to support it or not.
 *)
type
    PAudioBusBuffers = ^TAudioBusBuffers;
    TAudioBusBuffers = record
      numChannels  : int32;   // number of audio channels in bus
      silenceFlags : uint64;  // Bitset of silence state per channel
      case int32 of
        kSample32: (channelBuffers32: PPSample32);   // sample buffers to process with 32-bit precision
        kSample64: (channelBuffers64: PPSample64);   // sample buffers to process with 64-bit precision
    end;

    TAudioBusBuffersArray = array[0..0] of TAudioBusBuffers;
    PAudioBusBuffersArray = ^TAudioBusBuffersArray;

//------------------------------------------------------------------------
(** Description of audio processing data.
	The host prepares AudioBusBuffers for each input/output bus,
	regardless of the bus activation state. Bus buffer indices always match
	with bus indices used in IComponent::getBusInfo of media type kAudio. *)
//------------------------------------------------------------------------
type
    TProcessData = record
      processMode            : int32;               // see TProcessModes
      symbolicSampleSize     : int32;               // see TSymbolicSampleSizes
      numSamples             : int32;               // number of samples to process
      numInputs              : int32;               // number of audio input busses
      numOutputs             : int32;               // number of audio output busses
      inputs                 : PAudioBusBuffers;    // buffers of input busses
      outputs                : PAudioBusBuffers;    // buffers of output busses
      inputParameterChanges  : IParameterChanges;   // incoming parameter changes for this block
      outputParameterChanges : IParameterChanges;   // outgoing parameter changes for this block (optional)
      inputEvents            : IEventList;          // incoming events for this block (optional)
      outputEvents           : IEventList;          // outgoing events for this block (optional)
      processContext         : PProcessContext;     // processing context (optional, but most welcome)
    end;

//------------------------------------------------------------------------
//  IAudioProcessor Interface
//------------------------------------------------------------------------
(** Audio Processing Interface.
[plug imp]
[extends IComponent]
IAudioProcessor must always be supported by audio processing plugins.
*)
const
     UID_IAudioProcessor: TGUID = '{42043F99-B7DA-453C-A569-E79D9AAEC33D}';

type
    IAudioProcessor = interface(FUnknown)
    ['{42043F99-B7DA-453C-A569-E79D9AAEC33D}']
      (* Try to set (from host) a predefined arrangement for inputs and outputs.
         The host should always deliver the same number of input and output buses than the Plug-in needs (see \ref IComponent::getBusCount).
           The Plug-in returns kResultFalse if wanted arrangements are not supported.
           If the Plug-in accepts these arrangements, it should modify its buses to match the new arrangements
           (asked by the host with IComponent::getInfo () or IAudioProcessor::getBusArrangement ()) and then return kResultTrue.
           If the Plug-in does not accept these arrangements, but can adapt its current arrangements (according to the wanted ones),
           it should modify its buses arrangements and return kResultFalse. *)
      function SetBusArrangements(inputs: PSpeakerArrangement; numIns: int32; outputs: PSpeakerArrangement; numOuts: int32): TResult; stdcall;
      (* Gets the bus arrangement for a given direction (input/output) and index.
         Note: IComponent::getInfo () and IAudioProcessor::getBusArrangement () should be always return the same information about the buses arrangements. *)
      function GetBusArrangement(dir: TBusDirection; index: int32; var arr: TSpeakerArrangement): TResult; stdcall;
      // Ask if a given samplesize is supported (@see ProcessSampleSize).
      function CanProcessSampleSize(symbolicSampleSize: int32): TResult; stdcall;
      (* Gets the current Latency in samples.
           The returned value defines the group delay or the latency of the Plug-in. For example, if the Plug-in internally needs
           to look in advance (like compressors) 512 samples then this Plug-in should report 512 as latency.
           If during the use of the Plug-in this latency change, the Plug-in has to inform the host by using IComponentHandler::restartComponent (kLatencyChanged),
           this could lead to audio playback interruption because the host has to recompute its internal mixer delay compensation.
           Note that for player live recording this latency should be zero or small. *)
      function GetLatencySamples: uint32; stdcall;
      // Called in disable state (not active) before processing will begin.
      function SetupProcessing(var setup: TProcessSetup): TResult; stdcall;
      (* Informs the Plug-in about the processing state. This will be called before process calls (once or more) start with true and after with false.
           In this call the Plug-in should do only light operation (no memory allocation or big setup reconfiguration), this could be used to reset some
           buffers (like Delay line or Reverb). *)
      function SetProcessing(state: TBool): TResult; stdcall;
      // The Process call, where all information (parameter changes, event, audio buffer) are passed.
      function Process(var data: TProcessData): TResult; stdcall;
      (* Gets tail size in samples. For example, if the Plug-in is a Reverb Plug-in and it knows that
           the maximum length of the Reverb is 2sec, then it has to return in getTailSamples() (in VST2 it was getGetTailSize ()): 2*sampleRate.
           This information could be used by host for offline processing, process optimization and downmix (avoiding signal cut (clicks)).
           It should return:
           - kNoTail when no tail
           - x * sampleRate when x Sec tail.
           - kInfiniteTail when infinite tail. *)
      function GetTailSamples: uint32; stdcall;
    end;

//------------------------------------------------------------------------
(** Extended IAudioProcessor interface for a component.
\ingroup vstIPlug
- [plug imp]
- [extends IAudioProcessor]
- [released: 3.1.0]

Inform the plug-in about how long from the moment of generation/acquiring (from file or from Input)
it will take for its input to arrive, and how long it will take for its output to be presented (to output or to Speaker).

Note for Input Presentation Latency: when reading from file, the first plug-in will have an input presentation latency set to zero.
When monitoring audio input from a Audio Device, then this initial input latency will be the input latency of the Audio Device itself.

Note for Output Presentation Latency: when writing to a file, the last plug-in will have an output presentation latency set to zero.
When the output of this plug-in is connected to a Audio Device then this initial output latency will be the output latency of the Audio Device itself.

A value of zero means either no latency or an unknown latency.

Each plug-in adding a latency (returning a none zero value for IAudioProcessor::getLatencySamples) will modify the input presentation latency of the next
plug-ins in the mixer routing graph and will modify the output presentation latency of the previous plug-ins.
\see IAudioProcessor
\see IComponent*)
const
     UID_IAudioPresentationLatency : TGUID = '{309ECE78-EB7D-4FAE-8B22-25D909FD08B6}';

type
    IAudioPresentationLatency = interface(FUnknown)
      // Inform the plug-in about the Audio Presentation Latency in samples for a given direction (kInput/kOutput) and bus index.
      function setAudioPresentationLatencySamples(dir: TBusDirection; busIndex: int32; latencyInSamples: uint32): TResult; stdcall;
    end;



(***********************
    IVSTMESSAGE.H
************************)

//------------------------------------------------------------------------
// IMessage Interface
//------------------------------------------------------------------------
const
     UID_IMessage: TGUID = '{936F033B-C6C0-47DB-BB08-82F813C1E613}';

type
    IMessage = interface(FUnknown)
      // Returns the message ID (for example "TextMessage").
      function GetMessageID: PAnsiChar; stdcall;
      // Sets a message ID (for example "TextMessage").
      procedure SetMessageID(id: PAnsiChar); stdcall;
      // Returns the attribute list associated to the message.
      function GetAttributes: pointer{IAttributeList}; stdcall;
    end;



//------------------------------------------------------------------------
// IConnectionPoint Interface
//------------------------------------------------------------------------
const
     UID_IConnectionPoint: TGUID = '{70A4156F-6E6E-4026-9891-48BFAA60D8D1}';

type
    IConnectionPoint = interface(FUnknown)
      // Connects this instance with an another connection point.
      function Connect(other: IConnectionPoint): TResult; stdcall;
      // Disconnects a given connection point from this.
      function Disconnect(other: IConnectionPoint): TResult; stdcall;
      // Called when a message has been send from the connection point to this.
      function Notify(msg: IMessage): TResult; stdcall;
    end;



(*****************************
    IVSTHOSTAPPLICATION.H
******************************)

//------------------------------------------------------------------------
// IHostApplication Interface
//------------------------------------------------------------------------
(*  VST Host Interface
[host imp]
Basic VST host application interface.
*)
const
     UID_IHostApplication: TGUID = '{58E595CC-DB2D-4969-8B6A-AF8C36A664E5}';

type
    IHostApplication = interface(FUnknown)
      // Gets host application name.
      function GetName(name: PString128): TResult; stdcall;
      // Create host object (e.g. Vst::IMessage).
      function CreateInstance(cid: TUID; iid: TUID; var obj: pointer): TResult; stdcall;
    end;

//------------------------------------------------------------------------



(****************************
    IVSTEDITCONTROLLER.H
*****************************)

//------------------------------------------------------------------------
// Class Categories
//------------------------------------------------------------------------
const
     kVstComponentControllerClass = 'Component Controller Class';

//------------------------------------------------------------------------
// GUI Parameter Info
//------------------------------------------------------------------------
type
    TParameterFlags = int32;

const
     kCanAutomate     = 1 shl 0;   // parameter can be automated
     kIsReadOnly      = 1 shl 1;   // parameter can not be changed from outside (implies that kCanAutomate is false)
     kIsProgramChange = 1 shl 15;  // parameter is a program change (unitId gives info about associated program list)
     kIsBypass        = 1 shl 16;  // special bypass parameter (only one allowed): plugin can handle bypass

type
    TParameterInfo = record
      id                     : TParamID;         // unique identifier of this parameter
      title                  : TString128;       // parameter title (e.g. "Volume")
      shortTitle             : TString128;       // parameter shortTitle (e.g. "Vol")
      units                  : TString128;       // parameter unit (e.g. "dB")
      stepCount              : int32;            // number of discrete steps (0: continuous, 1: toggle, discrete value otherwise)
      defaultNormalizedValue : TParamValue;      // default normalized value
      unitId                 : TUnitID;          // id of unit this parameter belongs to
      flags                  : TParameterFlags;  // ParameterFlags (see below)
    end;


//------------------------------------------------------------------------
// View Types used for IEditController::createView
//------------------------------------------------------------------------
const
     kEditor = 'editor';

//------------------------------------------------------------------------
// Flags used for IComponentHandler::restartComponent
//------------------------------------------------------------------------
type
    TRestartFlags = int32;

const
     kReloadComponent         = 1 shl 0;	// the Component should be reloaded
     kIoChanged               = 1 shl 1;	// Input and/or Output Bus configuration has changed
     kParamValuesChanged      = 1 shl 2;	// multiple parameter values have changed (as result of a program change for example)
     kLatencyChanged          = 1 shl 3;	// latency has changed (IAudioProcessor->getLatencySamples)
     kParamTitlesChanged      = 1 shl 4;	// parameter titles have changed
     kMidiCCAssignmentChanged = 1 shl 5;  // Midi Controller Assignments have changed [SDK 3.0.1]
     kNoteExpressionChanged		= 1 shl 6;  // Note Expression has changed (info, count...) [SDK 3.5.0]
     kIoTitlesChanged		      = 1 shl 7;  // Input and/or Output bus titles have changed  [SDK 3.5.0]

//------------------------------------------------------------------------
(* Host callback interface for an edit controller.
- Transfer parameter editing to component via host and support automation
- Cause the host to react on configuration changes (restartComponent)    *)
//------------------------------------------------------------------------
const
     UID_IComponentHandler: TGUID = '{93A0BEA3-0BD0-45DB-8E89-0B0CC1E46AC6}';

type
    IComponentHandler = interface(FUnknown)
      // Transfer parameter editing to component via host.
      // To be called before calling a performEdit (when mouse down for example).
      function BeginEdit(tag: TParamID): TResult; stdcall;
      // Called between beginEdit and endEdit to inform the handler that a given parameter has a new value.
      function PerformEdit(tag: TParamID; valueNormalized: TParamValue): TResult; stdcall;
      // To be called after calling a performEdit (when mouse up for example).
      function EndEdit(tag: TParamID): TResult; stdcall;
      // Instruct host to restart the component.
      // - flags is a combination of RestartFlags
      function RestartComponent(flags: int32): TResult; stdcall;
    end;



//------------------------------------------------------------------------
(** Extended Host callback interface IComponentHandler2 for an edit controller.
\ingroup vstIHost
- [host imp]
- [extends IComponentHandler]
- [released: 3.1.0]

One part handles:
- Setting dirty state of plug-in
- requesting the host to open the editor

The other part handles parameter group editing from plug-in UI. It wraps a set of \ref IComponentHandler::beginEdit /
\ref IComponentHandler::performEdit / \ref IComponentHandler::endEdit functions (see \ref IComponentHandler)
which should use the same timestamp in the host when writing automation.
This allows for better synchronizing multiple parameter changes at once.
\note Examples of different use cases:
\verbatim
	//--------------------------------------
	// in case of multiple switch buttons (with associated ParamID 1 and 3)
	// on mouse down :
	hostHandler2->startGroupEdit ();
	hostHandler->beginEdit (1);
	hostHandler->beginEdit (3);
	hostHandler->performEdit (1, 1.0);
	hostHandler->performEdit (3, 0.0); // the opposite of paramID 1 for example
	....
	// on mouse up :
	hostHandler->endEdit (1);
	hostHandler->endEdit (3);
	hostHandler2->finishGroupEdit ();
	....
	....
	//--------------------------------------
	// in case of multiple faders (with associated ParamID 1 and 3)
	// on mouse down :
	hostHandler2->startGroupEdit ();
	hostHandler->beginEdit (1);
	hostHandler->beginEdit (3);
	hostHandler2->finishGroupEdit ();
	....
	// on mouse move :
	hostHandler2->startGroupEdit ();
	hostHandler->performEdit (1, x); // x the wanted value
	hostHandler->performEdit (3, x);
	hostHandler2->finishGroupEdit ();
	....
	// on mouse up :
	hostHandler2->startGroupEdit ();
	hostHandler->endEdit (1);
	hostHandler->endEdit (3);
	hostHandler2->finishGroupEdit ();
\endverbatim
\see IComponentHandler
\see IEditController*)
//------------------------------------------------------------------------
const
     UID_IComponentHandler2 : TGUID = '{F040B4B3-A360-45EC-ABCD-C045B4D5A2CC}';

type
    IComponentHandler2 = interface(FUnknown)
	    // Tells host that the plug-in is dirty (something besides parameters has changed since last save),
      // if true the host should apply a save before quitting.
      function setDirty(state: TBool): TResult; stdcall;

	    // Tells host that it should open the plug-in editor the next time it's possible.
      // You should use this instead of showing an alert and blocking the program flow (especially on loading projects).
      function requestOpenEditor(name: FIDString): TResult; stdcall;

      // Start the group editing (call before a IComponentHandler::beginEdit),
      // the host will keep the current timestamp at this call and will use it for all IComponentHandler::beginEdit,
      // IComponentHandler::performEdit & IComponentHandler::endEdit calls until a finishGroupEdit ().
      function startGroupEdit: TResult; stdcall;

      // Finish the group editing started by a \ref startGroupEdit (call after a \ref IComponentHandler::endEdit).
      function finishGroupEdit: TResult; stdcall;
    end;



//------------------------------------------------------------------------
// IEditController Interface
//------------------------------------------------------------------------
const
     UID_IEditController: TGUID = '{DCD7BBE3-7742-448D-A874-AACC979C759E}';

type
    IEditController = interface(IPluginBase)
         ['{DCD7BBE3-7742-448D-A874-AACC979C759E}']

      // Receive the component state.
      function SetComponentState(state: IBStream): TResult; stdcall;
      // Set the controller state.
      function SetState(state: IBStream): TResult; stdcall;
      // Gets the controller state.
      function GetState(state: IBStream): TResult; stdcall;

      // parameters -------------------------
      // Returns the number of parameter exported.
      function GetParameterCount: int32; stdcall;
      // Gets for a given index the parameter information.
      function GetParameterInfo(paramIndex: int32; out info: TParameterInfo): TResult; stdcall;
      // Gets for a given paramID and normalized value its associated AnsiString representation.
      function GetParamStringByValue(tag: TParamID; valueNormalized: TParamValue; text: PString128): TResult; stdcall;
      // Gets for a given paramID and AnsiString its normalized value.
      function GetParamValueByString(tag: TParamID; text: PTChar; out valueNormalized: TParamValue): TResult; stdcall;
      // Returns for a given paramID and a normalized value its plain representation (for example 1000 for 1000Hz).
      function NormalizedParamToPlain(tag: TParamID; valueNormalized: TParamValue): TParamValue; stdcall;
      // Returns for a given paramID and a plain value its normalized value.
      function PlainParamToNormalized(tag: TParamID; plainValue: TParamValue): TParamValue; stdcall;
      // Returns the normalized value of the parameter associated to the paramID.
      function GetParamNormalized(tag: TParamID): TParamValue; stdcall;
      // Sets the normalized value to the parameter associated to the paramID. The controller must never
      // pass this value change back to the host via the IComponentHandler. It should update the according
      // GUI element(s) only!
      function SetParamNormalized(tag: TParamID; value: TParamValue): TResult; stdcall;

      // handler ----------------------------
      // Gets from host a handler.
      function SetComponentHandler(handler: IComponentHandler): TResult; stdcall;

      // view -------------------------------
      (* Creates the editor view of the Plug-in, currently only "editor" is supported, see \ref ViewType.
         The life time of the editor view will never exceed the life time of this controller instance. *)
      function CreateView(name: PAnsiChar): pointer; stdcall;
    end;

//------------------------------------------------------------------------
// Knob Mode
//------------------------------------------------------------------------
type
    TKnobMode = int32;

const
     kCircularMode        = 0;  // Circular with jump to clicked position
     kRelativCircularMode = 1;	// Circular without jump to clicked position
     kLinearMode          = 2;  // Linear: depending on vertical movement

//------------------------------------------------------------------------
(** Edit controller component interface extension.
\ingroup vstIPlug
- [plug imp]
- [extends IEditController]
- [released: 3.1.0]

Extension to inform the plug-in about the host Knob Mode,
and to open the plug-in about box or help documentation.

\see IEditController*)
//------------------------------------------------------------------------
const
     UID_IEditController2 : TGUID = '{7F4EFE59-F320-4967-AC27-A3AEAFB63038}';

type
    IEditController2 = interface(IPluginBase)
      // Host could set the Knob Mode for the plug-in. Return kResultFalse means not supported mode. \see KnobModes.
      function setKnobMode(mode: TKnobMode): TResult; stdcall;

      // Host could ask to open the plug-in help (could be: opening a PDF document or link to a web page).
      // The host could call it with onlyCheck set to true for testing support of open Help. Return kResultFalse means not supported function.
      function openHelp(onlyCheck: TBool): TResult; stdcall;

      // Host could ask to open the plug-in about box.
      // The host could call it with onlyCheck set to true for testing support of open AboutBox. Return kResultFalse means not supported function.
      function openAboutBox(onlyCheck: TBool): TResult; stdcall;
    end;

//------------------------------------------------------------------------
// Midi Mapping Interface.
//
// MIDI controllers are not transmitted directly to a VST component. MIDI as hardware protocol has
// restrictions that can be avoided in software. Controller data in particular come along with unclear
// and often ignored semantics. On top of this they can interfere with regular parameter automation and
// the host is unaware of what happens in the Plug-in when passing MIDI controllers directly.
//
// So any functionality that is to be controlled by MIDI controllers must be exported as regular parameter.
// The host will transform incoming MIDI controller data using this interface and transmit them as normal
// parameter change. This allows the host to automate them in the same way as other parameters.
// CtrlNumber could be typical MIDI controller value extended to some others values like pitch bend or after touch (see ControllerNumbers).
// If the mapping has changed, the Plug-in should call IComponentHandler::restartComponent (kMidiCCAssignmentChanged)
// to inform the host about this change.
//------------------------------------------------------------------------
const
     UID_IMidiMapping: TGUID = '{DF0FF9F7-49B7-4669-B63A-B7327ADBF5E5}';

type
    IMidiMapping = interface(FUnknown)
      [ '{DF0FF9F7-49B7-4669-B63A-B7327ADBF5E5}' ]
      // Gets an (preferred) associated ParamID for a given Input Event Bus index, channel and MIDI Controller.
      function getMidiControllerAssignment(busIndex: int32; channel: int16; midiControllerNumber: TCtrlNumber; out tag: TParamID): TResult; stdcall;
    end;

    IMidiLearn = interface(FUnknown)
      [ '{6B2449CC-4197-40B5-AB3C-79DAC5FE5C86}' ]
	  (* Called on live input MIDI-CC change associated to a given bus index and MIDI channel *)
	    function onLiveMIDIControllerInput (busIndex: int32; channel: int16; midiControllerNumber: TCtrlNumber):TResult; stdcall;
end;


//------------------------------------------------------------------------
// Parameter Editing from Host.
//
// If this interface is implemented by the edit controller and when performing edits from outside
// the Plug-in (host / remote) of a not automatable and not read only flagged parameter (kind of helper parameter), the host will start
// with a beginEditFromHost before calling setParamNormalized and end with a endEditFromHost.
// Here the sequencing, the host will call:
// - beginEditFromHost ()
// - setParamNormalized ()
// - setParamNormalized ()
// - ...
// - endEditFromHost ()
//
//------------------------------------------------------------------------
const
     UID_IEditControllerHostEditing: TGUID = '{C1271208-7059-4098-B9DD-34B36BB0195E}';

type
    IEditControllerHostEditing = interface(FUnknown)
      // Called before a setParamNormalized sequence, a endEditFromHost will be call at the end of the editing action.
      function beginEditFromHost(paramID: TParamID): TResult; stdcall;
      // Called after a beginEditFromHost and a sequence of setParamNormalized.
      function endEditFromHost(paramID: TParamID): TResult; stdcall;
    end;



(********************
    IVSTUNITS.H
*********************)

const
     // special UnitIDs for UnitInfo
     kRootUnitId      = 0;     // to indicate that this unit is at top level (root);
     kNoParentUnitId  = -1;    // used for root unit which doesnt have a parent.

     // special ProgramListIDs for UnitInfo
     kNoProgramListId = -1;    // to indicate that no programs are used in the unit.

//------------------------------------------------------------------------
// Basic Unit Description.
//------------------------------------------------------------------------
type
    PUnitInfo = ^TUnitInfo;
    TUnitInfo = record
      id            : TUnitID;          // unit identifier
      parentUnitId  : TUnitID;          // identifier of parent unit (kNoParentUnitId: does not apply, this unit is the root)
      name          : TString128;       // name, optional for the root component, required otherwise
      programListId : TProgramListID;   // id of program list used in unit (kNoProgramListId = no programs used in this unit)
    end;

//------------------------------------------------------------------------
// Basic Program List Description.
//------------------------------------------------------------------------
type
    TProgramListInfo = record
      id           : TProgramListID;   // program list identifier
      name         : TString128;       // name of program list
      programCount : int32;            // number of programs in this list
    end;

//------------------------------------------------------------------------
// IUnitHandler Interface
//------------------------------------------------------------------------

// some defines for IUnitHandler
const
     kAllProgramInvalid = -1;   // all program information is invalid

(**
[host imp]
[extends IComponentHandler]

Host callback interface, used with IUnitInfo.
Retrieve via queryInterface from IComponentHandler.
*)
const
     UID_IUnitHandler: TGUID = '{4B5147F8-4654-486B-8DAB-30BA163A3C56}';

type
    IUnitHandler = interface(FUnknown)
      // Notify host when a module is selected in plugin gui
      function NotifyUnitSelection(unitId: TUnitID): TResult; stdcall;
      // Tell host that the plugin controller changed a program list (rename, load, PitchName changes).
      // - programIndex : when kAllProgramInvalid, all program information is invalid, otherwise only the program of given index
      function NotifyProgramListChange(listId: TProgramListID; programIndex: int32): TResult; stdcall;
    end;



//------------------------------------------------------------------------
//  IUnitInfo Interface
//------------------------------------------------------------------------
(*  Interface for describing plugin structure on controller side.
[plug imp]
[extends IEditController]

IUnitInfo describes the internal structure of the plugin.

the root unit is the component itself, so getUnitCount must return 1 at least.
the root unit id should be kRootUnitId (0).
each unit can reference one program list - this reference must not change.
each unit using a program list, references one program of the list.
*)
const
     UID_IUnitInfo: TGUID = '{3D4BD6B5-913A-4FD2-A886-E768A5EB92C1}';

type
    IUnitInfo = interface(FUnknown)
      [ '{3D4BD6B5-913A-4FD2-A886-E768A5EB92C1}' ]
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
    end;



//------------------------------------------------------------------------
//  IUnitData Interface
//------------------------------------------------------------------------
(*  Interface for accessing program data on component side.
[plug imp]
[extends IComponent]
*)
const
     UID_IProgramListData: TGUID = '{8683B01F-7B35-4F70-A265-1DEC353AF4FF}';

type
    IProgramListData = interface(FUnknown)
      // Returns kResultTrue if the given Program List ID supports Program Data.
      function ProgramDataSupported(listId: TProgramListID): TResult; stdcall;
      // Gets for a given program list ID and program index the program Data.
      function GetProgramData(listId: TProgramListID; programIndex: int32; data: IBStream): TResult; stdcall;
      // Sets for a given program list ID and program index a program Data.
      function SetProgramData(listId: TProgramListID; programIndex: int32; data: IBStream): TResult; stdcall;
    end;

//------------------------------------------------------------------------
(* Component extension to access unit data.
- [plug imp]
- [extends IComponent]

A component can either support unit preset data via this interface or
program list data (IProgramListData), but not both! *)
//------------------------------------------------------------------------
const
     UID_IUnitData: TGUID = '{6C389611-D391-455D-B870-B83394A0EFDD}';

type
    IUnitData = interface(FUnknown)
      // Returns kResultTrue if the specified unit supports export and import of preset data.
      function UnitDataSupported(unitID: TUnitID): TResult; stdcall;

      // Gets the preset data for the specified unit.
      function GetUnitData(unitId: TUnitID; data: IBStream): TResult; stdcall;

      // Sets the preset data for the specified unit.
      function SetUnitData(unitId: TUnitID; data: IBStream): TResult; stdcall;
    end;



(************************
    VSTPRESETKEYS.H
*************************)

const
     kPlugInName        = 'PlugInName';          // Plug-in name
     kPlugInCategory    = 'PlugInCategory';      // e.g. "Fx|Dynamics", "Instrument", "Instrument|Synth"
     kMusicalInstrument = 'MusicalInstrument';   // eg. instrument group (like 'Piano' or 'Piano|A. Piano')
     kStyle             = 'MusicalStyle';        // eg. 'Pop', 'Jazz', 'Classic'
     kCharacter         = 'MusicalCharacter';    // eg. instrument nature (like 'Soft' 'Dry' 'Acoustic')



//------------------------------------------------------------------------
// Predefined Musical Instrument
//------------------------------------------------------------------------
const
     kAccordion               = 'Accordion';
     kAccordionAccordion      = 'Accordion|Accordion';
     kAccordionHarmonica      = 'Accordion|Harmonica';
     kAccordionOther          = 'Accordion|Other';

     kBass                    = 'Bass';
     kBassABass               = 'Bass|A. Bass';
     kBassEBass               = 'Bass|E. Bass';
     kBassSynthBass           = 'Bass|Synth Bass';
     kBassOther               = 'Bass|Other';

     kBrass                   = 'Brass';
     kBrassFrenchHorn         = 'Brass|French Horn';
     kBrassTrumpet            = 'Brass|Trumpet';
     kBrassTrombone           = 'Brass|Trombone';
     kBrassTuba               = 'Brass|Tuba';
     kBrassSection            = 'Brass|Section';
     kBrassSynth              = 'Brass|Synth';
     kBrassOther              = 'Brass|Other';

     kChromaticPerc           = 'Chromatic Perc';
     kChromaticPercBell       = 'Chromatic Perc|Bell';
     kChromaticPercMallett    = 'Chromatic Perc|Mallett';
     kChromaticPercWood       = 'Chromatic Perc|Wood';
     kChromaticPercPercussion = 'Chromatic Perc|Percussion';
     kChromaticPercTimpani    = 'Chromatic Perc|Timpani';
     kChromaticPercOther      = 'Chromatic Perc|Other';

     kDrumPerc                = 'Drum&Perc';
     kDrumPercDrumsetGM       = 'Drum&Perc|Drumset GM';
     kDrumPercDrumset         = 'Drum&Perc|Drumset';
     kDrumPercDrumMenues      = 'Drum&Perc|Drum Menues';
     kDrumPercBeats	          = 'Drum&Perc|Beats';
     kDrumPercPercussion      = 'Drum&Perc|Percussion';
     kDrumPercKickDrum        = 'Drum&Perc|Kick Drum';
     kDrumPercSnareDrum       = 'Drum&Perc|Snare Drum';
     kDrumPercToms            = 'Drum&Perc|Toms';
     kDrumPercHiHats          = 'Drum&Perc|HiHats';
     kDrumPercCymbals         = 'Drum&Perc|Cymbals';
     kDrumPercOther           = 'Drum&Perc|Other';

     kEthnic                  = 'Ethnic';
     kEthnicAsian             = 'Ethnic|Asian';
     kEthnicAfrican           = 'Ethnic|African';
     kEthnicEuropean          = 'Ethnic|European';
     kEthnicLatin             = 'Ethnic|Latin';
     kEthnicAmerican          = 'Ethnic|American';
     kEthnicAlien             = 'Ethnic|Alien';
     kEthnicOther             = 'Ethnic|Other';

     kGuitar                  = 'Guitar/Plucked';
     kGuitarAGuitar           = 'Guitar/Plucked|A. Guitar';
     kGuitarEGuitar           = 'Guitar/Plucked|E. Guitar';
     kGuitarHarp              = 'Guitar/Plucked|Harp';
     kGuitarEthnic            = 'Guitar/Plucked|Ethnic';
     kGuitarOther             = 'Guitar/Plucked|Other';

//------------------------------------------------------------------------
// Predefined Musical Style
//------------------------------------------------------------------------
const
     kAlternativeIndie					            = 'Alternative/Indie';
     kAlternativeIndieGothRock			        = 'Alternative/Indie|Goth Rock';
     kAlternativeIndieGrunge			          = 'Alternative/Indie|Grunge';
     kAlternativeIndieNewWave			          = 'Alternative/Indie|New Wave';
     kAlternativeIndiePunk				          = 'Alternative/Indie|Punk';
     kAlternativeIndieCollegeRock           = 'Alternative/Indie|College Rock';
     kAlternativeIndieDarkWave			        = 'Alternative/Indie|Dark Wave';
     kAlternativeIndieHardcore			        = 'Alternative/Indie|Hardcore';

     kAmbientChillOut					              = 'Ambient/ChillOut';
     kAmbientChillOutNewAgeMeditation	      = 'Ambient/ChillOut|New Age/Meditation';
     kAmbientChillOutDarkAmbient		        = 'Ambient/ChillOut|Dark Ambient';
     kAmbientChillOutDowntempo			        = 'Ambient/ChillOut|Downtempo';
     kAmbientChillOutLounge			            = 'Ambient/ChillOut|Lounge';

     kBlues							                    = 'Blues';
     kBluesAcousticBlues				            = 'Blues|Acoustic Blues';
     kBluesCountryBlues				              = 'Blues|Country Blues';
     kBluesElectricBlues				            = 'Blues|Electric Blues';
     kBluesChicagoBlues				              = 'Blues|Chicago Blues';

     kClassical						                  = 'Classical';
     kClassicalBaroque					            = 'Classical|Baroque';
     kClassicalChamberMusic			            = 'Classical|Chamber Music';
     kClassicalMedieval				              = 'Classical|Medieval';
     kClassicalModernComposition		        = 'Classical|Modern Composition';
     kClassicalOpera					              = 'Classical|Opera';
     kClassicalGregorian				            = 'Classical|Gregorian';
     kClassicalRenaissance				          = 'Classical|Renaissance';
     kClassicalClassic					            = 'Classical|Classic';
     kClassicalRomantic				              = 'Classical|Romantic';
     kClassicalSoundtrack				            = 'Classical|Soundtrack';

     kCountry							                  = 'Country';
     kCountryCountryWestern			            = 'Country|Country/Western';
     kCountryHonkyTonk					            = 'Country|Honky Tonk';
     kCountryUrbanCowboy				            = 'Country|Urban Cowboy';
     kCountryBluegrass					            = 'Country|Bluegrass';
     kCountryAmericana					            = 'Country|Americana';
     kCountrySquaredance				            = 'Country|Squaredance';
     kCountryNorthAmericanFolk			        = 'Country|North American Folk';

     kElectronicaDance					            = 'Electronica/Dance';
     kElectronicaDanceMinimal			          = 'Electronica/Dance|Minimal';
     kElectronicaDanceClassicHouse		      = 'Electronica/Dance|Classic House';
     kElectronicaDanceElektroHouse		      = 'Electronica/Dance|Elektro House';
     kElectronicaDanceFunkyHouse		        = 'Electronica/Dance|Funky House';
     kElectronicaDanceIndustrial		        = 'Electronica/Dance|Industrial';
     kElectronicaDanceElectronicBodyMusic	  = 'Electronica/Dance|Electronic Body Music';
     kElectronicaDanceTripHop			          = 'Electronica/Dance|Trip Hop';
     kElectronicaDanceTechno			          = 'Electronica/Dance|Techno';
     kElectronicaDanceDrumNBassJungle	      = 'Electronica/Dance|Drum''n''Bass/Jungle';
     kElectronicaDanceElektro			          = 'Electronica/Dance|Elektro';
     kElectronicaDanceTrance			          = 'Electronica/Dance|Trance';
     kElectronicaDanceDub				            = 'Electronica/Dance|Dub';
     kElectronicaDanceBigBeats			        = 'Electronica/Dance|Big Beats';

     kExperimental						              = 'Experimental';
     kExperimentalNewMusic				          = 'Experimental|New Music';
     kExperimentalFreeImprovisation        	= 'Experimental|Free Improvisation';
     kExperimentalElectronicArtMusic	      = 'Experimental|Electronic Art Music';
     kExperimentalNoise				              = 'Experimental|Noise';

     kJazz								                  = 'Jazz';
     kJazzNewOrleansJazz				            = 'Jazz|New Orleans Jazz';
     kJazzTraditionalJazz			             	= 'Jazz|Traditional Jazz';
     kJazzOldtimeJazzDixiland			          = 'Jazz|Oldtime Jazz/Dixiland';
     kJazzFusion						                = 'Jazz|Fusion';
     kJazzAvantgarde					              = 'Jazz|Avantgarde';
     kJazzLatinJazz					                = 'Jazz|Latin Jazz';
     kJazzFreeJazz						              = 'Jazz|Free Jazz';
     kJazzRagtime						                = 'Jazz|Ragtime';

     kPop								                    = 'Pop';
     kPopBritpop						                = 'Pop|Britpop';
     kPopRock							                  = 'Pop|Pop/Rock';
     kPopTeenPop						                = 'Pop|Teen Pop';
     kPopChartDance					                = 'Pop|Chart Dance';
     kPop80sPop						                  = 'Pop|80''s Pop';
     kPopDancehall						              = 'Pop|Dancehall';
     kPopDisco							                = 'Pop|Disco';

     kRockMetal						                  = 'Rock/Metal';
     kRockMetalBluesRock				            = 'Rock/Metal|Blues Rock';
     kRockMetalClassicRock				          = 'Rock/Metal|Classic Rock';
     kRockMetalHardRock				              = 'Rock/Metal|Hard Rock';
     kRockMetalRockRoll				              = 'Rock/Metal|Rock &amp; Roll';
     kRockMetalSingerSongwriter		          = 'Rock/Metal|Singer/Songwriter';
     kRockMetalHeavyMetal				            = 'Rock/Metal|Heavy Metal';
     kRockMetalDeathBlackMetal			        = 'Rock/Metal|Death/Black Metal';
     kRockMetalNuMetal					            = 'Rock/Metal|NuMetal';
     kRockMetalReggae					              = 'Rock/Metal|Reggae';
     kRockMetalBallad					              = 'Rock/Metal|Ballad';
     kRockMetalAlternativeRock			        = 'Rock/Metal|Alternative Rock';
     kRockMetalRockabilly				            = 'Rock/Metal|Rockabilly';
     kRockMetalThrashMetal				          = 'Rock/Metal|Thrash Metal';
     kRockMetalProgressiveRock			        = 'Rock/Metal|Progressive Rock';

     kUrbanHipHopRB					                = 'Urban (Hip-Hop / R&B)';
     kUrbanHipHopRBClassic 			            = 'Urban (Hip-Hop / R&B)|Classic R&B';
     kUrbanHipHopRBModern				            = 'Urban (Hip-Hop / R&B)|Modern R&B';
     kUrbanHipHopRBPop					            = 'Urban (Hip-Hop / R&B)|R&B Pop';
     kUrbanHipHopRBWestCoastHipHop		      = 'Urban (Hip-Hop / R&B)|WestCoast Hip-Hop';
     kUrbanHipHopRBEastCoastHipHop		      = 'Urban (Hip-Hop / R&B)|EastCoast Hip-Hop';
     kUrbanHipHopRBRapHipHop			          = 'Urban (Hip-Hop / R&B)|Rap/Hip Hop';
     kUrbanHipHopRBSoul				              = 'Urban (Hip-Hop / R&B)|Soul';
     kUrbanHipHopRBFunk				              = 'Urban (Hip-Hop / R&B)|Funk';

     kWorldEthnic						                = 'World/Ethnic';
     kWorldEthnicAfrica				              = 'World/Ethnic|Africa';
     kWorldEthnicAsia					              = 'World/Ethnic|Asia';
     kWorldEthnicCeltic				              = 'World/Ethnic|Celtic';
     kWorldEthnicEurope				              = 'World/Ethnic|Europe';
     kWorldEthnicKlezmer				            = 'World/Ethnic|Klezmer';
     kWorldEthnicScandinavia			          = 'World/Ethnic|Scandinavia';
     kWorldEthnicEasternEurope			        = 'World/Ethnic|Eastern Europe';
     kWorldEthnicIndiaOriental			        = 'World/Ethnic|India/Oriental';
     kWorldEthnicNorthAmerica			          = 'World/Ethnic|North America';
     kWorldEthnicSouthAmerica			          = 'World/Ethnic|South America';
     kWorldEthnicAustralia				          = 'World/Ethnic|Australia';


//------------------------------------------------------------------------
// Predefined Musical Character
//------------------------------------------------------------------------
const
     //----TYPE------------------------------------
     kmcMono      = 'Mono';
     kmcPoly		  = 'Poly';

     kmcSplit		  = 'Split';
     kmcLayer		  = 'Layer';

     kmcGlide		  = 'Glide';
     kmcGlissando = 'Glissando';

     kmcMajor		  = 'Major';
     kmcMinor		  = 'Minor';

     kmcSingle	  = 'Single';
     kmcEnsemble  = 'Ensemble';


     kmcAcoustic	= 'Acoustic';
     kmcElectric	= 'Electric';

     kmcAnalog		= 'Analog';
     kmcDigital		= 'Digital';

     kmcVintage		= 'Vintage';
     kmcModern		= 'Modern';

     kmcOld			  = 'Old';
     kmcNew			  = 'New';

     //----TONE------------------------------------
     kmcClean		  = 'Clean';
     kmcDistorted	= 'Distorted';

     kmcDry			  = 'Dry';
     kmcProcessed = 'Processed';

     kmcHarmonic  = 'Harmonic';
     kmcDissonant = 'Dissonant';

     kmcClear     = 'Clear';
     kmcNoisy     = 'Noisy';

     kmcThin		  = 'Thin';
     kmcRich		  = 'Rich';

     kmcDark		  = 'Dark';
     kmcBright	  = 'Bright';

     kmcCold		  = 'Cold';
     kmcWarm		  = 'Warm';

     kmcMetallic  = 'Metallic';
     kmcWooden    = 'Wooden';

     kmcGlass     = 'Glass';
     kmcPlastic   = 'Plastic';

     //----ENVELOPE------------------------------------
     kmcPercussive   = 'Percussive';
     kmcSoft         = 'Soft';

     kmcFast         = 'Fast';
     kmcSlow			   = 'Slow';

     kmcShort	       = 'Short';
     kmcLong			   = 'Long';

     kmcAttack		   = 'Attack';
     kmcRelease		   = 'Release';

     kmcDecay	       = 'Decay';
     kmcSustain	     = 'Sustain';

     kmcFastAttack   = 'Fast Attack';
     kmcSlowAttack   = 'Slow Attack';

     kmcShortRelease = 'Short Release';
     kmcLongRelease  = 'Long Release';

     kmcStatic       = 'Static';
     kmcMoving	     = 'Moving';

     kmcLoop		     = 'Loop';
     kmcOneShot	     = 'One Shot';



(************************
    IVSTCONTEXTMENU.H
*************************)

//------------------------------------------------------------------------
// Context Menu Item Target Interface.
//
// A receiver of a menu item should implement this interface, which will be called after the user has selected
// this menu item.
//
// See IComponentHandler3 for more.
//------------------------------------------------------------------------
const
     UID_IContextMenuTarget: TGUID = '{3CDF2E75-85D3-4144-BF86-D36BD7C4894D}';

type
    IContextMenuTarget = interface(FUnknown)
      // Called when an menu item was executed.
      function executeMenuItem(tag: int32): TResult; stdcall;
    end;


//------------------------------------------------------------------------
// Context Menu Interface.
//
// A context menu is composed of Item (entry). A Item is defined by a name, a tag, a flag
// and a associated target (called when this item will be selected/executed).
// With IContextMenu the Plug-in can retrieve a Item, add a Item, remove a Item and pop-up the menu.
//
// See IComponentHandler3 for more.
//------------------------------------------------------------------------
type
    TContextMenuItemFlags = int32;

const
     kIsSeparator  = 1 shl 0;                    // Item is a separator
     kIsDisabled   = 1 shl 1;                    // Item is disabled
     kIsChecked    = 1 shl 2;                    // Item is checked
     kIsGroupStart = 1 shl 3 or kIsDisabled;     // Item is a group start (like sub folder)
     kIsGroupEnd   = 1 shl 4 or kIsSeparator;    // Item is a group end

type
    // TContextMenuItem is a entry element of the context menu.
      TContextMenuItem = record
        name  : TString128;   // Name of the item
        tag   : int32;        // Identifier tag of the item
        flags : int32;        // Flags of the item
      end;

const
     UID_IContextMenu: TGUID = '{2E93C863-0C9C-4588-97DB-ECF5AD17817D}';

type
    IContextMenu = interface(FUnknown)
      // Gets the number of menu items.
      function getItemCount: int32; stdcall;
      // Gets a menu item and its target (target could be not assigned).
      function getItem(index: int32; var item: TContextMenuItem; var target: IContextMenuTarget): TResult; stdcall;
      // Adds a menu item and its target.
      function addItem(const item: TContextMenuItem; target: IContextMenuTarget): TResult; stdcall;
      // Removes a menu item.
      function removeItem(const item: TContextMenuItem; target: IContextMenuTarget): TResult; stdcall;
      // Pop-ups the menu. Coordinates are relative to the top-left position of the Plug-ins view.
      function popup(x, y: TUCoord): TResult; stdcall;
    end;



//------------------------------------------------------------------------
// Extended Host callback interface IComponentHandler3 for an edit controller.
//
// A Plug-in can ask the host to create a context menu for a given exported Parameter ID or a generic context menu.
//
// The host may pre-fill this context menu with specific items regarding the parameter ID like "Show automation for parameter",
// "MIDI learn" etc...
//
// The Plug-in can use the context menu in two ways :
// - add its own items to the menu via the IContextMenu interface and call IContextMenu::popup(..) to pop-up it. See the \ref IContextMenuExample.
// - extract the host menu items and add them to its own created context menu
//
// Note: You can and should use this even if you don't add your own items to the menu as this is considered to be a big user value.
//
//
// IContextMenuExample Example
// Adding Plug-in specific items to the context menu
//
// class PluginContextMenuTarget : public IContextMenuTarget, public FObject
// {
// public:
// 	PluginContextMenuTarget () {}
//
// 	virtual tresult PLUGIN_API executeMenuItem (int32 tag)
// 	{
// 		// this will be called if the user has executed one of the menu items of the Plug-in.
// 		// It won't be called for items of the host.
// 		switch (tag)
// 		{
// 			case 1: break;
// 			case 2: break;
// 		}
// 		return kResultTrue;
// 	}
//
// 	OBJ_METHODS(PluginContextMenuTarget, FObject)
// 	DEFINE_INTERFACES
// 		DEF_INTERFACE (IContextMenuTarget)
// 	END_DEFINE_INTERFACES (FObject)
// 	REFCOUNT_METHODS(FObject)
// };
//
// // The following is the code to create the context menu
// void popupContextMenu (IComponentHandler* componentHandler, IPlugView* view, const ParamID* paramID, UCoord x, UCoord y)
// {
// 	if (componentHandler == 0 || view == 0)
// 		return;
// 	FUnknownPtr<IComponentHandler3> handler (componentHandler);
// 	if (handler == 0)
// 		return;
// 	IContextMenu* menu = handler->createContextMenu (view, paramID);
// 	if (menu)
// 	{
// 		// here you can add your entries (optional)
// 		PluginContextMenuTarget* target = new PluginContextMenuTarget ();
//
// 		IContextMenu::Item item = {0};
// 		UString128 ("My Item 1").copyTo (item.name, 128);
// 		item.tag = 1;
// 		menu->addItem (item, target);
//
// 		UString128 ("My Item 2").copyTo (item.name, 128);
// 		item.tag = 2;
// 		menu->addItem (item, target);
// 		target->release ();
// 		//--end of adding new entries
//
// 		// here the the context menu will be pop-up (and it waits a user interaction)
// 		menu->popup (x, y);
// 		menu->release ();
// 	}
// }
//
//------------------------------------------------------------------------
const
     UID_IComponentHandler3: TGUID = '{69F11617-D26B-400D-A4B6-B9647B6EBBAB}';

type
    IComponentHandler3 = interface(FUnknown)
      (* Creates a host context menu for a Plug-in:
         - If paramID is zero, the host may create a generic context menu.
         - The IPlugView object must be valid.
         - The return IContextMenu object needs to be released afterwards by the Plug-in. *)
      function createContextMenu(plugView: IPlugView; var paramID: TParamID): IContextMenu; stdcall;
    end;



(************************
    IVSTREPRESENTATION.H
*************************)

//------------------------------------------------------------------------
// RepresentationInfo is the structure describing a representation
// This structure is used in the function IXmlRepresentationController::getXmlRepresentationStream.
// see IXmlRepresentationController
const
     kRepresentationNameSize = 64;

type
    PRepresentationInfo = ^TRepresentationInfo;
    TRepresentationInfo = record
      vendor  : array[0..kRepresentationNameSize-1] of char8;  // Vendor name of the associated representation (remote) (eg. "Yamaha").
      name    : array[0..kRepresentationNameSize-1] of char8;  // Representation (remote) Name (eg. "O2").
      version : array[0..kRepresentationNameSize-1] of char8;  // Version of this "Remote" (eg. "1.0").
      host    : array[0..kRepresentationNameSize-1] of char8;  // Optional: used if the representation is for a given host only (eg. "Nuendo").
    end;


//------------------------------------------------------------------------
// Extended IEditController interface for a component.
//
// A Representation based on XML is a way to export and structure, group Plug-ins parameters for a specific remote (could be hardware or software rack (like quickcontrols)).
//
// It allows to describe more precisely each parameter (what is the best matching to a knob, different titles lengths matching limited remote display,...).\n See an \ref Example.
//
// - A Representation is composed of Pages (this means that to see all exported parameters the user has to navigate through the pages).
// - A Page is composed of Cells (for example 8 Cells per page).
// - A Cell is composed of Layers (for example a cell could have a knob, a display and a button which are 3 Layers).
// - A Layer is associated to a Plug-in parameter using the ParameterID as identifier:
// 	- it could be a knob with a display for Title and/or value, this display uses the same parameterId, but it could an another one.
// 	- Switch
// 	- link which allows to jump directly to a subpage (an another page)
// 	- more... See Vst::LayerType
//
//
// This Representation is implemented as XML text following the Document Type Definition (DTD): http://dtd.steinberg.net/VST-Remote-1.1.dtd
//
// Example
// Here an example of what should be passed in the stream of getXmlRepresentationStream:
//
//
// <?xml version="1.0" encoding="utf-8"?>
// <!DOCTYPE vstXML PUBLIC "-//Steinberg//DTD VST Remote 1.1//EN" "http://dtd.steinberg.net/VST-Remote-1.1.dtd">
// <vstXML version="1.0">
// 	<plugin classID="341FC5898AAA46A7A506BC0799E882AE" name="Chorus" vendor="Steinberg Media Technologies" />
// 	<originator>My name</originator>
// 	<date>2010-12-31</date>
// 	<comment>This is an example for 4 Cells per Page for the Remote named ProductRemote
// 	         from company HardwareCompany.</comment>
//
// 	<!-- ===================================== -->
// 	<representation name="ProductRemote" vendor="HardwareCompany" version="1.0">
// 		<page name="Root">
// 			<cell>
// 				<layer type="knob" parameterID="0">
// 					<titleDisplay>
// 						<name>Mix dry/wet</name>
// 						<name>Mix</name>
// 					</titleDisplay>
// 				</layer>
// 			</cell>
// 			<cell>
// 				<layer type="display"></layer>
// 			</cell>
// 			<cell>
// 				<layer type="knob" parameterID="3">
// 					<titleDisplay>
// 						<name>Delay</name>
// 						<name>Dly</name>
// 					</titleDisplay>
// 				</layer>
// 			</cell>
// 			<cell>
// 				<layer type="knob" parameterID="15">
// 					<titleDisplay>
// 						<name>Spatial</name>
// 						<name>Spat</name>
// 					</titleDisplay>
// 				</layer>
// 			</cell>
// 		</page>
// 		<page name="Page 2">
// 			<cell>
// 				<layer type="LED" ledStyle="spread" parameterID="2">
// 					<titleDisplay>
// 						<name>Width +</name>
// 						<name>Widt</name>
// 					</titleDisplay>
// 				</layer>
// 				<!--this is the switch for shape A/B-->
// 				<layer type="switch" switchStyle="pushIncLooped" parameterID="4"></layer>
// 			</cell>
// 			<cell>
// 				<layer type="display"></layer>
// 			</cell>
// 			<cell>
// 				<layer type="LED" ledStyle="singleDot" parameterID="17">
// 					<titleDisplay>
// 						<name>Sync Note +</name>
// 						<name>Note</name>
// 					</titleDisplay>
// 				</layer>
// 				<!--this is the switch for sync to tempo on /off-->
// 				<layer type="switch" switchStyle="pushIncLooped" parameterID="16"></layer>
// 			</cell>
// 			<cell>
// 				<layer type="knob" parameterID="1">
// 					<titleDisplay>
// 						<name>Rate</name>
// 					</titleDisplay>
// 				</layer>
// 			</cell>
// 		</page>
// 	</representation>
// </vstXML>
//
//------------------------------------------------------------------------
const
     UID_IXmlRepresentationController: TGUID = '{A81A0471-48C3-4DC4-AC30-C9E13C8393D5}';

type
    IXmlRepresentationController = interface(FUnknown)
      // Retrieves a stream containing a XmlRepresentation for a wanted representation info
      function getXmlRepresentationStream(var info: TRepresentationInfo {in}; stream: IBStream {out}): TResult; stdcall;
    end;



//------------------------------------------------------------------------
// Defines for XML representation Tags and Attributes
const
     ROOTXML_TAG            = 'vstXML';

     COMMENT_TAG			      = 'comment';
     CELL_TAG			          = 'cell';
     CELLGROUP_TAG		      = 'cellGroup';
     CELLGROUPTEMPLATE_TAG  = 'cellGroupTemplate';
     CURVE_TAG			        = 'curve';
     CURVETEMPLATE_TAG	    = 'curveTemplate';
     DATE_TAG			          = 'date';
     LAYER_TAG			        = 'layer';
     NAME_TAG			          = 'name';
     ORIGINATOR_TAG		      = 'originator';
     PAGE_TAG			          = 'page';
     PAGETEMPLATE_TAG	      = 'pageTemplate';
     PLUGIN_TAG			        = 'plugin';
     VALUE_TAG			        = 'value';
     VALUEDISPLAY_TAG	      = 'valueDisplay';
     VALUELIST_TAG		      = 'valueList';
     REPRESENTATION_TAG	    = 'representation';
     SEGMENT_TAG			      = 'segment';
     SEGMENTLIST_TAG		    = 'segmentList';
     TITLEDISPLAY_TAG	      = 'titleDisplay';

     ATTR_CLASSID		        = 'classID';
     ATTR_ENDPOINT		      = 'endPoint';
     ATTR_INDEX			        = 'index';
     ATTR_FLAGS			        = 'flags';
     ATTR_FUNCTION		      = 'function';
     ATTR_HOST			        = 'host';
     ATTR_LEDSTYLE		      = 'ledStyle';
     ATTR_LENGTH			      = 'length';
     ATTR_LINKEDTO		      = 'linkedTo';
     ATTR_NAME			        = 'name';
     ATTR_ORDER			        = 'order';
     ATTR_PAGE			        = 'page';
     ATTR_PARAMID		        = 'parameterID';
     ATTR_STARTPOINT		    = 'startPoint';
     ATTR_STYLE			        = 'style';
     ATTR_SWITCHSTYLE	      = 'switchStyle';
     ATTR_TEMPLATE		      = 'template';
     ATTR_TURNSPERFULLRANGE	= 'turnsPerFullRange';
     ATTR_TYPE			        = 'type';
     ATTR_UNITID			      = 'unitID';
     ATTR_VARIABLES		      = 'variables';
     ATTR_VENDOR			      = 'vendor';
     ATTR_VERSION		        = 'version';

//------------------------------------------------------------------------
// Defines some predefined Representation Remote Names
const
     GENERIC 			         = 'Generic';
     GENERIC_4_CELLS		   = 'Generic 4 Cells';
     GENERIC_8_CELLS			 = 'Generic 8 Cells';
     GENERIC_12_CELLS		   = 'Generic 12 Cells';
     GENERIC_24_CELLS		   = 'Generic 24 Cells';
     GENERIC_N_CELLS		   = 'Generic %d Cells';
     QUICK_CONTROL_8_CELLS = 'Quick Controls 8 Cells';

//------------------------------------------------------------------------
// Layer Types used in a VST XML Representation
//------------------------------------------------------------------------
const
     kLayerTypeKnob            = 0;    // a knob (encoder or not)
     kLayerTypePressedKnob     = 1;    // a knob which is used by pressing and turning
     kLayerTypeSwitchKnob      = 2;    // knob could be pressed to simulate a switch
     kLayerTypeSwitch          = 3;    // a "on/off" button
     kLayerTypeLED             = 4;    // LED like VU-meter or display around a knob
     kLayerTypeLink            = 5;    // indicates that this layer is a folder linked to an another INode (page)
     kLayerTypeDisplay         = 6;    // only for text display (not really a control)
     kLayerTypeFader           = 7;    // a fader
     kLayerTypeEndOfLayerType  = 8;

	   // FIDString variant of the LayerType
     layerTypeFIDString : array[0..7] of string = (
        'knob',
        'pressedKnob',
        'switchKnob',
        'switch',
        'LED',
        'link',
        'display',
        'fader');

//------------------------------------------------------------------------
// Curve Types used in a VST XML Representation
//------------------------------------------------------------------------
const
     kCurveTypeSegment   = 'segment';
     kCurveTypeValueList = 'valueList';

//------------------------------------------------------------------------
// Attributes used to defined a Layer in a VST XML Representation
//------------------------------------------------------------------------
const
    kAttributesStyle                 = ATTR_STYLE;                // string attribute : See AttributesStyle for available string value
    kAttributesLEDStyle              = ATTR_LEDSTYLE;             // string attribute : See AttributesStyle for available string value
    kAttributesSwitchStyle           = ATTR_SWITCHSTYLE;          // string attribute : See AttributesStyle for available string value
    kAttributesKnobTurnsPerFullRange = ATTR_TURNSPERFULLRANGE;    // float attribute
    kAttributesFunction              = ATTR_FUNCTION;             // string attribute : See AttributesFunction for available string value
    kAttributesFlags                 = ATTR_FLAGS;                // string attribute : See AttributesFlags for available string value


//------------------------------------------------------------------------
// Attributes Function used to defined the function of a Layer in a VST XML Representation
//------------------------------------------------------------------------
const
     // Global Style
     kAttrFuncPanPosCenterXFunc     = 'PanPosCenterX';       // Gravity point X-axis (L-R) (for stereo: middle between left and right)
     kAttrFuncPanPosCenterYFunc		  = 'PanPosCenterY';       // Gravity point Y-axis (Front-Rear)
     kAttrFuncPanPosFrontLeftXFunc	= 'PanPosFrontLeftX';    // Left channel Position in X-axis
     kAttrFuncPanPosFrontLeftYFunc	= 'PanPosFrontLeftY';    // Left channel Position in Y-axis
     kAttrFuncPanPosFrontRightXFunc	= 'PanPosFrontRightX';   // Right channel Position in X-axis
     kAttrFuncPanPosFrontRightYFunc	= 'PanPosFrontRightY';   // Right channel Position in Y-axis
     kAttrFuncPanRotationFunc			  = 'PanRotation';         // Rotation around the Center (gravity point)
     kAttrFuncPanLawFunc				    = 'PanLaw';              // Panning Law
     kAttrFuncPanMirrorModeFunc		  = 'PanMirrorMode';       // Panning Mirror Mode
     kAttrFuncPanLfeGainFunc			  = 'PanLfeGain';          // Panning LFE Gain
     kAttrFuncGainReductionFunc		  = 'GainReduction';       // Gain Reduction for compressor
     kAttrFuncSoloFunc					    = 'Solo';                // Solo
     kAttrFuncMuteFunc					    = 'Mute';                // Mute
     kAttrFuncVolumeFunc				    = 'Volume';              // Volume

//------------------------------------------------------------------------
// Attributes Style associated a specific Layer Type in a VST XML Representation
//------------------------------------------------------------------------
const
     // Global Style
     kAttributesStyleInverseStyle             = 'inverse';        // the associated layer should use the inverse value of parameter (1 - x).

     // LED Style
     kAttributesStyleLEDWrapLeftStyle		      = 'wrapLeft';       // |======>----- (the default one if not specified)
     kAttributesStyleLEDWrapRightStyle	      = 'wrapRight';      // -------<====|
     kAttributesStyleLEDSpreadStyle		        = 'spread';         // ---<==|==>---
     kAttributesStyleLEDBoostCutStyle		      = 'boostCut';       // ------|===>--
     kAttributesStyleLEDSingleDotStyle	      = 'singleDot';      // --------|----

     // Switch Style
     kAttributesStyleSwitchPushStyle		      = 'push';           // Apply only when pressed, unpressed will reset the value to min.
     kAttributesStyleSwitchPushIncLoopedStyle = 'pushIncLooped';  // Push will increment the value. When the max is reached it will restart with min.
                                                                  // The default one if not specified (with 2 states values it is a OnOff switch).
     kAttributesStyleSwitchPushDecLoopedStyle = 'pushDecLooped';  // Push will decrement the value. When the min is reached it will restart with max.
     kAttributesStyleSwitchPushIncStyle	      = 'pushInc';        // Increment after each press (delta depends of the curve).
     kAttributesStyleSwitchPushDecStyle	      = 'pushDec';        // Decrement after each press (delta depends of the curve).
     kAttributesStyleSwitchLatchStyle		      = 'latch';          // Each push-release will change the value between min and max.
                                                                  // A timeout between push and release could be used to simulate a push style (if timeout is reached).

//------------------------------------------------------------------------
// Attributes Flags defining a Layer in a VST XML Representation
//------------------------------------------------------------------------
const
     kAttributesFlagsHideableFlag = 'hideable';  // the associated layer marked as hideable allows a remote to hide or make it not usable a parameter when the associated value is inactive

implementation

end.
