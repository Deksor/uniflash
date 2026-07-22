{$R-}

Unit PCI;  { Unit to communicate with chipsets }

Interface

Uses AMIBIOS, AsusBIOS;

Const 
  PCICfIdx    = $CF8;
  PCICfData   = $CFC;

Var 
  NorthFunc, SouthFunc, LPCFunc: Word;
  NorthPos,SouthPos,PMUPos,CurPCIROM,PCIROMBus,PCIROMDev,PCIROMFun,LPCBase: Byte
  ;
  CurrentChipset, CurrentPCICard: string;
  WantToUseAMI, AMIUsed, ChipsetFound, ROMEnabled, PCIROMEnabled: Boolean;
  WantToUseAsus, AsusUsed: Boolean;
  PCIROMs: array[1..20] Of 
           Record
             MaxSize      : LongInt;
             VenID, DevID : Word;
             Bus, Pos     : Byte;
           End;
  BIOSID: array[1..8] Of Char; {v1.34}

Procedure OPortD( Prt : Word; Val : LongInt );
Function  IPortD( Prt : Word ) : LongInt;
Function  GetPCIRegD( Bus, Dev, Func, Reg : Byte ) : LongInt;
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Function  LocatePIIX : {byte}Boolean; {v1.22 byte->boolean}
Procedure GetBIOSID;
Procedure RomEnable( Map : boolean);
Procedure ShadowDisable_Aladdin; {v1.31}
Procedure ShadowRestore_Aladdin; {v1.31}

Implementation

Uses Tools,Flash,Crt,DMI;

{ PortD[ x ] := y }
Procedure OPortD( Prt : Word; Val : LongInt );
Assembler;
Asm
DB     66H
MOV    AX,WORD PTR Val
MOV    DX,Prt
DB     66H
OUT    DX,AX
End;

{ y := PortD[ x ] }
Function IPortD( Prt : Word ) : LongInt;
Assembler;
Asm
MOV    DX,Prt
DB     66H
IN     AX,DX
DB     66H
MOV    DX,AX
DB     66H
SHR    DX,16
End;

{Read PCI configuration reg}
Function GetPCIRegD( Bus, Dev, Func, Reg : Byte ) : LongInt;
Begin
  OPortD( PCICfIdx, $80000000 Or
         ( LongInt( Bus ) shl 16 ) or
  ( ( LongInt( Dev ) and $1F ) shl 11 ) or
  ( ( LongInt( Func ) and $7 ) shl 8 ) or
  ( Reg And $FC ) );
  GetPCIRegD := IPortD( PCICfData );
End;

{Write PCI configuration reg}
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Begin
  OPortD( PCICfIdx, $80000000 Or
         ( LongInt( Bus ) shl 16 ) or
  ( ( LongInt( Dev ) and $1F ) shl 11 ) or
  ( ( LongInt( Func ) and $7 ) shl 8 ) or
  ( Reg And $FC ) );
  OPortD( PCICfData, Value );
End;

Function LPCRead(Index:Byte): Byte; {v1.27}
Begin
  Port[LPCBase] := Index;
  LPCRead := Port[LPCBase+1];
End;

Procedure LPCWrite(Index,Data:Byte); {v1.27}
Begin
  Port[LPCBase] := Index;
  Port[LPCBase+1] := Data;
End;

Procedure LPCUnlock; {v1.27}
Begin
  Port[LPCBase] := $87;
  Port[LPCBase] := $87;
  Port[LPCBase] := $87;
  Port[LPCBase] := $01;
  Port[LPCBase] := $55;
  Case LPCBase Of 
    $2E: Port[LPCBase] := $55;
    $4E: Port[LPCBase] := $AA;
  End;
End;

Procedure LPCLock_ITE; {v1.39}
Begin
  LPCWrite($02,LPCRead($02) or 2);
End;

Procedure LPCLock_WB; {v1.39}
Begin
  Port[LPCBase] := $AA;
End;

Function LocatePIIX : Boolean{byte}; {v1.22 byte->boolean}

Var 
  Pos_,
  NorthRev,
  SouthRev  : Byte;
  SouthMan,
  SouthId,
  NorthMan,
  NorthId   : Word;
  NorthName,
  SouthName,
  LPCName : String;

Function LPCDetectAt(Base: Byte): Word;

Var ID: Word;
Begin
  LPCBase := Base;
  LPCName := '';
  LPCDetectAt := $0;
  LPCUnlock;
  ID := 256*word(LPCRead($20));
  ID := ID+LPCRead($21);
  Case ID Of 
    $8702:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'ITE IT8702F';
           End; {v1.39}
    $8705:
           Begin
             LPCDetectAt := $0100;
             LPCName := 'ITE IT8700F/05F';
           End;
    $8710:
           Begin
             LPCDetectAt := $0100;
             LPCName := 'ITE IT8710F';
           End;
    $8711:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'ITE IT8711F';
           End; {v1.39}
    $8712:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'ITE IT8712F';
           End; {v1.39}
    $8722:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'ITE IT8722F';
           End; {v1.39}
  End;
  If LPCName<>'' Then
    Begin
      LPCLock_ITE;
      Exit;
    End;
  Case ID And $FFF0 Of 
    $5210,
    $5230:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'Winbond W83627(H)F';
           End; {v1.39}
    $5950:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'Winbond W83627SF/GF';
           End; {v1.39}
    $6010:
           Begin
             LPCDetectAt := $0200;
             LPCName := 'Winbond W83697(H)F';
           End;
    $6800:
           Begin
             LPCDetectAt := $0200;
             LPCName := 'Winbond W83697SF';
           End;
    $6810:
           Begin
             LPCDetectAt := $0200;
             LPCName := 'Winbond W83697UF';
           End;
    $7080:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'Winbond W83637HF';
           End; {v1.39}
    $8280:
           Begin
             LPCDetectAt := $0000;
             LPCName := 'Winbond W83627THF';
           End; {v1.39}
  End;
  If LPCName<>'' Then
    Begin
      LPCLock_WB;
      Exit;
    End;
  LPCBase := 0;
  LogWrite('Unknown LPC ID '+Hw(ID));
End;

Function LPCDetect: Word; {v1.27}
Begin
  LogWrite('Detecting LPC Super I/O chip...');
  LPCDetect := LPCDetectAt($2E);
  If LPCBase=0 Then LPCDetect := LPCDetectAt($4E);
  If LPCBase<>0 Then LogWrite('Detected '+LPCName+' at '+Hb(LPCBase));
End;

