Unit GenFlash;

Interface

Procedure GenPageProgB( Pos, Data : LongInt ); Far;
Procedure GenPageProgW( Pos, Data : LongInt ); Far;
Procedure IntelSecProg( Pos, Data : LongInt ); Far;
Procedure IntelSecProgW( Pos, Data : LongInt ); Far;
Procedure IntelSecErase( SAddr : LongInt ); Far;
Procedure IntelSecEraseW( SAddr : LongInt ); Far;
Procedure AMDSecProg( Pos, Data : LongInt ); Far;
Procedure AMDSecErase( SAddr : LongInt ); Far;
Procedure AMDEmbdErase( SAddr : LongInt ); Far;
Procedure AMDEmbdWrite( Pos, Data : LongInt ); Far;
Procedure AMDFlashWrite( Pos, Data : LongInt ); Far;
Procedure AMDFlashErase( SAddr : LongInt ); Far;

Implementation

Uses Tools, Crt, Flash;

Procedure GenPageProgB( Pos, Data : LongInt );
Var
Attempt,
Ld, X   : Byte;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 );
  MoveLinBlockB( Data, Pos, CurCInfo.PgSize );
  Wait( 300 );  {Wait min. 300 usec}

  Ld := FiMemB( Data + 127 ) and $80; {Last data byte, bit 7}
  Repeat
   X := FiMemB( Pos + 127 );    {Read last byte written}
  Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 );
  X := FiMemB( Pos + 127 );    {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
 If ( ( X and $A0 ) <> Ld ) then FlashError := 2; {programming error, timeout}
End;

{not tested yet}
Procedure GenPageProgW( Pos, Data : LongInt );
Var
Attempt,
Ld, X   : Byte;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 );
  MoveLinBlockW( Data, Pos, CurCInfo.PgSize );
  Wait( 300 ); {Min. 300 usec}
  Ld := FiMemB( Data + 255 ) and $80; {Last data byte, bit 7}
  Repeat
   X := FiMemB( Pos + 255 );    {Read last byte written}
  Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 );
  X := FiMemB( Pos + 255 );    {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
 If ( ( X and $A0 ) <> Ld ) then FlashError := 2; {programming error, timeout}
End;

Procedure IntelResetB;
Begin
 {Reset}
 FOMemB( ROMBase, $FF );
 FOMemB( ROMBase, $FF );
End;

Procedure IntelResetW;
Begin
 {Reset}
 FOMemW( ROMBase, $FFFF );
 FOMemW( ROMBase, $FFFF );
End;

Procedure IntelSecProg( Pos, Data : LongInt );
Var
Attempt,
X, Y, Ld : Byte;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemB( Data + Y );
   { Do not program FF, erase will result in all FF's so it's }
   { not necessary. Besides, 2*FF means reset ...             }
   If Ld <> $FF then
    Begin
     Repeat
      FOMemB( Pos + Y, $40 );  {Write setup}
      FOMemB( Pos + Y, Ld );   {Write data}
      {Wait for programming to finish}
      Repeat
       X := FiMemB( Pos + Y );
      Until ( ( X and $80 ) <> 0 );
      Inc( Attempt );
      X := FiMemB( Pos + Y );
      FOMemB( Pos + Y, $50 );  {Clear status}
     Until ( Attempt > 3 ) or  ( ( X and $98 ) = $80 );
     If ( ( X and $98 ) <> $80 ) then
      Begin
       IntelResetB;
       FlashError := 2; {programming error}
       Exit;
      End;
    End;
  End;
 IntelResetB;
End;

Procedure IntelSecProgW( Pos, Data : LongInt );
Var
Attempt,
X, Y, Ld : Word;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemW( Data + Y + Y );
   { Hmmm. Sure hope 2*FFFFh pulls reset, not 2*xxFFh ...}
   If Ld <> $FFFF then
    Begin
     Repeat
      FOMemW( Pos + Y + Y, $40 );  {Write setup}
      FOMemW( Pos + Y + Y, Ld );   {Write data}
      {Wait for programming to finish}
      Repeat
       X := FiMemW( Pos + Y + Y );
      Until ( ( X and $80 ) <> 0 );
      Inc( Attempt );
      X := FiMemW( Pos + Y + Y );
      FOMemW( Pos + Y + Y, $50 ); {Clear status}
     Until ( Attempt > 3 ) or  ( ( X and $98 ) = $80 );
     If ( ( X and $98 ) <> $80 ) then
      Begin
       IntelResetW;
       FlashError := 2; {programming error}
       Exit;
      End;
    End;
  End;
 IntelResetW;
End;

Procedure IntelSecErase( SAddr : LongInt );
Var
Attempt,
X        : Byte;

Begin
 Attempt := 0;
 Repeat
  FOMemB( SAddr, $20 ); {Erase setup}
  FOMemB( SAddr, $D0 ); {Erase confirm}
  {Wait for erase to finish}
  Repeat
   X := FiMemB( SAddr );
  Until ( ( X and $80 ) <> 0 );
  Inc( Attempt );
  X := FiMemB( SAddr );
  FOMemB( SAddr, $50 ); {Clear status}
 Until ( Attempt > 3 ) or ( ( X and $B8 ) = $80 );
 If ( X and $B8 ) <> $80 then FlashError := 3; {erasing error}
 IntelResetB;
End;

Procedure IntelSecEraseW( SAddr : LongInt );
Var
Attempt  : Byte;
X        : Word;

Begin
 Attempt := 0;
 Repeat
  FOMemW( SAddr, $20 ); {Erase setup}
  FOMemW( SAddr, $D0 ); {Erase confirm}
  {Wait for erase to finish}
  Repeat
   X := FiMemW( SAddr );
  Until ( ( X and $80 ) <> 0 );
  Inc( Attempt );
  X := FiMemW( SAddr );
  FoMemW( SAddr, $50 ); {Clear status}
 Until ( Attempt > 3 ) or ( ( X and $B8 ) = $80 );
 If ( X and $B8 ) <> $80 then FlashError := 3; {erasing error}
 IntelResetW;
End;

Procedure AMDSecProg( Pos, Data : LongInt );
Var
Attempt,
X, Y, Ld : Byte;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemB( Data + Y );
   If Ld <> $FF then
    Begin
     Repeat
      FlashCmd( $A0 );
      FOMemB( Pos + Y, Ld );
      Ld := Ld and $80; {Last data byte, bit 7}
      Repeat
       X := FiMemB( Pos + Y );    {Read last byte written}
      Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 );
      X := FiMemB( Pos + Y );    {Read last byte written}
      Inc( Attempt );
     Until ( Attempt > 3 ) or  ( ( X and $80 ) = Ld );
     If ( ( X and $80 ) <> Ld ) then
      Begin
       FlashError := 2; {programming error, timeout}
       Exit;
      End;
    End;
  End;
