Unit GenFlash;

Interface
{v1.24 16-bit removed}
Procedure GenPageProgB( Pos, Data : LongInt ); Far;
{Procedure GenPageProgW( Pos, Data : LongInt ); Far;}
Procedure IntelResetB;
{Procedure IntelResetW;}
Procedure IntelSecProg( Pos, Data : LongInt ); Far;
{Procedure IntelSecProgW( Pos, Data : LongInt ); Far;}
Procedure IntelSecErase( SAddr : LongInt ); Far;
{Procedure IntelSecEraseW( SAddr : LongInt ); Far;}
Procedure AMDSecProg( Pos, Data : LongInt ); Far;
{Procedure AMDSecProgW( Pos, Data : LongInt ); Far;} {v1.21}
Procedure AMDSecErase( SAddr : LongInt ); Far;
Procedure AMDBulkErase( SAddr : LongInt ); Far; {v1.22}
{Procedure AMDSecEraseW( SAddr : LongInt ); Far;} {v1.21}
Procedure AMDEmbdErase( SAddr : LongInt ); Far;
Procedure AMDEmbdWrite( Pos, Data : LongInt ); Far;
Procedure AMDFlashWrite( Pos, Data : LongInt ); Far;
{Procedure AMDFlashWriteW( Pos, Data : LongInt ); Far;} {v1.21}
Procedure AMDFlashErase( SAddr : LongInt ); Far;
{Procedure AMDFlashEraseW( SAddr : LongInt ); Far;} {v1.21}

Implementation

Uses Tools, Crt, Flash;

Procedure GenPageProgB( Pos, Data : LongInt );
Var
Attempt, Ld, X : Byte;
TimeOut : Word; {v1.23}

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 );
  MoveLinBlockB( Data, Pos, CurCInfo.PgSize );
  Wait( 5000 {300});  {Wait 5ms} {v1.22 300us->5ms}

  Ld := FiMemB( Data + {127}CurCInfo.PgSize - 1 ) and $80; {Last data byte, bit 7}
  TimeOut := 1000;
  Repeat
   X := FiMemB( Pos + {127}CurCInfo.PgSize - 1 );    {Read last byte written}
   Wait( 50 );
   Dec( TimeOut );
  Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 ) or ( TimeOut<1 );
  if TimeOut < 1 then {v1.23}
   Begin
     FlashError := 2;
     Exit;
   End;
  X := FiMemB( Pos + {127}CurCInfo.PgSize - 1 );    {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
 If ( ( X and $A0 ) <> Ld ) then FlashError := 2; {programming error, timeout}
End;

{not tested yet}

(*Procedure GenPageProgW( Pos, Data : LongInt );
Var
Attempt, Ld, X : Byte;
TimeOut : Word; {v1.23}

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 );
  MoveLinBlockW( Data, Pos, CurCInfo.PgSize );
  Wait( 8000 {300});  {Wait 5ms} {v1.22 300us->5ms}
  Ld := FiMemB( Data + {255}CurCInfo.PgSize - 1 ) and $80; {Last data byte, bit 7}
  TimeOut := 1000;
  Repeat
   X := FiMemB( Pos + {255}CurCInfo.PgSize - 1 );    {Read last byte written}
   Wait( 50 );
   Dec( TimeOut );
  Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 ) or ( TimeOut<1 );
  if TimeOut < 1 then {v1.23}
   Begin
     FlashError := 2;
     Exit;
   End;
  X := FiMemB( Pos + {255}CurCInfo.PgSize - 1 );    {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
 If ( ( X and $A0 ) <> Ld ) then FlashError := 2; {programming error, timeout}
End;*)

Procedure IntelResetB;
Begin
 {Reset}
 FOMemB( ROMBase, $FF );
 FOMemB( ROMBase, $FF );
End;

(*Procedure IntelResetW;
Begin
 {Reset}
 FOMemW( ROMBase, $FFFF );
 FOMemW( ROMBase, $FFFF );
End;*)

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

(*Procedure IntelSecProgW( Pos, Data : LongInt );
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
End;*)

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

