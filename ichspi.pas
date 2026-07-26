Unit ICHSpi;{alexx}

Interface
Uses Spi, flash;
Type
    opcode=record
      code:byte;{This commands spi opcode}
      spi_type:byte;{This commands spi type}
      atomic:byte;{Use preop: (0: none, 1: preop0, 2: preop1}
    end;

(* Opcode definition:
 * Preop 1: Write Enable
 * Preop 2: Write Status register enable
 *
 * OP 0: Write address
 * OP 1: Read Address
 * OP 2: ERASE block
 * OP 3: Read Status register
 * OP 4: Read ID
 * OP 5: Write Status register
 * OP 6: chip private (read JDEC id)
 * OP 7: Chip erase
 *)
    opcodes=record
      preop:array[1..2]of byte;
      codes:array[1..8]of opcode;
    end;

    preop_opcode_pair=record
      preop:byte;
      opcode:byte;
    end;

Function ICH_Probe:boolean;
Function ICH_Spi_Command(writecnt:word;writearr:SpiPacket;
                           readcnt:word;readarr:PSpiPacket):byte;
function ich_spi_read(chip:PChipInfo;Var resFile:File):integer;
function ich_spi_write(chip:PChipInfo;Var resFile:File):integer;

Implementation
Uses crt, PCI, Tools, Language;

Const
     BootBiosDest = $3410;
     BootBiosSPI  = $04;

     ICH_STRAP_RSVD = $00;
     ICH_STRAP_SPI  = $01;
     ICH_STRAP_PCI  = $02;
     ICH_STRAP_LPC  = $03;

     ICH7SpiBarOffset = $3020;
     ICH8SpiBarOffset = $3020;
     ICH9SpiBarOffset = $3800;

     ICH7_REG_SPIS = $00;
     SPIS_SCIP  = $0001;
     SPIS_CDS   = $0004;
     SPIS_FCERR = $0008;


     ICH7_REG_SPIC = $02;
     SPIC_SCGO = $0002;
     SPIC_ACS  = $0004;
     SPIC_SPOP = $0008;
     SPIC_DS   = $4000;

     ICH7_REG_SPIA = $04;

     ICH7_REG_SPID0= $08;
     ICH7_REG_SPID1= $10;
     ICH7_REG_SPID2= $18;
     ICH7_REG_SPID3= $20;
     ICH7_REG_SPID4= $28;
     ICH7_REG_SPID5= $30;
     ICH7_REG_SPID6= $38;
     ICH7_REG_SPID7= $40;
     ICH7_REG_BBAR    = $50;
     ICH7_REG_PREOP   = $54;
     ICH7_REG_OPTYPE  = $56;
     ICH7_REG_OPMENU  = $58;
     ICH7_REG_PBR0    = $60;
     ICH7_REG_PBR1    = $64;
     ICH7_REG_PBR2    = $68;

     SPI_OPCODE_TYPE_READ_NO_ADDRESS    = $00;
     SPI_OPCODE_TYPE_WRITE_NO_ADDRESS   = $01;
     SPI_OPCODE_TYPE_READ_WITH_ADDRESS  = $02;
     SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS = $03;

{ ICH9 controller register definition }
ICH9_REG_FADDR  =       $08;	{ 32 Bits }
ICH9_REG_FDATA0 =       $10;	{ 64 Bytes }

ICH9_REG_SSFS   =       $90;	{ 08 Bits }
SSFS_SCIP	=	$00000001;
SSFS_CDS	=	$00000004;
SSFS_FCERR	=	$00000008;
SSFS_AEL	=	$00000010;

ICH9_REG_SSFC   =       $91;	{ 24 Bits }
SSFC_SCGO	=	$00000200;
SSFC_ACS	=	$00000400;
SSFC_SPOP	=	$00000800;
SSFC_COP	=	$00001000;
SSFC_DBC	=	$00010000;
SSFC_DS		=	$00400000;
SSFC_SME	=	$00800000;
SSFC_SCF	=	$01000000;
SSFC_SCF_20MHZ  =       $00000000;
SSFC_SCF_33MHZ  =       $01000000;

ICH9_REG_PREOP  =       $94;	{ 16 Bits }
ICH9_REG_OPTYPE =       $96;	{ 16 Bits }
ICH9_REG_OPMENU =       $98;	{ 64 Bits }

     Op_Common:opcodes=(preop:(
                               JEDEC_WREN,0
                              );
                        codes:(

                               (code:JEDEC_BYTE_PROGRAM; {Write Byte}
                                 spi_type:SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS;
                                 atomic:1),

                               (*(code:JEDEC_REMS; { Read Electronic Manufacturer Signature - test purposes only!}
                                 spi_type:SPI_OPCODE_TYPE_READ_NO_ADDRESS;
                                 atomic:0),*)
                               (code:JEDEC_READ; {Read Data}
                                 spi_type:SPI_OPCODE_TYPE_READ_WITH_ADDRESS;
                                 atomic:0),
                               (code:JEDEC_BE_D8; {Erase Sector}
                                 spi_type:SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS;
                                 atomic:1),
                               (code:JEDEC_RDSR; {Read Device Status Reg}
                                 spi_type:SPI_OPCODE_TYPE_READ_NO_ADDRESS;
                                 atomic:0),
                               (code:JEDEC_RES; {Resume Deep Power-Down}
                                 spi_type:SPI_OPCODE_TYPE_READ_WITH_ADDRESS;
                                 atomic:0),
                               (code:JEDEC_WRSR; {Write Status Register}
                                 spi_type:SPI_OPCODE_TYPE_WRITE_NO_ADDRESS;
                                 atomic:1),
                               (code:JEDEC_RDID; {Read JDEC ID}
                                 spi_type:SPI_OPCODE_TYPE_READ_NO_ADDRESS;
                                 atomic:0),
                               (code:JEDEC_CE_C7; {Bulk erase}
                                 spi_type:SPI_OPCODE_TYPE_WRITE_NO_ADDRESS;
                                 atomic:1)
                              )
                       );
     Op_Exists:opcodes=(preop:(
                               0,0
                              );
                        codes:((code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0),
                               (code:0;spi_type:0;atomic:0)
                              )
                       );
     pops:array[1..8]of preop_opcode_pair=
                        ((preop:JEDEC_WREN;opcode:JEDEC_BYTE_PROGRAM),
                         (preop:JEDEC_WREN;opcode:JEDEC_SE),
                         (preop:JEDEC_WREN;opcode:JEDEC_BE_52),
                         (preop:JEDEC_WREN;opcode:JEDEC_BE_D8),
                         (preop:JEDEC_WREN;opcode:JEDEC_CE_60),
                         (preop:JEDEC_WREN;opcode:JEDEC_CE_C7),
                         (preop:JEDEC_EWSR;opcode:JEDEC_WRSR),
                         (preop:0;opcode:0)
                        );
Var
   FlashPort:Longint;
   SpiBar:LongInt;
   ICHSpi_Lock:byte;
   CurOpcodes:opcodes;

Function REGREAD8(address:longint):byte;
begin
     REGREAD8 := FIMemB(SpiBar+address);
end;

Function REGREAD16(address:longint):word;
begin
     REGREAD16 := FIMemW(SpiBar+address);
end;

Function REGREAD32(address:longint):longint;
var
   long:longint;
begin
     long := FIMemW(SpiBar+address+$02);
     long := long shl 16;
     REGREAD32 := long or FIMemW(SpiBar+address);;
end;

Procedure REGWRITE8(address:longint;data:byte);
begin
     FOMemB(SpiBar+address, data);
end;

Procedure REGWRITE16(address:longint;data:word);
begin
     FOMemB(SpiBar+address+1, (data shr 8) and $FF);
     FOMemB(SpiBar+address, data and $FF);
end;

Procedure REGWRITE32(address:longint;data:longint);
begin
     FOMemB(SpiBar+address, data and $FF);
     FOMemB(SpiBar+address+1, (data shr 8) and $FF);
     FOMemB(SpiBar+address+2, (data shr 16) and $FF);
     FOMemB(SpiBar+address+3, (data shr 24) and $FF);
end;

function find_opcode(ops:opcodes;op:byte):integer;
var i:byte;
begin
     find_opcode := -1;
     for i:=1 to 8 do
         if (ops.codes[i].code = op) then
            find_opcode := i;
end;

function find_preop(ops:opcodes;preop:byte):integer;
var i:byte;
begin
     find_preop := -1;
     for i:=1 to 2 do
         if (ops.preop[i] = preop) then
            find_preop := i;
end;

function generate_opcodes(ops:opcodes):integer;
var
   preop,optype:word;
   opmenu:array[1..2] of longint;
   i,a,b:byte;
begin
     generate_opcodes := -1;
     case FlashBus of
          SPI_TYPE_ICH7,
          SPI_TYPE_VIA:
            begin
             preop  := REGREAD16(ICH7_REG_PREOP);
              LogWrite('Read PREOP='+Hw(preop));
             optype := REGREAD16(ICH7_REG_OPTYPE);
              LogWrite('Read OPTYPE='+Hw(optype));
             opmenu[1] := REGREAD32(ICH7_REG_OPMENU);
              LogWrite('Read OPMENU[0]='+Hl(opmenu[1]));
	     opmenu[2] := REGREAD32(ICH7_REG_OPMENU + 4);
              LogWrite('Read OPMENU[1]='+Hl(opmenu[2]));
            end;
          SPI_TYPE_ICH8,
          SPI_TYPE_ICH9:
            begin
             preop := REGREAD16(ICH9_REG_PREOP);
             LogWrite('Read PREOP='+Hw(preop));
	     optype:= REGREAD16(ICH9_REG_OPTYPE);
             LogWrite('Read OPTYPE='+Hw(optype));
	     opmenu[1] := REGREAD32(ICH9_REG_OPMENU);
             LogWrite('Read OPMENU[0]='+Hl(opmenu[1]));
	     opmenu[2] := REGREAD32(ICH9_REG_OPMENU + 4);
             LogWrite('Read OPMENU[0]='+Hl(opmenu[2]));

            end;
          else
            begin
              LogWrite('Unsupported chipset!');
              exit;
            end;
     end;

     ops.preop[1] := preop and $FF;
     ops.preop[2] := (preop shr 8) and $FF;

     for i:=1 to 8 do
         begin
           ops.codes[i].spi_type := (optype and $03);
           optype := optype shr 2;
           ops.codes[i].atomic := 0;
         end;

     for i:=1 to 4 do
         begin
           ops.codes[i].code := (opmenu[1] and $FF);
           opmenu[1] := opmenu[1] shr 8;
         end;

     for i:=5 to 8 do
         begin
           ops.codes[i].code := (opmenu[2] and $FF);
           opmenu[2] := opmenu[2] shr 8;
         end;
     i:=1;
     while (pops[i].opcode <> 0) do
           begin
             a := find_opcode(ops, pops[i].opcode);
	     b := find_preop(ops, pops[i].preop);
	     if ((a <> -1) and (b <> -1)) then
	          ops.codes[a].atomic := b-1;
             inc(i);
           end;
     generate_opcodes := 0;
end;

function program_opcodes(ops:opcodes):integer;
var
   preop,optype:word;
   opmenu:array[1..2] of longint;
   i,a,b:byte;
   long:longint;
begin
     program_opcodes := -1;

     (* Program Prefix Opcodes *)
     preop := ops.preop[1];
     preop := preop or (ops.preop[2] shl 8);

     (* Program Opcode Types 0 - 7 *)
     optype := 0;
     for i:=1 to 8 do
         optype := optype or (ops.codes[i].spi_type shl ((i-1)*2));

     (* Program Allowable Opcodes 0 - 3 *)
     opmenu[1] := 0;
     for i := 1 to 4 do
         begin
          long := ops.codes[i].code;
          long := long shl ((i-1) * 8);
          opmenu[1] := opmenu[1] or long;
         end;
     (* Program Allowable Opcodes 4 - 7 *)
     opmenu[2] := 0;
     for i := 5 to 8 do
         begin
          long := ops.codes[i].code;
          long := long shl ((i-5) * 8);
          opmenu[2] := opmenu[2] or long;
         end;

     case FlashBus of
          SPI_TYPE_ICH7,
          SPI_TYPE_VIA:
             begin
               LogWrite('Write PREOP='+Hw(preop));
               REGWRITE16(ICH7_REG_PREOP, preop);
               {LogWrite('Read PREOP='+Hw(REGREAD16(ICH7_REG_PREOP)));}

               LogWrite('Write OPTYPE='+Hw(optype));
	       REGWRITE16(ICH7_REG_OPTYPE, optype);
               {LogWrite('Read OPTYPE='+Hw(REGREAD16(ICH7_REG_OPTYPE)));}

               LogWrite('Write OPMENU[0]='+Hl(opmenu[1]));
	       REGWRITE32(ICH7_REG_OPMENU, opmenu[1]);
               {LogWrite('Read OPMENU[0]='+Hl(REGREAD32(ICH7_REG_OPMENU)));}

               LogWrite('Write OPMENU[1]='+Hl(opmenu[2]));
	       REGWRITE32(ICH7_REG_OPMENU + 4, opmenu[2]);
               {LogWrite('Read OPMENU[1]='+Hl(REGREAD32(ICH7_REG_OPMENU + 4)));}

{               long :=$FFFFFFFF;
               REGWRITE32(ICH7_REG_SPID0,long);
               LogWrite('Read SPID0='+Hl(REGREAD32(ICH7_REG_SPID0)));}
             end;
          SPI_TYPE_ICH8,
          SPI_TYPE_ICH9:
            begin
               LogWrite('Write PREOP='+Hw(preop));
               REGWRITE16(ICH9_REG_PREOP, preop);

               LogWrite('Write OPTYPE='+Hw(optype));
	       REGWRITE16(ICH9_REG_OPTYPE, optype);

               LogWrite('Write OPMENU[0]='+Hl(opmenu[1]));
	       REGWRITE32(ICH9_REG_OPMENU, opmenu[1]);

               LogWrite('Write OPMENU[1]='+Hl(opmenu[2]));
	       REGWRITE32(ICH9_REG_OPMENU + 4, opmenu[2]);

            end;
          else
              begin
                LogWrite('Unsupported chipset!');
                exit;
              end;
     end;

     program_opcodes := 0;
end;

(* This function generates OPCODES from or programs OPCODES to ICH according to
 * the chipset's SPI configuration lock.
 *
 * It should be called before ICH sends any spi command.
 *)
Function ich_init_opcodes:integer;
var
   curopcodes_done:opcodes;
   rc:integer;
begin
     ich_init_opcodes := -1;
     if ICHSpi_Lock = 1 then
        begin
          LogWrite('Generating OPCODES...');
	  curopcodes_done := Op_Exists;
	  rc := generate_opcodes(curopcodes_done);
        end
     else
         begin
	   LogWrite('Programming OPCODES...');
	   curopcodes_done := Op_Common;
	   rc := program_opcodes(curopcodes_done);
         end;

     if rc = 0 then
        begin
          curopcodes := curopcodes_done;
	  LogWrite('done');
	  ich_init_opcodes := 0;
        end
     else
         begin
           LogWrite('failed');
	   ich_init_opcodes := -1;
         end;
end;

Function ICH_Probe:boolean;
var
   long,long2:Longint;
   word1:word;
   bbs : byte;
Begin
     {enable_flash_ich}
     long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $DC);
     LogWrite('BIOS CNTL='+Hl(long));
     {LogWrite('BIOS Lock Enable:'+Hb(long and $02));
     LogWrite('BIOS Write Enable:'+Hb(long and $01));}
     if (long and $01) = 0 then
        begin
         long := long or $01;
         SetPCIRegD($00, SouthPos shr 3, SouthPos and $07, $DC, long);
         if long <> GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $DC) then
            LogWrite('Cant set write enable to bios. Warrning!');
        end;

     FlashPort := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $F0);

     if odd(FlashPort) then
        FlashPort := FlashPort - 1;{ugly fix!!!}
     LogWrite('SpiBar base address='+Hl(FlashPort));
     bbs := FIMemB(FlashPort+BootBiosDest+1);
     LogWrite('BootBIOSDest='+Hb(bbs));
     bbs := (bbs shr 2) and $03;
     if bbs <> ICH_STRAP_SPI then
        begin
         LogWrite('Bios straps='+Hb(bbs));
         ICH_Probe := false;
         exit;
        end;

     case FlashBus of
	SPI_TYPE_ICH7:
             SpiBar := FlashPort + ICH7SpiBarOffset;
        SPI_TYPE_ICH8:
	     SpiBar := FlashPort + ICH8SpiBarOffset;
	SPI_TYPE_ICH9:
	     SpiBar := FlashPort + ICH9SpiBarOffset;
     end;

     case FlashBus of
          SPI_TYPE_ICH7:
             begin
               LogWrite('SPIS='+Hb(FIMemB(SpiBar+$01))+Hb(FIMemB(SpiBar+$00)));
               LogWrite('SPIC='+Hb(FIMemB(SpiBar+$03))+Hb(FIMemB(SpiBar+$02)));
               LogWrite('SPIA='+Hb(FIMemB(SpiBar+$07))+Hb(FIMemB(SpiBar+$06))+
                      Hb(FIMemB(SpiBar+$05))+Hb(FIMemB(SpiBar+$04)));

               LogWrite('SPID0='+Hb(FIMemB(SpiBar+$0F))+Hb(FIMemB(SpiBar+$0E))+
                      Hb(FIMemB(SpiBar+$0D))+Hb(FIMemB(SpiBar+$0C))
                      +Hb(FIMemB(SpiBar+$0B))+Hb(FIMemB(SpiBar+$0A))+
                      Hb(FIMemB(SpiBar+$09))+Hb(FIMemB(SpiBar+$08)));

               LogWrite('SPID1='+Hb(FIMemB(SpiBar+$17))+Hb(FIMemB(SpiBar+$16))+
                      Hb(FIMemB(SpiBar+$15))+Hb(FIMemB(SpiBar+$14))
                      +Hb(FIMemB(SpiBar+$13))+Hb(FIMemB(SpiBar+$12))+
                      Hb(FIMemB(SpiBar+$11))+Hb(FIMemB(SpiBar+$10)));

               LogWrite('SPID2='+Hb(FIMemB(SpiBar+$1F))+Hb(FIMemB(SpiBar+$1E))+
                      Hb(FIMemB(SpiBar+$1D))+Hb(FIMemB(SpiBar+$1C))
                      +Hb(FIMemB(SpiBar+$1B))+Hb(FIMemB(SpiBar+$1A))+
                      Hb(FIMemB(SpiBar+$19))+Hb(FIMemB(SpiBar+$18)));

               LogWrite('SPID3='+Hb(FIMemB(SpiBar+$27))+Hb(FIMemB(SpiBar+$26))+
                      Hb(FIMemB(SpiBar+$25))+Hb(FIMemB(SpiBar+$24))
                      +Hb(FIMemB(SpiBar+$23))+Hb(FIMemB(SpiBar+$22))+
                      Hb(FIMemB(SpiBar+$21))+Hb(FIMemB(SpiBar+$20)));

               LogWrite('SPID4='+Hb(FIMemB(SpiBar+$2F))+Hb(FIMemB(SpiBar+$2E))+
                      Hb(FIMemB(SpiBar+$2D))+Hb(FIMemB(SpiBar+$2C))
                      +Hb(FIMemB(SpiBar+$2B))+Hb(FIMemB(SpiBar+$2A))+
                      Hb(FIMemB(SpiBar+$29))+Hb(FIMemB(SpiBar+$28)));

               LogWrite('SPID5='+Hb(FIMemB(SpiBar+$37))+Hb(FIMemB(SpiBar+$36))+
                      Hb(FIMemB(SpiBar+$35))+Hb(FIMemB(SpiBar+$34))
                      +Hb(FIMemB(SpiBar+$33))+Hb(FIMemB(SpiBar+$32))+
                      Hb(FIMemB(SpiBar+$31))+Hb(FIMemB(SpiBar+$30)));

               LogWrite('SPID6='+Hb(FIMemB(SpiBar+$3F))+Hb(FIMemB(SpiBar+$3E))+
                      Hb(FIMemB(SpiBar+$3D))+Hb(FIMemB(SpiBar+$3C))
                      +Hb(FIMemB(SpiBar+$3B))+Hb(FIMemB(SpiBar+$3A))+
                      Hb(FIMemB(SpiBar+$39))+Hb(FIMemB(SpiBar+$38)));

               LogWrite('SPID7='+Hb(FIMemB(SpiBar+$47))+Hb(FIMemB(SpiBar+$46))+
                      Hb(FIMemB(SpiBar+$45))+Hb(FIMemB(SpiBar+$44))
                      +Hb(FIMemB(SpiBar+$43))+Hb(FIMemB(SpiBar+$42))+
                      Hb(FIMemB(SpiBar+$41))+Hb(FIMemB(SpiBar+$40)));

               LogWrite('BBAR='+Hb(FIMemB(SpiBar+$53))+Hb(FIMemB(SpiBar+$52))+
                      Hb(FIMemB(SpiBar+$51))+Hb(FIMemB(SpiBar+$50)));
               LogWrite('PREOP='+Hb(FIMemB(SpiBar+$55))+Hb(FIMemB(SpiBar+$54)));
               LogWrite('OPTYPE='+Hb(FIMemB(SpiBar+$57))+Hb(FIMemB(SpiBar+$56)));
               LogWrite('OPMENU='+Hb(FIMemB(SpiBar+$5F))+Hb(FIMemB(SpiBar+$5E))+
                       Hb(FIMemB(SpiBar+$5D))+Hb(FIMemB(SpiBar+$5C))
                      +Hb(FIMemB(SpiBar+$5B))+Hb(FIMemB(SpiBar+$5A))+
                       Hb(FIMemB(SpiBar+$59))+Hb(FIMemB(SpiBar+$58)));
               LogWrite('PBR0='+Hb(FIMemB(SpiBar+$63))+Hb(FIMemB(SpiBar+$62))+
                      Hb(FIMemB(SpiBar+$61))+Hb(FIMemB(SpiBar+$60)));
               LogWrite('PBR1='+Hb(FIMemB(SpiBar+$67))+Hb(FIMemB(SpiBar+$66))+
                      Hb(FIMemB(SpiBar+$65))+Hb(FIMemB(SpiBar+$64)));
               LogWrite('PBR2='+Hb(FIMemB(SpiBar+$6B))+Hb(FIMemB(SpiBar+$6A))+
                      Hb(FIMemB(SpiBar+$69))+Hb(FIMemB(SpiBar+$68)));

	       word1 := FIMemB(SpiBar+1);
	       word1 := word1 shl 8;
	       word1 := word1 or FIMemB(SpiBar);
               if (word1 and ($01 shl 15))<>0 then
                  begin
                    LogWrite('WARNING: SPI Configuration Lockdown activated.');
                    ICHSpi_Lock := 1;
                  end;

               ich_init_opcodes;
             end;
	  SPI_TYPE_ICH8,
          SPI_TYPE_ICH9:
             begin
	       word1 := FIMemB(SpiBar+5);
	       word1 := word1 shl 8;
	       word1 := word1 or FIMemB(SpiBar+4);
	       LogWrite('HSFS='+Hw(word1));

	       long := FIMemB(SpiBar+$53);
	       long := (long shl 8) or FIMemB(SpiBar+$52);
	       long := (long shl 8) or FIMemB(SpiBar+$51);
	       long := (long shl 8) or FIMemB(SpiBar+$50);
	       LogWrite('FRACC='+Hl(long));

               LogWrite('FREG0='+Hb(FIMemB(SpiBar+$57))+Hb(FIMemB(SpiBar+$56))+
                      Hb(FIMemB(SpiBar+$55))+Hb(FIMemB(SpiBar+$54)));
               LogWrite('FREG1='+Hb(FIMemB(SpiBar+$5B))+Hb(FIMemB(SpiBar+$5A))+
                      Hb(FIMemB(SpiBar+$59))+Hb(FIMemB(SpiBar+$58)));
               LogWrite('FREG2='+Hb(FIMemB(SpiBar+$5F))+Hb(FIMemB(SpiBar+$5E))+
                      Hb(FIMemB(SpiBar+$5D))+Hb(FIMemB(SpiBar+$5C)));
               LogWrite('FREG3='+Hb(FIMemB(SpiBar+$63))+Hb(FIMemB(SpiBar+$62))+
                      Hb(FIMemB(SpiBar+$61))+Hb(FIMemB(SpiBar+$60)));
               LogWrite('FREG4='+Hb(FIMemB(SpiBar+$67))+Hb(FIMemB(SpiBar+$66))+
                      Hb(FIMemB(SpiBar+$65))+Hb(FIMemB(SpiBar+$64)));
               LogWrite('PR0='+Hb(FIMemB(SpiBar+$77))+Hb(FIMemB(SpiBar+$76))+
                      Hb(FIMemB(SpiBar+$75))+Hb(FIMemB(SpiBar+$74)));
               LogWrite('PR1='+Hb(FIMemB(SpiBar+$7B))+Hb(FIMemB(SpiBar+$7A))+
                      Hb(FIMemB(SpiBar+$79))+Hb(FIMemB(SpiBar+$78)));
               LogWrite('PR2='+Hb(FIMemB(SpiBar+$7F))+Hb(FIMemB(SpiBar+$7E))+
                      Hb(FIMemB(SpiBar+$7D))+Hb(FIMemB(SpiBar+$7C)));
               LogWrite('PR3='+Hb(FIMemB(SpiBar+$83))+Hb(FIMemB(SpiBar+$82))+
                      Hb(FIMemB(SpiBar+$81))+Hb(FIMemB(SpiBar+$80)));
               LogWrite('PR4='+Hb(FIMemB(SpiBar+$87))+Hb(FIMemB(SpiBar+$86))+
                      Hb(FIMemB(SpiBar+$85))+Hb(FIMemB(SpiBar+$84)));
               LogWrite('SSFS,SSFC='+Hb(FIMemB(SpiBar+$93))+Hb(FIMemB(SpiBar+$92))+
                      Hb(FIMemB(SpiBar+$91))+Hb(FIMemB(SpiBar+$90)));
               LogWrite('PREOP='+Hb(FIMemB(SpiBar+$95))+Hb(FIMemB(SpiBar+$94)));
               LogWrite('OPTYPE='+Hb(FIMemB(SpiBar+$97))+Hb(FIMemB(SpiBar+$96)));
               LogWrite('OPMENU='+Hb(FIMemB(SpiBar+$9B))+Hb(FIMemB(SpiBar+$9A))+
                      Hb(FIMemB(SpiBar+$99))+Hb(FIMemB(SpiBar+$98)));
               LogWrite('OPMENU+4='+Hb(FIMemB(SpiBar+$9F))+Hb(FIMemB(SpiBar+$9E))+
                      Hb(FIMemB(SpiBar+$9D))+Hb(FIMemB(SpiBar+$9C)));
               LogWrite('BBAR='+Hb(FIMemB(SpiBar+$A3))+Hb(FIMemB(SpiBar+$A2))+
                      Hb(FIMemB(SpiBar+$A1))+Hb(FIMemB(SpiBar+$A0)));
               LogWrite('FDOC='+Hb(FIMemB(SpiBar+$B3))+Hb(FIMemB(SpiBar+$B2))+
                      Hb(FIMemB(SpiBar+$B1))+Hb(FIMemB(SpiBar+$B0)));

	       if (word1 and ($01 shl 15))<>0 then
                  begin
                    LogWrite('WARNING: SPI Configuration Lockdown activated.');
                    ICHSpi_Lock := 1;
                  end;
	       ich_init_opcodes;
	     end;
     end;

     long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $DC);
     LogWrite('SPI Read Conf in '+Hl(long)+' is:');
     long := (long shr 2) and $03;
     case long of
          0,1,2:
            LogWrite('prefetching='+Hb(long and $02)+', caching='+Hb(long and $01));
          else
            LogWrite('invalid prefetching/caching settings');
     end;
     ICH_Probe := true;
