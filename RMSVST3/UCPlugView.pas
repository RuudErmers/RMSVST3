unit UCPlugView;

interface

uses Vst3Base,Forms,UVST3Controller;

type
     CPlugView = class(TInterfacedObject,IPlugView)
     FEditorForm:TForm;
public
      IVST3:IVST3Controller;
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
//      procedure SetParam(index:integer;value:double);
      constructor create(controller: IVST3Controller);
  private
    end;

implementation

uses CodeSiteLogging,UUIDHelper,SysUtils, Windows;

{ CPlugView }

(*
procedure CPlugView.ResendParameters;
VAR i,count:integer;
    value:double;
begin
  if FeditorForm=NIL then exit;
  count:=IVST3.GetParameterCount;
  for i:=0 to count-1 do
  begin
    value:=IVST3.GetParameterValue(i);
    FeditorForm.DoChangeParameter(i,value);
  end;
end;
*)

function CPlugView.Attached(parent: pointer; aType: FIDString): TResult;
begin
  result:=kResultFalse;
  if parent=NIL then exit;
  CodeSite.Send('CPlugView.Attached');
  if FeditorForm = NIL then
    FeditorForm:=IVST3.CreateForm(parent);
//    if IVST3.editorFormClass <> NIL then
//      FEditorForm:=IVST3.editorFormClass.CreateParented(HWnd(parent));
  if FeditorForm<>NIL then
  with FEditorForm do
  begin
    Visible := True;
    BorderStyle := bsNone;
    SetBounds(0, 0, Width, Height);
    Invalidate;
  end;
  IVST3.EditOpen(FEditorForm);
  result:=kResultOk;
end;

function CPlugView.CanResize: TResult;
begin
  CodeSite.Send('CPlugView.Attached');
  result:=kResultOk;
end;

function CPlugView.CheckSizeConstraint(rect: PViewRect): TResult;
begin
  result:=kResultOk;
end;

constructor CPlugView.create(controller: IVST3Controller);
begin
  inherited Create;
  IVST3:=controller;
end;

function CPlugView.GetSize(size: PViewRect): TResult;
begin
  CodeSite.Send('CPlugView.GetSize:');
  size.left:=0;
  size.top:=0;
  size.right:=1000;
  size.bottom:=800;
  if FeditorForm<>NIL then with FeditorForm do
  begin
    size.right:=width;
    size.bottom:=height;
  end;
  result:=kResultOk;
end;

function CPlugView.IsPlatformTypeSupported(aType: FIDString): TResult;
begin
  CodeSite.Send('CPlugView.IsPlatformTypeSupported:' + aType);
  if aType = 'HWND' then result:=kResultOk
                    else result:=kResultFalse;
end;

function CPlugView.OnFocus(state: TBool): TResult;
begin
  result:=kResultOk;
end;

function CPlugView.OnKeyDown(key: char16; keyCode, modifiers: int16): TResult;
begin
  result:=kResultOk;
end;

function CPlugView.OnKeyUp(key: char16; keyCode, modifiers: int16): TResult;
begin
  result:=kResultOk;
end;

function CPlugView.OnSize(newSize: PViewRect): TResult;
begin
  CodeSite.Send('CPlugView.OnSize');
  result:=kResultOk;
end;

function CPlugView.OnWheel(distance: single): TResult;
begin
  result:=kResultOk;
end;

function CPlugView.Removed: TResult;
begin
  CodeSite.Send('CPlugView.Removed');
  IVST3.EditClose;
  FEditorForm.Parent:=NIL;
  FeditorForm.Free;
  FeditorForm:=NIL;
  result:=kResultOk;
end;

function CPlugView.SetFrame(frame: IPlugFrame): TResult;
begin
  CodeSite.Send('CPlugView.SetFrame');
  result:=kResultOk;
end;

end.
