{$R-}
unit pci;  { Unit to communicate with ChipSet }

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
ChipsetFound   : boolean;

Procedure OPortD( Prt : Word; Val : LongInt );
Function IPortD( Prt : Word ) : LongInt;
Function GetPCIRegD( Bus, Dev, Func, Reg : Byte ) : LongInt;
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Function LocatePIIX : byte;
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

Function LocatePIIX : byte;
Const
NbName    : ARRAY[ 1 .. $1B ] of String[ 16 ] = { Rainbow }
{1}         ( 'i82433LX',
{2}           'i82433NX',
{3}           'i82437FX',
{4}           'i82437MX',
{5}           'i82441FX',
{6}           'i82439HX',
{7}           'i82437VX',
{8}           'i82439TX',
{9}           'i82443LX/EX', { EX v1.18}
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
{15}          'VT82C576M',
{16}          'VT82C585VP/VPX',
{17}          'VT82C595/AMD 640',
{18}          'VT82C597',
{19}          'VT82C598[AT]',
{1A}          'VT82C685',
{1B}          'M1621' ); {v1.18}
SbName    : ARRAY[ 1 .. $D ] of String[ 21 ] =
{1}         ( 'i82378IB SIO',
{2}           'i82379AB SIO.A',
{3}           'i82371FB PIIX',
{4}           'i82371MX MPIIX',
{5}           'i82371SB PIIX3',
{6}           'i82371AB/EB PIIX4(E)', {EB v1.19}
{7}           'i82801AA ICH', {v1.19}
{8}           'i82801AB ICH0', {v1.19}
{9}           'i82801BA ICH2', {v1.19}
{A}           'i82801BAM ICH2-M', {v1.19}
{B}           'VT82C586[A|B]/AMD 645',
{C}           'VT82C596',
{D}           'M1543' ); {v1.18}



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
 { Locate north bridge. (NOTE: Just to catch the theoretical case where    }
 { the north bridge is NOT at bus 0, dev 0, func 0 - which should normally }
 { not be the case, but you never know and it doesn't hurt as this thing   }
 { tests bus 0, dev 0, func 0 first and immediately exits if found.)       }
 For Pos := 0 to $FF do
  If ( GetPCIRegD( $00, Pos shr 3, Pos and $07, $00 ) and $FFFF ) <> $FFFF then
   If ( GetPCIRegD( $00, Pos shr 3,
                    Pos and $07, $08 ) shr 8 ) = $60000 then Break;
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
   If NorthId = $4A3 then
    Case NorthRev of
     $00, $01, $02, $03 : NbId := $01;  {82433LX} { $00,$02 v1.18}
     $10, $11 : NbId := $02;  {82433NX}
    End else
   If NorthId = $122D then NbId := $03 {82437FX} else
   If NorthId = $1235 then NbId := $04 {82437MX} else
   If NorthId = $1237 then NbId := $05 {82441FX} else
   If NorthId = $1250 then NbId := $06 {82439HX} else
   If NorthId = $7030 then NbId := $07 {82437VX} else
   If NorthId = $7100 then NbId := $08 {82439TX} else
   If NorthId = $7180 then NbId := $09 {82443LX/EX} else { EX v1.18}
   If (NorthId = $7190) or (NorthId = $7192) then NbId := $0A {82443BX/ZX} else {v1.18}
   If (NorthId = $71A0) or (NorthId = $71A2) then NbId := $0B {82443GX} else {v1.18}
   If NorthId = $84C4 then
    Case NorthRev of
     $02      : NbId := $0C; {82454KX}
     $04      : NbId := $0D; {82454KX/GX, not sure}
     $05, $06 : NbId := $0E; {82454GX}
    End else
   If (NorthId = $7120) or (NorthId = $7122) then NbId := $0F else {82810} {v1.19}
   If NorthId = $7124 then NbId := $10 else {82810E} {v1.19}
   If NorthId = $1130 then NbId := $11 else {82815} {v1.19}
   If NorthId = $2500 then NbId := $12 else {82820} {v1.19}
   If NorthId = $1A21 then NbId := $13; {82840} {v1.19}
   If NorthId = $2530 then NbId := $14 else {82850} {v1.19}
  End else
 If NorthMan = $1106 {VIA} then
  Begin
   If NorthId = $576 then
    Begin
     NorthFunc := $0100; {VIA A8/A9 scheme}
     NbId := $15 {82C576M}
    End else
   If NorthId = $585 then NbId := $16 {82C585VP/VPX} else
   If NorthId = $595 then NbId := $17 {82C595} else
   If NorthId = $597 then NbId := $18 {82C597} else
   If NorthId = $598 then NbId := $19 {82C598(AT)} else
   If NorthId = $685 then
    Begin
     NorthFunc := $0100; {VIA A8/A9 scheme}
     NbId := $1A; {82C685}
    End;
  End else
 If NorthMan = $1045 {Opti} then
  Begin
  End else
 If NorthMan = $1060 {UMC} then
  Begin
  End else
 If NorthMan = $1039 {SiS} then
  Begin
  End;
 If NorthMan = $10B9 {ALi} then
  Begin
   If NorthId = $1621 then NbId := $1B; {M1621} {v1.19}
  End;

 {Id southbridge}
 SbId := 0;  {not recognised yet}
 If SouthMan = $8086 {Intel} then
  Begin
   SouthFunc := $0100; {Intel method}
   If SouthId = $484 then SbId := $02 {82379AB SIO.A} else
   If SouthId = $122E then SbId := $03 {82371FB PIIX} else
   If SouthId = $1234 then SbId := $04 {82371MX MPIIX} else
   If SouthId = $7000 then
    Begin
     SbId := $05 {82371SB PIIX3};
     Inc( SouthFunc );
    End else
   If SouthId = $7110 then
    Begin
     SbId := $06; {82371AB PIIX4}
     Inc( SouthFunc, 3 );
    End else
   If SouthID = $2410 then {i82801AA ICH}
    Begin
     SbId := $07;
     SouthFunc := $0200;
    End else
   If SouthID = $2420 then {i82801AB ICH0}
    Begin
     SbId := $08;
     SouthFunc := $0200;
    End else
   If SouthID = $2440 then {i82801BA ICH2}
    Begin
     SbId := $09;
     SouthFunc := $0200;
    End else
   If SouthID = $244C then {i82801BAM ICH2-M}
    Begin
     SbId := $0A;
     SouthFunc := $0200;
    End;
  End else
 If SouthMan = $1106 {VIA} then
  Begin
   SouthFunc := $0300; {VIA method}
   If SouthId = $586 then SbId := $0B else

   If SouthId = $596 then SbId := $0C;
  End else
 If SouthMan = $1045 {Opti} then
  Begin
  End else
 If SouthMan = $1060 {UMC} then
  Begin
  End else
 If SouthMan = $1039 {SiS} then
  Begin
  End;
 If SouthMan = $10B9 {ALi} then {v1.18}
  Begin
   If SouthId = $1533 then {M1543} {v1.19}
    Begin
     SouthFunc := $0400; {ALi method}
     SbId := $0D;
    End;
  End;

 {Id chipset as a whole}
 CurrentChipset := '';
 Case NbId of
  $01 : If SbId = $01 then CurrentChipset := 'Intel Mercury 430LX';
  $02 : If SbId = $01 then CurrentChipset := 'Intel Neptune 430NX';
  $03 : If SbId = $03 then CurrentChipset := 'Intel Triton 430FX';
  $04 : If SbId = $04 then CurrentChipset := 'Intel 430MX (mobile)';
  $05 : If SbId = $05 then CurrentChipset := 'Intel Natoma" 440FX';
  $06 : If SbId = $05 then CurrentChipset := 'Intel Triton II 430HX';
  $07 : If SbId = $05 then CurrentChipset := 'Intel Triton II 430VX';
  $08 : If SbId = $06 then CurrentChipset := 'Intel Triton III 430TX';
  $09 : If SbId = $06 then CurrentChipset := 'Intel AGPSet 440LX/EX'; {EX v1.18}
  $0A : If SbId = $06 then CurrentChipset := 'Intel AGPSet 440BX/ZX'; {v1.18}
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
         $07,$08 : CurrentChipset := 'Intel 815';
         $09     : CurrentChipset := 'Intel 815E(P)';
         $0A     : CurrentChipset := 'Intel 815EM';
        End;
  $12 : case SbId of {v1.19}
         $07,$08 : CurrentChipset := 'Intel 820';
         $09     : CurrentChipset := 'Intel 820E';
        End;
  $13 : If (SbId = $07) or (SbId = $08) then CurrentChipset := 'Intel 840'; {v1.19}
  $14 : If SbId = $09 then CurrentChipset := 'Intel 850'; {v1.19}
  $15 : CurrentChipset := 'VIA Apollo Master';
  $16 : If SbId = $0B then CurrentChipset := 'VIA Apollo-VP/VPX';
  $17 : If SbId = $0B then CurrentChipset := 'VIA Apollo-VP2/AMD 640';
  $18 : If SbId = $0B then CurrentChipset := 'VIA Apollo-VP3';
  $19 : If SbId = $0C then CurrentChipset := 'VIA Apollo-MVP3';
  $1A : CurrentChipset := 'VIA Apollo-P6';
  $1B : If SbId = $0D then CurrentChipset := 'ALi Alladin Pro II'; {v1.18}
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

 If ( ( not ChipsetFound ) or ( WantToUseAMI ) ) and AMICheckFor then
  Begin
   AMIUsed := True;
   ChipsetFound := True;
   CurrentChipset := CurrentChipset + ' [AMI FLASH]';
  End;
end;

Var
PIIXReg,
PIIXReg2 : LongInt;

{Generic Intel chipset low ROM enable & ROM write access enable}
Procedure ROMEnable( Map : Boolean );
Var
Mask : LongInt;

Begin
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
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or Mask );
          End else
          Begin
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
          End;
        End;
  $02 : Begin {Intel 8xx method} {v1.19}
         If Map then
          Begin
           Mask := $10000; {FWH Write Enable}
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C );
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg or Mask );
           Mask := $C0000000; {FWH Decode at $FFF00000-$FFFFFFFF}
           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0 );
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0, PIIXReg2 or Mask );
          End else
          Begin
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $4C, PIIXReg );
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $E0, PIIXReg2 );
          End;
        End;
  $03 : Begin {VIA method}
         If Map then
          Begin
           Mask := $C0000001;  {write enable, 512K enable}

           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40 );
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg or Mask );
          End else
          Begin
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $40, PIIXReg );
          End;
        End;
  $04 : Begin {ALi method} {v1.18}
         If Map then
          Begin
           Mask := $43000000; {write enable, 256K enable}
           PIIXReg := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44 );
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg or Mask );
           {M1543C rev. B1 - supports 512K ROM} {uncommented in v1.19}
           {According to ALi, there is only one correct way to detect revision
            of the M1543 chip: by looking at the label. But that's pretty hard
            to do in software. Also, if your M1543 is relabelled (TXpro on the
            chip with BXcel sticker), you never know, what it really is.
            This reg. is Reserved on pre-B1 revisions of M1543C, but I hope
            writing to this register will not cause any problems...}
           Mask := $10000000; {512K enable} {v1.19}
           PIIXReg2 := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78 ); {v1.19}
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg2 or Mask ); {v1.19}
          End else
          Begin
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $44, PIIXReg );
           SetPCIRegD( $00, SouthPos shr 3, SouthPos and $7, $78, PIIXReg2 ); {v1.19}
          End;
        End;
 End;


