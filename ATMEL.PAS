Unit Atmel; { Unit to communicate with Atmel chips }
Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure AtBulkErase( SAddr : LongInt ); Far;
var TimeOut:Word; {v1.30}
Begin
 FlashCmd( $80 );
 FlashCmd( $10 );
 TimeOut:=20000;
 Repeat
   Wait(1000);
   Dec(TimeOut);
 Until ((Flash_Read(0) and $80)<>0) or (TimeOut<1); {v1.29}
 if TimeOut<1 then FlashError:=3;
End;

Procedure AtByteProg( Pos, Data : LongInt ); Far;
Var
X : Word;
D : Byte;
TimeOut:Word;
Begin
 For X := 0 to CurCInfo.PgSize - 1 do
  Begin
   FlashCmd( $A0 );
   D := FIMemB( Data + X );
   Flash_Write(Pos+X,D); {v1.29}
   TimeOut:=10;
   Repeat
     Wait(10);
     Dec(TimeOut);
   Until ((Flash_Read(Pos+X) and $80)=(D and $80)) or (TimeOut<1);
   if TimeOut<1 then FlashError:=2;
  End;
End;

Procedure AtmelPageProg( Pos, Data : LongInt ); Far;
Var
Attempt,
Ld, X   : Byte;
TimeOut:Word;
Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 ); {v1.28}
  Flash_WriteBlock(Data,Pos,CurCInfo.PgSize);
  Wait( 10000 );  {Wait 10ms} {v1.22 750us->10ms}

  Ld := FiMemB( Data + 127 ) and $80; {Last data byte, bit 7}
  TimeOut:=100;
  Repeat
   X := Flash_Read(Pos+127);    {Read last byte written}
   Wait(10);
   Dec(TimeOut);
  Until ((X and $80)=Ld) {or ((X and $20)<>0)} or (TimeOut<1);
  if TimeOut<1 then FlashError:=2;
  X := Flash_Read(Pos+127);    {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $80 ) = Ld );
 If ( ( X and $80 ) <> Ld ) then FlashError := 2; {programming error, timeout}
End;

Procedure AtmelSecProgFWH( Pos, Data : LongInt ); Far; {AT49LW080} {v1.34}
begin
  {Unprotect}
  FOMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) and $FC);
  IntelSecProg(Pos,Data);
  {Protect}
  FOMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) or $01);
end;

Procedure AtmelSecEraseFWH( SAddr: LongInt ); Far; {AT49LW080} {v1.34}
begin
  {Unprotect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) and $FC);
  IntelSecErase(SAddr);
  {Protect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) or $01);
end;

Procedure AtmelSecProgFWH2( Pos, Data : LongInt ); Far; {AT49LH002} {v1.34}
var X:LongInt;
begin
  {Unprotect}
  if Pos>=$30000 then
   begin
     X:=$FFBF0002;
     if Pos>=$38000 then X:=$FFBF8002;
     if Pos>=$3A000 then X:=$FFBFA002;
     if Pos>=$3C000 then X:=$FFBFC002;
   end
  else X:=Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  FOMemB(X,FIMemB(X) and $FC);
  FOMemB(X-$400000,FIMemB(X-$400000) and $FC);
  IntelSecProg(Pos,Data);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
  FOMemB(X-$400000,FIMemB(X-$400000) or $01);
end;

Procedure AtmelSecEraseFWH2( SAddr: LongInt ); Far; {AT49LH002} {v1.34}
var X:LongInt;
begin
  {Unprotect}
  if SAddr>=$30000 then
   begin
     X:=$FFBF0002;
     if SAddr>=$38000 then X:=$FFBF8002;
     if SAddr>=$3A000 then X:=$FFBFA002;
     if SAddr>=$3C000 then X:=$FFBFC002;
   end
  else X:=SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  FOMemB(X,FIMemB(X) and $FC);
  FOMemB(X-$400000,FIMemB(X-$400000) and $FC);
  IntelSecErase2(SAddr);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
  FOMemB(X-$400000,FIMemB(X-$400000) or $01);
end;

Procedure AtmelSecProgFWH3( Pos, Data : LongInt ); Far; {AT49LH004} {v1.34}
var X,X1:LongInt;
begin
  {Unprotect}
  if Pos>=$70000 then
   begin
     X:=$FFBF0002;
     X1:=$FF7F0002;
     if Pos>=$74000 then X1:=$FF7F4002;
     if Pos>=$76000 then X1:=$FF7F6002;
     if Pos>=$78000 then X1:=$FF7F8002;
   end
  else
   begin
     X:=Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
     X1:=Pos and $FFFF0000+$FF800002-LongInt(CurCInfo.Size) shl 10;
   end;
  FOMemB(X,FIMemB(X) and $FC);
  FOMemB(X1,FIMemB(X1) and $FC);
  IntelSecProg(Pos,Data);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
  FOMemB(X1,FIMemB(X1) or $01);
