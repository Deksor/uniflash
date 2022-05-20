Unit Intel; { Unit to communicate with Intel chips }
Interface

{29FXXXB3.PDF:}
{28F400B3-T=$8894 28F400B3-B=$8895 conflict}
{28F800B3-T,B 28F160B3-T,B, 28F320B3-T,B 28F640B3-T,B not supported}

{28FXXXC3.PDF: all not supported}
{28FXXXF3.PDF: all not supported}

{28FXXXS3.PDF: 28F160S3 conflict, 28F320S3 not done}
{28FXXXS5.PDF: 28F160S5 conflict, 28F320S5 not done}
Implementation

Uses Flash, GenFlash, Tools;

Procedure Unprotect( SAddr : LongInt ); {v1.18}
Begin
 FOMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10,
  FIMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10) and $F8); {Disable Write-Lock}
End;

Procedure Protect( SAddr : LongInt ); {v1.18}
Begin
 FOMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10,
  FIMemB(SAddr and $FFFF0000+$FFC00002-CurCInfo.Size shl 10) or $01); {Enable Write-Lock}
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
    $B9 : Begin {v1.21}
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 32;
           Name := ConstPtr( '28F256(A)/12V' );
          End;
    $B8 : Begin {v1.21}
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 64;
           Name := ConstPtr( '28F512/12V' );
          End;
    $B4 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 128;
           Name := ConstPtr( '28F010/12V' );
          End;
    $BD : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 256;
           Name := ConstPtr( '28F020/12V' );
          End;
    $94 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 112k}
           Sectors[ 0, 1 ] := 896;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 32;
           Sectors[ 2, 0 ] := 1;  {1 x 8k}
           Sectors[ 2, 1 ] := 64;
           Size := 128;
           Name := ConstPtr( '28F001BX/BN-T/12V' );
          End;
    $95 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 2;  {2 x 4k}
           Sectors[ 1, 1 ] := 32;
           Sectors[ 2, 0 ] := 1;  {1 x 112k}
           Sectors[ 2, 1 ] := 896;
           Size := 128;
           Name := ConstPtr( '28F001BX/BN-B/12V' );
          End;
    $7C : Begin
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
           Name := ConstPtr( '28F002-T series (12V/5V)' );
          End;
    $7D : Begin
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
           Name := ConstPtr( '28F002-B series (12V/5V)' );
          End;
    $78 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 512;
           Name := ConstPtr( '28F004-T series (12V/5V)' );
          End;
    $79 : Begin
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
           Sectors[ 3, 0 ] := 3;  {3 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 512;
           Name := ConstPtr( '28F004-B series (12V/5V)' );
          End;
    $D4 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 512;
           Name := ConstPtr( '28F004B3-T/3V' );
          End;
    $D5 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 7;  {7 x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( '28F004B3-B/3V' );
          End;
    $D2 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 15; {15 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 1024;
           Name := ConstPtr( '28F008B3-T/3V' );
          End;
    $D3 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 15; {15 x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( '28F008B3-B/3V' );
          End;
    $98 : Begin {v1.22}
           Flags  := 0;   {sector mode}
           PgSize := 256; {'page' size, program 128 words at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 1024;
           Name := ConstPtr( '28F008-T series (5V/3V/2.7V)' );
          End;
    $99 : Begin {v1.22}
           Flags  := 0;   {sector mode}
           PgSize := 256; {'page' size, program 128 words at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 768;
           Sectors[ 3, 0 ] := 7;  {7 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 1024;
           Name := ConstPtr( '28F008-B series (5V/3V/2.7V)' );
          End;
    $D0 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 31; {31 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 8;  {8 x 8k}
           Sectors[ 1, 1 ] := 64;
           Size := 2048;
           Name := ConstPtr( '28F016B3-T/3V' );
          End;
    $D1 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 8k}
           Sectors[ 0, 1 ] := 64;
           Sectors[ 1, 0 ] := 31; {31 x 64k}
           Sectors[ 1, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( '28F016B3-B/3V' );
          End;
    $A7 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( '28F004Sx series (5V/3.3V/2.7V)' );
          End;
    $A6 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( '28F008Sx series (5V/3.3V/2.7V)' );
          End;
    $A2 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( '28F008SA/12V' );
          End;
    $AA : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( '28F016Sx series (5V/3.3V/2.7V)' );
          End;
    $A0 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( '28F016S5/SA (5V/3.3V)' );
          End;
    $16,
    $14 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Size := 4096;
           case DevId of
            $16 : Name := ConstPtr( '28F320J3A/3V' );
            $14 : Name := ConstPtr( '28F320J5/5V' );
           End;
          End;
    $17,
    $15 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 64;  {64 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Size := 8192;
           case DevId of
            $17 : Name := ConstPtr( '28F640J3A/3V' );
            $15 : Name := ConstPtr( '28F640J5/5V' );
           End;
          End;
    $18 : Begin {v1.21}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 128; {128 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Size := 16384;
           Name := ConstPtr( '28F128J3A/3V' );
          End;
    $AD : Begin {v1.18}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProgU;
           Erase := IntelSecEraseU;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512; {4Mb}
           Name := ConstPtr( '82802AB/3.3V (Firmware Hub)' );
          End;
    $AC : Begin {v1.18}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProgU;
           Erase := IntelSecEraseU;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
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
 RegisterFlashManu( $89, IntelIdChip );
End.