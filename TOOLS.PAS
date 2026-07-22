{$R-}
{$I-}

Unit Tools;

Interface

Type 
  ProcType   = Procedure ;
  WaitProc   = Procedure ( MicroSec: LongInt ); {v1.22}
  PMenuItem  = ^MenuItem;
  MenuItem   = Record
    X, Y   : Byte;
    Descr  : String[60]; {v1.23 80->60}
    Help   : String[79]; {v1.23}
    Flags  : Byte;
    Action : Record
      Case Integer Of 
        0 : ( P : ProcType );
        1 : ( M : PMenuItem );
        2 : ( T : Pointer );
    End;
    Next,
    Prev   : PMenuItem;
  End;

Const 
  Version    = '1.50';
  XMSLeft    : LongInt = 0;
  XMSPos     : LongInt = 0;
  Logging    : Boolean = False; {v1.23}
  Mono       : Boolean = False; {v1.27}

Var Wait: WaitProc;

Function ConstPtr( Const S : String ) : Pointer;
Function FIMemB( Addr : LongInt ) : Byte;
Function FIMemW( Addr : LongInt ) : Word;
Procedure FOMemB( Addr : LongInt; Data : Byte );
Function Hb( B : Byte ) : String;
Function Hw( W : Word ) : String;
Function Hl( L : Longint ) : String;
Function Hex2Dec(S:String): LongInt; {v1.32}
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
                     Proc : ProcType; Nxt : PMenuItem ) : PMenuItem;
Function AddSubMenuItem( Txt, Hlp : String; RY, Flg : Byte;
                        Sub : PMenuItem; Nxt : PMenuItem ) : PMenuItem;
Procedure RunMenu( Menu : PMenuItem );
Procedure WrtProgressBar( Msg : String );
Procedure ClearProgressBar;
Procedure Beep( Hz, Ms : Word );
Function zero2str(s,o : word) : string;
Function strcomp(s1,s2 : String; b : byte) : boolean;
Procedure ClrKbBuf; {v1.27}
Procedure InitKB; {v1.38}
Function _ReadKey: Char; {v1.23}
Function _Str(I:LongInt): String; {v1.23}
Procedure LogWrite(S:String); {v1.23}
Procedure LogStart; {v1.23}
Procedure LogEnd; {v1.23}
Procedure Text_Color(Color:Byte); {v1.27}
Procedure Text_Background(Color:Byte); {v1.27}
Function NoVideo: Boolean; {v1.28}
Procedure FInput(Var Name:String;DefaultName:String;MaxLen:Byte); {v1.28}
Function BrowseFile: String; {v1.28}
Function IntToStr(I:LongInt): String; {v1.28}

Implementation

Uses Crt,Dos;

Const 
  MTop    = 10{9}; {v1.22}
  XMSHnd  : Word = 0;

Var 
  TmpGDT    : ARRAY[ 0 .. 7 ] Of Word;
  XMMRtn    : LongInt;
  CurMenu   : PMenuItem;
  MicroSec  : Word;
  TSC,uSec  : LongInt; {v1.22}
  Ext       : Char; {v1.23}
  History   : String[2]; {v1.23}
  Shift     : Boolean; {v1.23}
  XMSManager: Boolean; {v1.27}
  ConstStringPos : Byte;
  ConstStrings   : Array[ 0 .. 7 ] Of String;

Function ConstPtr( Const S : String ) : Pointer;
Begin


{Borland kept literal const parameters in stable storage.  FPC may pass a
  temporary here, so returning @S leaves a dangling pointer.  Keep a small
  rotating pool; chip identification consumes the strings immediately and
  retains only the final manufacturer/name pair.}
  ConstStrings[ ConstStringPos ] := S;
  ConstPtr := @ConstStrings[ ConstStringPos ];
  ConstStringPos := ( ConstStringPos + 1 ) And 7;
End;

Function FIMemB( Addr : LongInt ) : Byte;
Assembler;
Asm
XOR    AX,AX
MOV    ES,AX
DB     66H
MOV    SI,WORD PTR Addr    {MOV ESI,Addr}
DB     26H,67H,8AH,06H     {MOV AL,ES:[ESI]}
End;

Function FIMemW( Addr : LongInt ) : Word;
Assembler;
Asm
XOR    AX,AX
MOV    ES,AX
DB     66H
MOV    SI,WORD PTR Addr    {MOV ESI,Addr}
DB     26H,67H,8BH,06H     {MOV AX,ES:[ESI]}
End;

Procedure FOMemB( Addr : LongInt; Data : Byte );
Assembler;
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

Function Hex2Dec(S:String): LongInt; {v1.32}

Var A,I,Z: LongInt;
Begin
  I := 0;
  Z := 1;
  For A:=Length(S) Downto 1 Do
    Begin
      If S[A] In ['0'..'9'] Then I := I+(Ord(S[A])-48)*Z;
      If S[A] In ['A'..'F'] Then I := I+(Ord(S[A])-55)*Z;
      If S[A] In ['a'..'f'] Then I := I+(Ord(S[A])-87)*Z;
      Z := Z shl 4;
    End;
  Hex2Dec := I;