End;

function ich7_run_opcode(op:opcode; offset:longint; datalength:byte; data:PSpiPacket; maxdata:integer):integer;
var
   write_cmd:byte;
   timeout:integer;
   temp32:longint;
   temp16:word;
   a:longint;
   opmenu:array[1..2]of longint;
   opcode_index:integer;
   bt:byte;
   find:boolean;
begin
     LogWrite('Enter ich7_run_opcode: opcode='+Hb(op.code)+
     ' offset='+Hl(offset)+' count='+Hb(datalength));
     write_cmd := 0;
     temp32 := 0;
     (* Is it a write command? *)
     if ((op.spi_type = SPI_OPCODE_TYPE_WRITE_NO_ADDRESS)
	    or (op.spi_type = SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS)) then
		write_cmd := 1;
     (* Programm Offset in Flash into FADDR *)
     REGWRITE32(ICH7_REG_SPIA, (offset and $00FFFFFF));	(* SPI addresses are 24 BIT only *)

     (* Program data into FDATA0 to N *)
     if ((write_cmd = 1) and (datalength <> 0)) then
        begin
		temp32 := 0;
		for a := 0 to datalength-1 do
                    begin
			if ((a mod 4) = 0) then
			   temp32 := 0;

			temp32 := temp32 or (data^[a+1] shl ((a mod 4) * 8));

			if ((a mod 4) = 3) then
                           begin
			     REGWRITE32(ICH7_REG_SPID0 + (a - (a mod 4)), temp32);
                             {LogWrite('Write SPID='+Hl(temp32));}
                           end;
		    end;
		if (((a - 1) mod 4) <> 3) then
                   begin
		     REGWRITE32(ICH7_REG_SPID0 + ((a - 1) - ((a - 1) mod 4)), temp32);
                     {LogWrite('Write SPID='+Hl(temp32));}
                   end;
        end;

     (* Assemble SPIS *)
     temp16 := 0;
     (* clear error status registers *)
     temp16 := temp16 or (SPIS_CDS + SPIS_FCERR);
     {LogWrite('Write SPIS='+Hw(temp16));}
     REGWRITE16(ICH7_REG_SPIS, temp16);

     (* Assemble SPIC *)
     temp16 := 0;

     if (datalength <> 0) then
        begin
          temp16 := temp16 or SPIC_DS;
	  temp16 := temp16 or (((datalength - 1) and (maxdata - 1))) shl 8;
	end;

     (* Select opcode *)
     opmenu[1] := REGREAD32(ICH7_REG_OPMENU);
     {LogWrite('Read OPMENU[0]='+Hl(opmenu[1]));}
     opmenu[2] := REGREAD32(ICH7_REG_OPMENU + 4);
     {LogWrite('Read OPMENU[1]='+Hl(opmenu[2]));}

     find := false;
     for opcode_index:=0 to 3 do
         begin
           bt := (opmenu[1] and $FF);
           if (bt = op.code) then
              begin
                find := true;
	        break;
              end;
	   opmenu[1] := opmenu[1] shr 8;
	end;
     if (not find) then
        for opcode_index:=4 to 7 do
            begin
              bt := (opmenu[2] and $ff);
              if (bt = op.code) then
                 begin
                   find := true;
	           break;
                 end;
	      opmenu[2] := opmenu[2] shr 8;
	    end;
     if (not find) then
        begin
	  LogWrite('Opcode '+Hb(op.code)+' not found.');
	  ich7_run_opcode := 2;
          exit;
	end;
     temp16 := temp16 or ((opcode_index and $07) shl 4);

     (* Handle Atomic *)
     if (op.atomic <> 0) then
        begin
	  (* Select atomic command *)
	  temp16 := temp16 or SPIC_ACS;
	  (* Select prefix opcode *)
	  if ((op.atomic - 1) = 1) then
	     (*Select prefix opcode 2 *) {????????}
	     temp16 := temp16 or SPIC_SPOP;
	end;

     (* Start *)
     temp16 := temp16 or SPIC_SCGO;

     (* write it *)
     LogWrite('Write SPIC='+Hw(temp16));
     REGWRITE16(ICH7_REG_SPIC, temp16);

     (* wait for cycle complete *)
     timeout := 10*60;	{60s is a looong timeout}
     while (((REGREAD16(ICH7_REG_SPIS) and SPIS_CDS) = 0) and (timeout <> 0)) do
           begin
                {temp32 := maxlongint;
                while temp32 > 0 do dec(temp32);}
		delay(10);
                dec(timeout);
	   end;
     if (timeout = 0) then
        LogWrite('timeout');

     if ((REGREAD16(ICH7_REG_SPIS) and SPIS_FCERR) <> 0) then
        begin
		LogWrite('Transaction error!');
                LogWrite('SPIS='+Hw(REGREAD16(ICH7_REG_SPIS)));
                ich7_run_opcode := 1;
		exit;
	end;

     if ((write_cmd = 0) and (datalength <> 0)) then
        for a := 0 to datalength-1 do
            begin
	      if ((a mod 4) = 0) then
                 begin
	          temp32 := REGREAD32(ICH7_REG_SPID0 + (a));
                  LogWrite('Read result SPID='+Hl(temp32));
                 end;

	      data^[a+1] := (temp32 and (($ff) shl ((a mod 4) * 8))) shr ((a mod 4) * 8);
	    end;
     ich7_run_opcode := 0;
