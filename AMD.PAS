Unit AMD; { Unit to communicate with AMD chips }

Interface


Implementation

Uses Flash, GenFlash, Tools;

Function AMDIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 AMDIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $21 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 32;
           Name := ConstPtr( 'Am28F256/12V' );
          End;
    $22 : Begin
           Flags  := 2;   {bulk erase}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDEmbdWrite;
           Erase := AMDEmbdErase;
           Size := 128;
           Name := ConstPtr( 'Am28F010A/12V' );
          End;
    $25 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 64;
           Name := ConstPtr( 'Am28F512/12V' );
          End;
    $27 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 128;
           Name := ConstPtr( 'Am28F010/12V' );
          End;
    $29 : Begin
           Flags  := 2;   {bulk erase}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDEmbdWrite;
           Erase := AMDEmbdErase;
           Size := 256;
           Name := ConstPtr( 'Am28F020A/12V' );
          End;
    $2A : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 256;
           Name := ConstPtr( 'Am28F020/12V' );
          End;
    $2E : Begin
           Flags  := 2;   {bulk erase}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDEmbdWrite;
           Erase := AMDEmbdErase;
           Size := 64;
           Name := ConstPtr( 'Am28F512A/12V' );
          End;
    $2F : Begin
           Flags  := 2;   {bulk erase}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDEmbdWrite;
           Erase := AMDEmbdErase;
           Size := 32;
           Name := ConstPtr( 'Am28F256A/12V' );
          End;
    {29F100T}
    $59 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 15;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 128;
           Name := ConstPtr( 'Am29F100T/5V' );
          End;
    {29F100B}
    $5F : Begin
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
           Sectors[ 3, 0 ] := 1;  {1 x 64k}
           Sectors[ 3, 1 ] := 31;
           Size := 128;
           Name := ConstPtr( 'Am29F100T/5V' );
          End;
    {29F010}
    $20 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( 'Am29F010/5V' );
          End;
    {29F080B}
    $55 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 1024;
           Name := ConstPtr( 'Am29F080B/5V' );
          End;
    {standard 512kx8 sectored, 'T'}
    $39,
    $23,
    $35 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 15;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 512;
           Case DevId of
            $23 : Name := ConstPtr( 'Am29F400AT/5V or Am29F400BT/5V' );
            $35 : Name := ConstPtr( 'Am29LV004T/3V' );
            $39 : Name := ConstPtr( 'Am29LV400T/3V' );
           End;
          End;
    {standard 512kx8 sectored, 'B'}
    $3A,
    $2B,
    $36 : Begin
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
           Sectors[ 3, 0 ] := 7;  {7 x 64k}
           Sectors[ 3, 1 ] := 31;
           Size := 512;
           Case DevId of
            $2B : Name := ConstPtr( 'Am29F400AB/5V or Am29F400BB/5V' );
            $36 : Name := ConstPtr( 'Am29LV004B/3V' );
            $3A : Name := ConstPtr( 'Am29LV400B/3V' );
           End;
          End;
    {standard 256kx8 sectored, 'T'}
    $40,
    $3B,
    $51,
    $30 : Begin
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
           Case DevId of
            $30 : Name := ConstPtr( 'Am29F002T/5V or Am29F002NT/5V' );
            $51 : Name := ConstPtr( 'Am29F200AT/5V' );
            $3B : Name := ConstPtr( 'Am29LV200T/3V' );
            $40 : Name := ConstPtr( 'Am29LV002T/3V' );
           End;
          End;
    {standard 256kx8 sectored, 'B'}
    $42,
    $3F,
    $57,
    $34 : Begin
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
           Case DevId of
            $34 : Name := ConstPtr( 'Am29F002B/5V or Am29F002NB/5V' );
            $57 : Name := ConstPtr( 'Am29F200AB/5V' );
            $3F : Name := ConstPtr( 'Am29LV200B/3V' );
            $42 : Name := ConstPtr( 'Am29LV002B/3V' );
           End;
          End;
    {29F040B}
    $24 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 512;
           Name := ConstPtr( 'Am29F040B/5V' );
          End;
    {29F800BT}
    $56 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 15;  {15 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 15;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 3;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 7;
           Size := 1024;
           Name := ConstPtr( 'Am29F800BT/5V' );
          End;
    {29F800BB}
    $58 : Begin
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
           Sectors[ 3, 0 ] := 15;  {15 x 64k}
           Sectors[ 3, 1 ] := 31;
           Size := 1024;
           Name := ConstPtr( 'Am29F800BB/5V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'AMD' );
 AMDIdChip := True;
End;

Begin
 RegisterFlashManu( $01, AMDIdChip );
End.
