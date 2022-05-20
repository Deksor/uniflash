Unit SHARP; { Unit to communicate with SHARP chips } {v1.37}
Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure SHARPSecProg( Pos, Data : LongInt ); Far;
var TimeOut:Word;
    X:Byte;
begin
  {Unprotect}
  Flash_Write(0,$60);
  Flash_Write(0,$DB);
  if (Flash_Read(0) and $BA) <> $80 then
   begin
     Wait(10);
     if (Flash_Read(0) and $BA) <> $80 then FlashError:=2;
   end;
  {Clear top boot block lock bits}
  if Pos>=LongInt(CurCInfo.Size) shl 10-$10000 then
   begin
     Flash_Write(0,$60);
     Flash_Write($1F0000,$D0);
     TimeOut:=6000; {this might take upto 5 seconds, add one to be sure}
     repeat
       X:=Flash_Read($1F0000);
       Wait(1000);
       Dec(TimeOut);
     until ((X and $80)<>0) or (TimeOut<1);
     if (TimeOut<1) or (X and $BA <> $80) then FlashError:=2;
   end;
  IntelSecProg(Pos,Data);
  {Protect}
  Flash_Write(0,$60);
  Flash_Write(0,$BB);
  if (Flash_Read(0) and $BA) <> $80 then
   begin
     Wait(10);
     if (Flash_Read(0) and $BA) <> $80 then FlashError:=2;
   end;
end;

Procedure SHARPSecErase( SAddr: LongInt ); Far;
var TimeOut:Word;
    X:Byte;
begin
  {Unprotect}
  Flash_Write(0,$60);
  Flash_Write(0,$DB);
  if (Flash_Read(0) and $BA) <> $80 then
   begin
     Wait(10);
     if (Flash_Read(0) and $BA) <> $80 then FlashError:=3;
   end;
  {Clear top boot block lock bits}
  if SAddr>=LongInt(CurCInfo.Size) shl 10-$10000 then
   begin
     Flash_Write(0,$60);
     Flash_Write($1F0000,$D0);
     TimeOut:=6000; {this might take upto 5 seconds, add one to be sure}
     repeat
       X:=Flash_Read($1F0000);
       Wait(1000);
       Dec(TimeOut);
     until ((X and $80)<>0) or (TimeOut<1);
     if (TimeOut<1) or (X and $BA <> $80) then FlashError:=3;
   end;
  IntelSecErase(SAddr);
  {Protect}
  Flash_Write(0,$60);
  Flash_Write(0,$BB);
  if (Flash_Read(0) and $BA) <> $80 then
   begin
     Wait(10);
     if (Flash_Read(0) and $BA) <> $80 then FlashError:=3;
   end;
end;

Function SHARPIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 SHARPIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $C9 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SHARPSecProg;
           Erase := SHARPSecErase;
           Sectors[ 0, 0 ] := 15; {15 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8; {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 1024;
           Name := ConstPtr( 'LHF00L02/6/7/3.3V (LPC)' );
          End;
    $CF : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SHARPSecProg;
           Erase := SHARPSecErase;
           Sectors[ 0, 0 ] := 15; {15 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8; {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 1024;
           Name := ConstPtr( 'LHF00L03/4/5/3.3V (FWH)' );
          End;
    $CA : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SHARPSecProg;
           Erase := SHARPSecErase;
           Sectors[ 0, 0 ] := 16; {16 x 4k}
           Sectors[ 0, 1 ] := 32;
           Sectors[ 1, 0 ] := 30; {30 x 64k}
           Sectors[ 1, 1 ] := 512;
           Sectors[ 2, 0 ] := 8; {8 x 8k}
           Sectors[ 2, 1 ] := 64;
           Size := 2048;
           Name := ConstPtr( 'LHF00L01/3.3V (LPC)' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'SHARP' );
 SHARPIdChip := True;
End;

Begin
 RegisterFlashManu( $B0, SHARPIdChip );
End.