end;

function ich9_run_opcode(op:opcode; offset:longint; datalength:byte; data:PSpiPacket; maxdata:integer):integer;
var
   write_cmd:byte;
   timeout:integer;
   temp32:longint;
   temp16:word;
   a:longint;
   opmenu:array[1..2]of longint;
   opcode_index:integer;
   bt:byte;
   find:boolean;
begin
     LogWrite('Enter ich9_run_opcode: opcode='+Hb(op.code)+
     ' offset='+Hl(offset)+' count='+Hb(datalength));
     write_cmd := 0;
     temp32 := 0;
     (* Is it a write command? *)
     if ((op.spi_type = SPI_OPCODE_TYPE_WRITE_NO_ADDRESS)
	    or (op.spi_type = SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS)) then
		write_cmd := 1;
     (* Programm Offset in Flash into FADDR *)
     REGWRITE32(ICH9_REG_FADDR, (offset and $00FFFFFF));	(* SPI addresses are 24 BIT only *)

     (* Program data into FDATA0 to N *)
     if ((write_cmd = 1) and (datalength <> 0)) then
        begin
		temp32 := 0;
		for a := 0 to datalength-1 do
                    begin
			if ((a mod 4) = 0) then
			   temp32 := 0;

			temp32 := temp32 or (data^[a+1] shl ((a mod 4) * 8));

			if ((a mod 4) = 3) then
                           begin
			     REGWRITE32(ICH9_REG_FDATA0 + (a - (a mod 4)), temp32);
                           end;
		    end;
		if (((a - 1) mod 4) <> 3) then
                   begin
		     REGWRITE32(ICH9_REG_FDATA0 + ((a - 1) - ((a - 1) mod 4)), temp32);
                   end;
        end;

     (* Assemble SSFS + SSFC *)
     temp32 := 0;
     (* clear error status registers *)
     temp32 := temp32 or (SSFS_CDS + SSFS_FCERR);
     (* Use 20 MHz *)
     temp32 := temp32 or SSFC_SCF_20MHZ;
     if (datalength <> 0) then
        begin
          temp32 := temp32 or SSFC_DS;
          a:=(((datalength - 1) and $3F));
          a:=a shl 16;
	  temp32 := temp32 or a;
	end;

     (* Select opcode *)
     opmenu[1] := REGREAD32(ICH9_REG_OPMENU);
     {LogWrite('Read OPMENU[0]='+Hl(opmenu[1]));}
     opmenu[2] := REGREAD32(ICH9_REG_OPMENU + 4);
     {LogWrite('Read OPMENU[1]='+Hl(opmenu[2]));}

     find := false;
     for opcode_index:=0 to 3 do
         begin
           bt := (opmenu[1] and $FF);
           if (bt = op.code) then
              begin
                find := true;
	        break;
              end;
	   opmenu[1] := opmenu[1] shr 8;
	end;
     if (not find) then
        for opcode_index:=4 to 7 do
            begin
              bt := (opmenu[2] and $ff);
              if (bt = op.code) then
                 begin
                   find := true;
	           break;
                 end;
	      opmenu[2] := opmenu[2] shr 8;
	    end;
     if (not find) then
        begin
	  LogWrite('Opcode '+Hb(op.code)+' not found.');
	  ich9_run_opcode := 2;
          exit;
	end;
     temp32 := temp32 or ((opcode_index and $07) shl 12);

     (* Handle Atomic *)
     if (op.atomic <> 0) then
        begin
	  (* Select atomic command *)
	  temp32 := temp32 or SSFC_ACS;
	  (* Select prefix opcode *)
	  if ((op.atomic - 1) = 1) then
	     (*Select prefix opcode 2 *)
	     temp32 := temp32 or SSFC_SPOP;
	end;

     (* Start *)
     temp32 := temp32 or SSFC_SCGO;

     (* write it *)
     LogWrite('Write SSFS='+Hl(temp32));
     {REGWRITE32(ICH9_REG_SSFS, temp32);}
     {change byte write sequence because write to spibar+1 start spi transfer}
     FOMemB(SpiBar+ICH9_REG_SSFS, temp32 and $FF);
     FOMemB(SpiBar+ICH9_REG_SSFS+2, (temp32 shr 16) and $FF);
     FOMemB(SpiBar+ICH9_REG_SSFS+3, (temp32 shr 24) and $FF);
     FOMemB(SpiBar+ICH9_REG_SSFS+1, (temp32 shr 8) and $FF);


     (* wait for cycle complete *)
     timeout := 100*60;	{60s is a looong timeout}
     while (((REGREAD32(ICH9_REG_SSFS) and SSFS_CDS) = 0) and (timeout <> 0)) do
           begin
                {temp32 := maxlongint;
                while temp32 > 0 do dec(temp32);}
		delay(10);
                dec(timeout);
	   end;
     if (timeout = 0) then
        LogWrite('timeout');

     if ((REGREAD32(ICH9_REG_SSFS) and SSFS_FCERR) <> 0) then
        begin
		LogWrite('Transaction error!');
                LogWrite('SSFS='+Hl(REGREAD32(ICH9_REG_SSFS)));
                ich9_run_opcode := 1;
		exit;
	end;

     if ((write_cmd = 0) and (datalength <> 0)) then
        for a := 0 to datalength-1 do
            begin
	      if ((a mod 4) = 0) then
                 begin
	          temp32 := REGREAD32(ICH9_REG_FDATA0 + (a));
                  LogWrite('Read result FDATA='+Hl(temp32));
                 end;

	      data^[a+1] := (temp32 and (($ff) shl ((a mod 4) * 8))) shr ((a mod 4) * 8);
	    end;
     ich9_run_opcode := 0;
