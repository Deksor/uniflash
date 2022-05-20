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

Procedure AtWordProg( Pos, Data : LongInt ); Far;
Var
X, D : Word;

Begin
 For X := 0 to ( CurCInfo.PgSize shr 1 ) - 1 do
  Begin
   FlashCmd( $A0 );
   D := FIMemW( Data + X + X );
   FOMemW( Pos + X + X, D );
   Repeat Until ( FIMemW( Pos + X + X ) and $8000 ) = ( D and $8000 );
  End;
End;

Function AtmelIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 AtmelIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $05 : Begin
           Name := ConstPtr( 'AT49BV010/2.7V' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 128;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $07 : Begin
           Name := ConstPtr( 'AT49F1025/5V' );
           Flags := 2; {bulk erase}
           PgSize := 256; {whatever}
           Size := 128;
           Progr := AtWordProg;
           Erase := AtBulkErase;
          End;
    $08 : Begin { Rainbow }
           Name := ConstPtr( 'AT49F002(N)T/5V' ); { N has no RESET pin }
           Flags := 2; {bulk erase}
           PgSize := 128; { whatever }
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $0B : Begin
           Name := ConstPtr( 'AT49x020 series (5V/3V/2.7V)' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 256;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $13 : Begin
           Name := ConstPtr( 'AT49F040/5V' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 512;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $17 : Begin
           Name := ConstPtr( 'AT49F010/5V' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 128;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $23 : Begin
           Name := ConstPtr( 'AT49F080/5V' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;
    $24 : Begin
           Name := ConstPtr( 'AT29C040A/5V' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 512;
           Progr  := GenPageProgBAtmel;
          End;
    $25 : Begin
           Name := ConstPtr( 'AT29C1024/5V' );
           Flags := 1; {page mode}
           PgSize := 256; {128 words!}
           Size := 128;
           Progr := GenPageProgWAtmel;
          End;
    $26 : Begin
           Name := ConstPtr( 'AT29LV1024/3V' );
           Flags := 1; {page mode}
           PgSize := 256; {128 words!}
           Size := 128;
           Progr  := GenPageProgWAtmel;
          End;
    $27 : Begin
           Name := ConstPtr( 'AT49F080T/5V' );
           Flags := 2; {bulk erase}
           PgSize := 128; {whatever}
           Size := 1024;
           Progr := AtByteProg;
           Erase := AtBulkErase;
          End;

    $35 : Begin
           Name := ConstPtr( 'AT29xV010A series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 128;
           Progr  := GenPageProgBAtmel;
          End;
    $3A : Begin
           Name := ConstPtr( 'AT29xV020 series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 256;
           Progr  := GenPageProgBAtmel;
          End;
    $3C : Begin
           Name := ConstPtr( 'AT29LV256/3V' );
           Flags := 1; {page mode}
           PgSize := 64;
           Size := 32;
           Progr  := GenPageProgBAtmel;
          End;
    $44 : Begin
           Name := ConstPtr( 'AT29xV040A series (3V/2.7V)' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 512;
           Progr  := GenPageProgBAtmel;
          End;
    $D5 and $7f : Begin
           Name := ConstPtr( 'AT29C010A/5V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 128;
           Progr  := GenPageProgBAtmel;
          End;
    $5A : Begin
           Name := ConstPtr( 'AT29C020/5V' );
           Flags := 1; {page mode}
           PgSize := 256;
           Size := 256;
           Progr  := GenPageProgBAtmel;
          End;
    $5C : Begin
           Name := ConstPtr( 'AT29C256/5V or AT29C257/5V' );
           Flags := 1; {page mode}
           PgSize := 64;
           Size := 32;
           Progr  := GenPageProgBAtmel;
          End;
    $5D : Begin
           Name := ConstPtr( 'AT29C512/5V' );
           Flags := 1; {page mode}
           PgSize := 128;
           Size := 64;
           Progr  := GenPageProgBAtmel;
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Atmel' );
 AtmelIdChip := True;
End;

Begin
 RegisterFlashManu( $1f, AtmelIdChip );
End.