End;

{Detect if Windows is running}
Function Windows : Boolean;
Assembler; {v1.22}
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
Function EMM386: Boolean; {v1.27}

Var F: File;
Begin
  Assign(F,'EMMXXXX0');
  Reset(F);
  If IOResult<>0 Then
    Begin
      EMM386 := False;
      Exit;
    End;
  EMM386 := True;
  Close(F);
End;

{Set flat real mode, return false on error}
Function FlatRealOn : Boolean;
Assembler;
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
MOV     WORD [DS: SI],10H  {GDT limit}
                  MOV     [DS: SI+2],BX      {GDT linear addr lo}
                               DB      66H
                               SHR     BX,16   {BX=Hi(EBX)}
                               MOV     [DS: SI+4],BX      {GDT linear addr hi}
                                            XOR     DX,DX
                                            MOV     WORD [DS: SI+10],DX
                                                        {segment base bits 0-15}
                                                              DEC     DX
                                                              MOV     WORD [DS:

                                                                              SI

                                                                               +

                                                                               8

                                                                               ]

                                                                               ,

                                                                              DX
                                     {segment limit bits 0..15 (actually 12-27)}


                                                                             MOV

                                                                            WORD

                                                                               [

                                                                              DS

                                                                               :

                                                                              SI

                                                                               +

                                                                              12

                                                                               ]

                                                                               ,

                                                                           09200

                                                                               H
                                     {segment base bits 16-23, R/W,DT1,DPL0,P=1}


                                                                             MOV

                                                                            WORD

                                                                               [

                                                                              DS

                                                                               :

                                                                              SI

                                                                               +

                                                                              14

                                                                               ]

                                                                               ,

                                                                             008

                                                                              FH
                                     {segment limit bits 16-19 (actually 28-31)}
                                      {D=0,G=1(4K), segment base bits 24-31}


                                                                            LGDT

                                                                               [

                                                                              DS

                                                                               :

                                                                          OFFSET

                                                                          TmpGDT

                                                                               ]
                                                                     {Load GDTR}


                                                                             INC

                                                                              AX
                                                                         {PM on}


                                                                             CLI


                                                                            LMSW

                                                                              AX
                                                                  {switch to PM}


                                                                             MOV

                                                                              BX

                                                                               ,

                                                                              08

                                                                               H
                                                                  {flat segment}


                                                                             MOV

                                                                              ES

                                                                               ,

                                                                              BX
                                              {ES=flat. NOTE:DS=flat->error??!!}


                                                                              DB

                                                                               0

                                                                              FH

                                                                               ,

                                                                              20

                                                                               H

                                                                               ,

                                                                               0

                                                                             C0H
                                                                   {MOV EAX,CR0}


                                                                             DEC

                                                                              AX
                                                                        {PM off}


                                                                              DB

                                                                               0

                                                                              FH

                                                                               ,

                                                                              22

                                                                               H

                                                                               ,

                                                                               0

                                                                             C0H
                                                                   {MOV CR0,EAX}


                                                                             STI


                                                                             MOV

                                                                              AL

                                                                               ,

                                                                               1


                                                                             JMP

                                                                               @

                                                                            exit


                                                                               @

                                                                           error

                                                                               :

                                                                             XOR

                                                                              AL

                                                                               ,

                                                                              AL


                                                                               @

                                                                            exit

                                                                               :
End;

{Disable flat real mode}
{NOTE: It is assumed that FlatRealOn has been previously called !!}
Procedure FlatRealOff;
Assembler;
Asm
MOV     SI,OFFSET TmpGDT
MOV     BYTE [DS: SI+14],00H {segment limit bits 16-19 (actually 28-31)}
                                    {D=0,G=0(byte), segment base bits 24-31}
                  LGDT    [DS: OFFSET TmpGDT]  {Load GDTR}
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
  If Not XMSManager Then Exit; {v1.27}
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


{Make cleanup safe when both MyExitProc and the chained XMS exit handler
  call it.  FPC does not necessarily chain ExitProc exactly like Borland.}
XMSManager := False;
XMSHnd := 0;
XMSPos := 0;
XMSLeft := 0;
End;

Procedure XMSExitProc;
Begin
  CloseXMS;
  ExitProc := Nil;
End;

Function A20NotOn : Boolean;
Assembler;
Asm
PUSH  DS
MOV   AX,0
MOV   DS,AX
DEC   AX
MOV   ES,AX
CLI
MOV   AL,[DS: 0]
              MOV   BL,[ES: 10H]
                            MOV   AH,AL
                            XOR   AL,55H
                            MOV   [ES: 10H],AL
                                       CMP   [DS: 0],AL
                                                  MOV   [DS: 0],AH
                                                             MOV   [ES: 10H],BL
                                                                        STI
                                                                        POP   DS
                                                                        MOV   AL
                                                                        ,0
                                                                        JNZ   @@
                                                                        1
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
  XMSManager := False; {v1.27}
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
XMSManager := True; {v1.27}
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
If XMSPos <> 0 Then
  XMSLeft := LongInt( BSize ) shl 10;
