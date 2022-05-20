Unit WinBond; { Unit to communicate with WinBond chips }

Interface

Implementation

Uses Flash, GenFlash, Tools;

Function WBIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 WBIdChip := False;
 With CInfo do
  Begin
  {Generic}
   Case DevId of
    $41,
    $45,
    $48 : Begin
           Flags  := 1;   {page mode}
           PgSize := 128; {page size}
           Progr  := GenPageProgB;
          End;
    $4F : Begin
           Flags  := 1;   {page mode}
           PgSize := 256; {page size}
           Progr  := GenPageProgB;
          End;
    else Exit;
   End;
  {Specific}
   Case DevId of
    $41 : Begin
           Name := ConstPtr( 'W29EE011/5V or W29C010/5V' );
           Size := 128;
          End;
    $45 : Begin
           {note: 2 write-protectable boot blocks}
           Name := ConstPtr( 'W29C020/5V' );
           Size := 256;
          End;
    $48 : Begin
           Name := ConstPtr( 'W29EE512/5V' );
           Size := 64;
          End;
    $4F : Begin
           Name := ConstPtr( 'W29C101/5V' );
           Size := 128;
          End;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'Winbond' );
 WBIdChip := True;
End;

Begin
 RegisterFlashManu( $5A, WBIdChip );
End.
