Unit GenFlash;
{v1.29 - Flash_Read, Flash_Write}

Interface
{v1.24 16-bit removed}
Procedure GenPageProgB( Pos, Data : LongInt ); Far;
Procedure IntelResetB;
Procedure IntelSecProg( Pos, Data : LongInt ); Far;
Procedure IntelSecErase( SAddr : LongInt ); Far;
Procedure IntelSecErase2( SAddr : LongInt ); Far;
Procedure AMDSecProg( Pos, Data : LongInt ); Far;
Procedure AMDSecErase( SAddr : LongInt ); Far;
Procedure AMDBulkErase( SAddr : LongInt ); Far; {v1.22}
Procedure AMDEmbdErase( SAddr : LongInt ); Far;
Procedure AMDEmbdWrite( Pos, Data : LongInt ); Far;
Procedure AMDFlashWrite( Pos, Data : LongInt ); Far;
Procedure AMDFlashErase( SAddr : LongInt ); Far;

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
  Flash_WriteBlock(Data,Pos,CurCInfo.PgSize);
  Wait( 5000 {300});  {Wait 5ms} {v1.22 300us->5ms}

  Ld := FiMemB( Data + CurCInfo.PgSize - 1 ) and $80; {Last data byte, bit 7}
  TimeOut := 1000;
  Repeat
   X:=Flash_Read(Pos+CurCInfo.PgSize-1); {Read last byte written}
   Wait( 50 );
   Dec( TimeOut );
  Until ( ( X and $80 ) = Ld ) {or ( ( X and $20 ) <> 0 )} or ( TimeOut<1 );
  if TimeOut < 1 then {v1.23}
   Begin
     FlashError := 2;
{     Exit;}
   End;
  X:=Flash_Read(Pos+CurCInfo.PgSize-1); {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $80 {A0}) = Ld );
 If ( ( X and $80 {A0}) <> Ld ) then FlashError := 2; {programming error, timeout}
End;

Procedure IntelResetB;
Begin
 Flash_Write(0,$FF);
 Flash_Write(0,$FF);
End;

Procedure IntelSecProg( Pos, Data : LongInt );
Var
Attempt,X,Y,Ld: Byte;
TimeOut: Word; {v1.30}
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
      Flash_Write(Pos+Y,$40);    {Write setup}
      Flash_Write(Pos+Y,Ld);     {Write data}
      {Wait for programming to finish}
      TimeOut:=100;
      Repeat
       X:=Flash_Read(Pos+Y);
       Wait(10);
       Dec(TimeOut);
      Until ((X and $80)<>0) or (TimeOut<1);
      if TimeOut<1 then FlashError:=2;
      Inc( Attempt );
      X := Flash_Read(Pos+Y);
      Flash_Write(Pos+Y,$50);    {Clear status}
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

Procedure IntelSecErase( SAddr : LongInt );
Var
Attempt,
X        : Byte;
TimeOut:Word;
Begin
 Attempt := 0;
 Repeat
  Flash_Write(SAddr,$20); {Erase setup}
  Flash_Write(SAddr,$D0); {Erase confirm}
  {Wait for erase to finish}
  TimeOut:=65000;
  Repeat
   X := Flash_Read(SAddr);
   Wait(1000);
   Dec(TimeOut);
  Until ((X and $80)<>0) or (TimeOut<1);
  if TimeOut<1 then FlashError:=3;
  Inc( Attempt );
  X := Flash_Read(Saddr);
  Flash_Write(SAddr,$50); {Clear status}
 Until ( Attempt > 3 ) or ( ( X and $B8 ) = $80 );
 If ( X and $B8 ) <> $80 then FlashError := 3; {erasing error}
 IntelResetB;
End;

Procedure IntelSecErase2( SAddr : LongInt ); {erase setup $21} {v1.34}
Var
Attempt,
X        : Byte;
TimeOut:Word;
Begin
 Attempt := 0;
 Repeat
  Flash_Write(SAddr,$21); {Erase setup}
  Flash_Write(SAddr,$D0); {Erase confirm}
  {Wait for erase to finish}
  TimeOut:=65000;
  Repeat
   X := Flash_Read(SAddr);
   Wait(1000);
   Dec(TimeOut);
  Until ((X and $80)<>0) or (TimeOut<1);
  if TimeOut<1 then FlashError:=3;
  Inc( Attempt );
  X := Flash_Read(Saddr);
  Flash_Write(SAddr,$50); {Clear status}
 Until ( Attempt > 3 ) or ( ( X and $B8 ) = $80 );
 If ( X and $B8 ) <> $80 then FlashError := 3; {erasing error}
 IntelResetB;