Goto XMMDone;
NoXMM:
{XMS manager not found, need to enable A20 & figure out XMS size ourselves}
       Attempt := 0;
While A20NotOn And ( Attempt < 3 ) Do
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
If A20NotOn Then
  Begin
    Asm CLI
  End;
Port[ $64 ] := $D0;
Repeat
Until ( Port[ $64 ] And 1 ) <> 0;
X := Port[ $60 ];
Port[ $64 ] := $D1;
Repeat
Until ( Port[ $64 ] And 2 ) = 0;
Port[ $60 ] := X Or 2;
Asm STI
End;
Delay( 10 ); {wait a while before testing}
End;
Inc( Attempt );
End;
XMSLeft := -2; {No XMS}
XMMDone:
         If A20NotOn Then XMSLeft := -1;
End;

Procedure AllocHimem;

Var 
  Done : Boolean;

Begin
  If XMSLeft <> -2 Then Exit;
{Scan for available memory. NOTE: It is assumed that none of this memory    }
{is in use and that there is a gap between system memory & option ROM/RAM !!}
  XMSPos := $100000;
  XMSLeft := 0;
  Repeat
    Done := True;
    FOMemB( XMSPos, $55 );
    If FIMemB( XMSPos ) = $55 Then
      Begin
        FOMemB( XMSPos, $AA );
        If FIMemB( XMSPos ) = $AA Then
          Begin
            FOMemB( XMSPos + 4095, $55 );
            If FIMemB( XMSPos + 4095 ) = $55 Then
              Begin
                FOMemB( XMSPos + 4095, $AA );
                If FIMemB( XMSPos + 4095 ) = $AA Then
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
  Size := ( Size + 3 ) And $FFFFFFFC; {DWORD ALIGN}
  Asm
  MOV   AH,48H     {Alloc dos mem}
  MOV   BX,0FFFFH  {Get largest free block}
  INT   21H
  MOV   Block,BX
End;
If Size <= ( LongInt( Block ) * 16 ) Then
  Begin
    Block := ( Size + 15 ) shr 4;
    Asm
    MOV      AH,48H
    MOV      BX,Block
    INT      21H
    MOV      Block,AX
  End;
AllocLinBlock := LongInt( Block ) * 16;
End
Else
  If Size <= XMSLeft Then
    Begin
      XMSLeft := XMSLeft - Size;
      AllocLinBlock := XMSPos;
      XMSPos := XMSPos + Size;
    End
Else AllocLinBlock := 0;
End;

Procedure MoveLinBlockD( Src, Dest, Size : LongInt );
Assembler;
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

Procedure MoveLinBlockB( Src, Dest, Size : LongInt );
Assembler;
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

Procedure MoveLinBlockW( Src, Dest, Size : LongInt );
Assembler;
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

Procedure FillLinBlockD( Dest, Size : LongInt; Data : Byte );
Assembler;
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

Function CompLinBlocks( Block1, Block2, Size : LongInt ) : Boolean;
Assembler;
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
                     Proc : ProcType; Nxt : PMenuItem ) : PMenuItem;

Var 
  This : PMenuItem;

Begin
  New( This );
  With This^ Do
    Begin
      X := ( 78 - Length( Txt ) ) shr 1;
      Y := RY;
      Descr := ' ' + Txt + ' ';
      Help := Hlp;
      Flags := Flg;
      Action.P := Proc;
      Next := Nxt;
      Prev := Nil;
    End;
  If Nxt <> Nil Then Nxt^.Prev := This;
  AddMenuItem := This;
End;

Function AddSubMenuItem( Txt, Hlp : String; RY, Flg : Byte;
                        Sub : PMenuItem; Nxt : PMenuItem ) : PMenuItem;

Var 
  This : PMenuItem;

Begin
  New( This );
  With This^ Do
    Begin
      X := ( 78 - Length( Txt ) ) shr 1;
      Y := RY;
      Descr := ' ' + Txt + ' ';
      Help := Hlp;
      Flags := Flg;
      Action.M := Sub;
      Next := Nxt;
      Prev := Nil;
    End;
  If Nxt <> Nil Then Nxt^.Prev := This;
  AddSubMenuItem := This;
End;

Procedure CursorOn;
Assembler;
Asm
MOV AH,01H
MOV CX,0607H
INT 10H
End;

Procedure CursorOff;
Assembler;
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
  While ( Item <> Nil ) And
        ( Item^.Y <> YVal ) Do
    Item := Item^.Next;
  If Item <> Nil Then
    With Item^ Do
      Begin
        If Act Then Flags := Flags Or 1
        Else Flags := Flags And Not 1;
        If CurMenu = Menu Then
          Begin
            GotoXY( X, Y + MTop );
            If Act Then Text_Color( 15 )
            Else Text_Color( 7 );
            Text_Background( 0 );
            Write( Descr );
          End;
      End;
End;

Procedure ExecuteMenuAction( Item : PMenuItem );