end;

function run_opcode(op:opcode; offset:longint; datalength:byte; data:PSpiPacket):integer;
begin
     run_opcode := 1;
     case FlashBus of
          SPI_TYPE_ICH7:
             begin
               run_opcode := ich7_run_opcode(op, offset, datalength, data, 64);
             end;
	  SPI_TYPE_ICH8,
	  SPI_TYPE_ICH9:
             begin
               run_opcode := ich9_run_opcode(op, offset, datalength, data, 64);
             end;
     end;
end;


function ich_spi_read_page(chip:PChipInfo;
                        readarr:PSpiPacket;
                         offset:longint;
                        maxdata:byte)
                               :integer;
var
   page_size:word;
   remaining:word;
   a:word;
begin
	page_size := chip^.PgSize;
	remaining := page_size;

	LogWrite('ich_spi_read_page: offset='+Hl(offset)+', count='+
                                     Hw(page_size));

	a := 0;
        while a < page_size do
          begin
	    if remaining < maxdata then
               begin
	        if spi_nbyte_read(offset + (page_size - remaining),
				remaining, @readarr^[a+1]) <> 0 then
                                begin
				 LogWrite('Error reading');
				 ich_spi_read_page := 1;
                                 exit;
                                end;
	        remaining := 0;
               end
	    else
                begin
		     if (spi_nbyte_read(offset + (page_size - remaining),
				maxdata, @readarr^[a+1])) <> 0 then
                                begin
				 LogWrite('Error reading');
				 ich_spi_read_page := 1;
                                 exit;

                                end;
		     remaining := remaining - maxdata;
		end;
          a := a + maxdata;
	end;

	ich_spi_read_page := 0;
