Unit PMC; { Unit to communicate with PMC chips } {v1.21}
{v1.21 Manufacturer & Device ID codes are now not ANDed $7F !!}
{v1.21 New Sector table format}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Function PMCIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 PMCIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $1D : Begin
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
           Name := ConstPtr( 'Pm29F002T/5V' ); {Top Boot Block}
          End;
    $2D : Begin
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
           Name := ConstPtr( 'Pm29F002B/5V' ); {Bottom Boot Block}
          End;
    $1E : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 512;
           Name := ConstPtr( 'Pm29F004T/5V or Pm29LV104T/3.3V' ); {Top Boot Block}
          End;
    $2E : Begin
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
           Sectors[ 3, 0 ] := 3;  {3 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 512;
           Name := ConstPtr( 'Pm29F004B/5V or Pm29LV104B/3.3V' ); {Bottom Boot Block}
          End;
    $1B : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 64;
           Name := ConstPtr( 'Pm39LV512R/3.3V' );
          End;
    $1C : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 128;
           Name := ConstPtr( 'Pm39LV010R/3.3V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'PMC' );
 PMCIdChip := True;
End;

Begin
 RegisterFlashManu( $9D, PMCIdChip );
End.