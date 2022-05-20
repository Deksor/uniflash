Unit Macronix; { Unit to communicate with Macronix chips }

{NOTE: This is experimental and based on some quick }
{      reverse engineering, we currently don't have }
{      any datasheets on Macronix chips ...         }

Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure MxSecProg( Pos, Data : LongInt ); Far;
Var
Attempt,
X, Y, Ld,
TimeOut  : Byte;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemB( Data + Y );
   Repeat
    FOMemB( Pos + Y, $40 );  {Write setup}
    FOMemB( Pos + Y, Ld );   {Write data}

    {Wait for programming to finish}
    TimeOut := 40;  {300 usec max}
    While  ( ( FiMemB( Pos + Y ) and $40 ) <>
             ( FiMemB( Pos + Y ) and $40 ) ) and ( TimeOut > 0 ) do
     Begin
      Dec( TimeOut );
      Wait( 10 );
     End;

    Inc( Attempt );
    X := FIMemB( Pos + Y );
   Until ( Attempt > 3 ) or  ( X = Ld );
   If ( X <> Ld ) then
    Begin
     IntelResetB;
     FlashCmd( 0 );
     FlashError := 2; {programming error}
     Exit;
    End;
  End;
 IntelResetB;
 FlashCmd( 0 );
End;

Procedure MxSecErase( SAddr : LongInt ); Far;
Var
Attempt,
X        : Byte;
TimeOut  : Word;


Begin
 Attempt := 0;
 Repeat
  FOMemB( SAddr, $20 ); {Erase setup}
  FOMemB( SAddr, $D0 ); {Erase confirm}
  Wait( 250 ); {Wait +- 200 usec for erase to start}

  {Wait for erase to finish}
  TimeOut := 50000;   {5 sec max}
  While  ( ( FiMemB( SAddr ) and $40 ) <>
           ( FiMemB( SAddr ) and $40 ) ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 100 );
   End;

  {Did erase work?}
  X := FiMemB( SAddr ) and $80;
  Inc( Attempt );
 Until ( Attempt > 3 ) or ( X <> $0 );
 If X = 0 then FlashError := 3; {erasing error}
 IntelResetB;
 FlashCmd( 0 );
End;


Function MxIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 MxIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $77,
    $11 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 128;
           If DevId = $11 then
            Name := ConstPtr( 'MXIC28F1000P/12V' )
           else
            Name := ConstPtr( 'MXIC28F1000PC/12V' );
          End;
    $1A : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 4;  {4 x 4k}
           Sectors[ 1, 1 ] := 1;
           Sectors[ 2, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( 'MXIC28F1000AP/12V' );
          End;
    $7F : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 4;  {4 x 4k}
           Sectors[ 1, 1 ] := 1;
           Sectors[ 2, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( 'MXIC28F1000PPC/12V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Macronix' );
 MxIdChip := True;
End;

Begin
 RegisterFlashManu( $42, MxIdChip );
End.