(* If PiixMan = $1045 then
  Begin
   {OPTi}
   {NOTE: This is for the OPTi 82C750 'Vendetta' chipset and may or}
   {      may not work on other OPTi chipsets                      }
   CurrentChipset:='OPTi 82C750 Vendetta';
   If Map then
    Begin
     PIIXReg := GetPCIRegD( $00, PiixL shr 3, PiixL and $7, $44 );
     {WP off}
     SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $44, PIIXReg or $80000000 );

     PIIXReg2:= GetPCIRegD( $00, PiixL shr 3, PiixL and $7, $48 );
     {BIOS CS enable for FFFC0000 - FFFFFFFF}
     SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $48,
                 ( PIIXReg2 and $3FFFFFFF ) or $3F000000 );
    End else
    Begin
     SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $44, PIIXReg );
     SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $48, PIIXReg2 );
    End;
  End;
 If PiixMan=$1039 then  {SiS}
   begin
   CurrentChipset:='SiS ';
   Case PiixId of
        $5597 : CurrentChipset:=CurrentChipset+'5597 +VGA (SuperTX)';
        $0496 : CurrentChipset:=CurrentChipset+'496/497 (486)';
        end;
   CurrentChipset:=CurrentChipset+'(N/A)';
   if Map then
              begin
              end
          else
              begin
              end;
   end;

If PiixMan=$1060 then  {UMC}
   begin
   CurrentChipset:='UMC ';
   Case PiixId of
        $E881,
        $0881,
        $8881 : CurrentChipset:=CurrentChipset+'8881 (486)';
        end;
   CurrentChipset:=CurrentChipset+'(N/A)';
   if Map then
              begin
              end
          else
              begin
              end;
   end; *)
End;

begin
 AMIUsed:=False;
 WantToUseAMI :=False;
 ChipsetFound:=false;
 LocatePIIX;      { Sets address of PIIX }
end.