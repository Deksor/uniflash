{$R-}
{$I-}
Unit Tools;

Interface

Type
ProcType   = Procedure;
WaitProc   = Procedure( MicroSec: LongInt ); {v1.22}
PMenuItem  = ^MenuItem;
MenuItem   = Record
              X, Y   : Byte;
              Descr  : String[60]; {v1.23 80->60}
              Help   : String[79]; {v1.23}
              Flags  : Byte;
              Action : Record
                        Case Integer of
                         0 : ( P : ProcType );
                         1 : ( M : PMenuItem );
                         2 : ( T : Pointer );
                       End;
              Next,
              Prev   : PMenuItem;
             End;

Const
Version    = '1.36';
XMSLeft    : LongInt = 0;
XMSPos     : LongInt = 0;
Logging    : Boolean = False; {v1.23}
Mono       : Boolean = False; {v1.27}
var Wait:WaitProc;

Function ConstPtr( Const S : String ) : Pointer;
Function FIMemB( Addr : LongInt ) : Byte;
Function FIMemW( Addr : LongInt ) : Word;
Procedure FOMemB( Addr : LongInt; Data : Byte );
Function Hb( B : Byte ) : String;
Function Hw( W : Word ) : String;
Function Hl( L : Longint ) : String;
function Hex2Dec(S:String):LongInt; {v1.32}
Function Windows : Boolean; {v1.22}
Function EMM386 : Boolean; {v1.27}
Function FlatRealOn : Boolean;
Procedure FlatRealOff;
Procedure CloseXMS; {v1.24}
Procedure InitXMS;
Procedure AllocHimem;
Function AllocLinBlock( Size : LongInt ) : LongInt;
Procedure MoveLinBlockD( Src, Dest, Size : LongInt );
Procedure MoveLinBlockB( Src, Dest, Size : LongInt );
Procedure MoveLinBlockW( Src, Dest, Size : LongInt );
Procedure FillLinBlockD( Dest, Size : LongInt; Data : Byte );
Function CompLinBlocks( Block1, Block2, Size : LongInt ) : Boolean;
Procedure SetMenuItemStatus( Menu : PMenuItem; YVal : Byte; Act : Boolean );
Function AddMenuItem( Txt, Hlp : String; RY, Flg : Byte;
                      Proc : Pointer; Nxt : PMenuItem ) : PMenuItem;
Procedure RunMenu( Menu : PMenuItem );
Procedure WrtProgressBar( Msg : String );
Procedure ClearProgressBar;
Procedure Beep( Hz, Ms : Word );
function zero2str(s,o : word) : string;
function strcomp(s1,s2 : string; b : byte) : boolean;
procedure ClrKbBuf; {v1.27}
function _ReadKey:Char; {v1.23}
function _Str(I:LongInt):String; {v1.23}
procedure LogWrite(S:String); {v1.23}
procedure LogStart; {v1.23}
procedure LogEnd; {v1.23}
procedure Text_Color(Color:Byte); {v1.27}
procedure Text_Background(Color:Byte); {v1.27}
function NoVideo:Boolean; {v1.28}
procedure FInput(var Name:String;DefaultName:String;MaxLen:Byte); {v1.28}
function BrowseFile:String; {v1.28}
function IntToStr(I:LongInt):String; {v1.28}

Implementation

Uses Crt,Dos;

Const
MTop    = 10{9}; {v1.22}
XMSHnd  : Word = 0;

Var
TmpGDT    : ARRAY[ 0 .. 7 ] of Word;
XMMRtn    : LongInt;
CurMenu   : PMenuItem;
MicroSec  : Word;
TSC,uSec  : LongInt; {v1.22}
Ext       : Char; {v1.23}
History   : String[2]; {v1.23}
Shift     : Boolean; {v1.23}
XMSManager: Boolean; {v1.27}

Function ConstPtr( Const S : String ) : Pointer;
Begin
 ConstPtr := @S;
End;

Function FIMemB( Addr : LongInt ) : Byte; Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD PTR Addr    {MOV ESI,Addr}
 DB     26H,67H,8AH,06H     {MOV AL,ES:[ESI]}
End;

Function FIMemW( Addr : LongInt ) : Word; Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD PTR Addr    {MOV ESI,Addr}
 DB     26H,67H,8BH,06H     {MOV AX,ES:[ESI]}
End;

Procedure FOMemB( Addr : LongInt; Data : Byte ); Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD PTR Addr    {MOV ESI,Addr}
 MOV    AL,Data
 DB     26H,67H,88H,06H     {MOV ES:[ESI],AL}
End;

{ Convert byte to hex string }
Function Hb( B : Byte ) : String;
Var
C1, C2 : Char;

Begin
 Asm
   mov AL,B
   MOV BL,AL
   SHR AL,4
   AND BL,0FH
   DAA
   ADD  AL,0F0H
   ADC  AL,040H
   MOV  C1,AL
   MOV  AL,BL
   AND  AL,0FH
   DAA
   ADD  AL,0F0H
   ADC  AL,040H
   MOV  C2,AL
 End;
 Hb := C1 + C2;
End;

{ Convert word to hex string }
Function Hw( W : Word ) : String;
Begin
 Hw := Hb( W shr 8 ) + Hb( W );
End;

Function Hl( L : Longint ) : String;
Begin
 Hl := Hw( L shr 16 ) + hw(l);
End;

function Hex2Dec(S:String):LongInt; {v1.32}
var A,I,Z:LongInt;
begin
  I:=0;
  Z:=1;
  for A:=Length(S) downto 1 do
   begin
     if S[A] in ['0'..'9'] then I:=I+(Ord(S[A])-48)*Z;
     if S[A] in ['A'..'F'] then I:=I+(Ord(S[A])-55)*Z;
     if S[A] in ['a'..'f'] then I:=I+(Ord(S[A])-87)*Z;
     Z:=Z shl 4;
   end;
  Hex2Dec:=I;
end;

{Detect if Windows is running}
Function Windows : Boolean; Assembler; {v1.22}
Asm
        MOV     AX,1600H
        INT     2FH
        CMP     AL,0H
        JE      @nowin
        MOV     AX,1
        JMP     @exit
@nowin: XOR     AX,AX
@exit:
End;