Var 
  P : ProcType;
Begin
  P := Item^.Action.P;
  P;
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
  While CurItem <> Nil Do
    With CurItem^ Do
      Begin
        GotoXY( X, Y + MTop );
        If ( Flags And 1 ) <> 0 Then Text_Color( 15 )
        Else Text_Color( 7 );
        Write( Descr );

        CurItem := Next;
      End;
  CurItem := Nil;
  NewItem := Menu;
  Done := False;
  Repeat
    If CurItem <> NewItem Then
      Begin
        If CurItem <> Nil Then
          With CurItem^ Do
            Begin
              GotoXY( X, Y + MTop );
              If ( Flags And 1 ) <> 0 Then Text_Color( White )
              Else Text_Color( LightGray );
              Text_Background( Black );
              Write( Descr );
            End;
        With NewItem^ Do
          Begin
            GotoXY( X, Y + MTop );
            If ( Flags And 1 ) <> 0 Then Text_Color( White )
            Else Text_Color( LightGray );
            Text_Background( LightRed );
            Write( Descr );
            GotoXY( 1,25 ); {v1.23}
            If ( Flags And 1 ) <> 0 Then Text_Color( LightGreen )
            Else Text_Color( Green );
            Text_Background( Black );
            ClrEol; {v1.23}
            Write( Help ); {v1.23}
            GotoXY( X, Y + MTop ); {v1.23}
          End;
        CurItem := NewItem;
      End;
    A := _ReadKey; {v1.23}
    Case A Of 
      #27 : Done := True;
      #13 : If CurItem^.Action.T = Nil Then Done := True
            Else If ( CurItem^.Flags And 1 ) <> 0 Then
                   Begin
                     If ( CurItem^.Flags And 2 ) = 0 Then
                       Begin
                         Text_Color( 7 );
                         Text_Background( 0 );
                         CursorOn;
                         ExecuteMenuAction( CurItem );
                         CursorOff;
                         NewItem := CurItem;
                         CurItem := Nil;
                       End
                     Else
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
                         While CurItem <> Nil Do
                           With CurItem^ Do
                             Begin
                               GotoXY( X, Y + MTop );
                               If ( Flags And 1 ) <> 0 Then Text_Color( 15 )
                               Else Text_Color( 7 );
                               Write( Descr );
                               CurItem := Next;
                             End;
                         CurItem := Nil;
                         NewItem := SvItem;
                       End;
                   End;
      #0  :
            Begin
              A := _ReadKey; {v1.23}
              Case A Of 
                #80 : If CurItem^.Next <> Nil Then NewItem := CurItem^.Next;
                #72 : If CurItem^.Prev <> Nil Then NewItem := CurItem^.Prev;
                #71,
                #73 :
                      Begin {v1.22}
                        If CurItem^.Prev <> Nil Then NewItem := CurItem^.Prev;
                        While NewItem^.Prev <> Nil Do
                          NewItem := NewItem^.Prev;
                      End;
                #79,
                #81 :
                      Begin {v1.22}
                        If CurItem^.Next <> Nil Then NewItem := CurItem^.Next;
                        While NewItem^.Next <> Nil Do
                          NewItem := NewItem^.Next;
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
  GotoXY( 11, 19 );
  ClrEol;
  GotoXY( 11, 20 );
  ClrEol;
  GotoXY( 11, 21 );
  ClrEol;
End;

Procedure WrtProgressBar( Msg : String );
Begin
  ClearProgressBar;
  GotoXY( 11, 20 );
  ClrEol;
  Text_Color(yellow);
  GotoXY( 33, 19 );
  write(

'��������������������������������ͻ'
  );
  GotoXY( 11, 20 );
  Write( Msg );
  GotoXY( 33, 20 );
  Write( '�');
  Text_Color(4);
  Write(

'��������������������������������'
  );
  Text_Color(yellow);
  Write('�' );
  GotoXY( 33, 21 );
  write(

'��������������������������������ͼ'
  );
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
Function InitOldWait : Word;
Assembler;
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
Procedure OldWait( MiSec : LongInt );
Assembler;
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

Function zero2str(s, o : word) : string;

Var outstr : string;
  i,c : byte;
Begin
  i := 0;
  c := 0;
  outstr[0] := #0;
  While (mem[s:o+i]<>0) And (i<255) Do
    Begin
      inc(c);
      outstr[1+i] := char(mem[s:o+i]);
      inc(i);
    End;
  outstr[0] := #0;
  zero2str := outstr;
End;

Function Time: String; {v1.23}

Var Hour,Min,Sec,Sec100: Word;
  S,S1: String;
Begin
  GetTime(Hour,Min,Sec,Sec100);
  Str(Hour,S);
  If Length(S)<2 Then S := '0'+S;
  S1 := S;
  Str(Min,S);
  If Length(S)<2 Then S := '0'+S;
  S1 := S1+':'+S;
  Str(Sec,S);
  If Length(S)<2 Then S := '0'+S;
  S1 := S1+':'+S;
  Str(Sec100,S);
  If Length(S)<2 Then S := '0'+S;
  S1 := S1+'.'+S;
  Time := S1;
