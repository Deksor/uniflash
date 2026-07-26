Unit SBSpi;
Interface
Uses
    Spi, Flash;

Function SB_Probe:boolean;
Function SB_Spi_Command(writecnt:word;writearr:SpiPacket;
                         readcnt:word;readarr:PSpiPacket):byte;
Function SB_Spi_Read(chip:PChipInfo;Var resFile:File):integer;
Function SB_Spi_Write(chip:PChipInfo;Var resFile:File):integer;

Implementation
Uses
    Crt, PCI, Tools, Language;
Var
   {FlashPort:Longint;}
   SB_SpiBar:LongInt;
{=============================================================}

{-------------------------------------------------------------}
Function SB_Probe:boolean;
Var
   long,tlong:longint;
   i:byte;
   st:string;
   has_spi:boolean;
   w:word;
begin
     sb_probe := false;
     has_spi := false;
     {GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $DC);}
     for i:=0 to 3 do
         begin
            long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $50+i*4);
            if (long and $03) = 0 then continue;
            st := 'SBxxx ';
            if (long and $01) <> 0 then st := st + 'write protected from ';
            if (long and $02) <> 0 then st := st + 'read protected from ';
            tlong := long and $fffffc00;
            st := st+Hl(tlong)+' to ';
            tlong := tlong + ((long and $03ff) shl 8);
            st := st+Hl(tlong);
            LogWrite(st);
            long := long and $fffffffc;
            SetPCIRegD($00, SouthPos shr 3, SouthPos and $07, $50+i*4, long);
            long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $50+i*4);
            if (long and $03) <> 0 then
               begin
                  st := 'SBxxx ';
                  if (long and $01) <> 0 then st := st + 'write unprotect failed from ';
                  if (long and $02) <> 0 then st := st + 'read unprotect failed from ';
                  tlong := long and $fffffc00;
                  st := st+Hl(tlong)+' to ';
                  tlong := tlong + ((long and $03ff) shl 8);
                  st := st+Hl(tlong);
                  LogWrite(st);
               end;
         end;
     long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $A0);
     long := long and $ffffffe0;
     LogWrite('SBxxx SPI base adress is at '+Hl(long));
     if long <> 0 then has_spi := true;

     if has_spi then
        begin
          SB_SpiBar := long;
          long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $A0);
          LogWrite('SPI_Base_Addr_Reg='+Hl(long));
          long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $BA);
          i := long and $ff;
          LogWrite('IMC_Control='+Hb(i));
          long := GetPCIRegD( $00, SouthPos shr 3, SouthPos and $07, $BB);
          i := long and $ff;
          LogWrite('Host_Control='+Hb(i));
          w := FIMemW(SB_SpiBar);
          LogWrite('Spi_Control_Reg='+Hw(w));
       end;
     {found smbus device and check rom straps}
     sb_probe := true;
end;
{-------------------------------------------------------------}
procedure reset_ififo_pointer;
var
temp:byte;
begin
     temp := FIMemB(sb_spibar+2);
     temp := temp or $10;
     FOMemB(sb_spibar+2, temp);
     while (FIMemB(sb_spibar+$0d) and $07)>0 do
           {LogWrite('reset')};
end;

procedure execute_command;
var
   temp :byte;
begin
     temp := FIMemB(sb_spibar+2);
     temp := temp or 1;
     FOMemB(sb_spibar+2, temp);
     while (FIMemB(sb_spibar+2) and 1)>0 do;
end;

Function SB_Spi_Command(writecnt:word;writearr:SpiPacket;
                         readcnt:word;readarr:PSpiPacket):byte;
Var
   cmd :byte;
   count :integer;
   temp :byte;
   i:integer;
begin
     cmd := writearr[1];
     {LogWrite('SBxxx execute '+Hb(cmd));}
     dec(writecnt);
     if (readcnt > 8) or (writecnt > 8) then
        begin
             LogWrite('SBxxx can not operate '+Hw(readcnt)+' bytes. Allow only 8 bytes.');
             sb_spi_command := 1;
             exit;
        end;
     if writecnt = 0 then
       temp := 1
     else
       temp := 0;
     temp := temp + readcnt;
     temp := temp shl 4;
     temp := temp or writecnt;
     FOMemB(sb_spibar+1, temp);
     {Logwrite('SBxxx transfer counts='+Hb(temp));}
     FOMemB(sb_spibar, cmd);
     LogWrite('SBxxx transfer command='+Hb(cmd));
     {reset internal fifo}
     reset_ififo_pointer;
     for i:=2 to writecnt+1 do
       begin
         FOMemB(sb_spibar+$0C, writearr[i]);
         Logwrite('SBxxx write:'+Hb(writearr[i]));
       end;

     reset_ififo_pointer;
     execute_command;
     reset_ififo_pointer;

     for i:=2 to writecnt+1 do
       begin
         temp := FIMemB(sb_spibar+$0C);
         {LogWrite('SBxxx skip write byte:'+Hb(temp));}
       end;

     for i:=1 to readcnt do
       begin
         readarr^[i]:=FIMemB(sb_spibar+$0C);
         LogWrite('SBxxx read byte:'+Hb(readarr^[i]));
       end;

     sb_spi_command := 0;
