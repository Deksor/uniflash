Unit SST; { Unit to communicate with SST chips }
Interface

Implementation

Uses Flash, GenFlash, Tools;

{Unprotect 28x040(A) series}
Procedure SSTUnprot;
Begin
 Flash_Read($1823); {v1.29}
 Flash_Read($1820);
 Flash_Read($1822);
 Flash_Read($0418);
 Flash_Read($041B);
 Flash_Read($0419);
 Flash_Read($041A);
End;

{Protect 28x040(A) series}
Procedure SSTProt;
Begin
 Flash_Read($1823);
 Flash_Read($1820);
 Flash_Read($1822);
 Flash_Read($0418);
 Flash_Read($041B);
 Flash_Read($0419);
 Flash_Read($040A);
End;

Procedure SSTSecProg( Pos, Data : LongInt ); Far; {for 28x040(A) series}
Var
X        : Word;
Attempt,
Ld, Y    : Byte;

Begin
 {Unprotect chip}
 SSTUnprot;
 {Erase the sector}
 Flash_Write(0,$20);     {Erase sector setup}
 Flash_Write(Pos,$D0);   {Erase sector containing address Pos}
 Repeat
  X:=Flash_Read(Pos+127);    {Read last byte written}
 Until ( ( X and $A0 ) <> 0 );
 If ( ( X and $A0 ) <> $80 ) then
  Begin
   FlashError := 3; {erasing error}
   Flash_Write(0,$FF); {reset}
   SSTProt;
   Exit;
  End;
 {Erase verify}
 For X := 0 to {255}CurCInfo.PgSize - 1 do {v1.21 PgSize}
  If Flash_Read(Pos+X)<>$FF then
   Begin
    FlashError := 3; {erasing error}
    Flash_Write(0,$FF); {reset}
    SSTProt;
    Exit;
   End;
 {Program the sector}
 For X := 0 to {255}CurCInfo.PgSize - 1 do {v1.21 PgSize}
  Begin
   Attempt := 0;
   Repeat
    Ld := FIMemB( Data + X );
    Flash_Write(0,$10);       {program setup}
    Flash_Write(Pos+X,Ld);    {program data byte}
    Ld := Ld and $80;
    Repeat
     Y:=Flash_Read(Pos+X);    {Read last byte written}
    Until ( ( Y and $80 ) = Ld ) or ( ( Y and $20 ) <> 0 );
    Y:=Flash_Read(Pos+X);    {Read last byte written}
    Inc( Attempt );
   Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
   If ( ( X and $A0 ) <> Ld ) then
    Begin
     FlashError := 2; {programming error, timeout}
     Flash_Write(0,$FF); {reset}
     SSTProt;
     Exit;
    End;
  End;
 {Enable protection again}
 SSTProt;
End;

Procedure SSTSecProg2( Pos, Data : LongInt ); Far; {for 29SF/VFxxx}
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 { Erase as AMDSecErase, but the command is $20 instead of $30 }
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  Flash_Write($5555,$AA);
  Flash_Write($2AAA,$55);
  Flash_Write(Pos,$20); {Erase sector containing address Pos}

  TimeOut := 15;    {80 usec max normally, but waits 150usec to be sure}
  {Wait for erase to start}
  While ( (Flash_Read(Pos) and $08 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 10 );
   End;

  {Wait for erase to finish}
  TimeOut := 50; {25ms max normally, but waits 50ms to be sure}
  While ( (Flash_Read(Pos) and $A0 ) = 0 ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 1000 );
   End;

  X:=Flash_Read(Pos);
  Inc( Attempt );
  FlashCmd( $F0 ); {Reset}
 Until ( Attempt > 3 ) or ( ( X and $80 ) <> 0 );
 If ( X and $80 ) = 0 then FlashError := 3; {erasing error}
 AMDSecProg ( Pos, Data );
End;

Procedure SSTSecProgFWH( Pos, Data : LongInt ); Far; {49LF003A/4A/8A} {v1.26}
begin
  {Unprotect}
  FOMemB(Pos and $FFFF0000+$FFC00002-CurCInfo.Size shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-CurCInfo.Size shl 10) and $FC);
  AMDSecProg(Pos,Data);
  {Protect}
  FOMemB(Pos and $FFFF0000+$FFC00002-CurCInfo.Size shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-CurCInfo.Size shl 10) or $01);
end;

Procedure SSTSecEraseFWH( SAddr: LongInt ); Far; {49LF003A/4A/8A} {v1.26}
begin
  {Unprotect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10) and $FC);
  AMDSecErase(SAddr);
  {Protect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10) or $01);
end;

Procedure SSTSecProgFWH2( Pos, Data : LongInt ); Far; {49LF002A} {v1.26}
var X:LongInt;
begin
  X:=Pos and $FFFF8000+$FFC00002-CurCInfo.Size shl 10;
  if (Pos>=$38000) and (Pos<$3C000) then X:=(Pos-$4000) and $FFFF8000+$FFC00002-CurCInfo.Size shl 10;
  {Unprotect}
  FOMemB(X,FIMemB(X) and $FC);
  AMDSecProg(Pos,Data);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
end;

