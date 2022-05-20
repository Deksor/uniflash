Unit WinBond; { Unit to communicate with WinBond chips }
{ Boot Block Erase is not supported on some chips!!! }
Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure WBMainErase( SAddr : LongInt );Far; {v1.21}
Begin
 { Boot Block Erase is not supported, only Chip Erase can erase Boot Block
   (and it must not be protected) }
 if ( SAddr - ROMBase ) > $3FFF then
  AMDSecErase( $5555 ); { Erases Main Memory Block only, not Boot Block }
End;

Function WBIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 WBIdChip := False;
 With CInfo do
  Begin
   {Common info for some chips v1.21}
   Flags  := 1;   {page mode}
   PgSize := 128; {page size}
   Progr  := GenPageProgB;
   Case DevId of
    $C1 : Begin {W29EE011, W29C010, W29C010M, W29C011A}
           Name := ConstPtr( 'W29x010/011/5V series' );
           Size := 128;
          End;
    $45 : Begin
           {note: 2 write-protectable boot blocks}
           Name := ConstPtr( 'W29C020(C)/5V' );
           Size := 256;
          End;
    $46 : Begin {v1.21}
           {note: 2 write-protectable boot blocks}
           Name := ConstPtr( 'W29C040/5V' );
           PgSize := 256; {page size}
           Size := 512;
          End;
    $C8 : Begin
           Name := ConstPtr( 'W29EE512/5V' );
           Size := 64;
          End;
    $4F : Begin
           Name := ConstPtr( 'W29C101/102/5V' );
           PgSize := 256; {page size}
           Size := 128;
           Progr  := GenPageProgW; {v1.21}
          End;
    $0B : Begin {v1.21}
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
           Name := ConstPtr( 'W49F002U/5V' );
          End;
    $B0 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 256;
           Name := ConstPtr( 'W49V002(A)/3.3V' );
          End;
    $32 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 256;
           Name := ConstPtr( 'W49V002F(A)/3.3V (Firmware Hub)' );
          End;
    $2F : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProgW;
           Erase := WBMainErase;   {Boot Block Erase not supported}
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 1;  {1 x 112k}
           Sectors[ 1, 1 ] := 896;
           Size := 128;
           Name := ConstPtr( 'W29F102/5V or W49F102/5V' );
          End;
    $BF : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProgW;
           Erase := WBMainErase;   {Boot Block Erase not supported}
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 1;  {1 x 112k}
           Sectors[ 1, 1 ] := 896;
           Size := 128;
           Name := ConstPtr( 'W49L102/3.3V' );
          End;
    $AE : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProgW;
           Erase := AMDSecEraseW;
           Sectors[ 0, 0 ] := 3;  {3 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 1;  {1 x 208k}
           Sectors[ 1, 1 ] := 1664;
           Size := 256;
           Name := ConstPtr( 'W49F201/5V' );
          End;
    $3E : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProgW;
           Erase := AMDSecEraseW;
           Sectors[ 0, 0 ] := 3;  {3 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 1;  {1 x 208k}
           Sectors[ 1, 1 ] := 1664;
           Size := 256;
           Name := ConstPtr( 'W49L201/3.3V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Winbond' );
 WBIdChip := True;
End;

Begin
 RegisterFlashManu( $DA, WBIdChip );
End.