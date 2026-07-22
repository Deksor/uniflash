
Unit Flash;

Interface

Uses Tools; {v1.29}

Type 
  Fl_Erase   = Procedure ( SAddr : LongInt );
  far;
  Fl_Program = Procedure ( Pos, Data : LongInt );
  far;
  ChipInfo   = Record
    Manuf,
    Name    : ^String;
    Erase   : Fl_Erase;
    Progr   : Fl_Program;
    Sectors : ARRAY[ 0 .. 4, 0 .. 1 ] Of Word;
    Size    : Word;
    PgSize  : Word;
    Flags   : Byte;
{              Count   : Byte;}
  End;
  PChipInfo  = ^ChipInfo;
  Fl_IdChip  = Function ( DevID : Byte; Var CInfo : ChipInfo ) : Boolean;
  far;
  PFl_Manuf  = ^Fl_Manuf;
  Fl_Manuf   = Record
    IdChip : Fl_IdChip;

    Next   : PFl_Manuf;
    Manuf  : Byte;
  End;

Var 
  Man1, Dev1,
  Man2, Dev2 : Byte;
  CurCInfo   : ChipInfo;
  ROMBase    : LongInt;

Procedure SetBank_FinALi(Bank:Byte); {v1.28}
Function  FIMemB_Flash(Addr:LongInt): Byte; {v1.29}
Function  FIMemB_Flash_FinALi(Addr:LongInt): Byte; {v1.29}
Function  FIMemB_Flash_Low(Addr:LongInt): Byte; {v1.31}
Function  FIMemB_Flash_ALiGPO(Addr:LongInt): Byte; {v1.34}
Procedure FOMemB_Flash(Addr:LongInt;Data:Byte); {v1.29}
Procedure FOMemB_Flash_FinALi(Addr:LongInt;Data:Byte); {v1.29}
Procedure FOMemB_Flash_ALiGPO(Addr:LongInt;Data:Byte); {v1.34}
Procedure MoveLinBlock_From_Flash_D(Src,Dest,Size:LongInt); {v1.29}
Procedure MoveLinBlock_From_Flash_D_FinALi(Src,Dest,Size:LongInt); {v1.29}
Procedure MoveLinBlock_From_Flash_D_Low(Src,Dest,Size:LongInt); {v1.31}
Procedure MoveLinBlock_From_Flash_D_ALiGPO(Src,Dest,Size:LongInt); {v1.34}
Procedure MoveLinBlock_To_Flash_B(Src,Dest,Size:LongInt); {v1.29}
Procedure MoveLinBlock_To_Flash_B_FinALi(Src,Dest,Size:LongInt); {v1.29}
Procedure MoveLinBlock_To_Flash_B_ALiGPO(Src,Dest,Size:LongInt); {v1.34}
Function  CompLinBlocks_Flash(Block1,Block2,Size:LongInt): Boolean; {v1.29}
Function  CompLinBlocks_Flash_FinALi(Block1,Block2,Size:LongInt): Boolean;
{v1.29}
Function  CompLinBlocks_Flash_Low(Block1,Block2,Size:LongInt): Boolean; {v1.31}
Function  CompLinBlocks_Flash_ALiGPO(Block1,Block2,Size:LongInt): Boolean;
{v1.34}
Procedure FlashCmd( Cmd : Byte );
Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
Procedure SetChipErase( Var EraseProc : Fl_Erase; ProcAddr : Fl_Erase );
Procedure SetChipProgram( Var ProgramProc : Fl_Program; ProcAddr : Fl_Program );
Function  FlashDetect : PChipInfo;
Procedure FlashProgram( Pos, Data : LongInt );
Procedure FlashErase( Pos : LongInt );

