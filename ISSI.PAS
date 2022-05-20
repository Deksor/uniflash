Unit ISSI; { Unit to communicate with ISSI chips } {v1.21}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Function ISSIIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 ISSIIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $B4 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 128;
           Name := ConstPtr( 'IS28F010/12V' );
          End;
    $BD : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := AMDFlashWrite;
           Erase := AMDFlashErase;
           Size := 256;
           Name := ConstPtr( 'IS28F020/12V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'ISSI' );
 ISSIIdChip := True;
End;

Begin
 RegisterFlashManu( $D5, ISSIIdChip );
End.