end;

Procedure AtmelSecEraseFWH3( SAddr: LongInt ); Far; {AT49LH004} {v1.34}
var X,X1:LongInt;
begin
  {Unprotect}
  if SAddr>=$70000 then
   begin
     X:=$FFBF0002;
     X1:=$FF7F0002;
     if SAddr>=$74000 then X1:=$FF7F4002;
     if SAddr>=$76000 then X1:=$FF7F6002;
     if SAddr>=$78000 then X1:=$FF7F8002;
   end
  else
   begin
     X:=SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
     X1:=SAddr and $FFFF0000+$FF800002-LongInt(CurCInfo.Size) shl 10;
   end;
  FOMemB(X,FIMemB(X) and $FC);
  FOMemB(X1,FIMemB(X1) and $FC);
  IntelSecErase2(SAddr);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
  FOMemB(X1,FIMemB(X1) or $01);
end;

Procedure AtmelSecProgFWH4( Pos, Data : LongInt ); Far; {AT49LH00B4} {v1.34}
var X:LongInt;
begin
  {Unprotect}
  if Pos<$10000 then
   begin
     X:=$FFB88002;
     if Pos<$8000 then X:=$FFB84002;
     if Pos<$4000 then X:=$FFB82002;
     if Pos<$2000 then X:=$FFB80002;
   end
  else X:=Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  FOMemB(X,FIMemB(X) and $FC);
  FOMemB(X-$400000,FIMemB(X-$400000) and $FC);
  IntelSecProg(Pos,Data);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
  FOMemB(X-$400000,FIMemB(X-$400000) or $01);
end;

Procedure AtmelSecEraseFWH4( SAddr: LongInt ); Far; {AT49LH00B4} {v1.34}
var X:LongInt;
begin
  {Unprotect}
  if SAddr<$10000 then
   begin
     X:=$FFB88002;
     if SAddr<$8000 then X:=$FFB84002;
     if SAddr<$4000 then X:=$FFB82002;
     if SAddr<$2000 then X:=$FFB80002;
   end
  else X:=SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  FOMemB(X,FIMemB(X) and $FC);
  FOMemB(X-$400000,FIMemB(X-$400000) and $FC);
  IntelSecErase2(SAddr);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
  FOMemB(X-$400000,FIMemB(X-$400000) or $01);
end;


