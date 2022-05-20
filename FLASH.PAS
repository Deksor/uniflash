Unit Flash;

Interface
uses Tools; {v1.29}

Type
Fl_Erase   = Procedure( SAddr : LongInt );
Fl_Program = Procedure( Pos, Data : LongInt );
ChipInfo   = Record
              Manuf,
              Name    : ^String;
              Erase   : Fl_Erase;
              Progr   : Fl_Program;
              Sectors : ARRAY[ 0 .. 4, 0 .. 1 ] of Word;
              Size    : Word;
              PgSize  : Word;
              Flags   : Byte;
{              Count   : Byte;}
             End;
PChipInfo  = ^ChipInfo;
Fl_IdChip  = Function( DevID : Byte; Var CInfo : ChipInfo ) : Boolean;
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

function  FIMemB_Flash(Addr:LongInt):Byte; {v1.29}
function  FIMemB_Flash_FinALi(Addr:LongInt):Byte; {v1.29}
function  FIMemB_Flash_Low(Addr:LongInt):Byte; {v1.31}
procedure FOMemB_Flash(Addr:LongInt;Data:Byte); {v1.29}
procedure FOMemB_Flash_FinALi(Addr:LongInt;Data:Byte); {v1.29}
procedure MoveLinBlock_From_Flash_D(Src,Dest,Size:LongInt); {v1.29}
procedure MoveLinBlock_From_Flash_D_FinALi(Src,Dest,Size:LongInt); {v1.29}
procedure MoveLinBlock_From_Flash_D_Low(Src,Dest,Size:LongInt); {v1.31}
procedure MoveLinBlock_To_Flash_B(Src,Dest,Size:LongInt); {v1.29}
procedure MoveLinBlock_To_Flash_B_FinALi(Src,Dest,Size:LongInt); {v1.29}
function  CompLinBlocks_Flash(Block1,Block2,Size:LongInt):Boolean; {v1.29}
function  CompLinBlocks_Flash_FinALi(Block1,Block2,Size:LongInt):Boolean; {v1.29}
function  CompLinBlocks_Flash_Low(Block1,Block2,Size:LongInt):Boolean; {v1.31}
Procedure FlashCmd( Cmd : Byte );
Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
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
Flash_Read : function(Address:LongInt):Byte=FIMemB_Flash; {v1.29}
Flash_Write: procedure(Address:LongInt;Data:Byte)=FOMemB_Flash; {v1.29}
Flash_ReadBlock: procedure(FlashAddr,MemAddr,Size:LongInt)=MoveLinBlock_From_Flash_D; {v1.29}
Flash_WriteBlock: procedure(FlashAddr,MemAddr,Size:LongInt)=MoveLinBlock_To_Flash_B; {v1.29}
Flash_Compare: function(MemAddr,FlashAddr,Size:LongInt):Boolean=CompLinBlocks_Flash; {v1.29}
ShadowDisable: procedure=nil; {v1.31}
ShadowRestore: procedure=nil; {v1.31}

Implementation

Uses Crt, PCI;

function FIMemB_Flash(Addr:LongInt):Byte; {v1.29}
begin
 FIMemB_Flash:=FIMemB(ROMBase+Addr);
end;

function FIMemB_Flash_FinALi(Addr:LongInt):Byte; {v1.29}
begin
  if Addr<$10000 then SetBank(1) else SetBank(2);
  FIMemB_Flash_FinALi:=FIMemB(ROMBase+Addr-Byte(Addr>=$10000)*$10000);
end;

function FIMemB_Flash_Low(Addr:LongInt):Byte; {v1.31}
begin
 asm pushf;cli end;
 ShadowDisable;
 FIMemB_Flash_Low:=FIMemB(ROMBase+Addr);
 ShadowRestore;
 asm popf end;
end;

procedure FOMemB_Flash(Addr:LongInt;Data:Byte); {v1.29}
begin
 FOMemB(ROMBase+Addr,Data);
end;

procedure FOMemB_Flash_FinALi(Addr:LongInt;Data:Byte); {v1.29}
begin
  if Addr<$10000 then SetBank(1) else SetBank(2);
  FOMemB($F0000+Addr-Byte(Addr>=$10000)*$10000,Data);
end;

procedure MoveLinBlock_From_Flash_D(Src,Dest,Size:LongInt); {v1.29}
begin
 MoveLinBlockD(ROMBase+Src,Dest,Size);
end;

