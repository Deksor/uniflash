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
              Count   : Byte;
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
Method          : Byte;

 Function DetectLoop( Method : Byte; Var Man, Dev : Byte ) : Boolean;
 Var
 M, D, X   : Byte;
 T         : Word;
 Done,
 Found     : Boolean;

  Procedure SendIdCmd;
   Begin
    Case ( Method and 3 ) of
      0 : Begin {old method}
           FlashCmd( $80 );
           FlashCmd( $60 );
          End;
      1 : Begin {new method}
           FlashCmd( $90 );
          End;
      2 : Begin {old method, words}
           FlashCmdW( $80 );
           FlashCmdW( $60 );
          End;
      3 : Begin {new method, words}
           FlashCmdW( $90 );
          End;
    End;
    Wait( 50 );
   End;

  Procedure ResetROM;
  Begin
   If ( Method and 2 ) = 0 then
    Begin
     FOMemB( ROMBase, $FF );
     FOMemB( ROMBase, $FF );
     FOMemB( ROMBase, $00 );
     FlashCmd( $F0 );
    End else
    Begin
     FOMemW( ROMBase, $FFFF );
     FOMemW( ROMBase, $FFFF );
     FOMemW( ROMBase, $0000 );
     FlashCmdW( $F0 );
    End;
  End;


 Begin
  DetectLoop := True;
  Found := False;
  For X := MinB to MaxB do
   Begin
    If X > 0 then ROMBase := ( - ( LongInt( 1 ) shl X ) );
    Done := False;

    Repeat
     Asm CLI End;
{     ResetROM;} {v1.22}
     SendIdCmd;
     If ( Method and 2 ) = 0 then {Get mfg. code}
      Begin
       M := FIMemB( ROMBase );
       if M = $7F then M := FIMemB( ROMBase + $100 ); {Mfg. ID for EON v1.21}
 {      if M = $7F then M := FIMemB( ROMBase + $11 );}  {Mfg. ID for IMT v1.21}
      End
     else M := Lo( FIMemW( ROMBase ) );

(*     If ( Method and 4 ) <> 0 then   {v1.22}
      Begin
       ResetROM;
       SendIdCmd;
      End;*)
     If ( Method and 2 ) = 0 then {Get dev. code}
      Begin
       D := FIMemB( ROMBase + 1 );
       if D = $7F then D := FIMemB( ROMBase + $101 ); {Dev. ID for EON v1.21}
      End
     else D := Hi( FIMemW( ROMBase ) );
     ResetROM;
     Asm STI End;

     If ( ( M <> FIMemB( ROMBase ) ) or
        ( D <> FIMemB( ROMBase + 1 ) ) ) and
 {       ParityOdd( D ) and }ParityOdd( M ) then {v1.21 - Device ID can have even parity}
      Begin

       If not Found then
        Begin
         Man := M {and $7F}; {v1.21}
         Dev := D {and $7F}; {v1.21}
         CurManuf := ManuRoot;
         Found := False;
         Repeat
          FillChar( CurCInfo.Sectors, SizeOf( CurCInfo.Sectors ), 0); {v1.21 Clear sector table}
          With CurManuf^ do
           Begin
            If ( Manuf = Man ) and IdChip( Dev, CurCInfo ) then Found := True
            else CurManuf := CurManuf^.Next;
           End;
         Until Found or ( CurManuf = Nil );
         If not Found then Done := True else
          Begin
           If X > 0 then
            Begin
             ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
             If CurCInfo.Size <= 512 then
              ROMBase := ROMBase - ( LongInt( CurCInfo.Size ) shl 10 )
             else Exit;
            End else Exit;
          End;
        End
       else
        Begin
         If ( ( M {and $7F }) = Man ) and {v1.21}
            ( ( D {and $7F }) = Dev ) and {v1.21}
            {Catch the partial decode case ...}
            ( not CompLinBlocks( ROMBase + ( CurCInfo.Size shl 10 ) - 16,
                                 ROMBase + ( CurCInfo.Size shl 11 ) - 16,
                                 16 ) ) then
          Begin
           Inc( CurCInfo.Count );
           ROMBase := ROMBase - ( LongInt( CurCInfo.Size ) shl 10 );
          End
         else
          Begin
           CurCInfo.Size := CurCInfo.Size * CurCInfo.Count;
           ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
           Exit;
          End;
        End;
      End
     else
      Begin
       Done := True;
       If Found then
        Begin
         CurCInfo.Size := CurCInfo.Size * CurCInfo.Count;
         ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
         Exit;
        End;
      End;
    Until Done;
   End;
  DetectLoop := False;
 End;

Begin
 Man1 := $FF; Dev1 := $FF; Man2 := $FF; Dev2 := $FF;
 ROMFound:=false;
 FlashError := 0;
 FlashDetect := @CurCInfo;
 FillChar( CurCInfo, SizeOf( CurCInfo ), 0 );
 CurCInfo.Count := 1;
 If ROMBase = 0 then Begin MinB := 15; MaxB := 20; End
  else Begin MinB := 0; MaxB := 0; End;
{ randomize;
 tries:=0;} {v1.22}

 for Method := 0 to 3 do
  Begin
    if DetectLoop( Method, Man1, Dev1 ) then
     Begin
       ROMFound := True;
       Break;
     End
    else
     If ( Man1 <> $FF ) or ( Dev2 <> $FF ) then
      Begin
       Man2 := Man1;
       Dev2 := Dev1;
      End;
  End;

{ The loop below is *VERY* tricky. The DetectLoop proc is called until}
{ the chip is detected or the number of unsuccessful tries (255) is reached}

(* conditions := false;
 repeat
  rand:=random( 8 );

  if DetectLoop( rand, Man1, Dev1 ) then conditions := true
  else if ( man1 <> $FF ) or ( dev2 <> $FF ) then
   begin
    man2 := man1;
    dev2 := dev1;
   end;
  inc(tries);
 until (conditions) or (tries=0);*)

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
   With CurCInfo do
   If Count > 1 then
    Begin
     {Make ROMBase point to single chip we need}
     ROMBase := ROMBase +
                ( LongInt( Size div Count ) shl 10 ) *
                ( ( Pos - ROMBase ) div ( LongInt( Size div Count ) shl 10 ) );
    End;
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
   With CurCInfo do
   If Count > 1 then
    Begin
     {Make ROMBase point to single chip we need}
     ROMBase := ROMBase +
                ( LongInt( Size div Count ) shl 10 ) *
                ( ( Pos - ROMBase ) div ( LongInt( Size div Count ) shl 10 ) );
    End;
   Asm CLI End;
   CurCInfo.Erase( Pos );
   Asm STI End;
   ROMBase := SaveRB; {Restore ROMBase}
  End;
End;

Begin
End.