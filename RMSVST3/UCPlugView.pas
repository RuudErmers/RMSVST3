unit UCPlugView;

interface

uses Vst3Base,Forms,UVST3Controller,Types;

type
     CPlugView = class(TInterfacedObject,IPlugView)
     FEditorForm:TForm;
     FFrame: IPlugFrame;
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

uses ULogger,UVST3Utils,SysUtils, Windows;

{ CPlugView }

function CPlugView.Attached(parent: pointer; aType: FIDString): TResult;
var rect: TViewRect;
begin
  WriteLog('CPlugView.Attached');
  result:=kResultFalse;
  if parent=NIL then exit;
  if FeditorForm = NIL then
    FeditorForm:=IVST3.CreateForm(parent);
  if FeditorForm<>NIL then
  with FEditorForm do
  begin
    Visible := True;
    BorderStyle := bsNone;
    SetBounds(0, 0, Width, Height);
    rect.left:= 0; rect.top:= 0; rect.right:= Width; rect.bottom:= Height;
    Invalidate;
  end;
  IVST3.EditOpen(FEditorForm);
  if FFrame<>nil then
    FFrame.resizeView (self, @rect);
  result:=kResultOk;
end;

function CPlugView.CanResize: TResult;
begin
  //WriteLog('CPlugView.CanResize');   // this can Log SPAM // turn on at own risk
  result:=kResultFalse;    // was kResultOk kResultFalse
end;

function CPlugView.CheckSizeConstraint(rect: PViewRect): TResult;
begin
  WriteLog('CPlugView.CheckSizeConstraint:'+inttostr( rect.right));
  rect.left:=0;
  rect.top:=0;
  rect.right:=1000;
  rect.bottom:=800;
  if FeditorForm<>NIL then with FeditorForm do
  begin
    rect^.right:=width;
    rect^.bottom:=height;
  end;
  result:=kResultOk;
end;

constructor CPlugView.create(controller: IVST3Controller);
begin
  WriteLog('CPlugView.create');
  inherited Create;
  IVST3:=controller;
  _AddRef;
end;

function CPlugView.GetSize(size: PViewRect): TResult;
begin
  WriteLog('CPlugView.GetSize:');
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
  WriteLog('CPlugView.IsPlatformTypeSupported:' + aType);
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
  WriteLog('CPlugView.OnSize');
  IVST3.OnSize(Rect(newSize.left,newSize.top,newSize.right,newSize.bottom));
  result:=kResultOk;
end;

function CPlugView.OnWheel(distance: single): TResult;
begin
  result:=kResultOk;
end;

function CPlugView.Removed: TResult;
begin
  WriteLog('CPlugView.Removed');
  IVST3.EditClose;
  FEditorForm.Parent:=NIL;
  FeditorForm.Free;
  FeditorForm:=NIL;
  result:=kResultOk;
end;

function CPlugView.SetFrame(frame: IPlugFrame): TResult;
begin
  WriteLog('CPlugView.SetFrame');
  if frame = nil then
  begin
    WriteLog('CPlugView.SetFrame / frame = nil');
    WriteLog('IVST3.EditClose');
    IVST3.EditClose;
    //FFrame._Release;
    WriteLog('result:=kResultOk');
    result:=kResultOk;
  end
  else
  begin
    FFrame:= frame;
    FFrame._AddRef;
    result:=kResultOk;
  end;
end;

end.
