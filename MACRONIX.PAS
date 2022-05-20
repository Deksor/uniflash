Unit Macronix; { Unit to communicate with Macronix chips }
{v1.21 Removed 2 non-existing chips and added new chips}
Interface

{v1.24 added 4B,D5 to MX28F1000P - another conflict - $D5 has MX29F080/5V}
{MX29LV008B Device ID CONFLICT WITH MX29F022B}
{v1.27 Some H.T. chip (45) probably conflict with MX29F004T/5V}

Implementation

Uses Flash, GenFlash, Tools;

Procedure MxSecProg( Pos, Data : LongInt ); Far;
Var
Attempt,
X, Y, Ld,
TimeOut  : Byte;

Begin
 For Y := 0 to CurCInfo.PgSize - 1 do
  Begin
   Attempt := 0;
   Ld := FIMemB( Data + Y );
   Repeat
    FOMemB( Pos + Y, $40 );  {Write setup}
    FOMemB( Pos + Y, Ld );   {Write data}

    {Wait for programming to finish}
    TimeOut := 40;  {300 usec max}
    While  ( ( FiMemB( Pos + Y ) and $40 ) <>
             ( FiMemB( Pos + Y ) and $40 ) ) and ( TimeOut > 0 ) do
     Begin
      Dec( TimeOut );
      Wait( 10 );
     End;

    Inc( Attempt );
    X := FIMemB( Pos + Y );
   Until ( Attempt > 3 ) or  ( X = Ld );
   If ( X <> Ld ) then
    Begin
     IntelResetB;
     FlashCmd( 0 );
     FlashError := 2; {programming error}
     Exit;
    End;
  End;
 IntelResetB;
 FlashCmd( 0 );
End;

Procedure MxSecErase( SAddr : LongInt ); Far;
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FOMemB( SAddr, $20 ); {Erase setup}
  FOMemB( SAddr, $D0 ); {Erase confirm}
  Wait( 250 ); {Wait +- 200 usec for erase to start}

  {Wait for erase to finish}
  TimeOut := 50000;   {5 sec max}
  While  ( ( FiMemB( SAddr ) and $40 ) <>
           ( FiMemB( SAddr ) and $40 ) ) and ( TimeOut > 0 ) do
   Begin
    Dec( TimeOut );
    Wait( 100 );
   End;

  {Did erase work?}
  X := FiMemB( SAddr ) and $80;
  Inc( Attempt );
 Until ( Attempt > 3 ) or ( X <> $0 );
 If X = 0 then FlashError := 3; {erasing error}
 IntelResetB;
 FlashCmd( 0 );
End;

{Standard page programming with Intel status register, but requires erase}
Procedure MxSecPageProg( Pos, Data : LongInt ); Far; {v1.21}
Var
Attempt,
Ld, X   : Byte;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $A0 );
  MoveLinBlockB( Data, Pos, CurCInfo.PgSize );
  Wait( 300 );  {Wait min. 300 usec}

  {Wait for programming to finish}
  Repeat
   X := FiMemB( Pos + CurCInfo.PgSize - 1 );
  Until ( ( X and $80 ) <> 0 );
  X := FiMemB( Pos + CurCInfo.PgSize - 1 );
  Inc( Attempt );
  FlashCmd( $50 );  {Clear status}
 Until ( Attempt > 3 ) or  ( ( X and $B0 ) = $80 );
 If ( ( X and $B0 ) <> $80 ) then FlashError := 2; {programming error}
 FlashCmd( $F0 );
End;

{AMD sector erase with Intel status register}
Procedure MxSecPageErase( SAddr : LongInt ); Far; {v1.21}
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  FOMemB( ROMBase + $5555, $AA );
  FOMemB( ROMBase + $2AAA, $55 );
  FOMemB( SAddr, $30 ); {Erase sector containing address SAddr}

  {Wait for erase to finish}
  Repeat
   X := FiMemB( SAddr );
  Until ( ( X and $80 ) <> 0 );
  Inc( Attempt );
  X := FiMemB( SAddr );
  FlashCmd( $50 ); {Clear status}
 Until ( Attempt > 3 ) or ( ( X and $B0 ) = $80 );
 If ( X and $B0 ) <> $80 then FlashError := 3; {erasing error}
 FlashCmd( $F0 );
End;

{AMD bulk erase with Intel status register}
Procedure MxBulkErase( SAddr : LongInt ); Far; {v1.21}
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  FlashCmd( $10 );      {Erase confirm}

  {Wait for erase to finish}
  Repeat
   X := FiMemB( SAddr );
  Until ( ( X and $80 ) <> 0 );
  Inc( Attempt );
  X := FiMemB( SAddr );
  FlashCmd( $50 ); {Clear status}
 Until ( Attempt > 3 ) or ( ( X and $B0 ) = $80 );
 If ( X and $B0 ) <> $80 then FlashError := 3; {erasing error}
 FlashCmd( $F0 );
End;


