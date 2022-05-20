{$R-}
unit PCI;  { Unit to communicate with chipsets }

interface

uses AMIBIOS, AsusBIOS;

Const
PCICfIdx    = $CF8;
PCICfData   = $CFC;

Var
NorthFunc, SouthFunc, LPCFunc: Word;
NorthPos,SouthPos,PMUPos,CurPCIROM,PCIROMBus,PCIROMDev,PCIROMFun,LPCBase: Byte;
CurrentChipset, CurrentPCICard: string;
WantToUseAMI, AMIUsed, ChipsetFound, ROMEnabled, PCIROMEnabled: Boolean;
WantToUseAsus, AsusUsed: Boolean;
PCIROMs: array[1..20] of
          record
            MaxSize      : LongInt;
            VenID, DevID : Word;
            Bus, Pos     : Byte;
          end;
BIOSID: array[1..8] of Char; {v1.34}

Procedure OPortD( Prt : Word; Val : LongInt );
Function  IPortD( Prt : Word ) : LongInt;
Function  GetPCIRegD( Bus, Dev, Func, Reg : Byte ) : LongInt;
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Function  LocatePIIX : {byte}Boolean; {v1.22 byte->boolean}
procedure GetBIOSID;
Procedure RomEnable( Map : boolean);
procedure ShadowDisable_Aladdin; {v1.31}
procedure ShadowRestore_Aladdin; {v1.31}

implementation

Uses Tools,Flash,Crt,DMI;

{ PortD[ x ] := y }
Procedure OPortD( Prt : Word; Val : LongInt ); Assembler;
Asm
 DB     66H
 MOV    AX,WORD PTR Val
 MOV    DX,Prt
 DB     66H
 OUT    DX,AX
End;

{ y := PortD[ x ] }
Function IPortD( Prt : Word ) : LongInt; Assembler;
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
 OPortD( PCICfIdx, $80000000 or
                   ( LongInt( Bus ) shl 16 ) or
                   ( ( LongInt( Dev ) and $1F ) shl 11 ) or
                   ( ( LongInt( Func ) and $7 ) shl 8 ) or
                   ( Reg and $FC ) );
 GetPCIRegD := IPortD( PCICfData );
End;

{Write PCI configuration reg}
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Begin
 OPortD( PCICfIdx, $80000000 or
                   ( LongInt( Bus ) shl 16 ) or
                   ( ( LongInt( Dev ) and $1F ) shl 11 ) or
                   ( ( LongInt( Func ) and $7 ) shl 8 ) or
                   ( Reg and $FC ) );
 OPortD( PCICfData, Value );
End;

function LPCRead(Index:Byte):Byte; {v1.27}
begin
  Port[LPCBase]:=Index;
  LPCRead:=Port[LPCBase+1];
end;

procedure LPCWrite(Index,Data:Byte); {v1.27}
begin
  Port[LPCBase]:=Index;
  Port[LPCBase+1]:=Data;
end;

procedure LPCUnlock; {v1.27}
begin
  Port[LPCBase]:=$87;
  Port[LPCBase]:=$87;
  Port[LPCBase]:=$87;
  Port[LPCBase]:=$01;
  Port[LPCBase]:=$55;
  case LPCBase of
   $2E: Port[LPCBase]:=$55;
   $4E: Port[LPCBase]:=$AA;
  end;
end;

procedure LPCLock_ITE; {v1.39}
begin
  LPCWrite($02,LPCRead($02) or 2);
end;

procedure LPCLock_WB; {v1.39}
begin
  Port[LPCBase]:=$AA;
end;

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

  function LPCDetectAt(Base: Byte):Word;
  var ID:Word;
  begin
    LPCBase:=Base;
    LPCName:='';
    LPCDetectAt:=$0;
    LPCUnlock;
    ID:=256*word(LPCRead($20));
    ID:=ID+LPCRead($21);
    case ID of
     $8702: begin LPCDetectAt:=$0000; LPCName:='ITE IT8702F'; end; {v1.39}
     $8705: begin LPCDetectAt:=$0100; LPCName:='ITE IT8700F/05F'; end;
     $8710: begin LPCDetectAt:=$0100; LPCName:='ITE IT8710F'; end;
     $8711: begin LPCDetectAt:=$0000; LPCName:='ITE IT8711F'; end; {v1.39}
     $8712: begin LPCDetectAt:=$0000; LPCName:='ITE IT8712F'; end; {v1.39}
     $8722: begin LPCDetectAt:=$0000; LPCName:='ITE IT8722F'; end; {v1.39}
    end;
    if LPCName<>'' then
     begin
       LPCLock_ITE;
       Exit;
     end;
    case ID and $FFF0 of
     $5210,
     $5230: begin LPCDetectAt:=$0000; LPCName:='Winbond W83627(H)F'; end; {v1.39}
     $5950: begin LPCDetectAt:=$0000; LPCName:='Winbond W83627SF/GF'; end; {v1.39}
     $6010: begin LPCDetectAt:=$0200; LPCName:='Winbond W83697(H)F'; end;
     $6800: begin LPCDetectAt:=$0200; LPCName:='Winbond W83697SF'; end;
     $6810: begin LPCDetectAt:=$0200; LPCName:='Winbond W83697UF'; end;
     $7080: begin LPCDetectAt:=$0000; LPCName:='Winbond W83637HF'; end; {v1.39}
     $8280: begin LPCDetectAt:=$0000; LPCName:='Winbond W83627THF'; end; {v1.39}
     end;
    if LPCName<>'' then
     begin
       LPCLock_WB;
       Exit;
     end;
    LPCBase:=0;
    LogWrite('Unknown LPC ID '+Hw(ID));
  end;

  function LPCDetect:Word; {v1.27}
  begin
    LogWrite('Detecting LPC Super I/O chip...');
    LPCDetect:=LPCDetectAt($2E);
    if LPCBase=0 then LPCDetect:=LPCDetectAt($4E);
    if LPCBase<>0 then LogWrite('Detected '+LPCName+' at '+Hb(LPCBase));
  end;

