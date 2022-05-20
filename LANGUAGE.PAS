Unit Language;

Interface
const LangCount: Byte = 0;
var   CurLang  : Byte;

Function Msg( Id : Word ) : String;
Function RegisterLanguage( Name : String ) : Byte;
Procedure AddMsg( LId : Byte; MId : Word; Msg : String );
Function GetLangName( LangId : Byte ) : String;

Implementation

Type
LangDef = ARRAY[ 1 .. 150 ] of ^String; {v1.25 130->150}

Var
MsgPtrs   : ARRAY[ 1 .. 4 ] of ^LangDef;
LangNames : ARRAY[ 1 .. 4 ] of ^String;
{CurLang   : Byte;}

Function Msg( Id : Word ) : String;
Begin
 Msg := MsgPtrs[ CurLang ]^[ Id ]^;
End;

{For some reason we can't call New from assembler, }
{so we call this helper function instead.          }
Procedure RegLangHelp;
Begin
 Inc( LangCount );
 New( MsgPtrs[ LangCount ] );
End;

Function RegisterLanguage( Name : String ) : Byte; Assembler;
{See AddMsg}
Asm
 CALL RegLangHelp
 MOV  BL,LangCount
 XOR  BH,BH
 DEC  BX
 SHL  BX,2
 MOV  AX,WORD PTR Name
 MOV  DS:[BX+OFFSET LangNames],AX
 MOV  AX,WORD PTR Name+2
 MOV  DS:[BX+OFFSET LangNames+2],AX
 MOV  AL,LangCount
End;


Procedure AddMsg( LId : Byte; MId : Word; Msg : String ); Assembler;
Asm
{ This is done in assembler because otherwise the %!$# compiler        }
{ copies the string onto the stack and returns a pointer to that       }
{ copy instead of the original. Which is necessary if the string       }
{ would be modified inside this procedure, but that's *NOT* the        }
{ case so those Borland morons are just waisting our time and code     }
{ space in such cases (not to mention making things like this          }
{ unnecessarily hard).                                                 }
 MOV BL,LId
 XOR BH,BH
 DEC BX
 SHL BX,2
 LES DI,DWORD PTR [OFFSET MsgPtrs + BX]
 MOV BX,MId
 DEC BX
 SHL BX,2
 MOV AX,WORD PTR Msg
 MOV ES:[DI+BX],AX
 MOV AX,WORD PTR Msg+2
 MOV ES:[DI+BX+2],AX
End;

Function GetLangName( LangId : Byte ) : String;
Begin
 GetLangName := LangNames[ LangId ]^;
End;

{Begin}
End.