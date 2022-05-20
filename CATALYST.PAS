Unit Catalyst; { Unit to communicate with Catalyst chips }

{NOTE: Catalyst is an officially licensed 2nd source for Intel     }
{      flash chips. Most of the chips in this unit are essentially }
{      equal to their Intel counterparts (with the exception of    }
{      the manufacturer ID of course ...)                          }

Interface

Implementation

Uses Flash, GenFlash, Tools;

Function CatIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 CatIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $04 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 47;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 192;
           Name := ConstPtr( 'CAT28F150T/12V' );
          End;
    $05 : Begin
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
           Sectors[ 3, 0 ] := 1;  {1 x 64k}
           Sectors[ 3, 1 ] := 31;
           Size := 192;
           Name := ConstPtr( 'CAT28F150B/12V' );
          End;

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
           Name := ConstPtr( 'CAT28F001T/12V' );
          End;
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
           Name := ConstPtr( 'CAT28F001B/12V' );
          End;
    $30 : Begin
           {similar to AMD}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 15;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 256;
           Name := ConstPtr( 'CAT29F002T/5V' );
          End;
    $34 : Begin
           {similar to AMD}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 3;
           Sectors[ 2, 0 ] := 1;  {1 x 32k}
           Sectors[ 2, 1 ] := 15;
           Sectors[ 3, 0 ] := 3;  {3 x 64k}
           Sectors[ 3, 1 ] := 31;
           Size := 256;
           Name := ConstPtr( 'CAT29F002B/5V' );
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
           Name := ConstPtr( 'CAT28F002T/12V' );
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
           Name := ConstPtr( 'CAT28F002B/12V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Catalyst' );
 CatIdChip := True;
End;

Begin
 RegisterFlashManu( $31, CatIdChip );
End.
