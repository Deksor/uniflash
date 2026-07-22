
Unit PCICards; {Specific support for some PCI/AGP/CardBus cards} {v1.31}

Interface
Procedure PCIROMEnable(Map:Boolean); {v1.29}
Procedure Flash_PCI_ReadBlock(FlashAddr,MemAddr,Size:LongInt); {v1.31}
Procedure Flash_PCI_WriteBlock(FlashAddr,MemAddr,Size:LongInt); {v1.31}
Function Flash_PCI_Compare(MemAddr,FlashAddr,Size:LongInt): Boolean; {v1.31}

Implementation

Uses PCI,Flash;

Var PCIReg,PCIMemBase: LongInt;
  PCIBase: Word;

Type ReadFunc = Function (Address:LongInt): Byte;
  WriteProc = Procedure (Address:LongInt;Data:Byte);

Procedure DetectPCIBase;

Var A: Byte;
  X: LongInt;
Begin
  A := $10;
  Repeat
    X := GetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,A);
    If X And 7=4 Then A := A+4;
    If X And 1=0 Then A := A+4;
  Until (X And 1=1) Or (A>$28);
  If A<=$28 Then PCIBase := X shr 2
  Else PCIBase := $FFFF;
End;

Procedure DetectPCIMemBase;

Var A: Byte;
  X: LongInt;
Begin
  A := $10;
  Repeat
    X := GetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,A);
    If X And 1=1 Then A := A+4;
  Until (X And 1=0) Or (A>$28);
  If A<=$28 Then PCIMemBase := X shr 4
  Else PCIMemBase := $FFFFFFFF;
End;

Procedure SetPCIFlashAccess(ReadFun:ReadFunc;WritePro:WriteProc);
Begin
  DetectPCIBase;
  Flash_Read := ReadFun;
  Flash_Write := WritePro;
  Flash_ReadBlock := @Flash_PCI_ReadBlock;
  Flash_WriteBlock := @Flash_PCI_WriteBlock;
  Flash_Compare := @Flash_PCI_Compare;
End;

{$F+}
Function Flash_PCI_Read_Winbond(Address:LongInt): Byte;

Var A: LongInt;
Begin
  OPortD(PCIBase+$28,Address);
  A := IPortD(PCIBase+$24);
  OPortD(PCIBase+$24,A And $FFFFF7FF Or $4000);
  Repeat
    A := IPortD(PCIBase+$24);
  Until A And $4000=0;
  Flash_PCI_Read_Winbond := Lo(A);
End;

Procedure Flash_PCI_Write_Winbond(Address:LongInt;Data:Byte);

Var A: LongInt;
Begin
  OPortD(PCIBase+$28,Address);
  A := IPortD(PCIBase+$24);
  OPortD(PCIBase+$24,A And $FFFFF700 Or LongInt(Data) or $2000);
  Repeat
    A := IPortD(PCIBase+$24);
  Until A And $2000=0;
End;

Function Flash_PCI_Read_3Com(Address:LongInt): Byte; {3C90xB/C}
Begin
  OPortD(PCIBase+4,Address);
  Flash_PCI_Read_3Com := Port[PCIBase+8];
End;

Procedure Flash_PCI_Write_3Com(Address:LongInt;Data:Byte);
Begin
  OPortD(PCIBase+4,Address);
  Port[PCIBase+8] := Data;
End;

Function Flash_PCI_Read_Realtek(Address:LongInt): Byte;
Begin
  OPortD(PCIBase+$D4,Address Or $1A0000);
  Flash_PCI_Read_Realtek := IPortD(PCIBase+$D4) shr 24;
End;

Procedure Flash_PCI_Write_Realtek(Address:LongInt;Data:Byte);
Begin
  OPortD(PCIBase+$D4,Address Or $160000 Or LongInt(Data) shl 24);
End;

Function Flash_PCI_Read_Realtek1000(Address:LongInt): Byte;
Begin
  OPortD(PCIBase+$30,Address Or $1A0000);
  Flash_PCI_Read_Realtek1000 := IPortD(PCIBase+$30) shr 24;
End;

Procedure Flash_PCI_Write_Realtek1000(Address:LongInt;Data:Byte);
Begin
  OPortD(PCIBase+$30,Address Or $160000 Or LongInt(Data) shl 24);
End;

Function Flash_PCI_Read_VIA(Address:LongInt): Byte;

Var A: Byte;
Begin
  PortW[PCIBase+$8C] := Address;
  Port[PCIBase+$90] := 1;
  Repeat
    A := Port[PCIBase+$90];
  Until A And $80=$80;
  Flash_PCI_Read_VIA := Port[PCIBase+$91];
End;

Procedure Flash_PCI_Write_VIA(Address:LongInt;Data:Byte);