Function MxIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 MxIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $11 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 128;
           Size := 128;
           Name := ConstPtr( 'MX28F1000/12V' )
          End;
    $1A,
    $4B,
    $D5 : Begin {4B,D5 v1.24}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 4;  {4 x 4k}
           Sectors[ 1, 1 ] := 32;
           Size := 128;
           Name := ConstPtr( 'MX28F1000P/12V' );
          End;
    $2A : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 4;  {4 x 4k}
           Sectors[ 0, 1 ] := 32;
           Sectors[ 1, 0 ] := 14; {14 x 16k}
           Sectors[ 1, 1 ] := 128;
           Sectors[ 2, 0 ] := 4;  {4 x 4k}
           Sectors[ 2, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( 'MX28F2000P/12V' );
          End;
    $3C : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecProg;
           Erase := MxSecErase;
           Sectors[ 0, 0 ] := 14; {14 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 8;  {8 x 4k}
           Sectors[ 1, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( 'MX28F2000T/12V' );
          End;
    $D9 : Begin {v1.21}
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
           Name := ConstPtr( 'MX29F100T/5V' );
          End;
    $DF : Begin {v1.21}
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
           Name := ConstPtr( 'MX29F100B/5V' );
          End;
    $2D : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 256;
           Name := ConstPtr( 'MX28F002T/12V' );
          End;
    $2E : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 768;
           Sectors[ 3, 0 ] := 1;  {1 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 256;
           Name := ConstPtr( 'MX28F002B/12V' );
          End;
    $18 : Begin
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
           Sectors[ 3, 0 ] := 2;  {2 x 4k}
           Sectors[ 3, 1 ] := 32;
           Sectors[ 4, 0 ] := 1;  {1 x 8k}
           Sectors[ 4, 1 ] := 64;
           Size := 128;
           Name := ConstPtr( 'MX29F001T/5V' ); {Top Boot Block}
          End;
    $19 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 32;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 32k}
           Sectors[ 3, 1 ] := 256;
           Sectors[ 4, 0 ] := 1;  {1 x 64k}
           Sectors[ 4, 1 ] := 512;
           Size := 128;
           Name := ConstPtr( 'MX29F001B/5V' ); {Bottom Boot Block}
          End;
    $B0,
    $36,
    $51 : Begin {v1.21}
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
            $B0 : Name := ConstPtr( 'MX29F002(N)T/5V' );
            $36 : Name := ConstPtr( 'MX29F022T/5V' );
            $51 : Name := ConstPtr( 'MX29F200T/5V' );
           End;
          End;
    $34,
    $37,
    $57 : Begin {v1.21}
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
            $34 : Name := ConstPtr( 'MX29F002(N)B/5V' );
            $37 : Name := ConstPtr( 'MX29F022B/5V' );
            $57 : Name := ConstPtr( 'MX29F200B/5V' );
           End;
          End;
    $45,
    $23,
    $B5,
    $B9 : Begin {v1.21}
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
           case DevId of
            $45 : Name := ConstPtr( 'MX29F004T/5V' );
            $23 : Name := ConstPtr( 'MX29F400T/5V' );
            $B5 : Name := ConstPtr( 'MX29LV004T/3V' );
            $B9 : Name := ConstPtr( 'MX29LV400T/3V' );
           End;
          End;
    $46,
    $AB,
    $B6,
    $BA : Begin {v1.21}
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
           case DevId of
            $46 : Name := ConstPtr( 'MX29F004B/5V' );
            $AB : Name := ConstPtr( 'MX29F400B/5V' );
            $B6 : Name := ConstPtr( 'MX29LV004B/3V' );
            $BA : Name := ConstPtr( 'MX29LV400B/3V' );
           End;
          End;
    $A4,
    $4F : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           case DevId of
            $A4 : Name := ConstPtr( 'MX29F040/5V' );
            $4F : Name := ConstPtr( 'MX29LV040/3V' );
           End;
          End;
{    $D5,} {v1.24}
    $38 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           case DevId of
            $D5 : Name := ConstPtr( 'MX29F080/5V' );
            $38 : Name := ConstPtr( 'MX29LV081/3V' );
           End;
          End;
    $D6,
    $3E,
    $DA : Begin {v1.21}
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
           case DevId of
            $D6 : Name := ConstPtr( 'MX29F800T/5V' );
            $3E : Name := ConstPtr( 'MX29LV008T/3V' );
            $DA : Name := ConstPtr( 'MX29LV800T/3V' );
           End;
          End;
    $58,
{    $37,}
    $5B : Begin {v1.21}
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
            $58 : Name := ConstPtr( 'MX29F800B/5V' );
{            $37 : Name := ConstPtr( 'MX29LV008B/3V' ); CONFLICT WITH 29F022B}
            $5B : Name := ConstPtr( 'MX29LV800B/3V' );
           End;
          End;
    $AD : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32; {32 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'MX29F016/5V' );
          End;
    $F8,
    $F6 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecPageProg;
           Erase := MxSecPageErase;
           Sectors[ 0, 0 ] := 32; {32 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           case DevId of
            $F8 : Name := ConstPtr( 'MX29L1611/3.3V' );
            $F6 : Name := ConstPtr( 'MX29L1611G/11V' );
           End;
          End;
    $FA : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecPageProg;
           Erase := MxSecPageErase;
           Sectors[ 0, 0 ] := 16; {16 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Size := 2048;
           Name := ConstPtr( 'MX29F1610A/5V' );
          End;
    $C4 : Begin {v1.21}
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
           Name := ConstPtr( 'MX29LV160T/3V' );
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
           Name := ConstPtr( 'MX29LV160B/3V' );
          End;
    $6B : Begin {v1.21}
           Flags  := 2;   {bulk erase}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecPageProg;
           Erase := MxBulkErase;
           Size := 2048;
           Name := ConstPtr( 'MX29F1615/5V' );
          End;
    $F9 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := MxSecPageProg;
           Erase := MxSecPageErase;
           Sectors[ 0, 0 ] := 32; {32 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Size := 4096;
           Name := ConstPtr( 'MX29L3211/3.3V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Macronix' );
 MxIdChip := True;
End;

Begin
 RegisterFlashManu( $C2, MxIdChip );
End.