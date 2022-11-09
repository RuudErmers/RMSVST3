{
  I've put it on the forums Delphi Praxis and stackoverflow asking how to bypass CodeSiteLogging
  if the person doesn't have it.  I'm waiting on a answer for updating this source.

  For now, I've re-added it back as I think it will be necessary to help improve the code.
}

unit ULogger;    // renamed from UCodeSiteLogger

interface

procedure WriteLog(s:string);

implementation

uses Windows, System.IOUtils, Classes, SysUtils, CodeSiteLogging;       // Not everyone has CodeSiteLogging -- working on a way to make this optional
                                                                        // for now, if you get this... just comment it out if you don't have CodeSiteLogging

// Comment this below out if you don't have CodeSiteLogging:
VAR FlastCheck:Int64;
    FLastResult:boolean;
function Enabled:boolean;
VAR fname:string;
    sl:TStringlist;
    p:integer;
begin
  if GetTickCount>FLastCheck+5000 then
  begin
    FLastCheck:=GetTickCount;
    FLastResult:=true; // default = on
    fname:=TPath.GetDocumentsPath+'\My CodeSite Files\Logging.inf';
    sl:=TStringlist.Create;
    try
      sl.LoadFromFile(fname);
      p:=Pos('LOG=',UpperCase(sl[0]));
      if p=1 then FLastResult:=sl[0][5]='1';
    except
    end;
    sl.Free;
  end;
  result:=FLastResult;
end;
// Comment this above out if you don't have CodeSiteLogging


procedure WriteLog(s:string);
begin
  //  if not Enabled then exit;
  // Comment the next line out if you don't have CodeSiteLogging:
  CodeSite.Send(s);
end;

begin
  // Comment the next line out if you don't have CodeSiteLogging:
  FLastResult:=true;
end.
