
Unit TI; { Unit to communicate with TI chips } {v1.22}

Interface

Implementation

Uses Flash, GenFlash, Tools;

Const 
  ProgAMDSecProg : Fl_Program = @AMDSecProg;
  EraseAMDSecErase : Fl_Erase = @AMDSecErase;

Function TIIdChip( DevId : Byte; Var CInfo : ChipInfo ) : Boolean;
Far;
Begin
  TIIdChip := False;
  With CInfo Do
    Begin
      Case DevId Of 
        $94 :
              Begin
                Flags  := 0;   {sector mode}
                PgSize := 128; {'page' size, program 128 bytes at a time}
                SetChipProgram( Progr, ProgAMDSecProg );
                SetChipErase( Erase, EraseAMDSecErase );
                Sectors[ 0, 0 ] := 8; {8 x 64k}
                Sectors[ 0, 1 ] := 512;
                Size := 512;
                Name := ConstPtr( 'TMS29xF040 (3.3/2.7V)' );
              End;
        Else Exit;
      End;
    End;
  CInfo.Manuf := ConstPtr( 'Texas Instruments' );
  TIIdChip := True;
End;

Const 
  IdTIIdChip : Fl_IdChip = @TIIdChip;


Begin
  RegisterFlashManu( $97, IdTIIdChip );
End.
