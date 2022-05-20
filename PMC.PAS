Unit PMC; { Unit to communicate with PMC chips } {v1.21}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Procedure PMCSecProgFWH( Pos, Data : LongInt ); Far; {Pm49FL004/008} {v1.31}
begin
  {Unprotect}
  FOMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) and $FC);
  AMDSecProg(Pos,Data);
  {Protect}
  FOMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(Pos and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) or $01);
end;

Procedure PMCSecEraseFWH( SAddr: LongInt ); Far; {Pm49FL004/008} {v1.31}
begin
  {Unprotect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) and $FC);
  AMDSecErase(SAddr);
  {Protect}
  FOMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10,
   FIMemB(SAddr and $FFFF0000+$FFC00002-LongInt(CurCInfo.Size) shl 10) or $01);
end;

Procedure PMCSecProgFWH2( Pos, Data : LongInt ); Far; {Pm49FL002} {v1.31}
var X:LongInt;
begin
  X:=Pos and $FFFF8000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  if (Pos>=$38000) and (Pos<$3C000) then X:=(Pos-$4000) and $FFFF8000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  {Unprotect}
  FOMemB(X,FIMemB(X) and $FC);
  AMDSecProg(Pos,Data);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
end;

Procedure PMCSecEraseFWH2( SAddr: LongInt ); Far; {Pm49FL002} {v1.31}
var X:LongInt;
begin
  X:=SAddr and $FFFF8000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  if (SAddr>=$38000) and (SAddr<$3C000) then X:=(SAddr-$4000) and $FFFF8000+$FFC00002-LongInt(CurCInfo.Size) shl 10;
  {Unprotect}
  FOMemB(X,FIMemB(X) and $FC);
  AMDSecErase(SAddr);
  {Protect}
  FOMemB(X,FIMemB(X) or $01);
end;

Function PMCIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 PMCIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $1D : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
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
           Name := ConstPtr( 'Pm29F002T/5V' ); {Top Boot Block}
          End;
    $2D : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 768;
           Sectors[ 3, 0 ] := 1;  {1 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 256;
           Name := ConstPtr( 'Pm29F002B/5V' ); {Bottom Boot Block}
          End;
    $1E : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 3;  {3 x 128k}
           Sectors[ 0, 1 ] := 1024;
           Sectors[ 1, 0 ] := 1;  {1 x 96k}
           Sectors[ 1, 1 ] := 768;
           Sectors[ 2, 0 ] := 2;  {2 x 8k}
           Sectors[ 2, 1 ] := 64;
           Sectors[ 3, 0 ] := 1;  {1 x 16k}
           Sectors[ 3, 1 ] := 128;
           Size := 512;
           Name := ConstPtr( 'Pm29F004T/5V or Pm29LV104T/3.3V' ); {Top Boot Block}
          End;
    $2E : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 1;  {1 x 16k}
           Sectors[ 0, 1 ] := 128;
           Sectors[ 1, 0 ] := 2;  {2 x 8k}
           Sectors[ 1, 1 ] := 64;
           Sectors[ 2, 0 ] := 1;  {1 x 96k}
           Sectors[ 2, 1 ] := 768;
           Sectors[ 3, 0 ] := 3;  {3 x 128k}
           Sectors[ 3, 1 ] := 1024;
           Size := 512;
           Name := ConstPtr( 'Pm29F004B/5V or Pm29LV104B/3.3V' ); {Bottom Boot Block}
          End;
    $1B : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 16;  {16 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 64;
           Name := ConstPtr( 'Pm39LV512R/3.3V' );
          End;
    $1C : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 32;  {32 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 128;
           Name := ConstPtr( 'Pm39LV010R/3.3V' );
          End;
    $6D : Begin {v1.31}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := PMCSecProgFWH2;
           Erase := PMCSecEraseFWH2;
           Sectors[ 0, 0 ] := 64;  {64 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 256;
           Name := ConstPtr( 'Pm49FL002/3.3V (LPC/FWH)' );
          End;
    $6E : Begin {v1.31}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := PMCSecProgFWH;
           Erase := PMCSecEraseFWH;
           Sectors[ 0, 0 ] := 128;  {128 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 512;
           Name := ConstPtr( 'Pm49FL004/3.3V (LPC/FWH)' );
          End;
    $6A : Begin {v1.31}
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := PMCSecProgFWH;
           Erase := PMCSecEraseFWH;
           Sectors[ 0, 0 ] := 256;  {256 x 4k}
           Sectors[ 0, 1 ] := 32;
           Size := 1024;
           Name := ConstPtr( 'Pm49FL008/3.3V (LPC/FWH)' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'PMC' );
 PMCIdChip := True;
End;

Begin
 RegisterFlashManu( $9D, PMCIdChip );
End.