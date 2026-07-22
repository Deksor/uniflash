
Unit SHARP; { Unit to communicate with SHARP chips } {v1.37}

Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure SHARPSecProg( Pos, Data : LongInt );
Far;

Var TimeOut: Word;
  X: Byte;
Begin
  {Unprotect}
  Flash_Write(0,$60);
  Flash_Write(0,$DB);
  If (Flash_Read(0) And $BA) <> $80 Then
    Begin
      Wait(10);
      If (Flash_Read(0) And $BA) <> $80 Then FlashError := 2;
    End;
  {Clear top boot block lock bits}
  If Pos>=LongInt(CurCInfo.Size) shl 10-$10000 Then
    Begin
      Flash_Write(0,$60);
      Flash_Write($1F0000,$D0);
      TimeOut := 6000; {this might take upto 5 seconds, add one to be sure}
      Repeat
        X := Flash_Read($1F0000);
        Wait(1000);
        Dec(TimeOut);
      Until ((X And $80)<>0) Or (TimeOut<1);
      If (TimeOut<1) Or (X And $BA <> $80) Then FlashError := 2;
    End;
  IntelSecProg(Pos,Data);
  {Protect}
  Flash_Write(0,$60);
  Flash_Write(0,$BB);
  If (Flash_Read(0) And $BA) <> $80 Then
    Begin
      Wait(10);
      If (Flash_Read(0) And $BA) <> $80 Then FlashError := 2;
    End;
End;

Procedure SHARPSecErase( SAddr: LongInt );
Far;

Var TimeOut: Word;
  X: Byte;
Begin
  {Unprotect}
  Flash_Write(0,$60);
  Flash_Write(0,$DB);
  If (Flash_Read(0) And $BA) <> $80 Then
    Begin
      Wait(10);
      If (Flash_Read(0) And $BA) <> $80 Then FlashError := 3;
    End;
  {Clear top boot block lock bits}
  If SAddr>=LongInt(CurCInfo.Size) shl 10-$10000 Then
    Begin
      Flash_Write(0,$60);
      Flash_Write($1F0000,$D0);
      TimeOut := 6000; {this might take upto 5 seconds, add one to be sure}
      Repeat
        X := Flash_Read($1F0000);
        Wait(1000);
        Dec(TimeOut);
      Until ((X And $80)<>0) Or (TimeOut<1);
      If (TimeOut<1) Or (X And $BA <> $80) Then FlashError := 3;
    End;
  IntelSecErase(SAddr);
  {Protect}
  Flash_Write(0,$60);
  Flash_Write(0,$BB);
  If (Flash_Read(0) And $BA) <> $80 Then
    Begin
      Wait(10);
      If (Flash_Read(0) And $BA) <> $80 Then FlashError := 3;
    End;
End;

Const 
  ProgSHARPSecProg : Fl_Program = @SHARPSecProg;
  EraseSHARPSecErase : Fl_Erase = @SHARPSecErase;

Function SHARPIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean;
Far;
Begin
  SHARPIdChip := False;
  With CInfo Do
    Begin
      Case DevId Of 
        $C9 :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgSHARPSecProg );
                SetChipErase( Erase, EraseSHARPSecErase );
                Sectors[ 0, 0 ] := 15; {15 x 64k}
                Sectors[ 0, 1 ] := 512;
                Sectors[ 1, 0 ] := 8; {8 x 8k}
                Sectors[ 1, 1 ] := 64;
                Size := 1024;
                Name := ConstPtr( 'LHF00L02/6/7/3.3V (LPC)' );
              End;
        $CF :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgSHARPSecProg );
                SetChipErase( Erase, EraseSHARPSecErase );
                Sectors[ 0, 0 ] := 15; {15 x 64k}
                Sectors[ 0, 1 ] := 512;
                Sectors[ 1, 0 ] := 8; {8 x 8k}
                Sectors[ 1, 1 ] := 64;
                Size := 1024;
                Name := ConstPtr( 'LHF00L03/4/5/3.3V (FWH)' );
              End;
        $CA :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgSHARPSecProg );
                SetChipErase( Erase, EraseSHARPSecErase );
                Sectors[ 0, 0 ] := 16; {16 x 4k}
                Sectors[ 0, 1 ] := 32;
                Sectors[ 1, 0 ] := 30; {30 x 64k}
                Sectors[ 1, 1 ] := 512;
                Sectors[ 2, 0 ] := 8; {8 x 8k}
                Sectors[ 2, 1 ] := 64;
                Size := 2048;
                Name := ConstPtr( 'LHF00L01/3.3V (LPC)' );
              End;
        Else Exit;
      End;
    End;
  CInfo.Manuf := ConstPtr( 'SHARP' );
  SHARPIdChip := True;
End;

Const 
  IdSHARPIdChip : Fl_IdChip = @SHARPIdChip;


Begin
  RegisterFlashManu( $B0, IdSHARPIdChip );
End.