End;

Procedure AMDSecErase( SAddr : LongInt );
Var
Attempt,
X        : Byte;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  FOMemB( SAddr, $30 ); {Erase sector containing address SAddr}
(*  {Wait for erase to start}
  Repeat
   X := FiMemB( SAddr );
  Until ( X and $08 ) <> 0; *)

  {NOTE: IF THIS WON'T WORK THEN TRY A DELAY IN BETWEEN HERE ...}

  {Wait for erase to finish}
  Repeat
   X := FiMemB( SAddr );
  Until ( ( X and $A0 ) <> 0 );
  X := FiMemB( SAddr );
  Inc( Attempt );
 Until ( Attempt > 3 ) or ( ( X and $80 ) <> 0 );
 If ( X and $80 ) = 0 then FlashError := 3; {erasing error}
End;

Procedure AMDEmbdErase( SAddr : LongInt );
Begin
 FOMemB( ROMBase, $30 );
 FOMemB( ROMBase, $30 );
 Repeat Until ( FIMemB( ROMBase ) and $80 ) <> 0;
End;

Procedure AMDEmbdWrite( Pos, Data : LongInt );
Var
Attempt,
X, Y, Ld : Byte;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemB( Data + Y );
   If Ld <> $FF then
    Begin
     Repeat
      FOMemB( Pos + Y, $10 );
      FOMemB( Pos + Y, Ld );
      Ld := Ld and $80; {Last data byte, bit 7}
      Repeat
       X := FiMemB( Pos + Y );    {Read last byte written}
      Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 );
      X := FiMemB( Pos + Y );    {Read last byte written}
      Inc( Attempt );
     Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
     If ( ( X and $A0 ) <> Ld ) then
      Begin
       IntelResetB;
       FlashError := 2; {programming error, timeout}
       Exit;
      End;
    End;
  End;
 IntelResetB;
End;

Procedure AMDFlashWrite( Pos, Data : LongInt );
Var
X, Y, D,
Attempt : Byte;


Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   D := FIMemB( Data + Pos );
   If D <> $FF then
    Begin
     Repeat
      FOMemB( Pos + Y, $40 );
      FOMemB( Pos + Y, D );
      Wait( 10 );
      FOMemB( Pos + Y, $C0 );
      Wait( 6 );
      X := FIMemB( Pos + Y );
      Inc( Attempt );
     Until ( X = D ) or ( Attempt >= 25 );
     If Attempt >= 25 then
      Begin
       IntelResetB;
       FlashError := 2;
       Exit;
      End;
    End;
  End;
 IntelResetB;
End;

Procedure AMDFlashErase( SAddr : LongInt );
Var
Attempt : Word;
Addr    : LongInt;
D       : Byte;

Begin
 Attempt := 0;
 Repeat
  FOMemB( ROMBase, $20 );
  FOMemB( ROMBase, $20 );
  Wait( 10000 );
  For Addr := 0 to ( LongInt( CurCInfo.Size ) shl 10 ) - 1 do
   Begin
    FOMemB( ROMBase + Addr, $A0 );
    Wait( 6 );
    D := FIMemB( ROMBase + Addr );
    If D <> $FF then Break;
   End;
  Inc( Attempt );
 Until ( D = $FF ) or ( Attempt >= 1000 );
 If ( D <> $FF ) then FlashError := 3;
 IntelResetB;
End;

End.
