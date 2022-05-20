Unit IMT; { Unit to communicate with IMT chips } {v1.21}
Interface
{Used device ID 7F - it's actually $1F, but Atmel has $1F}
{Detection needs to be heavily modified}

Implementation

Uses Flash, GenFlash, Tools;

Function IMTIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 IMTIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $A0,
    $A3 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 128;
           case DevId of
            $A0 : Name := ConstPtr( 'IM29F001T/5V' );
            $A3 : Name := ConstPtr( 'IM29F001B/5V' );
           End;
          End;
    $A1,
    $A2 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 256;
           case DevId of
            $A1 : Name := ConstPtr( 'IM29F002T/5V' );
            $A2 : Name := ConstPtr( 'IM29F002B/5V' );
           End;
          End;
    $AF,
    $AE,
    $A7,
    $A8 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1024b}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           case DevId of
            $AF : Name := ConstPtr( 'IM29F004T/5V' );
            $AE : Name := ConstPtr( 'IM29F004B/5V' );
            $A7 : Name := ConstPtr( 'IM29LV004T/3.3V' );
            $A8 : Name := ConstPtr( 'IM29LV004B/3.3V' );
           End;
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'IMT' );
 IMTIdChip := True;
End;

Begin
 RegisterFlashManu( $7F, IMTIdChip ); {It's actually $1F, but Atmel has $1F}
End.