{$R-}
unit PCI;  { Unit to communicate with chipsets }

interface

uses AMIBIOS;

Const
PCICfIdx    = $CF8;
PCICfData   = $CFC;

Map         = True;
Unmap       = False;



Var
NorthFunc,
SouthFunc      : Word;
NorthPos,
SouthPos       : Byte;
CurrentChipset : string;
WantToUseAMI,
AMIUsed,
ChipsetFound,
ROMEnabled     : Boolean; {v1.22}

Procedure OPortD( Prt : Word; Val : LongInt );
Function IPortD( Prt : Word ) : LongInt;
Function GetPCIRegD( Bus, Dev, Func, Reg : Byte ) : LongInt;
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Function LocatePIIX : {byte}Boolean; {v1.22 byte->boolean}
Procedure RomEnable( Map : boolean);

implementation

Uses Tools;

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

Function LocatePIIX : Boolean{byte}; {v1.22 byte->boolean}
Const
NbName    : ARRAY[ 1 .. $48 ] of String[ 24 ] = {16->24 v1.21}
{1}         ( 'i82433LX',
{2}           'i82433NX',
{3}           'i82437FX',
{4}           'i82437MX',
{5}           'i82441FX',
{6}           'i82439HX',
{7}           'i82437VX',
{8}           'i82439TX',
{9}           'i82443LX/EX', {EX v1.18}
{A}           'i82443BX/ZX', {v1.18}
{B}           'i82443GX', {v1.18}
{C}           'i82454KX',
{D}           'i82454KX/GX',
{E}           'i82454GX',
{F}           'i82810', {v1.19}
{10}          'i82810E', {v1.19}
{11}          'i82815', {v1.19}
{12}          'i82820', {v1.19}
{13}          'i82840', {v1.19}
{14}          'i82850', {v1.19}
{15}          'i82860', {v1.22}
{16}          'i82830MP', {v1.23}
{17}          'i82845', {v1.23}
{18}          'iE7500', {v1.26}
{19}          'VT82C576M',
{1A}          'VT82C585VP/VPX',
{1B}          'VT82C595/AMD-640',
{1C}          'VT82C597',
{1D}          'VT82C598[AT]',
{1E}          'VT82C685',
{1F}          'VT8501', {v1.20}
{20}          'VT82C691/693(A)/694X', {v1.20}
{21}          'VT82C693(A)', {v1.20}
{22}          'VT8601', {v1.20}
{23}          'VT8605', {v1.20}
{24}          'VT8371', {v1.20}
{25}          'VT8363(A)', {v1.20}
{26}          'VT8366', {v1.20}
{27}          'VT8633', {v1.20}
{28}          'VT8653', {v1.20} {???}
{29}          'VT8662', {v1.20} {???}
{2A}          'VT8615', {v1.20} {???}
{2B}          'VT8361', {v1.20} {???}
{2C}          'VT3133', {v1.20} {???}
{2D}          'M1489 not supported', {v1.26}
{2E}          'M1521', {v1.26}
{2F}          'M1531(B)', {v1.26}
{30}          'M1541/1542', {v1.22}
{31}          'M1621', {v1.18}
{32}          'M1641', {v1.24}
{33}          'M1647', {v1.24}
{34}          'AMD-751', {v1.20}
{35}          'AMD-761', {v1.20}
{36}          'AMD-762', {v1.20}
{37}          'SiS 85C496+497', {v1.21}
{38}          'SiS 501/5101/5501', {v1.21}
{39}          'SiS 5511', {v1.21}
{3A}          'SiS 5571', {v1.21}
{3B}          'SiS 5591/5592', {v1.21}
{3C}          'SiS 5596', {v1.21}
{3D}          'SiS 5597/5598/5581/5120', {v1.21}
{3E}          'SiS 530', {v1.21}
{3F}          'SiS 540', {v1.21}
{40}          'SiS 600', {v1.21}
{41}          'SiS 620', {v1.21}
{42}          'SiS 630', {v1.21}
{43}          'Reliance NB6635', {v1.25}
{44}          'Reliance NB6536', {v1.25}
{45}          'Vesuvius V1-LS', {v1.25}
{46}          'Geode GX1', {v1.25}
{47}          'OPTi 82C750', {v1.26}
{48}          'HiNT VXPro-II North'); {v1.26}

SbName    : ARRAY[ 1 .. $21 ] of String[ 21 ] =
{1}         ( 'i82378ZB SIO',
{2}           'i82379AB SIO.A',
{3}           'i82371FB PIIX',
{4}           'i82371MX MPIIX',
{5}           'i82371SB PIIX3',
{6}           'i82371AB/EB PIIX4(E)', {EB v1.19}
{7}           'i82801AA ICH', {v1.19}
{8}           'i82801AB ICH0', {v1.19}
{9}           'i82801BA ICH2', {v1.19}
{A}           'i82801BAM ICH2-M', {v1.19}
{B}           'i82801CAM ICH3-M', {v1.23}
{C}           'i82801CA ICH3-S', {v1.26}
{D}           'VT82C586(A|B)/AMD-645',
{E}           'VT82C596(A|B)',
{F}           'VT82C686(A)', {v1.20}
{10}          'VT8231', {v1.20}
{11}          'VT8233', {v1.20}
{12}          'M1523(B)', {v1.26}
{13}          'M1533/1543/1535', {v1.18}
{14}          'AMD-756', {v1.20}
{15}          'AMD-766', {v1.20}
{16}          'AMD-768', {v1.26}
{17}          'SiS South Bridge', {v1.21}
{18}          'SiS 950', {v1.21}
{19}          'SMSC SLC90E66', {v1.21}
{1A}          'Winbond W83C553F', {v1.21}
{1B}          'ITE IT8871F/2F', {v1.21}
{1C}          'ITE IT8888F', {v1.21}
{1D}          'Reliance OSB4', {v1.24}
{1E}          'Vesuvius V3-LS', {v1.25}
{1F}          'Geode CS5530(A)', {v1.25}
{20}          'OPTi 82C750', {v1.26}
{21}          'HiNT VXPro-II South'); {v1.26}

