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
Version    = '1.24';
XMSLeft    : LongInt = 0;
XMSPos     : LongInt = 0;
Logging    : Boolean = False; {v1.23}
var Wait:WaitProc;

Function ConstPtr( Const S : String ) : Pointer;
Function FIMemB( Addr : LongInt ) : Byte;
Function FIMemW( Addr : LongInt ) : Word;
Procedure FOMemB( Addr : LongInt; Data : Byte );
Procedure FOMemW( Addr : LongInt; Data : Word );
Function Hb( B : Byte ) : String;
Function Hw( W : Word ) : String;
Function Hl( L : Longint ) : String;
Function Windows : Boolean; {v1.22}
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
{Procedure Wait( MiSec : LongInt );}
function zero2str(s,o : word) : string;
{procedure cwriteln(c1,c2 : byte; s1,s2 : string);
procedure cwrite(c1,c2 : byte; s1,s2 : string);}
function strcomp(s1,s2 : string; b : byte) : boolean;
function _ReadKey:Char; {v1.23}
function _Str(I:LongInt):String; {v1.23}
procedure LogWrite(S:String); {v1.23}
procedure LogStart; {v1.23}
procedure LogEnd; {v1.23}

Implementation

Uses Crt,Dos;

Const
MTop    = 10{9}; {v1.22}
XMSHnd  : Word = 0;

Var
TmpGDT    : ARRAY[ 0 .. 7 ] of Word;
SaveEProc : Pointer;
XMMRtn    : LongInt;
CurMenu   : PMenuItem;
MicroSec  : Word;
TSC,uSec  : LongInt; {v1.22}
Ext       : Char; {v1.23}
History   : String[2]; {v1.23}
Shift     : Boolean; {v1.23}

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

Procedure FOMemW( Addr : LongInt; Data : Word ); Assembler;
Asm
 XOR    AX,AX
 MOV    ES,AX
 DB     66H
 MOV    SI,WORD PTR Addr    {MOV ESI,Addr}
 MOV    AX,Data
 DB     26H,67H,89H,06H     {MOV ES:[ESI],AX}
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
 if SaveEProc=nil then Exit;
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
 ExitProc := SaveEProc;
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
 SaveEProc:=nil;
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
 SaveEProc := ExitProc;
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
      If Act then TextColor( 15 ) else TextColor( 7 );
      TextBackGround( 0 );
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
    If ( Flags and 1 ) <> 0 then TextColor( 15 ) else TextColor( 7 );
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
      If ( Flags and 1 ) <> 0 then TextColor( White ) else TextColor( LightGray );
      TextBackGround( Black );
      Write( Descr );
     End;
    With NewItem^ do
     Begin
      GotoXY( X, Y + MTop );
      If ( Flags and 1 ) <> 0 then TextColor( White ) else TextColor( LightGray );
      TextBackGround( LightRed );
      Write( Descr );
      GotoXY( 1,25 ); {v1.23}
      If ( Flags and 1 ) <> 0 then TextColor( LightGreen ) else TextColor( Green );
      TextBackGround( Black );
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
             textcolor( 7 );
             textbackground( 0 );
             CursorOn;
             CurItem^.Action.P;
             CursorOff;
             NewItem := CurItem;
             CurItem := Nil;
            End else
            Begin
             Window( 1, MTop, 80, 22 );
             TextBackGround( 0 );
             ClrScr;
             Window( 1, 1, 80, 25 );
             SvItem := CurItem;
             RunMenu( CurItem^.Action.M );
             CursorOff;
             Window( 1, MTop, 80, 22 );
             TextBackGround( 0 );
             ClrScr;
             Window( 1, 1, 80, 25 );
             CurItem := Menu;
             While CurItem <> Nil do
              With CurItem^ do
               Begin
                GotoXY( X, Y + MTop );
                If ( Flags and 1 ) <> 0 then TextColor( 15 ) else TextColor( 7 );
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
 TextBackGround( 0 );
 TextColor( 7 );
 CursorOn;
End;

Procedure ClearProgressBar;
Begin
 gotoxy( 11, 19 ); ClrEol;
 gotoxy( 11, 20 ); ClrEol;
 gotoxy( 11, 21 ); ClrEol;
End;

Procedure WrtProgressBar( Msg : String );
Begin
 ClearProgressBar;
 GotoXY( 11, 20 );
 ClrEol;
 Textcolor(yellow);
 GotoXY( 33, 19 );
 write('ษออออออออออออออออออออออออออออออออป');
 GotoXY( 11, 20 );
 Write( Msg );
 GotoXY( 33, 20 );
 Write( 'บ');
 TextColor(4);
 Write('ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ');
 TextColor(yellow);
 Write('บ' );
 GotoXY( 33, 21 );
 write('ศออออออออออออออออออออออออออออออออผ');
 Textcolor(white);
 GotoXY( 34, 20 );
 TextColor( 2 );
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

{procedure cwriteln(c1,c2 : byte; s1,s2 : string);
begin
textcolor(c1);
write(s1);
textcolor(c2);
writeln(s2);
end;

procedure cwrite(c1,c2 : byte; s1,s2 : string);
begin
textcolor(c1);
write(s1);
textcolor(c2);
write(s2);
end;}

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
begin
 if Logging then
  Begin
   Assign( F, 'UNIFLASH.LOG');
   Append( F );
   if IOResult <> 0 then ReWrite( F );
   WriteLn( F, Time,': ',S);
   Close(F);
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

procedure ClrKbBuf; {v1.23}
begin
  MemW[$40:$1A]:=MemW[$40:$80]; {Next char := Buffer beginning}
  MemW[$40:$1C]:=MemW[$40:$80]; {First free char := Buffer beginning}
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


Begin
 If TSCPresent then {v1.22}
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