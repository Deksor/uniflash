Unit CT_Flash; {c't Flasher 8-bit ISA card} {v1.32}

Interface
uses Flash,Tools;
const Size512K:Boolean=False; {v1.34}
var CTFlashPort: Word;
    CTFlashBase: LongInt;

function CTFlash_AutoDetect:Boolean;
function FIMemB_Flash_CTFlash(Addr:LongInt):Byte;
procedure FOMemB_Flash_CTFlash(Addr:LongInt;Data:Byte);
procedure MoveLinBlock_From_Flash_D_CTFlash(Src,Dest,Size:LongInt);
procedure MoveLinBlock_To_Flash_B_CTFlash(Src,Dest,Size:LongInt);
function CompLinBlocks_Flash_CTFlash(Block1,Block2,Size:LongInt):Boolean;

Implementation

function FIMemB_Flash_CTFlash(Addr:LongInt):Byte;
begin
  if not Size512K then Addr:=Addr or $40000; {v1.34}
  Port[CTFlashPort]:=Addr shr 11;
  FIMemB_Flash_CTFlash:=FIMemB(CTFlashBase+Addr and $7FF);
end;

procedure FOMemB_Flash_CTFlash(Addr:LongInt;Data:Byte);
begin
  if not Size512K then Addr:=Addr or $40000; {v1.34}
  Port[CTFlashPort]:=Addr shr 11;
  FOMemB(CTFlashBase+Addr and $7FF,Data);
end;

procedure MoveLinBlock_From_Flash_D_CTFlash(Src,Dest,Size:LongInt);
var Pos:LongInt;
begin
 if not Size512K then Src:=Src or $40000; {v1.34}
 Pos:=0;
 while Pos<Size do
  begin
    Port[CTFlashPort]:=(Src+Pos) shr 11;
    if Size-Pos>=2048 then MoveLinBlockD(CTFlashBase+(Src+Pos) and $7FF,Dest+Pos,2048)
     else MoveLinBlockD(CTFlashBase+(Src+Pos) and $7FF,Dest+Pos,Size-Pos);
    Pos:=Pos+2048;
  end;
end;

procedure MoveLinBlock_To_Flash_B_CTFlash(Src,Dest,Size:LongInt);
var Pos:LongInt;
begin
 if not Size512K then Dest:=Dest or $40000; {v1.34}
 Pos:=0;
 while Pos<Size do
  begin
    Port[CTFlashPort]:=(Dest+Pos) shr 11;
    if Size-Pos>=2048 then MoveLinBlockB(Src+Pos,CTFlashBase+(Dest+Pos) and $7FF,2048)
     else MoveLinBlockB(Src+Pos,CTFlashBase+(Dest+Pos) and $7FF,Size-Pos);
    Pos:=Pos+2048;
  end;
end;

function CompLinBlocks_Flash_CTFlash(Block1,Block2,Size:LongInt):Boolean;
var OK:Boolean;
    Pos:LongInt;
begin
 if not Size512K then Block1:=Block1 or $40000; {v1.34}
 OK:=True;
 Pos:=0;
 while Pos<Size do
  begin
    Port[CTFlashPort]:=(Block1+Pos) shr 11;
    if Size-Pos>=2048 then
     begin
       if not CompLinBlocks(CTFlashBase+(Block1+Pos) and $7FF,Block2+Pos,2048) then OK:=False;
     end
    else
     begin
       if not CompLinBlocks(CTFlashBase+(Block1+Pos) and $7FF,Block2+Pos,Size-Pos) then OK:=False;
     end;
    Pos:=Pos+2048;
    if not OK then Break;
  end;
 CompLinBlocks_Flash_CTFlash:=OK;
end;

function CTFlash_AutoDetect:Boolean;
begin
  CTFlash_AutoDetect:=False;
  if CTFlashPort=0 then
   begin
     LogWrite('CTFlash: autodetecting...');
     CTFlashPort:=$200;
     while CTFlashPort<$400 do
      begin
        if Port[CTFlashPort] and $C7=$80 then
         begin
           Port[CTFlashPort]:=0;
           if Port[CTFlashPort] and $C7=$80 then Break;
         end;
        CTFlashPort:=CTFlashPort+4;
      end;
   end;
  if Port[CTFlashPort] and $C7<>$80 then Exit;
  CTFlashBase:=$C0000+LongInt(Port[CTFlashPort]) and $38 shl 11;
  LogWrite('CTFlash: present at '+Hw(CTFlashPort)+', base '+Hl(CTFlashBase));
  ROMBase:=CTFlashBase;
  Flash_Read:=FIMemB_Flash_CTFlash;
  Flash_Write:=FOMemB_Flash_CTFlash;
  Flash_ReadBlock:=MoveLinBlock_From_Flash_D_CTFlash;
  Flash_WriteBlock:=MoveLinBlock_To_Flash_B_CTFlash;
  Flash_Compare:=CompLinBlocks_Flash_CTFlash;
  CTFlash_AutoDetect:=True;
end;

{Begin}
End.