Var
SbId,
NbId,
Pos,
NorthRev,
SouthRev  : Byte;
SouthMan,
SouthId,
NorthMan,
NorthId   : Word;
NorthName,
SouthName : String;

Begin
 if Port[$CFB]<>$FF then {Check for PCI configuration mechanism type} {v1.26}
  begin
    Port[$CFB]:=Port[$CFB] or $1;
  end;
 { Locate north bridge. (NOTE: Just to catch the theoretical case where    }
 { the north bridge is NOT at bus 0, dev 0, func 0 - which should normally }
 { not be the case, but you never know and it doesn't hurt as this thing   }
 { tests bus 0, dev 0, func 0 first and immediately exits if found.)       }
 For Pos := 0 to $FF do
  If ( GetPCIRegD( $00, Pos shr 3, Pos and $07, $00 ) and $FFFF ) <> $FFFF then
   If ( GetPCIRegD( $00, Pos shr 3,
                    Pos and $07, $08 ) shr 8 ) = $60000 then Break;
 If Pos = $FF then {v1.22}
  Begin
   LocatePIIX := False;
   Exit;
  End
 else LocatePIIX:=True;
 NorthPos := Pos;
 {Get north bridge MID & DID}
 NorthMan := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $07, $00 );
 NorthId  := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $07, $00 ) shr 16;
 {Get north bridge rev ID}
 NorthRev := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $07, $08 );

 {Locate south bridge}
 For Pos := 0 to $FF do
  If ( GetPCIRegD( $00, Pos shr 3, Pos and $07, $00 ) and $FFFF ) <> $FFFF then
   If ( GetPCIRegD( $00, Pos shr 3,
                    Pos and $07, $08 ) shr 8 ) = $60100 then Break;
 If Pos = $FF then {v1.22 for i430MX}
  Begin
   For Pos := 0 to $FF do
    If ( GetPCIRegD( $00, Pos shr 3, Pos and $07, $00 ) and $FFFF ) <> $FFFF then
     If ( GetPCIRegD( $00, Pos shr 3,
                      Pos and $07, $08 ) shr 8 ) = $68000 then Break;
  End;
 SouthPos := Pos;
 {Get south bridge MID & DID}
 SouthMan := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $00 );
 SouthID := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $00 ) shr 16;
 {Get south bridge rev ID}
 SouthRev := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $08 );

 CurrentChipset := '';

 NorthFunc := 0; {No special treatment necessary}
 SouthFunc := 0; {Same}

 {Id northbridge}
 NbId := 0;  {not recognised yet}
 If NorthMan = $8086 {Intel} then
  Begin
   case NorthId of {case v1.21}
     $4A3: Case NorthRev of
            $00, $01, $02, $03 : NbId := $01;  {82433LX} { $00,$02 v1.18}
            $10, $11 : NbId := $02;  {82433NX}
           End;
    $122D: NbId := $03; {82437FX}
    $1235: NbId := $04; {82437MX}
    $1237: NbId := $05; {82441FX}
    $1250: NbId := $06; {82439HX}
    $7030: NbId := $07; {82437VX}
    $7100: NbId := $08; {82439TX}
    $7180: NbId := $09; {82443LX/EX} {EX v1.18}
    $7190, $7192: NbId := $0A; {82443BX/ZX} {v1.18}
    $71A0, $71A2: NbId := $0B; {82443GX} {v1.18}
    $84C4: Case NorthRev of
            $02      : NbId := $0C; {82454KX}
            $04      : NbId := $0D; {82454KX/GX, not sure}
            $05, $06 : NbId := $0E; {82454GX}
           End;
    $7120, $7122: NbId := $0F; {82810} {v1.19}
    $7124: NbId := $10; {82810E} {v1.19}
    $1130: NbId := $11; {82815} {v1.19}
    $2500: NbId := $12; {82820} {v1.19}
    $1A21: NbId := $13; {82840} {v1.19}
    $2530: NbId := $14; {82850} {v1.19}
    $2531: NbId := $15; {82860} {v1.22}
    $3575: NbId := $16; {82830MP} {v1.23}
    $1A30: NbId := $17; {82845} {v1.23}
    $2540: NbId := $18; {E7500} {v1.26}
   End;
  End else
 If NorthMan = $1106 {VIA} then
  Begin
   case NorthId of {case v1.21}
     $576: Begin
            NorthFunc := $0100; {VIA A8/A9 scheme}
            NbId := $19 {82C576M}
           End;
     $585: NbId := $1A; {82C585VP/VPX}
     $595: NbId := $1B; {82C595}
     $597: NbId := $1C; {82C597}
     $598: NbId := $1D; {82C598(AT)}
     $685: Begin
            NorthFunc := $0100; {VIA A8/A9 scheme}
            NbId := $1E; {82C685}
           End;
     $501: NbId := $1F; {8501}
     $691: NbId := $20; {82C691/693(A)/694X}
     $693: NbId := $21; {82C693(A)}
     $601: NbId := $22; {82C601}
     $605: NbId := $23; {8605}
     $391: NbId := $24; {82371}
     $305: NbId := $25; {8363(A)}
    $3099: NbId := $26; {8366}
    $3091: NbId := $27; {8633}
    $3101: NbId := $28; {8653}
    $3102: NbId := $29; {8662}
    $3103: NbId := $2A; {8615}
    $3112: NbId := $2B; {8361}
    $3133: NbId := $2C; {3133}
   End;
  End else
 If NorthMan = $1022 {AMD} then {v1.20}
  Begin
   case NorthId of {case v1.21}
    $7006: NbId := $34; {AMD-751}
    $700E: NbId := $35; {AMD-761}
    $700C: NbId := $36; {AMD-762}
   End;
  End else
 If NorthMan = $1039 {SiS} then
  Begin
   SouthFunc:=$0503; {SiS reg. 45 bits 5,2}
   case NorthId of
     $496: Begin {85C496+497} {v1.21}
            NorthFunc := $0200; {SiS reg. D0 scheme}
            SouthFunc := 0;
            NbId := $37;
           End;
     $406: Begin {501/5101/5501} {v1.21}
            SouthFunc := $0501; {SiS internal reg. 80h}
            NbId := $38;
           End;
    $5511: Begin {5511} {v1.21}
            SouthFunc := $0502; {SiS internal reg. 50h}
            NbId := $39;
           End;
    $5571: NbId := $3A; {5571} {v1.21}
    $5591: NbId := $3B; {5591/5592} {v1.21}
    $5596: Begin {5596} {v1.21}
            SouthFunc := $0502; {SiS internal reg. 50h}
            NbId := $3C;
           End;
    $5597: NbId := $3D; {5597/5598/5581/5120} {v1.21}
    $0530: NbId := $3E; {530} {v1.21}
    $0540: Begin {540} {v1.21}
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            NbId := $3F;
           End;
    $5600: NbId := $40; {600} {v1.21}
    $0620: NbId := $41; {620} {v1.21}
    $0630: Begin {630} {v1.21}
            SouthFunc := $0504; {SiS reg. 45 bits 7,6}
            NbId := $42;
           End;
   End;
  End else
 If NorthMan = $10B9 {ALi} then
  Begin
   case NorthId of
    $1489: NbId := $2D; {M1489 cannot be supported} {v1.26}
    $1521: NbId := $2E; {M1521} {v1.26}
    $1531: NbId := $2F; {M1531} {v1.26}
    $1541: NbId := $30; {M1541} {v1.22}
    $1621: NbId := $31; {M1621} {v1.19}
    $1641: NbId := $32; {M1641} {v1.24}
    $1647: NbId := $33; {M1647} {v1.24}
   End;
  End else
 If NorthMan = $1166 {Reliance/ServerWorks} then {v1.25}
  Begin
   case NorthId of
    $0007: NbId := $43; {NB6635}
    $0008: NbId := $44; {NB6536}
   End;
  End else
 If NorthMan = $1066 {PicoPower} then {v1.25}
  Begin
   case NorthId of
    $0001: NbId := $45; {Vesuvius V1-LS}
   End;
  End else
 If NorthMan = $1078 {Cyrix} then {v1.25}
  Begin
   case NorthId of
    $0001: NbId := $46; {Geode GX1/Cyrix MediaGX}
   End;
  End else
 If NorthMan = $1045 {OPTi} then {v1.26}
  Begin
   case NorthId of
    $C567: NbId := $47; {OPTi 82C750}
   end;
  End else
 If NorthMan = $3388 {HiNT} then {v1.26}
  Begin
   case NorthId of
    $8011: NbId := $48; {HiNT VXPro-II}
   end;
  End;

 {Id southbridge}
 SbId := 0;  {not recognised yet}
 If SouthMan = $8086 {Intel} then
  Begin
   if Hi(SouthId)=$24 then SouthFunc := $0200 else SouthFunc := $0100; {v1.21}
   case SouthId of {case v1.21}
     $484: (*SbId := $02; {82379AB SIO.A}*)
           Case SouthRev of {v1.26}
            $03 : SbId := $01;  {82378ZB SIO}
            $88 : NbId := $02;  {82379AB SIO.A}
           End;
    $122E: Begin
            SbId := $03; {82371FB PIIX}
            Inc( SouthFunc ); {v1.23}
           End;
    $1234: SbId := $04; {82371MX MPIIX}
    $7000: Begin
            SbId := $05 {82371SB PIIX3};
            Inc( SouthFunc );
           End;
    $7110: Begin
            SbId := $06; {82371AB PIIX4}
            Inc( SouthFunc, 3 );
           End;
    $2410: SbId := $07; {i82801AA ICH}
    $2420: SbId := $08; {i82801AB ICH0}
    $2440: SbId := $09; {i82801BA ICH2}
    $244C: SbId := $0A; {i82801BAM ICH2-M}
    $248C: SbId := $0B; {i82801CAM ICH3-M}
    $2480: SbId := $0C; {i82801CA ICH3-S}
   End;
  End else
 If SouthMan = $1106 {VIA} then
  Begin
   SouthFunc := $0300; {VIA/AMD method}
   case SouthId of {case v1.21}
     $586: SbId := $0D;
     $596: Begin SbId := $0E; Inc( SouthFunc ); End; {VT82C596(A|B)}
     $686: Begin SbId := $0F; Inc( SouthFunc ); End; {VT82C686(A)} {v1.20}
    $8231: SbId := $10; {VT8231} {v1.20}
    $3074: SbId := $11; {VT8233} {v1.20}
   End;
  End else
 If SouthMan = $1022 {AMD} then {v1.20}
  Begin
   SouthFunc := $0300; {AMD/VIA method}
   case SouthId of {case v1.21}
    $7408: SbId := $14; {AMD-756}
    $7410: SbId := $15; {AMD-766}
    $7440: SbId := $16; {AMD-768}
   end;
  End else
 If SouthMan = $1039 {SiS} then
  Begin
   case SouthId of {v1.21}
     $8: SbId := $17; {any SiS South Bridge}
    $18: SbId := $18; {SiS 950 can have $8 or $18}
   End;
  End else
 If SouthMan = $10B9 {ALi} then {v1.18}
  Begin
   SouthFunc := $0400; {ALi method}
   case SouthId of
    $1523: begin SbId:=$12; end; {M1523} {v1.26}
    $1533: begin SbId:=$13; Inc(SouthFunc); end; {M1533/1543/1535} {v1.19}
   end;
  End else
 If SouthMan = $1055 {SMSC} then {v1.21}
  Begin
   If SouthId = $9460 then {SLC90E66} {v1.21}
    Begin
     SouthFunc := $0600; {SMSC method}
     SbId := $19;
    End;
  End else
 If SouthMan = $10AD {Winbond/Symphony Labs} then {v1.21}
  Begin
   If SouthId = $0565 then {W83C553F} {v1.21}
    Begin
     SouthFunc := $0700; {Winbond method}
     SbId := $1A;
    End;
  End else
 If SouthMan = $1283 {ITE} then {v1.21}
  Begin
   case SouthId of
    $8872 : Begin SouthFunc := $0801; SbId := $1B; End; {IT8871F/8872F}
    $8888 : Begin SouthFunc := $0802; SbId := $1C; End; {IT8888F}
   End;
  End else
 If SouthMan = $1166 {Reliance/ServerWorks} then {v1.24}
  Begin
   SouthFunc:=$0900;
   case SouthId of
    $0200 : SbId := $1D; {OSB4}
   End;
  End else
 If SouthMan = $1066 {PicoPower} then {v1.25}
  Begin
   SouthFunc:=$1000;
   case SouthId of
    $0002,$8002 : SbId := $1E; {Vesuvius V3-LS}
   End;
  End else
 If SouthMan = $1078 {PicoPower} then {v1.25}
  Begin
   SouthFunc:=$1100;
   case SouthId of
    $0100 : SbId := $1F; {Geode CS5530(A)}
   End;
  End else
 If SouthMan = $1045 {OPTi} then {v1.26}
  Begin
   SouthFunc:=$1200;
   case SouthId of
    $C568: SbId:=$20; {OPTi 82C750}
   end;
  End else
 If SouthMan = $3388 {HiNT} then {v1.26}
  Begin
   SouthFunc:=$1300;
   case SouthId of
    $8012: SbId:=$21; {HiNT VXPro-II}
   end;
  End;

 {Id chipset as a whole}
 CurrentChipset := '';
 Case NbId of
  $01 : If (SbId = $01) or (SbId = $02) then CurrentChipset := 'Intel Mercury 430LX';
  $02 : If (SbId = $01) or (SbId = $02) then CurrentChipset := 'Intel Neptune 430NX';
  $03 : If SbId = $03 then CurrentChipset := 'Intel Triton 430FX';
  $04 : If SbId = $04 then CurrentChipset := 'Intel 430MX (mobile)';
  $05 : If SbId = $05 then CurrentChipset := 'Intel Natoma" 440FX';
  $06 : If SbId = $05 then CurrentChipset := 'Intel Triton II 430HX';
  $07 : If SbId = $05 then CurrentChipset := 'Intel Triton II 430VX';
  $08 : If SbId = $06 then CurrentChipset := 'Intel Triton III 430TX';
  $09 : If SbId = $06 then CurrentChipset := 'Intel AGPSet 440LX/EX'; {EX v1.18}
  $0A : case SbId of
         $06 : CurrentChipset := 'Intel AGPSet 440BX/ZX'; {v1.18}
         $18 : CurrentChipset := 'SMSC VictoryBX-66'; {v1.21}
        End;
  $0B : If SbId = $06 then CurrentChipset := 'Intel AGPSet 440GX'; {v1.18}
  $0C : If SbId = $02 then CurrentChipset := 'Intel 450KX';
  $0D : If SbId = $02 then CurrentChipset := 'Intel 450KX/GX';
  $0E : If SbId = $02 then CurrentChipset := 'Intel 450GX';
  $0F : If (SbId = $07) or (SbId = $08) then CurrentChipset := 'Intel 810'; {v1.19}
  $10 : case SbId of  {v1.19}
         $07,$08 : CurrentChipset := 'Intel 810E';
         $09     : CurrentChipset := 'Intel 810E2';
        End;
  $11 : case SbId of {v1.19}
         $07,$08 : CurrentChipset := 'Intel 815(G)';
         $09     : CurrentChipset := 'Intel 815E(P/G)';
         $0A     : CurrentChipset := 'Intel 815EM';
        End;
  $12 : case SbId of {v1.19}
         $07,$08 : CurrentChipset := 'Intel 820';
         $09     : CurrentChipset := 'Intel 820E';
        End;
  $13 : If (SbId = $07) or (SbId = $08) then CurrentChipset := 'Intel 840'; {v1.19}
  $14 : If SbId = $09 then CurrentChipset := 'Intel 850'; {v1.19}
  $15 : If SbId = $09 then CurrentChipset := 'Intel 860'; {v1.22}
  $16 : If SbId = $0B then CurrentChipset := 'Intel 830MP'; {v1.23}
  $17 : If SbId = $09 then CurrentChipset := 'Intel 845'; {v1.23}
  $18 : If SbId = $0C then CurrentChipset := 'Intel E7500'; {v1.26}
  $19 : CurrentChipset := 'VIA Apollo Master';
  $1A : If SbId = $0D then CurrentChipset := 'VIA Apollo VP/VPX';
  $1B : If SbId = $0D then CurrentChipset := 'VIA Apollo VP2/AMD 640';
  $1C : If (SbId = $0D) or (SbId = $0E) then CurrentChipset := 'VIA Apollo VP3'; {0D v1.24}
  $1D : If (SbId = $0E) or (SbId = $0F) then CurrentChipset := 'VIA Apollo MVP3'; {0D v1.20}
  $1E : CurrentChipset := 'VIA Apollo P6';
  $1F : If SbId = $0F then CurrentChipset := 'VIA Apollo MVP4'; {v1.20}
  $20 : If (SbId = $0E) or (SbId = $0F) then CurrentChipset := 'VIA Apollo Pro (Plus/133/133A)'; {v1.20}
  $21 : If (SbId = $0E) or (SbId = $0F) then CurrentChipset := 'VIA Apollo Pro Plus/133/133A'; {v1.20}
  $22 : If SbId = $0F then CurrentChipset := 'VIA Apollo ProMedia'; {v1.20}
  $23 : CurrentChipset := 'VIA Apollo Pro 133Z/PM133'; {v1.20}
  $24 : If SbId = $0F then CurrentChipset := 'VIA Apollo KX133'; {v1.20}
  $25 : If SbId = $0F then CurrentChipset := 'VIA Apollo KT133(A)'; {v1.20}
  $26 : If SbId = $11 then CurrentChipset := 'VIA Apollo KT266'; {v1.20}
  $27 : If SbId = $11 then CurrentChipset := 'VIA Apollo Pro 266'; {v1.20}
  $2D : CurrentChipset := 'ALi FinALi 486 not supported!'; {v1.26}
  $2E : If SbId = $12 then CurrentChipset := 'ALi Aladdin III'; {v1.26}
  $2F : If SbId = $13 then CurrentChipset := 'ALi Aladdin IV/IV+'; {v1.26}
  $30 : If SbId = $13 then CurrentChipset := 'ALi Aladdin V'; {v1.22}
  $31 : If SbId = $13 then CurrentChipset := 'ALi Aladdin Pro II'; {v1.18}
  $32 : If SbId = $13 then CurrentChipset := 'ALi Aladdin Pro IV'; {v1.24}
  $33 : If SbId = $13 then CurrentChipset := 'ALi ALiMAGiK 1'; {v1.24}
  $34 : If SbId = $14 then CurrentChipset := 'AMD 750'; {v1.20}
  $35 : case SbId of {v1.20}
         $0F : CurrentChipset := 'AMD 760 (VIA South)';
         $15 : CurrentChipset := 'AMD 760 (AMD South)';
        end;
  $36 : case SbId of
         $15 : CurrentChipset := 'AMD 760MP'; {v1.20}
         $16 : CurrentChipset := 'AMD 760MPX'; {v1.26}
        end;
  $37 : CurrentChipset := 'SiS 85C496+497'; {v1.21}
  $38 : If SbId = $17 then CurrentChipset := 'SiS 501/5101/5501'; {v1.21}
  $39 : If SbId = $17 then CurrentChipset := 'SiS 5511+5513'; {v1.21}
  $3A : If SbId = $17 then CurrentChipset := 'SiS 5571'; {v1.21}
  $3B : If SbId = $17 then CurrentChipset := 'SiS 5591/5592+5595'; {v1.21}
  $3C : If SbId = $17 then CurrentChipset := 'SiS 5596+5595'; {v1.21}
  $3D : If SbId = $17 then CurrentChipset := 'SiS 5597/5598/5581/5120'; {v1.21}
  $3E : If SbId = $17 then CurrentChipset := 'SiS 530'; {v1.21}
  $3F : If (SbId = $17) or (SbId = $18) then CurrentChipset := 'SiS 540'; {v1.21}
  $40 : If SbId = $17 then CurrentChipset := 'SiS 600'; {v1.21}
  $41 : If SbId = $17 then CurrentChipset := 'SiS 620'; {v1.21}
  $42 : If (SbId = $17) or (SbId = $18) then CurrentChipset := 'SiS 630'; {v1.21}
  $43 : If SbId = $1D then CurrentChipset := 'ServerWorks ServerSet III LE'; {v1.25}
  $44 : If SbId = $1D then CurrentChipset := 'ServerWorks ServerSet III HE'; {v1.25}
  $45 : If SbId = $1E then CurrentChipset := 'National PicoPower Vesuvius-LS'; {v1.25}
  $46 : If SbId = $1F then CurrentChipset := 'National Geode GX1 + CS5530(A)'; {v1.25}
  $47 : If SbId = $20 then CurrentChipset := 'OPTi Vendetta 82C750'; {v1.26}
  $48 : If SbId = $21 then CurrentChipset := 'HiNT VXPro-II (Utron UT85C50x)'; {v1.26}
 End;

 ChipsetFound := ( NbId <> 0 ) or ( SbId <> 0 ); {One of 'm might be enough}

 {If chipset ID failed then show north & south bridge name or ID}
 If CurrentChipset = '' then
  Begin
   If NbId <> 0 then
    CurrentChipset := NbName[ NbId ] + ' + '
   else
    CurrentChipset := '(' + Hw( NorthMan ) + ',' + Hw( NorthId ) +
                      ',' + Hb( NorthRev ) + ') + ';
   If SbId <> 0 then
    CurrentChipset := CurrentChipset + SbName[ SbId ]
   else
    CurrentChipset := CurrentChipset +
                      '(' + Hw( SouthMan ) + ',' + Hw( SouthId ) +
                      ',' + Hb( SouthRev ) + ')';
  End;

 If {( ( not ChipsetFound ) or (} WantToUseAMI {) )} and AMICheckFor then {v1.24}
  Begin
   AMIUsed := True;
   ChipsetFound := True;
   CurrentChipset := CurrentChipset + ' [AMI FLASH]';
  End;
end;

Var
PIIXReg, PIIXReg2, PIIXReg3, PIIXReg4 : LongInt;

{Generic Intel chipset low ROM enable & ROM write access enable}
Procedure ROMEnable( Map : Boolean );
Var
Mask : LongInt;

Begin
 If ROMEnabled=Map then Exit; {v1.22}
 {AMI FLASH INTERFACE STUFF}
 If AMIUsed then
  Begin
   {AMI ROM MAP STUFF}
   If Map then AMIEnable else AMIDisable;
  End else

 {Chipset northbridge stuff}
 Case Hi( NorthFunc ) of
  $01 : Begin {older VIA chipsets}
         If Map then
          Begin
           Port[ $A8 ] := $11;
           PIIXReg := Port[ $A9 ];
           Port[ $A8 ] := $11;
           Port[ $A9 ] := PIIXReg or $40; {ROM Write enable}
          End else
          Begin
           Port[ $A8 ] := $11;
           Port[ $A9 ] := PIIXReg;
          End;
        End;
  $02 : Begin {SiS 85C496+497 chipset} {v1.21}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0 );
           {write enable, 384K enable}
           SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0, PIIXReg or $F8 );
          End else
          Begin
           SetPCIRegD( $00, NorthPos shr 3, NorthPos and $7, $D0, PIIXReg );
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

           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('Intel method: reg $4C = '+_Str(PIIXReg)); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or Mask );
           LogWrite('Intel method: reg $4C changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C ))); {v1.23}
          End else
          Begin
           LogWrite('Intel method: restoring reg $4C from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
          End;
        End;
  $02 : Begin {Intel 8xx method} {v1.19}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('Intel 8xx method: reg $4C = '+_Str(PIIXReg)); {v1.23}
           {FWH Write Enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or $10000 );
           LogWrite('Intel 8xx method: reg $4C changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0 );
           LogWrite('Intel 8xx method: reg $E0 = '+_Str(PIIXReg2)); {v1.23}
           {FWH Decode at $FFF00000-$FFFFFFFF}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0, PIIXReg2 or $C0000000 );
           LogWrite('Intel 8xx method: reg $E0 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $E0 ))); {v1.23}
          End else
          Begin
           LogWrite('Intel 8xx method: restoring reg $4C from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
           LogWrite('Intel 8xx method: restoring reg $E0 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $E0 ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0, PIIXReg2 );
          End;
        End;
  $03 : Begin {VIA method} {AMD method is the same v1.20}
         If Map then
          Begin
           Mask := $C0000001;  {write enable, 512K enable}
           If ( SouthFunc and 1 ) <> 0 then Mask := Mask or $20000000; {1M enable} {v1.22}

           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           LogWrite('VIA/AMD method: reg $40 = '+_Str(PIIXReg)); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or Mask );
           LogWrite('VIA/AMD method: reg $40 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $40 ))); {v1.23}
          End else
          Begin
           LogWrite('VIA/AMD method: restoring reg $40 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $40 ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
          End;
        End;
  $04 : Begin {ALi method} {v1.18}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('ALi method: reg $44 = '+_Str(PIIXReg)); {v1.23}
           {write enable, 256K enable} {43->47 v1.24}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or $47000000 );
           LogWrite('ALi method: reg $44 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 ))); {v1.23}

           PIIXReg4 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           LogWrite('ALi method: reg $40 = '+_Str(PIIXReg4));
           {PCI-ISA Posted Write Disable} {v1.26}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg4 and $FFFFFFFB );
           LogWrite('ALi method: reg $40 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 )));
           If (SouthFunc and 1)<>0 then {v1.26}
            begin
              {M1543C rev. B1 - supports 512K ROM}
              PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78 ); {v1.19}
              LogWrite('ALi method: reg $78 = '+_Str(PIIXReg2)); {v1.23}
              {512K enable} {v1.19} {v1.24 fixed}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg2 or $1000 ); {v1.19}
              LogWrite('ALi method: reg $78 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78 )));
              {M1535 - supports 512K ROM} {v1.24}
              PIIXReg3 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C );
              LogWrite('ALi method: reg $7C = '+_Str(PIIXReg3));
              {512K enable}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C, PIIXReg3 or $1000000 );
              LogWrite('ALi method: reg $7C changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C )));
            end;
          End else
          Begin
           LogWrite('ALi method: restoring reg $44 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
           LogWrite('ALi method: restoring reg $40 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $40 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg4 );
           If (SouthFunc and 1)<>0 then {v1.26}
            begin
              LogWrite('ALi method: restoring reg $78 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
               SouthPos and $7, $78 ))); {v1.23}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg2 ); {v1.19}
              LogWrite('ALi method: restoring reg $7C from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
               SouthPos and $7, $7C ))); {v1.24}
              SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $7C, PIIXReg3 ); {v1.24}
            end;
          End;
        End;
  $05 : Begin {SiS methods} {v1.21}
         if Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           LogWrite('SiS method: reg $40 = '+_Str(PIIXReg)); {v1.23}
           {Lower & extended BIOS enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or $3 );
           LogWrite('SiS method: reg $40 changed to '+_Str(GetPCIRegD($00,SouthPos shr 3,SouthPos and $7,$40))); {v1.23}
           case Lo(SouthFunc) of
            $01: Begin {internal reg. 80h}
                   Port[ $22 ] := $80;
                   PIIXReg2 := Port[ $23 ];
                   LogWrite('SiS method 1: internal reg $80 = '+_Str(PIIXReg2)); {v1.23}
                   Port[ $22 ] := $80;
                   Port[ $23 ] := PIIXReg2 and $DF or $4; {Enable Flash ROM write}
                   Port[ $22 ] := $80;
                   LogWrite('SiS method 1: internal reg $80 changed to '+_Str(Port[$23])); {v1.23}
                   {v1.23 registers can be also at $70}
                   Port[ $22 ] := $70;
                   PIIXReg3 := Port[ $23 ];
                   LogWrite('SiS method 1: internal reg $70 = '+_Str(PIIXReg3)); {v1.23}
                   Port[ $22 ] := $70;
                   Port[ $23 ] := PIIXReg3 and $DF or $4; {Enable Flash ROM write}
                   Port[ $22 ] := $70;
                   LogWrite('SiS method 1: internal reg $70 changed to '+_Str(Port[$23])); {v1.23}
                 End;
            $02: Begin {internal reg. 50h}
                   Port[ $22 ] := $50;
                   PIIXReg2 := Port[ $23 ];
                   LogWrite('SiS method 2: internal reg $50 = '+_Str(PIIXReg2)); {v1.23}
                   Port[ $22 ] := $50;
                   Port[ $23 ] := PIIXReg2 and $DF or $4; {Enable Flash ROM write}
                   Port[ $22 ] := $50;
                   LogWrite('SiS method 2: internal reg $50 changed to '+_Str(Port[$23])); {v1.23}
                 End;
            $03: Begin {PCI reg. 45h bits 5,2}
                   PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
                   LogWrite('SiS method 3: reg $44 = '+_Str(PIIXReg2)); {v1.23}
                   SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg2 and $FFFFDFFF or $400 );
                   LogWrite('SiS method 3: reg $44 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
                    SouthPos and $7, $44 ))); {v1.23}
                 End;
            $04: Begin {PCI reg. 45h bits 7,6}
                   PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
                   LogWrite('SiS method 4: reg $44 = '+_Str(PIIXReg2)); {v1.23}
                   SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg2 and $FFFF7FFF or $4000 );
                   LogWrite('SiS method 4: reg $44 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
                    SouthPos and $7, $44 ))); {v1.23}
                 End;
           End;
          End else
          Begin
           LogWrite('SiS method: restoring reg $40 from '+_Str(GetPCIRegD($00,SouthPos shr 3,SouthPos and $7,$40))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
           case Lo(SouthFunc) of
            $01: Begin {internal reg. 80h}
                   Port[ $22 ] := $80;
                   LogWrite('SiS method 1: restoring internal reg $80 from '+_Str(Port[$23])); {v1.23}
                   Port[ $22 ] := $80;
                   Port[ $23 ] := PIIXReg2;
                   {v1.23 registers can be also at $70}
                   Port[ $22 ] := $70;
                   LogWrite('SiS method 1: restoring internal reg $70 from '+_Str(Port[$23])); {v1.23}
                   Port[ $22 ] := $70;
                   Port[ $23 ] := PIIXReg3;
                 End;
            $02: Begin {internal reg. 50h}
                   Port[ $22 ] := $50;
                   LogWrite('SiS method 2: restoring internal reg $50 from '+_Str(Port[$23])); {v1.23}
                   Port[ $22 ] := $50;
                   Port[ $23 ] := PIIXReg2;
                 End;
            $03,$04: Begin {PCI reg. 45h}
                      LogWrite('SiS method 3/4: restoring reg $44 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
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
           LogWrite('SMSC method: reg $4C = '+_Str(PIIXReg)); {v1.23}
           {write & 1M enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or $02C40000 );
           LogWrite('SMSC method: reg $4C changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C ))); {v1.23}
          End else
          Begin
           LogWrite('SMSC method: restoring reg $4C from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
          End;
        End;
  $07 : Begin {Winbond method} {v1.21}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           LogWrite('Winbond method: reg $4C = '+_Str(PIIXReg)); {v1.23}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg and $DF00 or $D000 );
           LogWrite('Winbond method: reg $4C changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $4C ))); {v1.23}
          End else
          Begin
           LogWrite('Winbond method: restoring reg $4C from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
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
                  LogWrite('ITE method 1: reg $44 = '+_Str(PIIXReg)); {v1.23}
                  {write enable}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg and $FFFF7FFF );
                  LogWrite('ITE method 1: reg $44 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $44 ))); {v1.23}
                 End;
            $02: Begin
                  PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50 );
                  LogWrite('ITE method 2: reg $50 = '+_Str(PIIXReg)); {v1.23}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg or $E0000000 and $FEFFFFFF );
                  LogWrite('ITE method 2: reg $50 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $50 ))); {v1.23}
                 End;
           End;
          End else
          Begin
           case Lo(SouthFunc) of
            $01: Begin
                  LogWrite('ITE method 1: restoring reg $44 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
                   SouthPos and $7, $44 ))); {v1.23}
                  SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
                 End;
            $02: Begin
                  LogWrite('ITE method 2: restoring reg $50 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
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
           LogWrite('Reliance method: reg $40 = '+_Str(PIIXReg));
           {512K enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or $00000200 );
           LogWrite('Reliance method: reg $40 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 )));

           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70 );
           LogWrite('Reliance method: reg $70 = '+_Str(PIIXReg2));
           {4MB enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70, PIIXReg2 or $00000080 );
           LogWrite('Reliance method: reg $70 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70 )));

           LogWrite('Reliance method: internal reg $C6F = '+_Str(Port[$C6F]));
           Port[$C6F]:=Port[$C6F] or $40; {Flash write enable}
           LogWrite('Reliance method: internal reg $C6F changed to '+_Str(Port[$C6F]));
          End else
          Begin
           LogWrite('Reliance method: restoring reg $40 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $40 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
           LogWrite('Reliance method: restoring reg $70 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $70 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $70, PIIXReg2 );
           LogWrite('Reliance method: restoring internal reg $C6F from '+_Str(Port[$C6F]));
           Port[$C6F]:=Port[$C6F] and $BF; {Flash write disable}
          End;
        End;
  $10 : Begin {PicoPower method} {v1.25}
         If Map then
          Begin
           Port[$24]:=$03;
           PIIXReg:=Port[$26];
           LogWrite('PicoPower method: internal reg $03 = '+_Str(PIIXReg));
           Port[$24]:=$03;
           Port[$26]:=PIIXReg or $40; {Flash enable}
           Port[$24]:=$03;
           LogWrite('PicoPower method: internal reg $03 changed to '+_Str(Port[$26]));
          End else
          Begin
           Port[$24]:=$03;
           LogWrite('PicoPower method: restoring internal reg $03 from '+_Str(Port[$26]));
           Port[$24]:=$03;
           Port[$26]:=PIIXReg;
          End;
        End;
  $11 : Begin {Cyrix method} {v1.25}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50 );
           LogWrite('Cyrix method: reg $50 = '+_Str(PIIXReg));
           {16MB enable, write enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg or $00060000 );
           LogWrite('Cyrix method: reg $50 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50 )));
          End else
          Begin
           LogWrite('Cyrix method: restoring reg $50 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $50 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $50, PIIXReg );
          End;
        End;
  $12 : Begin {OPTi method} {v1.26}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           LogWrite('OPTi method: reg $44 = '+_Str(PIIXReg));
           {write enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or $80000000 );
           LogWrite('OPTi method: reg $44 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 )));

           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48 );
           LogWrite('OPTi method: reg $48 = '+_Str(PIIXReg2));
           {256k enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48, PIIXReg2 or $FF000000 );
           LogWrite('OPTi method: reg $48 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48 )));

          End else
          Begin
           LogWrite('OPTi method: restoring reg $44 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $44 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
           LogWrite('OPTi method: restoring reg $48 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $48 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $48, PIIXReg2 );
          End;
        End;
  $13 : Begin {Utron method} {v1.26}
         If Map then
          Begin
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60 );
           LogWrite('Utron method: reg $60 = '+_Str(PIIXReg));
           {write enable}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60, PIIXReg or $2 );
           LogWrite('Utron method: reg $60 changed to '+_Str(GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60 )));
          End else
          Begin
           LogWrite('Utron method: restoring reg $60 from '+_Str(GetPCIRegD( $00, SouthPos shr 3,
            SouthPos and $7, $60 )));
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $60, PIIXReg );
          End;
        End;
 End;
 ROMEnabled:=Map; {v1.22}
End;

begin
 AMIUsed:=False;
 WantToUseAMI :=False;
 ChipsetFound:=false;
 ROMEnabled:=False; {v1.22}
 {v1.22 Initialization moved to UNIFLASH.PAS}
end.