end;


function ich_spi_read(chip:PChipInfo;Var resFile:File):integer;
var
   total_size:longint;
   page_size:word;
   maxdata:byte;
   result:integer;
   i,a,long :longint;
   buf:SpiPacket;
begin
     {LogWrite('Start ICH spi read');}
     for i:=1 to SpiPacketLen do buf[i]:=0;
     ich_spi_read := 0;
     maxdata := 64;
     total_size := chip^.Size;
     total_size := total_size shl 7;
     page_size := chip^.PgSize;
     if FlashBus = SPI_TYPE_VIA then
        maxdata := 16;
     {Rewrite(resFile,1);}
     LogWrite('total_size='+Hl(total_size));
     LogWrite('page_size='+Hw(page_size));
     a := total_size div page_size;
     LogWrite('Pages count='+Hl(a));
     for i := 0 to a-1 do
         begin
           long := i * page_size;
           result := ich_spi_read_page(chip,
                                @buf,
                                long,
                                maxdata);
           Logwrite('ich_spi_read_page: offset='+Hl(long)+' result='+Hw(result));
           if result <> 0 then break;
           BlockWrite(resFile, buf, page_size);
           LogWrite('Page #'+Hl(i)+' is write to disk');
           {if IOError then
              begin
                ErrorMsg(Msg(65));
                IOError;
                Exit;
              end;}

         end;
     {Close(resFile);}
     ich_spi_read := result;
