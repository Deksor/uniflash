Unit SST; { Unit to communicate with SST chips }

Interface

Implementation

Uses Flash, GenFlash, Tools;

{Unprotect}
Procedure SSTUnprot;
Begin
 FIMemB( ROMBase + $1823 );
 FIMemB( ROMBase + $1820 );
 FIMemB( ROMBase + $1822 );
 FIMemB( ROMBase + $0418 );
 FIMemB( ROMBase + $041B );
 FIMemB( ROMBase + $0419 );
 FIMemB( ROMBase + $041A );
End;

{Protect}
Procedure SSTProt;
Begin
 FIMemB( ROMBase + $1823 );
 FIMemB( ROMBase + $1820 );
 FIMemB( ROMBase + $1822 );
 FIMemB( ROMBase + $0418 );
 FIMemB( ROMBase + $041B );
 FIMemB( ROMBase + $0419 );
 FIMemB( ROMBase + $040A );
End;

{Erase & program one full sector}
Procedure SSTSecProg( Pos, Data : LongInt ); Far;
Var
X        : Word;
Attempt,
Ld, Y    : Byte;

Begin
 {Unprotect chip}
 SSTUnprot;
 {Erase the sector}
 FOMemB( ROMBase, $20 ); {Erase sector setup}
 FOMemB( Pos, $D0 );       {Erase sector containing address Pos}
 Repeat
  X := FiMemB( Pos + 127 );    {Read last byte written}
 Until ( ( X and $A0 ) <> 0 );
 If ( ( X and $A0 ) <> $80 ) then
  Begin
   FlashError := 3; {erasing error}
   FOMemB( ROMBase, $FF ); {reset}
   SSTProt;
   Exit;
  End;
 {Erase verify}
 For X := 0 to 255 do If FIMemB( Pos + X ) <> $FF then
  Begin
   FlashError := 3; {erasing error}
   FOMemB( ROMBase, $FF ); {reset}
   SSTProt;
   Exit;
  End;
 {Program the sector}
 For X := 0 to 255 do
  Begin
   Attempt := 0;
   Repeat
    Ld := FIMemB( Data + X );
    FOMemB( ROMBase, $10 ); {program setup}
    FOMemB( Pos + X, Ld );    {program data byte}
    Ld := Ld and $80;
    Repeat
     Y := FiMemB( Pos + X );    {Read last byte written}
    Until ( ( Y and $80 ) = Ld ) or ( ( Y and $20 ) <> 0 );
    Y := FiMemB( Pos + X );    {Read last byte written}
    Inc( Attempt );
   Until ( Attempt > 3 ) or  ( ( X and $A0 ) = Ld );
   If ( ( X and $A0 ) <> Ld ) then
    Begin
     FlashError := 2; {programming error, timeout}
     FOMemB( ROMBase, $FF ); {reset}
     SSTProt;
     Exit;
    End;
  End;
 {Enable protection again}
 SSTProt;
End;

Function SSTIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean; Far;
Begin
 SSTIdChip := False;
 With CInfo do
  Begin
  {Generic}
   Case DevId of
    $01,
    $07,
    $3D,
    $08,
    $10,
    $12,
    $5D : Begin
           Flags  := 1;   {page mode}
           PgSize := 128; {page size}
           Progr  := GenPageProgB;
          End;
    $04 : Begin
           Flags  := 3;   {small sectors}
           PgSize := 128; {sector size}
           Progr  := SSTSecProg;
           FOMemB( ROMBase, $FF ); {end ID mode}
          End;
    else Exit;
   End;
  {Specific}
   Case DevId of
    $01 : Begin
           Name := ConstPtr( '28EE011/5V' );
           Size := 128;
          End;
    $04 : Begin
           Name := ConstPtr( '28x040 series (5V/3V/2.7V)' );
           Size := 512;
          End;
    $07 : Begin
           Name := ConstPtr( '29EE010/5V' );
           Size := 128;
          End;
    $08 : Begin
           Name := ConstPtr( '29x010 series (3V/2.7 V)' );
           Size := 128;
          End;
    $10 : Begin
           Name := ConstPtr( '29EE020/5V' );
           Size := 256;
          End;
    $12 : Begin
           Name := ConstPtr( '29x020 series (3V/2.7V)' );
           Size := 256;
          End;
    $3D : Begin
           Name := ConstPtr( '29x512 series (3V/2.7V)' );
           Size := 64;
          End;
    $5D : Begin
           Name := ConstPtr( '29EE512/5V' );
           Size := 64;
          End;
   End;
  End;
 CInfo.Manuf := ConstPtr( 'SST' );
 SSTIdChip := True;
End;

Begin
 RegisterFlashManu( $3F, SSTIdChip );
End.