End;

Function _Str(I:LongInt): String;

Var S: String;
Begin
  Str(I,S);
  _Str := S;
End;

Procedure LogWrite(S:String); {v1.23}

Var F : Text;

Procedure LogDisable;
Begin
  WriteLn;
  WriteLn('Warning: unable to write to log file, logging disabled.');
  Logging := False;
End;

Begin
  If Logging Then
    Begin
      Assign( F, 'UNIFLASH.LOG');
      Append( F );
      If IOResult=2 Then
        Begin
          ReWrite( F );
          If IOResult<>0 Then
            Begin
              LogDisable;
              Exit;
            End;
        End;
      WriteLn( F, Time,': ',S);
      Close(F);
      If IOResult<>0 Then
        Begin
          LogDisable;
          Exit;
        End;
    End;
End;

Procedure LogStart; {v1.23}

Var S: String;
  A: Byte;
Begin
  S := '';
  For A:=0 To ParamCount Do
    S := S+ParamStr(A)+' ';
  Delete(S,Length(S),1);
  LogWrite('UniFlash v'+Version+' started: '+S);
End;

Procedure LogEnd; {v1.23}

Var F : Text;
  A : Byte;
Begin
  If Logging Then
    Begin
      Assign( F, 'UNIFLASH.LOG');
      Append( F );
      For A := 1 To 78 Do
        Write(F, '-');
      WriteLn(F);
      Close(F);
    End;
End;

Procedure Text_Color(Color:Byte); {v1.27}
Begin
  If Not Mono Then TextColor(Color);
End;

Procedure Text_Background(Color:Byte); {v1.27}
Begin
  If Not Mono Then TextBackground(Color)
  Else
    If Color=Black Then
      Begin
        TextBackground(Black);
        TextColor(LightGray);
      End
  Else
    Begin
      TextBackground(LightGray);
      TextColor(Black);
    End;
End;

Procedure ClrKbBuf; {v1.23}
Begin
  MemW[$40: $1A] := MemW[$40:$80]; {Next char := Buffer beginning}
  MemW[$40: $1C] := MemW[$40:$80]; {First free char := Buffer beginning}
  Mem[$40: $17] := 0; {Clear keyboard flags} {v1.27}
  Mem[$40: $18] := 0;
End;

Procedure InitKB; {v1.38}
Begin
  Port[$60] := $EE;
End;

Function _ReadKey: Char; {v1.23}

Var A,Z: Byte;

Const KeyTable: string[127] = #27'1234567890-='#8#9'qwertyuiop[]'#13#0
                              'asdfghjkl;''`'#0'\zxcvbnm,./'#0'*'#0' '#0;
  KeyTableShift: string[127] = #27'!@#$%^&*()_+'#8#9'QWERTYUIOP{}'#13#0
                               'ASDFGHJKL:"~'#0'|ZXCVBNM<>?'#0#0#0' '#0;
