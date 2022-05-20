unit PCICards; {Specific support for some PCI/AGP/CardBus cards} {v1.31}

interface
procedure PCIROMEnable(Map:Boolean); {v1.29}
procedure Flash_PCI_ReadBlock(FlashAddr,MemAddr,Size:LongInt); {v1.31}
procedure Flash_PCI_WriteBlock(FlashAddr,MemAddr,Size:LongInt); {v1.31}
function Flash_PCI_Compare(MemAddr,FlashAddr,Size:LongInt):Boolean; {v1.31}

implementation
uses PCI,Flash;
var PCIReg,PCIMemBase:LongInt;
    PCIBase:Word;
type ReadFunc=function(Address:LongInt):Byte;
     WriteProc=procedure(Address:LongInt;Data:Byte);

procedure DetectPCIBase;
var A:Byte;
    X:LongInt;
begin
  A:=$10;
  repeat
    X:=GetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,A);
    if X and 7=4 then A:=A+4;
    if X and 1=0 then A:=A+4;
  until (X and 1=1) or (A>$28);
  if A<=$28 then PCIBase:=X shr 2 else PCIBase:=$FFFF;
end;

procedure DetectPCIMemBase;
var A:Byte;
    X:LongInt;
begin
  A:=$10;
  repeat
    X:=GetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,A);
    if X and 1=1 then A:=A+4;
  until (X and 1=0) or (A>$28);
  if A<=$28 then PCIMemBase:=X shr 4 else PCIMemBase:=$FFFFFFFF;
end;

procedure SetPCIFlashAccess(ReadFun:ReadFunc;WritePro:WriteProc);
begin
  DetectPCIBase;
  Flash_Read:=ReadFun;
  Flash_Write:=WritePro;
  Flash_ReadBlock:=Flash_PCI_ReadBlock;
  Flash_WriteBlock:=Flash_PCI_WriteBlock;
  Flash_Compare:=Flash_PCI_Compare;
end;

{$F+}
function Flash_PCI_Read_Winbond(Address:LongInt):Byte;
var A:LongInt;
begin
  OPortD(PCIBase+$28,Address);
  A:=IPortD(PCIBase+$24);
  OPortD(PCIBase+$24,A and $FFFFF7FF or $4000);
  repeat
    A:=IPortD(PCIBase+$24);
  until A and $4000=0;
  Flash_PCI_Read_Winbond:=Lo(A);
end;

procedure Flash_PCI_Write_Winbond(Address:LongInt;Data:Byte);
var A:LongInt;
begin
  OPortD(PCIBase+$28,Address);
  A:=IPortD(PCIBase+$24);
  OPortD(PCIBase+$24,A and $FFFFF700 or LongInt(Data) or $2000);
  repeat
    A:=IPortD(PCIBase+$24);
  until A and $2000=0;
end;

function Flash_PCI_Read_3Com(Address:LongInt):Byte; {3C90xB/C}
begin
  OPortD(PCIBase+4,Address);
  Flash_PCI_Read_3Com:=Port[PCIBase+8];
end;

procedure Flash_PCI_Write_3Com(Address:LongInt;Data:Byte);
begin
  OPortD(PCIBase+4,Address);
  Port[PCIBase+8]:=Data;
end;

function Flash_PCI_Read_Realtek(Address:LongInt):Byte;
begin
  OPortD(PCIBase+$D4,Address or $1A0000);
  Flash_PCI_Read_Realtek:=IPortD(PCIBase+$D4) shr 24;
end;

procedure Flash_PCI_Write_Realtek(Address:LongInt;Data:Byte);
begin
  OPortD(PCIBase+$D4,Address or $160000 or LongInt(Data) shl 24);
end;

function Flash_PCI_Read_Realtek1000(Address:LongInt):Byte;
begin
  OPortD(PCIBase+$30,Address or $1A0000);
  Flash_PCI_Read_Realtek1000:=IPortD(PCIBase+$30) shr 24;
end;

procedure Flash_PCI_Write_Realtek1000(Address:LongInt;Data:Byte);
begin
  OPortD(PCIBase+$30,Address or $160000 or LongInt(Data) shl 24);
end;

function Flash_PCI_Read_VIA(Address:LongInt):Byte;
var A:Byte;
begin
  PortW[PCIBase+$8C]:=Address;
  Port[PCIBase+$90]:=1;
  repeat
    A:=Port[PCIBase+$90];
  until A and $80=$80;
  Flash_PCI_Read_VIA:=Port[PCIBase+$91];
