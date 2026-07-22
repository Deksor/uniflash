unit Language;

interface
const LangCount: Byte = 0;
var   CurLang  : Byte;
type  InitProc = procedure;

function Msg(Id:Word):String;
procedure RegisterLanguage(const Name:String;Init:InitProc);
procedure InitLanguage(LId:Byte);
procedure AddMsg(MId:Word;const Msg:String);
function GetLangName(LangId:Byte):String;

implementation

var MsgPtrs  : array[1..150] of ^String;
    LangNames: array[1..5] of ^String;
    LangInits: array[1..5] of InitProc;

function Msg(Id:Word):String;
begin
  Msg:=MsgPtrs[Id]^;
end;

procedure RegisterLanguage(const Name:String;Init:InitProc);
begin
  Inc(LangCount);
  LangNames[LangCount]:=@Name;
  LangInits[LangCount]:=Init;
end;

procedure InitLanguage(LId:Byte); {v1.31}
begin
  LangInits[LId];
end;

procedure AddMsg(MId:Word;const Msg:String);
begin {The compiler is not %!$# anymore when we use constant parameter :-)) }
  MsgPtrs[MId]:=@Msg;
end;

function GetLangName(LangId:Byte):String;
begin
  GetLangName:=LangNames[LangId]^;
end;

{begin}
end.