end;

function ich_spi_write_page(chip:PChipInfo;
                        readarr:PSpiPacket;
                         offset:longint;
                        maxdata:byte)
                               :integer;
var
   page_size:word;
   remaining:word;
   a:word;
begin
	page_size := chip^.PgSize;
	remaining := page_size;

	LogWrite('ich_spi_write_page: offset='+Hl(offset)+', count='+
                                     Hw(page_size));

	a := 0;
        while a < page_size do
          begin
	    if remaining < maxdata then
               begin
	        if run_opcode(curopcodes.codes[1],offset + (page_size - remaining),
				remaining, @readarr^[a+1]) <> 0 then
                                begin
				 LogWrite('Error writing');
				 ich_spi_write_page := 1;
                                 exit;
                                end;
	        remaining := 0;
               end
	    else
                begin
		     if (run_opcode(curopcodes.codes[1],offset + (page_size - remaining),
				maxdata, @readarr^[a+1])) <> 0 then
                                begin
				 LogWrite('Error writing');
				 ich_spi_write_page := 1;
                                 exit;

                                end;
		     remaining := remaining - maxdata;
		end;
          a := a + maxdata;
	end;

	ich_spi_write_page := 0;
end;


function ich_spi_write(chip:PChipInfo;Var resFile:File):integer;
var
   total_size:longint;
   page_size:word;
   erase_size:longint;
   maxdata:byte;
   result:integer;
   i,j,a,b,long :longint;
   buf:SpiPacket;
