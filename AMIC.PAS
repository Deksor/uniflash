Unit AMIC; { Unit to communicate with AMIC chips } {v1.20}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Function AMICIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 AMICIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $A1: Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 32k}
           Sectors[ 0, 1 ] := 256;
           Sectors[ 1, 0 ] := 1;  {1 x 16k}
           Sectors[ 1, 1 ] := 128;
           Sectors[ 2, 0 ] := 2;  {2 x 4k}
           Sectors[ 2, 1 ] := 32;
           Sectors[ 3, 0 ] := 1;  {1 x 8k}
           Sectors[ 3, 1 ] := 64;
           Size := 128;
           Name := ConstPtr( 'A29001(1)T/5V' ); {Top Boot Block}
          End;
    $4C: Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 32;
           Sectors[ 2, 0 ] := 1;  {1 x 16k}
           Sectors[ 2, 1 ] := 128;
           Sectors[ 3, 0 ] := 3;  {3 x 32k}
           Sectors[ 3, 1 ] := 256;
           Size := 128;
           Name := ConstPtr( 'A29001(1)B/5V' ); {Bottom Boot Block}
          End;
    $8C : Begin
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
           Name := ConstPtr( 'A29002(1)T/5V' ); {Top Boot Block}
          End;
    $0D : Begin
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
           Name := ConstPtr( 'A29002(1)B/5V' ); {Bottom Boot Block}
          End;
    $A4: Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 4;  {4 x 32k}
           Sectors[ 0, 1 ] := 256;
           Size := 128;
           Name := ConstPtr( 'A29010/5V' );
          End;
    $86,
    $92 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Case DevId of
            $86 : Name := ConstPtr( 'A29040(A/B)/5V' );
            $92 : Name := ConstPtr( 'A29L040/3V' ); {v1.37}
           End;
          End;
    $B0,
    $34: Begin
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
            $B0 : Name := ConstPtr( 'A29400T/5V' ); {Top Boot Block}
            $34 : Name := ConstPtr( 'A29L004T/400B/3V' ); {Top Boot Block} {v1.37}
           End;
          End;
    $31,
    $B5: Begin
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
            $31 : Name := ConstPtr( 'A29400B/5V' ); {Bottom Boot Block}
            $B5 : Name := ConstPtr( 'A29L004B/400B/5V' ); {Bottom Boot Block} {v1.37}
           End;
          End;
    $0E,
    $1A: Begin {v1.37}
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
            $0E : Name := ConstPtr( 'A29800T/5V' ); {Top Boot Block}
            $1A : Name := ConstPtr( 'A29L008T/800T/3V' ); {Top Boot Block}
           End;
          End;
    $8F,
    $9B: Begin {v1.37}
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
            $8F : Name := ConstPtr( 'A29800B/5V' ); {Bottom Boot Block}
            $9B : Name := ConstPtr( 'A29L008B/800B/3V' ); {Bottom Boot Block}
           End;
          End;
    $A8: Begin {v1.37}
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
           Name := ConstPtr( 'A29L160T/3V' ); {Top Boot Block}
          End;
    $29: Begin {v1.37}
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
           Name := ConstPtr( 'A29L160B/3V' ); {Bottom Boot Block}
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'AMIC' );
 AMICIdChip := True;
End;

Begin
 RegisterFlashManu( $37, AMICIdChip );
End.