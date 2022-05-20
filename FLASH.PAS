Unit Flash;

Interface

Const
On         = True;
Off        = False;
FlashError : Word = 0;

Type
Fl_Erase   = Procedure( SAddr : LongInt );
Fl_Program = Procedure( Pos, Data : LongInt );
ChipInfo   = Record
              Manuf,
              Name    : ^String;
              Erase   : Fl_Erase;
              Progr   : Fl_Program;
              Sectors : ARRAY[ 0 .. 3, 0 .. 1 ] of Byte;
              Size    : Word;
              PgSize  : Word;
              Flags   : Byte;
              Count   : Byte;
             End;
PChipInfo  = ^ChipInfo;
Fl_IdChip  = Function( DevID : Byte; Var CInfo : ChipInfo ) : Boolean;

Var
Man1, Dev1,
Man2, Dev2 : Byte;
CurCInfo   : ChipInfo;
ROMBase    : LongInt;

Procedure FlashCmd( Cmd : Byte );
Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
Function FlashDetect : PChipInfo;
Procedure FlashProgram( Pos, Data : LongInt );
Procedure FlashErase( Pos : LongInt );

Implementation

Uses Crt, Tools;

Type
PFl_Manuf  = ^Fl_Manuf;
Fl_Manuf   = Record
              IdChip : Fl_IdChip;

              Next   : PFl_Manuf;
              Manuf  : Byte;
             End;

Const
ManuRoot   : PFl_Manuf = Nil;
ManuTail   : PFl_Manuf = Nil;
CurManuf   : PFl_Manuf = Nil;

Procedure FlashCmd( Cmd : Byte );
Begin
 FOMemB( ROMBase + $5555, $AA );
 FOMemB( ROMBase + $2AAA, $55 );
 FOMemB( ROMBase + $5555, Cmd );
End;

Procedure RegisterFlashManu( Manu : Byte; Id : Fl_IdChip );
Begin
 If ManuTail = Nil then
  Begin
   New( ManuTail );
   ManuRoot := ManuTail;
  End else
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
MinB,MaxB : Byte;

Function DetectLoop( Method : Byte; Var Man, Dev : Byte ) : Boolean;
Var
M, D, X   : Byte;
Done,
Found     : Boolean;

Begin
 DetectLoop := True;
 Found := False;
 For X := MinB to MaxB do
  Begin
   If X > 0 then ROMBase := ( - ( LongInt( 1 ) shl X ) );
   Done := False;
   Repeat
    Asm CLI End;
    If Method = 0 then
     Begin
      {old method}
      FlashCmd( $80 );
      FlashCmd( $60 );
     End else
     Begin
      {new method}
      FlashCmd( $90 );
     End;
    Wait( 20 );
    M := FIMemB( ROMBase );
    D := FIMemB( ROMBase + 1 );
    FOMemW( ROMBase, $FFFF );
    FOMemW( ROMBase, $FFFF );
    FOMemW( ROMBase, $0000 );
    FlashCmd( $F0 ); {Avoid leaving the chip in ID mode}
    Wait( 20 );
    Asm STI End;
    If ( ( M <> FIMemB( ROMBase ) ) or
       ( D <> FIMemB( ROMBase + 1 ) ) ) and
       ParityOdd( D ) and ParityOdd( M ) then
     Begin
      If not Found then
       Begin
        Man := M and $7F;
        Dev := D and $7F;
        CurManuf := ManuRoot;
        Found := False;
        Repeat
         With CurManuf^ do
          Begin
           If ( Manuf = Man ) and
              IdChip( Dev, CurCInfo ) then Found := True
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
       End else
       Begin
        If ( ( M and $7F ) = Man ) and
           ( ( D and $7F ) = Dev ) and
           {Catch the partial decode case ...}
           ( not CompLinBlocks( ROMBase + ( CurCInfo.Size shl 10 ) - 16,
                                ROMBase + ( CurCInfo.Size shl 11 ) - 16,
                                16 ) ) then
         Begin
          Inc( CurCInfo.Count );
          ROMBase := ROMBase - ( LongInt( CurCInfo.Size ) shl 10 );
         End else
         Begin
          CurCInfo.Size := CurCInfo.Size * CurCInfo.Count;
          ROMBase := - ( LongInt( CurCInfo.Size ) shl 10 );
          Exit;
         End;
       End;
     End else
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
 Man1 := $FF;
 Dev1 := $FF;
 Man2 := $FF;
 Dev2 := $FF;

 FlashError := 0;
 FlashDetect := @CurCInfo;
 FillChar( CurCInfo, SizeOf( CurCInfo ), 0 );
 CurCInfo.Count := 1;

 If ROMBase = 0 then
  Begin
   MinB := 15;
   MaxB := 20;
  End else
  Begin
   MinB := 0;
   MaxB := 0;
  End;

 If not ( DetectLoop( 0, Man1, Dev1 ) or
          DetectLoop( 1, Man2, Dev2 ) ) then
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

End.