Unit ST; { Unit to communicate with ST chips } {v1.22}
Interface

Implementation

Uses Flash, GenFlash, Tools;

procedure Unprotect(SAddr:LongInt); {v1.29}
begin
 FOMemB(SAddr and $FFFF0000+$FC00002-LongInt(CurCInfo.Size) shl 10,
  FIMemB(SAddr and $FFFF0000+$FC00002-LongInt(CurCInfo.Size) shl 10) and $F8); {Disable Write-Lock}
end;

procedure Protect(SAddr:LongInt); {v1.29}
begin
 FOMemB(SAddr and $FFFF0000+$FC00002-LongInt(CurCInfo.Size) shl 10,
  FIMemB(SAddr and $FFFF0000+$FC00002-LongInt(CurCInfo.Size) shl 10) or $01); {Enable Write-Lock}
end;

procedure UnprotectB(SAddr:LongInt); {v1.29}
begin
 if SAddr>=LongInt(CurCInfo.Size) shl 10-$8000 then
  begin
    if SAddr>=LongInt(CurCInfo.Size) shl 10-$6000 then
     begin
       if SAddr>=LongInt(CurCInfo.Size) shl 10-$4000 then
        begin
          SAddr:=$FBFC002;
        end
       else SAddr:=$FBFA002;
     end
    else SAddr:=$FBF8002;
  end
 else SAddr:=SAddr and $FFFF0000+$FC00002-LongInt(CurCInfo.Size);
 FOMemB(SAddr,FIMemB(SAddr) and $F8); {Disable Write-Lock}
end;

procedure ProtectB(SAddr:LongInt); {v1.29}
begin
 if SAddr>=LongInt(CurCInfo.Size) shl 10-$8000 then
  begin
    if SAddr>=LongInt(CurCInfo.Size) shl 10-$6000 then
     begin
       if SAddr>=LongInt(CurCInfo.Size) shl 10-$4000 then
        begin
          SAddr:=$FBFC002;
        end
       else SAddr:=$FBFA002;
     end
    else SAddr:=$FBF8002;
  end
 else SAddr:=SAddr and $FFFF0000+$FC00002-LongInt(CurCInfo.Size);
 FOMemB(SAddr,FIMemB(SAddr) or $01); {Enable Write-Lock}
end;

procedure STSecErase(SAddr:LongInt);Far; {v1.29}
begin
 Unprotect(SAddr);
 IntelSecErase(SAddr);
 Protect(SAddr);
end;

procedure STSecProg(Pos,Data:LongInt);Far; {v1.29}
begin
 Unprotect(Pos);
 IntelSecProg(Pos,Data);
 Protect(Pos);
end;

procedure STSecEraseB(SAddr:LongInt);Far; {v1.29}
begin
 UnprotectB(SAddr);
 IntelSecErase(SAddr);
 ProtectB(SAddr);
end;

procedure STSecProgB(Pos,Data:LongInt);Far; {v1.29}
begin
 UnprotectB(Pos);
 IntelSecProg(Pos,Data);
 ProtectB(Pos);
end;

