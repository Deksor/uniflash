Unit AMD; { Unit to communicate with AMD chips }
{v1.21 Manufacturer & Device ID codes are now not ANDed $7F !!}
{v1.21 New Sector table format}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Function AMDIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 AMDIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $A1 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 32;
           Name := ConstPtr( 'Am28F256/12V' );
          End;
    $A2 : Begin
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
    $A7 : Begin
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
    $AE : Begin
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
    $D9 : Begin
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
           Name := ConstPtr( 'Am29F100T/5V' );
          End;
    $DF : Begin
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
           Name := ConstPtr( 'Am29F100B/5V' ); {B v1.21}
          End;
    $ED : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 32;
           Sectors[ 2, 0 ] := 1;  {1 x 8k}
           Sectors[ 2, 1 ] := 64;
           Size := 128;
           Name := ConstPtr( 'Am29LV001BT/3V' );
          End;
    $6D : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 32;
           Sectors[ 2, 0 ] := 7;  {7 x 16k}
           Sectors[ 2, 1 ] := 128;
           Size := 128;
           Name := ConstPtr( 'Am29LV001BB/3V' );
          End;
    $20 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 128;
           Size := 128;
           Name := ConstPtr( 'Am29F010(A/B)/5V' ); {A,B v1.21}
          End;
    $6E : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 128;
           Size := 128;
           Name := ConstPtr( 'Am29LV010B/3V' );
          End;
    $D5 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( 'Am29F080(B)/5V' ); {B v1.21}
          End;
    {standard 512kx8 sectored, 'T'}
    $23,
    $77,
    $B5,
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
           Case DevId of
            $23 : Name := ConstPtr( 'Am29F400AT/BT/5V' );
            $77 : Name := ConstPtr( 'Am29F004BT/5V' ); {v1.21}
            $B5 : Name := ConstPtr( 'Am29LV004(B)T/3V' );
            $B9 : Name := ConstPtr( 'Am29LV400(B)T/3V' );
           End;
          End;
    {standard 512kx8 sectored, 'B'}
    $AB,
    $7B,
    $B6,
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
           Case DevId of
            $AB : Name := ConstPtr( 'Am29F400AB/BB/5V' );
            $7B : Name := ConstPtr( 'Am29F004BB/5V' ); {v1.21}
            $B6 : Name := ConstPtr( 'Am29LV004(B)B/3V' );
            $BA : Name := ConstPtr( 'Am29LV400(B)B/3V' );
           End;
          End;
    {standard 256kx8 sectored, 'T'}
    $40,
    $3B,
    $51,
    $B0 : Begin
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
           Case DevId of
            $B0 : Name := ConstPtr( 'Am29F002(N)(B)T/5V' );
            $51 : Name := ConstPtr( 'Am29F200AT/BT/5V' );
            $3B : Name := ConstPtr( 'Am29LV200(B)T/3V' );
            $40 : Name := ConstPtr( 'Am29LV002(B)T/3V' );
           End;
          End;
    {standard 256kx8 sectored, 'B'}
    $C2,
    $BF,
    $57,
    $34 : Begin
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
           Case DevId of
            $34 : Name := ConstPtr( 'Am29F002(N)(B)B/5V' );
            $57 : Name := ConstPtr( 'Am29F200AB/BB/5V' );
            $BF : Name := ConstPtr( 'Am29LV200(B)B/3V' );
            $C2 : Name := ConstPtr( 'Am29LV002(B)B/3V' );
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
           Name := ConstPtr( 'Am29F040(B)/5V' );
          End;
    $4F : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( 'Am29LV040B/3V' );
          End;
    $38 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( 'Am29LV081B/3V' );
          End;
    $3E,
    $DA,
    $EA : Begin {v1.21}
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
           Case DevId of
            $3E : Name := ConstPtr( 'Am29LV008(B)T/3V' );
            $DA : Name := ConstPtr( 'Am29LV800BT/3V' );
            $EA : Name := ConstPtr( 'Am29SL800CT/1.8V' );
           End;
          End;
    $37,
    $5B,
    $6B : Begin {v1.21}
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
           case DevId of
            $37 : Name := ConstPtr( 'Am29LV008(B)B/3V' );
            $5B : Name := ConstPtr( 'Am29LV800BB/3V' );
            $6B : Name := ConstPtr( 'Am29SL800CB/1.8V' );
           End;
          End;
    $D6 : Begin
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
           Name := ConstPtr( 'Am29F800(B)T/5V' );
          End;
    $58 : Begin
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
           Name := ConstPtr( 'Am29F800(B)B/5V' );
          End;
    $AD : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32; {32x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29F016(B)/5V' );
          End;
    $3D : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32; {32x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29F017B/5V' );
          End;
    $C8 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32; {32x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29LV017B/3V' );
          End;
    $C7 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 31; {31 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 2048;
           Name := ConstPtr( 'Am29LV116BT/3V' );
          End;
    $4C : Begin {v1.21}
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
           Sectors[ 3, 0 ] := 31; {31 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29LV116BB/3V' );
          End;
    $D2 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 31; {31x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 2048;
           Name := ConstPtr( 'Am29F160DT/5V' );
          End;
    $D8 : Begin {v1.21}
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
           Sectors[ 3, 0 ] := 31; {31x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29F160DB/5V' );
          End;
    $C4 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 31; {31x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 2048;
           Name := ConstPtr( 'Am29LV160BT/DT/3V' );
          End;
    $49 : Begin {v1.21}
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
           Sectors[ 3, 0 ] := 31; {31x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29LV160BB/DB/3V' );
          End;
    $E4 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 31; {31x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 2048;
           Name := ConstPtr( 'Am29SL160CT/1.8V' );
          End;
    $E7 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 31; {31x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'Am29SL160CB/1.8V' );
          End;
    $45 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 224k}
           Sectors[ 2, 1 ] := 1792;
           Sectors[ 3, 0 ] := 7;  {7 x 256k}
           Sectors[ 3, 1 ] := 2048;
           Size := 2048;
           Name := ConstPtr( 'Am29PL160CB/3V' );
          End;
    $41 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 64; {64x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 4096;
           Name := ConstPtr( 'Am29F032B/5V' );
          End;
    $A3 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 64; {64x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 4096;
           Name := ConstPtr( 'Am29LV033C/3V' );
          End;
    $F6 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 63; {63x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 4096;
           Name := ConstPtr( 'Am29LV320DT/3V' );
          End;
    $F9 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 63; {63x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 4096;
           Name := ConstPtr( 'Am29LV320DB/3V' );
          End;
    $93 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 128; {128 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 8192;
           Name := ConstPtr( 'Am29LV065D/3V' );
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