{Detect if EMM386.EXE is loaded}
function EMM386: Boolean; {v1.27}
var F:File;
begin
  Assign(F,'EMMXXXX0');
  Reset(F);
  if IOResult<>0 then
   begin
     EMM386:=False;
     Exit;
   end;
  EMM386:=True;
  Close(F);
end;

{Set flat real mode, return false on error}
Function FlatRealOn : Boolean; Assembler;
Asm
(*{286 check, probably too late anyway (depending on $G switch) <G>}
        PUSH    SP
        POP     AX
        CMP     AX,SP
        JNZ     @error*)
{check for protected (V86) mode}
        SMSW    AX
        TEST    AL,1
        JNZ     @error
{Intel recommended 386 check}
        MOV     BX,7000H
        PUSHF
        PUSH    BX
        POPF
        PUSHF
        POP     CX
        POPF
        TEST    CX,BX
        JZ      @error
{486 check}
        DB      66H
        PUSHF
        DB      66H
        PUSHF
        DB      66H
        POP     AX
        DB      66H
        XOR     AX,0
        DW      4
        DB      66H
        PUSH    AX
        DB      66H
        POPF
        DB      66H
        PUSHF
        DB      66H
        POP     BX
        DB      66H
        POPF
        DB      66H
        XOR     AX,BX
        DB      66H
        TEST    AX,0
        DW      4
        JNZ     @error

{switch to flat real mode}
        DB      66H
        MOV     BX,DS  {EBX=DS}
        DB      66H
        SHL     BX,4   {EBX=DS*16}
        DB      66H
        MOV     SI,OFFSET TmpGDT
        DW      0      {ESI=OFFSET TmpGDT}
        DB      66H
        ADD     BX,SI  {EBX=linear addr of TmpGDT structure}
        MOV     WORD [DS:SI],10H  {GDT limit}
        MOV     [DS:SI+2],BX      {GDT linear addr lo}
        DB      66H
        SHR     BX,16   {BX=Hi(EBX)}
        MOV     [DS:SI+4],BX      {GDT linear addr hi}
        XOR     DX,DX
        MOV     WORD [DS:SI+10],DX {segment base bits 0-15}
        DEC     DX
        MOV     WORD [DS:SI+8],DX  {segment limit bits 0..15 (actually 12-27)}
        MOV     WORD [DS:SI+12],09200H {segment base bits 16-23, R/W,DT1,DPL0,P=1}
        MOV     WORD [DS:SI+14],008FH {segment limit bits 16-19 (actually 28-31)}
                                      {D=0,G=1(4K), segment base bits 24-31}
        LGDT    [DS:OFFSET TmpGDT]   {Load GDTR}
        INC     AX                   {PM on}
        CLI
        LMSW    AX                   {switch to PM}
        MOV     BX,08H               {flat segment}
        MOV     ES,BX                {ES=flat. NOTE:DS=flat->error??!!}
        DB      0FH,20H,0C0H         {MOV EAX,CR0}
        DEC     AX                   {PM off}
        DB      0FH,22H,0C0H         {MOV CR0,EAX}
        STI
        MOV     AL,1
        JMP     @exit
@error: XOR     AL,AL
@exit:
End;

{Disable flat real mode}
{NOTE: It is assumed that FlatRealOn has been previously called !!}
Procedure FlatRealOff; Assembler;
Asm
        MOV     SI,OFFSET TmpGDT
        MOV     BYTE [DS:SI+14],00H {segment limit bits 16-19 (actually 28-31)}
                                    {D=0,G=0(byte), segment base bits 24-31}
        LGDT    [DS:OFFSET TmpGDT]  {Load GDTR}
        SMSW    AX
        INC     AX                  {PM on}
        CLI
        LMSW    AX                  {switch to PM}
        MOV     BX,08H              {non-flat segment}
        MOV     ES,BX               {ES=normal}
        DB      0FH,20H,0C0H        {MOV EAX,CR0}
        DEC     AX                  {PM off}
        DB      0FH,22H,0C0H        {MOV CR0,EAX}
        STI
End;

Procedure CloseXMS; {v1.24}
Begin
 if not XMSManager then Exit; {v1.27}
 Asm
  MOV   AH,0DH  {Unlock}
  MOV   DX,XMSHnd
  CALL  DWORD [XMMRtn]
  MOV   AH,0AH  {Free}
  MOV   DX,XMSHnd
  CALL  DWORD [XMMRtn]
  MOV   AH,04H {Global disable A20}
  CALL  DWORD [XMMRtn]
 End;
End;

Procedure XMSExitProc; Far;
Begin
 CloseXMS;
 ExitProc := nil;
End;

Function A20NotOn : Boolean; Assembler;
Asm
  PUSH  DS
  MOV   AX,0
  MOV   DS,AX
  DEC   AX
  MOV   ES,AX
  CLI
  MOV   AL,[DS:0]
  MOV   BL,[ES:10H]
  MOV   AH,AL
  XOR   AL,55H
  MOV   [ES:10H],AL
  CMP   [DS:0],AL
  MOV   [DS:0],AH
  MOV   [ES:10H],BL
  STI
  POP   DS
  MOV   AL,0
  JNZ   @@1
  INC   AL
@@1:
End;

{This routine simply allocates the largest XMS block}
{pretty crude, but should work fine in most cases   }
Procedure InitXMS;
Label NoXMM, NoXMMMem, XMMDone;

Var
Attempt,
BSize    : Word;
X        : Byte;

Begin
 XMSManager:=False; {v1.27}
 Asm
  MOV   AX,4300H
  INT   2FH
  CMP   AL,80H
  JNZ   NoXMM
  MOV   AX,4310H
  INT   2FH
  MOV   [OFFSET XMMRtn],BX
  MOV   [OFFSET XMMRtn+2],ES
  MOV   AH,08H  {Query}
  CALL  DWORD [XMMRtn]
  OR    AX,AX
  JZ    NoXMMMem
  MOV   DX,AX   {Largest block}
  MOV   BSize,AX
  MOV   AH,09H  {Allocate}
  CALL  DWORD [XMMRtn]
  CMP   AX,1    {Exit on error}
  JNZ   NoXMMMem
  MOV   XMSHnd,DX
 End;
 XMSManager:=True; {v1.27}
 ExitProc := @XMSExitProc;
 Asm
  MOV   AH,0CH  {Lock XMS block}
  MOV   DX,XMSHnd
  CALL  DWORD [XMMRtn]
  CMP   AX,1
  JNZ   NoXMMMem
  MOV   [OFFSET XMSPos],BX
  MOV   [OFFSET XMSPos+2],DX
