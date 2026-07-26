Unit Spi;{alexx}

Interface
Uses Flash;
Const
     SpiPacketLen=1024;
     { Read Electronic ID }
     JEDEC_RDID	          = $9f;
     JEDEC_RDID_OUTSIZE	  = $01;
     JEDEC_RDID_INSIZE	  = $03;

     { AT25F512A has bit 3 as don't care bit in commands }
     AT25F512A_RDID		= $15;
     AT25F512A_RDID_OUTSIZE	= $01;
     AT25F512A_RDID_INSIZE	= $02;

     { Read Electronic Manufacturer Signature }
     JEDEC_REMS		= $90;
     JEDEC_REMS_OUTSIZE	= $04;
     JEDEC_REMS_INSIZE	= $02;

     { Read Electronic Signature }
     JEDEC_RES		= $ab;
     JEDEC_RES_OUTSIZE	= $04;
     JEDEC_RES_INSIZE	= $01;

     { Write Enable }
     JEDEC_WREN		= $06;
     JEDEC_WREN_OUTSIZE	= $01;
     JEDEC_WREN_INSIZE	= $00;

     { Write Disable }
     JEDEC_WRDI		= $04;
     JEDEC_WRDI_OUTSIZE	= $01;
     JEDEC_WRDI_INSIZE	= $00;

     { Chip Erase = $60 is supported by Macronix/SST chips. }
     JEDEC_CE_60		= $60;
     JEDEC_CE_60_OUTSIZE	= $01;
     JEDEC_CE_60_INSIZE	        = $00;

     { Chip Erase = $c7 is supported by SST/ST/EON/Macronix chips. }
     JEDEC_CE_C7		= $c7;
     JEDEC_CE_C7_OUTSIZE	= $01;
     JEDEC_CE_C7_INSIZE	        = $00;

     { Block Erase = $52 is supported by SST and old Atmel chips. }
     JEDEC_BE_52		= $52;
     JEDEC_BE_52_OUTSIZE	= $04;
     JEDEC_BE_52_INSIZE	        = $00;

     { Block Erase = $d8 is supported by EON/Macronix chips. }
     JEDEC_BE_D8		= $d8;
     JEDEC_BE_D8_OUTSIZE	= $04;
     JEDEC_BE_D8_INSIZE	        = $00;

     { Sector Erase = $20 is supported by Macronix/SST chips. }
     JEDEC_SE		= $20;
     JEDEC_SE_OUTSIZE	= $04;
     JEDEC_SE_INSIZE	= $00;

     { Read Status Register }
     JEDEC_RDSR		= $05;
     JEDEC_RDSR_OUTSIZE	= $01;
     JEDEC_RDSR_INSIZE	= $01;
     JEDEC_RDSR_BIT_WIP	= $01;{($01 << 0);}

     { Write Status Enable }
     JEDEC_EWSR		= $50;
     JEDEC_EWSR_OUTSIZE	= $01;
     JEDEC_EWSR_INSIZE	= $00;

     { Write Status Register }
     JEDEC_WRSR		= $01;
     JEDEC_WRSR_OUTSIZE	= $02;
     JEDEC_WRSR_INSIZE	= $00;

     { Read the memory }
     JEDEC_READ		= $03;
     JEDEC_READ_OUTSIZE	= $04;
     {JEDEC_READ_INSIZE : any length }

     { Write memory byte }
     JEDEC_BYTE_PROGRAM	        = $02;
     JEDEC_BYTE_PROGRAM_OUTSIZE	= $05;
     JEDEC_BYTE_PROGRAM_INSIZE	= $00;

Type
    SPI_Bus=(SPI_TYPE_NONE,
             SPI_TYPE_IT87XX,
             SPI_TYPE_WBSIO,
             SPI_TYPE_ICH7,
             SPI_TYPE_ICH8,
             SPI_TYPE_ICH9,
             SPI_TYPE_VIA,
             SPI_TYPE_SBXXX);
    SpiPacket=array[1..SpiPacketLen]of byte;
    PSpiPacket=^SpiPacket;
Var
   FlashBus:SPI_Bus;
Function Spi_Command(writecnt:word;writearr:SpiPacket;
                      readcnt:word;readarr:PSpiPacket):byte;
Function Spi_RDID(readcnt:word;readarr:PSpiPacket):byte;
Function Spi_RES(readarr:PSpiPacket):byte;
{Function Spi_REMS(readarr:PSpiPacket):byte;}
Function Spi_nByte_Read(address:longint;readcnt:word;readarr:PSpiPacket):byte;
function spi_disable_blockprotect:byte;
function spi_block_erase_d8(chip:PChipInfo;addr:longint):byte;
function spi_chip_erase(chip:PChipInfo):byte;
function spi_chip_read(SaveName:string;chip:PChipInfo):integer;
function spi_chip_write(ReadName:string;chip:PChipInfo):integer;
function spi_read_status_register:byte;
Function Spi_Write_Enable(readarr:PSpiPacket):byte;
Function Spi_Write_Disable(readarr:PSpiPacket):byte;
Function SpiFlashDetect : PChipInfo;

Implementation
Uses crt, Tools, PCI, IT87Spi, WBSIOSpi, ICHSpi, SBSpi, Language;

Function Spi_Command(writecnt:word;writearr:SpiPacket;
                       readcnt:word;readarr:PSpiPacket):byte;
Begin
     Spi_Command := 0;
     case FlashBus of
     SPI_TYPE_IT87XX:
         begin
              Spi_Command := IT87_Spi_Command(writecnt, writearr,
                                               readcnt, readarr);
              exit;
         end;
     SPI_TYPE_WBSIO:
         begin
              Spi_Command := WBSIO_Spi_Command(writecnt, writearr,
                                                readcnt, readarr);
              exit;
         end;
     SPI_TYPE_ICH7,
     SPI_TYPE_ICH8,
     SPI_TYPE_ICH9:
         begin
              Spi_Command := ICH_Spi_Command(writecnt, writearr,
                                              readcnt, readarr);
              exit;
         end;
     SPI_TYPE_SBXXX:
         begin
              Spi_Command := SB_Spi_Command(writecnt, writearr,
                                              readcnt, readarr);
              exit;
         end;
     else
         begin
           LogWrite('SPI bus not set!');
           Spi_Command := 1;
           exit;
         end;
     end;
End;

Function Spi_RDID(readcnt:word;readarr:PSpiPacket):byte;
Var
   i:word;
Begin
     readarr^[1] := JEDEC_RDID;
     if readcnt <> JEDEC_RDID_INSIZE then
        Spi_RDID := Spi_Command(JEDEC_RDID_OUTSIZE, readarr^, readcnt, readarr)
     else
        Spi_RDID := Spi_Command(JEDEC_RDID_OUTSIZE, readarr^, JEDEC_RDID_INSIZE, readarr);
     {LogWrite('RDID('+Hb(JEDEC_RDID)+') returned:'+
               Hb(readarr^[1])+' '+
               Hb(readarr^[2])+' '+
               Hb(readarr^[3]));}
End;

{Function Spi_REMS(readarr:PSpiPacket):byte;
Var
   cmd:SpiPacket;
   i:word;
Begin
     for i:=1 to SpiPacketLen do cmd[i]:=0;
     cmd[1] := JEDEC_REMS;
     Spi_REMS := Spi_Command(JEDEC_REMS_OUTSIZE, cmd, JEDEC_REMS_INSIZE, readarr);
     LogWrite('REMS('+Hb(JEDEC_REMS)+') returned:'+
               Hb(readarr^[1])+' '+
               Hb(readarr^[2]));
End;}

Function Spi_RES(readarr:PSpiPacket):byte;
Var
   i:word;
Begin
     readarr^[1] := JEDEC_RES;
     Spi_RES := Spi_Command(JEDEC_RES_OUTSIZE, readarr^, JEDEC_RES_INSIZE, readarr);
     LogWrite('RES('+Hb(JEDEC_RES)+') returned:'+
               Hb(readarr^[1]));
End;

Function Spi_nByte_Read(address:longint;readcnt:word;readarr:PSpiPacket):byte;
Var
   i:integer;
Begin
{     LogWrite('nbyte_read offset='+Hl(address));}
     readarr^[1] := JEDEC_READ;
     readarr^[2] := (address shr 16) and $FF;
     readarr^[3] := (address shr 8) and $FF;
     readarr^[4] := (address shr 0) and $FF;
     spi_nbyte_read := Spi_Command(JEDEC_READ_OUTSIZE, readarr^, readcnt, readarr);
     {LogWrite('READ('+Hb(JEDEC_READ)+') executed params='+Hb(readarr^[1])+' '+
                                                          Hb(readarr^[2])+' '+
                                                          Hb(readarr^[3])+' '+
                                                          Hb(readarr^[4])+' '+
                                                          Hb(readarr^[5])+' '+
                                                          Hb(readarr^[6])+' ');}
End;

Function Spi_Write_Enable(readarr:PSpiPacket):byte;
{Var
   i:word;}
Begin
     readarr^[1] := JEDEC_WREN;
     Spi_Write_Enable := Spi_Command(JEDEC_WREN_OUTSIZE, readarr^, JEDEC_WREN_INSIZE, readarr);
End;

Function Spi_Write_Disable(readarr:PSpiPacket):byte;
Var
   i:word;
Begin
     readarr^[1] := JEDEC_WRDI;
     Spi_Write_Disable := Spi_Command(JEDEC_WRDI_OUTSIZE, readarr^, JEDEC_WRDI_INSIZE, readarr);
End;

function spi_read_status_register:byte;
var
   i:integer;
   cmd:spipacket;
begin
     for i:=1 to SpiPacketLen do cmd[i]:=0;
     cmd[1] := JEDEC_RDSR;
     spi_read_status_register := Spi_Command(JEDEC_RDSR_OUTSIZE, cmd, JEDEC_RDSR_INSIZE, @cmd);
     {LogWrite('RDSR('+Hb(JEDEC_RDSR)+') returned:'+
               Hb(cmd[1])+' '+Hb(cmd[2]));}
     spi_read_status_register := cmd[1];
end;

function spi_block_erase_d8(chip:PChipInfo;addr:longint):byte;
var
   long:longint;
   i:integer;
   cmd:spipacket;
begin
     for i:=1 to SpiPacketLen do cmd[i]:=0;
     cmd[1] := JEDEC_BE_D8;
     long := addr shr 16;
     cmd[2] := long and $FF;
     long := addr shr 8;
     cmd[3] := long and $FF;
     cmd[4] := addr and $FF;
     {LogWrite('Erase addr='+Hb(0)+Hb(cmd[2])+Hb(cmd[3])+Hb(cmd[4]));}
     {spi_write_enable(@cmd);}
     spi_block_erase_d8 := Spi_Command(JEDEC_BE_D8_OUTSIZE, cmd, JEDEC_BE_D8_INSIZE, @cmd);
    while (spi_read_status_register and JEDEC_RDSR_BIT_WIP)<>0 do
          begin
               delay(100);
          end;
    spi_block_erase_d8 := 0;
end;

function spi_write_status_register(status:byte):byte;
var
   i:integer;
   cmd:spipacket;
begin
     for i:=1 to SpiPacketLen do cmd[i]:=0;
     cmd[1] := JEDEC_WRSR;
     cmd[2] := status;
     spi_write_status_register := Spi_Command(JEDEC_WRSR_OUTSIZE, cmd, JEDEC_WRSR_INSIZE, @cmd);
end;

function spi_disable_blockprotect:byte;
var
   status:byte;
begin
     LogWrite('Disable blockprotect');
     spi_disable_blockprotect := 0;
     status := spi_read_status_register;
     if (status and $3c) <>0 then
             spi_disable_blockprotect := spi_write_status_register(status and (not $3c));
     LogWrite('...done with status='+Hb(status));
end;

function spi_chip_read(SaveName:string;chip:PChipInfo):integer;
Var
IFile : File;
begin
     spi_chip_read := 1;
     LogWrite('Start save spi chip to '+savename);
     If SaveName = '' then SaveName := 'backup.bin';

     Assign( IFile, SaveName );
     Rewrite( IFile, 1 );
{     If IOError then
        Begin
          ErrorMsg(Msg(7)+SaveName+Msg(95));
          Exit;
        End;}

     case FlashBus of
          SPI_TYPE_ICH7,
          SPI_TYPE_ICH8,
          SPI_TYPE_ICH9:
             begin
               spi_chip_read := ich_spi_read(chip, IFile);
             end;
          SPI_TYPE_SBXXX:
             begin
               spi_chip_read := sb_spi_read(chip, IFile);
             end;
     end;
     close(IFile);
     {IOError;}
     LogWrite('BIOS image saved to file '+SaveName);

     spi_chip_read := 0;
end;

function spi_chip_write(ReadName:string;chip:PChipInfo):integer;
Var
IFile : File;
begin
     spi_chip_write := 1;
     LogWrite('Start read spi chip from '+readname);
     If ReadName = '' then ReadName := 'backup.bin';

     Assign( IFile, ReadName );
     Reset( IFile, 1 );
{     If IOError then
        Begin
          ErrorMsg(Msg(7)+SaveName+Msg(95));
          Exit;
        End;}

     case FlashBus of
          SPI_TYPE_ICH7,
          SPI_TYPE_ICH8,
          SPI_TYPE_ICH9:
             begin
               spi_chip_write := ich_spi_write(chip, IFile);
             end;
          SPI_TYPE_SBXXX:
             begin
               spi_chip_write := sb_spi_write(chip, IFile);
             end;

     end;
     close(IFile);
     {IOError;}
     LogWrite('BIOS image write from file '+ReadName);

     spi_chip_write := 0;
end;

function spi_chip_erase(chip:PChipInfo):byte;
var
   cmd:SpiPacket;
   i:integer;
begin
     for i:=1 to SpiPacketLen do cmd[i]:=0;
     cmd[1] := JEDEC_CE_60;
     spi_chip_erase := Spi_Command(JEDEC_CE_60_OUTSIZE, cmd, JEDEC_CE_60_INSIZE, @cmd);

end;

Function SpiFlashDetect : PChipInfo;
var
   Found:boolean;
   Cmd:SpiPacket;
   Man:byte;
   Dev:word;
   i:integer;
Begin
     for i:=1 to SpiPacketLen do cmd[i]:=0;
     if Spi_RDID(3, @cmd) = 0 then
        begin
         Man := Cmd[1];
         Dev := (Cmd[2] shl 8) or Cmd[3];

         Man1 := Cmd[1];
         Dev1 := $00;
         Man2 := Cmd[2];
         Dev2 := Cmd[3];
        end;

    { Spi_REMS(@Cmd); }
    { Spi_RES(@Cmd);  }

     CurManuf := ManuRoot;
     Found := False;
     repeat
      with CurManuf^ do
       if ( Manuf = Man ) and IdChip( Dev, CurCInfo ) then Found := True
       else CurManuf := CurManuf^.Next;
     until Found or ( CurManuf = Nil );
     if Found then
        begin
          LogWrite('Found spi flash chip '+CurCInfo.Name^);
          SpiFlashDetect := @CurCInfo;
        end
     else
         begin
           if (Man = 0) and (Dev = 0) then
              LogWrite('No spi flash chip found')
           else
               LogWrite('Found unknown spi flash chip: Man='+Hb(Man)+' Dev='+Hw(Dev));
           SpiFlashDetect := Nil;
           CurManuf := Nil;
         end;
End;

Begin
     FlashBus := SPI_TYPE_NONE;
End.