Var A: Byte;
Begin
  PortW[PCIBase+$8C] := Address;
  Port[PCIBase+$8F] := Data;
  Port[PCIBase+$90] := 2;
  Repeat
    A := Port[PCIBase+$90];
  Until A And $80=$80;
End;

Function Flash_PCI_Read_ADMtek(Address:LongInt): Byte;

Var A: LongInt;
Begin
  A := IPortD(PCIBase+$A0);
  OPortD(PCIBase+$A0,A And $78000000 Or (Address shl 8) or $8000000);
  Repeat
    A := IPortD(PCIBase+$A0);
  Until A And $8000000=0;
  Flash_PCI_Read_ADMtek := Lo(A);
End;

Procedure Flash_PCI_Write_ADMtek(Address:LongInt;Data:Byte);

Var A: LongInt;
Begin
  A := IPortD(PCIBase+$A0);
  OPortD(PCIBase+$A0,A And $78000000 Or (Address shl 8) or LongInt(Data) or $
  4000000);
  Repeat
    A := IPortD(PCIBase+$A0);
  Until A And $4000000=0;
End;

Function Flash_PCI_Read_Sundance(Address:LongInt): Byte;
Begin
  OPortD(PCIBase+$40,Address);
  Flash_PCI_Read_Sundance := Port[PCIBase+$44];
End;

Procedure Flash_PCI_Write_Sundance(Address:LongInt;Data:Byte);
Begin
  OPortD(PCIBase+$40,Address);
  Port[PCIBase+$44] := Data;
End;
{$F-}

Procedure PCIROMEnable(Map: Boolean); {v1.29}
Begin
  If PCIROMEnabled=Map Then Exit;
  CurrentPCICard := '';
  If PCIROMBus<>0 Then {Configure PCI-to-PCI bridge(s)}
    Begin

    End;
  With PCIROMs[CurPCIROM] Do
    Begin
      Case VenID Of 
        $104A: {STMicroelectronics} {v1.31}
               Begin
                 CurrentPCICard := 'STMicroelectronics';
                 Case DevID Of 
                   $0981,
                   $2774:
                          Begin
                            CurrentPCICard := CurrentPCICard+' STE10/100(A)';
                            SetPCIFlashAccess(@Flash_PCI_Read_ADMtek,@
                                              Flash_PCI_Write_ADMtek);
                          End;
                 End;
               End;
        $1050: {Winbond} {v1.31}
               Begin
                 CurrentPCICard := 'Winbond';
                 Case DevID Of 
                   $0840:
                          Begin
                            CurrentPCICard := CurrentPCICard+' W89C840AF';
                            SetPCIFlashAccess(@Flash_PCI_Read_Winbond,@
                                              Flash_PCI_Write_Winbond);
                          End;
                 End;
               End;
        $10B7: {3Com}
               Begin
                 CurrentPCICard := '3Com';
                 Case DevID Of 
                   $9001:
                          Begin
                            CurrentPCICard := CurrentPCICard+
                                              ' EtherLink XL PCI Combo';
                            SetPCIFlashAccess(@Flash_PCI_Read_3Com,@
                                              Flash_PCI_Write_3Com);
                          End;
                 End;
               End;
        $10B8: {SMSC} {v1.31}
               Begin
                 CurrentPCICard := 'SMSC';
                 Case DevID Of 
                   $0006:
                          Begin
                            CurrentPCICard := CurrentPCICard+' LAN83C175 EPIC/C'
                            ;
                            DetectPCIBase;
                            If Map Then
                              Begin
                                PCIReg := IPortD(PCIBase+$10);
                                OPortD(PCIBase+$10,PCIReg Or $100);
                              End
                            Else OPortD(PCIBase+$10,PCIReg);
                          End;
                 End;
               End;
        $10EC: {Realtek} {v1.31}
               Begin
                 CurrentPCICard := 'Realtek';
                 Case DevID Of 
                   $8129:
                          Begin
                            CurrentPCICard := CurrentPCICard+' RTL8129/30/39';
                            SetPCIFlashAccess(@Flash_PCI_Read_Realtek,@
                                              Flash_PCI_Write_Realtek);
                          End;
                   $8139:
                          Begin
                            CurrentPCICard := CurrentPCICard+' RTL8139 series';
                            SetPCIFlashAccess(@Flash_PCI_Read_Realtek,@
                                              Flash_PCI_Write_Realtek);
                          End;
                   $8169:
                          Begin
                            CurrentPCICard := CurrentPCICard+' RTL8169 series';
                            SetPCIFlashAccess(@Flash_PCI_Read_Realtek1000,@
                                              Flash_PCI_Write_Realtek1000);
                          End;
                 End;
               End;
        $1106: {VIA} {v1.31}
               Begin
                 CurrentPCICard := 'VIA';
                 SetPCIFlashAccess(@Flash_PCI_Read_VIA,@Flash_PCI_Write_VIA);
                 Case DevID Of 
                   $3065: CurrentPCICard := CurrentPCICard+' VT6102';
                   $3106: CurrentPCICard := CurrentPCICard+' VT6105M Rhine III';
                 End;
               End;
        $121A: {3Dfx}
               Begin
                 CurrentPCICard := '3Dfx';
                 Case DevID Of 
                   $0003: {Banshee}
                          Begin
                            CurrentPCICard := CurrentPCICard+' Banshee';
                            If Map Then
                              Begin
                                PCIReg := GetPCIRegD(PCIROMBus,PCIROMDev,
                                          PCIROMFun,$14);
                                SetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,$14,
                                           PCIReg Or $10);
                              End
                            Else SetPCIRegD(PCIROMBus,PCIROMDev,PCIROMFun,$14,
                                            PCIReg);
                          End;
                 End;
               End;
        $1317: {ADMtek} {v1.31}
               Begin
                 CurrentPCICard := 'ADMtek';
                 SetPCIFlashAccess(@Flash_PCI_Read_ADMtek,@
                                   Flash_PCI_Write_ADMtek);
                 Case DevID Of 
                   $0981: CurrentPCICard := CurrentPCICard+' AL981 Comet';
                   $0985: CurrentPCICard := CurrentPCICard+
                                            ' AN983(B/BL) Centaur (B)';
                   $1985: CurrentPCICard := CurrentPCICard+
                                            ' AN985(B/BL) Centaur (B)';
                   $9511: CurrentPCICard := CurrentPCICard+' ADM9511 Centaur II'
                   ;
                   $9513,
                   $9514: CurrentPCICard := CurrentPCICard+' ADM9513 Centaur II'
                   ;
                 End;
               End;
        $13F0: {Sundance Technology}
               Begin
                 CurrentPCICard := 'Sundance Technology';
                 Case DevID Of 
                   $0201:
                          Begin
                            CurrentPCICard := CurrentPCICard+' ST201';
                            SetPCIFlashAccess(@Flash_PCI_Read_Sundance,@
                                              Flash_PCI_Write_Sundance);
                          End;
                 End;
               End;
        $9004: {Adaptec} {v1.31}
               Begin
                 CurrentPCICard := 'Adaptec';
                 Case DevID Of 
                   $6915:
                          Begin
                            CurrentPCICard := CurrentPCICard+' AIC-6915';
                            DetectPCIMemBase;
                            If PCIMemBase<>$FFFFFFFF Then ROMBase := PCIMemBase;
                          End;
                 End;
               End;
      End;
    End;
  If CurrentPCICard='' Then CurrentPCICard := 'PCI or AGP card';
  PCIROMEnabled := Map;