Function STIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 STIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $A8 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 32;
           Name := ConstPtr( 'M28F256/12V' );
          End;
    $02 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 64;
           Name := ConstPtr( 'M28F512/12V' );
          End;
    $07 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 128;
           Name := ConstPtr( 'M28F101/12V' );
          End;
    $F4,
    $F5 : Begin {v1.37}
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 256;
           Case DevId of
            $F4 : Name := ConstPtr( 'M28F201/12V' );
            $F5 : Name := ConstPtr( 'M28W201/12V' );
           End;
          End;
    $24,
    $27 : Begin
           Flags  := 2;   {bulk erase}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDBulkErase;
           Size := 64;
           Case DevId of
            $24 : Name := ConstPtr( 'M29F512B/5V' );
            $27 : Name := ConstPtr( 'M29W512B/3V' );
           End;
          End;
    $20,
    $23 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 128;
           Size := 128;
           Case DevId of
            $20 : Name := ConstPtr( 'M29F010B/5V' );
            $23 : Name := ConstPtr( 'M29W010B/3V' );
           End;
          End;
    $D0 : Begin
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
           Name := ConstPtr( 'M29F100(B)T/5V' );
          End;
    $D1 : Begin
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
           Name := ConstPtr( 'M29F100(B)B/5V' );
          End;
    $B0,
    $D3,
    $C4,
    $51 : Begin
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
            $B0 : Name := ConstPtr( 'M29F002(B)(N)T/5V' );
            $D3 : Name := ConstPtr( 'M29F200(B)T/5V' );
            $C4 : Name := ConstPtr( 'M29W022BT/3V' );
            $51 : Name := ConstPtr( 'M29W200BT/3V' );
           End;
          End;
    $34,
    $D4,
    $C3,
    $57 : Begin
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
            $34 : Name := ConstPtr( 'M29F002(B)B/5V' );
            $D4 : Name := ConstPtr( 'M29F200(B)B/5V' );
            $C3 : Name := ConstPtr( 'M29W022BB/3V' );
            $57 : Name := ConstPtr( 'M29W200BB/3V' );
           End;
          End;
    $E2,
    $E3 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           case DevId of
            $E2 : Name := ConstPtr( 'M29F040(B)/5V' );
            $E3 : Name := ConstPtr( 'M29W040(B)/3V' );
           End;
          End;
    $D5,
    $EA,
    $EE : Begin
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
            $D5 : Name := ConstPtr( 'M29F400(B)T/5V' );
            $EA : Name := ConstPtr( 'M29W004(B)T/3V' );
            $EE : Name := ConstPtr( 'M29W400(B)T/3V' );
           End;
          End;
    $D6,
    $EB,
    $EF : Begin
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
            $D6 : Name := ConstPtr( 'M29F400(B)B/5V' );
            $EB : Name := ConstPtr( 'M29W004(B)B/3V' );
            $EF : Name := ConstPtr( 'M29W400(B)B/3V' );
           End;
          End;
    $F1 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           Name := ConstPtr( 'M29F080A/5V' );
          End;
    $EC,
    $D2,
    $D7 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 15; {15 x 64k}
           Sectors[ 0, 1 ] := 512;
           Sectors[ 1, 0 ] := 1;  {1 x 32k}
           Sectors[ 1, 1 ] := 256;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 1024;
           case DevId of
            $EC : Name := ConstPtr( 'M29F800AT/5V' );
            $D2 : Name := ConstPtr( 'M29W008(A)T/3V' );
            $D7 : Name := ConstPtr( 'M29W800(A)T/3V' );
           End;
          End;
    $58,
    $DC,
    $5B : Begin
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
           Sectors[ 3, 0 ] := 15; {15 x 64k}
           Sectors[ 3, 1 ] := 512;
           Size := 1024;
           case DevId of
            $58 : Name := ConstPtr( 'M29F800AB/5V' );
            $DC : Name := ConstPtr( 'M29W008(A)B/3V' );
            $5B : Name := ConstPtr( 'M29W800(A)B/3V' );
           End;
          End;
    $AD : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32; {32x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'M29F016B/5V' );
          End;
    $CC,
    $C4 : Begin
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
           case DevId of
            $CC : Name := ConstPtr( 'M29F160BT/5V' );
            $C4 : Name := ConstPtr( 'M29W160BT/DT/3V' );
           End;
          End;
    $4B,
    $49 : Begin
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
           case DevId of
            $4B : Name := ConstPtr( 'M29F160BB/5V' );
            $49 : Name := ConstPtr( 'M29W160BB/DB/3V' );
           End;
          End;
    $29,
    $31 : Begin {v1.29}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := STSecProgB;
           Erase := STSecEraseB;
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
            $29 : Name := ConstPtr( 'M50FW002/3V (FWH)' );
            $31 : Name := ConstPtr( 'M50LPW002/3V (LPC)' );
           End;
          End;
    $26, {v1.29}
    $2C,
    $08, {v1.37}
    $28 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := STSecProg;
           Erase := STSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           case DevId of
            $2C : Name := ConstPtr( 'M50FW040/3V (FWH)' );
            $26 : Name := ConstPtr( 'M50LPW040/3V (LPC)' );
            $08 : Name := ConstPtr( 'M50FLW040A/3V (LPC/FWH)' );
            $28 : Name := ConstPtr( 'M50FLW040B/3V (LPC/FWH)' );
           End;
          End;
    $2D, {v1.29}
    $2F,
    $80, {v1.37}
    $81 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := STSecProg;
           Erase := STSecErase;
           Sectors[ 0, 0 ] := 16; {16 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 1024;
           case DevId of
            $2D : Name := ConstPtr( 'M50FW080/3V (FWH)' );
            $2F : Name := ConstPtr( 'M50LPW080/3V (LPC)' );
            $80 : Name := ConstPtr( 'M50FLW080A/3V (LPC/FWH)' );
            $81 : Name := ConstPtr( 'M50FLW080B/3V (LPC/FWH)' );
           End;
          End;
    $2E : Begin {v1.37}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := STSecProg;
           Erase := STSecErase;
           Sectors[ 0, 0 ] := 32; {32 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 2048;
           Name := ConstPtr( 'M50FW016/3V (FWH)' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'STMicroelectronics' );
 STIdChip := True;
End;

Begin
 RegisterFlashManu( $20, STIdChip );
End.