Function AtmelIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 AtmelIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $DC : Begin
           Name := ConstPtr( 'AT29C256/5V or AT29C257/5V' );
           Flags := 1; {page mode}
           PgSize := 64;
           Size := 32;
           Progr  := AtmelPageProg;
          End;
    $BC : Begin
           Name := ConstPtr( 'AT29LV256/3V' );
           Flags := 1; {page mode}
           PgSize := 64;
           Size := 32;
           Progr  := AtmelPageProg;
          End;
    $5D : Begin
           Name := ConstPtr( 'AT29C512/5V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 64;
           Progr  := AtmelPageProg;
          End;
    $3D : Begin
           Name := ConstPtr( 'AT29LV512/3V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 64;
           Progr  := AtmelPageProg;
          End;
    $03 : Begin
           Name := ConstPtr( 'AT49x512 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 64;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $D5 : Begin
           Name := ConstPtr( 'AT29C010(A)/5V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 128;
           Progr  := AtmelPageProg;
          End;
    $17 : Begin
           Name := ConstPtr( 'AT49x010 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 128;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $35 : Begin
           Name := ConstPtr( 'AT29xV010(A) series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 128;
           Progr  := AtmelPageProg;
          End;
    $04 : Begin {v1.33 FIXED}
           Flags := 2; {bulk erase}
           PgSize := 128; { whatever }
           Size := 128;
           Progr := AtByteProg;
           Erase := AtBulkErase;
           Name := ConstPtr( 'AT49x001(A)(N)T series (5V/3V/2.7V)' ); {Top Boot Block}
          End;
    $05 : Begin {v1.33 FIXED}
           Flags := 2; {bulk erase}
           PgSize := 128; { whatever }
           Size := 128;
           Progr := AtByteProg;
           Erase := AtBulkErase;
           Name := ConstPtr( 'AT49x001(A)(N) series (5V/3V/2.7V)' ); {Bottom Boot Block}
          End;
    $DA : Begin
           Name := ConstPtr( 'AT29C020(A)/5V' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 256;
           Progr  := AtmelPageProg;
          End;
    $BA : Begin
           Name := ConstPtr( 'AT29xV020 series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 256;
           Progr  := AtmelPageProg;
          End;
    $0B : Begin
           Name := ConstPtr( 'AT49x020 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $08 : Begin {v1.33 FIXED}
           Flags := 2; {bulk erase}
           PgSize := 128; { whatever }
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
           Name := ConstPtr( 'AT49x002(A)(N)T series (5V/3V/2.7V)' ); {Top Boot Block}
          End;
    $07 : Begin {v1.33 FIXED}
           Flags := 2; {bulk erase}
           PgSize := 128; { whatever }
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
           Name := ConstPtr( 'AT49x002(A)(N) series (5V/3V/2.7V)' ); {Bottom Boot Block}
          End;
    $82 : Begin {A has different sectors -> using bulk erase} {v1.34}
           Name := ConstPtr( 'AT49x2048(A) series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $E9 : Begin {v1.34}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AtmelSecProgFWH2;
           Erase := AtmelSecEraseFWH2;
           Sectors[ 0, 0 ] := 3;  {3 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 256;
           Name := ConstPtr( 'AT49LH002/3.3V (LPC/FWH)' );
          End;
    $A4 : Begin
           Name := ConstPtr( 'AT29C040A/5V' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 512;
           Progr  := AtmelPageProg;
          End;
    $C4 : Begin
           Name := ConstPtr( 'AT29xV040A series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 512;
           Progr  := AtmelPageProg;
          End;
    $13 : Begin
           Name := ConstPtr( 'AT49x040(A) series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 512;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $92 : Begin {A has different sectors -> using bulk erase}
           Name := ConstPtr( 'AT49x4096(A) series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 512;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $ED : Begin {v1.34}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AtmelSecProgFWH4;
           Erase := AtmelSecEraseFWH4;
           Sectors[ 0, 0 ] := 2;  {2 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 1;  {1 x 16k}
           Sectors[ 1, 1 ] := 128;
           Sectors[ 2, 0 ] := 1;  {1 x 32k}
           Sectors[ 2, 1 ] := 256;
           Sectors[ 3, 0 ] := 7;  {7 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( 'AT49LH00B4/3.3V (LPC/FWH)' );
          End;
    $EE : Begin {v1.34}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AtmelSecProgFWH3;
           Erase := AtmelSecEraseFWH3;
           Sectors[ 0, 0 ] := 7;  {7 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 16k}
           Sectors[ 1, 1 ] := 128;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 32k}
           Sectors[ 3, 1 ] := 256;
           Size := 512;
           Name := ConstPtr( 'AT49LH004/3.3V (LPC/FWH)' );
          End;
    $22 : Begin
           Name := ConstPtr( 'AT49x008(A) series (5V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $21 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 992k}
           Sectors[ 0, 1 ] := 7936;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 16k}
           Sectors[ 2, 1 ] := 128;
           Size := 1024;
           Name := ConstPtr( 'AT49x008AT series (5V/2.7V)' ); {Top Boot Block}
          End;
    $23 : Begin
           Name := ConstPtr( 'AT49x080 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $27 : Begin
           Name := ConstPtr( 'AT49x080T series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $4A : Begin {weird sectors -> using bulk erase}
           Name := ConstPtr( 'AT49x8011T series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $CB : Begin {weird sectors -> using bulk erase}
           Name := ConstPtr( 'AT49x8011 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $E1 : Begin {v1.34}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AtmelSecProgFWH;
           Erase := AtmelSecEraseFWH;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( 'AT49LW080/3.3V (Firmware Hub)' );
          End;
    $C2 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 31; {31x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 2048;
           Name := ConstPtr( 'AT49x160/161(4)T series (5V/3V)' ); {Top Boot Block}
          End;
    $C0 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 31; {31x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'AT49x160/161(4) series (5V/3V)' ); {Bottom Boot Block}
          End;
    $C9 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 63; {63x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 4096;
           Name := ConstPtr( 'AT49BV320T/321T/3V' ); {Top Boot Block}
          End;
    $C8 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 63; {63x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 4096;
           Name := ConstPtr( 'AT49BV320/321/3V' ); {Bottom Boot Block}
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Atmel' );
 AtmelIdChip := True;
End;

Begin
 RegisterFlashManu( $1F, AtmelIdChip );
End.