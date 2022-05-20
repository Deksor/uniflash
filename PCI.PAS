unit pci;  { Unit to communicate with ChipSet }



interface
Const
PCICfIdx    = $CF8;
PCICfData   = $CFC;

Map         = True;
Unmap       = False;

Var
PiixID,
PiixMan : Word;
PiixL   : Byte;

Procedure OPortD( Prt : Word; Val : LongInt );
Function IPortD( Prt : Word ) : LongInt;
Function GetPCIRegD( Bus, Dev, Func, Reg : Byte ) : LongInt;
Procedure SetPCIRegD( Bus, Dev, Func, Reg : Byte; Value : LongInt );
Function LocatePIIX : byte;
Procedure RomEnable( Map : boolean);

implementation

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
var pos : word;
 {Locate PIIX}
Begin
 For Pos := 0 to $FF do
  If ( GetPCIRegD( $00, Pos shr 3, Pos and $07, $00 ) and $FFFF ) <> $FFFF then
   If ( GetPCIRegD( $00, Pos shr 3,
                    Pos and $07, $08 ) shr 8 ) = $60100 then Break;
 LocatePiix := Pos;
 PiixMan := GetPCIRegD( $00, PIIXL shr 3,
                        PIIXL and $07, $00 ) and $FFFF;
 PiixID := GetPCIRegD( $00, PIIXL shr 3,
                       PIIXL and $07, $00 ) shr 16;
end;

Var
PIIXReg,
PIIXReg2 : LongInt;

{Generic Intel chipset low ROM enable & ROM write access enable}
Procedure ROMEnable( Map : Boolean );
Var
Mask : LongInt;

Begin
 If PiixMan = $8086 then
  Begin
   {INTEL}
   If Map then
    Begin
     Mask := $00440000;                               {write & 128k enable}
     If PiixID = $7000 {PIIX3} then Mask := Mask or $800000;  {512k enable}
     If PiixID = $7110 {PIIX4} then Mask := Mask or $2800000; {1M enable}

     PIIXReg := GetPCIRegD( $00, PiixL shr 3, PiixL and $7, $4C );
     {Enable low bios area (FFF00000-FFFEFFFF), enable BIOS write access}
     SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $4C, PIIXReg or Mask );
    End else
    Begin
     SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $4C, PIIXReg );
    End;
  End else
 If PiixMan = $1106 then
  Begin
   {VIA}
   If PiixID = $576 then
    Begin
     {VIA 82C570 chipset}
     If Map then
      Begin
       Port[ $A8 ] := $11;
       PIIXReg := Port[ $A9 ];
       Port[ $A8 ] := $11;
       Port[ $A9 ] := ( PIIXReg and $7F ) or $40; {ROM Write enable}
      End else
      Begin
       Port[ $A8 ] := $11;
       Port[ $A9 ] := PIIXReg;
      End;
    End else
    Begin
     If Map then
      Begin
       Mask := $00000001;  {write enable}
       If PiixID = $0586 {VT82C586A} then Mask := Mask or $C0000000; {512k enable}

       PIIXReg := GetPCIRegD( $00, PiixL shr 3, PiixL and $7, $40 );
       {Enable low bios area (FFF80000-FFFEFFFF), enable BIOS write access}
       SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $40, PIIXReg or Mask );
      End else
      Begin
       SetPCIRegD( $00, PiixL shr 3, PiixL and $7, $40, PIIXReg );
      End;
    End;
  End else
 If PiixMan = $1045 then
  Begin
   {OPTi}
   {NOTE: This is for the OPTi 82C750 'Vendetta' chipset and may or}
   {      may not work on other OPTi chipsets                      }
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
End;

begin
 PIIXL:=LocatePIIX;      { Sets address of PIIX }
end.
