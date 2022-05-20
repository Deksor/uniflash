Unit Winbond; { Unit to communicate with Winbond chips }
Interface

Implementation

Uses Flash, GenFlash, Tools;

Procedure WbSecErase( SAddr : LongInt );Far; {v1.29}
Var
Attempt,
X        : Byte;
TimeOut  : Word;

Begin
 Attempt := 0;
 Repeat
  FlashCmd( $80 );      {Erase setup}
  Flash_Write($5555,$AA);
  Flash_Write($2AAA,$55);
  Flash_Write(SAddr,$50); {Erase sector containing address SAddr}

  TimeOut:=25000;
  X:=Flash_Read(SAddr); {v1.24 Toggle bit method}
  while ((X and $40) <> (Flash_Read(SAddr) and $40)) and (TimeOut>0) do
   begin
     X:=Flash_Read(SAddr);
     Wait(1000);
     Dec(TimeOut);
   end;

  Inc( Attempt );
  FlashCmd( $F0 ); {Reset}
 Until ( Attempt > 3 ) or ( TimeOut>0 );
 If TimeOut>0 then FlashError := 3; {erasing error}
End;

Procedure WbSecProgFWH( Pos, Data : LongInt ); Far; {W39V040FA} {v1.29}
begin
  {Unprotect}
  FOMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) and $F8);
  AMDSecProg(Pos,Data);
  {Protect}
  FOMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) or $01);
end;

Procedure WbSecEraseFWH( SAddr: LongInt ); Far; {W39V040FA} {v1.29}
begin
  {Unprotect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) and $F8);
  WbSecErase(SAddr);
  {Protect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) or $01);
end;

Function WBIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 WBIdChip := False;
 With CInfo do
  Begin
   {Common info for some chips v1.21}
   Flags  := 1;   {page mode}
   PgSize := 128; {page size}
   Progr  := GenPageProgB;
   Case DevId of
    $C8 : Begin
           Name := ConstPtr( 'W29x512/5V series' );
           Size := 64;
          End;
    $C1 : Begin {W29EE011, W29C010, W29C010M, W29C011A, W29EE012}
           Name := ConstPtr( 'W29x010/011/012/5V series' );
           Size := 128;
          End;
    $45 : Begin
           {note: 2 write-protectable boot blocks}
           Name := ConstPtr( 'W29C020(C)/022/5V' );
           Size := 256;
          End;
    $46 : Begin {v1.21}
           {note: 2 write-protectable boot blocks}
           Name := ConstPtr( 'W29C040/043/5V' );
           PgSize := 256; {page size}
           Size := 512;
          End;
    $38 : Begin {v1.29}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := WbSecErase;
           Sectors[ 0, 0 ] := 16; {16 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 64;
           Name := ConstPtr( 'W39L512/3.3V' );
          End;
    $A1,
    $31 : Begin {v1.29}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := WbSecErase;
           Sectors[ 0, 0 ] := 32; {32 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 128;
           case DevId of
            $A1: Name := ConstPtr( 'W39F010/5V' );
            $31: Name := ConstPtr( 'W39L010/3.3V' );
           end;
          End;
    $B5 : Begin {v1.29}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := WbSecErase;
           Sectors[ 0, 0 ] := 64; {64 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( 'W39L020/3.3V' );
          End;
    $B6 : Begin {v1.29}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := WbSecErase;
           Sectors[ 0, 0 ] := 128; {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( 'W39L040/3.3V' );
          End;
    $D6 : Begin {v1.39}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8; {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( 'W39L040A/3.3V' );
          End;
    $3D : Begin {v1.39}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := WbSecErase;
           Sectors[ 0, 0 ] := 128; {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( 'W39V040A/3.3V (LPC)' );
          End;
    $34 : Begin {v1.29}
           Flags  := 0;   {sector mode}
           Progr  := WbSecProgFWH;
           Erase := WbSecEraseFWH;
           Sectors[ 0, 0 ] := 128; {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( 'W39V040FA/3.3V (Firmware Hub)' );
          End;
    $8C : Begin {v1.29}
           Flags  := 2;   {bulk erase}
           Progr  := AMDSecProg;
           Erase := AMDBulkErase;
           Size := 256;
           Name := ConstPtr( 'W49F020/5V' );
          End;
    $0B : Begin {v1.21}
           Flags  := 0;   {sector mode}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 256;
           Name := ConstPtr( 'W49F002U/5V' );
          End;
    $B0,
    $32 : Begin {v1.21}
           Flags  := 0;   {sector mode}
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
           case DevID of
            $B0: Name := ConstPtr( 'W49V002(A)/3.3V (LPC)' );
            $32: Name := ConstPtr( 'W49V002F(A)/3.3V (Firmware Hub)' );
           end;
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Winbond' );
 WBIdChip := True;
End;

Begin
 RegisterFlashManu( $DA, WBIdChip );
End.