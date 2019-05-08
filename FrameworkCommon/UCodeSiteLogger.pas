unit UCodeSiteLogger;

interface

procedure WriteLog(s:string);

implementation

uses Windows,CodeSiteLogging, System.IOUtils, Classes, SysUtils;

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


procedure WriteLog(s:string);
begin
  if not Enabled then exit;
  CodeSite.Send(s);
end;

begin
  FLastResult:=true;
end.
