
Unit GenFlash;
{v1.29 - Flash_Read, Flash_Write}

Interface
{v1.24 16-bit removed}
Procedure GenPageProgB( Pos, Data : LongInt );
Far;
Procedure IntelResetB;
Procedure IntelSecProg( Pos, Data : LongInt );
Far;
Procedure IntelSecErase( SAddr : LongInt );
Far;
Procedure IntelSecErase2( SAddr : LongInt );
Far;
Procedure AMDSecProg( Pos, Data : LongInt );
Far;
Procedure AMDSecErase( SAddr : LongInt );
Far;
Procedure AMDBulkErase( SAddr : LongInt );
Far; {v1.22}
Procedure AMDEmbdErase( SAddr : LongInt );
Far;
Procedure AMDEmbdWrite( Pos, Data : LongInt );
Far;
Procedure AMDFlashWrite( Pos, Data : LongInt );
Far;
Procedure AMDFlashErase( SAddr : LongInt );
Far;

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

    Ld := FiMemB( Data + CurCInfo.PgSize - 1 ) And $80; {Last data byte, bit 7}
    TimeOut := 1000;
    Repeat
      X := Flash_Read(Pos+CurCInfo.PgSize-1); {Read last byte written}
      Wait( 50 );
      Dec( TimeOut );
    Until ( ( X And $80 ) = Ld ) {or ( ( X and $20 ) <> 0 )} Or ( TimeOut<1 );
    If TimeOut < 1 Then {v1.23}
      Begin
        FlashError := 2;
{     Exit;}
      End;
    X := Flash_Read(Pos+CurCInfo.PgSize-1); {Read last byte written}
    Inc( Attempt );
  Until ( Attempt > 3 ) Or  ( ( X And $80 {A0}) = Ld );
  If ( ( X And $80 {A0}) <> Ld ) Then FlashError := 2;
  {programming error, timeout}
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
  For Y := 0 To CurCInfo.PgSize - 1 Do
    Begin
      Attempt := 0;
      Ld := FIMemB( Data + Y );
   { Do not program FF, erase will result in all FF's so it's }
   { not necessary. Besides, 2*FF means reset ...             }

      If Ld <> $FF Then
        Begin
          Repeat
            Flash_Write(Pos+Y,$40);    {Write setup}
            Flash_Write(Pos+Y,Ld);     {Write data}
      {Wait for programming to finish}
            TimeOut := 100;
            Repeat
              X := Flash_Read(Pos+Y);
              Wait(10);
              Dec(TimeOut);
            Until ((X And $80)<>0) Or (TimeOut<1);
            If TimeOut<1 Then FlashError := 2;
            Inc( Attempt );
            X := Flash_Read(Pos+Y);
            Flash_Write(Pos+Y,$50);    {Clear status}
          Until ( Attempt > 3 ) Or  ( ( X And $98 ) = $80 );
          If ( ( X And $98 ) <> $80 ) Then
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
  TimeOut: Word;
Begin
  Attempt := 0;
  Repeat
    Flash_Write(SAddr,$20); {Erase setup}
    Flash_Write(SAddr,$D0); {Erase confirm}
  {Wait for erase to finish}
    TimeOut := 65000;
    Repeat
      X := Flash_Read(SAddr);
      Wait(1000);
      Dec(TimeOut);
    Until ((X And $80)<>0) Or (TimeOut<1);
    If TimeOut<1 Then FlashError := 3;
    Inc( Attempt );
    X := Flash_Read(Saddr);
    Flash_Write(SAddr,$50); {Clear status}
  Until ( Attempt > 3 ) Or ( ( X And $B8 ) = $80 );
  If ( X And $B8 ) <> $80 Then FlashError := 3; {erasing error}
  IntelResetB;
End;

Procedure IntelSecErase2( SAddr : LongInt ); {erase setup $21} {v1.34}

Var 
  Attempt,
  X        : Byte;
  TimeOut: Word;
Begin
  Attempt := 0;
  Repeat
    Flash_Write(SAddr,$21); {Erase setup}
    Flash_Write(SAddr,$D0); {Erase confirm}
  {Wait for erase to finish}
    TimeOut := 65000;
    Repeat
      X := Flash_Read(SAddr);
      Wait(1000);
      Dec(TimeOut);
    Until ((X And $80)<>0) Or (TimeOut<1);
    If TimeOut<1 Then FlashError := 3;
    Inc( Attempt );
    X := Flash_Read(Saddr);
    Flash_Write(SAddr,$50); {Clear status}
  Until ( Attempt > 3 ) Or ( ( X And $B8 ) = $80 );
  If ( X And $B8 ) <> $80 Then FlashError := 3; {erasing error}
  IntelResetB;
End;


Procedure AMDSecProg( Pos, Data : LongInt );

Var 
  Attempt,
  X, Y, Ld : Byte;
  TimeOut  : Word;

