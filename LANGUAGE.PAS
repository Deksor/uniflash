
Unit Language;

Interface

Const LangCount: Byte = 0;

Var   CurLang  : Byte;

Type  InitProc = Procedure ;

Function Msg(Id:Word): String;
Procedure RegisterLanguage(Const Name:String;Init:InitProc);
Procedure InitLanguage(LId:Byte);
Procedure AddMsg(MId:Word;Const Msg:String);
Function GetLangName(LangId:Byte): String;

Implementation

Var MsgPtrs  : array[1..150] Of ^String;
  LangNames: array[1..5] Of ^String;
  LangInits: array[1..5] Of InitProc;

Function Msg(Id:Word): String;
Begin
  Msg := MsgPtrs[Id]^;
End;

Procedure RegisterLanguage(Const Name:String;Init:InitProc);
Begin
  Inc(LangCount);
  LangNames[LangCount] := @Name;
  LangInits[LangCount] := Init;
End;

Procedure InitLanguage(LId:Byte); {v1.31}
Begin
  LangInits[LId];
End;

Procedure AddMsg(MId:Word;Const Msg:String);
Begin {The compiler is not %!$# anymore when we use constant parameter :-)) }
  MsgPtrs[MId] := @Msg;
End;

Function GetLangName(LangId:Byte): String;
Begin
  GetLangName := LangNames[LangId]^;
End;

{begin}
End.
