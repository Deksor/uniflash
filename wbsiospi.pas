Unit WBSioSPI;{alexx}

Interface
Uses Spi;

Function WBSIO_Probe:boolean;
Function WBSIO_Spi_Command(writecnt:word;writearr:SpiPacket;
                           readcnt:word;readarr:PSpiPacket):byte;
Implementation
Uses PCI, Tools, Crt;

Var
   FlashPort:word;

procedure wbsio_enter;
begin
     Port[LPCBase] := $87;
     Port[LPCBase] := $87;
end;

procedure wbsio_leave;
begin
     Port[LPCBase] := $AA;
end;

Function WBSIO_Probe:boolean;
Var
   tmp:byte;
Begin
     WBSIO_Probe := false;
     wbsio_enter;
     tmp := LPCRead($20);
     if tmp <> $0A then
        begin
          LogWrite('W83627 not found at '+Hb(LPCBase)+', id='+Hb(tmp)+', want=$0A.');
          wbsio_leave;
          Exit;
        end;
     tmp := LPCRead($24);
     if (tmp and $02) = 0 then
        begin
          LogWrite('W83627 found at '+Hb(LPCBase)+', but SPI pins are not enabled. CR[$24] bit 1=0');
          wbsio_leave;
          Exit;
        end;
     LPCWrite($07, $06);
     tmp := LPCRead($30);
     if (tmp and $01) = 0 then
        begin
          LogWrite('W83627 found at '+Hb(LPCBase)+', but SPI is not enabled. LDN6[$30] bit 0=0');
          wbsio_leave;
          Exit;
        end;
     FlashPort := (LPCRead($62) shl 8) or LPCRead($63);
     if FlashPort <> 0 then
        begin
        LogWrite('WBSIOSpi found W83627 at '+Hb(LPCBase)+' and it have address '+Hw(FlashPort));
        WBSIO_Probe := true;
        end
     else
        LogWrite('W83627 have empty FlashPort address!');

     wbsio_leave;
End;

Function WBSIO_Spi_Command(writecnt:word;writearr:SpiPacket;
                           readcnt:word;readarr:PSpiPacket):byte;
Var
   i:integer;
   mode:byte;
Begin
     WBSIO_Spi_Command := 0;
     LogWrite('WBSIOSpi Command');
     if (writecnt = 1) and (readcnt = 0) then mode := $10
     else
         if (writecnt = 2) and (readcnt = 0) then
            begin
              mode := $20;
              Port[FlashPort+4] := writearr[2];
              LogWrite('data='+Hb(writearr[2]));
            end
         else
           if (writecnt = 1) and (readcnt = 2) then mode := $30
           else
               if (writecnt = 4) and (readcnt = 0) then
                  begin
                    LogWrite('addr='+Hb(writearr[2] and $0F));
                    for i:=3 to writecnt do
                        begin Port[FlashPort+i-1] := writearr[i]; LogWrite(Hb(writearr[i])+' ');end;
                    mode := $40 or (writearr[2] and $0F);
                  end
               else
                   if (writecnt = 5) and (readcnt = 0) then
                      begin
                        LogWrite('addr='+Hb(writearr[2] and $0F));
                        for i:=3 to 4 do
                            begin Port[FlashPort+i-1] := writearr[i]; LogWrite(Hb(writearr[i])+' ');end;
                        Port[FlashPort+4] := writearr[5];
                        LogWrite('data='+Hb(writearr[5]));
                        mode := $50 or (writearr[2] and $0F);
                      end
                   else
                       if (writecnt = 8) and (readcnt = 0) then
                          begin
                            LogWrite('addr='+Hb(writearr[2] and $0F));
                            for i:=3 to 4 do
                                begin Port[FlashPort+i-1] := writearr[i]; LogWrite(Hb(writearr[i])+' ');end;
                            LogWrite('data=');
                            for i:=5 to 8 do
                                begin Port[FlashPort+i-1] := writearr[i]; LogWrite(Hb(writearr[i])+' ');end;
                            mode := $60 or (writearr[2] and $0F);
                          end
                       else
                           if (writecnt = 5) and (readcnt = 4) then {TODO}
                           else
                               if (writecnt = 4) and (readcnt >= 1) and (readcnt <= 4) then
                                  begin
                                    LogWrite('addr='+Hb(writearr[2] and $0F));
                                    for i:=3 to writecnt do
                                        begin Port[FlashPort+i-1] := writearr[i]; LogWrite(Hb(writearr[i])+' ');end;
                                    mode := ((readcnt + 7) shl 4) or (writearr[2] and $0F);
                                  end;
     LogWrite('cmd='+Hb(writearr[1])+', mode='+Hb(mode));
     if (mode = 0) then
        begin
          LogWrite('Unsupported command writecnt='+Hb(writecnt)+', readcnt='+Hb(readcnt));
          WBSIO_Spi_Command := 1;
          Exit;
        end;
     Port[FlashPort]:=writearr[1];
     Port[FlashPort+1]:=mode;
     Delay(10);
     if readcnt = 0 then Exit;
     LogWrite('Returning data:');
     for i:=1 to readcnt do
         begin
           readarr^[i]:=Port[FlashPort+3+i];
           LogWrite(Hb(readarr^[i]));
         end;
End;

Begin
     FlashPort := 0;
End.