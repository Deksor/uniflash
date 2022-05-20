Unit Macronix; { Unit to communicate with Macronix chips }

{NOTE: This is experimental and based on some quick }
{      reverse engineering, we currently don't have }
{      any datasheets on Macronix chips ...         }

Interface

Implementation

Uses Flash, GenFlash, Tools;

Function MxIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 MxIdChip := False;
 With CInfo do
  Begin
   Case DevId of
    $11 : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 8;  {8 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( 'MXIC28F1000P/12V' );
          End;
    $1A : Begin
           Flags  := 0;   {sector mode}
           PgSize := 128; {'page' size, program 128 bytes at a time}
           Progr  := IntelSecProg;
           Erase := IntelSecErase;
           Sectors[ 0, 0 ] := 7;  {7 x 16k}
           Sectors[ 0, 1 ] := 7;
           Sectors[ 1, 0 ] := 4;  {4 x 4k}
           Sectors[ 1, 1 ] := 1;
           Sectors[ 2, 0 ] := 0;  {end of list}
           Size := 128;
           Name := ConstPtr( 'MXIC28F1000AP/12V' );
          End;
    else Exit;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Macronix' );
 MxIdChip := True;
End;

Begin
 RegisterFlashManu( $42, MxIdChip );
End.