Begin
  For Y := 0 To CurCInfo.PgSize - 1 Do
    Begin
      Attempt := 0;
      Ld := FIMemB( Data + Y );
      If Ld <> $FF Then
        Begin
          Repeat
            FlashCmd($A0);
            Flash_Write(Pos+Y,Ld);

            TimeOut := 30;   {should take no more than 200usec, we wait 300 max}
            X := Flash_Read(Pos+Y);
            While ( ( X And $80 ) <> ( Ld And $80 ) ) And ( TimeOut > 0 ) Do
{            ( ( X and $20 ) = 0 ) and} {v1.38 - breaks some W49F002U chips}
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

          Until ( Attempt > 3 ) Or  ( ( X And $80 ) = ( Ld And $80 ) );
          If ( ( X And $80 ) <> ( Ld And $80 ) ) Then
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
    TimeOut := 25000;
    X := Flash_Read(SAddr); {v1.24 Toggle bit method}
    While ((X And $40) <> (Flash_Read(SAddr) And $40)) And (TimeOut>0) Do
      Begin
        X := Flash_Read(SAddr);
        Wait(1000);
        Dec(TimeOut);
      End;

{  X := FiMemB( SAddr );}
    Inc( Attempt );
    FlashCmd( $F0 ); {Reset}
  Until ( Attempt > 3 ) Or ( {( X and $80 ) <> 0}TimeOut>0 );
  If {( X and $80 ) = 0}TimeOut>0 Then FlashError := 3; {erasing error}
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
    While ( (Flash_Read(SAddr) And $08 ) = 0 ) And ( TimeOut > 0 ) Do
      Begin
        Dec( TimeOut );
        Wait( 10 );
      End;

  {Wait for erase to finish}
    TimeOut := 40000; {35 sec max normally, but waits 40 sec to be sure}
    While ( (Flash_Read(SAddr) And $A0 ) = 0 ) And ( TimeOut > 0 ) Do
      Begin
        Dec( TimeOut );
        Wait( 1000 );
      End;

    X := Flash_Read(SAddr);
    Inc( Attempt );
    FlashCmd( $F0 ); {Reset}
  Until ( Attempt > 3 ) Or ( ( X And $80 ) <> 0 );
  If ( X And $80 ) = 0 Then FlashError := 3; {erasing error}
End;

Procedure AMDEmbdErase( SAddr : LongInt );

Var TimeOut: Word; {v1.30}
Begin
  Flash_Write(0,$30);
  Flash_Write(0,$30);
  TimeOut := 25000;
  Repeat
    Wait(1000);
    Dec(TimeOut);
  Until ((Flash_Read(0) And $80)<>0) Or (TimeOut<1);
  If TimeOut<1 Then FlashError := 3;
End;

Procedure AMDEmbdWrite( Pos, Data : LongInt );

Var 
  Attempt,
  X, Y, Ld : Byte;
  TimeOut: Word; {v1.30}
Begin
  For Y := 0 To CurCInfo.PgSize - 1 Do
    Begin
      Attempt := 0;
      Ld := FIMemB( Data + Y );
      If Ld <> $FF Then
        Begin
          Repeat
            Flash_Write(Pos+Y,$10);
            Flash_Write(Pos+Y,Ld);
            Ld := Ld And $80; {Last data byte, bit 7}
            TimeOut := 1000;
            Repeat
              X := Flash_Read(Pos+Y);    {Read last byte written}
              Wait(100);
              Dec(TimeOut);
            Until ( ( X And $80 ) = Ld ) Or ( ( X And $20 ) <> 0 ) Or (TimeOut<1
                  );
            If TimeOut<1 Then FlashError := 2;
            X := Flash_Read(Pos+Y);    {Read last byte written}
            Inc( Attempt );
          Until ( Attempt > 3 ) Or  ( ( X And $A0 ) = Ld );
          If ( ( X And $A0 ) <> Ld ) Then
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
  For Y := 0 To CurCInfo.PgSize - 1 Do
    Begin
      Attempt := 0;
      D := FIMemB( Data + Y{Pos} ); {v1.22 _VERY_ NASTY BUG FIXED}
      If D <> $FF Then
        Begin
          Repeat
            Flash_Write(Pos+Y,$40);
            Flash_Write(Pos+Y,D);
            Wait( 10 );
            Flash_Write(Pos+Y,$C0);
            Wait( 6 );
            X := Flash_Read(Pos+Y);
            Inc( Attempt );
          Until ( X = D ) Or ( Attempt >= 25 );
          If Attempt >= 25 Then
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
    For Addr := 0 To ( LongInt( CurCInfo.Size ) shl 10 ) - 1 Do
      Begin
        Flash_Write(Addr,$A0);
        Wait( 6 );
        D := Flash_Read(Addr);
        If D <> $FF Then Break;
      End;
    Inc( Attempt );
  Until ( D = $FF ) Or ( Attempt >= 1000 );
  If ( D <> $FF ) Then FlashError := 3;
  IntelResetB;
End;

{Begin}
End.
