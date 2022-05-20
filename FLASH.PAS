Unit Flash;

Interface

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


Const
On         = True;
Off        = False;
FlashError : Word = 0;
ManuRoot   : PFl_Manuf = Nil;
ManuTail   : PFl_Manuf = Nil;
CurManuf   : PFl_Manuf = Nil;


Var
Man1, Dev1,
Man2, Dev2 : Byte;
CurCInfo   : ChipInfo;
ROMBase    : LongInt;

Procedure FlashCmd( Cmd : Byte );
Procedure FlashCmdW( Cmd : Byte ); {v1.21}
Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
Function FlashDetect : PChipInfo;
Procedure FlashProgram( Pos, Data : LongInt );
Procedure FlashErase( Pos : LongInt );

Implementation

Uses Crt, Tools;

Procedure FlashCmd( Cmd : Byte );
Begin
 FOMemB( ROMBase + $5555, $AA );
 FOMemB( ROMBase + $2AAA, $55 );
 FOMemB( ROMBase + $5555, Cmd );
End;

Procedure FlashCmdW( Cmd : Byte );
Begin
 FOMemW( ROMBase + $5555, $AA );
 FOMemW( ROMBase + $2AAA, $55 );
 FOMemW( ROMBase + $5555, Cmd );
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
    FOMemB( ROMBase, $FF );
    FOMemB( ROMBase, $FF );
    FOMemB( ROMBase, $00 );
    FlashCmd( $F0 ); {disable for Macronix chips? like v1.24 BETA}
  End;


 begin
  DetectLoop := True;
  Found := False;
  for X := MinB to MaxB do
   begin
    if X > 0 then ROMBase := ( - ( LongInt( 1 ) shl X ) );
    Done := False;

    repeat
     resetrom;
     M0:=FIMemB(ROMBase);
     D0:=FIMemB(ROMBase+1);
     asm CLI end;
     SendIdCmd;
     {Get mfg. code}
     M := FIMemB( ROMBase );
     if M = $7F then M := FIMemB( ROMBase + $100 ); {Mfg. ID for EON}
     if (M=$7F) and (FIMemB(ROMBase+$3)=$1F) then M:=$7F; {Mfg. ID for IMT}

     {Get dev. code}
     D := FIMemB( ROMBase + 1 );
     if D = $7F then D := FIMemB( ROMBase + $101 ); {Dev. ID for EON}
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
Var
SaveRB : LongInt;

Begin
 FlashError := 0;
 If CurManuf <> Nil then
  Begin
   SaveRB := ROMBase;  {Save ROMBase}
(*   With CurCInfo do
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
   ROMBase := SaveRB; {Restore ROMBase}
  End;
End;

Procedure FlashErase( Pos : LongInt );
Var
SaveRB : LongInt;

Begin
 If ( CurManuf <> Nil ) and ( @CurCInfo.Erase <> Nil ) then
  Begin
   FlashError := 0;
   SaveRB := ROMBase;  {Save ROMBase}
(*   With CurCInfo do
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
   ROMBase := SaveRB; {Restore ROMBase}
  End;
End;

{Begin}
End.