procedure MoveLinBlock_From_Flash_D_FinALi(Src,Dest,Size:LongInt); {v1.29}
var FirstBlock:LongInt;
begin
 FirstBlock:=0;
 if Src<$10000 then
  begin
    SetBank(1);
    if Size+Src>=$10000 then FirstBlock:=$10000-Src else FirstBlock:=Size;
    MoveLinBlockD(ROMBase+Src,Dest,FirstBlock);
  end;
 if Src+Size>=$10000 then
  begin
    SetBank(2);
    if Src<$10000 then MoveLinBlockD(ROMBase,Dest+FirstBlock,Size-FirstBlock)
     else MoveLinBlockD(ROMBase+Src-$10000,Dest+FirstBlock,Size);
  end;
end;

procedure MoveLinBlock_From_Flash_D_Low(Src,Dest,Size:LongInt); {v1.31}
begin
 asm pushf;cli end;
 ShadowDisable;
 MoveLinBlockD(ROMBase+Src,Dest,Size);
 ShadowRestore;
 asm popf end;
end;

procedure MoveLinBlock_To_Flash_B(Src,Dest,Size:LongInt); {v1.29}
begin
 MoveLinBlockB(Src,ROMBase+Dest,Size);
end;

procedure MoveLinBlock_To_Flash_B_FinALi(Src,Dest,Size:LongInt); {v1.29}
var FirstBlock:LongInt;
begin
 FirstBlock:=0;
 if Dest<$10000 then
  begin
    SetBank(1);
    if Size+Dest>=$10000 then FirstBlock:=$10000-Dest else FirstBlock:=Size;
    MoveLinBlockB(Src,$F0000+Dest,FirstBlock);
  end;
 if Dest+Size>=$10000 then
  begin
    SetBank(2);
    if Dest<$10000 then MoveLinBlockB(Src+FirstBlock,$F0000,Size-FirstBlock)
     else MoveLinBlockD(Src,$F0000+Dest-$10000,Size);
  end;
end;

function CompLinBlocks_Flash(Block1,Block2,Size:LongInt):Boolean; {v1.29}
begin
 CompLinBlocks_Flash:=CompLinBlocks(ROMBase+Block1,Block2,Size);
end;

function CompLinBlocks_Flash_FinALi(Block1,Block2,Size:LongInt):Boolean; {v1.29}
var OK:Boolean;
    FirstBlock:LongInt;
begin
 OK:=True;
 FirstBlock:=0;
 if Block1<$10000 then
  begin
    SetBank(1);
    if Size+Block1>=$10000 then FirstBlock:=$10000-Block1 else FirstBlock:=Size;
    if not CompLinBlocks(ROMBase+Block1,Block2,FirstBlock) then OK:=False;
  end;
 if (Block1+Size>=$10000) and OK then
  begin
    SetBank(2);
    if Block1<$10000 then
     begin
       if not CompLinBlocks(ROMBase,Block2+FirstBlock,Size-FirstBlock) then OK:=False;
     end
     else if not CompLinBlocks(ROMBase+Block1-$10000,Block2+FirstBlock,Size) then OK:=False;
  end;
 CompLinBlocks_Flash_FinALi:=OK;
end;

function CompLinBlocks_Flash_Low(Block1,Block2,Size:LongInt):Boolean; {v1.31}
begin
 asm pushf;cli end;
 ShadowDisable;
 CompLinBlocks_Flash_Low:=CompLinBlocks(ROMBase+Block1,Block2,Size);
 ShadowRestore;
 asm popf end;
end;

Procedure FlashCmd( Cmd : Byte );
Begin
 Flash_Write($5555,$AA); {v1.29}
 Flash_Write($2AAA,$55);
 Flash_Write($5555,Cmd);
End;

Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
Begin
 If ManuTail = Nil then
  Begin
   New( ManuTail );
   ManuRoot := ManuTail;
  End
 else
  Begin
   New( ManuTail^.Next );
   ManuTail := ManuTail^.Next;
  End;
 With ManuTail^ do
  Begin
   IdChip := Id;
   Manuf := Manu;
   Next := Nil;
  End;
End;

Function ParityOdd( B : Byte ) : Boolean; Assembler;
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