Procedure SSTSecEraseFWH2( SAddr: LongInt ); Far; {49LF002A} {v1.26}
var X:LongInt;
begin
  X:=SAddr and $FFFF8000+$FFC00002-CurCInfo.Size shl 10;
  if (SAddr>=$38000) and (SAddr<$3C000) then X:=(SAddr-$4000) and $FFFF8000+$FFC00002-CurCInfo.Size shl 10;
  {Unprotect}
  FOMemB(X,FIMemB(X) and $FC);
  AMDSecErase(SAddr);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
end;


Function SSTIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 SSTIdChip := False;
 With CInfo do
  Begin
   {Common info for some chips v1.21}
   Flags  := 1;   {page mode}
   PgSize := 128; {page size}
   Progr  := GenPageProgB;
   Case DevId of
    $01 : Begin
           Name := ConstPtr( '28EE010/011/5V' );
           Size := 128;
          End;
    $5D : Begin
           Name := ConstPtr( '29EE512/5V' );
           Size := 64;
          End;
    $3D : Begin
           Name := ConstPtr( '29x512 series (3V/2.7V)' );
           Size := 64;
          End;
    $20 : Begin {v1.21}
           Name := ConstPtr( '29SF512/5V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 64;
          End;
    $21 : Begin {v1.21}
           Name := ConstPtr( '29VF512/2.7V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 64;
          End;
    $07 : Begin
           Name := ConstPtr( '29EE010/5V' );
           Size := 128;
          End;
    $08 : Begin
           Name := ConstPtr( '29x010 series (3V/2.7V)' );
           Size := 128;
          End;
    $22 : Begin {v1.21}
           Name := ConstPtr( '29SF010/5V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 128;
          End;
    $23 : Begin {v1.21}
           Name := ConstPtr( '29VF010/2.7V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 128;
          End;
    $10 : Begin
           Name := ConstPtr( '29EE020/5V' );
           Size := 256;
          End;
    $12 : Begin
           Name := ConstPtr( '29x020 series (3V/2.7V)' );
           Size := 256;
          End;
    $24 : Begin {v1.21}
           Name := ConstPtr( '29SF020/5V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 256;
          End;
    $25 : Begin {v1.21}
           Name := ConstPtr( '29VF020/2.7V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 256;
          End;
    $04 : Begin
           Name := ConstPtr( '28x040(A) series (5V/3V/2.7V)' );
           Flags  := 3;   {small sectors}
           PgSize := 256; {sector size}
           Progr  := SSTSecProg;
           Size := 512;
          End;
    $13 : Begin {v1.21}
           Name := ConstPtr( '29SF040/5V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 512;
          End;
    $14 : Begin {v1.21}
           Name := ConstPtr( '29VF040/2.7V' );
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg2;
           Size := 512;
          End;
    $B4 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 64;
           Name := ConstPtr( '39SF512/5V' );
          End;
    $D4 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 64;
           Name := ConstPtr( '39xF512 series (3V/2.7V)' );
          End;
    $B5 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 128;
           Name := ConstPtr( '39SF010(A)/5V' );
          End;
    $D5 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 128;
           Name := ConstPtr( '39xF010 series (3V/2.7V)' );
          End;
    $B6 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 64;  {64 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( '39SF020(A)/5V' );
          End;
    $D6 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 64;  {64 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( '39xF020 series (3V/2.7V)' );
          End;
    $B7 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( '39SF040/5V' );
          End;
    $D7 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( '39xF040 series (3V/2.7V)' );
          End;
    $D8 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 1024;
           Name := ConstPtr( '39xF080 series (3V/2.7V)' );
          End;
    $D9 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 2048;
           Name := ConstPtr( '39xF016 series (3V/2.7V)' );
          End;
    $57 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SSTSecProgFWH2;
           Erase := SSTSecEraseFWH2;
           Sectors[ 0, 0 ] := 64;  {64 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( '49LF002(A)/3.3V (Firmware Hub)' );
          End;
    $1B : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SSTSecProgFWH;
           Erase := SSTSecEraseFWH;
           Sectors[ 0, 0 ] := 96;  {96 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 384;
           Name := ConstPtr( '49LF003A/3.3V (Firmware Hub)' );
          End;
    $58 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( '49LF004/3.3V (Firmware Hub)' );
          End;
    $60 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SSTSecProgFWH;
           Erase := SSTSecEraseFWH;
           Sectors[ 0, 0 ] := 128;  {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( '49LF004A/3.3V (Firmware Hub)' );
          End;
    $59 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 1024;
           Name := ConstPtr( '49LF008/3.3V (Firmware Hub)' );
          End;
    $5A : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := SSTSecProgFWH;
           Erase := SSTSecEraseFWH;
           Sectors[ 0, 0 ] := 256;  {256 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 1024;
           Name := ConstPtr( '49LF008A/3.3V (Firmware Hub)' );
          End;
    $61 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 64;  {64 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( '49LF020/3V' );
          End;
    $1C : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 96;  {96 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 384;
           Name := ConstPtr( '49LF030/3V' );
          End;
    $51 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( '49LF040/3V' );
          End;
    $5B : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 1024;
           Name := ConstPtr( '49LF080/3V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'SST' );
 SSTIdChip := True;
End;

Begin
 RegisterFlashManu( $BF, SSTIdChip );
End.