end;

procedure Flash_PCI_Write_VIA(Address:LongInt;Data:Byte);
var A:Byte;
begin
  PortW[PCIBase+$8C]:=Address;
  Port[PCIBase+$8F]:=Data;
  Port[PCIBase+$90]:=2;
  repeat
    A:=Port[PCIBase+$90];
  until A and $80=$80;
end;

function Flash_PCI_Read_ADMtek(Address:LongInt):Byte;
var A:LongInt;
begin
  A:=IPortD(PCIBase+$A0);
  OPortD(PCIBase+$A0,A and $78000000 or (Address shl 8) or $8000000);
  repeat
    A:=IPortD(PCIBase+$A0);
  until A and $8000000=0;
  Flash_PCI_Read_ADMtek:=Lo(A);
end;

procedure Flash_PCI_Write_ADMtek(Address:LongInt;Data:Byte);
var A:LongInt;
begin
  A:=IPortD(PCIBase+$A0);
  OPortD(PCIBase+$A0,A and $78000000 or (Address shl 8) or LongInt(Data) or $4000000);
  repeat
    A:=IPortD(PCIBase+$A0);
  until A and $4000000=0;
end;

function Flash_PCI_Read_Sundance(Address:LongInt):Byte;
begin
  OPortD(PCIBase+$40,Address);
  Flash_PCI_Read_Sundance:=Port[PCIBase+$44];
end;

procedure Flash_PCI_Write_Sundance(Address:LongInt;Data:Byte);
begin
  OPortD(PCIBase+$40,Address);
  Port[PCIBase+$44]:=Data;
end;
{$F-}

procedure PCIROMEnable(Map: Boolean); {v1.29}
begin
  if PCIROMEnabled=Map then Exit;
  CurrentPCICard:='';
  if PCIROMBus<>0 then {Configure PCI-to-PCI bridge(s)}
   begin

   end;
  with PCIROMs[CurPCIROM] do
   begin
    case VenID of
     $104A: {STMicroelectronics} {v1.31}
      begin
        CurrentPCICard:='STMicroelectronics';
        case DevID of
         $0981,
         $2774: begin
                  CurrentPCICard:=CurrentPCICard+' STE10/100(A)';
                  SetPCIFlashAccess(Flash_PCI_Read_ADMtek,Flash_PCI_Write_ADMtek);
                end;
        end;
      end;
     $1050: {Winbond} {v1.31}
      begin
        CurrentPCICard:='Winbond';
        case DevID of
         $0840: begin
                  CurrentPCICard:=CurrentPCICard+' W89C840AF';
                  SetPCIFlashAccess(Flash_PCI_Read_Winbond,Flash_PCI_Write_Winbond);
                end;
        end;
      end;
     $10B7: {3Com}
      begin
        CurrentPCICard:='3Com';
        case DevID of
         $9001:
          begin
            CurrentPCICard:=CurrentPCICard+' EtherLink XL PCI Combo';
            SetPCIFlashAccess(Flash_PCI_Read_3Com,Flash_PCI_Write_3Com);
          end;
        end;
      end;
     $10B8: {SMSC} {v1.31}
      begin
        CurrentPCICard:='SMSC';
        case DevID of
         $0006:
          begin
           CurrentPCICard:=CurrentPCICard+' LAN83C175 EPIC/C';
           DetectPCIBase;
           if Map then
            begin
              PCIReg:=IPortD(PCIBase+$10);
              OPortD(PCIBase+$10,PCIReg or $100);
            end
           else OPortD(PCIBase+$10,PCIReg);
          end;
        end;
      end;
     $10EC: {Realtek} {v1.31}
      begin
        CurrentPCICard:='Realtek';
        case DevID of
         $8129: begin
                 CurrentPCICard:=CurrentPCICard+' RTL8129/30/39';
                 SetPCIFlashAccess(Flash_PCI_Read_Realtek,Flash_PCI_Write_Realtek);
                end;
         $8139: begin
                 CurrentPCICard:=CurrentPCICard+' RTL8139 series';
                 SetPCIFlashAccess(Flash_PCI_Read_Realtek,Flash_PCI_Write_Realtek);
                end;
         $8169: begin
                 CurrentPCICard:=CurrentPCICard+' RTL8169 series';
                 SetPCIFlashAccess(Flash_PCI_Read_Realtek1000,Flash_PCI_Write_Realtek1000);
                end;
        end;
      end;
     $1106: {VIA} {v1.31}
      begin
        CurrentPCICard:='VIA';
        SetPCIFlashAccess(Flash_PCI_Read_VIA,Flash_PCI_Write_VIA);
        case DevID of
         $3065: CurrentPCICard:=CurrentPCICard+' VT6102';
         $3106: CurrentPCICard:=CurrentPCICard+' VT6105M Rhine III';
        end;
      end;
     $121A: {3Dfx}
      begin
        CurrentPCICard:='3Dfx';
        case DevID of
         $0003: {Banshee}
          begin
           CurrentPCICard:=CurrentPCICard+' Banshee';
           if Map then
            begin
              PCIReg:=GetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,$14);
              SetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,$14,PCIReg or $10);
            end
           else SetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,$14,PCIReg);
          end;
        end;
      end;
     $1317: {ADMtek} {v1.31}
      begin
        CurrentPCICard:='ADMtek';
        SetPCIFlashAccess(Flash_PCI_Read_ADMtek,Flash_PCI_Write_ADMtek);
        case DevID of
         $0981: CurrentPCICard:=CurrentPCICard+' AL981 Comet';
         $0985: CurrentPCICard:=CurrentPCICard+' AN983(B/BL) Centaur (B)';
         $1985: CurrentPCICard:=CurrentPCICard+' AN985(B/BL) Centaur (B)';
         $9511: CurrentPCICard:=CurrentPCICard+' ADM9511 Centaur II';
         $9513,
         $9514: CurrentPCICard:=CurrentPCICard+' ADM9513 Centaur II';
        end;
      end;
     $13F0: {Sundance Technology}
      begin
        CurrentPCICard:='Sundance Technology';
        case DevID of
         $0201:
          begin
            CurrentPCICard:=CurrentPCICard+' ST201';
            SetPCIFlashAccess(Flash_PCI_Read_Sundance,Flash_PCI_Write_Sundance);
          end;
        end;
      end;
     $9004: {Adaptec} {v1.31}
      begin
        CurrentPCICard:='Adaptec';
        case DevID of
         $6915:
          begin
            CurrentPCICard:=CurrentPCICard+' AIC-6915';
            DetectPCIMemBase;
            if PCIMemBase<>$FFFFFFFF then ROMBase:=PCIMemBase;
          end;
        end;
      end;
    end;
   end;
  if CurrentPCICard='' then CurrentPCICard:='PCI or AGP card';
  PCIROMEnabled:=Map;