Const 
  On         = True;
  Off        = False;
  FlashError : Word = 0;
  ManuRoot   : PFl_Manuf = Nil;
  ManuTail   : PFl_Manuf = Nil;
  CurManuf   : PFl_Manuf = Nil;
  Flash_Read : Function (Address:LongInt): Byte = @FIMemB_Flash; {v1.29}
  Flash_Write: Procedure (Address:LongInt;Data:Byte) = @FOMemB_Flash; {v1.29}
  Flash_ReadBlock: Procedure (FlashAddr,MemAddr,Size:LongInt) = @
                                                       MoveLinBlock_From_Flash_D
  ; {v1.29}
  Flash_WriteBlock: Procedure (FlashAddr,MemAddr,Size:LongInt) = @
                                                         MoveLinBlock_To_Flash_B
  ; {v1.29}
  Flash_Compare: Function (MemAddr,FlashAddr,Size:LongInt): Boolean = @
                                                             CompLinBlocks_Flash
  ; {v1.29}
  ShadowDisable: Procedure  = nil; {v1.31}
  ShadowRestore: Procedure  = nil; {v1.31}
  FirstBank  : Boolean = True;  {v1.28}

Implementation

Uses Crt, PCI, CT_Flash;

Procedure SetBank_FinALi(Bank:Byte); {for ALi FinALi 486} {v1.28}

Var A: Byte;
Begin
  If FirstBank=(Bank=1) Then Exit;
  Port[$22] := $03;
  Port[$23] := $C5;

  Port[$22] := $2B;
  A := Port[$23];
  Port[$22] := $2B;
  If Bank=1 Then Port[$23] := A Or $20
  Else Port[$23] := A And $DF;

  Port[$22] := $03;
  Port[$23] := $00;
  FirstBank := Bank=1;
End;

Procedure SetBank_ALiGPO(Bank:Byte); {for ALi M1533/43} {v1.34}

Var A: Byte;
Begin
  If FirstBank=(Bank=1) Then Exit;
  If Bank=1 Then SetPCIRegD($00,PMUPos shr 3,PMUPos And $7,$C0,
                            GetPCIRegD($00,PMUPos shr 3,PMUPos And $7,$C0) and $
    FFF7FFFF)
  Else SetPCIRegD($00,PMUPos shr 3,PMUPos And $7,$C0,
                  GetPCIRegD($00,PMUPos shr 3,PMUPos And $7,$C0) or $80000);
  FirstBank := Bank=1;
End;

Function FIMemB_Flash(Addr:LongInt): Byte; {v1.29}
Begin
  FIMemB_Flash := FIMemB(ROMBase+Addr);
End;

Function FIMemB_Flash_FinALi(Addr:LongInt): Byte; {v1.29}
Begin
  If Addr<$10000 Then SetBank_FinALi(1)
  Else SetBank_FinALi(2);
  FIMemB_Flash_FinALi := FIMemB(ROMBase+Addr-Byte(Addr>=$10000)*$10000);
End;

Function FIMemB_Flash_Low(Addr:LongInt): Byte; {v1.31}
Begin
  asm pushf;
  cli
End;
ShadowDisable;
FIMemB_Flash_Low := FIMemB(ROMBase+Addr);
ShadowRestore;
asm popf
End;
End;

Function FIMemB_Flash_ALiGPO(Addr:LongInt): Byte; {v1.34}
Begin
  If Addr<$20000 Then SetBank_ALiGPO(1)
  Else SetBank_ALiGPO(2);
  FIMemB_Flash_ALiGPO := FIMemB(ROMBase+Addr-Byte(Addr>=$20000)*$20000);
End;

Procedure FOMemB_Flash(Addr:LongInt;Data:Byte); {v1.29}
Begin
  FOMemB(ROMBase+Addr,Data);
End;

Procedure FOMemB_Flash_FinALi(Addr:LongInt;Data:Byte); {v1.29}
Begin
  If Addr<$10000 Then SetBank_FinALi(1)
  Else SetBank_FinALi(2);
  FOMemB($F0000+Addr-Byte(Addr>=$10000)*$10000,Data);
End;

Procedure FOMemB_Flash_ALiGPO(Addr:LongInt;Data:Byte); {v1.34}
Begin
  If Addr<$20000 Then SetBank_ALiGPO(1)
  Else SetBank_ALiGPO(2);
  FOMemB(ROMBase+Addr-Byte(Addr>=$20000)*$20000,Data);
