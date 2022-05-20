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
    $0C : Begin
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
           Name := ConstPtr( 'A29002(1)T/5V' ); {Top Boot Block}
          End;
    $0D : Begin
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
           Name := ConstPtr( 'A29002(1)B/5V' ); {Bottom Boot Block}
          End;
    $21: Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 64k}
           Sectors[ 0, 1 ] := 15;
           Sectors[ 1, 0 ] := 1;  {1 x 16k}
           Sectors[ 1, 1 ] := 7;
           Sectors[ 2, 0 ] := 2;  {2 x 4k}
           Sectors[ 2, 1 ] := 1;
           Sectors[ 3, 0 ] := 1;  {1 x 8k}
           Sectors[ 3, 1 ] := 3;
           Size := 128;
           Name := ConstPtr( 'A29001(1)T/5V' ); {Top Boot Block}
          End;
    $4C: Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 8k}
           Sectors[ 0, 1 ] := 3;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 1;
           Sectors[ 2, 0 ] := 1;  {1 x 16k}
           Sectors[ 2, 1 ] := 7;
           Sectors[ 3, 0 ] := 3;  {3 x 32k}
           Sectors[ 3, 1 ] := 15;
           Size := 128;
           Name := ConstPtr( 'A29001(1)B/5V' ); {Bottom Boot Block}
          End;
    $24: Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 4;  {4 x 32k}
           Sectors[ 0, 1 ] := 15;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( 'A29010/5V' );
          End;
    $06 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 31;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 512;
           Name := ConstPtr( 'A29040/5V' );
          End;
    $30: Begin
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
           Name := ConstPtr( 'A29400T/5V' ); {Top Boot Block}
          End;
    $31: Begin
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
           Name := ConstPtr( 'A29400B/5V' ); {Bottom Boot Block}
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