Begin
 if Port[$CFB]<>$FF then {v1.26}
  Port[$CFB]:=Port[$CFB] or $1; {Set PCI configuration mechanism #1}
 {Locate north bridge}
 For Pos_ := 0 to $FF do
  If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ and $07, $00 ) and $FFFF ) <> $FFFF then
   If ( GetPCIRegD( $00, Pos_ shr 3,
                    Pos_ and $07, $08 ) shr 8 ) = $60000 then Break;
 If Pos_ = $FF then {v1.22}
  Begin
   LocatePIIX := False;
   Exit;
  End
 else LocatePIIX:=True;
 NorthPos := Pos_;
 {Get north bridge MID & DID}
 NorthMan := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $07, $00 );
 NorthId  := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $07, $00 ) shr 16;
 {Get north bridge rev ID}
 NorthRev := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $07, $08 );

 {Locate south bridge}
 For Pos_ := 0 to $FF do
  If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ and $07, $00 ) and $FFFF ) <> $FFFF then
   If ( GetPCIRegD( $00, Pos_ shr 3,
                    Pos_ and $07, $08 ) shr 8 ) = $60100 then Break;
 If Pos_ = $FF then {v1.22 for i430MX}
  For Pos_ := 0 to $FF do
   If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ and $07, $00 ) and $FFFF ) <> $FFFF then
    If ( GetPCIRegD( $00, Pos_ shr 3,
                     Pos_ and $07, $08 ) shr 8 ) = $68000 then Break;
 If Pos_ = $FF then {v1.31 for old chipsets}
  For Pos_ := 0 to $FF do
   If ( GetPCIRegD( $00, Pos_ shr 3, Pos_ and $07, $00 ) and $FFFF ) <> $FFFF then
    If ( GetPCIRegD( $00, Pos_ shr 3,
                     Pos_ and $07, $08 ) shr 8 ) = $00000 then Break;
 SouthPos := Pos_;
 {Get south bridge MID & DID}
 SouthMan := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $00 );
 SouthID := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $00 ) shr 16;
 {Get south bridge rev ID}
 SouthRev := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $08 );

 CurrentChipset := '';

 NorthFunc := 0; {No special treatment necessary}
 SouthFunc := 0; {Same}
 LPCFunc   := 0; {v1.27}
 NorthName:='';
 SouthName:='';
 LPCName:='';

 {Id northbridge}
 If NorthMan = $8086 {Intel} then
  Begin
   case NorthId of {case v1.21}
     $4A3: if NorthRev>=$10 then NorthName:='i82433NX' else NorthName:='i82433LX';
    $122D: NorthName:='i82437FX';
    $1235: NorthName:='i82437MX';
    $1237: NorthName:='i82441FX';
    $1250: NorthName:='i82439HX';
    $7030: NorthName:='i82437VX';
    $7100: NorthName:='i82439TX';
    $7180: NorthName:='i82443LX/EX';
    $7190, $7192: NorthName:='i82443BX/ZX';
    $71A0, $71A2: NorthName:='i82443GX';
    $84C4: NorthName:='i82454KX/GX';
    $7120: NorthName:='i82810';
    $7122: NorthName:='i82810-DC100';
    $7124: NorthName:='i82810E';
    $1130: NorthName:='i82815';
    $2500: NorthName:='i82820';
    $3575: NorthName:='i82830M';
    $1A21: NorthName:='i82840';
    $1A30: NorthName:='i82845';
    $2560: NorthName:='i82845G/P';
    $2530: NorthName:='i82850';
    $3580: NorthName:='i8285xGM';
    $3340: NorthName:='i82855PM';
    $2531: NorthName:='i82860';
    $2570: NorthName:='i82865'; {v1.34}
    $2578: NorthName:='i82875';
    $255D: NorthName:='iE7205';
    $2578: NorthName:='iE7210'; {v1.39}
    $2588: NorthName:='iE7221'; {v1.39}
    $3592: NorthName:='iE7320'; {v1.39}
    $2540: NorthName:='iE7500';
    $254C: NorthName:='iE7501';
    $2550: NorthName:='iE7505';
    $3590: NorthName:='iE7520'; {v1.39}
    $359E: NorthName:='iE7525'; {v1.39}
    $0500: NorthName:='iE8870'; {v1.39}
    $2580: NorthName:='i829xxx'; {v1.37}
    $2590: NorthName:='i829xxxM'; {v1.39}
   End;
  End else
 If NorthMan = $1106 {VIA} then
  Begin
   case NorthId of {case v1.21}
     $505: Begin {v1.37}
            NorthFunc := $0100; {VIA A8/A9 scheme}
            NorthName:='VT82C505';
           End;
     $576: Begin
            NorthFunc := $0100; {VIA A8/A9 scheme}
            NorthName:='VT82C576M';
           End;
     $585: NorthName:='VT82C585VP/VPX';
     $595: NorthName:='VT82C595/AMD-640';
     $597: NorthName:='VT82C597';
     $598: NorthName:='VT82C598(AT)';
     $685: Begin
            NorthFunc := $0100; {VIA A8/A9 scheme}
            NorthName:='VT82C685';
           End;
     $501: NorthName:='VT8501';
     $691: NorthName:='VT82C691/693(A)/694X/T';
     $693: NorthName:='VT82C693(A)';
     $601: NorthName:='VT8601';
     $605: NorthName:='VT8605';
     $391: NorthName:='VT8371';
     $305: NorthName:='VT8363(A)/8365';
    $3099: NorthName:='VT8366(A)';
    $3091: NorthName:='VT8633';
    $3101: NorthName:='VT8653';
    $3102: NorthName:='VT8662';
    $3103: NorthName:='VT8615';
    $3112: NorthName:='VT8361';
    $3133: NorthName:='VT3133';
    $3148: NorthName:='VT8751';
    $3128: NorthName:='VT8753(A)/8754';
    $3189: NorthName:='VT8377';
    $3205: NorthName:='VT8378';
   End;
  End else
 If NorthMan = $1022 {AMD} then {v1.20}
  Begin
   case NorthId of {case v1.21}
    $7006: NorthName:='AMD-751';
    $700E: NorthName:='AMD-761';
    $700C: NorthName:='AMD-762';
    $7454: NorthName:='AMD-8151'; {v1.36}
   End;
  End else
 If NorthMan = $1039 {SiS} then
  Begin
   SouthFunc:=$0503; {SiS reg. 45 bits 5,2}
   case NorthId of
     $496: Begin
            NorthFunc := $0200; {SiS reg. D0 scheme}
            SouthFunc := 0;
            NorthName:='SiS 85C496+497';
           End;
     $406: Begin
            SouthFunc := $0501; {SiS internal reg. 80h}
            NorthName:='SiS 501/5101/5501';
           End;
    $5511: Begin
            SouthFunc := $0502; {SiS internal reg. 50h}
            NorthName:='SiS 5511';
           End;
    $5571: NorthName:='SiS 5571';
    $5591: NorthName:='SiS 5591/5592';
    $5596: Begin
            NorthName:='SiS 5596';
            SouthFunc := $0502; {SiS internal reg. 50h}
            LPCFunc:=LPCDetect; {v1.27}
           End;
    $5597: NorthName:='SiS 5597/5598/5581/5120';
    $0530: NorthName:='SiS 530';
    $0540: Begin
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            NorthName:='SiS 540';
           End;
    $5600: NorthName:='SiS 600';
    $0620: NorthName:='SiS 620';
    $0630: Begin
            NorthName:='SiS 630';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect; {v1.27}
           End;
    $0635: Begin
            NorthName:='SiS 635';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0640: Begin
            NorthName:='SiS 640';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0645: Begin
            NorthName:='SiS 645';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0646: Begin
            NorthName:='SiS 645DX';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0648: Begin {v1.31}
            NorthName:='SiS 648';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0650: Begin
            NorthName:='SiS 650';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0651: Begin {v1.31}
            NorthName:='SiS 651';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0655: Begin {v1.31}
            NorthName:='SiS 655';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0730: Begin
            NorthName:='SiS 730';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0733: Begin {v1.31}
            NorthName:='SiS 733';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0735: Begin
            NorthName:='SiS 735';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0740: Begin
            NorthName:='SiS 740';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0745: Begin {v1.31}
            NorthName:='SiS 745';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0746: Begin {v1.31}
            NorthName:='SiS 746';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0748: Begin {v1.31}
            NorthName:='SiS 748';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
    $0755: Begin {v1.31}
            NorthName:='SiS 755';
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            LPCFunc:=LPCDetect;
           End;
   End;
  End else
 If NorthMan = $10B9 {ALi} then
  Begin
   case NorthId of
    $1451: begin
             NorthFunc := $0300; {ALi Aladdin}
             NorthName:='M1451';
           end;
    $1489: begin
             NorthFunc := $0301; {ALi FinALi}
             NorthName:='M1489';
           end;
    $1521: NorthName:='M1521';
    $1531: NorthName:='M1531(B)';
    $1541: NorthName:='M1541/1542';
    $1561: NorthName:='M1561'; {v1.31}
    $1621: NorthName:='M1621';
    $1631: NorthName:='M1631';
    $1632: NorthName:='M1632M';
    $1641: NorthName:='M1641';
    $1647: NorthName:='M1647';
    $1651: NorthName:='M1651'; {v1.31}
    $1671: NorthName:='M1671'; {v1.31}
    $1672: NorthName:='M1672'; {v1.31}
   End;
  End else
 If NorthMan = $1166 {Reliance/ServerWorks} then {v1.25}
  Begin
   case NorthId of
    $0007: NorthName:='Reliance NB6635';
    $0008: NorthName:='Reliance NB6536';
   End;
  End else
 If NorthMan = $1066 {PicoPower} then {v1.25}
  Begin
   case NorthId of
    $0001: NorthName:='Vesuvius V1-LS';
   End;
  End else
 If NorthMan = $1078 {Cyrix} then {v1.25}
  Begin
   case NorthId of
    $0001: NorthName:='MediaGX';
   End;
  End else
 If NorthMan = $1045 {OPTi} then {v1.26}
  Begin
   case NorthId of
    $C557: NorthName:='OPTi 82C557(M)'; {v1.37}
    $C567: NorthName:='OPTi 82C567';
   end;
  End else
 If NorthMan = $3388 {HiNT} then {v1.26}
  Begin
   case NorthId of
    $8011: NorthName:='HiNT VXPro-II North';
   end;
  End else
 If NorthMan = $1060 {UMC} then {v1.28}
  Begin
   case NorthId of
    $8881: NorthName:='UMC UM8881F';
   end;
  End else
 If NorthMan = $1344 {Micron} then {v1.29}
  Begin
   case NorthId of
    $3320: NorthName:='Micron MT8LLN21PADF';
   end;
  End else
 If NorthMan = $1080 {Contaq/Cypress} then {v1.29}
  Begin
   case NorthId of
    $0600: begin {CY82C599}
             NorthFunc := $0400;
             NorthName:='CY82C599';
           end;
    $C691: NorthName:='CY82C691';
   end;
  End else
 If NorthMan = $10DE {nVidia} then {v1.30}
  Begin
   case NorthId of
    $1A4: NorthName:='nVidia IGP';
    $1E0: NorthName:='nVidia IGP2';
   end;
  End;

 {Id southbridge}
 If SouthMan = $8086 {Intel} then
  Begin
   if (Hi(SouthId)=$24) or (Hi(SouthId)=$25) then SouthFunc := $0200
     else SouthFunc := $0100; {v1.21}
   if Hi(SouthId)=$26 then SouthFunc := $1700; {v1.37}
   case SouthId of {case v1.21}
     $484: Begin
            if SouthRev<$88 then SouthName:='i82378ZB SIO' else
             SouthName:='i82379AB SIO.A';
            SouthFunc:=$0104; {v1.29}
           End;
    $122E: Begin
            SouthName:='i82371FB PIIX';
            Inc( SouthFunc ); {v1.23}
           End;
    $1234: SouthName:='i82371MX MPIIX';
    $7000: Begin
            SouthName:='i82371SB PIIX3';
            Inc( SouthFunc );
           End;
    $7110: Begin
            SouthName:='i82371AB/EB PIIX4(E)';
            Inc( SouthFunc, 3 );
            if NorthName='i82439TX' then SouthFunc:=SouthFunc+$10; {v1.33}
           End;
    $2410: SouthName:='i82801AA ICH';
    $2420: SouthName:='i82801AB ICH0';
    $2440: SouthName:='i82801BA ICH2';
    $244C: SouthName:='i82801BAM ICH2-M';
    $248C: SouthName:='i82801CAM ICH3-M';
    $2480: SouthName:='i82801CA ICH3-S';
    $24C0: SouthName:='i82801DB ICH4';
    $24CC: SouthName:='i82801DBM ICH4-M';
    $24D0: SouthName:='i82801EB ICH5(R)';
    $2640: SouthName:='i82801FB/R ICH6(R)'; {v1.37}
    $2641: SouthName:='i82801FBM ICH6-M'; {v1.39}
    $2642: SouthName:='i82801F(R)W ICH6(R)W'; {v1.37}
    $25A1: SouthName:='i6300ESB ICH'; {v1.39}
   End;
  End else
 If SouthMan = $1106 {VIA} then
  Begin
   SouthFunc := $0300; {VIA/AMD method}
   case SouthId of {case v1.21}
     $586: SouthName:='VT82C586(A|B)/AMD-645';
     $596: Begin SouthName:='VT82C596(A|B)'; Inc( SouthFunc ); End;
     $686: Begin SouthName:='VT82C686(A|B)'; Inc( SouthFunc ); End;
    $8231: SouthName:='VT8231';
    $3074,$3147: begin SouthName:='VT8233(A|C)'; SouthFunc := $0310; LPCFunc:=LPCDetect; end;
    $3177: begin SouthName:='VT8235'; SouthFunc := $0310; LPCFunc:=LPCDetect; end;
    $3227: begin SouthName:='VT8237'; SouthFunc := $0310; LPCFunc:=LPCDetect; end; {v1.39}
   End;
  End else
 If SouthMan = $1022 {AMD} then {v1.20}
  Begin
   SouthFunc := $0300; {AMD/VIA method}
   case SouthId of {case v1.21}
    $7408: SouthName:='AMD-756';
    $7410: SouthName:='AMD-766';
    $7440: SouthName:='AMD-768';
    $7468: SouthName:='AMD-8111'; {v1.36}
   end;
  End else
 If SouthMan = $1039 {SiS} then
  Begin
   case SouthId of {v1.21}
     $8: SouthName:='SiS South Bridge'; {any SiS South Bridge}
    $18: SouthName:='SiS 950'; {SiS 950 can have $8 or $18}
   $964: SouthName:='SiS 964'; {v1.35}
   End;
  End else
 If SouthMan = $10B9 {ALi} then {v1.18}
  Begin
   SouthFunc := $0400; {ALi method}
   case SouthId of
    $1449: begin SouthName:='M1449'; SouthFunc:=0; end;
    $1523: SouthName:='M1523(B)';
    $1533,
    $1543,
    $1535: begin SouthName:='M1533/1543/1535'; Inc(SouthFunc); end;
   end;
  End else
 If SouthMan = $1055 {SMSC} then {v1.21}
  Begin
   If SouthId = $9460 then {SLC90E66} {v1.21}
    Begin
     SouthFunc := $0600; {SMSC method}
     SouthName:='SMSC SLC90E66';
    End;
  End else
 If SouthMan = $10AD {Winbond/Symphony Labs} then {v1.21}
  Begin
   If SouthId = $0565 then {W83C553F/4F} {v1.21}
    Begin
     SouthFunc := $0700; {Winbond method}
     SouthName:='Winbond W83C553F/4F';
    End;
  End else
 If SouthMan = $1283 {ITE} then {v1.21}
  Begin
   case SouthId of
    $8872 : Begin SouthFunc := $0801; SouthName:='ITE IT8871F/2F'; End;
    $8888 : Begin SouthFunc := $0802; SouthName:='ITE IT8888F'; End;
   End;
  End else
 If SouthMan = $1166 {Reliance/ServerWorks} then {v1.24}
  Begin
   SouthFunc:=$0900;
   case SouthId of
    $0200 : SouthName:='Reliance OSB4';
   End;
  End else
 If SouthMan = $1066 {PicoPower} then {v1.25}
  Begin
   SouthFunc:=$1000;
   case SouthId of
    $0002,$8002 : SouthName:='Vesuvius V3-LS';
   End;
  End else
 If SouthMan = $100B {National} then {v1.36}
  Begin
   SouthFunc:=$1100;
   case SouthId of
    $0500 : begin SouthName:='Geode SCx200'; LPCFunc:=LPCDetect; end;
    $0510 : begin SouthName:='Geode SC1100'; LPCFunc:=LPCDetect; end;
   End;
  End else
 If SouthMan = $1078 {Cyrix} then {v1.25}
  Begin
   SouthFunc:=$1100;
   case SouthId of
    $0000 : SouthName:='Cyrix Cx5510'; {v1.36}
    $0002 : SouthName:='Cyrix Cx5520'; {v1.36}
    $0100 : SouthName:='Cyrix Cx5530(A)';
   End;
  End else
 If SouthMan = $1045 {OPTi} then {v1.26}
  Begin
   SouthFunc:=$1200;
   case SouthId of
    $C558: SouthName:='OPTi 82C558(M)';
    $C568: SouthName:='OPTi 82C568';
   end;
  End else
 If SouthMan = $3388 {HiNT} then {v1.26}
  Begin
   SouthFunc:=$1300;
   case SouthId of
    $8012: SouthName:='HiNT VXPro-II South';
   end;
  End;
 If SouthMan = $1060 {UMC} then {v1.28}
  Begin
   SouthFunc:=$1400;
   case SouthId of
    $886A: SouthName:='UMC UM8886BF';
   end;
  End else
 If SouthMan = $1344 {Micron} then {v1.29}
  Begin
   case SouthId of
    $3470: SouthName:='Micron MT7LLN22NCNE';
   end;
  End else
 If SouthMan = $1080 {Contaq/Cypress} then {v1.29}
  Begin
   SouthFunc:=$1500;
   case SouthId of
    $C693: SouthName:='CY82C693(U/UB)';
   end;
  End else
 If SouthMan = $10DE {nVidia} then {v1.30}
  Begin
   SouthFunc:=$1600;
   case SouthId of
    $01B2: SouthName:='nVidia MCP/MCP-D';
    $0060: SouthName:='nVidia MCP2';
   end;
  End;


 {Id chipset as a whole}
 CurrentChipset := '';

 if (NorthName='i82433LX') and ((SouthName='i82378ZB SIO') or (SouthName='i82379AB SIO.A'))
  then CurrentChipset:='Intel Mercury 430LX';
 if (NorthName='i82433NX') and ((SouthName='i82378ZB SIO') or (SouthName='i82379AB SIO.A'))
  then CurrentChipset:='Intel Neptune 430NX';
 if (NorthName='i82437FX') and (SouthName='i82371FB PIIX')
  then CurrentChipset:='Intel Triton 430FX';
 if (NorthName='i82437MX') and (SouthName='i82371MX MPIIX')
  then CurrentChipset:='Intel 430MX (mobile)';
 if (NorthName='i82441FX') and (SouthName='i82371SB PIIX3')
  then CurrentChipset:='Intel Natoma 440FX';
 if (NorthName='i82439HX') and (SouthName='i82371SB PIIX3')
  then CurrentChipset:='Intel Triton II 430HX';
 if (NorthName='i82437VX') and (SouthName='i82371SB PIIX3')
  then CurrentChipset:='Intel Triton II 430VX';
 if (NorthName='i82439TX') and (SouthName='i82371AB/EB PIIX4(E)')
  then CurrentChipset:='Intel Triton III 430TX';
 if (NorthName='i82443LX/EX') and (SouthName='i82371AB/EB PIIX4(E)')
  then CurrentChipset:='Intel AGPSet 440LX/EX';
 if (NorthName='i82443BX/ZX') and (SouthName='i82371AB/EB PIIX4(E)')
  then CurrentChipset:='Intel AGPSet 440BX/ZX';
 if (NorthName='i82443BX/ZX') and (SouthName='SMSC SLC90E66')
  then CurrentChipset:='SMSC VictoryBX-66';
 if (NorthName='i82443GX') and (SouthName='i82371AB/EB PIIX4(E)')
  then CurrentChipset:='Intel AGPSet 440GX';
 if (NorthName='i82454KX/GX') and ((SouthName='i82379AB SIO.A') or (SouthName='i82371FB PIIX') or (SouthName='i82371SB PIIX3'))
  then CurrentChipset:='Intel 450KX/GX';
 if (NorthName='i82810') and ((SouthName='i82801AA ICH') or (SouthName='i82801AB ICH0'))
  then CurrentChipset:='Intel 810';
 if (NorthName='i82810-DC100') and ((SouthName='i82801AA ICH') or (SouthName='i82801AB ICH0'))
  then CurrentChipset:='Intel 810-DC100';
 if (NorthName='i82810E') and ((SouthName='i82801AA ICH') or (SouthName='i82801AB ICH0'))
  then CurrentChipset:='Intel 810E';
 if (NorthName='i82810E') and (SouthName='i82801BA ICH2')
  then CurrentChipset:='Intel 810E2';
 if (NorthName='i82815') and ((SouthName='i82801AA ICH') or (SouthName='i82801AB ICH0'))
  then CurrentChipset:='Intel 815(P/G)';
 if (NorthName='i82815') and (SouthName='i82801BA ICH2')
  then CurrentChipset:='Intel 815E(P/G)';
 if (NorthName='i82815') and (SouthName='i82801BAM ICH2-M')
  then CurrentChipset:='Intel 815EM';
 if (NorthName='i82820') and ((SouthName='i82801AA ICH') or (SouthName='i82801AB ICH0'))
  then CurrentChipset:='Intel 820';
 if (NorthName='i82820') and (SouthName='i82801BA ICH2')
  then CurrentChipset:='Intel 820E';
 if (NorthName='i82830M') and (SouthName='i82801CAM ICH3-M')
  then CurrentChipset:='Intel 830M(P/G)';
 if (NorthName='i82840') and ((SouthName='i82801AA ICH') or (SouthName='i82801AB ICH0'))
  then CurrentChipset:='Intel 840';
 if (NorthName='i82845') and (SouthName='i82801BA ICH2')
  then CurrentChipset:='Intel 845';
 if (NorthName='i82845') and (SouthName='i82801DB ICH4')
  then CurrentChipset:='Intel 845E'; {v1.31}
 if (NorthName='i82845G/P') and (SouthName='i82801DB ICH4')
  then CurrentChipset:='Intel 845G(E/L/V)/845PE'; {v1.31}
 if (NorthName='i82845') and (SouthName='i82801CAM ICH3-M')
  then CurrentChipset:='Intel 845MP/MZ'; {v1.31}
 if (NorthName='i82850') and (SouthName='i82801BA ICH2')
  then CurrentChipset:='Intel 850(E)';
 if (NorthName='i8285xGM') and ((SouthName='i82801DBM ICH4-M') or (SouthName='i82801DB ICH4') or (SouthName='i6300ESB ICH'))
  then CurrentChipset:='Intel 852GM(E)/855GM(E)'; {v1.31}
 if (NorthName='i82855PM') and (SouthName='i82801DBM ICH4-M')
  then CurrentChipset:='Intel 855PM'; {v1.31}
 if (NorthName='i82860') and (SouthName='i82801BA ICH2')
  then CurrentChipset:='Intel 860';
 if (NorthName='i82865') and (SouthName='i82801EB ICH5(R)')
  then CurrentChipset:='Intel 865P(E)/G(V)/848P'; {v1.34}
 if (NorthName='i82875') and ((SouthName='i82801EB ICH5(R)') or (SouthName='i6300ESB ICH'))
  then CurrentChipset:='Intel 875P'; {v1.31}
 if (NorthName='iE7205') and (SouthName='i82801DB ICH4')
  then CurrentChipset:='Intel E7205'; {v1.31}
 if (NorthName='iE7210') and (SouthName='i6300ESB ICH')
  then CurrentChipset:='Intel E7210'; {v1.39}
 if (NorthName='iE7221') and ((SouthName='i82801FB/R ICH6(R)') or (SouthName='i82801F(R)W ICH6(R)W'))
  then CurrentChipset:='Intel E7221'; {v1.39}
 if (NorthName='iE7500') and (SouthName='i82801CA ICH3-S')
  then CurrentChipset:='Intel E7500';
 if (NorthName='iE7320') and ((SouthName='i82801EB ICH5(R)') or (SouthName='i6300ESB ICH'))
  then CurrentChipset:='Intel E7320'; {v1.39}
 if (NorthName='iE7501') and (SouthName='i82801CA ICH3-S')
  then CurrentChipset:='Intel E7501'; {v1.31}
 if (NorthName='iE7505') and (SouthName='i82801DB ICH4')
  then CurrentChipset:='Intel E7505'; {v1.31}
 if (NorthName='iE7520') and ((SouthName='i82801EB ICH5(R)') or (SouthName='i6300ESB ICH'))
  then CurrentChipset:='Intel E7520'; {v1.39}
 if (NorthName='iE7525') and ((SouthName='i82801EB ICH5(R)') or (SouthName='i6300ESB ICH'))
  then CurrentChipset:='Intel E7525'; {v1.39}
 if (NorthName='iE8870') and (SouthName='i82801DB ICH4')
  then CurrentChipset:='Intel E8870'; {v1.39}
 if (NorthName='i829xxx') and ((SouthName='i82801FB/R ICH6(R)') or (SouthName='i82801F(R)W ICH6(R)W'))
  then CurrentChipset:='Intel 910/915/925 series'; {v1.37}
 if (NorthName='i829xxxM') and (SouthName='i82801FBM ICH6-M')
  then CurrentChipset:='Intel mobile 910/915 series'; {v1.39}

 if (NorthName='VT82C505') then CurrentChipset:='VIA 486 chipset with VT82C505'; {v1.37}
 if (NorthName='VT82C576M') then CurrentChipset:='VIA Apollo Master';
 if (NorthName='VT82C585VP/VPX') and (SouthName='VT82C586(A|B)/AMD-645')
  then CurrentChipset:='VIA Apollo VP/VPX';
 if (NorthName='VT82C595/AMD-640') and (SouthName='VT82C586(A|B)/AMD-645')
  then CurrentChipset:='VIA Apollo VP2/AMD 640';
 if (NorthName='VT82C597') and ((SouthName='VT82C586(A|B)/AMD-645') or (SouthName='VT82C596(A|B)'))
  then CurrentChipset:='VIA Apollo (M)VP3';
 if (NorthName='VT82C598(AT)') and ((SouthName='VT82C596(A|B)') or (SouthName='VT82C686(A|B)'))
  then CurrentChipset:='VIA Apollo MVP3';
 if (NorthName='VT82C685') then CurrentChipset:='VIA Apollo P6';
 if (NorthName='VT8501') and (SouthName='VT82C686(A|B)')
  then CurrentChipset:='VIA Apollo MVP4';
 if (NorthName='VT82C691/693(A)/694X/T') and ((SouthName='VT82C596(A|B)') or (SouthName='VT82C686(A|B)'))
  then CurrentChipset:='VIA Apollo Pro (Plus/133(A|T))';
 if (NorthName='VT82C693(A)') and ((SouthName='VT82C596(A|B)') or (SouthName='VT82C686(A|B)'))
  then CurrentChipset:='VIA Apollo Pro Plus/133(A)';
 if (NorthName='VT8601') and (SouthName='VT82C686(A|B)')
  then CurrentChipset:='VIA Apollo ProMedia';
 if (NorthName='VT8605') then CurrentChipset:='VIA Apollo Pro 133Z/PM133';
 if (NorthName='VT8371') and (SouthName='VT82C686(A|B)')
  then CurrentChipset:='VIA Apollo KX133';
 if (NorthName='VT8363(A)/8365') and (SouthName='VT82C686(A|B)')
  then CurrentChipset:='VIA Apollo KT133(A)';
 if (NorthName='VT8363(A)/8365') and (SouthName='VT8231')
  then CurrentChipset:='VIA ProSavage KM133(A)';
 if (NorthName='VT8366(A)') and ((SouthName='VT8233(A|C)') or (SouthName='VT8235'))
  then CurrentChipset:='VIA Apollo KT266(A)/KT333';