End;

Procedure Flash_PCI_ReadBlock(FlashAddr,MemAddr,Size:LongInt);

Var A: LongInt;
  B: Byte;
Begin
  For A:=0 To Size Do
    Begin
      B := Flash_Read(FlashAddr+A);
      asm
      XOR    AX,AX
      MOV    ES,AX
      DB     66H
      MOV    DI,WORD(MemAddr)
      DB     66H
      ADD    DI,WORD(A)
      MOV    AH,B
      DB     66H
      MOV    ES: [DI],AH
    End;
End;
End;

Procedure Flash_PCI_WriteBlock(FlashAddr,MemAddr,Size:LongInt);

Var A: LongInt;
  B: Byte;
Begin
  For A:=0 To Size Do
    Begin
      asm
      XOR    AX,AX
      MOV    ES,AX
      DB     66H
      MOV    DI,WORD(MemAddr)
      DB     66H
      ADD    DI,WORD(A)
      DB     66H
      MOV    AH,ES: [DI]
                    MOV    B,AH
    End;
  Flash_Write(FlashAddr+A,B);
End;
End;

Function Flash_PCI_Compare(MemAddr,FlashAddr,Size:LongInt): Boolean;

Var A: LongInt;
  B,C: Byte;
Begin
  For A:=0 To Size Do
    Begin
      B := Flash_Read(FlashAddr+A);
      asm
      XOR    AX,AX
      MOV    ES,AX
      DB     66H
      MOV    DI,WORD(MemAddr)
      DB     66H
      ADD    DI,WORD(A)
      DB     66H
      MOV    AH,ES: [DI]
                    MOV    C,AH
    End;
  If B<>C Then
    Begin
      Flash_PCI_Compare := False;
      Exit;
    End;
End;
Flash_PCI_Compare := True;
End;

{begin}
End.
