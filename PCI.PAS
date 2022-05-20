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
NbName    : ARRAY[ 1 .. $12 ] of String[ 16 ] =
            ( 'i82433LX',
              'i82433NX',
              'i82437FX',
              'i82437MX',
              'i82441FX',
              'i82439HX',
              'i82437VX',
              'i82439TX',
              'i82443LX',
              'i82454KX',
              'i82454KX/GX',
              'i82454GX',
              'VT82C576M',
              'VT82C585VP/VPX',
              'VT82C595/AMD 640',
              'VT82C597',
              'VT82C598[AT]',
              'VT82C685' );
SbName    : ARRAY[ 1 .. 8 ] of String[ 21 ] =
            ( 'i82378IB SIO',
              'i82379AB SIO.A',
              'i82371FB PIIX',
              'i82371MX MPIIX',
              'i82371SB PIIX3',
              'i82371AB PIIX4',
              'VT82C586[A|B]/AMD 645',
              'VT82C596' );



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
     $01, $03 : NbId := $01;  {82433LX}
     $10, $11 : NbId := $02;  {82433NX}
    End else
   If NorthId = $122D then NbId := $03 {82437FX} else
   If NorthId = $1235 then NbId := $04 {82437MX} else
   If NorthId = $1237 then NbId := $05 {82441FX} else
   If NorthId = $1250 then NbId := $06 {82439HX} else
   If NorthId = $7030 then NbId := $07 {82437VX} else
   If NorthId = $7100 then NbId := $08 {82439TX} else
   If NorthId = $7180 then NbId := $09 {82443LX} else
   If NorthId = $84C4 then
    Case NorthRev of
     $02      : NbId := $0A; {82454KX}
     $04      : NbId := $0B; {82454KX/GX, not sure}
     $05, $06 : NbId := $0C; {82454GX}
    End;
  End else
 If NorthMan = $1106 {VIA} then
  Begin
   If NorthId = $576 then
    Begin
     NorthFunc := $0100; {VIA A8/A9 scheme}
     NbId := $0D {82C576M}
    End else
   If NorthId = $585 then NbId := $0E {82C585VP/VPX} else
   If NorthId = $595 then NbId := $0F {82C595} else
   If NorthId = $597 then NbId := $10 {82C597} else
   If NorthId = $598 then NbId := $11 {82C598(AT)} else
   If NorthId = $685 then
    Begin
     NorthFunc := $0100; {VIA A8/A9 scheme}
     NbId := $12; {82C685}
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
    End;
  End else
 If SouthMan = $1106 {VIA} then
  Begin
   SouthFunc := $0200; {VIA method}
   If SouthId = $586 then SbId := $07 else
   If SouthId = $596 then SbId := $08;
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
  $09 : If SbId = $06 then CurrentChipset := 'Intel AGPSet 440LX';
  $0A : If SbId = $02 then CurrentChipset := 'Intel 450KX';
  $0B : If SbId = $02 then CurrentChipset := 'Intel 450KX/GX';
  $0C : If SbId = $02 then CurrentChipset := 'Intel 450GX';
  $0D : CurrentChipset := 'VIA Apollo Master';
  $0E : If SbId = $07 then CurrentChipset := 'VIA Apollo-VP/VPX';
  $0F : If SbId = $07 then CurrentChipset := 'VIA Apollo-VP2/AMD 640';
  $10 : If SbId = $07 then CurrentChipset := 'VIA Apollo-VP3';
  $11 : If SbId = $08 then CurrentChipset := 'VIA Apollo-MVP3';
  $12 : CurrentChipset := 'VIA Apollo-P6';
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
  $02 : Begin {VIA method}
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