End;

Procedure MoveLinBlock_From_Flash_D(Src,Dest,Size:LongInt); {v1.29}
Begin
  MoveLinBlockD(ROMBase+Src,Dest,Size);
End;

Procedure MoveLinBlock_From_Flash_D_FinALi(Src,Dest,Size:LongInt); {v1.29}

Var FirstBlock: LongInt;
Begin
  FirstBlock := 0;
  If Src<$10000 Then
    Begin
      SetBank_FinALi(1);
      If Size+Src>=$10000 Then FirstBlock := $10000-Src
      Else FirstBlock := Size;
      MoveLinBlockD(ROMBase+Src,Dest,FirstBlock);
    End;
  If Src+Size>=$10000 Then
    Begin
      SetBank_FinALi(2);
      If Src<$10000 Then MoveLinBlockD(ROMBase,Dest+FirstBlock,Size-FirstBlock)
      Else MoveLinBlockD(ROMBase+Src-$10000,Dest+FirstBlock,Size);
    End;
End;

Procedure MoveLinBlock_From_Flash_D_Low(Src,Dest,Size:LongInt); {v1.31}
Begin
  asm pushf;
  cli
End;
ShadowDisable;
MoveLinBlockD(ROMBase+Src,Dest,Size);
ShadowRestore;
asm popf
End;
End;

Procedure MoveLinBlock_From_Flash_D_ALiGPO(Src,Dest,Size:LongInt); {v1.34}

Var FirstBlock: LongInt;
Begin
  FirstBlock := 0;
  If Src<$20000 Then
    Begin
      SetBank_ALiGPO(1);
      If Size+Src>=$20000 Then FirstBlock := $20000-Src
      Else FirstBlock := Size;
      MoveLinBlockD(ROMBase+Src,Dest,FirstBlock);
    End;
  If Src+Size>=$20000 Then
    Begin
      SetBank_ALiGPO(2);
      If Src<$20000 Then MoveLinBlockD(ROMBase,Dest+FirstBlock,Size-FirstBlock)
      Else MoveLinBlockD(ROMBase+Src-$20000,Dest+FirstBlock,Size);
    End;
End;

Procedure MoveLinBlock_To_Flash_B(Src,Dest,Size:LongInt); {v1.29}
Begin
  MoveLinBlockB(Src,ROMBase+Dest,Size);
End;

Procedure MoveLinBlock_To_Flash_B_FinALi(Src,Dest,Size:LongInt); {v1.29}

Var FirstBlock: LongInt;
Begin
  FirstBlock := 0;
  If Dest<$10000 Then
    Begin
      SetBank_FinALi(1);
      If Size+Dest>=$10000 Then FirstBlock := $10000-Dest
      Else FirstBlock := Size;
      MoveLinBlockB(Src,$F0000+Dest,FirstBlock);
    End;
  If Dest+Size>=$10000 Then
    Begin
      SetBank_FinALi(2);
      If Dest<$10000 Then MoveLinBlockB(Src+FirstBlock,$F0000,Size-FirstBlock)
      Else MoveLinBlockD(Src,$F0000+Dest-$10000,Size);
    End;
End;

Procedure MoveLinBlock_To_Flash_B_ALiGPO(Src,Dest,Size:LongInt); {v1.34}

Var FirstBlock: LongInt;
Begin
  FirstBlock := 0;
  If Dest<$20000 Then
    Begin
      SetBank_ALiGPO(1);
      If Size+Dest>=$20000 Then FirstBlock := $20000-Dest
      Else FirstBlock := Size;
      MoveLinBlockB(Src,ROMBase+Dest,FirstBlock);
    End;
  If Dest+Size>=$20000 Then
    Begin
      SetBank_ALiGPO(2);
      If Dest<$20000 Then MoveLinBlockB(Src+FirstBlock,ROMBase,Size-FirstBlock)
      Else MoveLinBlockD(Src,ROMBase+Dest-$20000,Size);
    End;