end;
{-------------------------------------------------------------}
function sb_spi_read_page(chip:PChipInfo;
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

	LogWrite('sb_spi_read_page: offset='+Hl(offset)+', count='+
                                     Hb(maxdata)+' of '+
                                     Hw(page_size));

	a := 0;
        while a < page_size do
          begin
	       if (spi_nbyte_read(offset + (page_size - remaining),
	           maxdata, @(readarr^[a+1]))) <> 0 then
                   begin
		        LogWrite('SBxxx error reading');
			sb_spi_read_page := 1;
                        exit;
                   end;
	       remaining := remaining - maxdata;
               a := a + maxdata;
	  end;
	  sb_spi_read_page := 0;
end;

Function SB_Spi_Read(chip:PChipInfo;Var resFile:File):integer;
var
   total_size:longint;
   page_size:word;
   maxdata:byte;
   result:integer;
   i,a,long :longint;
   buf:SpiPacket;
begin
     {LogWrite('Start SBxxx spi read');}
     for i:=1 to SpiPacketLen do buf[i]:=0;
     sb_spi_read := 0;
     maxdata := 8;
     total_size := chip^.Size;
     total_size := total_size shl 7;
     page_size := chip^.PgSize;
     {Rewrite(resFile,1);}
     LogWrite('total_size='+Hl(total_size));
     LogWrite('page_size='+Hw(page_size));
     a := total_size div page_size;
     LogWrite('Pages count='+Hl(a));
     for i := 0 to a-1 do
         begin
           long := i * page_size;
           result := sb_spi_read_page(chip,
                                @buf,
                                long,
                                maxdata);
           Logwrite('sb_spi_read_page: offset='+Hl(long)+' result='+Hw(result));
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
     sb_spi_read := result;
end;
{-------------------------------------------------------------}
function program_1byte(addres:longint; data:PSpiPacket):integer;
var
   cmd:SpiPacket;
   i:integer;
begin
     Spi_Write_Enable(@cmd);
     cmd[1]:= JEDEC_BYTE_PROGRAM;
     cmd[4]:= addres and $FF;
     addres := addres shr 8;
     cmd[3]:= addres and $FF;
     addres := addres shr 8;
     cmd[2]:= addres and $FF;
     cmd[5]:=data^[1];
     program_1byte := spi_command(JEDEC_BYTE_PROGRAM_OUTSIZE, cmd, JEDEC_BYTE_PROGRAM_INSIZE, @cmd);

     while (spi_read_status_register and JEDEC_RDSR_BIT_WIP)>0 do;

end;

Function sb_spi_write_page(chip:PChipInfo;
                        readarr:PSpiPacket;
                         offset:longint)
                               :integer;
Var
   page_size:word;
   a:word;
Begin
	page_size := chip^.PgSize;

	LogWrite('sb_spi_write_page: offset='+Hl(offset)+', count='+
                                     Hw(page_size));
	a := 0;
        while a < page_size do
          begin
	       if (program_1byte(offset + a,
                   @(readarr^[a+1]))) <> 0 then
                   begin
		        LogWrite('Error writing');
			sb_spi_write_page := 1;
                        exit;
                   end;
               a := a + 1;
	end;
	sb_spi_write_page := 0;
End;

Function SB_Spi_Write(chip:PChipInfo;Var resFile:File):integer;
var
   total_size:longint;
   page_size:word;
   erase_size:longint;
   {maxdata:byte;}
   result:integer;
   i,j,a,b,long :longint;
   buf:SpiPacket;
begin
     {LogWrite('Start SBxxx spi write');}
     for i:=1 to SpiPacketLen do buf[i]:=0;
     sb_spi_write := 0;
     {maxdata := 1;}
     total_size := chip^.Size;
     total_size := total_size shl 7;
     page_size := chip^.PgSize;
     erase_size := 64*1024;
     LogWrite('total_size='+Hl(total_size));
     LogWrite('page_size='+Hw(page_size));
     a := total_size div erase_size;
     b := erase_size div page_size;
     LogWrite('Block count='+Hl(a));
     LogWrite('Pages count in block ='+Hl(b));
     spi_disable_blockprotect;
     for i := 0 to a-1 do
         begin
           long := erase_size;
           long := long * i;
           Spi_Write_Enable(@buf);
           result := spi_block_erase_d8(chip, long);
           for j := 0 to b-1 do
           begin
             BlockRead(resFile, buf, page_size);
             long := erase_size;
             long := long * i;
             long := long + j * page_size;
             result := sb_spi_write_page(chip,
                                  @buf,
                                  long{,
                                  maxdata});
             Logwrite('sb_spi_write_page: offset='+Hl(long)+
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
     sb_spi_write := result;
end;
{=============================================================}
Begin
     {FlashPort := 0;}
     SB_SpiBar := 0;
End.