Begin
  ClrKbBuf;
  If Ext<>#0 Then
    Begin
      _ReadKey := Ext;
      Ext := #0;
      Exit;
    End;
  A := Port[$60];
  If (History[1]<>History[2]) And (Char(A)=History[2]) Then
    Begin
      For Z:=1 To 250 Do
        Begin
          Delay(1);
          If A<>Port[$60] Then Break;
        End;
    End
  Else Delay(50);
  Repeat
    A := Port[$60];
    If (A=42) Or (A=54) Then
      Begin
        Shift := True;
        Continue;
      End;
    If (A=170) Or (A=182) Then
      Begin
        Shift := False;
        Continue;
      End;
    If (A>127) Then History[2] := #0;
    If (A>58) And (A<128) Then
      Begin
        Ext := Char(A);
        _ReadKey := #0;
        History[1] := History[2];
        History[2] := Char(A);
        Exit;
      End;
  Until (A<128) And (A>0) And (KeyTable[A]<>#0);
  If Shift Then _ReadKey := KeyTableShift[A]
  Else _ReadKey := KeyTable[A];
  History[1] := History[2];
  History[2] := Char(A);
End;

Function strcomp(s1,s2 : String; b : byte) : boolean;

Var i : byte;
Begin
  strcomp := true;
  For i:=1 To b Do
    If s1[i]<>s2[i] Then strcomp := false;
End;

Procedure _Delay; {v1.22}
Begin
  Delay(100);
End;

Procedure InitTSC;
assembler; {Requires Pentium or newer CPU} {v1.22}
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
End;

{$F+}
Procedure TSCWait(MicroSec:LongInt);
assembler; {v1.22}
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
@: dw   310fh                {RDTSC}
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
End;
{$F-}

Function TSCPresent: Boolean;
assembler; {v1.22}
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
             popf                      {POPFD}
             {Restore EFLAGS register}
End;

Function NoVideo: Boolean;
assembler; {v1.28}
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
End;

Procedure FInput(Var Name:String;DefaultName:String;MaxLen:Byte); {v1.28}

Var S: String;
  Ch: Char;
  Default: Boolean;
  A,Pos,StartX: Byte;
Begin
  ClrKbBuf;
  S := DefaultName;
  Default := DefaultName<>'';
  Pos := Length(S)+1;
  StartX := WhereX;
  Write(S);
  Repeat
    Ch := _ReadKey;
    If Ch=#27 Then
      Begin
        Name := '';
        Exit;
      End;
    If Ch=#13 Then
      Begin
        If (S='') And (DefaultName='') Then
          Begin
            S := BrowseFile;
            Write(S);
            Pos := Length(S)+1;
          End
        Else Break;
      End;
    If Ch=#8 Then
      Begin
        If (Length(S)>0) And (Pos>1) Then
          Begin
            Dec(Pos);
            Delete(S,Pos,1);
            Write(#8' '#8);
            For A:=Pos To Length(S) Do
              Write(S[A]);
            Write(' ');
            GotoXY(StartX+Pos-1,WhereY);
            Default := False;
          End;
        Continue;
      End;
    If Ch=#0 Then
      Begin
        Ch := _ReadKey;
        Case Ch Of 
          #75: If Pos>1 Then Dec(Pos);
          #77: If Pos<=Length(S) Then Inc(Pos);
          #71: Pos := 1;
          #79: Pos := Length(S)+1;
          #83:
               Begin
                 If (Length(S)>0) And (Pos<=Length(S)) Then
                   Begin
                     Delete(S,Pos,1);
                     Write(' '#8);
                     For A:=Pos To Length(S) Do
                       Write(S[A]);
                     Write(' ');
                     GotoXY(StartX+Pos-1,WhereY);
                     Default := False;
                   End;
                 Continue;
               End;
        End;
        If (Ch=#75) Or (Ch=#77) Or (Ch=#71) Or (Ch=#79) Then
          Begin
            GotoXY(StartX+Pos-1,WhereY);
            Default := False;
          End;
        Continue;
      End;
    If (Length(S)>=MaxLen) Or (Ord(Ch)<32) Then Continue;
    If Default Then
      Begin
        S := '';
        For A:=1 To Length(DefaultName) Do
          Write(#8' '#8);
        Pos := 1;
        Default := False;
      End;
    Insert(Ch,S,Pos);
    For A:=Pos To Length(S) Do
      Write(S[A]);
    Inc(Pos);
    GotoXY(StartX+Pos-1,WhereY);
  Until False;
  Name := S;
End;

Function UpCaseStr(S:String): String; {v1.28}

Var S0: String;
  A: Byte;
Begin
  S0 := '';
  For A:=1 To Length(S) Do
    S0 := S0+UpCase(S[A]);
  UpCaseStr := S0;
End;

Function LowCaseStr(S:String): String; {v1.28}

Var S0: String;
  A: Byte;
Begin
  S0 := '';
  For A:=1 To Length(S) Do
    If (S[A]>='A') And (S[A]<='Z') Then S0 := S0+Chr(Ord(S[A])+32)
    Else S0 := S0+S[A];
  LowCaseStr := S0;
End;

Function Zero2Name(S:String): String; {v1.28}

Var S0: String;
Begin
  If (Pos(#0,S)<>0) And (S[1]<>'.') Then S[Pos(#0,S)] := '.';
  While Pos(#0,S)<>0 Do
    Delete(S,Pos(#0,S),1);
  Zero2Name := S;
End;

Function Min(A,B:LongInt): LongInt; {v1.28}
Begin
  If A<B Then Min := A
  Else Min := B;
End;

Function BrowseFile: String; {v1.28}

Var SR: SearchRec;
  A,Count,CurPos,PagePos,OldPos,StackPos,FreeSpace: Word;
  P: Pointer;
  PP: LongInt absolute P;
  Ch: Char;
  Stack: array[1..256] Of Word;
  X,Y,DrivePos: Byte;
  Path,Drives: String;

Const PageSize = 13;

Type FileName = array[1..12] Of Char;

Procedure StoreName(Name:String;Position:Word;Dir:Boolean);

Var S: String;
  A: Byte;
Begin
  If Name='..' Then Name := #1+'..'#0#0#0#0#0#0#0#0#0
  Else
    Begin
      If Dir Then S := #1#0#0#0#0#0#0#0#0#0#0#0
      Else S := #255#0#0#0#0#0#0#0#0#0#0#0;
      A := Pos('.',Name);
      If A=0 Then Move(Name[1],S[2],Length(Name))
      Else
        Begin
          Move(Name[1],S[2],A-1);
          Move(Name[A+1],S[10],Length(Name)-A);
        End;
      Name := S;
    End;
  Move(Name[1],Pointer(PP+Position*SizeOf(FileName))^,Length(Name));
End;

Function GetName(Pos:Word;Full:Boolean): String;

Var S: String;
Begin
  S := #0#0#0#0#0#0#0#0#0#0#0#0;
  If Full Then Move(Pointer(PP+Pos*SizeOf(FileName))^,S[1],12)
  Else Move(Pointer(PP+Pos*SizeOf(FileName)+1)^,S[1],11);
  If S[9]<>#0 Then S := Copy(S,1,8)+#0+Copy(S,9,Length(S)-9);
  GetName := S;
End;

Procedure DobosSort;

Var Step,I: LongInt;
  OK: Boolean;
  S: String;
  A: Byte;

Procedure ExChange(X,Y:Word);

Var A: FileName;
Begin
  Move(Pointer(PP+X*SizeOf(FileName))^,A,SizeOf(A));
  Move(Pointer(PP+Y*SizeOf(FileName))^,Pointer(PP+X*SizeOf(FileName))^,SizeOf(

                                                                        FileName
  ));
  Move(A,Pointer(PP+Y*SizeOf(FileName))^,SizeOf(FileName));
End;

Begin
  Step := Count;
  If Zero2Name(GetName(1,False))='..' Then A := 2
  Else A := 1;
  Repeat
    OK := True;
    Step := (Step*4) Div 5;
    If Step<1 Then Step := 1;
    For I:=Step+A To Count Do
      If (GetName(I,True)<GetName(I-Step,True)) Then
        Begin
          ExChange(I,I-Step);
          OK := False;
        End;
  Until (OK) And (Step=1);
End;

Procedure DispFile(Name:String;Active,NextLine:Boolean);

Var A: Byte;
Begin
  If Active Then Text_Background(Blue)
  Else Text_Background(Black);
  Write(' '+Name);
  For A:=1 To 13-Length(Name) Do
    Write(' ');
  If NextLine Then WriteLn;
  Text_Background(Black);
End;

Procedure ReadDir;
Begin
  FindFirst('*.*',AnyFile And Not VolumeID,SR);
  A := 1;
  While (DOSError=0) And (A<FreeSpace Div 12) Do
    Begin
      If SR.Name<>'.' Then
        Begin
          If SR.Attr And Directory<>Directory Then StoreName(LowCaseStr(SR.Name)
            ,A,False)
          Else StoreName(UpCaseStr(SR.Name),A,True);
          Inc(A);
        End;
      FindNext(SR);
    End;
  Count := A-1;
  CurPos := 1;
  PagePos := 1;
  OldPos := 1;
  DobosSort;
End;

Function GetDrive: Byte;
assembler;
asm mov ah,$19;
int 21h;
End;

Procedure SetDrive(A:Byte);
assembler;
asm mov ah,$0E;
mov dl,a;
int $21;
End;

Function ValidDrive(Dr:Char): Boolean;

Var S,S1: string[40];
  B,B1: Byte;
  R: Registers;
  NumFloppy: Byte;
Begin
  ValidDrive := False;
  If Dr<'A' Then Exit;
  If Dr='A' Then
    Begin
      R.AH := $15;
      R.DL := 0;
      Intr($13,R);
      If ((R.Flags) And fCarry=fCarry) Or (R.AH=0) Then ValidDrive := False
      Else ValidDrive := True;
      Exit;
    End;
  If Dr='B' Then
    Begin
      R.AH := $15;
      R.DL := 1;
      Intr($13,R);
      If ((R.Flags) And fCarry=fCarry) Or (R.AH=0) Then ValidDrive := False
      Else ValidDrive := True;
      Exit;
    End;
  B := GetDrive;
  SetDrive(Byte(Dr)-65);
  B1 := GetDrive;
  SetDrive(B);
  If Byte(Dr)-65<>B1 Then Exit;
  S := Dr+':\'#0;
  R.ax := $2900;
  R.ds := Seg(S);
  R.si := Ofs(S[1]);
  R.es := Seg(S1);
  R.di := Ofs(S1);
  Intr($21,R);
  If R.ax<>$FF Then ValidDrive := True
  Else ValidDrive := False;
End;

Procedure ChangeDrive(Drive:Char);

Var OldDir: String;
  A: Byte;
Begin
  GetDir(0,OldDir);
  ChDir(Drive+':\');
  If IOResult<>0 Then
    Begin
      ChDir(OldDir);
      Exit;
    End;
  ReadDir;
  Window(2,9,17,22);
  Text_Background(Black);
  ClrScr;
  Window(2,9,17,23); {v1.31}
  For A:=PagePos To Min(PagePos+PageSize,Count) Do
    DispFile(GetName(A,False),A = CurPos,True);
  Window(25,22,80,22);
End;

Begin
  FreeSpace := Min(MaxAvail,65520);
  GetMem(P,FreeSpace);
  StackPos := 1;

  ReadDir;

  Text_Background(Black);
  X := WhereX;
  Y := WhereY;
  CursorOff;
  Window(2,9,17,22);
  ClrScr;
  Window(2,9,17,23);
  For A:=PagePos To Min(PagePos+PageSize,Count) Do
    DispFile(GetName(A,False),A = CurPos,True);

  Repeat
    Ch := _ReadKey;
    If Ch=#27 Then
      Begin
        Window(2,9,17,22);
        ClrScr;
        BrowseFile := '';
        Break;
      End;
    If Ch=#13 Then
      Begin
        If Copy(GetName(CurPos,True),1,1)=#255 Then
          Begin
            Window(2,9,17,22);
            ClrScr;
            BrowseFile := Zero2Name(GetName(CurPos,False));
            Break;
          End;
        ChDir(Zero2Name(GetName(CurPos,False)));
        If Zero2Name(GetName(CurPos,False))='..' Then
          Begin
            ReadDir;
            If StackPos>1 Then
              Begin
                Dec(StackPos);
                PagePos := Stack[StackPos];
                Dec(StackPos);
                CurPos := Stack[StackPos];
              End
            Else
              Begin
                PagePos := 1;
                CurPos := 1;
              End;
          End
        Else
          Begin
            Stack[StackPos] := CurPos;
            Inc(StackPos);
            Stack[StackPos] := PagePos;
            Inc(StackPos);
            ReadDir;
          End;
        Window(2,9,17,22);
        ClrScr;
        Window(2,9,17,23);
        OldPos := CurPos;
        For A:=PagePos To Min(PagePos+PageSize,Count) Do
          DispFile(GetName(A,False),A = CurPos,True);
      End;
    If Ch=#9 Then
      Begin
        Window(25,22,80,22);
        GetDir(0,Path);
        Drives := '';
        For Ch:='A' To 'Z' Do
          If ValidDrive(Ch) Then
            Begin
              Drives := Drives+Ch;
              If UpCase(Path[1])=Ch Then DrivePos := Length(Drives);
            End;
        Repeat
          GotoXY(1,1);
          For A:=1 To Length(Drives) Do
            Begin
              If A=DrivePos Then Text_Background(Green)
              Else Text_Background(Black);
              Write(' '+Drives[A]+' ');
            End;
          Ch := _ReadKey;
          Case Ch Of 
            #0: Case _ReadKey Of 
                  'K': If DrivePos>1 Then Dec(DrivePos);
                  'M': If DrivePos<Length(Drives) Then Inc(DrivePos);
                End;
            #27: Break;
            #9,#13:
                    Begin
                      ChangeDrive(Drives[DrivePos]);
                      Break;
                    End;
            'a'..'z','A'..'Z':
                               Begin
                                 ChangeDrive(UpCase(Ch));
                                 Break;
                               End;
          End;
        Until False;
        GotoXY(1,1);
        Text_Background(Black);
        ClrEol;
        Window(2,9,17,23);
      End;
    If Ch=#0 Then
      Begin
        OldPos := CurPos;
        Case _ReadKey Of 
          'I': If CurPos<=PageSize Then CurPos := 1
               Else CurPos := CurPos-PageSize;
          'Q': If CurPos>Integer(Count)-PageSize Then CurPos := Count
               Else CurPos := CurPos+PageSize;
          'H': If CurPos>1 Then Dec(CurPos);
          'P': If CurPos<Count Then Inc(CurPos);
          'G': CurPos := 1;
          'O': CurPos := Count;
        End;
      End;
    If (Count=0) Or (CurPos=OldPos) Then Continue;
    If (CurPos<=PagePos+PageSize) And (CurPos>=PagePos) Then
      Begin
        GotoXY(1,OldPos-PagePos+1);
        DispFile(GetName(OldPos,False),False,False);
        GotoXY(1,WhereY+(Integer(CurPos)-OldPos));
        DispFile(GetName(CurPos,False),True,False);
      End
    Else
      Begin
        If CurPos>PagePos+PageSize Then Inc(PagePos);
        If CurPos>PagePos+PageSize Then
          Begin
            While CurPos>PagePos+PageSize Do
              PagePos := PagePos+PageSize;
            Dec(PagePos);
          End;
        If CurPos<PagePos Then Dec(PagePos);
        If CurPos<PagePos Then
          Begin
            If PagePos>PageSize Then
              Begin
                While CurPos<PagePos Do
                  If PagePos>PageSize Then PagePos := PagePos-PageSize
                  Else PagePos := 0;
                Inc(PagePos);
              End
            Else PagePos := 1;
          End;
        If Count-PagePos<PageSize Then PagePos := Count-PageSize;
        Window(2,9,17,22);
        ClrScr;
        Window(2,9,17,23);
        For A:=PagePos To Min(PagePos+PageSize,Count) Do
          DispFile(GetName(A,False),A = CurPos,True);
      End;
  Until False;

  FreeMem(P,FreeSpace);
  Window(1,1,80,25);
  GotoXY(X,Y);
  CursorOn;
  ClrKbBuf;
End;

Function IntToStr(I:LongInt): String; {v1.28}

Var S: String;
Begin
  Str(I,S);
  IntToStr := S;
End;

Begin
  If Not Windows And Not EMM386 And TSCPresent Then {v1.22}
    Begin
      InitTSC;
      uSec := TSC Div 100000;
      Wait := @TSCWait;
    End
  Else
    Begin
      MicroSec := 312785 Div InitOldWait;
      Wait := @OldWait;
    End;
End.