begin
     {LogWrite('Start ICH spi write');}
     for i:=1 to SpiPacketLen do buf[i]:=0;
     ich_spi_write := 0;
     maxdata := 64;
     total_size := chip^.Size;
     total_size := total_size shl 7;
     page_size := chip^.PgSize;
     erase_size := 64*1024;
     if FlashBus = SPI_TYPE_VIA then
        maxdata := 16;
     LogWrite('total_size='+Hl(total_size));
     LogWrite('page_size='+Hw(page_size));
     a := total_size div erase_size;
     b := erase_size div page_size;
     LogWrite('Pages on block count='+Hl(b));
     LogWrite('Block count='+Hl(a));
     spi_disable_blockprotect;
     for i := 0 to a-1 do
         begin
           long := erase_size;
           long := long * i;
           result := spi_block_erase_d8(chip, long);
           for j := 0 to b-1 do
           begin
             BlockRead(resFile, buf, page_size);
             long := erase_size;
             long := long * i;
             long := long + j * page_size;
             result := ich_spi_write_page(chip,
                                  @buf,
                                  long,
                                  maxdata);
             Logwrite('ich_spi_write_page: offset='+Hl(long)+
                      ' result='+Hw(result));
             if result <> 0 then break;

             LogWrite('Page #'+Hl(i*b+j)+' is write to chip');
             {if IOError then
                begin
                  ErrorMsg(Msg(65));
                  IOError;
                  Exit;
                end;}

           end;{j}
         end;{i}
     {Close(resFile);}
     ich_spi_write := result;