End;

Function CompLinBlocks_Flash(Block1,Block2,Size:LongInt): Boolean; {v1.29}
Begin
  CompLinBlocks_Flash := CompLinBlocks(ROMBase+Block1,Block2,Size);
End;

Function CompLinBlocks_Flash_FinALi(Block1,Block2,Size:LongInt): Boolean;
{v1.29}

Var OK: Boolean;
  FirstBlock: LongInt;
Begin
  OK := True;
  FirstBlock := 0;
  If Block1<$10000 Then
    Begin
      SetBank_FinALi(1);
      If Size+Block1>=$10000 Then FirstBlock := $10000-Block1
      Else FirstBlock := Size;
      If Not CompLinBlocks(ROMBase+Block1,Block2,FirstBlock) Then OK := False;
    End;
  If (Block1+Size>=$10000) And OK Then
    Begin
      SetBank_FinALi(2);
      If Block1<$10000 Then
        Begin
          If Not CompLinBlocks(ROMBase,Block2+FirstBlock,Size-FirstBlock) Then
            OK := False;
        End
      Else If Not CompLinBlocks(ROMBase+Block1-$10000,Block2+FirstBlock,Size)
             Then OK := False;
    End;
  CompLinBlocks_Flash_FinALi := OK;
End;

Function CompLinBlocks_Flash_Low(Block1,Block2,Size:LongInt): Boolean; {v1.31}
Begin
  asm pushf;
  cli
End;
ShadowDisable;
CompLinBlocks_Flash_Low := CompLinBlocks(ROMBase+Block1,Block2,Size);
ShadowRestore;
asm popf
End;
End;

Function CompLinBlocks_Flash_ALiGPO(Block1,Block2,Size:LongInt): Boolean;
{v1.34}

Var OK: Boolean;
  FirstBlock: LongInt;
Begin
  OK := True;
  FirstBlock := 0;
  If Block1<$20000 Then
    Begin
      SetBank_ALiGPO(1);
      If Size+Block1>=$20000 Then FirstBlock := $20000-Block1
      Else FirstBlock := Size;
      If Not CompLinBlocks(ROMBase+Block1,Block2,FirstBlock) Then OK := False;
    End;
  If (Block1+Size>=$20000) And OK Then
    Begin
      SetBank_ALiGPO(2);
      If Block1<$20000 Then
        Begin
          If Not CompLinBlocks(ROMBase,Block2+FirstBlock,Size-FirstBlock) Then
            OK := False;
        End
      Else If Not CompLinBlocks(ROMBase+Block1-$20000,Block2+FirstBlock,Size)
             Then OK := False;
    End;
  CompLinBlocks_Flash_ALiGPO := OK;
End;

Procedure FlashCmd( Cmd : Byte );
Begin
  Flash_Write($5555,$AA); {v1.29}
  Flash_Write($2AAA,$55);
  Flash_Write($5555,Cmd);
End;

Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
Begin
  If ManuTail = Nil Then
    Begin
      New( ManuTail );
      ManuRoot := ManuTail;
    End
  Else
    Begin
      New( ManuTail^.Next );
      ManuTail := ManuTail^.Next;
    End;
  With ManuTail^ Do
    Begin
      IdChip := Id;
      Manuf := Manu;
      Next := Nil;
    End;
End;

Procedure SetChipErase( Var EraseProc : Fl_Erase; ProcAddr : Fl_Erase );
Begin
  Move( ProcAddr, EraseProc, SizeOf( EraseProc ) );
End;

Procedure SetChipProgram( Var ProgramProc : Fl_Program; ProcAddr : Fl_Program );
Begin
  Move( ProcAddr, ProgramProc, SizeOf( ProgramProc ) );
End;

Function ParityOdd( B : Byte ) : Boolean;
Assembler;
Asm
MOV AL,B
OR  AL,AL
JPE @@1
MOV AL,1
JMP @@2
@@1:
     MOV AL,0
     @@2:
End;