(* if (NorthName='VT8366(A)') and (SouthName='VT8235')
  then CurrentChipset:='VIA Apollo KT333'; {v1.31}*)
 if (NorthName='VT8377') and (SouthName='VT8235')
  then CurrentChipset:='VIA Apollo KT400(A)'; {v1.31}
 if (NorthName='VT8378') and ((SouthName='VT8233(A|C)') or (SouthName='VT8235') or (SouthName='VT8237'))
  then CurrentChipset:='VIA UniChrome KM400(A)'; {v1.39}
 if (NorthName='VT8633') and (SouthName='VT8233(A|C)')
  then CurrentChipset:='VIA Apollo Pro 266';
 if (NorthName='VT8653') and (SouthName='VT8233(A|C)')
  then CurrentChipset:='VIA Apollo Pro 266T'; {v1.31}
 if (NorthName='VT8751') and (SouthName='VT8233(A|C)')
  then CurrentChipset:='VIA ProSavage P4M266';
 if (NorthName='VT8753(A)/8754') and (SouthName='VT8233(A|C)')
  then CurrentChipset:='VIA P4X266(A)/P4X333/P4X400';

 if (NorthName='M1451') and (SouthName='M1449')
  then CurrentChipset:='ALi Aladdin';
 if (NorthName='M1489') then CurrentChipset:='ALi FinALi 486';
 if (NorthName='M1521') and (SouthName='M1523(B)')
  then CurrentChipset:='ALi Aladdin III';
 if (NorthName='M1531(B)') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin IV/IV+';
 if (NorthName='M1541/1542') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin V';
 if (NorthName='M1561') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin 7'; {v1.31}
 if (NorthName='M1621') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin Pro/Pro II';
 if (NorthName='M1631') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin Pro III (TNT2)'; {v1.31}
 if (NorthName='M1632M') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi CyberBLADE Aladdin i1'; {v1.31}
 if (NorthName='M1641') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin Pro IV';
 if (NorthName='M1647') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi ALiMAGiK/MobileMAGiK 1';
 if (NorthName='M1651') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin Pro 5(T/M)'; {v1.31}
 if (NorthName='M1671') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi Aladdin-P4'; {v1.31}
 if (NorthName='M1672') and (SouthName='M1533/1543/1535')
  then CurrentChipset:='ALi CyberAladdin-P4'; {v1.31}

 if (NorthName='AMD-751') and (SouthName='AMD-756')
  then CurrentChipset:='AMD 750';
 if (NorthName='AMD-761') and (SouthName='VT82C686(A|B)')
  then CurrentChipset:='AMD 760 (VIA South)';
 if (NorthName='AMD-761') and (SouthName='AMD-766')
  then CurrentChipset:='AMD 760 (AMD South)';
 if (NorthName='AMD-762') and (SouthName='AMD-766')
  then CurrentChipset:='AMD 760MP';
 if (NorthName='AMD-762') and (SouthName='AMD-768')
  then CurrentChipset:='AMD 760MPX';
 if (NorthName='AMD-8151') and (SouthName='AMD-8111')
  then CurrentChipset:='AMD 8000'; {v1.36}

 if (NorthName='SiS 85C496+497') then CurrentChipset:='SiS 85C496+497';
 if (NorthName='SiS 501/5101/5501') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 501/5101/5501';
 if (NorthName='SiS 5511') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 5511+5513';
 if (NorthName='SiS 5571') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 5571';
 if (NorthName='SiS 5591/5592') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 5591/5592+5595';
 if (NorthName='SiS 5596') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 5596+5595';
 if (NorthName='SiS 5597/5598/5581/5120') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 5597/5598/5581/5120';
 if (NorthName='SiS 530') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 530';
 if (NorthName='SiS 540') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 540';
 if (NorthName='SiS 600') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 600';
 if (NorthName='SiS 620') and (SouthName='SiS South Bridge')
  then CurrentChipset:='SiS 620';
 if (NorthName='SiS 630') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 630';
 if (NorthName='SiS 635') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 635';
 if (NorthName='SiS 640') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 640';
 if (NorthName='SiS 645') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 645';
 if (NorthName='SiS 645DX') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 645DX';
 if (NorthName='SiS 648') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 648'; {v1.31}
 if (NorthName='SiS 650') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 650';
 if (NorthName='SiS 651') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 651'; {v1.31}
 if (NorthName='SiS 655') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 655'; {v1.31}
 if (NorthName='SiS 730') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 730';
 if (NorthName='SiS 733') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 733'; {v1.31}
 if (NorthName='SiS 735') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 735';
 if (NorthName='SiS 740') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 740';
 if (NorthName='SiS 745') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 745'; {v1.31}
 if (NorthName='SiS 746') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 746'; {v1.31}
 if (NorthName='SiS 748') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 748'; {v1.31}
 if (NorthName='SiS 755') and ((SouthName='SiS South Bridge') or (SouthName='SiS 950'))
  then CurrentChipset:='SiS 755'; {v1.31}

 if (NorthName='Reliance NB6635') and (SouthName='Reliance OSB4')
  then CurrentChipset:='ServerWorks ServerSet III LE';
 if (NorthName='Reliance NB6536') and (SouthName='Reliance OSB4')
  then CurrentChipset:='ServerWorks ServerSet III HE';

 if (NorthName='Vesuvius V1-LS') and (SouthName='Vesuvius V3-LS')
  then CurrentChipset:='National PicoPower Vesuvius-LS';

 if (NorthName='MediaGX') and (SouthName='Cyrix Cx5510')
  then CurrentChipset:='Cyrix MediaGX + Cx5510'; {v1.36}
 if (NorthName='MediaGX') and (SouthName='Cyrix Cx5520')
  then CurrentChipset:='Cyrix MediaGX + Cx5520'; {v1.36}
 if (NorthName='MediaGX') and (SouthName='Cyrix Cx5530(A)')
  then CurrentChipset:='National Geode GX1 + CS5530(A)';
 if (NorthName='MediaGX') and (SouthName='Geode SC1100')
  then CurrentChipset:='AMD Geode SC1100'; {v1.36}
 if (NorthName='MediaGX') and (SouthName='Geode SCx200')
  then CurrentChipset:='AMD Geode SC1200/2200/3200'; {v1.36}

 if (NorthName='OPTi 82C557(M)') and (SouthName='OPTi 82C558(M)')
  then CurrentChipset:='OPTi Viper M/N/NK/N+/DP';
 if (NorthName='OPTi 82C567') and (SouthName='OPTi 82C568')
  then CurrentChipset:='OPTi Viper Max/Vendetta 82C750';

 if (NorthName='HiNT VXPro-II North') and (SouthName='HiNT VXPro-II South')
  then CurrentChipset:='HiNT VXPro-II (Utron UT85C50x)';

 if (NorthName='UMC UM8881F') and (SouthName='UMC UM8886BF')
  then CurrentChipset:='UMC UM8881F + UM8886BF';

 if (NorthName='Micron MT8LLN21PADF') and (SouthName='Micron MT7LLN22NCNE')
  then CurrentChipset:='Micron Copperhead+Coppertail';

 if (NorthName='CY82C599') then CurrentChipset:='Cypress 386/486 chipset';
 if (NorthName='CY82C691') and (SouthName='CY82C693(U/UB)')
  then CurrentChipset:='Cypress hyperCache';

 if (NorthName='nVidia IGP') and (SouthName='nVidia MCP/MCP-D')
  then CurrentChipset:='nVidia nForce';
 if (NorthName='nVidia IGP2') and (SouthName='nVidia MCP2')
  then CurrentChipset:='nVidia nForce2';

 ChipsetFound := ( NorthName<>'' ) or ( SouthName<>'' ); {One of 'm might be enough}

 {If chipset ID failed then show north & south bridge name or ID}
 If CurrentChipset = '' then
  Begin
   If NorthName<>'' then
    CurrentChipset := NorthName + ' + '
   else
    CurrentChipset := '(' + Hw( NorthMan ) + ',' + Hw( NorthId ) +
                      ',' + Hb( NorthRev ) + ') + ';
   If SouthName<>'' then
    CurrentChipset := CurrentChipset + SouthName
   else
    CurrentChipset := CurrentChipset +
                      '(' + Hw( SouthMan ) + ',' + Hw( SouthId ) +
                      ',' + Hb( SouthRev ) + ')';
  End;
 if LPCName<>'' then CurrentChipset:=CurrentChipset+' + '+LPCName; {v1.27}
 If WantToUseAMI and AMICheckFor then {v1.24}
  Begin
   AMIUsed := True;
   ChipsetFound := True;
   CurrentChipset := CurrentChipset + ' [AMI FLASH]';
   LogWrite('AMI flash interface enabled');
  End;
 If WantToUseAsus and AsusCheckFor then {v1.39}
  Begin
   AsusUsed := True;
   ChipsetFound := True;
   CurrentChipset := CurrentChipset + ' [ASUS FLASH]';
   LogWrite('Asus flash interface enabled');
  End;
end;

procedure GetBIOSID;
var Buf: array[1..80] of Char;
    b,e: Byte;
begin
  MoveLinBlockB($FFFFFFE8,LongInt(Seg(BIOSID)) shl 4+LongInt(Ofs(BIOSID)),8); {v1.34}
  if (BIOSID=#0#0#0#0#0#0#0#0) or (BIOSID=#$FF#$FF#$FF#$FF#$FF#$FF#$FF#$FF) then {v1.39}
   begin
     BIOSID:=#0#0#0#0#0#0#0#0;
     MoveLinBlockB($FEC71,LongInt(Seg(Buf)) shl 4+LongInt(Ofs(Buf)),SizeOf(Buf));
     e:=Pos(#0,Buf)-1;
     b := e;
     while ((Buf[b]<>'-') or (e-b<3)) and (b>1) do Dec(b);
     if e-b>8 then e:=b+8;
     Move(Buf[b+1],BIOSID,e-b);
   end;
  GotoXY(73,23);
  Write(BIOSID); {v1.38}
  LogWrite('Detected Award BIOS ID: '+BIOSID);
end;

Var
PIIXReg, PIIXReg2, PIIXReg3, PIIXReg4, PIIXReg5 : LongInt;

{Generic Intel chipset low ROM enable & ROM write access enable}
Procedure ROMEnable( Map : Boolean );
Var
Mask : LongInt;
Pos_: Byte;

Begin
 if ROMEnabled=Map then Exit; {v1.22}

 if AMIUsed then
  begin
    if Map then AMIEnable else AMIDisable;
    ROMEnabled:=Map;
    Exit;
  end;
 if AsusUsed then
  begin
    if Map then AsusEnable else AsusDisable;
    ROMEnabled:=Map;
    Exit;
  end;

 {Chipset northbridge stuff}
 Case Hi( NorthFunc ) of
  $01 : begin {older VIA chipsets}
         if Map then
          begin
           Port[$A8]:=$11;
           PIIXReg:=Port[$A9];
           LogWrite('VIA old method: internal reg $11 = '+Hl(PIIXReg)); {v1.28}
           Port[$A8]:=$11;
           Port[$A9]:=PIIXReg or $40; {ROM Write enable}
           Port[$A8]:=$11;
           LogWrite('VIA old method: internal reg $11 changed to '+Hl(Port[$A9])); {v1.28}
          end else
          begin
           Port[$A8]:=$11;
           LogWrite('VIA old method: restoring internal reg $11 from '+Hl(Port[$A9])); {v1.28}
           Port[$A8]:=$11;
           Port[$A9]:=PIIXReg;
          end;
        End;
  $02 : Begin {SiS 85C496+497 chipset} {v1.21}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0 );
           LogWrite('SiS old method: reg $D0 = '+Hl(PIIXReg)); {v1.28}
           {write enable, 384K enable}
           SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0, PIIXReg or $F8 );
           LogWrite('SiS old method: reg $D0 changed to '+Hl(GetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0 )));
          End else
          Begin
           LogWrite('SiS old method: restoring reg $D0 from '+Hl(GetPCIRegD( $00, NorthPos shr 3,
            NorthPos and $7, $D0 ))); {v1.28}
           SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0, PIIXReg );
          End;
        End;
  $03 : begin {ALi Aladdin and FinALi}
         if Map then
          begin
            if Lo(NorthFunc)=0 then
             begin {ALi Aladdin M1451/1449} {v1.31}
               ROMBase:=$E0000;
               ShadowDisable:=ShadowDisable_Aladdin;
               ShadowRestore:=ShadowRestore_Aladdin;
               Flash_Read:=FIMemB_Flash_Low;
               Flash_ReadBlock:=MoveLinBlock_From_Flash_D_Low;
               Flash_Compare:=CompLinBlocks_Flash_Low;
               PIIXReg := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $4C );
               LogWrite('ALi old method: reg $4C = '+Hl(PIIXReg));
               {E and F segment write shadow disable}
               SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $4C, PIIXReg and $00FFFFFF );
                LogWrite('ALi old method: reg $4C changed to '+Hl(GetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $4C)));
             end
            else
             begin {ALi FinALi 486 M1489/1487} {v1.28}
               ROMBase:=$FFFF0000;
               Flash_Read:=FIMemB_Flash_FinALi;
               Flash_Write:=FOMemB_Flash_FinALi;
               Flash_ReadBlock:=MoveLinBlock_From_Flash_D_FinALi;
               Flash_WriteBlock:=MoveLinBlock_To_Flash_B_FinALi;
               Flash_Compare:=CompLinBlocks_Flash_FinALi;
               Port[$22]:=$03;
               Port[$23]:=$C5;

               Port[$22]:=$12;
               PIIXReg:=Port[$23];
               LogWrite('ALi old method: internal reg $12 = '+Hl(PIIXReg));
               Port[$22]:=$12;
               Port[$23]:=PIIXReg or $11;
               Port[$22]:=$12;
               LogWrite('ALi old method: internal reg $12 changed to '+Hl(Port[$23]));

               Port[$22]:=$21;
               PIIXReg2:=Port[$23];
               LogWrite('ALi old method: internal reg $21 = '+Hl(PIIXReg2));
               Port[$22]:=$21;
               Port[$23]:=PIIXReg2 or $20;
               Port[$22]:=$21;
               LogWrite('ALi old method: internal reg $21 changed to '+Hl(Port[$23]));

               Port[$22]:=$2B;
               PIIXReg3:=Port[$23];
               LogWrite('ALi old method: internal reg $2B = '+Hl(PIIXReg3));
               Port[$22]:=$2B;
               Port[$23]:=PIIXReg3 or $20;
               Port[$22]:=$2B;
               LogWrite('ALi old method: internal reg $2B changed to '+Hl(Port[$23]));

               Port[$22]:=$03;
               Port[$23]:=$00;
             end;
          end
         else
          begin
            if Lo(NorthFunc)=0 then
             begin {ALi Aladdin M1451/1449} {v1.31}
               LogWrite('ALi old method: restoring reg $4C from '+Hl(GetPCIRegD( $00, NorthPos shr 3,
                NorthPos and $7, $4C )));
               SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $4C, PIIXReg );
             end
            else
             begin
               Port[$22]:=$03;
               Port[$23]:=$C5;

               Port[$22]:=$12;
               LogWrite('ALi old method: restoring internal reg $12 from '+Hl(Port[$23]));
               Port[$22]:=$12;
               Port[$23]:=PIIXReg;

               Port[$22]:=$21;
               LogWrite('ALi old method: restoring internal reg $21 from '+Hl(Port[$23]));
               Port[$22]:=$21;
               Port[$23]:=PIIXReg2;

               Port[$22]:=$2B;
               LogWrite('ALi old method: restoring internal reg $2B from '+Hl(Port[$23]));
               Port[$22]:=$2B;
               Port[$23]:=PIIXReg3;

               Port[$22]:=$03;
               Port[$23]:=$00;
             end;
          end;
        end;
  $04 : Begin {Contaq/Cypress CY82C599} {v1.29}
         If Map then
          Begin
            Port[$22]:=$12;
            PIIXReg:=Port[$23];
            LogWrite('Cypress old method: internal reg $12 = '+Hl(PIIXReg));
            Port[$22]:=$12;
            Port[$23]:=PIIXReg and $EF;
            Port[$22]:=$12;
            LogWrite('Cypress old method: internal reg $12 changed to '+Hl(Port[$23]));
          End else
          Begin
            Port[$22]:=$12;
            LogWrite('Cypress old method: restoring internal reg $12 from '+Hl(Port[$23]));
            Port[$22]:=$12;
            Port[$23]:=PIIXReg;
          End;
        End;
 End;

 {Chipset southbridge stuff}
 Case Hi( SouthFunc ) of
  $01 : Begin {Intel method}
         If Map then
          Begin
           Mask := $00440000;                    {write & 128k enable}
           If ( SouthFunc and 1 ) <> 0 then Mask := Mask or $800000;  {512k enable}
           If ( SouthFunc and 2 ) <> 0 then Mask := Mask or $2000000; {1M enable}
           If ( SouthFunc and 4 ) <> 0 then Mask := $C00000; {v1.29}

           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('Intel method: reg $4C = '+Hl(PIIXReg)); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or Mask );
           LogWrite('Intel method: reg $4C changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C ))); {v1.23}
           PIIXReg4:=0;
           if Lo(SouthFunc)=3 then {v1.29}
            begin
              if (BIOSID='6A69KA19') {Abit BF6, BE6-II v1.0 and v1.1}
               or (BIOSID='6A69KA1B') {Abit BE6-II v1.2}
               or (BIOSID='6A69KA1C') {Abit BE6-II v2.0 and BX133-RAID}
               or (BIOSID='2A69KA1Q') {Abit ZM6}
               or (BIOSID='2A69KA1U') then {Abit BE6}
               begin
                 PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, 4, $40 ); {v1.29}
                 LogWrite('Intel method: PM Base = '+Hl(PIIXReg2));
                 if PIIXReg2=-1 then
                  begin
                    PIIXReg4:=1;
                    SetPCIRegD($00,SouthPos shr 3,3,$40,$6101);
                    SetPCIRegD($00,SouthPos shr 3,3,$80,GetPCIRegD($00,SouthPos shr 3,3,$80) or 1);
                    LogWrite('Intel method: PM Base set to '+Hl(GetPCIRegD($00,SouthPos shr 3,3,$40)));
                    PIIXReg3:=Port[$6134] or LongInt(Port[$6135]) shl 8
                                                             or LongInt(Port[$6136]) shl 16 or LongInt(Port[$6137]) shl 24;
                    LogWrite('Intel method: GPO status '+Hl(PIIXReg3));
                    Port[$6135]:=Port[$6135] and $FD;
                    Port[$6137]:=Port[$6137] and $FB; {Abit BX133-RAID v1.29}
                    LogWrite('Intel method: GPO changed to '+Hl(Port[$6134] or LongInt(Port[$6135]) shl 8
                      or LongInt(Port[$6136]) shl 16 or LongInt(Port[$6137]) shl 24));
                  end;
               end;
             end;
          End else
          Begin
           LogWrite('Intel method: restoring reg $4C from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
           if (BIOSID='6A69KA19') {Abit BF6, BE6-II v1.0 and v1.1}
            or (BIOSID='6A69KA1B') {Abit BE6-II v1.2}
            or (BIOSID='6A69KA1C') {Abit BE6-II v2.0 and BX133-RAID}
            or (BIOSID='2A69KA1Q') {Abit ZM6}
            or (BIOSID='2A69KA1U') then {Abit BE6}
            if PIIXReg4=1 then {v1.29}
             begin
               LogWrite('Intel method: restoring GPO from '+Hl(Port[$6134] or LongInt(Port[$6135]) shl 8
                or LongInt(Port[$6136]) shl 16 or LongInt(Port[$6137]) shl 24));
               Port[$6134]:=PIIXReg3 and $FF;
               Port[$6135]:=PIIXReg3 and $FF00 shr 8;
               Port[$6136]:=PIIXReg3 and $FF0000 shr 16;
               Port[$6137]:=PIIXReg3 and $FF000000 shr 24;
               SetPCIRegD($00,SouthPos shr 3,3,$80,GetPCIRegD($00,SouthPos shr 3,3,$80) and $FFFFFFFE);
               SetPCIRegD($00,SouthPos shr 3,3,$40,PIIXReg2);
             end;
          End;
        End;
  $02 : Begin {Intel 8xx method} {v1.19}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('Intel 8xx method: reg $4C = '+Hl(PIIXReg)); {v1.23}
           {FWH Write Enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or $10000 );
           LogWrite('Intel 8xx method: reg $4C changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0 );
           LogWrite('Intel 8xx method: reg $E0 = '+Hl(PIIXReg2)); {v1.23}
           {FWH Decode at $FF800000-$FFFFFFFF = 8MB enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0, PIIXReg2 or $FF000000 ); {C0 -> FF} {v1.31}
           LogWrite('Intel 8xx method: reg $E0 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $E0 ))); {v1.23}
           if (BIOSID='6A69RM4E') or {MSI MS-6337 v3.x}
            (BIOSID='6A69RM4L') then {MSI MS-6337 v5.x}
            begin
             if GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $5C ) and $10=$10 then
              begin
               PIIXReg3:=GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $58 ) and $7FC0;
               LogWrite('6A69RM4E: GPO at '+Hw(PIIXReg3));
               PIIXReg4:=Port[PIIXReg3+$E];
               LogWrite('6A69RM4E: GPO = '+Hb(PIIXReg4));
               Port[PIIXReg3+$E]:=PIIXReg4 or $80;
               LogWrite('6A69RM4E: GPO changed to '+Hb(Port[PIIXReg3+$E]));
              end;
            end;
          End else
          Begin
           LogWrite('Intel 8xx method: restoring reg $4C from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
           LogWrite('Intel 8xx method: restoring reg $E0 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $E0 ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0, PIIXReg2 );
           if BIOSID='6A69RM4E' then {MSI MS-6337 v3.x}
            begin
             if GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $5C ) and $10=$10 then
              begin
               LogWrite('6A69RM4E: restoring GPO from '+Hb(Port[PIIXReg3+$E]));
               Port[PIIXReg3+$E]:=PIIXReg4;
              end;
            end;
          End;
        End;
  $03 : Begin {VIA method} {AMD method is the same v1.20}
         If Lo(SouthFunc)=$10 then {VT8233/8235 method v1.27}
          begin
            if Map then
             begin
               PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
               LogWrite('VT8233 method: reg $40 = '+Hl(PIIXReg)); {v1.23}
               {write enable, 4MB enable}
               SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or $7F10 );
               LogWrite('VT8233 method: reg $40 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                SouthPos and $7, $40 ))); {v1.23}
               if (DMI_Board_String='MSI MS-6380 2.0')
                or (DMI_Board_String='MSI MS-6380E 1.0') then
                begin
                  Port[$84D]:=Port[$84D] or $10;
                end;
               if (BIOSID='A7V266'#0#0) then {Asus A7V266} {v1.39}
                begin
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
                  Port[$370]:=Port[$370] or $02;
                end;
               if (BIOSID='A7V8X-X'#0) then {Asus A7V8X-X} {v1.39}
                begin
                  LogWrite('A7V8X-X: enabling write access');
                  Port[$372]:=Port[$372] or $04; {GP32 pin of Super I/O}
                end;
             end
            else
             begin
               LogWrite('VT8233 method: restoring reg $40 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                SouthPos and $7, $40 ))); {v1.23}
               SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
               if (DMI_Board_String='MSI MS-6380 2.0')
                or (DMI_Board_String='MSI MS-6380E 1.0') then
                begin
                  Port[$84D]:=Port[$84D] and $EF;
                end;
               if (BIOSID='A7V266'#0#0) then {Asus A7V266} {v1.39}
                begin
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
                  Port[$370]:=Port[$370] and $FD;
                end;
               if (BIOSID='A7V8X-X'#0) then {Asus A7V8X-X} {v1.39}
                begin
                  LogWrite('A7V8X-X: disabling write access');
                  Port[$372]:=Port[$372] and $FB;
                end;
             end;
          end
         else
          begin
            If Map then
             Begin
              Mask := $C0000001;  {write enable, 512K enable}
              If ( SouthFunc and 1 ) <> 0 then Mask := Mask or $20000000; {1M enable} {v1.22}

              PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
              LogWrite('VIA/AMD method: reg $40 = '+Hl(PIIXReg)); {v1.23}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or Mask );
              LogWrite('VIA/AMD method: reg $40 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
               SouthPos and $7, $40 ))); {v1.23}

              if (BIOSID='6A6S6A1A') {Abit KG7}
               or (BIOSID='6A6LMA19') {Abit KT7}
               or (BIOSID='6A6LMA1A') then {Abit KT7A v1.3}
               begin
                if GetPCIRegD( $00, SouthPos shr 3, 4, $40 ) and $8000=$8000 then
                 begin
                  PIIXReg2:=GetPCIRegD( $00, SouthPos shr 3, 4, $48 ) and $FFFE;
                  LogWrite('6A6S6A1A: GPO at '+Hw(PIIXReg2));
                  PIIXReg3:=IPortD(PIIXReg2+$4C);
                  LogWrite('6A6S6A1A: GPO = '+Hl(PIIXReg3));
                  OPortD(PIIXReg2+$4C,PIIXReg3 or $10);
                  LogWrite('6A6S6A1A: GPO changed to '+Hl(IPortD(PIIXReg2+$4C)));
                 end;
               end;
             End else
             Begin
              LogWrite('VIA/AMD method: restoring reg $40 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
               SouthPos and $7, $40 ))); {v1.23}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );

              if BIOSID='6A6S6A1A' then {Abit KG7}
               begin
                if GetPCIRegD( $00, SouthPos shr 3, 4, $40 ) and $8000=$8000 then
                 begin
                  LogWrite('6A6S6A1A: restoring GPO from '+Hl(IPortD(PIIXReg2+$4C)));
                  OPortD(PIIXReg2+$4C,PIIXReg3);
                 end;
               end;
             End;
          end;
        End;
  $04 : Begin {ALi method} {v1.18}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('ALi method: reg $44 = '+Hl(PIIXReg)); {v1.23}
           {write enable, 256K enable} {43->47 v1.24}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or $47000000 );
           LogWrite('ALi method: reg $44 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 ))); {v1.23}

           PIIXReg4 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           LogWrite('ALi method: reg $40 = '+Hl(PIIXReg4));
           {PCI-ISA Posted Write Disable} {v1.26}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg4 and $FFFFFFFB );
           LogWrite('ALi method: reg $40 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 )));
           If (SouthFunc and 1)<>0 then {v1.26}
            begin
              {M1543C rev. B1 - supports 512K ROM}
              PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78 ); {v1.19}
              LogWrite('ALi method: reg $78 = '+Hl(PIIXReg2)); {v1.23}
              {512K enable} {v1.19} {v1.24 fixed}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg2 or $1000 ); {v1.19}
              LogWrite('ALi method: reg $78 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78 )));
              {M1535 - supports 512K ROM} {v1.24}
              PIIXReg3 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C );
              LogWrite('ALi method: reg $7C = '+Hl(PIIXReg3));
              {512K enable}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C, PIIXReg3 or $1000000 );
              LogWrite('ALi method: reg $7C changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C )));
              {256KB support through GPO for M1533/M1543}
              PIIXReg4:=GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $54 ); {v1.34}
              LogWrite('ALi method: reg $54 = '+Hl(PIIXReg4));
              if PIIXReg4 and $10=$10 then
               begin
                LogWrite('ALi method: using GPO to control A17');
                {Locate PMU}
                for Pos_:=0 to $FF do
                 if GetPCIRegD($00,Pos_ shr 3,Pos_ and $07,$00) and $FFFF<>$FFFF then
                  if GetPCIRegD($00,Pos_ shr 3,
                                   Pos_ and $07,$00)=$710110B9 then Break;
                if Pos_=$FF then PMUPos:=SouthPos else PMUPos:=Pos_;
                PIIXReg5:=GetPCIRegD($00,PMUPos shr 3,PMUPos and $7,$C0);
                LogWrite('ALi method: PMU reg $C0 = '+Hl(PIIXReg5));
                Flash_Read:=FIMemB_Flash_ALiGPO;
                Flash_Write:=FOMemB_Flash_ALiGPO;
                Flash_ReadBlock:=MoveLinBlock_From_Flash_D_ALiGPO;
                Flash_WriteBlock:=MoveLinBlock_To_Flash_B_ALiGPO;
                Flash_Compare:=CompLinBlocks_Flash_ALiGPO;
               end;
            end;
          End else
          Begin
           LogWrite('ALi method: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
           LogWrite('ALi method: restoring reg $40 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $40 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg4 );
           If (SouthFunc and 1)<>0 then {v1.26}
            begin
              LogWrite('ALi method: restoring reg $78 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
               SouthPos and $7, $78 ))); {v1.23}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg2 ); {v1.19}
              LogWrite('ALi method: restoring reg $7C from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
               SouthPos and $7, $7C ))); {v1.24}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C, PIIXReg3 ); {v1.24}
              if PIIXReg4 and $10=$10 then {v1.34}
               begin
                LogWrite('ALi method: restoring PMU reg $C0 from '+Hl(GetPCIRegD($00,PMUPos shr 3,
                 PMUPos and $7,$C0)));
                SetPCIRegD($00,PMUPos shr 3,PMUPos and $7,$C0,PIIXReg5);
               end;
            end;
          End;
        End;
  $05 : Begin {SiS methods} {v1.21}
         if Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           LogWrite('SiS method: reg $40 = '+Hl(PIIXReg)); {v1.23}
           {Lower & extended BIOS enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg and $FFFFFFFB or $B{or $3} );
           LogWrite('SiS method: reg $40 changed to '+Hl(GetPCIRegD($00,SouthPos shr 3,SouthPos and $7,$40))); {v1.23}
           case Lo(SouthFunc) of
            $01: Begin {internal reg. 80h}
                   Port[ $22 ] := $80;
                   PIIXReg2 := Port[ $23 ];
                   LogWrite('SiS method 1: internal reg $80 = '+Hl(PIIXReg2)); {v1.23}
                   Port[ $22 ] := $80;
                   Port[ $23 ] := PIIXReg2 and $DF or $4; {Enable Flash ROM write}
                   Port[ $22 ] := $80;
                   LogWrite('SiS method 1: internal reg $80 changed to '+Hl(Port[$23])); {v1.23}
                   {v1.23 registers can be also at $70}
                   Port[ $22 ] := $70;
                   PIIXReg3 := Port[ $23 ];
                   LogWrite('SiS method 1: internal reg $70 = '+Hl(PIIXReg3)); {v1.23}
                   Port[ $22 ] := $70;
                   Port[ $23 ] := PIIXReg3 and $DF or $4; {Enable Flash ROM write}
                   Port[ $22 ] := $70;
                   LogWrite('SiS method 1: internal reg $70 changed to '+Hl(Port[$23])); {v1.23}
                 End;
            $02: Begin {internal reg. 50h}
                   Port[ $22 ] := $50;
                   PIIXReg2 := Port[ $23 ];
                   LogWrite('SiS method 2: internal reg $50 = '+Hl(PIIXReg2)); {v1.23}
                   Port[ $22 ] := $50;
                   Port[ $23 ] := PIIXReg2 and $DF or $4; {Enable Flash ROM write}
                   Port[ $22 ] := $50;
                   LogWrite('SiS method 2: internal reg $50 changed to '+Hl(Port[$23])); {v1.23}
                 End;
            $03: Begin {PCI reg. 45h bits 5,2}
                   PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
                   LogWrite('SiS method 3: reg $44 = '+Hl(PIIXReg2)); {v1.23}
                   SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg2 and $FFFFDFFF or $400 );
                   LogWrite('SiS method 3: reg $44 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                    SouthPos and $7, $44 ))); {v1.23}
                 End;
            $04: Begin {PCI reg. 45h bits 7,6}
                   PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
                   LogWrite('SiS method 4: reg $44 = '+Hl(PIIXReg2)); {v1.23}
                   SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg2 and $FFFF7FFF or $4000 );
                   LogWrite('SiS method 4: reg $44 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                    SouthPos and $7, $44 ))); {v1.23}
                 End;
           End;
          End else
          Begin
           LogWrite('SiS method: restoring reg $40 from '+Hl(GetPCIRegD($00,SouthPos shr 3,SouthPos and $7,$40))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
           case Lo(SouthFunc) of
            $01: Begin {internal reg. 80h}
                   Port[ $22 ] := $80;
                   LogWrite('SiS method 1: restoring internal reg $80 from '+Hl(Port[$23])); {v1.23}
                   Port[ $22 ] := $80;
                   Port[ $23 ] := PIIXReg2;
                   {v1.23 registers can be also at $70}
                   Port[ $22 ] := $70;
                   LogWrite('SiS method 1: restoring internal reg $70 from '+Hl(Port[$23])); {v1.23}
                   Port[ $22 ] := $70;
                   Port[ $23 ] := PIIXReg3;
                 End;
            $02: Begin {internal reg. 50h}
                   Port[ $22 ] := $50;
                   LogWrite('SiS method 2: restoring internal reg $50 from '+Hl(Port[$23])); {v1.23}
                   Port[ $22 ] := $50;
                   Port[ $23 ] := PIIXReg2;
                 End;
            $03,$04: Begin {PCI reg. 45h}
                      LogWrite('SiS method 3/4: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                       SouthPos and $7, $44 ))); {v1.23}
                      SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg2 );
                     End;
           End;
          End;
        End;
  $06 : Begin {SMSC method} {v1.21}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('SMSC method: reg $4C = '+Hl(PIIXReg)); {v1.23}
           {write & 1M enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or $02C40000 );
           LogWrite('SMSC method: reg $4C changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C ))); {v1.23}
          End else
          Begin
           LogWrite('SMSC method: restoring reg $4C from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
          End;
        End;
  $07 : Begin {Winbond method} {v1.21}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('Winbond method: reg $4C = '+Hl(PIIXReg)); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg and $DF00 or $D000 );
           LogWrite('Winbond method: reg $4C changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
          End else
          Begin
           LogWrite('Winbond method: restoring reg $4C from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
          End;
        End;
  $08 : Begin {ITE methods} {v1.21}
         If Map then
          Begin
           case Lo(SouthFunc) of
            $01: Begin
                  PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
                  LogWrite('ITE method 1: reg $44 = '+Hl(PIIXReg)); {v1.23}
                  {write enable}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg and $FFFF7FFF );
                  LogWrite('ITE method 1: reg $44 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $44 ))); {v1.23}
                 End;
            $02: Begin
                  PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50 );
                  LogWrite('ITE method 2: reg $50 = '+Hl(PIIXReg)); {v1.23}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg or $E0000000 and $FEFFFFFF );
                  LogWrite('ITE method 2: reg $50 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $50 ))); {v1.23}
                 End;
           End;
          End else
          Begin
           case Lo(SouthFunc) of
            $01: Begin
                  LogWrite('ITE method 1: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $44 ))); {v1.23}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
                 End;
            $02: Begin
                  LogWrite('ITE method 2: restoring reg $50 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $50 ))); {v1.23}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg );
                 End;
           End;
          End;
        End;
  $09 : Begin {Reliance method} {v1.24}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           LogWrite('Reliance method: reg $40 = '+Hl(PIIXReg));
           {512K enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or $00000200 );
           LogWrite('Reliance method: reg $40 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 )));

           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70 );
           LogWrite('Reliance method: reg $70 = '+Hl(PIIXReg2));
           {4MB enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70, PIIXReg2 or $00000080 );
           LogWrite('Reliance method: reg $70 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70 )));

           LogWrite('Reliance method: internal reg $C6F = '+Hl(Port[$C6F]));
           Port[$C6F]:=Port[$C6F] or $40; {Flash write enable}
           LogWrite('Reliance method: internal reg $C6F changed to '+Hl(Port[$C6F]));
          End else
          Begin
           LogWrite('Reliance method: restoring reg $40 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $40 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
           LogWrite('Reliance method: restoring reg $70 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $70 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70, PIIXReg2 );
           LogWrite('Reliance method: restoring internal reg $C6F from '+Hl(Port[$C6F]));
           Port[$C6F]:=Port[$C6F] and $BF; {Flash write disable}
          End;
        End;
  $10 : Begin {PicoPower method} {v1.25}
         If Map then
          Begin
           Port[$24]:=$03;
           PIIXReg:=Port[$26];
           LogWrite('PicoPower method: internal reg $03 = '+Hl(PIIXReg));
           Port[$24]:=$03;
           Port[$26]:=PIIXReg or $40; {Flash enable}
           Port[$24]:=$03;
           LogWrite('PicoPower method: internal reg $03 changed to '+Hl(Port[$26]));
          End else
          Begin
           Port[$24]:=$03;
           LogWrite('PicoPower method: restoring internal reg $03 from '+Hl(Port[$26]));
           Port[$24]:=$03;
           Port[$26]:=PIIXReg;
          End;
        End;
  $11 : Begin {Cyrix method} {v1.25}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50 );
           LogWrite('Cyrix method: reg $50 = '+Hl(PIIXReg));
           {16MB enable, write enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg or $00060000 );
           LogWrite('Cyrix method: reg $50 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50 )));
          End else
          Begin
           LogWrite('Cyrix method: restoring reg $50 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $50 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg );
          End;
        End;
  $12 : Begin {OPTi method} {v1.26}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('OPTi method: reg $44 = '+Hl(PIIXReg));
           {write enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or $80000000 );
           LogWrite('OPTi method: reg $44 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 )));

           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48 );
           LogWrite('OPTi method: reg $48 = '+Hl(PIIXReg2));
           {256k enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48, PIIXReg2 and $FFFFFF or $3F000000 ); {v1.37}
           LogWrite('OPTi method: reg $48 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48 )));
          End else
          Begin
           LogWrite('OPTi method: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
           LogWrite('OPTi method: restoring reg $48 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $48 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48, PIIXReg2 );
          End;
        End;
  $13 : Begin {Utron method} {v1.26}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60 );
           LogWrite('Utron method: reg $60 = '+Hl(PIIXReg));
           {write & 128k enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60, PIIXReg and $FFFFEFFF or $2{or $802} ); {v1.28}
           LogWrite('Utron method: reg $60 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60 )));
          End else
          Begin
           LogWrite('Utron method: restoring reg $60 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $60 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60, PIIXReg );
          End;
        End;
  $14 : Begin {UMC method} {v1.28}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('UMC method: reg $44 = '+Hl(PIIXReg));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg and $BFFFFFFF);
          End else
          Begin
           LogWrite('UMC method: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
          End;
        End;
  $15 : Begin {Contaq/Cypress method} {v1.29}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('Cypress method: reg $44 = '+Hl(PIIXReg));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or $E0000000);
          End else
          Begin
           LogWrite('Cypress method: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
          End;
        End;
  $16 : Begin {nForce method} {v1.30}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('nForce method: reg $44 = '+Hl(PIIXReg));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or $100);
           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70 );
           LogWrite('nForce method: reg $70 = '+Hl(PIIXReg2));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70, PIIXReg2 and $FFE0FFFF or $C0);
           PIIXReg3 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $74 );
           LogWrite('nForce method: reg $74 = '+Hl(PIIXReg3));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $74, 0);
           PIIXReg4 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78 );
           LogWrite('nForce method: reg $78 = '+Hl(PIIXReg4));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, 0);
           PIIXReg5 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C );
           LogWrite('nForce method: reg $7C = '+Hl(PIIXReg5));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C, 0);
          End else
          Begin
           LogWrite('nForce method: restoring reg $44 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
           LogWrite('nForce method: restoring reg $70 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $70 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70, PIIXReg2 );
           LogWrite('nForce method: restoring reg $74 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $74 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $74, PIIXReg3 );
           LogWrite('nForce method: restoring reg $78 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $78 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg4 );
           LogWrite('nForce method: restoring reg $7C from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $7C )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C, PIIXReg5 );
          End;
        End;
  $17 : Begin {Intel 9xx (ICH6) method} {v1.37}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $DC );
           LogWrite('Intel 9xx method: reg $DC = '+Hl(PIIXReg));
           {FWH Write Enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $DC, PIIXReg or $1 );
           LogWrite('Intel 9xx method: reg $DC changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $DC )));
           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $D8 );
           LogWrite('Intel 9xx method: reg $D8 = '+Hl(PIIXReg2));
           {FWH Decode at $FF000000-$FFFFFFFF = 16MB enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $D8, PIIXReg2 or $FF0F );
           LogWrite('Intel 9xx method: reg $D8 changed to '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $D8 )));
          End else
          Begin
           LogWrite('Intel 9xx method: restoring reg $DC from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $DC )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $DC, PIIXReg );
           LogWrite('Intel 9xx method: restoring reg $D8 from '+Hl(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $D8 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $D8, PIIXReg2 );
          End;
        End;
 End;

 case Hi(LPCFunc) of {v1.27}
   $01: begin
          if Map then
           begin
             LPCUnlock;
             PIIXReg:=LPCRead($24);
             LogWrite('ITE LPC method: reg $24 = '+Hl(PIIXReg));
             {512K enable, write enable}
             LPCWrite($24,PIIXReg or $7C);
             LogWrite('ITE LPC method: reg $24 changed to '+Hl(LPCRead($24)));
             LPCLock_ITE;
           end else
           begin
             LPCUnlock;
             LogWrite('ITE LPC method: restoring reg $24 from '+Hl(LPCRead($24)));
             LPCWrite($24,PIIXReg);
             LPCLock_ITE;
           end;
        end;
   $02: begin {v1.33}
          if Map then
           begin
             LPCUnlock;
             PIIXReg:=LPCRead($24);
             LogWrite('Winbond LPC method: reg $24 = '+Hl(PIIXReg));
             {512K enable, write enable}
             LPCWrite($24,PIIXReg and $C7 or $28);
             LogWrite('Winbond LPC method: reg $24 changed to '+Hl(LPCRead($24)));
             LPCLock_WB;
           end else
           begin
             LPCUnlock;
             LogWrite('Winbond LPC method: restoring reg $24 from '+Hl(LPCRead($24)));
             LPCWrite($24,PIIXReg);
             LPCLock_WB;
           end;
        end;
 end;
 ROMEnabled:=Map; {v1.22}
End;

procedure ShadowDisable_Aladdin; {v1.31}
begin
  SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $4C, PIIXReg and $00FF00FF );
end;

procedure ShadowRestore_Aladdin; {v1.31}
begin
  SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $4C, PIIXReg and $00FFFFFF );
end;

begin
 AMIUsed:=False;
 WantToUseAMI:=False;
 AsusUsed:=False;
 WantToUseAsus:=False;
 ChipsetFound:=False;
 ROMEnabled:=False; {v1.22}
 {v1.22 Initialization moved to UNIFLASH.PAS}
end.