end;

Function ICH_Spi_Command(writecnt:word;writearr:SpiPacket;
                           readcnt:word;readarr:PSpiPacket):byte;
Var
   a:integer;
   opcode_index:integer;
   cmd:byte;
   op:opcode;
   addr:longint;
   data:SpiPacket;
   i:integer;
   count:byte;
Begin
     opcode_index := -1;
     cmd := writearr[1];
     addr := 0;
     (* find cmd in opcodes-table *)
     for a := 1 to 8 do
         if (curopcodes.codes[a].code = cmd) then
            begin
	      opcode_index := a;
	      break;
	    end;
     (* unknown / not programmed command *)
     if (opcode_index = -1) then
        begin
	  LogWrite('Invalid OPCODE '+Hb(cmd));
          ICH_Spi_Command := 1;
	  exit;
	end;

     op.code := curopcodes.codes[opcode_index].code;
     op.spi_type := curopcodes.codes[opcode_index].spi_type;
     op.atomic := curopcodes.codes[opcode_index].atomic;

     (* if opcode-type requires an address *)
     if (op.spi_type = SPI_OPCODE_TYPE_READ_WITH_ADDRESS) or
         (op.spi_type = SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS) then
         begin
		{addr := (writearr[2] shl 16) or
		    (writearr[3] shl 8) or (writearr[4] shl 0);}
                addr := writearr[2];
                addr := (addr shl 8) or writearr[3];
                addr := (addr shl 8) or writearr[4];
         end;
     (* translate read/write array/count *)
     if (op.spi_type = SPI_OPCODE_TYPE_WRITE_NO_ADDRESS) then
        begin
          for i:=2 to writecnt do data[i-1] := writearr[i];
	  count := writecnt - 1;
	end
     else
         if (op.spi_type = SPI_OPCODE_TYPE_WRITE_WITH_ADDRESS) then
            begin
                for i:=5 to writecnt do data[i-4] := writearr[i];
		count := writecnt - 4;
	    end
         else
             begin
               (*for i:=1 to readcnt do data[i] := readarr[i];
	       count := readcnt;
               if (run_opcode(op, addr, count, data) <> 0) then*)
               LogWrite('run_opcode(read): op='+Hb(op.code)+' addr='+Hl(addr)+' readcnt='+Hb(readcnt));
               if (run_opcode(op, addr, readcnt, readarr) <> 0) then
                  begin
	            LogWrite('run OPCODE '+Hb(op.code)+' failed');
                    ich_spi_command := 1;
                    exit;
	          end;
               (*for i:=1 to readcnt do readarr[i] := data[i];*)
               ICH_Spi_Command := 0;
               exit;
	     end;

     {LogWrite('run_opcode(write): op='+Hb(op.code)+' addr='+Hl(addr)+' readcnt='+Hb(readcnt));}
     if (run_opcode(op, addr, count, @data) <> 0) then
        begin
	  LogWrite('run OPCODE '+Hb(op.code)+' failed');
          ich_spi_command := 1;
          exit;
	end;

     ICH_Spi_Command := 0;
End;

Begin
     FlashPort := 0;
     SpiBar := 0;
     ICHSpi_Lock := 0;
     CurOpcodes := Op_Exists;
End.