Begin
  If Port[$CFB]<>$FF Then {v1.26}
    Port[$CFB] := Port[$CFB] Or $1; {Set PCI configuration mechanism #1}
 {Locate north bridge}
  For Pos_ := 0 To $FF Do
    If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ And $07, $00 ) And $FFFF ) <> $FFFF
      Then
      If ( GetPCIRegD( $00, Pos_ shr 3,
         Pos_ And $07, $08 ) shr 8 ) = $60000 Then Break;
  If Pos_ = $FF Then {v1.22}
    Begin
      LocatePIIX := False;
      Exit;
    End
  Else LocatePIIX := True;
  NorthPos := Pos_;
 {Get north bridge MID & DID}
  NorthMan := GetPCIRegD( $00, NorthPos shr 3, NorthPos And $07, $00 );
  NorthId  := GetPCIRegD( $00, NorthPos shr 3, NorthPos And $07, $00 ) shr 16;
 {Get north bridge rev ID}
  NorthRev := GetPCIRegD( $00, NorthPos shr 3, NorthPos And $07, $08 );

 {Locate south bridge}
  For Pos_ := 0 To $FF Do
    If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ And $07, $00 ) And $FFFF ) <> $FFFF
      Then
      If ( GetPCIRegD( $00, Pos_ shr 3,
         Pos_ And $07, $08 ) shr 8 ) = $60100 Then Break;
  If Pos_ = $FF Then {v1.22 for i430MX}
    For Pos_ := 0 To $FF Do
      If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ And $07, $00 ) And $FFFF ) <> $FFFF
        Then
        If ( GetPCIRegD( $00, Pos_ shr 3,
           Pos_ And $07, $08 ) shr 8 ) = $68000 Then Break;
  If Pos_ = $FF Then {v1.31 for old chipsets}
    For Pos_ := 0 To $FF Do
      If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ And $07, $00 ) And $FFFF ) <> $FFFF
        Then
        If ( GetPCIRegD( $00, Pos_ shr 3,
           Pos_ And $07, $08 ) shr 8 ) = $00000 Then Break;
  SouthPos := Pos_;
 {Get south bridge MID & DID}
  SouthMan := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $07, $00 );
  SouthID := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $07, $00 ) shr 16;
 {Get south bridge rev ID}
  SouthRev := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $07, $08 );

  CurrentChipset := '';

  NorthFunc := 0; {No special treatment necessary}
  SouthFunc := 0; {Same}
  LPCFunc   := 0; {v1.27}
  NorthName := '';
  SouthName := '';
  LPCName := '';

 {Id northbridge}
  If NorthMan = $8086 {Intel} Then
    Begin
      Case NorthId Of {case v1.21}
        $4A3: If NorthRev>=$10 Then NorthName := 'i82433NX'
              Else NorthName := 'i82433LX';
        $122D: NorthName := 'i82437FX';
        $1235: NorthName := 'i82437MX';
        $1237: NorthName := 'i82441FX';
        $1250: NorthName := 'i82439HX';
        $7030: NorthName := 'i82437VX';
        $7100: NorthName := 'i82439TX';
        $7180: NorthName := 'i82443LX/EX';
        $7190, $7192: NorthName := 'i82443BX/ZX';
        $71A0, $71A2: NorthName := 'i82443GX';
        $84C4: NorthName := 'i82454KX/GX';
        $7120: NorthName := 'i82810';
        $7122: NorthName := 'i82810-DC100';
        $7124: NorthName := 'i82810E';
        $1130: NorthName := 'i82815';
        $2500: NorthName := 'i82820';
        $3575: NorthName := 'i82830M';
        $1A21: NorthName := 'i82840';
        $1A30: NorthName := 'i82845';
        $2560: NorthName := 'i82845G/P';
        $2530: NorthName := 'i82850';
        $3580: NorthName := 'i8285xGM';
        $3340: NorthName := 'i82855PM';
        $2531: NorthName := 'i82860';
        $2570: NorthName := 'i82865'; {v1.34}
        $2578: NorthName := 'i82875/iE7210';
        $255D: NorthName := 'iE7205';
        $2588: NorthName := 'iE7221'; {v1.39}
        $3592: NorthName := 'iE7320'; {v1.39}
        $2540: NorthName := 'iE7500';
        $254C: NorthName := 'iE7501';
        $2550: NorthName := 'iE7505';
        $3590: NorthName := 'iE7520'; {v1.39}
        $359E: NorthName := 'iE7525'; {v1.39}
        $0500: NorthName := 'iE8870'; {v1.39}
        $2580: NorthName := 'i829xxx'; {v1.37}
        $2590: NorthName := 'i829xxxM'; {v1.39}
      End;
    End
  Else
    If NorthMan = $1106 {VIA} Then
      Begin
        Case NorthId Of {case v1.21}
          $505:
                Begin {v1.37}
                  NorthFunc := $0100; {VIA A8/A9 scheme}
                  NorthName := 'VT82C505';
                End;
          $576:
                Begin
                  NorthFunc := $0100; {VIA A8/A9 scheme}
                  NorthName := 'VT82C576M';
                End;
          $585: NorthName := 'VT82C585VP/VPX';
          $595: NorthName := 'VT82C595/AMD-640';
          $597: NorthName := 'VT82C597';
          $598: NorthName := 'VT82C598(AT)';
          $685:
                Begin
                  NorthFunc := $0100; {VIA A8/A9 scheme}
                  NorthName := 'VT82C685';
                End;
          $501: NorthName := 'VT8501';
          $691: NorthName := 'VT82C691/693(A)/694X/T';
          $693: NorthName := 'VT82C693(A)';
          $601: NorthName := 'VT8601';
          $605: NorthName := 'VT8605';
          $391: NorthName := 'VT8371';
          $305: NorthName := 'VT8363(A)/8365';
          $3099: NorthName := 'VT8366(A)';
          $3091: NorthName := 'VT8633';
          $3101: NorthName := 'VT8653';
          $3102: NorthName := 'VT8662';
          $3103: NorthName := 'VT8615';
          $3112: NorthName := 'VT8361';
          $3133: NorthName := 'VT3133';
          $3148: NorthName := 'VT8751';
          $3128: NorthName := 'VT8753(A)/8754';
          $3189: NorthName := 'VT8377';
          $3205: NorthName := 'VT8378';
        End;
      End
  Else
    If NorthMan = $1022 {AMD} Then {v1.20}
      Begin
        Case NorthId Of {case v1.21}
          $7006: NorthName := 'AMD-751';
          $700E: NorthName := 'AMD-761';
          $700C: NorthName := 'AMD-762';
          $7454: NorthName := 'AMD-8151'; {v1.36}
        End;
      End
  Else
    If NorthMan = $1039 {SiS} Then
      Begin
        SouthFunc := $0503; {SiS reg. 45 bits 5,2}
        Case NorthId Of 
          $496:
                Begin
                  NorthFunc := $0200; {SiS reg. D0 scheme}
                  SouthFunc := 0;
                  NorthName := 'SiS 85C496+497';
                End;
          $406:
                Begin
                  SouthFunc := $0501; {SiS internal reg. 80h}
                  NorthName := 'SiS 501/5101/5501';
                End;
          $5511:
                 Begin
                   SouthFunc := $0502; {SiS internal reg. 50h}
                   NorthName := 'SiS 5511';
                 End;
          $5571: NorthName := 'SiS 5571';
          $5591: NorthName := 'SiS 5591/5592';
          $5596:
                 Begin
                   NorthName := 'SiS 5596';
                   SouthFunc := $0502; {SiS internal reg. 50h}
                   LPCFunc := LPCDetect; {v1.27}
                 End;
          $5597: NorthName := 'SiS 5597/5598/5581/5120';
          $0530: NorthName := 'SiS 530';
          $0540:
                 Begin
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   NorthName := 'SiS 540';
                 End;
          $5600: NorthName := 'SiS 600';
          $0620: NorthName := 'SiS 620';
          $0630:
                 Begin
                   NorthName := 'SiS 630';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect; {v1.27}
                 End;
          $0635:
                 Begin
                   NorthName := 'SiS 635';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0640:
                 Begin
                   NorthName := 'SiS 640';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0645:
                 Begin
                   NorthName := 'SiS 645';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0646:
                 Begin
                   NorthName := 'SiS 645DX';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0648:
                 Begin {v1.31}
                   NorthName := 'SiS 648';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0650:
                 Begin
                   NorthName := 'SiS 650';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0651:
                 Begin {v1.31}
                   NorthName := 'SiS 651';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0655:
                 Begin {v1.31}
                   NorthName := 'SiS 655';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0730:
                 Begin
                   NorthName := 'SiS 730';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0733:
                 Begin {v1.31}
                   NorthName := 'SiS 733';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0735:
                 Begin
                   NorthName := 'SiS 735';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0740:
                 Begin
                   NorthName := 'SiS 740';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0745:
                 Begin {v1.31}
                   NorthName := 'SiS 745';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0746:
                 Begin {v1.31}
                   NorthName := 'SiS 746';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0748:
                 Begin {v1.31}
                   NorthName := 'SiS 748';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
          $0755:
                 Begin {v1.31}
                   NorthName := 'SiS 755';
                   SouthFunc := $0504; {SiS reg. 45 bits 7,6}
                   LPCFunc := LPCDetect;
                 End;
        End;
      End
  Else
    If NorthMan = $10B9 {ALi} Then
      Begin
        Case NorthId Of 
          $1451:
                 Begin
                   NorthFunc := $0300; {ALi Aladdin}
                   NorthName := 'M1451';
                 End;
          $1489:
                 Begin
                   NorthFunc := $0301; {ALi FinALi}
                   NorthName := 'M1489';
                 End;
          $1521: NorthName := 'M1521';
          $1531: NorthName := 'M1531(B)';
          $1541: NorthName := 'M1541/1542';
          $1561: NorthName := 'M1561'; {v1.31}
          $1621: NorthName := 'M1621';
          $1631: NorthName := 'M1631';
          $1632: NorthName := 'M1632M';
          $1641: NorthName := 'M1641';
          $1647: NorthName := 'M1647';
          $1651: NorthName := 'M1651'; {v1.31}
          $1671: NorthName := 'M1671'; {v1.31}
          $1672: NorthName := 'M1672'; {v1.31}
        End;
      End
  Else
    If NorthMan = $1166 {Reliance/ServerWorks} Then {v1.25}
      Begin
        Case NorthId Of 
          $0007: NorthName := 'Reliance NB6635';
          $0008: NorthName := 'Reliance NB6536';
        End;
      End
  Else
    If NorthMan = $1066 {PicoPower} Then {v1.25}
      Begin
        Case NorthId Of 
          $0001: NorthName := 'Vesuvius V1-LS';
        End;
      End
  Else
    If NorthMan = $1078 {Cyrix} Then {v1.25}
      Begin
        Case NorthId Of 
          $0001: NorthName := 'MediaGX';
        End;
      End
  Else
    If NorthMan = $1045 {OPTi} Then {v1.26}
      Begin
        Case NorthId Of 
          $C557: NorthName := 'OPTi 82C557(M)'; {v1.37}
          $C567: NorthName := 'OPTi 82C567';
        End;
      End
  Else
    If NorthMan = $3388 {HiNT} Then {v1.26}
      Begin
        Case NorthId Of 
          $8011: NorthName := 'HiNT VXPro-II North';
        End;
      End
  Else
    If NorthMan = $1060 {UMC} Then {v1.28}
      Begin
        Case NorthId Of 
          $8881: NorthName := 'UMC UM8881F';
        End;
      End
  Else
    If NorthMan = $1344 {Micron} Then {v1.29}
      Begin
        Case NorthId Of 
          $3320: NorthName := 'Micron MT8LLN21PADF';
        End;
      End
  Else
    If NorthMan = $1080 {Contaq/Cypress} Then {v1.29}
      Begin
        Case NorthId Of 
          $0600:
                 Begin {CY82C599}
                   NorthFunc := $0400;
                   NorthName := 'CY82C599';
                 End;
          $C691: NorthName := 'CY82C691';
        End;
      End
  Else
    If NorthMan = $10DE {nVidia} Then {v1.30}
      Begin
        Case NorthId Of 
          $1A4: NorthName := 'nVidia IGP';
          $1E0: NorthName := 'nVidia IGP2';
        End;
      End;

 {Id southbridge}
  If SouthMan = $8086 {Intel} Then
    Begin
      If (Hi(SouthId)=$24) Or (Hi(SouthId)=$25) Then SouthFunc := $0200
      Else SouthFunc := $0100; {v1.21}
      If Hi(SouthId)=$26 Then SouthFunc := $1700; {v1.37}
      Case SouthId Of {case v1.21}
        $484:
              Begin
                If SouthRev<$88 Then SouthName := 'i82378ZB SIO'
                Else
                  SouthName := 'i82379AB SIO.A';
                SouthFunc := $0104; {v1.29}
              End;
        $122E:
               Begin
                 SouthName := 'i82371FB PIIX';
                 Inc( SouthFunc ); {v1.23}
               End;
        $1234: SouthName := 'i82371MX MPIIX';
        $7000:
               Begin
                 SouthName := 'i82371SB PIIX3';
                 Inc( SouthFunc );
               End;
        $7110:
               Begin
                 SouthName := 'i82371AB/EB PIIX4(E)';
                 Inc( SouthFunc, 3 );
                 If NorthName='i82439TX' Then SouthFunc := SouthFunc+$10;
                 {v1.33}
               End;
        $2410: SouthName := 'i82801AA ICH';
        $2420: SouthName := 'i82801AB ICH0';
        $2440: SouthName := 'i82801BA ICH2';
        $244C: SouthName := 'i82801BAM ICH2-M';
        $248C: SouthName := 'i82801CAM ICH3-M';
        $2480: SouthName := 'i82801CA ICH3-S';
        $24C0: SouthName := 'i82801DB ICH4';
        $24CC: SouthName := 'i82801DBM ICH4-M';
        $24D0: SouthName := 'i82801EB ICH5(R)';
        $2640: SouthName := 'i82801FB/R ICH6(R)'; {v1.37}
        $2641: SouthName := 'i82801FBM ICH6-M'; {v1.39}
        $2642: SouthName := 'i82801F(R)W ICH6(R)W'; {v1.37}
        $25A1: SouthName := 'i6300ESB ICH'; {v1.39}
      End;
    End
  Else
    If SouthMan = $1106 {VIA} Then
      Begin
        SouthFunc := $0300; {VIA/AMD method}
        Case SouthId Of {case v1.21}
          $586: SouthName := 'VT82C586(A|B)/AMD-645';
          $596:
                Begin
                  SouthName := 'VT82C596(A|B)';
                  Inc( SouthFunc );
                End;
          $686:
                Begin
                  SouthName := 'VT82C686(A|B)';
                  Inc( SouthFunc );
                End;
          $8231: SouthName := 'VT8231';
          $3074,$3147:
                       Begin
                         SouthName := 'VT8233(A|C)';
                         SouthFunc := $0310;
                         LPCFunc := LPCDetect;
                       End;
          $3177:
                 Begin
                   SouthName := 'VT8235';
                   SouthFunc := $0310;
                   LPCFunc := LPCDetect;
                 End;
          $3227:
                 Begin
                   SouthName := 'VT8237';
                   SouthFunc := $0310;
                   LPCFunc := LPCDetect;
                 End; {v1.39}
        End;
      End
  Else
    If SouthMan = $1022 {AMD} Then {v1.20}
      Begin
        SouthFunc := $0300; {AMD/VIA method}
        Case SouthId Of {case v1.21}
          $7408: SouthName := 'AMD-756';
          $7410: SouthName := 'AMD-766';
          $7440: SouthName := 'AMD-768';
          $7468: SouthName := 'AMD-8111'; {v1.36}
        End;
      End
  Else
    If SouthMan = $1039 {SiS} Then
      Begin
        Case SouthId Of {v1.21}
          $8: SouthName := 'SiS South Bridge'; {any SiS South Bridge}
          $18: SouthName := 'SiS 950'; {SiS 950 can have $8 or $18}
          $964: SouthName := 'SiS 964'; {v1.35}
        End;
      End
  Else
    If SouthMan = $10B9 {ALi} Then {v1.18}
      Begin
        SouthFunc := $0400; {ALi method}
        Case SouthId Of 
          $1449:
                 Begin
                   SouthName := 'M1449';
                   SouthFunc := 0;
                 End;
          $1523: SouthName := 'M1523(B)';
          $1533,
          $1543,
          $1535:
                 Begin
                   SouthName := 'M1533/1543/1535';
                   Inc(SouthFunc);
                 End;
        End;
      End
  Else
    If SouthMan = $1055 {SMSC} Then {v1.21}
      Begin
        If SouthId = $9460 Then {SLC90E66} {v1.21}
          Begin
            SouthFunc := $0600; {SMSC method}
            SouthName := 'SMSC SLC90E66';
          End;
      End
  Else
    If SouthMan = $10AD {Winbond/Symphony Labs} Then {v1.21}
      Begin
        If SouthId = $0565 Then {W83C553F/4F} {v1.21}
          Begin
            SouthFunc := $0700; {Winbond method}
            SouthName := 'Winbond W83C553F/4F';
          End;
      End
  Else
    If SouthMan = $1283 {ITE} Then {v1.21}
      Begin
        Case SouthId Of 
          $8872 :
                  Begin
                    SouthFunc := $0801;
                    SouthName := 'ITE IT8871F/2F';
                  End;
          $8888 :
                  Begin
                    SouthFunc := $0802;
                    SouthName := 'ITE IT8888F';
                  End;
        End;
      End
  Else
    If SouthMan = $1166 {Reliance/ServerWorks} Then {v1.24}
      Begin
        SouthFunc := $0900;
        Case SouthId Of 
          $0200 : SouthName := 'Reliance OSB4';
        End;
      End
  Else
    If SouthMan = $1066 {PicoPower} Then {v1.25}
      Begin
        SouthFunc := $1000;
        Case SouthId Of 
          $0002,$8002 : SouthName := 'Vesuvius V3-LS';
        End;
      End
  Else
    If SouthMan = $100B {National} Then {v1.36}
      Begin
        SouthFunc := $1100;
        Case SouthId Of 
          $0500 :
                  Begin
                    SouthName := 'Geode SCx200';
                    LPCFunc := LPCDetect;
                  End;
          $0510 :
                  Begin
                    SouthName := 'Geode SC1100';
                    LPCFunc := LPCDetect;
                  End;
        End;
      End
  Else
    If SouthMan = $1078 {Cyrix} Then {v1.25}
      Begin
        SouthFunc := $1100;
        Case SouthId Of 
          $0000 : SouthName := 'Cyrix Cx5510'; {v1.36}
          $0002 : SouthName := 'Cyrix Cx5520'; {v1.36}
          $0100 : SouthName := 'Cyrix Cx5530(A)';
        End;
      End
  Else
    If SouthMan = $1045 {OPTi} Then {v1.26}
      Begin
        SouthFunc := $1200;
        Case SouthId Of 
          $C558: SouthName := 'OPTi 82C558(M)';
          $C568: SouthName := 'OPTi 82C568';
        End;
      End
  Else
    If SouthMan = $3388 {HiNT} Then {v1.26}
      Begin
        SouthFunc := $1300;
        Case SouthId Of 
          $8012: SouthName := 'HiNT VXPro-II South';
        End;
      End;
  If SouthMan = $1060 {UMC} Then {v1.28}
    Begin
      SouthFunc := $1400;
      Case SouthId Of 
        $886A: SouthName := 'UMC UM8886BF';
      End;
    End
  Else
    If SouthMan = $1344 {Micron} Then {v1.29}
      Begin
        Case SouthId Of 
          $3470: SouthName := 'Micron MT7LLN22NCNE';
        End;
      End
  Else
    If SouthMan = $1080 {Contaq/Cypress} Then {v1.29}
      Begin
        SouthFunc := $1500;
        Case SouthId Of 
          $C693: SouthName := 'CY82C693(U/UB)';
        End;
      End
  Else
    If SouthMan = $10DE {nVidia} Then {v1.30}
      Begin
        SouthFunc := $1600;
        Case SouthId Of 
          $01B2: SouthName := 'nVidia MCP/MCP-D';
          $0060: SouthName := 'nVidia MCP2';
        End;
      End;


 {Id chipset as a whole}
  CurrentChipset := '';

  If (NorthName='i82433LX') And ((SouthName='i82378ZB SIO') Or (SouthName=
     'i82379AB SIO.A'))
    Then CurrentChipset := 'Intel Mercury 430LX';
  If (NorthName='i82433NX') And ((SouthName='i82378ZB SIO') Or (SouthName=
     'i82379AB SIO.A'))
    Then CurrentChipset := 'Intel Neptune 430NX';
  If (NorthName='i82437FX') And (SouthName='i82371FB PIIX')
    Then CurrentChipset := 'Intel Triton 430FX';
  If (NorthName='i82437MX') And (SouthName='i82371MX MPIIX')
    Then CurrentChipset := 'Intel 430MX (mobile)';
  If (NorthName='i82441FX') And (SouthName='i82371SB PIIX3')
    Then CurrentChipset := 'Intel Natoma 440FX';
  If (NorthName='i82439HX') And (SouthName='i82371SB PIIX3')
    Then CurrentChipset := 'Intel Triton II 430HX';
  If (NorthName='i82437VX') And (SouthName='i82371SB PIIX3')
    Then CurrentChipset := 'Intel Triton II 430VX';
  If (NorthName='i82439TX') And (SouthName='i82371AB/EB PIIX4(E)')
    Then CurrentChipset := 'Intel Triton III 430TX';
  If (NorthName='i82443LX/EX') And (SouthName='i82371AB/EB PIIX4(E)')
    Then CurrentChipset := 'Intel AGPSet 440LX/EX';
  If (NorthName='i82443BX/ZX') And (SouthName='i82371AB/EB PIIX4(E)')
    Then CurrentChipset := 'Intel AGPSet 440BX/ZX';
  If (NorthName='i82443BX/ZX') And (SouthName='SMSC SLC90E66')
    Then CurrentChipset := 'SMSC VictoryBX-66';
  If (NorthName='i82443GX') And (SouthName='i82371AB/EB PIIX4(E)')
    Then CurrentChipset := 'Intel AGPSet 440GX';
  If (NorthName='i82454KX/GX') And ((SouthName='i82379AB SIO.A') Or (SouthName=
     'i82371FB PIIX') Or (SouthName='i82371SB PIIX3'))
    Then CurrentChipset := 'Intel 450KX/GX';
  If (NorthName='i82810') And ((SouthName='i82801AA ICH') Or (SouthName=
     'i82801AB ICH0'))
    Then CurrentChipset := 'Intel 810';
  If (NorthName='i82810-DC100') And ((SouthName='i82801AA ICH') Or (SouthName=
     'i82801AB ICH0'))
    Then CurrentChipset := 'Intel 810-DC100';
  If (NorthName='i82810E') And ((SouthName='i82801AA ICH') Or (SouthName=
     'i82801AB ICH0'))
    Then CurrentChipset := 'Intel 810E';
  If (NorthName='i82810E') And (SouthName='i82801BA ICH2')
    Then CurrentChipset := 'Intel 810E2';
  If (NorthName='i82815') And ((SouthName='i82801AA ICH') Or (SouthName=
     'i82801AB ICH0'))
    Then CurrentChipset := 'Intel 815(P/G)';
  If (NorthName='i82815') And (SouthName='i82801BA ICH2')
    Then CurrentChipset := 'Intel 815E(P/G)';
  If (NorthName='i82815') And (SouthName='i82801BAM ICH2-M')
    Then CurrentChipset := 'Intel 815EM';
  If (NorthName='i82820') And ((SouthName='i82801AA ICH') Or (SouthName=
     'i82801AB ICH0'))
    Then CurrentChipset := 'Intel 820';
  If (NorthName='i82820') And (SouthName='i82801BA ICH2')
    Then CurrentChipset := 'Intel 820E';
  If (NorthName='i82830M') And (SouthName='i82801CAM ICH3-M')
    Then CurrentChipset := 'Intel 830M(P/G)';
  If (NorthName='i82840') And ((SouthName='i82801AA ICH') Or (SouthName=
     'i82801AB ICH0'))
    Then CurrentChipset := 'Intel 840';
  If (NorthName='i82845') And (SouthName='i82801BA ICH2')
    Then CurrentChipset := 'Intel 845';
  If (NorthName='i82845') And (SouthName='i82801DB ICH4')
    Then CurrentChipset := 'Intel 845E'; {v1.31}
  If (NorthName='i82845G/P') And (SouthName='i82801DB ICH4')
    Then CurrentChipset := 'Intel 845G(E/L/V)/845PE'; {v1.31}
  If (NorthName='i82845') And (SouthName='i82801CAM ICH3-M')
    Then CurrentChipset := 'Intel 845MP/MZ'; {v1.31}
  If (NorthName='i82850') And (SouthName='i82801BA ICH2')
    Then CurrentChipset := 'Intel 850(E)';
  If (NorthName='i8285xGM') And ((SouthName='i82801DBM ICH4-M') Or (SouthName=
     'i82801DB ICH4') Or (SouthName='i6300ESB ICH'))
    Then CurrentChipset := 'Intel 852GM(E)/855GM(E)'; {v1.31}
  If (NorthName='i82855PM') And (SouthName='i82801DBM ICH4-M')
    Then CurrentChipset := 'Intel 855PM'; {v1.31}
  If (NorthName='i82860') And (SouthName='i82801BA ICH2')
    Then CurrentChipset := 'Intel 860';
  If (NorthName='i82865') And (SouthName='i82801EB ICH5(R)')
    Then CurrentChipset := 'Intel 865P(E)/G(V)/848P'; {v1.34}
  If (NorthName='i82875') And ((SouthName='i82801EB ICH5(R)') Or (SouthName=
     'i6300ESB ICH'))
    Then CurrentChipset := 'Intel 875P'; {v1.31}
  If (NorthName='iE7205') And (SouthName='i82801DB ICH4')
    Then CurrentChipset := 'Intel E7205'; {v1.31}
  If (NorthName='iE7210') And (SouthName='i6300ESB ICH')
    Then CurrentChipset := 'Intel E7210'; {v1.39}
  If (NorthName='iE7221') And ((SouthName='i82801FB/R ICH6(R)') Or (SouthName=
     'i82801F(R)W ICH6(R)W'))
    Then CurrentChipset := 'Intel E7221'; {v1.39}
  If (NorthName='iE7500') And (SouthName='i82801CA ICH3-S')
    Then CurrentChipset := 'Intel E7500';
  If (NorthName='iE7320') And ((SouthName='i82801EB ICH5(R)') Or (SouthName=
     'i6300ESB ICH'))
    Then CurrentChipset := 'Intel E7320'; {v1.39}
  If (NorthName='iE7501') And (SouthName='i82801CA ICH3-S')
    Then CurrentChipset := 'Intel E7501'; {v1.31}
  If (NorthName='iE7505') And (SouthName='i82801DB ICH4')
    Then CurrentChipset := 'Intel E7505'; {v1.31}
  If (NorthName='iE7520') And ((SouthName='i82801EB ICH5(R)') Or (SouthName=
     'i6300ESB ICH'))
    Then CurrentChipset := 'Intel E7520'; {v1.39}
  If (NorthName='iE7525') And ((SouthName='i82801EB ICH5(R)') Or (SouthName=
     'i6300ESB ICH'))
    Then CurrentChipset := 'Intel E7525'; {v1.39}
  If (NorthName='iE8870') And (SouthName='i82801DB ICH4')
    Then CurrentChipset := 'Intel E8870'; {v1.39}
  If (NorthName='i829xxx') And ((SouthName='i82801FB/R ICH6(R)') Or (SouthName=
     'i82801F(R)W ICH6(R)W'))
    Then CurrentChipset := 'Intel 910/915/925 series'; {v1.37}
  If (NorthName='i829xxxM') And (SouthName='i82801FBM ICH6-M')
    Then CurrentChipset := 'Intel mobile 910/915 series'; {v1.39}

  If (NorthName='VT82C505') Then CurrentChipset := 
                                                 'VIA 486 chipset with VT82C505'
  ; {v1.37}
  If (NorthName='VT82C576M') Then CurrentChipset := 'VIA Apollo Master';
  If (NorthName='VT82C585VP/VPX') And (SouthName='VT82C586(A|B)/AMD-645')
    Then CurrentChipset := 'VIA Apollo VP/VPX';
  If (NorthName='VT82C595/AMD-640') And (SouthName='VT82C586(A|B)/AMD-645')
    Then CurrentChipset := 'VIA Apollo VP2/AMD 640';
  If (NorthName='VT82C597') And ((SouthName='VT82C586(A|B)/AMD-645') Or (
     SouthName='VT82C596(A|B)'))
    Then CurrentChipset := 'VIA Apollo (M)VP3';
  If (NorthName='VT82C598(AT)') And ((SouthName='VT82C596(A|B)') Or (SouthName=
     'VT82C686(A|B)'))
    Then CurrentChipset := 'VIA Apollo MVP3';
  If (NorthName='VT82C685') Then CurrentChipset := 'VIA Apollo P6';
  If (NorthName='VT8501') And (SouthName='VT82C686(A|B)')
    Then CurrentChipset := 'VIA Apollo MVP4';
  If (NorthName='VT82C691/693(A)/694X/T') And ((SouthName='VT82C596(A|B)') Or (
     SouthName='VT82C686(A|B)'))
    Then CurrentChipset := 'VIA Apollo Pro (Plus/133(A|T))';
  If (NorthName='VT82C693(A)') And ((SouthName='VT82C596(A|B)') Or (SouthName=
     'VT82C686(A|B)'))
    Then CurrentChipset := 'VIA Apollo Pro Plus/133(A)';
  If (NorthName='VT8601') And (SouthName='VT82C686(A|B)')
    Then CurrentChipset := 'VIA Apollo ProMedia';
  If (NorthName='VT8605') Then CurrentChipset := 'VIA Apollo Pro 133Z/PM133';
  If (NorthName='VT8371') And (SouthName='VT82C686(A|B)')
    Then CurrentChipset := 'VIA Apollo KX133';
  If (NorthName='VT8363(A)/8365') And (SouthName='VT82C686(A|B)')
    Then CurrentChipset := 'VIA Apollo KT133(A)';
  If (NorthName='VT8363(A)/8365') And (SouthName='VT8231')
    Then CurrentChipset := 'VIA ProSavage KM133(A)';
  If (NorthName='VT8366(A)') And ((SouthName='VT8233(A|C)') Or (SouthName=
     'VT8235'))
    Then CurrentChipset := 'VIA Apollo KT266(A)/KT333';