Function FlashDetect : PChipInfo;
Var
MinB,MaxB,Tries : Byte;
ROMFound        : Boolean;

 Function DetectLoop( Method : Byte; Var Man, Dev : Byte ) : Boolean;
 Var
 M, D, X   : Byte;
 M0,D0     : Byte; {v1.24}
 Done,
 Found     : Boolean;

  Procedure SendIdCmd;
   Begin
    Case Method of
      0 : Begin {old method}
           FlashCmd( $80 );
           FlashCmd( $60 );
          End;
      1 : Begin {new method}
           FlashCmd( $90 );
          End;
    End;
    Wait( 50 );
   End;

  Procedure ResetROM;
  Begin
    FlashCmd( $F0 ); {v1.28}
    Wait(1000); {v1.28}
    Flash_Write(0,$FF);
    Flash_Write(0,$FF);
    Wait(1000); {v1.28}
    Flash_Write(0,0);
    Wait(1000); {v1.28}
    FlashCmd( $F0 );
    Wait(1000); {v1.28}
  End;


 begin
  DetectLoop := True;
  Found := False;
  for X := MinB to MaxB do
   begin
    if X > 0 then ROMBase := ( - ( LongInt( 1 ) shl X ) );
    Done := False;

    repeat
     M0:=Flash_Read(0);
     D0:=Flash_Read(1);
     asm CLI end;
     SendIdCmd;
     {Get mfg. code}
     M := Flash_Read(0);
     if M = $7F then M := Flash_Read($100); {Mfg. ID for EON}
     if (M=$7F) and (Flash_Read(3)=$1F) then M:=$7F; {Mfg. ID for IMT}
     if M=$C2 then {v1.28 fix Macronix }
      begin
        ResetROM;
        SendIdCmd;
      end;
     {Get dev. code}
     D := Flash_Read(1);
     if D = $7F then D := Flash_Read($101); {Dev. ID for EON}
     ResetROM;
     asm STI end;

     if ((M<>M0) or (D<>D0)) and ParityOdd(M) then
      begin

       if not Found then
        begin
         Man := M;
         Dev := D;
         CurManuf := ManuRoot;
         Found := False;
         repeat
          FillChar( CurCInfo.Sectors, SizeOf( CurCInfo.Sectors ), 0); {v1.21 Clear sector table}
          with CurManuf^ do
           if ( Manuf = Man ) and IdChip( Dev, CurCInfo ) then Found := True
           else CurManuf := CurManuf^.Next;
         until Found or ( CurManuf = Nil );
         if Found then
          begin
            If X > 0 then ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
            Exit;
          end
         else Done := True;
        end
       else
        begin
          CurCInfo.Size := CurCInfo.Size;
          ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
          Exit;
        end;
      end
     else
      begin
       Done := True;
       if Found then
        begin
         CurCInfo.Size := CurCInfo.Size;
         ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
         Exit;
        end;
      end;
    until Done;
   end;
  DetectLoop := False;
 end;

Begin
 Man1 := $FF; Dev1 := $FF; Man2 := $FF; Dev2 := $FF;
 ROMFound:=False;
 FlashError := 0;
 FlashDetect := @CurCInfo;
 FillChar( CurCInfo, SizeOf( CurCInfo ), 0 );
{ CurCInfo.Count := 1;}
 If ROMBase = 0 then Begin MinB := 15; MaxB := 20; End
  else Begin MinB := 0; MaxB := 0; End;

 if DetectLoop( 0, Man1, Dev1 ) then ROMFound := True
 else
  Begin
    If ( Man1 <> $FF ) or ( Dev2 <> $FF ) then
     Begin
      Man2 := Man1;
      Dev2 := Dev1;
     End;
    if DetectLoop( 1, Man1, Dev1 ) then ROMFound := True
  End;

 if not ROMFound then
  Begin
   FlashDetect := Nil; {not identified}
   CurManuf := Nil;
   FlashError := 1;    {unknown chip}
  End;
End;

Procedure FlashProgram( Pos, Data : LongInt );
{Var
SaveRB : LongInt;}

Begin
 FlashError := 0;
 If CurManuf <> Nil then
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
   Asm CLI End;
   CurCInfo.Progr( Pos, Data );
   Asm STI End;
(*   ROMBase := SaveRB; {Restore ROMBase}*)
  End;
End;

Procedure FlashErase( Pos : LongInt );
{Var
SaveRB : LongInt;}

Begin
 If ( CurManuf <> Nil ) and ( @CurCInfo.Erase <> Nil ) then
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
   Asm CLI End;
   CurCInfo.Erase( Pos );
   Asm STI End;
(*   ROMBase := SaveRB; {Restore ROMBase}*)
  End;
End;

{Begin}
End.