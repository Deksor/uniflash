
Unit CT_Flash; {c't Flasher 8-bit ISA card} {v1.32}

Interface

Uses Flash,Tools;

Const Size512K: Boolean = False; {v1.34}

Var CTFlashPort: Word;
  CTFlashBase: LongInt;

Function CTFlash_AutoDetect: Boolean;
Function FIMemB_Flash_CTFlash(Addr:LongInt): Byte;
Procedure FOMemB_Flash_CTFlash(Addr:LongInt;Data:Byte);
Procedure MoveLinBlock_From_Flash_D_CTFlash(Src,Dest,Size:LongInt);
Procedure MoveLinBlock_To_Flash_B_CTFlash(Src,Dest,Size:LongInt);
Function CompLinBlocks_Flash_CTFlash(Block1,Block2,Size:LongInt): Boolean;

Implementation

Function FIMemB_Flash_CTFlash(Addr:LongInt): Byte;
Begin
  If Not Size512K Then Addr := Addr Or $40000; {v1.34}
  Port[CTFlashPort] := Addr shr 11;
  FIMemB_Flash_CTFlash := FIMemB(CTFlashBase+Addr And $7FF);
End;

Procedure FOMemB_Flash_CTFlash(Addr:LongInt;Data:Byte);
Begin
  If Not Size512K Then Addr := Addr Or $40000; {v1.34}
  Port[CTFlashPort] := Addr shr 11;
  FOMemB(CTFlashBase+Addr And $7FF,Data);
End;

Procedure MoveLinBlock_From_Flash_D_CTFlash(Src,Dest,Size:LongInt);

Var Pos: LongInt;
Begin
  If Not Size512K Then Src := Src Or $40000; {v1.34}
  Pos := 0;
  While Pos<Size Do
    Begin
      Port[CTFlashPort] := (Src+Pos) shr 11;
      If Size-Pos>=2048 Then MoveLinBlockD(CTFlashBase+(Src+Pos) and $7FF,Dest+
        Pos,2048)
      Else MoveLinBlockD(CTFlashBase+(Src+Pos) and $7FF,Dest+Pos,Size-Pos);
      Pos := Pos+2048;
    End;
End;

Procedure MoveLinBlock_To_Flash_B_CTFlash(Src,Dest,Size:LongInt);

Var Pos: LongInt;
Begin
  If Not Size512K Then Dest := Dest Or $40000; {v1.34}
  Pos := 0;
  While Pos<Size Do
    Begin
      Port[CTFlashPort] := (Dest+Pos) shr 11;
      If Size-Pos>=2048 Then MoveLinBlockB(Src+Pos,CTFlashBase+(Dest+Pos) and $7
        FF,2048)
      Else MoveLinBlockB(Src+Pos,CTFlashBase+(Dest+Pos) and $7FF,Size-Pos);
      Pos := Pos+2048;
    End;
End;

Function CompLinBlocks_Flash_CTFlash(Block1,Block2,Size:LongInt): Boolean;

Var OK: Boolean;
  Pos: LongInt;
Begin
  If Not Size512K Then Block1 := Block1 Or $40000; {v1.34}
  OK := True;
  Pos := 0;
  While Pos<Size Do
    Begin
      Port[CTFlashPort] := (Block1+Pos) shr 11;
      If Size-Pos>=2048 Then
        Begin
          If Not CompLinBlocks(CTFlashBase+(Block1+Pos) And $7FF,Block2+Pos,2048
             ) Then OK := False;
        End
      Else
        Begin
          If Not CompLinBlocks(CTFlashBase+(Block1+Pos) And $7FF,Block2+Pos,Size
             -Pos) Then OK := False;
        End;
      Pos := Pos+2048;
      If Not OK Then Break;
    End;
  CompLinBlocks_Flash_CTFlash := OK;
End;

Function CTFlash_AutoDetect: Boolean;
Begin
  CTFlash_AutoDetect := False;
  If CTFlashPort=0 Then
    Begin
      LogWrite('CTFlash: autodetecting...');
      CTFlashPort := $200;
      While CTFlashPort<$400 Do
        Begin
          If Port[CTFlashPort] And $C7=$80 Then
            Begin
              Port[CTFlashPort] := 0;
              If Port[CTFlashPort] And $C7=$80 Then Break;
            End;
          CTFlashPort := CTFlashPort+4;
        End;
    End;
  If Port[CTFlashPort] And $C7<>$80 Then Exit;
  CTFlashBase := $C0000+LongInt(Port[CTFlashPort]) And $38 shl 11;
  LogWrite('CTFlash: present at '+Hw(CTFlashPort)+', base '+Hl(CTFlashBase));
  ROMBase := CTFlashBase;
  Flash_Read := @FIMemB_Flash_CTFlash;
  Flash_Write := @FOMemB_Flash_CTFlash;
  Flash_ReadBlock := @MoveLinBlock_From_Flash_D_CTFlash;
  Flash_WriteBlock := @MoveLinBlock_To_Flash_B_CTFlash;
  Flash_Compare := @CompLinBlocks_Flash_CTFlash;
  CTFlash_AutoDetect := True;
End;

{Begin}
End.
