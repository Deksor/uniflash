Unit EON; { Unit to communicate with EON chips } {v1.21}
Interface
{Note: Mfg. ID from 2nd bank}

Implementation

Uses Flash, GenFlash, Tools;

Function EONIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 EONIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $92 : Begin
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
           Name := ConstPtr( 'EN29F002(A)T/5V' ); {Top Boot Block}
          End;
    $97 : Begin
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
           Name := ConstPtr( 'EN29F002(A)B/5V' ); {Bottom Boot Block}
          End;
    $21,
    $6F : Begin {v1.37}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 4;  {4 x 16k}
           Sectors[ 0, 1 ] := 128;
           Size := 64;
           Case DevId of
            $21 : Name := ConstPtr( 'EN29F512/5V' );
            $6F : Name := ConstPtr( 'EN29LV512/3V' );
           End;
          End;
    $20,
    $6E : Begin {v1.37}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 128;
           Size := 128;
           Case DevId of
            $20 : Name := ConstPtr( 'EN29F010/5V' );
            $6E : Name := ConstPtr( 'EN29LV010/3V' );
           End;
          End;
    $04,
    $4F : Begin {v1.37}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Case DevId of
            $04 : Name := ConstPtr( 'EN29F040(A)/5V' );
            $4F : Name := ConstPtr( 'EN29LV040/3V' );
           End;
          End;
    $08 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( 'EN29F080/5V' );
          End;
    $B9 : Begin {v1.37}
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
           Name := ConstPtr( 'EN29LV400T/3V' ); {Top Boot Block}
          End;
    $BA : Begin {v1.37}
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
           Name := ConstPtr( 'EN29LV400B/3V' ); {Bottom Boot Block}
          End;
    $89,
    $DA : Begin {v1.37}
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
            $89 : Name := ConstPtr( 'EN29F800T/5V' ); {Top Boot Block}
            $DA : Name := ConstPtr( 'EN29LV800(A)T/3V' ); {Top Boot Block}
           End;
          End;
    $8A,
    $5B : Begin {v1.37}
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
           Case DevId of
            $8A : Name := ConstPtr( 'EN29F800B/5V' ); {Bottom Boot Block}
            $5B : Name := ConstPtr( 'EN29LV800(A)B/3V' ); {Bottom Boot Block}
           End;
          End;
    $C4 : Begin {v1.37}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 31;  {31 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 2048;
           Name := ConstPtr( 'EN29LV160T/3V' ); {Top Boot Block}
          End;
    $49 : Begin {v1.37}
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
           Sectors[ 3, 0 ] := 31;  {31 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'EN29LV160B/3V' ); {Bottom Boot Block}
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'EON' );
 EONIdChip := True;
End;

Begin
 RegisterFlashManu( $1C, EONIdChip ); {Note: ID from 2nd bank}
End.