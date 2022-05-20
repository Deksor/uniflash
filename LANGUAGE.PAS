Unit Language;

Interface
const LangCount: Byte = 0;
var   CurLang  : Byte;

function Msg(Id:Word):String;
function RegisterLanguage(const Name:String):Byte; {const v1.29}
procedure AddMsg(LId:Byte;MId:Word;const Msg:String); {const v1.29}
function GetLangName(LangId:Byte):String;

Implementation

type LangDef=array[1..150] of ^String; {v1.25 130->150}

Var
MsgPtrs   : array[1..5] of ^LangDef;
LangNames : array[1..5] of ^String;

function Msg(Id:Word):String;
begin
 Msg:=MsgPtrs[CurLang]^[Id]^;
end;

function RegisterLanguage(const Name:String):Byte;
begin
 Inc(LangCount);
 New(MsgPtrs[LangCount]);
 LangNames[LangCount]:=@Name;
 RegisterLanguage:=LangCount;
End;

procedure AddMsg(LId:Byte;MId:Word;const Msg:String);
begin {The compiler is not %!$# anymore when we use constant parameter :-)) }
 MsgPtrs[LId]^[MId]:=@Msg;
end;

function GetLangName(LangId:Byte):String;
begin
 GetLangName:=LangNames[LangId]^;
end;

{Begin}
End.