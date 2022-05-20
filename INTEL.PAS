Unit Intel; { Unit to communicate with Intel chips }

Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure Unprotect( SAddr : LongInt ); {v1.18}
Begin
 FOMemB((SAddr and $FFFF0000)-$3FFFFE,0); {Disable Write-Lock}
End;

Procedure Protect( SAddr : LongInt ); {v1.18}
Begin
 FOMemB((SAddr and $FFFF0000)-$3FFFFE,1); {Enable Write-Lock}
End;

Procedure IntelSecEraseU( SAddr : LongInt ); Far; {v1.18}
Begin
 {Unprotect}
 Unprotect( SAddr );
 IntelSecErase( SAddr );
 {Protect}
 Protect( SAddr );
End;

Procedure IntelSecProgU( Pos, Data : LongInt ); Far; {v1.18}
Begin
 {Unprotect}
 Unprotect( Pos );
 IntelSecProg( Pos, Data );
 {Protect}
 Protect( Pos );
End;

Function IntelIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 IntelIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    {28F010}
    $B4 and $7F : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 128;
           Name := ConstPtr( '28F010/12V' );
          End;
    {28F020}
    $BD and $7F : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 256;
           Name := ConstPtr( '28F020/12V' );
          End;

         {28F001BX-T}
    $14 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 112k}
           Sectors[ 0, 1 ] := 55;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 1;
           Sectors[ 2, 0 ] := 1;  {1 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( '28F001BX-T/12V or 28F001BN-T/12V' );
          End;
    {28F001BX-B}
    $15 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 8k}
           Sectors[ 0, 1 ] := 3;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 1;
           Sectors[ 2, 0 ] := 1;  {1 x 112k}
           Sectors[ 2, 1 ] := 55;
           Sectors[ 3, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( '28F001BX-B/12V or 28F001BN-B/12V' );
          End;
    $70 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 256; {'page' size, program 128 words at a time}
           Progr  := IntelSecProgW;
           Erase := IntelSecEraseW;
           Sectors[ 0, 0 ] := 3;  {3 x 128k}
           Sectors[ 0, 1 ] := 63;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 47;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 512;
           Name := ConstPtr( '28F400BX-T/12V' );
          End;
    $71 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 256; {'page' size, program 128 words at a time}
           Progr  := IntelSecProgW;
           Erase := IntelSecEraseW;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 3;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 47;
           Sectors[ 3, 0 ] := 3;  {3 x 128k}
           Sectors[ 3, 1 ] := 63;
           Size := 512;
           Name := ConstPtr( '28F400BX-B/12V' );
          End;
    $74 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 256; {'page' size, program 128 words at a time}
           Progr  := IntelSecProgW;
           Erase := IntelSecEraseW;
           Sectors[ 0, 0 ] := 1;  {1 x 128k}
           Sectors[ 0, 1 ] := 63;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 47;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 256;
           Name := ConstPtr( '28F200-T series (12V/5V)' );
          End;
    $75 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 256; {'page' size, program 128 words at a time}
           Progr  := IntelSecProgW;
           Erase := IntelSecEraseW;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 3;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 47;
           Sectors[ 3, 0 ] := 1;  {1 x 128k}
           Sectors[ 3, 1 ] := 63;
           Size := 256;
           Name := ConstPtr( '28F200-B series (12V/5V)' );
          End;
    $78 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 128k}
           Sectors[ 0, 1 ] := 63;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 47;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 512;
           Name := ConstPtr( '28F004BX-T/12V' );
          End;
    $79 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 3;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 47;
           Sectors[ 3, 0 ] := 3;  {3 x 128k}
           Sectors[ 3, 1 ] := 63;
           Size := 512;
           Name := ConstPtr( '28F004BX-B/12V' );
          End;
    $7C : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 128k}
           Sectors[ 0, 1 ] := 63;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 47;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 256;
           Name := ConstPtr( '28F002-T series (12V/5V)' );
          End;
    $7D : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 3;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 47;
           Sectors[ 3, 0 ] := 1;  {1 x 128k}
           Sectors[ 3, 1 ] := 63;
           Size := 256;
           Name := ConstPtr( '28F002-B series (12V/5V)' );
          End;
    $2D : Begin {v1.18}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProgU;
           Erase := IntelSecEraseU;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 512; {4Mb}
           Name := ConstPtr( '82802AB/3.3V (Firmware Hub)' );
          End;
    $2C : Begin {v1.18}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProgU;
           Erase := IntelSecEraseU;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 1024; {8Mb}
           Name := ConstPtr( '82802AC/3.3V (Firmware Hub)' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Intel' );
 IntelIdChip := True;
End;

Begin
 RegisterFlashManu( $09, IntelIdChip );
End.