Function MatchIdChip(ManufNode: PFl_Manuf; ExpectedMan, DevId: Byte; Var CInfo:
                     ChipInfo): Boolean;

Var IdChip: Fl_IdChip;
Begin
  MatchIdChip := False;
  If ManufNode^.Manuf <> ExpectedMan Then Exit;
  IdChip := ManufNode^.IdChip;
  MatchIdChip := IdChip(DevId, CInfo);
End;


Function FlashDetect : PChipInfo;

Var 
  MinB,MaxB,Tries : Byte;
  ROMFound        : Boolean;

Function DetectLoop( Method : Byte; Var Man, Dev : Byte ) : Boolean;

Var 
  M, D, X   : Byte;
  M0,D0     : Byte; {v1.24}
  BusStage  : Byte;
  Done,
  Found     : Boolean;

Procedure WaitWithIRQs( MicroSeconds : LongInt );
Begin

{FPC's DOS timing path and resident DOS drivers may require IRQs while
    waiting.  The caller keeps the flash command/read sequence protected.}
  Asm STI
End;
Wait( MicroSeconds );
Asm CLI
End;
End;

Procedure SerializeFlashWrite;
Begin

{An uncached VGA-bus transaction drains posted chipset writes.  Use an
    off-screen cell so this has the proven timing of the diagnostic markers
    without changing the visible display.}
  MemW[$B800: $1000] := $0700 Or BusStage;
  Inc(BusStage);
End;

Procedure SendFlashCommand( Cmd : Byte );
Begin

{Serialize posted chipset/ROM writes.  The original compiler generated
    enough delay between accesses; the FPC build can issue this unlock
    sequence too quickly on some cached/shadowed configurations.}
  Flash_Write($5555,$AA);
  SerializeFlashWrite;
  Flash_Write($2AAA,$55);
  SerializeFlashWrite;
  Flash_Write($5555,Cmd);
  SerializeFlashWrite;
End;

Procedure SendIdCmd;
Begin
  Case Method Of 
    0 :
        Begin {old method}
          SendFlashCommand( $80 );
          SendFlashCommand( $60 );
        End;
    1 :
        Begin {new method}
          SendFlashCommand( $90 );
        End;
  End;
  WaitWithIRQs( 50 );
End;

Procedure ResetROM;
Begin

{Exit software-ID/status mode with the command appropriate for the
     detected command set.  The old sequence wrote FF, FF, 00 after an
     unlock/F0 command; on some shadowed/cached DOS configurations the
     first raw FF write never returns.}
  If M = $89 Then
    Flash_Write(0,$FF)             {Intel read-array command}
  Else
    Flash_Write(0,$F0);            {AMD/SST reset/read command}
  SerializeFlashWrite;
  WaitWithIRQs(1000); {v1.28}
End;


Begin
  LogWrite('DetectLoop');
  DetectLoop := True;
  Found := False;
  BusStage := 0;
  For X := MinB To MaxB Do
    Begin
      If X > 0 Then ROMBase := ( - ( LongInt( 1 ) shl X ) );
      Done := False;

      Repeat
        LogWrite('DetectLoop: reading initial ROM bytes at '+Hl(ROMBase));
        M0 := Flash_Read(0);
        D0 := Flash_Read(1);
        LogWrite('DetectLoop: initial bytes '+Hb(M0)+','+Hb(D0)+
        '; entering interrupt-disabled ID sequence');
        asm CLI
      End;
      SendIdCmd;
     {Get mfg. code}
      M := Flash_Read(0);
      If M = $7F Then M := Flash_Read($100); {Mfg. ID for EON}
      If (M=$7F) And (Flash_Read(3)=$1F) Then M := $7F; {Mfg. ID for IMT}
      If M=$C2 Then {v1.28 fix Macronix }
        Begin
          ResetROM;
          SendIdCmd;
        End;
     {Get dev. code}
      D := Flash_Read(1);
      If D = $7F Then D := Flash_Read($101); {Dev. ID for EON}
      ResetROM;
      asm STI
    End;
  LogWrite('DetectLoop: ID sequence complete, read '+Hb(M)+','+Hb(D));

  If ((M<>M0) Or (D<>D0)) And ParityOdd(M) Then
    Begin

      If Not Found Then
        Begin
          Man := M;
          Dev := D;
          CurManuf := ManuRoot;
          Found := False;
          Repeat
            FillChar( CurCInfo.Sectors, SizeOf( CurCInfo.Sectors ), 0);
            {v1.21 Clear sector table}
            If MatchIdChip(CurManuf, Man, Dev, CurCInfo) Then Found := True
            Else CurManuf := CurManuf^.Next;
          Until Found Or ( CurManuf = Nil );
          If Found Then
            Begin
              If X > 0 Then ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
              Exit;
            End
          Else Done := True;
        End
      Else
        Begin
          CurCInfo.Size := CurCInfo.Size;
          ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
          Exit;
        End;
    End
  Else
    Begin
      Done := True;
      If Found Then
        Begin
          CurCInfo.Size := CurCInfo.Size;
          ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
          Exit;
        End;
    End;
