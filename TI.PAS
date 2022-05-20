Unit TI; { Unit to communicate with TI chips } {v1.22}
Interface

Implementation

Uses Flash, GenFlash, Tools;

Function TIIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 TIIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $E5 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWriteW;
           Erase := AMDFlashEraseW;
           Size := 128;
           Name := ConstPtr( 'TMS28F210/12V' );
          End;
    $94 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDSecProg;
           Erase := AMDSecErase;
           Sectors[ 0, 0 ] := 8; {8 x 64k}
           Sectors[ 0, 1 ] := 512;
           Size := 512;
           Name := ConstPtr( 'TMS29xF040 (3.3/2.7V)' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Texas Instruments' );
 TIIdChip := True;
End;

Begin
 RegisterFlashManu( $97, TIIdChip );
End.