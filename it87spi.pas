Unit IT87Spi;{alexx}

Interface
Uses Spi;
Const
{use fast 33MHz SPI (<>0) or slow 16MHz (0)}
Fast_Spi = $01;
Function IT87_Probe:boolean;
Function IT87_Spi_Command(writecnt:word;writearr:SpiPacket;
                           readcnt:word;readarr:PSpiPacket):byte;
Implementation
Uses PCI, Tools;

Var
   FlashPort:word;

Function IT87_Probe:boolean;
Var
   tmp:byte;
   st:string;
Begin
{8.3.7       Software Suspend and Flash I/F Control Register
(Index=24h, Default=00s0s0s0b, MB PnP)
    Bit                                                   Description
    7-6     Reserved
     5      Serial Flash I/F SO Selection
            0: Pin 29
            1: Pin 87
     4      LPC Memory/FWM write to Serial Flash I/F Enable
            0: Disable (default)
            1: Enable
     3      Flash I/F Address Segment 3
            (FFF8_0000h-FFFD_FFFFh, FFFE_0000h-FFFE_FFFFh)
            0: Disable
            1: Enable
     2      Flash I/F Address Segment 2
            (FFEF_0000h-FFEF_FFFFh, FFEE_0000h-FFEE_FFFFh)
            0: Disable (default)
            1: Enable
     1      Flash I/F Address Segment 1
            (FFFE_0000h_FFFF_FFFFh, 000E_0000h-000F_FFFFh)
            0: Disable
            1: Enable
     0      Software Suspend
            This register is the Software Suspend register.
            When the bit 0 is set, the IT8716F enters the
            "Software Suspend" state. All the devices, except KBC,
            remain inactive until this bit is cleared or
            when the wake-up event occurs. The wake-up event occurs
            at any transition on signals RI1# (pin 119) and
            Rl2# (pin 127).
            0: Normal.
            1: Software Suspend.}
     tmp := LPCRead($24) and $FE;
     if tmp and (1 shl 1) = 0 then
        st := 'disable'
     else
        st := 'enable';
     LogWrite('Serial flash segment 0xFFFE0000-0xFFFFFFFF, 0x000E0000-0x000FFFFF '+st);

     if tmp and (1 shl 2) = 0 then
        st := 'disable'
     else
        st := 'enable';
     LogWrite('Serial flash segment 0xFFEE0000-0xFFEFFFFF '+st);

     if tmp and (1 shl 3) = 0 then
        st := 'disable'
     else
        st := 'enable';
     LogWrite('Serial flash segment 0xFFF80000-0xFFFEFFFF '+st);

     if tmp and (1 shl 4) = 0 then
        st := 'disable'
     else
        st := 'enable';
     LogWrite('LPC write to serial flash '+st);

     {If any serial flash segment is enabled, enable writing.}
     if ((tmp and $0e) <> 0)  and ((tmp and (1 shl 4)) = 0) then
        begin
             LogWrite('Enabling LPC write to serial flash');
	     tmp := tmp or (1 shl 4);
             LPCWrite($24, tmp);
	end;

     if (tmp and (1 shl 5)) <> 0 then
        st := '87'
        else
            st := '29';
     LogWrite('Serial flash pin='+st);
     {LDN 0x7, reg 0x64/0x65}
     LPCWrite($07, $07);{switch to GPIO device}
     FlashPort := LPCRead($64) shl 8;
     FlashPort := FlashPort or LPCRead($65);
     IT87_Probe := (FlashPort <> 0);
End;

Function IT87_SPI_Command(writecnt:word;writearr:SpiPacket;
                           readcnt:word;readarr:PSpiPacket):byte;
Var
   writeenc,busy:byte;
   i:word;
Begin
     if FlashPort = 0 then
        begin
          LogWrite('Not set FlashPort address! Start IT87_Probe function first!');
          IT87_SPI_Command := 2;
          exit;
        end;
     repeat
       busy := Port[FlashPort] and $80;
     until (busy = 0);
     if readcnt > 3 then
        begin
          LogWrite('Wrong read count!');
          IT87_SPI_Command := 1;
          exit;
        end;
     case writecnt of
     1: begin
          Port[FlashPort+1] := writearr[1];
          writeenc := $00;
        end;
     2: begin
          Port[FlashPort+1] := writearr[1];
          Port[FlashPort+7] := writearr[2];
          writeenc := $01;
        end;
     4: begin
          Port[FlashPort+1] := writearr[1];
          Port[FlashPort+4] := writearr[2];
          Port[FlashPort+3] := writearr[3];
          Port[FlashPort+2] := writearr[4];
          writeenc := $02;
        end;
     5: begin
          Port[FlashPort+1] := writearr[1];
          Port[FlashPort+4] := writearr[2];
          Port[FlashPort+3] := writearr[3];
          Port[FlashPort+2] := writearr[4];
          Port[FlashPort+7] := writearr[5];
          writeenc := $03;
        end;
     else
         begin
           LogWrite('Function called with unsupported writecnt!');
           IT87_SPI_Command := 1;
           exit;
         end;
     end;{case}
     {
     * Start IO, 33 or 16 MHz, readcnt input bytes, writecnt output bytes.
     * Note: We can't use writecnt directly, but have to use a strange encoding.
     }
     if fast_spi = 1 then
        Port[FlashPort] := (($05) shl 4) or ((readcnt and $03) shl 2) or writeenc
     else
        Port[FlashPort] := (($04) shl 4) or ((readcnt and $03) shl 2) or writeenc;
     if readcnt > 0 then
        begin
          repeat
            busy := Port[FlashPort] and $80;
          until (busy = 0);
          for i:=1 to readcnt do
              readarr^[i] := Port[FlashPort+4+i];
        end;
     IT87_SPI_Command := 0;
End;

{procedure IT87_Spi_Page_Program}

Begin
     FlashPort:=0;
End.
