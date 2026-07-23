Unit ISSI; { Unit to communicate with ISSI chips } {v1.21}
Interface


Implementation

Uses Flash, GenFlash, Tools;

Const
 ProgAMDFlashWrite : Fl_Program = @AMDFlashWrite;
 EraseAMDFlashErase : Fl_Erase = @AMDFlashErase;

Function ISSIIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 ISSIIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $B4 : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           SetChipProgram( Progr, ProgAMDFlashWrite );
           SetChipErase( Erase, EraseAMDFlashErase );
           Size := 128;
           Name := ConstPtr( 'IS28F010/12V' );
          End;
    $BD : Begin
           Flags  := 6;   {bulk erase, need blanking}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           SetChipProgram( Progr, ProgAMDFlashWrite );
           SetChipErase( Erase, EraseAMDFlashErase );
           Size := 256;
           Name := ConstPtr( 'IS28F020/12V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'ISSI' );
 ISSIIdChip := True;
End;
Const
 IdISSIIdChip : Fl_IdChip = @ISSIIdChip;


Begin
 RegisterFlashManu( $D5, IdISSIIdChip );
End.