end;

procedure Flash_PCI_ReadBlock(FlashAddr,MemAddr,Size:LongInt);
var A:LongInt;
    B:Byte;
begin
  for A:=0 to Size do
   begin
     B:=Flash_Read(FlashAddr+A);
     asm
      XOR    AX,AX
      MOV    ES,AX
      DB     66H
      MOV    DI,WORD(MemAddr)
      DB     66H
      ADD    DI,WORD(A)
      MOV    AH,B
      DB     66H
      MOV    ES:[DI],AH
     end;
   end;
end;

procedure Flash_PCI_WriteBlock(FlashAddr,MemAddr,Size:LongInt);
var A:LongInt;
    B:Byte;
begin
  for A:=0 to Size do
   begin
     asm
      XOR    AX,AX
      MOV    ES,AX
      DB     66H
      MOV    DI,WORD(MemAddr)
      DB     66H
      ADD    DI,WORD(A)
      DB     66H
      MOV    AH,ES:[DI]
      MOV    B,AH
     end;
     Flash_Write(FlashAddr+A,B);
   end;
end;

function Flash_PCI_Compare(MemAddr,FlashAddr,Size:LongInt):Boolean;
var A:LongInt;
    B,C:Byte;
begin
  for A:=0 to Size do
   begin
     B:=Flash_Read(FlashAddr+A);
     asm
      XOR    AX,AX
      MOV    ES,AX
      DB     66H
      MOV    DI,WORD(MemAddr)
      DB     66H
      ADD    DI,WORD(A)
      DB     66H
      MOV    AH,ES:[DI]
      MOV    C,AH
     end;
     if B<>C then begin Flash_PCI_Compare:=False;Exit;end;
   end;
  Flash_PCI_Compare:=True;
end;

{begin}
end.