NoXMMMem:
  MOV   AH,03H  {Global enable A20}
  CALL  DWORD [XMMRtn]
  CMP   AX,1
  JNZ   XMMDone
 End;
 If XMSPos <> 0 then
  XMSLeft := LongInt( BSize ) shl 10;
 Goto XMMDone;
NoXMM:
{XMS manager not found, need to enable A20 & figure out XMS size ourselves}
 Attempt := 0;
 While A20NotOn and ( Attempt < 3 ) do
  Begin
   {First try PS2 method}
   Asm
    CLI
    IN      AL,92H
    OR      AL,2
    OUT     92H,AL
    STI
   End;
   Delay( 10 );  {wait a while before testing}
   {If it didn't work then try KBC method}
   If A20NotOn then
    Begin
     Asm CLI End;
     Port[ $64 ] := $D0;
     Repeat Until ( Port[ $64 ] and 1 ) <> 0;
     X := Port[ $60 ];
     Port[ $64 ] := $D1;
     Repeat Until ( Port[ $64 ] and 2 ) = 0;
     Port[ $60 ] := X or 2;
     Asm STI End;
     Delay( 10 ); {wait a while before testing}
    End;
   Inc( Attempt );
  End;
 XMSLeft := -2; {No XMS}
XMMDone:
 If A20NotOn then XMSLeft := -1;
End;

Procedure AllocHimem;
Var
Done : Boolean;

Begin
 If XMSLeft <> -2 then Exit;
{Scan for available memory. NOTE: It is assumed that none of this memory    }
{is in use and that there is a gap between system memory & option ROM/RAM !!}
 XMSPos := $100000;
 XMSLeft := 0;
 Repeat
  Done := True;
  FOMemB( XMSPos, $55 );
  If FIMemB( XMSPos ) = $55 then
   Begin
    FOMemB( XMSPos, $AA );
    If FIMemB( XMSPos ) = $AA then
     Begin
      FOMemB( XMSPos + 4095, $55 );
      If FIMemB( XMSPos + 4095 ) = $55 then
       Begin
        FOMemB( XMSPos + 4095, $AA );
        If FIMemB( XMSPos + 4095 ) = $AA then
         Begin
          Done := False;
          XMSLeft := XMSLeft + 4096;
          XMSPos := XMSPos + 4096;
         End;
       End;
     End;
   End;
 Until Done;
 XMSPos := $100000;
End;

{Allocate block of memory, either conventional or XMS, }
{return linear address                                 }
Function AllocLinBlock( Size : LongInt ) : LongInt;
Var
Block : Word;

Begin
 LogWrite('Allocating memory block '+Hl(Size));
 Size := ( Size + 3 ) and $FFFFFFFC; {DWORD ALIGN}
 Asm
  MOV   AH,48H     {Alloc dos mem}
  MOV   BX,0FFFFH  {Get largest free block}
  INT   21H
  MOV   Block,BX
 End;
 If Size <= ( LongInt( Block ) * 16 ) then
  Begin
   Block := ( Size + 15 ) shr 4;
   Asm
    MOV      AH,48H
    MOV      BX,Block
    INT      21H
    MOV      Block,AX
   End;
   AllocLinBlock := LongInt( Block ) * 16;
  End else
 If Size <= XMSLeft then
  Begin
   XMSLeft := XMSLeft - Size;
   AllocLinBlock := XMSPos;
   XMSPos := XMSPos + Size;
  End else AllocLinBlock := 0;
End;

Procedure MoveLinBlockD( Src, Dest, Size : LongInt ); Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD(Src)
 DB     66H
 MOV    DI,WORD(Dest)
 DB     66H
 MOV    CX,WORD(Size)
 MOV    AL,CL
 DB     66H
 SHR    CX,2
 AND    AL,3
 CLD
 DB     26H
 DW     6667H
 REP    MOVSW        {REP MOVSD ES:[EDI],ES:[ESI]}
 MOV    CL,AL
 DW     2667H
 REP    MOVSB        {REP MOVSB ES:[EDI],ES:[ESI]}
End;

Procedure MoveLinBlockB( Src, Dest, Size : LongInt ); Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD(Src)
 DB     66H
 MOV    DI,WORD(Dest)
 DB     66H
 MOV    CX,WORD(Size)
 CLD
 DW     2667H
 REP    MOVSB        {REP MOVSB ES:[EDI],ES:[ESI]}
End;

Procedure MoveLinBlockW( Src, Dest, Size : LongInt ); Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD(Src)
 DB     66H
 MOV    DI,WORD(Dest)
 DB     66H
 MOV    CX,WORD(Size)
 DB     66H
 SHR    CX,1
 CLD
 DW     2667H
 REP    MOVSW        {REP MOVSW ES:[EDI],ES:[ESI]}
 ADC    CL,0
 DW     2667H
 REP    MOVSB        {REP MOVSB ES:[EDI],ES:[ESI]}
End;

Procedure FillLinBlockD( Dest, Size : LongInt; Data : Byte ); Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    DI,WORD(Dest)
 DB     66H
 MOV    CX,WORD(Size)
 MOV    BL,CL
 DB     66H
 SHR    CX,2
 AND    BL,3
 MOV    AL,Data
 MOV    AH,AL
 MOV    SI,AX
 DB     66H
 SHL    AX,16
 MOV    AX,SI
 CLD
 DW     6667H
 REP    STOSW        {REP STOSD ES:[EDI]}
 MOV    CL,BL
 DB     67H
 REP    STOSB        {REP STOSB ES:[EDI]}
End;

Function CompLinBlocks( Block1, Block2, Size : LongInt ) : Boolean; Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD(Block1)
 DB     66H
 MOV    DI,WORD(Block2)
 DB     66H
 MOV    CX,WORD(Size)
 MOV    AL,CL
 DB     66H
 SHR    CX,2
 AND    AL,3
 CLD
 DB     26H
 DW     6667H
 REPZ   CMPSW        {REP CMPSD ES:[EDI],ES:[ESI]}
 JNZ    @@1
 MOV    CL,AL
 DW     2667H
 REPZ   CMPSB        {REP CMPSB ES:[EDI],ES:[ESI]}
 JNZ    @@1
 MOV    AL,1
 JMP    @@2
@@1:
 MOV    AL,0         {not equal-> return false}
@@2:
End;

Function AddMenuItem( Txt, Hlp : String; RY, Flg : Byte;
                      Proc : Pointer; Nxt : PMenuItem ) : PMenuItem;
Var
This : PMenuItem;

Begin
 New( This );
 With This^ do
  Begin
   X := ( 78 - Length( Txt ) ) shr 1;
   Y := RY;
   Descr := ' ' + Txt + ' ';
   Help := Hlp;
   Flags := Flg;
   Action.T := Proc;
   Next := Nxt;
   Prev := Nil;
  End;
 If Nxt <> Nil then Nxt^.Prev := This;
 AddMenuItem := This;
End;

Procedure CursorOn; Assembler;
Asm
 MOV AH,01H
 MOV CX,0607H
 INT 10H
End;

Procedure CursorOff; Assembler;
Asm
 MOV AH,01H
 MOV CX,2000H{0100H} {v1.22}
 INT 10H
End;

Procedure SetMenuItemStatus( Menu : PMenuItem; YVal : Byte; Act : Boolean );
Var
Item : PMenuItem;

Begin
 Item := Menu;
 While ( Item <> Nil ) and
       ( Item^.Y <> YVal ) do Item := Item^.Next;
 If Item <> Nil then
  With Item^ do
   Begin
    If Act then Flags := Flags or 1
     else Flags := Flags and not 1;
    If CurMenu = Menu then
     Begin
      GotoXY( X, Y + MTop );
      If Act then Text_Color( 15 ) else Text_Color( 7 );
      Text_Background( 0 );
      Write( Descr );
     End;
   End;
End;

Procedure RunMenu( Menu : PMenuItem );
Var
SvItem,
NewItem,
CurItem : PMenuItem;
A       : Char;
Done    : Boolean;

Begin
 CursorOff;
 CurMenu := Menu;
 CurItem := Menu;
 While CurItem <> Nil do
  With CurItem^ do
   Begin
    GotoXY( X, Y + MTop );
    If ( Flags and 1 ) <> 0 then Text_Color( 15 ) else Text_Color( 7 );
    Write( Descr );

    CurItem := Next;
   End;
 CurItem := Nil;
 NewItem := Menu;
 Done := False;
 Repeat
  If CurItem <> NewItem then
   Begin
    If CurItem <> Nil then
    With CurItem^ do
     Begin
      GotoXY( X, Y + MTop );
      If ( Flags and 1 ) <> 0 then Text_Color( White ) else Text_Color( LightGray );
      Text_Background( Black );
      Write( Descr );
     End;
    With NewItem^ do
     Begin
      GotoXY( X, Y + MTop );
      If ( Flags and 1 ) <> 0 then Text_Color( White ) else Text_Color( LightGray );
      Text_Background( LightRed );
      Write( Descr );
      GotoXY( 1,25 ); {v1.23}
      If ( Flags and 1 ) <> 0 then Text_Color( LightGreen ) else Text_Color( Green );
      Text_Background( Black );
      ClrEol; {v1.23}
      Write( Help ); {v1.23}
      GotoXY( X, Y + MTop ); {v1.23}
     End;
    CurItem := NewItem;
   End;
  A := _ReadKey; {v1.23}
  Case A of
   #27 : Done := True;
   #13 : If CurItem^.Action.T = Nil then Done := True
         else If ( CurItem^.Flags and 1 ) <> 0 then
          Begin
           If ( CurItem^.Flags and 2 ) = 0 then
            Begin
             Text_Color( 7 );
             Text_Background( 0 );
             CursorOn;
             CurItem^.Action.P;
             CursorOff;
             NewItem := CurItem;
             CurItem := Nil;
            End else
            Begin
             Window( 1, MTop, 80, 22 );
             Text_Background( 0 );
             ClrScr;
             Window( 1, 1, 80, 25 );
             SvItem := CurItem;
             RunMenu( CurItem^.Action.M );
             CursorOff;
             Window( 1, MTop, 80, 22 );
             Text_Background( 0 );
             ClrScr;
             Window( 1, 1, 80, 25 );
             CurItem := Menu;
             While CurItem <> Nil do
              With CurItem^ do
               Begin
                GotoXY( X, Y + MTop );
                If ( Flags and 1 ) <> 0 then Text_Color( 15 ) else Text_Color( 7 );
                Write( Descr );
                CurItem := Next;
               End;
             CurItem := Nil;
             NewItem := SvItem;
            End;
          End;
   #0  : Begin
          A := _ReadKey; {v1.23}
          Case A of
           #80 : If CurItem^.Next <> Nil then NewItem := CurItem^.Next;
           #72 : If CurItem^.Prev <> Nil then NewItem := CurItem^.Prev;
           #71,
           #73 : Begin {v1.22}
                  If CurItem^.Prev <> Nil then NewItem := CurItem^.Prev;
                  while NewItem^.Prev <> Nil do NewItem := NewItem^.Prev;
                 End;
           #79,
           #81 : Begin {v1.22}
                  If CurItem^.Next <> Nil then NewItem := CurItem^.Next;
                  while NewItem^.Next <> Nil do NewItem := NewItem^.Next;
                 End;
          End;
         End;
  End;
 Until Done;
 Text_Background( 0 );
 Text_Color( 7 );
 CursorOn;
End;

Procedure ClearProgressBar;
Begin
 GotoXY( 11, 19 ); ClrEol;
 GotoXY( 11, 20 ); ClrEol;
 GotoXY( 11, 21 ); ClrEol;
End;

Procedure WrtProgressBar( Msg : String );
Begin
 ClearProgressBar;
 GotoXY( 11, 20 );
 ClrEol;
 Text_Color(yellow);
 GotoXY( 33, 19 );
 write('ษออออออออออออออออออออออออออออออออป');
 GotoXY( 11, 20 );
 Write( Msg );
 GotoXY( 33, 20 );
 Write( 'บ');
 Text_Color(4);
 Write('ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ');
 Text_Color(yellow);
 Write('บ' );
 GotoXY( 33, 21 );
 write('ศออออออออออออออออออออออออออออออออผ');
 Text_Color(white);
 GotoXY( 34, 20 );
 Text_Color( 2 );
End;

Procedure Beep( Hz, Ms : Word );
Begin
 Sound( Hz );
 Delay( Ms );
 NoSound;
End;

{NOTE: Should work reliably on 486-25 and up, overflow will}
{      occur on slower processors                          }
Function InitOldWait : Word; Assembler;
Asm
        IN      AL,61H
        AND     AL,0FCH
        OR      AL,1
        OUT     61H,AL
        MOV     AL,0B4H
        OUT     43H,AL
        XOR     AL,AL
        OUT     42H,AL
        DB      66H
        MOV     CX,0
        DW      4
        CLI
        OUT     42H,AL
@@1:    DB      66H
        DEC     CX
        JNZ     @@1
        MOV     AL,80H
        OUT     43H,AL
        IN      AL,42H
        MOV     AH,AL
        IN      AL,42H
        STI
        PUSH    AX
        IN      AL,61H
        AND     AL,0FCH
        OUT     61H,AL
        POP     AX
        XCHG    AH,AL
        NEG     AX
        JNZ     @@2
        INC     AX
@@2:
End;

{$F+}
{High precision (usec) delay}
Procedure OldWait( MiSec : LongInt ); Assembler;
Asm
(*  DB  66H
  MOV CX,WORD PTR MiSec
  MOV DX,0EDh
  XOR AL,AL
@1:OUT DX,AL
  LOOP @1*)
        DB      66H
        XOR     BX,BX
        DB      66H
        MOV     AX,WORD PTR MiSec
        MOV     BX,MicroSec
        DB      66H
        MUL     BX
        DB      66H
        MOV     CX,AX
        PUSHF
        CLI
@@1:    DB      66H
        DEC     CX
        JNZ     @@1
        POPF
End;
{$F-}

function zero2str(s, o : word) : string;
var outstr : string;
i,c : byte;
begin
i:=0;
c:=0;
outstr[0]:=#0;
while (mem[s:o+i]<>0) and (i<255) do
      begin
      inc(c);
      outstr[1+i]:=char(mem[s:o+i]);
      inc(i);
      end;
outstr[0]:=#0;
zero2str:=outstr;
end;

function Time:String; {v1.23}
var Hour,Min,Sec,Sec100:Word;
    S,S1:String;
begin
  GetTime(Hour,Min,Sec,Sec100);
  Str(Hour,S);
  if Length(S)<2 then S:='0'+S;
  S1:=S;
  Str(Min,S);
  if Length(S)<2 then S:='0'+S;
  S1:=S1+':'+S;
  Str(Sec,S);
  if Length(S)<2 then S:='0'+S;
  S1:=S1+':'+S;
  Str(Sec100,S);
  if Length(S)<2 then S:='0'+S;
  S1:=S1+'.'+S;
  Time:=S1;
end;

function _Str(I:LongInt):String;
var S:String;
begin
 Str(I,S);
 _Str:=S;
end;

procedure LogWrite(S:String); {v1.23}
var F : Text;

 procedure LogDisable;
 begin
   WriteLn;
   WriteLn('Warning: unable to write to log file, logging disabled.');
   Logging:=False;
 end;

begin
 if Logging then
  Begin
   Assign( F, 'UNIFLASH.LOG');
   Append( F );
   if IOResult=2 then
    begin
      ReWrite( F );
      if IOResult<>0 then
       begin
         LogDisable;
         Exit;
       end;
    end;
   WriteLn( F, Time,': ',S);
   Close(F);
   if IOResult<>0 then
    begin
      LogDisable;
      Exit;
    end;
  End;
end;

procedure LogStart; {v1.23}
var S:String;
    A:Byte;
begin
 S:='';
 for A:=0 to ParamCount do S:=S+ParamStr(A)+' ';
 Delete(S,Length(S),1);
 LogWrite('UniFlash v'+Version+' started: '+S);
end;

procedure LogEnd; {v1.23}
var F : Text;
    A : Byte;
begin
 if Logging then
  Begin
   Assign( F, 'UNIFLASH.LOG');
   Append( F );
   for A := 1 to 78 do Write(F, '-');
   WriteLn(F);
   Close(F);
  End;
end;

procedure Text_Color(Color:Byte); {v1.27}
begin
  if not Mono then TextColor(Color);
end;

procedure Text_Background(Color:Byte); {v1.27}
begin
  if not Mono then TextBackground(Color) else
   if Color=Black then
    begin
      TextBackground(Black);
      TextColor(LightGray);
    end
   else
    begin
      TextBackground(LightGray);
      TextColor(Black);
    end;
end;

procedure ClrKbBuf; {v1.23}
begin
  MemW[$40:$1A]:=MemW[$40:$80]; {Next char := Buffer beginning}
  MemW[$40:$1C]:=MemW[$40:$80]; {First free char := Buffer beginning}
  Mem[$40:$17]:=0; {Clear keyboard flags} {v1.27}
  Mem[$40:$18]:=0;
end;

function _ReadKey:Char; {v1.23}
var A,Z:Byte;
const KeyTable:string[127]=#27'1234567890-='#8#9'qwertyuiop[]'#13#0'asdfghjkl;''`'#0'\zxcvbnm,./'#0'*'#0' '#0;
 KeyTableShift:string[127]=#27'!@#$%^&*()_+'#8#9'QWERTYUIOP{}'#13#0'ASDFGHJKL:"~'#0'|ZXCVBNM<>?'#0#0#0' '#0;
begin
  ClrKbBuf;
  if Ext<>#0 then
   begin
     _ReadKey:=Ext;
     Ext:=#0;
     Exit;
   end;
  A:=Port[$60];
  if (History[1]<>History[2]) and (Char(A)=History[2]) then
   begin
    for Z:=1 to 250 do
     begin
       Delay(1);
       if A<>Port[$60] then Break;
     end;
   end
  else Delay(50);
  repeat
    A:=Port[$60];
    if (A=42) or (A=54) then begin Shift:=True; Continue; end;
    if (A=170) or (A=182) then begin Shift:=False; Continue; end;
    if (A>127) then History[2]:=#0;
    if (A>58) and (A<128) then
     begin
       Ext:=Char(A);
       _ReadKey:=#0;
       History[1]:=History[2];
       History[2]:=Char(A);
       Exit;
     end;
  until (A<128) and (A>0) and (KeyTable[A]<>#0);
  if Shift then _ReadKey:=KeyTableShift[A] else _ReadKey:=KeyTable[A];
  History[1]:=History[2];
  History[2]:=Char(A);
end;

function strcomp(s1,s2 : string; b : byte) : boolean;
var i : byte;
begin
strcomp:=true;
for i:=1 to b do
    if s1[i]<>s2[i] then strcomp:=false;
end;

procedure _Delay; {v1.22}
begin
  Delay(100);
end;

procedure InitTSC;assembler; {Requires Pentium or newer CPU} {v1.22}
asm
  pushf                     {PUSHF}
  cli                       {CLI}
  dw   310fh                {RDTSC}
  db   66h
  push ax                   {PUSH EAX}
  call _Delay               {DELAY(100)}         {Delay 100ms}
  dw   310fh                {RDTSC}
  db   66h
  pop  bx                   {POP EBX}
  db   66h
  sub  ax,bx                {SUB EAX,EBX}        {Ticks elapsed ->EAX}
  db   66h
  mov  word ptr tsc,ax      {MOV TSC,EAX}        {Ticks per second}
  popf                      {POPF}               {Instead of STI}
end;

{$F+}
procedure TSCWait(MicroSec:LongInt);assembler; {v1.22}
asm
  dw   310fh                {RDTSC}
  db   66h
  mov  bx,ax                {MOV EBX,EAX}
  db   66h
  mov  cx,dx                {MOV ECX,EDX}
  db   66h
  mov  ax,word ptr MicroSec {MOV EAX,MicroSec}
  db   66h
  mul  word ptr uSec        {MUL uSec}          {Ticks to wait ->EDX:EAX}
  db   66h
  add  bx,ax                {ADD EBX,EAX}
  db   66h
  adc  cx,dx                {ADC ECX,EDX}
@:dw   310fh                {RDTSC}
  db   66h
  cmp  dx,cx                {CMP EDX,ECX}       {Waiting enough?}
  je   @low                 {JE  @low}          {Waiting enough (high)}
  ja   @exit                {JA  @exit}         {Waiting more! Exit!}
  jmp  @                    {JMP @}             {Not enough, wait more}
@low:
  db   66h
  cmp  ax,bx                {CMP EAX,EBX}       {Waiting enough?}
  jae  @exit                {JL  @}             {Not enough, wait more}
  jmp  @
@exit:
end;
{$F-}

function TSCPresent:Boolean;assembler; {v1.22}
asm
  db   66h
  pushf                     {PUSHFD}
  db   66h
  pop  ax                   {POP EAX}           {Read EFLAGS register to EAX}
  db   66h
  push ax                   {PUSH EAX}          {Save it for later use}
  db   66h
  or   ax,0h
  dw   20h                  {OR EAX,200000h}    {Set CPUID bit}
  db   66h
  push ax                   {PUSH EAX}
  db   66h
  popf                      {POPFD}             {Put EAX to EFLAGS}
  db   66h
  pushf                     {PUSHFD}
  db   66h
  pop  ax                   {POP EAX}           {Read back EFLAGS to EAX}
  db   66h
  and  ax,0h
  dw   20h                  {AND EAX,200000h}
  db   66h
  cmp  ax,0h
  dw   20h                  {CMP EAX,200000h}   {Is CPUID bit set?}
  jne  @bad                 {JNE @BAD}          {If not, CPUID not supported}
  db   66h
  xor  ax,ax                {XOR EAX,EAX}
  dw   0a20fh               {CPUID}             {Call level 0 CPUID}
  dd   0f88366h             {CMP EAX,0}         {Is MaxLevel 0?}
  je   @bad                 {JE @BAD}           {If yes, it's bad, we need 1}
  db   66h
  xor  ax,ax                {XOR EAX,EAX}
  db   66h
  inc  ax                   {INC EAX}           {MOV EAX,1}
  dw   0a20fh               {CPUID}             {Call level 1 CPUID}
  dd   10e28366h            {AND EDX,10h}
  db   66h
  cmp  dx,10h               {CMP EDX,10h}       {Is TSC bit set?}
  jne  @bad                 {JNE @BAD}          {If not, TSC not present}
  mov  ax,1                 {MOV AX,1}          {Return TRUE}
  jmp  @exit
@bad:
  xor  ax,ax                {XOR AX,AX}         {Return FALSE}
  jmp  @exit
@exit:
  db 66h
  popf                      {POPFD}             {Restore EFLAGS register}
end;

function NoVideo:Boolean;assembler; {v1.28}
asm
  mov ah,0Fh
  mov al,0FFh
  int 10h
  cmp al,0FFh
  je  @novideo
  xor ax,ax
  jmp @quit
@novideo:
  mov ax,1
@quit:
end;

procedure FInput(var Name:String;DefaultName:String;MaxLen:Byte); {v1.28}
var S:String;
    Ch:Char;
    Default:Boolean;
    A,Pos,StartX:Byte;
begin
  ClrKbBuf;
  S:=DefaultName;
  Default:=DefaultName<>'';
  Pos:=Length(S)+1;
  StartX:=WhereX;
  Write(S);
  repeat
    Ch:=_ReadKey;
    if Ch=#27 then
     begin
       Name:='';
       Exit;
     end;
    if Ch=#13 then
     begin
       if (S='') and (DefaultName='') then
        begin
          S:=BrowseFile;
          Write(S);
          Pos:=Length(S)+1;
        end
       else Break;
     end;
    if Ch=#8 then
     begin
       if (Length(S)>0) and (Pos>1) then
        begin
          Dec(Pos);
          Delete(S,Pos,1);
          Write(#8' '#8);
          for A:=Pos to Length(S) do Write(S[A]);
          Write(' ');
          GotoXY(StartX+Pos-1,WhereY);
          Default:=False;
        end;
       Continue;
     end;
    if Ch=#0 then
     begin
       Ch:=_ReadKey;
       case Ch of
        #75:if Pos>1 then Dec(Pos);
        #77:if Pos<=Length(S) then Inc(Pos);
        #71:Pos:=1;
        #79:Pos:=Length(S)+1;
        #83:begin
              if (Length(S)>0) and (Pos<=Length(S)) then
               begin
                 Delete(S,Pos,1);
                 Write(' '#8);
                 for A:=Pos to Length(S) do Write(S[A]);
                 Write(' ');
                 GotoXY(StartX+Pos-1,WhereY);
                 Default:=False;
               end;
              Continue;
            end;
       end;
       if (Ch=#75) or (Ch=#77) or (Ch=#71) or (Ch=#79) then
        begin
          GotoXY(StartX+Pos-1,WhereY);
          Default:=False;
        end;
       Continue;
     end;
    if (Length(S)>=MaxLen) or (Ord(Ch)<32) then Continue;
    if Default then
     begin
       S:='';
       for A:=1 to Length(DefaultName) do Write(#8' '#8);
       Pos:=1;
       Default:=False;
     end;
    Insert(Ch,S,Pos);
    for A:=Pos to Length(S) do Write(S[A]);
    Inc(Pos);
    GotoXY(StartX+Pos-1,WhereY);
  until False;
  Name:=S;
end;

function UpCaseStr(S:String):String; {v1.28}
var S0:String;
    A:Byte;
begin
  S0:='';
  for A:=1 to Length(S) do S0:=S0+UpCase(S[A]);
  UpCaseStr:=S0;
end;

function LowCaseStr(S:String):String; {v1.28}
var S0:String;
    A:Byte;
begin
  S0:='';
  for A:=1 to Length(S) do if (S[A]>='A') and (S[A]<='Z') then S0:=S0+Chr(Ord(S[A])+32) else S0:=S0+S[A];
  LowCaseStr:=S0;
end;

function Zero2Name(S:String):String; {v1.28}
var S0:String;
begin
  if (Pos(#0,S)<>0) and (S[1]<>'.') then S[Pos(#0,S)]:='.';
  while Pos(#0,S)<>0 do Delete(S,Pos(#0,S),1);
  Zero2Name:=S;
end;

function Min(A,B:LongInt):LongInt; {v1.28}
begin
  if A<B then Min:=A else Min:=B;
end;

function BrowseFile:String; {v1.28}
var SR:SearchRec;
    A,Count,CurPos,PagePos,OldPos,StackPos,FreeSpace:Word;
    P:Pointer;
    PP:LongInt absolute P;
    Ch:Char;
    Stack:array[1..256] of Word;
    X,Y,DrivePos:Byte;
    Path,Drives:String;
const PageSize=13;
type FileName=array[1..12] of Char;

 procedure StoreName(Name:String;Position:Word;Dir:Boolean);
 var S:String;
     A:Byte;
 begin
   if Name='..' then Name:=#1+'..'#0#0#0#0#0#0#0#0#0 else
    begin
      if Dir then S:=#1#0#0#0#0#0#0#0#0#0#0#0 else S:=#255#0#0#0#0#0#0#0#0#0#0#0;
      A:=Pos('.',Name);
      if A=0 then Move(Name[1],S[2],Length(Name)) else
       begin
         Move(Name[1],S[2],A-1);
         Move(Name[A+1],S[10],Length(Name)-A);
       end;
      Name:=S;
    end;
   Move(Name[1],Pointer(PP+Position*SizeOf(FileName))^,Length(Name));
 end;

 function GetName(Pos:Word;Full:Boolean):String;
 var S:String;
 begin
   S:=#0#0#0#0#0#0#0#0#0#0#0#0;
   if Full then Move(Pointer(PP+Pos*SizeOf(FileName))^,S[1],12)
    else Move(Pointer(PP+Pos*SizeOf(FileName)+1)^,S[1],11);
   if S[9]<>#0 then S:=Copy(S,1,8)+#0+Copy(S,9,Length(S)-9);
   GetName:=S;
 end;

 procedure DobosSort;
 var Step,I:LongInt;
     OK:Boolean;
     S:String;
     A:Byte;

   procedure ExChange(X,Y:Word);
   var A:FileName;
   begin
     Move(Pointer(PP+X*SizeOf(FileName))^,A,SizeOf(A));
     Move(Pointer(PP+Y*SizeOf(FileName))^,Pointer(PP+X*SizeOf(FileName))^,SizeOf(FileName));
     Move(A,Pointer(PP+Y*SizeOf(FileName))^,SizeOf(FileName));
   end;

 begin
   Step:=Count;
   if Zero2Name(GetName(1,False))='..' then A:=2 else A:=1;
   repeat
     OK:=True;
     Step:=(Step*4) div 5;
     if Step<1 then Step:=1;
     for I:=Step+A to Count do
     if (GetName(I,True)<GetName(I-Step,True)) then
      begin
        ExChange(I,I-Step);
        OK:=False;
      end;
   until (OK) and (Step=1);
 end;

 procedure DispFile(Name:String;Active,NextLine:Boolean);
 var A:Byte;
 begin
   if Active then Text_Background(Blue) else Text_Background(Black);
   Write(' '+Name);
   for A:=1 to 13-Length(Name) do Write(' ');
   if NextLine then WriteLn;
   Text_Background(Black);
 end;

 procedure ReadDir;
 begin
   FindFirst('*.*',AnyFile and not VolumeID,SR);
   A:=1;
   while (DOSError=0) and (A<FreeSpace div 12) do
    begin
      if SR.Name<>'.' then
       begin
         if SR.Attr and Directory<>Directory then StoreName(LowCaseStr(SR.Name),A,False)
          else StoreName(UpCaseStr(SR.Name),A,True);
         Inc(A);
       end;
      FindNext(SR);
    end;
   Count:=A-1;
   CurPos:=1;
   PagePos:=1;
   OldPos:=1;
   DobosSort;
 end;

 function GetDrive:Byte;assembler;
 asm mov ah,$19; int 21h; end;

 procedure SetDrive(A:Byte);assembler;
 asm mov ah,$0E; mov dl,a; int $21; end;

 function ValidDrive(Dr:Char):Boolean;
 var S,S1: string[40];
     B,B1: Byte;
     R: Registers;
     NumFloppy:Byte;
 begin
  ValidDrive:=False;
  if Dr<'A' then Exit;
  if Dr='A' then
   begin
     R.AH:=$15;
     R.DL:=0;
     Intr($13,R);
     if ((R.Flags) and fCarry=fCarry) or (R.AH=0) then ValidDrive:=False else ValidDrive:=True;
     Exit;
   end;
  if Dr='B' then
   begin
     R.AH:=$15;
     R.DL:=1;
     Intr($13,R);
     if ((R.Flags) and fCarry=fCarry) or (R.AH=0) then ValidDrive:=False else ValidDrive:=True;
     Exit;
   end;
  B:=GetDrive;
  SetDrive(Byte(Dr)-65);
  B1:=GetDrive;
  SetDrive(B);
  if Byte(Dr)-65<>B1 then Exit;
  S:=Dr+':\'#0;
  R.ax:=$2900;
  R.ds:=Seg(S);
  R.si:=Ofs(S[1]);
  R.es:=Seg(S1);
  R.di:=Ofs(S1);
  Intr($21,R);
  if R.ax<>$FF then ValidDrive:=True else ValidDrive:=False;
 end;

 procedure ChangeDrive(Drive:Char);
 var OldDir:String;
     A:Byte;
 begin
   GetDir(0,OldDir);
   ChDir(Drive+':\');
   if IOResult<>0 then
    begin
      ChDir(OldDir);
      Exit;
    end;
   ReadDir;
   Window(2,9,17,22);
   Text_Background(Black);
   ClrScr;
   Window(2,9,17,23); {v1.31}
   for A:=PagePos to Min(PagePos+PageSize,Count) do DispFile(GetName(A,False),A=CurPos,True);
   Window(25,22,80,22);
 end;

begin
  FreeSpace:=Min(MaxAvail,65520);
  GetMem(P,FreeSpace);
  StackPos:=1;

  ReadDir;

  Text_Background(Black);
  X:=WhereX;
  Y:=WhereY;
  CursorOff;
  Window(2,9,17,22);
  ClrScr;
  Window(2,9,17,23);
  for A:=PagePos to Min(PagePos+PageSize,Count) do DispFile(GetName(A,False),A=CurPos,True);

  repeat
    Ch:=_ReadKey;
    if Ch=#27 then
     begin
       Window(2,9,17,22);
       ClrScr;
       BrowseFile:='';
       Break;
     end;
    if Ch=#13 then
     begin
       if Copy(GetName(CurPos,True),1,1)=#255 then
        begin
          Window(2,9,17,22);
          ClrScr;
          BrowseFile:=Zero2Name(GetName(CurPos,False));
          Break;
        end;
       ChDir(Zero2Name(GetName(CurPos,False)));
       if Zero2Name(GetName(CurPos,False))='..' then
        begin
          ReadDir;
          if StackPos>1 then
           begin
             Dec(StackPos);
             PagePos:=Stack[StackPos];
             Dec(StackPos);
             CurPos:=Stack[StackPos];
           end
          else
           begin
             PagePos:=1;
             CurPos:=1;
           end;
        end
       else
        begin
          Stack[StackPos]:=CurPos;
          Inc(StackPos);
          Stack[StackPos]:=PagePos;
          Inc(StackPos);
          ReadDir;
        end;
       Window(2,9,17,22);
       ClrScr;
       Window(2,9,17,23);
       OldPos:=CurPos;
       for A:=PagePos to Min(PagePos+PageSize,Count) do DispFile(GetName(A,False),A=CurPos,True);
     end;
    if Ch=#9 then
     begin
       Window(25,22,80,22);
       GetDir(0,Path);
       Drives:='';
       for Ch:='A' to 'Z' do if ValidDrive(Ch) then
        begin
          Drives:=Drives+Ch;
          if UpCase(Path[1])=Ch then DrivePos:=Length(Drives);
        end;
       repeat
         GotoXY(1,1);
         for A:=1 to Length(Drives) do
          begin
            if A=DrivePos then Text_Background(Green) else Text_Background(Black);
            Write(' '+Drives[A]+' ');
          end;
         Ch:=_ReadKey;
         case Ch of
          #0:case _ReadKey of
              'K':if DrivePos>1 then Dec(DrivePos);
              'M':if DrivePos<Length(Drives) then Inc(DrivePos);
             end;
          #27:Break;
          #9,#13:begin
                   ChangeDrive(Drives[DrivePos]);
                   Break;
                 end;
          'a'..'z','A'..'Z':begin
                     ChangeDrive(UpCase(Ch));
                     Break;
                   end;
         end;
       until False;
       GotoXY(1,1);
       Text_Background(Black);
       ClrEol;
       Window(2,9,17,23);
     end;
    if Ch=#0 then
     begin
       OldPos:=CurPos;
       case _ReadKey of
        'I':if CurPos<=PageSize then CurPos:=1 else CurPos:=CurPos-PageSize;
        'Q':if CurPos>Integer(Count)-PageSize then CurPos:=Count else CurPos:=CurPos+PageSize;
        'H':if CurPos>1 then Dec(CurPos);
        'P':if CurPos<Count then Inc(CurPos);
        'G':CurPos:=1;
        'O':CurPos:=Count;
       end;
     end;
    if (Count=0) or (CurPos=OldPos) then Continue;
    if (CurPos<=PagePos+PageSize) and (CurPos>=PagePos) then
     begin
       GotoXY(1,OldPos-PagePos+1);
       DispFile(GetName(OldPos,False),False,False);
       GotoXY(1,WhereY+(Integer(CurPos)-OldPos));
       DispFile(GetName(CurPos,False),True,False);
     end
    else
     begin
       if CurPos>PagePos+PageSize then Inc(PagePos);
       if CurPos>PagePos+PageSize then
        begin
          while CurPos>PagePos+PageSize do PagePos:=PagePos+PageSize;
          Dec(PagePos);
        end;
       if CurPos<PagePos then Dec(PagePos);
       if CurPos<PagePos then
        begin
          if PagePos>PageSize then
           begin
             while CurPos<PagePos do if PagePos>PageSize then PagePos:=PagePos-PageSize else PagePos:=0;
             Inc(PagePos);
           end else PagePos:=1;
        end;
       if Count-PagePos<PageSize then PagePos:=Count-PageSize;
       Window(2,9,17,22);
       ClrScr;
       Window(2,9,17,23);
       for A:=PagePos to Min(PagePos+PageSize,Count) do DispFile(GetName(A,False),A=CurPos,True);
     end;
  until False;

  FreeMem(P,FreeSpace);
  Window(1,1,80,25);
  GotoXY(X,Y);
  CursorOn;
  ClrKbBuf;
end;

function IntToStr(I:LongInt):String; {v1.28}
var S:String;
begin
  Str(I,S);
  IntToStr:=S;
end;

Begin
 If not Windows and not EMM386 and TSCPresent then {v1.22}
  Begin
    InitTSC;
    uSec := TSC div 100000;
    Wait := TSCWait;
  End
 else
  Begin
    MicroSec := 312785 div InitOldWait;
    Wait := OldWait;
  End;
End.