End;


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
      FlashCmd($A0);
      Flash_Write(Pos+Y,Ld);

      TimeOut := 30;   {should take no more than 200usec, we wait 300 max}
      X := Flash_Read(Pos+Y);
      While ( ( X and $80 ) <> ( Ld and $80 ) ) and
            ( ( X and $20 ) = 0 ) and ( TimeOut > 0 ) do
       Begin
        Dec( TimeOut );
        Wait( 10 );
        X := Flash_Read(Pos+Y);
       End;
(*      TimeOut:=30;
      X:=FIMemB(Pos+Y); {v1.24 Toggle bit method}
      while ((X and $40) <> (FIMemB(Pos+Y) and $40)) and (TimeOut>0) do
       begin
         X:=FIMemB(Pos+Y);
         Wait(10);
         Dec(TimeOut);
       end;*)

      X := Flash_Read(Pos+Y);    {Read last byte written}
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

Procedure AMDSecErase( SAddr : LongInt );
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  Flash_Write($5555,$AA);
  Flash_Write($2AAA,$55);
  Flash_Write(SAddr,$30); {Erase sector containing address SAddr}

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
  X:=Flash_Read(SAddr); {v1.24 Toggle bit method}
  while ((X and $40) <> (Flash_Read(SAddr) and $40)) and (TimeOut>0) do
   begin
     X:=Flash_Read(SAddr);
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
  While ( (Flash_Read(SAddr) and $08 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 10 );
   End;

  {Wait for erase to finish}
  TimeOut := 40000; {35 sec max normally, but waits 40 sec to be sure}
  While ( (Flash_Read(SAddr) and $A0 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 1000 );
   End;

  X:=Flash_Read(SAddr);
  Inc( Attempt );
  FlashCmd( $F0 ); {Reset}
 Until ( Attempt > 3 ) or ( ( X and $80 ) <> 0 );
 If ( X and $80 ) = 0 then FlashError := 3; {erasing error}
End;

Procedure AMDEmbdErase( SAddr : LongInt );
var TimeOut:Word; {v1.30}
Begin
 Flash_Write(0,$30);
 Flash_Write(0,$30);
 TimeOut:=25000;
 Repeat
   Wait(1000);
   Dec(TimeOut);
 Until ((Flash_Read(0) and $80)<>0) or (TimeOut<1);
 if TimeOut<1 then FlashError:=3;
End;

Procedure AMDEmbdWrite( Pos, Data : LongInt );
Var
Attempt,
X, Y, Ld : Byte;
TimeOut:Word; {v1.30}
Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemB( Data + Y );
   If Ld <> $FF then
    Begin
     Repeat
      Flash_Write(Pos+Y,$10);
      Flash_Write(Pos+Y,Ld);
      Ld := Ld and $80; {Last data byte, bit 7}
      TimeOut:=1000;
      Repeat
       X:=Flash_Read(Pos+Y);    {Read last byte written}
       Wait(100);
       Dec(TimeOut);
      Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 ) or (TimeOut<1);
      if TimeOut<1 then FlashError:=2;
      X:=Flash_Read(Pos+Y);    {Read last byte written}
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
      Flash_Write(Pos+Y,$40);
      Flash_Write(Pos+Y,D);
      Wait( 10 );
      Flash_Write(Pos+Y,$C0);
      Wait( 6 );
      X:=Flash_Read(Pos+Y);
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
  Flash_Write(0,$20);
  Flash_Write(0,$20);
  Wait( 10000 );
  For Addr := 0 to ( LongInt( CurCInfo.Size ) shl 10 ) - 1 do
   Begin
    Flash_Write(Addr,$A0);
    Wait( 6 );
    D:=Flash_Read(Addr);
    If D <> $FF then Break;
   End;
  Inc( Attempt );
 Until ( D = $FF ) or ( Attempt >= 1000 );
 If ( D <> $FF ) then FlashError := 3;
 IntelResetB;
End;

{Begin}
End.