Until Done;
End;
DetectLoop := False;
End;

Begin
  LogWrite('Beginning Flash ROM detection...');
  Man1 := $FF;
  Dev1 := $FF;
  Man2 := $FF;
  Dev2 := $FF;
  ROMFound := False;
  FlashError := 0;
  FlashDetect := @CurCInfo;
  FillChar( CurCInfo, SizeOf( CurCInfo ), 0 );
{ CurCInfo.Count := 1;}
  If ROMBase = 0 Then
    Begin
      MinB := 15;
      MaxB := 20;
    End
  Else
    Begin
      MinB := 0;
      MaxB := 0;
    End;

  If DetectLoop( 0, Man1, Dev1 ) Then ROMFound := True
  Else
    Begin
      If ( Man1 <> $FF ) Or ( Dev2 <> $FF ) Then
        Begin
          Man2 := Man1;
          Dev2 := Dev1;
        End;
      If DetectLoop( 1, Man1, Dev1 ) Then ROMFound := True
    End;

  If Not ROMFound Then
    Begin
      FlashDetect := Nil; {not identified}
      CurManuf := Nil;
      FlashError := 1;    {unknown chip}
    End
  Else Size512K := CurCInfo.Size>=512; {v1.34}
  LogWrite('Flash ROM detection complete');
End;

Procedure FlashProgram( Pos, Data : LongInt );
{Var
SaveRB : LongInt;}

Begin
  FlashError := 0;
  If CurManuf <> Nil Then
    Begin

(*   SaveRB := ROMBase;  {Save ROMBase}
   With CurCInfo do
   If Count > 1 then
    Begin
     {Make ROMBase point to single chip we need}
     ROMBase := ROMBase +
                ( LongInt( Size div Count ) shl 10 ) *
                ( ( Pos - ROMBase ) div ( LongInt( Size div Count ) shl 10 ) );
    End;*)
      Asm CLI
    End;
  CurCInfo.Progr( Pos, Data );
  Asm STI
End;
(*   ROMBase := SaveRB; {Restore ROMBase}*)
End;
End;

Procedure FlashErase( Pos : LongInt );
{Var
SaveRB : LongInt;}

Begin
  If ( CurManuf <> Nil ) And ( @CurCInfo.Erase <> Nil ) Then
    Begin
      FlashError := 0;

(*   SaveRB := ROMBase;  {Save ROMBase}
   With CurCInfo do
   If Count > 1 then
    Begin
     {Make ROMBase point to single chip we need}
     ROMBase := ROMBase +
                ( LongInt( Size div Count ) shl 10 ) *
                ( ( Pos - ROMBase ) div ( LongInt( Size div Count ) shl 10 ) );
    End;*)
      Asm CLI
    End;
  CurCInfo.Erase( Pos );
  Asm STI
End;
(*   ROMBase := SaveRB; {Restore ROMBase}*)
End;
End;

{Begin}
End.
