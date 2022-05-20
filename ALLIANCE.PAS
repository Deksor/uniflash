Unit Alliance; { Unit to communicate with Alliance chips } {v1.21}
{v1.21 Manufacturer & Device ID codes are now not ANDed $7F !!}
{v1.21 New Sector table format}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Function AllianceIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 AllianceIdChip := False;
 With CInfo do
  Begin
   Case DevId of
(*    $04 : Begin
     It has totally weird commands, even the ID command is nonstandard
     It has commands like Converge, Verify-0, Verify-1, but the datasheet
     is crappy and doesn't say, what these commands do. There's even no
     algorithm in the datasheet.
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := ????;
           Erase := ????;
           Sectors[ 0, 0 ] := 4;  {4 x 32k}
           Sectors[ 0, 1 ] := 15;
           Size := 128;
           Name := ConstPtr( 'AS29F010/5V' );
          End;*)
    $B0,
    $51 : Begin
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
           case DevId of
            $B0 : Name := ConstPtr( 'AS29F002T/5V' ); {Top Boot Block}
            $51 : Name := ConstPtr( 'AS29F200T/5V' );
           End;
          End;
    $34,
    $57 : Begin
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
           Sectors[ 3, 0 ] := 3;  {3 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 256;
           case DevId of
            $34 : Name := ConstPtr( 'AS29F002B/5V' ); {Bottom Boot Block}
            $57 : Name := ConstPtr( 'AS29F200B/5V' );
           End;
          End;
    $A4 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( 'AS29F040/5V' );
          End;
    $B9 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 512;
           Name := ConstPtr( 'AS29LV400T/3V' ); {Top Boot Block}
          End;
    $BA : Begin
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
           Sectors[ 3, 0 ] := 7;  {7 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( 'AS29LV400B/3V' ); {Bottom Boot Block}
          End;
    $DA : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 15;  {15 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 1024;
           Name := ConstPtr( 'AS29LV800T/3V' ); {Top Boot Block}
          End;
    $5B : Begin
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
           Sectors[ 3, 0 ] := 15;  {15 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( 'AS29LV800B/3V' ); {Bottom Boot Block}
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Alliance' );
 AllianceIdChip := True;
End;

Begin
 RegisterFlashManu( $52, AllianceIdChip );
End.