(*Procedure IntelSecEraseW( SAddr : LongInt );
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
End;*)

Procedure AMDSecProg( Pos, Data : LongInt );
Var
Attempt,
X, Y, Ld : Byte;
TimeOut  : Word;

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

      TimeOut := 5;   {should take no more than 14usec, we wait 50 max}
      X := FiMemB( Pos + Y );
      While ( ( {FIMemB( Pos + Y )}X and $80 ) <> ( Ld and $80 ) ) and
            ( ( {FIMemB( Pos + Y )}X and $20 ) = 0 ) and ( TimeOut > 0 ) do
       Begin
        Dec( TimeOut );
        Wait( 10 );
        X := FiMemB( Pos + Y );
       End;
(*      TimeOut:=5;
      X:=FIMemB(Pos+Y); {v1.24 Toggle bit method}
      while ((X and $40) <> (FIMemB(Pos+Y) and $40)) and (TimeOut>0) do
       begin
         X:=FIMemB(Pos+Y);
         Wait(10);
         Dec(TimeOut);
       end;*)

      X := FiMemB( Pos + Y );    {Read last byte written}
      Inc( Attempt );

     Until ( Attempt > 3 ) or  ( ( X and $80 ) = ( Ld and $80 ) );
     If ( ( X and $80 ) <> ( Ld and $80 ) ) then
      Begin
       FlashError := 2; {programming error, timeout}
       FlashCmd( $F0 ); {Reset chip}
       Exit;
      End;
    End;
  End;
 FlashCmd( $F0 ); {Reset chip}
End;

(*Procedure AMDSecProgW( Pos, Data : LongInt ); {v1.21}
Var
Attempt  : Byte;
X, Y, Ld : Word;
TimeOut  : Word;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemW( Data + Y + Y );
   If Ld <> $FFFF then
    Begin
     Repeat
      FlashCmdW( $A0 );
      FOMemW( Pos + Y + Y, Ld );

      TimeOut := 5;   {should take no more than 14usec, we wait 50 max}
      While ( ( FIMemW( Pos + Y + Y ) and $80 ) <> ( Ld and $80 ) ) and
            ( ( FIMemW( Pos + Y + Y ) and $20 ) = 0 ) and ( TimeOut > 0 ) do
       Begin
        Dec( TimeOut );
        Wait( 10 );
       End;

      X := FiMemW( Pos + Y + Y );    {Read last byte written}
      Inc( Attempt );

     Until ( Attempt > 3 ) or  ( ( X and $80 ) = ( Ld and $80 ) );
     If ( ( X and $80 ) <> ( Ld and $80 ) ) then
      Begin
       FlashError := 2; {programming error, timeout}
       FlashCmdW( $F0 ); {Reset chip}
       Exit;
      End;
    End;
  End;
 FlashCmdW( $F0 ); {Reset chip}
End;*)


Procedure AMDSecErase( SAddr : LongInt );
Var
Attempt,
X        : Byte;
TimeOut  : Word;
a:byte;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  FOMemB( ROMBase + $5555, $AA );
  FOMemB( ROMBase + $2AAA, $55 );
  FOMemB( SAddr, $30 ); {Erase sector containing address SAddr}

