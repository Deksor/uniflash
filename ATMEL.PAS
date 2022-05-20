Unit Atmel; { Unit to communicate with Atmel chips }
Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure AtBulkErase( SAddr : LongInt ); Far;
Begin
 FlashCmd( $80 );
 FlashCmd( $10 );
 Repeat Until ( FIMemB( ROMBase ) and $80 ) <> 0;
End;

Procedure AtByteProg( Pos, Data : LongInt ); Far;
Var
X : Word;
D : Byte;

Begin
 For X := 0 to CurCInfo.PgSize - 1 do
  Begin
   FlashCmd( $A0 );
   D := FIMemB( Data + X );
   FOMemB( Pos + X, D );
   Repeat Until ( FIMemB( Pos + X ) and $80 ) = ( D and $80 );
  End;
End;

Procedure AtmelPageProgB( Pos, Data : LongInt ); Far;
Var
Attempt,
Ld, X   : Byte;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 ); {v1.28}
  MoveLinBlockB( Data, Pos, CurCInfo.PgSize );
  Wait( 10000 );  {Wait 10ms} {v1.22 750us->10ms}

  Ld := FiMemB( Data + 127 ) and $80; {Last data byte, bit 7}
  Repeat
   X := FiMemB( Pos + 127 );    {Read last byte written}
  Until ( ( X and $80 ) = Ld ) or ( ( X and $20 ) <> 0 );
  X := FiMemB( Pos + 127 );    {Read last byte written}
  Inc( Attempt );
 Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
 If ( ( X and $A0 ) <> Ld ) then FlashError := 2; {programming error, timeout}
End;


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
           Progr  := AtmelPageProgB;
          End;
    $BC : Begin
           Name := ConstPtr( 'AT29LV256/3V' );
           Flags := 1; {page mode}
           PgSize := 64;
           Size := 32;
           Progr  := AtmelPageProgB;
          End;
    $5D : Begin
           Name := ConstPtr( 'AT29C512/5V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 64;
           Progr  := AtmelPageProgB;
          End;
    $3D : Begin {v1.21}
           Name := ConstPtr( 'AT29LV512/3V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 64;
           Progr  := AtmelPageProgB;
          End;
    $03 : Begin {v1.21}
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
           Progr  := AtmelPageProgB;
          End;
    $17 : Begin {v1.21 Moved AT49BV010/2.7V here - was BAD $05}
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
           Progr  := AtmelPageProgB;
          End;
    $04 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 128;
           Name := ConstPtr( 'AT49x001(N)T series (5V/3V/2.7V)' ); {Top Boot Block}
          End;
    $05 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 32k}
           Sectors[ 2, 1 ] := 256;
           Sectors[ 3, 0 ] := 1;  {1 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 128;
           Name := ConstPtr( 'AT49x001(N) series (5V/3V/2.7V)' ); {Bottom Boot Block}
          End;
    $DA : Begin
           Name := ConstPtr( 'AT29C020(A)/5V' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 256;
           Progr  := AtmelPageProgB;
          End;
    $BA : Begin
           Name := ConstPtr( 'AT29xV020 series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 256;
           Progr  := AtmelPageProgB;
          End;
    $0B : Begin
           Name := ConstPtr( 'AT49x020 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $08 : Begin {v1.21 FIXED -> support sectors}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 256;
           Name := ConstPtr( 'AT49x002(N)T series (5V/3V/2.7V)' ); {Top Boot Block}
          End;
    $07 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 768;
           Sectors[ 3, 0 ] := 1;  {1 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 256;
           Name := ConstPtr( 'AT49x002(N) series (5V/3V/2.7V)' ); {Bottom Boot Block}
          End;
    $A4 : Begin
           Name := ConstPtr( 'AT29C040A/5V' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 512;
           Progr  := AtmelPageProgB;
          End;
    $C4 : Begin
           Name := ConstPtr( 'AT29xV040A series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 512;
           Progr  := AtmelPageProgB;
          End;
    $13 : Begin
           Name := ConstPtr( 'AT49x040 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 512;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $92 : Begin {v1.21} {A has different sectors -> using bulk erase}
           Name := ConstPtr( 'AT49x4096(A) series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 512;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $22 : Begin
           Name := ConstPtr( 'AT49x008(A) series (5V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $21 : Begin {v1.21}
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
    $4A : Begin {v1.21} {weird sectors -> using bulk erase}
           Name := ConstPtr( 'AT49x8011T series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $CB : Begin {v1.21} {weird sectors -> using bulk erase}
           Name := ConstPtr( 'AT49x8011 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $C2 : Begin {v1.21}
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
    $C0 : Begin {v1.21}
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
    $C9 : Begin {v1.21}
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
    $C8 : Begin {v1.21}
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