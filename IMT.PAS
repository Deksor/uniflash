
Unit IMT; { Unit to communicate with IMT chips } {v1.21}

Interface
{Used device ID 7F - it's actually $1F, but Atmel has $1F}
{Detection needs to be heavily modified}

Implementation

Uses Flash, GenFlash, Tools;

Const 
  ProgAMDSecProg : Fl_Program = @AMDSecProg;
  EraseAMDSecErase : Fl_Erase = @AMDSecErase;

Function IMTIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean;
Far;
Begin
  IMTIdChip := False;
  With CInfo Do
    Begin
      Case DevId Of 
        $A0,
        $A3,
        $A5,
        $A6 :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgAMDSecProg );
                SetChipErase( Erase, EraseAMDSecErase );
                Sectors[ 0, 0 ] := 256;  {256 x 512b}
                Sectors[ 0, 1 ] := 4;
                Size := 128;
                Case DevId Of 
                  $A0 : Name := ConstPtr( 'IM29F001T/5V' );
                  $A3 : Name := ConstPtr( 'IM29F001B/5V' );
                  $A5 : Name := ConstPtr( 'IM29LV001T/3.3V' );
                  $A6 : Name := ConstPtr( 'IM29LV001B/3.3V' );
                End;
              End;
        $A1,
        $A2 :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgAMDSecProg );
                SetChipErase( Erase, EraseAMDSecErase );
                Sectors[ 0, 0 ] := 512;  {512 x 512b}
                Sectors[ 0, 1 ] := 4;
                Size := 256;
                Case DevId Of 
                  $A1 : Name := ConstPtr( 'IM29F002T/5V' );
                  $A2 : Name := ConstPtr( 'IM29F002B/5V' );
                End;
              End;
        $AF,
        $AE,
        $A7,
        $A8 :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgAMDSecProg );
                SetChipErase( Erase, EraseAMDSecErase );
                Sectors[ 0, 0 ] := 512;  {512 x 1024b}
                Sectors[ 0, 1 ] := 8;
                Size := 512;
                Case DevId Of 
                  $AF : Name := ConstPtr( 'IM29F004T/5V' );
                  $AE : Name := ConstPtr( 'IM29F004B/5V' );
                  $A7 : Name := ConstPtr( 'IM29LV004T/3.3V' );
                  $A8 : Name := ConstPtr( 'IM29LV004B/3.3V' );
                End;
              End;
        Else Exit;
      End;
    End;
  CInfo.Manuf := ConstPtr( 'IMT' );
  IMTIdChip := True;
End;

Const 
  IdIMTIdChip : Fl_IdChip = @IMTIdChip;


Begin
  RegisterFlashManu( $7F, IdIMTIdChip ); {It's actually $1F, but Atmel has $1F}
End.
