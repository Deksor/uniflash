Unit Mosel; { Unit to communicate with Mosel chips } {v1.21}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Function MoselIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 MoselIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $00 : Begin
(*           if ROMBase<>0 then FOMemB( ROMBase + $5555, $FF ); {Reset after ID}*)
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 64;
           Name := ConstPtr( 'V29C51000T/5V' ); {Top Boot Block}
          End;
    $A0 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 64;
           Name := ConstPtr( 'V29C51000B/5V' ); {Bottom Boot Block}
          End;
    $01 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 128;
           Name := ConstPtr( 'V29C51001T/5V' ); {Top Boot Block}
          End;
    $A1 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 128;
           Name := ConstPtr( 'V29C51001B/5V' ); {Bottom Boot Block}
          End;
    $02 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 256;
           Name := ConstPtr( 'V29C51002T/5V' ); {Top Boot Block}
          End;
    $A2 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 256;
           Name := ConstPtr( 'V29C51002B/5V' ); {Bottom Boot Block}
          End;
    $03 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1k}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           Name := ConstPtr( 'V29C51004T/5V' ); {Top Boot Block}
          End;
    $A3 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1k}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           Name := ConstPtr( 'V29C51004B/5V' ); {Bottom Boot Block}
          End;
    $13 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1k}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           Name := ConstPtr( 'V29C51400T/5V' ); {Top Boot Block}
          End;
    $B3 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1k}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           Name := ConstPtr( 'V29C51400B/5V' ); {Bottom Boot Block}
          End;
    $83,  {v1.22 for SyncMOS}
    $63 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1k}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           case DevId of
            $63 : Name := ConstPtr( 'V29C31004T/3.3V' ); {Top Boot Block}
            $83 : Name := ConstPtr( 'V29C31400T/3.3V' );
           End;
          End;
    $C3,  {v1.22 for SyncMOS}
    $73 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 1k}
           Sectors[ 0, 1 ] := 8;
           Size := 512;
           Name := ConstPtr( 'V29C31004B/3.3V' ); {Bottom Boot Block}
          End;
    $20 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128;  {128 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 64;
           Name := ConstPtr( 'V29LC51000/5V' );
          End;
    $60 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 256;  {256 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 128;
           Name := ConstPtr( 'V29LC51001/5V' );
          End;
    $82 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 512;  {512 x 512b}
           Sectors[ 0, 1 ] := 4;
           Size := 256;
           Name := ConstPtr( 'V29LC51002/5V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Mosel Vitelic' );
 MoselIdChip := True;
End;

Begin
 RegisterFlashManu( $40, MoselIdChip );
End.