(* if (NorthName='VT8366(A)') and (SouthName='VT8235')
  then CurrentChipset:='VIA Apollo KT333'; {v1.31}*)
  If (NorthName='VT8377') And (SouthName='VT8235')
    Then CurrentChipset := 'VIA Apollo KT400(A)'; {v1.31}
  If (NorthName='VT8378') And ((SouthName='VT8233(A|C)') Or (SouthName='VT8235')
     Or (SouthName='VT8237'))
    Then CurrentChipset := 'VIA UniChrome KM400(A)'; {v1.39}
  If (NorthName='VT8633') And (SouthName='VT8233(A|C)')
    Then CurrentChipset := 'VIA Apollo Pro 266';
  If (NorthName='VT8653') And (SouthName='VT8233(A|C)')
    Then CurrentChipset := 'VIA Apollo Pro 266T'; {v1.31}
  If (NorthName='VT8751') And (SouthName='VT8233(A|C)')
    Then CurrentChipset := 'VIA ProSavage P4M266';
  If (NorthName='VT8753(A)/8754') And (SouthName='VT8233(A|C)')
    Then CurrentChipset := 'VIA P4X266(A)/P4X333/P4X400';

  If (NorthName='M1451') And (SouthName='M1449')
    Then CurrentChipset := 'ALi Aladdin';
  If (NorthName='M1489') Then CurrentChipset := 'ALi FinALi 486';
  If (NorthName='M1521') And (SouthName='M1523(B)')
    Then CurrentChipset := 'ALi Aladdin III';
  If (NorthName='M1531(B)') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin IV/IV+';
  If (NorthName='M1541/1542') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin V';
  If (NorthName='M1561') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin 7'; {v1.31}
  If (NorthName='M1621') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin Pro/Pro II';
  If (NorthName='M1631') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin Pro III (TNT2)'; {v1.31}
  If (NorthName='M1632M') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi CyberBLADE Aladdin i1'; {v1.31}
  If (NorthName='M1641') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin Pro IV';
  If (NorthName='M1647') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi ALiMAGiK/MobileMAGiK 1';
  If (NorthName='M1651') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin Pro 5(T/M)'; {v1.31}
  If (NorthName='M1671') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi Aladdin-P4'; {v1.31}
  If (NorthName='M1672') And (SouthName='M1533/1543/1535')
    Then CurrentChipset := 'ALi CyberAladdin-P4'; {v1.31}

  If (NorthName='AMD-751') And (SouthName='AMD-756')
    Then CurrentChipset := 'AMD 750';
  If (NorthName='AMD-761') And (SouthName='VT82C686(A|B)')
    Then CurrentChipset := 'AMD 760 (VIA South)';
  If (NorthName='AMD-761') And (SouthName='AMD-766')
    Then CurrentChipset := 'AMD 760 (AMD South)';
  If (NorthName='AMD-762') And (SouthName='AMD-766')
    Then CurrentChipset := 'AMD 760MP';
  If (NorthName='AMD-762') And (SouthName='AMD-768')
    Then CurrentChipset := 'AMD 760MPX';
  If (NorthName='AMD-8151') And (SouthName='AMD-8111')
    Then CurrentChipset := 'AMD 8000'; {v1.36}

  If (NorthName='SiS 85C496+497') Then CurrentChipset := 'SiS 85C496+497';
  If (NorthName='SiS 501/5101/5501') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 501/5101/5501';
  If (NorthName='SiS 5511') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 5511+5513';
  If (NorthName='SiS 5571') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 5571';
  If (NorthName='SiS 5591/5592') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 5591/5592+5595';
  If (NorthName='SiS 5596') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 5596+5595';
  If (NorthName='SiS 5597/5598/5581/5120') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 5597/5598/5581/5120';
  If (NorthName='SiS 530') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 530';
  If (NorthName='SiS 540') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 540';
  If (NorthName='SiS 600') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 600';
  If (NorthName='SiS 620') And (SouthName='SiS South Bridge')
    Then CurrentChipset := 'SiS 620';
  If (NorthName='SiS 630') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 630';
  If (NorthName='SiS 635') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 635';
  If (NorthName='SiS 640') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 640';
  If (NorthName='SiS 645') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 645';
  If (NorthName='SiS 645DX') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 645DX';
  If (NorthName='SiS 648') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 648'; {v1.31}
  If (NorthName='SiS 650') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 650';
  If (NorthName='SiS 651') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 651'; {v1.31}
  If (NorthName='SiS 655') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 655'; {v1.31}
  If (NorthName='SiS 730') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 730';
  If (NorthName='SiS 733') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 733'; {v1.31}
  If (NorthName='SiS 735') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 735';
  If (NorthName='SiS 740') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 740';
  If (NorthName='SiS 745') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 745'; {v1.31}
  If (NorthName='SiS 746') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 746'; {v1.31}
  If (NorthName='SiS 748') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 748'; {v1.31}
  If (NorthName='SiS 755') And ((SouthName='SiS South Bridge') Or (SouthName=
     'SiS 950'))
    Then CurrentChipset := 'SiS 755'; {v1.31}

  If (NorthName='Reliance NB6635') And (SouthName='Reliance OSB4')
    Then CurrentChipset := 'ServerWorks ServerSet III LE';
  If (NorthName='Reliance NB6536') And (SouthName='Reliance OSB4')
    Then CurrentChipset := 'ServerWorks ServerSet III HE';

  If (NorthName='Vesuvius V1-LS') And (SouthName='Vesuvius V3-LS')
    Then CurrentChipset := 'National PicoPower Vesuvius-LS';

  If (NorthName='MediaGX') And (SouthName='Cyrix Cx5510')
    Then CurrentChipset := 'Cyrix MediaGX + Cx5510'; {v1.36}
  If (NorthName='MediaGX') And (SouthName='Cyrix Cx5520')
    Then CurrentChipset := 'Cyrix MediaGX + Cx5520'; {v1.36}
  If (NorthName='MediaGX') And (SouthName='Cyrix Cx5530(A)')
    Then CurrentChipset := 'National Geode GX1 + CS5530(A)';
  If (NorthName='MediaGX') And (SouthName='Geode SC1100')
    Then CurrentChipset := 'AMD Geode SC1100'; {v1.36}
  If (NorthName='MediaGX') And (SouthName='Geode SCx200')
    Then CurrentChipset := 'AMD Geode SC1200/2200/3200'; {v1.36}

  If (NorthName='OPTi 82C557(M)') And (SouthName='OPTi 82C558(M)')
    Then CurrentChipset := 'OPTi Viper M/N/NK/N+/DP';
  If (NorthName='OPTi 82C567') And (SouthName='OPTi 82C568')
    Then CurrentChipset := 'OPTi Viper Max/Vendetta 82C750';

  If (NorthName='HiNT VXPro-II North') And (SouthName='HiNT VXPro-II South')
    Then CurrentChipset := 'HiNT VXPro-II (Utron UT85C50x)';

  If (NorthName='UMC UM8881F') And (SouthName='UMC UM8886BF')
    Then CurrentChipset := 'UMC UM8881F + UM8886BF';

  If (NorthName='Micron MT8LLN21PADF') And (SouthName='Micron MT7LLN22NCNE')
    Then CurrentChipset := 'Micron Copperhead+Coppertail';

  If (NorthName='CY82C599') Then CurrentChipset := 'Cypress 386/486 chipset';
  If (NorthName='CY82C691') And (SouthName='CY82C693(U/UB)')
    Then CurrentChipset := 'Cypress hyperCache';

  If (NorthName='nVidia IGP') And (SouthName='nVidia MCP/MCP-D')
    Then CurrentChipset := 'nVidia nForce';
  If (NorthName='nVidia IGP2') And (SouthName='nVidia MCP2')
    Then CurrentChipset := 'nVidia nForce2';

  ChipsetFound := ( NorthName<>'' ) Or ( SouthName<>'' );
  {One of 'm might be enough}

 {If chipset ID failed then show north & south bridge name or ID}
  If CurrentChipset = '' Then
    Begin
      If NorthName<>'' Then
        CurrentChipset := NorthName + ' + '
      Else
        CurrentChipset := '(' + Hw( NorthMan ) + ',' + Hw( NorthId ) +
                          ',' + Hb( NorthRev ) + ') + ';
      If SouthName<>'' Then
        CurrentChipset := CurrentChipset + SouthName
      Else
        CurrentChipset := CurrentChipset +
                          '(' + Hw( SouthMan ) + ',' + Hw( SouthId ) +
                          ',' + Hb( SouthRev ) + ')';
    End;
  If LPCName<>'' Then CurrentChipset := CurrentChipset+' + '+LPCName; {v1.27}
  If WantToUseAMI And AMICheckFor Then {v1.24}
    Begin
      AMIUsed := True;
      ChipsetFound := True;
      CurrentChipset := CurrentChipset + ' [AMI FLASH]';
      LogWrite('AMI flash interface enabled');
    End;
  If WantToUseAsus And AsusCheckFor Then {v1.39}
    Begin
      AsusUsed := True;
      ChipsetFound := True;
      CurrentChipset := CurrentChipset + ' [ASUS FLASH]';
      LogWrite('Asus flash interface enabled');
    End;
End;

Procedure GetBIOSID;

Var Buf: array[1..80] Of Char;
  b,e: Byte;
Begin
  MoveLinBlockB($FFFFFFE8,LongInt(Seg(BIOSID)) shl 4+LongInt(Ofs(BIOSID)),8);
  {v1.34}
  If (BIOSID=#0#0#0#0#0#0#0#0) Or (BIOSID=#$FF#$FF#$FF#$FF#$FF#$FF#$FF#$FF) Then
    {v1.39}
    Begin
      BIOSID := #0#0#0#0#0#0#0#0;
      MoveLinBlockB($FEC71,LongInt(Seg(Buf)) shl 4+LongInt(Ofs(Buf)),SizeOf(Buf)
      );
      e := Pos(#0,Buf)-1;
      b := e;
      While ((Buf[b]<>'-') Or (e-b<3)) And (b>1) Do
        Dec(b);
      If e-b>8 Then e := b+8;
      Move(Buf[b+1],BIOSID,e-b);
    End;
  GotoXY(73,23);
  Write(BIOSID); {v1.38}
  LogWrite('Detected Award BIOS ID: '+BIOSID);
End;

Var 
  PIIXReg, PIIXReg2, PIIXReg3, PIIXReg4, PIIXReg5 : LongInt;

{Generic Intel chipset low ROM enable & ROM write access enable}
Procedure ROMEnable( Map : Boolean );

Var 
  Mask : LongInt;
  Pos_: Byte;

Begin
  If ROMEnabled=Map Then Exit; {v1.22}

  If AMIUsed Then
    Begin
      If Map Then AMIEnable
      Else AMIDisable;
      ROMEnabled := Map;
      Exit;
    End;
  If AsusUsed Then
    Begin
      If Map Then AsusEnable
      Else AsusDisable;
      ROMEnabled := Map;
      Exit;
    End;

 {Chipset northbridge stuff}
  Case Hi( NorthFunc ) Of 
    $01 :
          Begin {older VIA chipsets}
            If Map Then
              Begin
                Port[$A8] := $11;
                PIIXReg := Port[$A9];
                LogWrite('VIA old method: internal reg $11 = '+Hl(PIIXReg));
                {v1.28}
                Port[$A8] := $11;
                Port[$A9] := PIIXReg Or $40; {ROM Write enable}
                Port[$A8] := $11;
                LogWrite('VIA old method: internal reg $11 changed to '+Hl(Port[
                         $A9])); {v1.28}
              End
            Else
              Begin
                Port[$A8] := $11;
                LogWrite('VIA old method: restoring internal reg $11 from '+Hl(
                         Port[$A9])); {v1.28}
                Port[$A8] := $11;
                Port[$A9] := PIIXReg;
              End;
          End;
    $02 :
          Begin {SiS 85C496+497 chipset} {v1.21}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $D0
                           );
                LogWrite('SiS old method: reg $D0 = '+Hl(PIIXReg)); {v1.28}
           {write enable, 384K enable}
                SetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $D0, PIIXReg
                           Or $F8 );
                LogWrite('SiS old method: reg $D0 changed to '+Hl(GetPCIRegD( $
                         00, NorthPos shr 3, NorthPos And $7, $D0 )));
              End
            Else
              Begin
                LogWrite('SiS old method: restoring reg $D0 from '+Hl(GetPCIRegD
                         ( $00, NorthPos shr 3,
                         NorthPos And $7, $D0 ))); {v1.28}
                SetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $D0, PIIXReg )
                ;
              End;
          End;
    $03 :
          Begin {ALi Aladdin and FinALi}
            If Map Then
              Begin
                If Lo(NorthFunc)=0 Then
                  Begin {ALi Aladdin M1451/1449} {v1.31}
                    ROMBase := $E0000;
                    ShadowDisable := @ShadowDisable_Aladdin;
                    ShadowRestore := @ShadowRestore_Aladdin;
                    Flash_Read := @FIMemB_Flash_Low;
                    Flash_ReadBlock := @MoveLinBlock_From_Flash_D_Low;
                    Flash_Compare := @CompLinBlocks_Flash_Low;
                    PIIXReg := GetPCIRegD( $00, NorthPos shr 3, NorthPos And $7,
                               $4C );
                    LogWrite('ALi old method: reg $4C = '+Hl(PIIXReg));
               {E and F segment write shadow disable}
                    SetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $4C,
                               PIIXReg And $00FFFFFF );
                    LogWrite('ALi old method: reg $4C changed to '+Hl(GetPCIRegD
                             ( $00, NorthPos shr 3, NorthPos And $7, $4C)));
                  End
                Else
                  Begin {ALi FinALi 486 M1489/1487} {v1.28}
                    ROMBase := $FFFF0000;
                    Flash_Read := @FIMemB_Flash_FinALi;
                    Flash_Write := @FOMemB_Flash_FinALi;
                    Flash_ReadBlock := @MoveLinBlock_From_Flash_D_FinALi;
                    Flash_WriteBlock := @MoveLinBlock_To_Flash_B_FinALi;
                    Flash_Compare := @CompLinBlocks_Flash_FinALi;
                    Port[$22] := $03;
                    Port[$23] := $C5;

                    Port[$22] := $12;
                    PIIXReg := Port[$23];
                    LogWrite('ALi old method: internal reg $12 = '+Hl(PIIXReg));
                    Port[$22] := $12;
                    Port[$23] := PIIXReg Or $11;
                    Port[$22] := $12;
                    LogWrite('ALi old method: internal reg $12 changed to '+Hl(
                             Port[$23]));

                    Port[$22] := $21;
                    PIIXReg2 := Port[$23];
                    LogWrite('ALi old method: internal reg $21 = '+Hl(PIIXReg2))
                    ;
                    Port[$22] := $21;
                    Port[$23] := PIIXReg2 Or $20;
                    Port[$22] := $21;
                    LogWrite('ALi old method: internal reg $21 changed to '+Hl(
                             Port[$23]));

                    Port[$22] := $2B;
                    PIIXReg3 := Port[$23];
                    LogWrite('ALi old method: internal reg $2B = '+Hl(PIIXReg3))
                    ;
                    Port[$22] := $2B;
                    Port[$23] := PIIXReg3 Or $20;
                    Port[$22] := $2B;
                    LogWrite('ALi old method: internal reg $2B changed to '+Hl(
                             Port[$23]));

                    Port[$22] := $03;
                    Port[$23] := $00;
                  End;
              End
            Else
              Begin
                If Lo(NorthFunc)=0 Then
                  Begin {ALi Aladdin M1451/1449} {v1.31}
                    LogWrite('ALi old method: restoring reg $4C from '+Hl(
                             GetPCIRegD( $00, NorthPos shr 3,
                             NorthPos And $7, $4C )));
                    SetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $4C,
                               PIIXReg );
                  End
                Else
                  Begin
                    Port[$22] := $03;
                    Port[$23] := $C5;

                    Port[$22] := $12;
                    LogWrite('ALi old method: restoring internal reg $12 from '+
                             Hl(Port[$23]));
                    Port[$22] := $12;
                    Port[$23] := PIIXReg;

                    Port[$22] := $21;
                    LogWrite('ALi old method: restoring internal reg $21 from '+
                             Hl(Port[$23]));
                    Port[$22] := $21;
                    Port[$23] := PIIXReg2;

                    Port[$22] := $2B;
                    LogWrite('ALi old method: restoring internal reg $2B from '+
                             Hl(Port[$23]));
                    Port[$22] := $2B;
                    Port[$23] := PIIXReg3;

                    Port[$22] := $03;
                    Port[$23] := $00;
                  End;
              End;
          End;
    $04 :
          Begin {Contaq/Cypress CY82C599} {v1.29}
            If Map Then
              Begin
                Port[$22] := $12;
                PIIXReg := Port[$23];
                LogWrite('Cypress old method: internal reg $12 = '+Hl(PIIXReg));
                Port[$22] := $12;
                Port[$23] := PIIXReg And $EF;
                Port[$22] := $12;
                LogWrite('Cypress old method: internal reg $12 changed to '+Hl(
                         Port[$23]));
              End
            Else
              Begin
                Port[$22] := $12;
                LogWrite('Cypress old method: restoring internal reg $12 from '+
                         Hl(Port[$23]));
                Port[$22] := $12;
                Port[$23] := PIIXReg;
              End;
          End;
  End;

 {Chipset southbridge stuff}
  Case Hi( SouthFunc ) Of 
    $01 :
          Begin {Intel method}
            If Map Then
              Begin
                Mask := $00440000;                    {write & 128k enable}
                If ( SouthFunc And 1 ) <> 0 Then Mask := Mask Or $800000;
                {512k enable}
                If ( SouthFunc And 2 ) <> 0 Then Mask := Mask Or $2000000;
                {1M enable}
                If ( SouthFunc And 4 ) <> 0 Then Mask := $C00000; {v1.29}

                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C
                           );
                LogWrite('Intel method: reg $4C = '+Hl(PIIXReg)); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg
                           Or Mask );
                LogWrite('Intel method: reg $4C changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $4C ))); {v1.23}
                PIIXReg4 := 0;
                If Lo(SouthFunc)=3 Then {v1.29}
                  Begin
                    If (BIOSID='6A69KA19') {Abit BF6, BE6-II v1.0 and v1.1}
                       Or (BIOSID='6A69KA1B') {Abit BE6-II v1.2}
                       Or (BIOSID='6A69KA1C') {Abit BE6-II v2.0 and BX133-RAID}
                       Or (BIOSID='2A69KA1Q') {Abit ZM6}
                       Or (BIOSID='2A69KA1U') Then {Abit BE6}
                      Begin
                        PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, 4, $40 );
                        {v1.29}
                        LogWrite('Intel method: PM Base = '+Hl(PIIXReg2));
                        If PIIXReg2=-1 Then
                          Begin
                            PIIXReg4 := 1;
                            SetPCIRegD($00,SouthPos shr 3,3,$40,$6101);
                            SetPCIRegD($00,SouthPos shr 3,3,$80,GetPCIRegD($00,
                                       SouthPos shr 3,3,$80) or 1);
                            LogWrite('Intel method: PM Base set to '+Hl(
                                     GetPCIRegD($00,SouthPos shr 3,3,$40)));
                            PIIXReg3 := Port[$6134] Or LongInt(Port[$6135]) shl
                                        8
                                        Or LongInt(Port[$6136]) shl 16 Or
                                        LongInt(Port[$6137]) shl 24;
                            LogWrite('Intel method: GPO status '+Hl(PIIXReg3));
                            Port[$6135] := Port[$6135] And $FD;
                            Port[$6137] := Port[$6137] And $FB;
                            {Abit BX133-RAID v1.29}
                            LogWrite('Intel method: GPO changed to '+Hl(Port[$
                                     6134] Or LongInt(Port[$6135]) shl 8
                            or LongInt(Port[$6136]) shl 16 or LongInt(Port[$6137
                                                                      ]) shl 24)
                            );
                          End;
                      End;
                  End;
              End
            Else
              Begin
                LogWrite('Intel method: restoring reg $4C from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $4C ))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg )
                ;
                If (BIOSID='6A69KA19') {Abit BF6, BE6-II v1.0 and v1.1}
                   Or (BIOSID='6A69KA1B') {Abit BE6-II v1.2}
                   Or (BIOSID='6A69KA1C') {Abit BE6-II v2.0 and BX133-RAID}
                   Or (BIOSID='2A69KA1Q') {Abit ZM6}
                   Or (BIOSID='2A69KA1U') Then {Abit BE6}
                  If PIIXReg4=1 Then {v1.29}
                    Begin
                      LogWrite('Intel method: restoring GPO from '+Hl(Port[$6134
                               ] Or LongInt(Port[$6135]) shl 8
                      or LongInt(Port[$6136]) shl 16 or LongInt(Port[$6137]) shl
                      24));
                      Port[$6134] := PIIXReg3 And $FF;
                      Port[$6135] := PIIXReg3 And $FF00 shr 8;
                      Port[$6136] := PIIXReg3 And $FF0000 shr 16;
                      Port[$6137] := PIIXReg3 And $FF000000 shr 24;
                      SetPCIRegD($00,SouthPos shr 3,3,$80,GetPCIRegD($00,
                                 SouthPos shr 3,3,$80) and $FFFFFFFE);
                      SetPCIRegD($00,SouthPos shr 3,3,$40,PIIXReg2);
                    End;
              End;
          End;
    $02 :
          Begin {Intel 8xx method} {v1.19}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C
                           );
                LogWrite('Intel 8xx method: reg $4C = '+Hl(PIIXReg)); {v1.23}
           {FWH Write Enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg
                           Or $10000 );
                LogWrite('Intel 8xx method: reg $4C changed to '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $4C ))); {v1.23}
                PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            E0 );
                LogWrite('Intel 8xx method: reg $E0 = '+Hl(PIIXReg2)); {v1.23}
           {FWH Decode at $FF800000-$FFFFFFFF = 8MB enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $E0, PIIXReg2
                           Or $FF000000 ); {C0 -> FF} {v1.31}
                LogWrite('Intel 8xx method: reg $E0 changed to '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $E0 ))); {v1.23}
                If (BIOSID='6A69RM4E') Or {MSI MS-6337 v3.x}
                   (BIOSID='6A69RM4L') Then {MSI MS-6337 v5.x}
                  Begin
                    If GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $5C )
                       And $10=$10 Then
                      Begin
                        PIIXReg3 := GetPCIRegD( $00, SouthPos shr 3, SouthPos
                                    And $7, $58 ) And $7FC0;
                        LogWrite('6A69RM4E: GPO at '+Hw(PIIXReg3));
                        PIIXReg4 := Port[PIIXReg3+$E];
                        LogWrite('6A69RM4E: GPO = '+Hb(PIIXReg4));
                        Port[PIIXReg3+$E] := PIIXReg4 Or $80;
                        LogWrite('6A69RM4E: GPO changed to '+Hb(Port[PIIXReg3+$E
                                 ]));
                      End;
                  End;
              End
            Else
              Begin
                LogWrite('Intel 8xx method: restoring reg $4C from '+Hl(
                         GetPCIRegD( $00, SouthPos shr 3,
                         SouthPos And $7, $4C ))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg )
                ;
                LogWrite('Intel 8xx method: restoring reg $E0 from '+Hl(
                         GetPCIRegD( $00, SouthPos shr 3,
                         SouthPos And $7, $E0 ))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $E0, PIIXReg2
                );
                If BIOSID='6A69RM4E' Then {MSI MS-6337 v3.x}
                  Begin
                    If GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $5C )
                       And $10=$10 Then
                      Begin
                        LogWrite('6A69RM4E: restoring GPO from '+Hb(Port[
                                 PIIXReg3+$E]));
                        Port[PIIXReg3+$E] := PIIXReg4;
                      End;
                  End;
              End;
          End;
    $03 :
          Begin {VIA method} {AMD method is the same v1.20}
            If Lo(SouthFunc)=$10 Then {VT8233/8235 method v1.27}
              Begin
                If Map Then
                  Begin
                    PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7,
                               $40 );
                    LogWrite('VT8233 method: reg $40 = '+Hl(PIIXReg)); {v1.23}
               {write enable, 4MB enable}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40,
                               PIIXReg Or $7F10 );
                    LogWrite('VT8233 method: reg $40 changed to '+Hl(GetPCIRegD(
                             $00, SouthPos shr 3,
                             SouthPos And $7, $40 ))); {v1.23}
                    If (DMI_Board_String='MSI MS-6380 2.0')
                       Or (DMI_Board_String='MSI MS-6380E 1.0') Then
                      Begin
                        Port[$84D] := Port[$84D] Or $10;
                      End;
                    If (BIOSID='A7V266'#0#0) Then {Asus A7V266} {v1.39}
                      Begin
                        LogWrite('A7V266: enabling write access');
                        LPCUnlock;
                  {flash access enable}
                        LPCWrite($2A, LPCRead($2A) or $80);
                        LPCWrite($07, $07);
                        LPCWrite($F0, LPCRead($F0) and $BF);
                        LPCWrite($F1, LPCRead($F1) or $40);
                        LPCWrite($30, LPCRead($30) or $01);
                  {write enable}
                        LPCWrite($07, $0C);
                        LPCWrite($F0, LPCRead($F0) and $FD);
                        LPCWrite($60, $03);
                        LPCWrite($61, $70);
                        LPCWrite($30, LPCRead($30) or $01);
                        LPCLock_WB;
                        Port[$370] := Port[$370] Or $02;
                      End;
                    If (BIOSID='A7V8X-X'#0) Then {Asus A7V8X-X} {v1.39}
                      Begin
                        LogWrite('A7V8X-X: enabling write access');
                        Port[$372] := Port[$372] Or $04; {GP32 pin of Super I/O}
                      End;
                  End
                Else
                  Begin
                    LogWrite('VT8233 method: restoring reg $40 from '+Hl(
                             GetPCIRegD( $00, SouthPos shr 3,
                             SouthPos And $7, $40 ))); {v1.23}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40,
                               PIIXReg );
                    If (DMI_Board_String='MSI MS-6380 2.0')
                       Or (DMI_Board_String='MSI MS-6380E 1.0') Then
                      Begin
                        Port[$84D] := Port[$84D] And $EF;
                      End;
                    If (BIOSID='A7V266'#0#0) Then {Asus A7V266} {v1.39}
                      Begin
                        LogWrite('A7V266: disabling write access');
                        LPCUnlock;
                  {flash access enable}
                        LPCWrite($2A, LPCRead($2A) or $80);
                        LPCWrite($07, $07);
                        LPCWrite($F0, LPCRead($F0) and $BF);
                        LPCWrite($F1, LPCRead($F1) and $BF);
                        LPCWrite($30, LPCRead($30) or $01);
                  {write enable}
                        LPCWrite($07, $0C);
                        LPCWrite($F0, LPCRead($F0) and $FD);
                        LPCWrite($60, $03);
                        LPCWrite($61, $70);
                        LPCWrite($30, LPCRead($30) or $01);
                        LPCLock_WB;
                        Port[$370] := Port[$370] And $FD;
                      End;
                    If (BIOSID='A7V8X-X'#0) Then {Asus A7V8X-X} {v1.39}
                      Begin
                        LogWrite('A7V8X-X: disabling write access');
                        Port[$372] := Port[$372] And $FB;
                      End;
                  End;
              End
            Else
              Begin
                If Map Then
                  Begin
                    Mask := $C0000001;  {write enable, 512K enable}
                    If ( SouthFunc And 1 ) <> 0 Then Mask := Mask Or $20000000;
                    {1M enable} {v1.22}

                    PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7,
                               $40 );
                    LogWrite('VIA/AMD method: reg $40 = '+Hl(PIIXReg)); {v1.23}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40,
                               PIIXReg Or Mask );
                    LogWrite('VIA/AMD method: reg $40 changed to '+Hl(GetPCIRegD
                             ( $00, SouthPos shr 3,
                             SouthPos And $7, $40 ))); {v1.23}

                    If (BIOSID='6A6S6A1A') {Abit KG7}
                       Or (BIOSID='6A6LMA19') {Abit KT7}
                       Or (BIOSID='6A6LMA1A') Then {Abit KT7A v1.3}
                      Begin
                        If GetPCIRegD( $00, SouthPos shr 3, 4, $40 ) And $8000=$
                           8000 Then
                          Begin
                            PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, 4, $48
                                        ) And $FFFE;
                            LogWrite('6A6S6A1A: GPO at '+Hw(PIIXReg2));
                            PIIXReg3 := IPortD(PIIXReg2+$4C);
                            LogWrite('6A6S6A1A: GPO = '+Hl(PIIXReg3));
                            OPortD(PIIXReg2+$4C,PIIXReg3 Or $10);
                            LogWrite('6A6S6A1A: GPO changed to '+Hl(IPortD(
                                     PIIXReg2+$4C)));
                          End;
                      End;
                  End
                Else
                  Begin
                    LogWrite('VIA/AMD method: restoring reg $40 from '+Hl(
                             GetPCIRegD( $00, SouthPos shr 3,
                             SouthPos And $7, $40 ))); {v1.23}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40,
                               PIIXReg );

                    If BIOSID='6A6S6A1A' Then {Abit KG7}
                      Begin
                        If GetPCIRegD( $00, SouthPos shr 3, 4, $40 ) And $8000=$
                           8000 Then
                          Begin
                            LogWrite('6A6S6A1A: restoring GPO from '+Hl(IPortD(
                                     PIIXReg2+$4C)));
                            OPortD(PIIXReg2+$4C,PIIXReg3);
                          End;
                      End;
                  End;
              End;
          End;
    $04 :
          Begin {ALi method} {v1.18}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44
                           );
                LogWrite('ALi method: reg $44 = '+Hl(PIIXReg)); {v1.23}
           {write enable, 256K enable} {43->47 v1.24}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg
                           Or $47000000 );
                LogWrite('ALi method: reg $44 changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $44 ))); {v1.23}

                PIIXReg4 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            40 );
                LogWrite('ALi method: reg $40 = '+Hl(PIIXReg4));
           {PCI-ISA Posted Write Disable} {v1.26}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40, PIIXReg4
                           And $FFFFFFFB );
                LogWrite('ALi method: reg $40 changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $40 )));
                If (SouthFunc And 1)<>0 Then {v1.26}
                  Begin
              {M1543C rev. B1 - supports 512K ROM}
                    PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7
                                , $78 ); {v1.19}
                    LogWrite('ALi method: reg $78 = '+Hl(PIIXReg2)); {v1.23}
              {512K enable} {v1.19} {v1.24 fixed}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $78,
                               PIIXReg2 Or $1000 ); {v1.19}
                    LogWrite('ALi method: reg $78 changed to '+Hl(GetPCIRegD( $
                             00, SouthPos shr 3, SouthPos And $7, $78 )));
              {M1535 - supports 512K ROM} {v1.24}
                    PIIXReg3 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7
                                , $7C );
                    LogWrite('ALi method: reg $7C = '+Hl(PIIXReg3));
              {512K enable}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $7C,
                               PIIXReg3 Or $1000000 );
                    LogWrite('ALi method: reg $7C changed to '+Hl(GetPCIRegD( $
                             00, SouthPos shr 3, SouthPos And $7, $7C )));
              {256KB support through GPO for M1533/M1543}
                    PIIXReg4 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7
                                , $54 ); {v1.34}
                    LogWrite('ALi method: reg $54 = '+Hl(PIIXReg4));
                    If PIIXReg4 And $10=$10 Then
                      Begin
                        LogWrite('ALi method: using GPO to control A17');
                {Locate PMU}
                        For Pos_:=0 To $FF Do
                          If GetPCIRegD($00,Pos_ shr 3,Pos_ And $07,$00) And $
                             FFFF<>$FFFF Then
                            If GetPCIRegD($00,Pos_ shr 3,
                               Pos_ And $07,$00)=$710110B9 Then Break;
                        If Pos_=$FF Then PMUPos := SouthPos
                        Else PMUPos := Pos_;
                        PIIXReg5 := GetPCIRegD($00,PMUPos shr 3,PMUPos And $7,$
                                    C0);
                        LogWrite('ALi method: PMU reg $C0 = '+Hl(PIIXReg5));
                        Flash_Read := @FIMemB_Flash_ALiGPO;
                        Flash_Write := @FOMemB_Flash_ALiGPO;
                        Flash_ReadBlock := @MoveLinBlock_From_Flash_D_ALiGPO;
                        Flash_WriteBlock := @MoveLinBlock_To_Flash_B_ALiGPO;
                        Flash_Compare := @CompLinBlocks_Flash_ALiGPO;
                      End;
                  End;
              End
            Else
              Begin
                LogWrite('ALi method: restoring reg $44 from '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $44 ))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg )
                ;
                LogWrite('ALi method: restoring reg $40 from '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $40 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40, PIIXReg4
                );
                If (SouthFunc And 1)<>0 Then {v1.26}
                  Begin
                    LogWrite('ALi method: restoring reg $78 from '+Hl(GetPCIRegD
                             ( $00, SouthPos shr 3,
                             SouthPos And $7, $78 ))); {v1.23}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $78,
                               PIIXReg2 ); {v1.19}
                    LogWrite('ALi method: restoring reg $7C from '+Hl(GetPCIRegD
                             ( $00, SouthPos shr 3,
                             SouthPos And $7, $7C ))); {v1.24}
                    SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $7C,
                               PIIXReg3 ); {v1.24}
                    If PIIXReg4 And $10=$10 Then {v1.34}
                      Begin
                        LogWrite('ALi method: restoring PMU reg $C0 from '+Hl(
                                 GetPCIRegD($00,PMUPos shr 3,
                                 PMUPos And $7,$C0)));
                        SetPCIRegD($00,PMUPos shr 3,PMUPos And $7,$C0,PIIXReg5);
                      End;
                  End;
              End;
          End;
    $05 :
          Begin {SiS methods} {v1.21}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40
                           );
                LogWrite('SiS method: reg $40 = '+Hl(PIIXReg)); {v1.23}
           {Lower & extended BIOS enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40, PIIXReg
                           And $FFFFFFFB Or $B{or $3} );
                LogWrite('SiS method: reg $40 changed to '+Hl(GetPCIRegD($00,
                         SouthPos shr 3,SouthPos And $7,$40))); {v1.23}
                Case Lo(SouthFunc) Of 
                  $01:
                       Begin {internal reg. 80h}
                         Port[ $22 ] := $80;
                         PIIXReg2 := Port[ $23 ];
                         LogWrite('SiS method 1: internal reg $80 = '+Hl(
                                  PIIXReg2)); {v1.23}
                         Port[ $22 ] := $80;
                         Port[ $23 ] := PIIXReg2 And $DF Or $4;
                         {Enable Flash ROM write}
                         Port[ $22 ] := $80;
                         LogWrite('SiS method 1: internal reg $80 changed to '+
                                  Hl(Port[$23])); {v1.23}
                   {v1.23 registers can be also at $70}
                         Port[ $22 ] := $70;
                         PIIXReg3 := Port[ $23 ];
                         LogWrite('SiS method 1: internal reg $70 = '+Hl(
                                  PIIXReg3)); {v1.23}
                         Port[ $22 ] := $70;
                         Port[ $23 ] := PIIXReg3 And $DF Or $4;
                         {Enable Flash ROM write}
                         Port[ $22 ] := $70;
                         LogWrite('SiS method 1: internal reg $70 changed to '+
                                  Hl(Port[$23])); {v1.23}
                       End;
                  $02:
                       Begin {internal reg. 50h}
                         Port[ $22 ] := $50;
                         PIIXReg2 := Port[ $23 ];
                         LogWrite('SiS method 2: internal reg $50 = '+Hl(
                                  PIIXReg2)); {v1.23}
                         Port[ $22 ] := $50;
                         Port[ $23 ] := PIIXReg2 And $DF Or $4;
                         {Enable Flash ROM write}
                         Port[ $22 ] := $50;
                         LogWrite('SiS method 2: internal reg $50 changed to '+
                                  Hl(Port[$23])); {v1.23}
                       End;
                  $03:
                       Begin {PCI reg. 45h bits 5,2}
                         PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos
                                     And $7, $44 );
                         LogWrite('SiS method 3: reg $44 = '+Hl(PIIXReg2));
                         {v1.23}
                         SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44,
                                    PIIXReg2 And $FFFFDFFF Or $400 );
                         LogWrite('SiS method 3: reg $44 changed to '+Hl(
                                  GetPCIRegD( $00, SouthPos shr 3,
                                  SouthPos And $7, $44 ))); {v1.23}
                       End;
                  $04:
                       Begin {PCI reg. 45h bits 7,6}
                         PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos
                                     And $7, $44 );
                         LogWrite('SiS method 4: reg $44 = '+Hl(PIIXReg2));
                         {v1.23}
                         SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44,
                                    PIIXReg2 And $FFFF7FFF Or $4000 );
                         LogWrite('SiS method 4: reg $44 changed to '+Hl(
                                  GetPCIRegD( $00, SouthPos shr 3,
                                  SouthPos And $7, $44 ))); {v1.23}
                       End;
                End;
              End
            Else
              Begin
                LogWrite('SiS method: restoring reg $40 from '+Hl(GetPCIRegD($00
                         ,SouthPos shr 3,SouthPos And $7,$40))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40, PIIXReg )
                ;
                Case Lo(SouthFunc) Of 
                  $01:
                       Begin {internal reg. 80h}
                         Port[ $22 ] := $80;
                         LogWrite(
                                'SiS method 1: restoring internal reg $80 from '
                                  +Hl(Port[$23])); {v1.23}
                         Port[ $22 ] := $80;
                         Port[ $23 ] := PIIXReg2;
                   {v1.23 registers can be also at $70}
                         Port[ $22 ] := $70;
                         LogWrite(
                                'SiS method 1: restoring internal reg $70 from '
                                  +Hl(Port[$23])); {v1.23}
                         Port[ $22 ] := $70;
                         Port[ $23 ] := PIIXReg3;
                       End;
                  $02:
                       Begin {internal reg. 50h}
                         Port[ $22 ] := $50;
                         LogWrite(
                                'SiS method 2: restoring internal reg $50 from '
                                  +Hl(Port[$23])); {v1.23}
                         Port[ $22 ] := $50;
                         Port[ $23 ] := PIIXReg2;
                       End;
                  $03,$04:
                           Begin {PCI reg. 45h}
                             LogWrite('SiS method 3/4: restoring reg $44 from '+
                                      Hl(GetPCIRegD( $00, SouthPos shr 3,
                                      SouthPos And $7, $44 ))); {v1.23}
                             SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                                        44, PIIXReg2 );
                           End;
                End;
              End;
          End;
    $06 :
          Begin {SMSC method} {v1.21}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C
                           );
                LogWrite('SMSC method: reg $4C = '+Hl(PIIXReg)); {v1.23}
           {write & 1M enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg
                           Or $02C40000 );
                LogWrite('SMSC method: reg $4C changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $4C ))); {v1.23}
              End
            Else
              Begin
                LogWrite('SMSC method: restoring reg $4C from '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $4C ))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg )
                ;
              End;
          End;
    $07 :
          Begin {Winbond method} {v1.21}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C
                           );
                LogWrite('Winbond method: reg $4C = '+Hl(PIIXReg)); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg
                           And $DF00 Or $D000 );
                LogWrite('Winbond method: reg $4C changed to '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $4C ))); {v1.23}
              End
            Else
              Begin
                LogWrite('Winbond method: restoring reg $4C from '+Hl(GetPCIRegD
                         ( $00, SouthPos shr 3,
                         SouthPos And $7, $4C ))); {v1.23}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $4C, PIIXReg )
                ;
              End;
          End;
    $08 :
          Begin {ITE methods} {v1.21}
            If Map Then
              Begin
                Case Lo(SouthFunc) Of 
                  $01:
                       Begin
                         PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos
                                    And $7, $44 );
                         LogWrite('ITE method 1: reg $44 = '+Hl(PIIXReg));
                         {v1.23}
                  {write enable}
                         SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44,
                                    PIIXReg And $FFFF7FFF );
                         LogWrite('ITE method 1: reg $44 changed to '+Hl(
                                  GetPCIRegD( $00, SouthPos shr 3,
                                  SouthPos And $7, $44 ))); {v1.23}
                       End;
                  $02:
                       Begin
                         PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos
                                    And $7, $50 );
                         LogWrite('ITE method 2: reg $50 = '+Hl(PIIXReg));
                         {v1.23}
                         SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $50,
                                    PIIXReg Or $E0000000 And $FEFFFFFF );
                         LogWrite('ITE method 2: reg $50 changed to '+Hl(
                                  GetPCIRegD( $00, SouthPos shr 3,
                                  SouthPos And $7, $50 ))); {v1.23}
                       End;
                End;
              End
            Else
              Begin
                Case Lo(SouthFunc) Of 
                  $01:
                       Begin
                         LogWrite('ITE method 1: restoring reg $44 from '+Hl(
                                  GetPCIRegD( $00, SouthPos shr 3,
                                  SouthPos And $7, $44 ))); {v1.23}
                         SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44,
                                    PIIXReg );
                       End;
                  $02:
                       Begin
                         LogWrite('ITE method 2: restoring reg $50 from '+Hl(
                                  GetPCIRegD( $00, SouthPos shr 3,
                                  SouthPos And $7, $50 ))); {v1.23}
                         SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $50,
                                    PIIXReg );
                       End;
                End;
              End;
          End;
    $09 :
          Begin {Reliance method} {v1.24}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40
                           );
                LogWrite('Reliance method: reg $40 = '+Hl(PIIXReg));
           {512K enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40, PIIXReg
                           Or $00000200 );
                LogWrite('Reliance method: reg $40 changed to '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3, SouthPos And $7, $40 )));

                PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            70 );
                LogWrite('Reliance method: reg $70 = '+Hl(PIIXReg2));
           {4MB enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $70, PIIXReg2
                           Or $00000080 );
                LogWrite('Reliance method: reg $70 changed to '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3, SouthPos And $7, $70 )));

                LogWrite('Reliance method: internal reg $C6F = '+Hl(Port[$C6F]))
                ;
                Port[$C6F] := Port[$C6F] Or $40; {Flash write enable}
                LogWrite('Reliance method: internal reg $C6F changed to '+Hl(
                         Port[$C6F]));
              End
            Else
              Begin
                LogWrite('Reliance method: restoring reg $40 from '+Hl(
                         GetPCIRegD( $00, SouthPos shr 3,
                         SouthPos And $7, $40 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $40, PIIXReg )
                ;
                LogWrite('Reliance method: restoring reg $70 from '+Hl(
                         GetPCIRegD( $00, SouthPos shr 3,
                         SouthPos And $7, $70 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $70, PIIXReg2
                );
                LogWrite('Reliance method: restoring internal reg $C6F from '+Hl
                         (Port[$C6F]));
                Port[$C6F] := Port[$C6F] And $BF; {Flash write disable}
              End;
          End;
    $10 :
          Begin {PicoPower method} {v1.25}
            If Map Then
              Begin
                Port[$24] := $03;
                PIIXReg := Port[$26];
                LogWrite('PicoPower method: internal reg $03 = '+Hl(PIIXReg));
                Port[$24] := $03;
                Port[$26] := PIIXReg Or $40; {Flash enable}
                Port[$24] := $03;
                LogWrite('PicoPower method: internal reg $03 changed to '+Hl(
                         Port[$26]));
              End
            Else
              Begin
                Port[$24] := $03;
                LogWrite('PicoPower method: restoring internal reg $03 from '+Hl
                         (Port[$26]));
                Port[$24] := $03;
                Port[$26] := PIIXReg;
              End;
          End;
    $11 :
          Begin {Cyrix method} {v1.25}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $50
                           );
                LogWrite('Cyrix method: reg $50 = '+Hl(PIIXReg));
           {16MB enable, write enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $50, PIIXReg
                           Or $00060000 );
                LogWrite('Cyrix method: reg $50 changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $50 )));
              End
            Else
              Begin
                LogWrite('Cyrix method: restoring reg $50 from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $50 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $50, PIIXReg )
                ;
              End;
          End;
    $12 :
          Begin {OPTi method} {v1.26}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44
                           );
                LogWrite('OPTi method: reg $44 = '+Hl(PIIXReg));
           {write enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg
                           Or $80000000 );
                LogWrite('OPTi method: reg $44 changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $44 )));

                PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            48 );
                LogWrite('OPTi method: reg $48 = '+Hl(PIIXReg2));
           {256k enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $48, PIIXReg2
                           And $FFFFFF Or $3F000000 ); {v1.37}
                LogWrite('OPTi method: reg $48 changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $48 )));
              End
            Else
              Begin
                LogWrite('OPTi method: restoring reg $44 from '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $44 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg )
                ;
                LogWrite('OPTi method: restoring reg $48 from '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $48 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $48, PIIXReg2
                );
              End;
          End;
    $13 :
          Begin {Utron method} {v1.26}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $60
                           );
                LogWrite('Utron method: reg $60 = '+Hl(PIIXReg));
           {write & 128k enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $60, PIIXReg
                           And $FFFFEFFF Or $2{or $802} ); {v1.28}
                LogWrite('Utron method: reg $60 changed to '+Hl(GetPCIRegD( $00,
                         SouthPos shr 3, SouthPos And $7, $60 )));
              End
            Else
              Begin
                LogWrite('Utron method: restoring reg $60 from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $60 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $60, PIIXReg )
                ;
              End;
          End;
    $14 :
          Begin {UMC method} {v1.28}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44
                           );
                LogWrite('UMC method: reg $44 = '+Hl(PIIXReg));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg
                           And $BFFFFFFF);
              End
            Else
              Begin
                LogWrite('UMC method: restoring reg $44 from '+Hl(GetPCIRegD( $
                         00, SouthPos shr 3,
                         SouthPos And $7, $44 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg )
                ;
              End;
          End;
    $15 :
          Begin {Contaq/Cypress method} {v1.29}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44
                           );
                LogWrite('Cypress method: reg $44 = '+Hl(PIIXReg));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg
                           Or $E0000000);
              End
            Else
              Begin
                LogWrite('Cypress method: restoring reg $44 from '+Hl(GetPCIRegD
                         ( $00, SouthPos shr 3,
                         SouthPos And $7, $44 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg )
                ;
              End;
          End;
    $16 :
          Begin {nForce method} {v1.30}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44
                           );
                LogWrite('nForce method: reg $44 = '+Hl(PIIXReg));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg
                           Or $100);
                PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            70 );
                LogWrite('nForce method: reg $70 = '+Hl(PIIXReg2));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $70, PIIXReg2
                           And $FFE0FFFF Or $C0);
                PIIXReg3 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            74 );
                LogWrite('nForce method: reg $74 = '+Hl(PIIXReg3));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $74, 0);
                PIIXReg4 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            78 );
                LogWrite('nForce method: reg $78 = '+Hl(PIIXReg4));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $78, 0);
                PIIXReg5 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $7
                            C );
                LogWrite('nForce method: reg $7C = '+Hl(PIIXReg5));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $7C, 0);
              End
            Else
              Begin
                LogWrite('nForce method: restoring reg $44 from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $44 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $44, PIIXReg )
                ;
                LogWrite('nForce method: restoring reg $70 from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $70 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $70, PIIXReg2
                );
                LogWrite('nForce method: restoring reg $74 from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $74 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $74, PIIXReg3
                );
                LogWrite('nForce method: restoring reg $78 from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $78 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $78, PIIXReg4
                );
                LogWrite('nForce method: restoring reg $7C from '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $7C )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $7C, PIIXReg5
                );
              End;
          End;
    $17 :
          Begin {Intel 9xx (ICH6) method} {v1.37}
            If Map Then
              Begin
                PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $DC
                           );
                LogWrite('Intel 9xx method: reg $DC = '+Hl(PIIXReg));
           {FWH Write Enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $DC, PIIXReg
                           Or $1 );
                LogWrite('Intel 9xx method: reg $DC changed to '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $DC )));
                PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $
                            D8 );
                LogWrite('Intel 9xx method: reg $D8 = '+Hl(PIIXReg2));
           {FWH Decode at $FF000000-$FFFFFFFF = 16MB enable}
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $D8, PIIXReg2
                           Or $FF0F );
                LogWrite('Intel 9xx method: reg $D8 changed to '+Hl(GetPCIRegD(
                         $00, SouthPos shr 3,
                         SouthPos And $7, $D8 )));
              End
            Else
              Begin
                LogWrite('Intel 9xx method: restoring reg $DC from '+Hl(
                         GetPCIRegD( $00, SouthPos shr 3,
                         SouthPos And $7, $DC )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $DC, PIIXReg )
                ;
                LogWrite('Intel 9xx method: restoring reg $D8 from '+Hl(
                         GetPCIRegD( $00, SouthPos shr 3,
                         SouthPos And $7, $D8 )));
                SetPCIRegD( $00, SouthPos shr 3, SouthPos And $7, $D8, PIIXReg2
                );
              End;
          End;
  End;

  Case Hi(LPCFunc) Of {v1.27}
    $01:
         Begin
           If Map Then
             Begin
               LPCUnlock;
               PIIXReg := LPCRead($24);
               LogWrite('ITE LPC method: reg $24 = '+Hl(PIIXReg));
             {512K enable, write enable}
               LPCWrite($24,PIIXReg Or $7C);
               LogWrite('ITE LPC method: reg $24 changed to '+Hl(LPCRead($24)));
               LPCLock_ITE;
             End
           Else
             Begin
               LPCUnlock;
               LogWrite('ITE LPC method: restoring reg $24 from '+Hl(LPCRead($24
               )));
               LPCWrite($24,PIIXReg);
               LPCLock_ITE;
             End;
         End;
    $02:
         Begin {v1.33}
           If Map Then
             Begin
               LPCUnlock;
               PIIXReg := LPCRead($24);
               LogWrite('Winbond LPC method: reg $24 = '+Hl(PIIXReg));
             {512K enable, write enable}
               LPCWrite($24,PIIXReg And $C7 Or $28);
               LogWrite('Winbond LPC method: reg $24 changed to '+Hl(LPCRead($24
               )));
               LPCLock_WB;
             End
           Else
             Begin
               LPCUnlock;
               LogWrite('Winbond LPC method: restoring reg $24 from '+Hl(LPCRead
                        ($24)));
               LPCWrite($24,PIIXReg);
               LPCLock_WB;
             End;
         End;
  End;
  ROMEnabled := Map; {v1.22}
End;

Procedure ShadowDisable_Aladdin; {v1.31}
Begin
  SetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $4C, PIIXReg And $00FF00FF )
  ;
End;

Procedure ShadowRestore_Aladdin; {v1.31}
Begin
  SetPCIRegD( $00, NorthPos shr 3, NorthPos And $7, $4C, PIIXReg And $00FFFFFF )
  ;
End;

Begin
  AMIUsed := False;
  WantToUseAMI := False;
  AsusUsed := False;
  WantToUseAsus := False;
  ChipsetFound := False;
  ROMEnabled := False; {v1.22}
 {v1.22 Initialization moved to UNIFLASH.PAS}
End.