(*  TimeOut := 15;    {80 usec max normally, but waits 150usec to be sure}
  {Wait for erase to start}
  While ( ( FiMemB( SAddr ) and $08 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 10 );
   End;*)

  {Wait for erase to finish}
(*  TimeOut := 25000; {15 sec max normally, but waits 25 sec to be sure}
  X:=FiMemB(SAddr);
  While ( ( {FiMemB( SAddr )}X and $A0 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 10{00} );
    X:=FiMemB(SAddr);
   End;*)
  TimeOut:=25000;
  X:=FIMemB(SAddr); {v1.24 Toggle bit method}
  while ((X and $40) <> (FIMemB(SAddr) and $40)) and (TimeOut>0) do
   begin
     X:=FIMemB(SAddr);
     Wait(1000);
     Dec(TimeOut);
   end;

{  X := FiMemB( SAddr );}
  Inc( Attempt );
  FlashCmd( $F0 ); {Reset}
 Until ( Attempt > 3 ) or ( {( X and $80 ) <> 0}TimeOut>0 );
 If {( X and $80 ) = 0}TimeOut>0 then FlashError := 3; {erasing error}
End;

Procedure AMDBulkErase( SAddr : LongInt ); {v1.22}
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  FlashCmd( $10 );      {Erase confirm}

  TimeOut := 15;    {80 usec max normally, but waits 150usec to be sure}
  {Wait for erase to start}
  While ( ( FiMemB( SAddr ) and $08 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 10 );
   End;

  {Wait for erase to finish}
  TimeOut := 25000; {15 sec max normally, but waits 25 sec to be sure}
  While ( ( FiMemB( SAddr ) and $A0 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 1000 );
   End;

  X := FiMemB( SAddr );
  Inc( Attempt );
  FlashCmd( $F0 ); {Reset}
 Until ( Attempt > 3 ) or ( ( X and $80 ) <> 0 );
 If ( X and $80 ) = 0 then FlashError := 3; {erasing error}
End;


(*Procedure AMDSecEraseW( SAddr : LongInt ); {v1.21}
Var
Attempt  : Byte;
X        : Word;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FlashCmdW( $80 );      {Erase setup}
  FOMemW( ROMBase + $5555, $AA );
  FOMemW( ROMBase + $2AAA, $55 );
  FOMemW( SAddr, $30 ); {Erase sector containing address SAddr}

  TimeOut := 15;    {80 usec max normally, but waits 150usec to be sure}
  {Wait for erase to start}
  While ( ( FiMemW( SAddr ) and $08 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 10 );
   End;

  {Wait for erase to finish}
  TimeOut := 25000; {15 sec max normally, but waits 25 sec to be sure}
  While ( ( FiMemW( SAddr ) and $A0 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 1000 );
   End;

  X := FiMemW( SAddr );
  Inc( Attempt );
  FlashCmdW( $F0 ); {Reset}
 Until ( Attempt > 3 ) or ( ( X and $80 ) <> 0 );
 If ( X and $80 ) = 0 then FlashError := 3; {erasing error}
End;*)


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
   D := FIMemB( Data + Y{Pos} ); {v1.22 _VERY_ NASTY BUG FIXED}
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

(*Procedure AMDFlashWriteW( Pos, Data : LongInt ); {v1.21}
Var
X, Y, D : Word;
Attempt : Byte;


Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   D := FIMemW( Data + Y ); {v1.22 _VERY_ NASTY BUG FIXED}
   If D <> $FFFF then
    Begin
     Repeat
      FOMemW( Pos + Y + Y, $40 );
      FOMemW( Pos + Y + Y, D );
      Wait( 10 );
      FOMemW( Pos + Y + Y, $C0 );
      Wait( 6 );
      X := FIMemW( Pos + Y + Y );
      Inc( Attempt );
     Until ( X = D ) or ( Attempt >= 25 );
     If Attempt >= 25 then
      Begin
       IntelResetW;
       FlashError := 2;
       Exit;
      End;
    End;
  End;
 IntelResetW;
End;*)

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

(*Procedure AMDFlashEraseW( SAddr : LongInt ); {v1.21}
Var
Attempt : Word;
Addr    : LongInt;
D       : Word;

Begin
 Attempt := 0;
 Repeat
  FOMemW( ROMBase, $20 );
  FOMemW( ROMBase, $20 );
  Wait( 10000 );
  For Addr := 0 to ( LongInt( CurCInfo.Size ) shl 10 ) - 1 do
   Begin
    FOMemW( ROMBase + Addr + Addr, $A0 );
    Wait( 6 );
    D := FIMemW( ROMBase + Addr + Addr );
    If D <> $FFFF then Break;
   End;
  Inc( Attempt );
 Until ( D = $FFFF ) or ( Attempt >= 1000 );
 If ( D <> $FFFF ) then FlashError := 3;
 IntelResetW;
End;*)

{Begin}
End.