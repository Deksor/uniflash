unit Award; { Unit to use Award flash interface when exists } {v1.42re}

interface
Function Byte2Hex(B:Byte):String;
function AwardCheckFor: Boolean;

procedure call_F000_sub (Sub_F000_Off : Word);


procedure KBC_12V_Control;
procedure Ct_ROM_Write_Enable;
procedure Ct_ROM_Write_Disable;
procedure Ct_Enable_ROM_Decode;
procedure Ct_Init;
procedure CT_Disable_ROM_Shadow;
procedure CT_Enable_ROM_Shadow;
procedure Ct_Special_REG_Save;
procedure Ct_After_Program;
procedure CT_Disable_CD_Shadow;
procedure CT_Enable_CD_Shadow;
procedure Aflash_Report_Fun;


procedure AwardEnable;
procedure AwardDisable;

implementation
uses Tools, CRT;
const Sign: array[1..10] of Char='$@AWDFLASH';

type AwardBIOSHook=record
  Sign: array[1..10] of Char;
  KBC_12V_Control: Word;
  Ct_ROM_Write_Enable: Word;
  Ct_ROM_Write_Disable: Word;
  Ct_Enable_ROM_Decode: Word;
  Ct_Init: Word;
  CT_Disable_ROM_Shadow: Word;
  CT_Enable_ROM_Shadow: Word;
  Ct_Special_REG_Save: Word;
  Ct_After_Program: Word;
  CT_Disable_CD_Shadow: Word;
  CT_Enable_CD_Shadow: Word;

  Aflash_Report_Fun: Word;
  Issue_System_or_PCI_Reset: Word;
  Switch_USB_SMI: Word;
  AMP_16_PowerOff_fun: Word;
  Check_ACPower: Word;
  Software_SMI_IO_port: Word;
end;

var Hook: ^AwardBIOSHook;

Function Byte2Hex(B:Byte):String;
Const HX:Array [0..15] of Char='0123456789ABCDEF';
Var Lo,Hi:Byte;
Begin
  Hi:=B div 16;
  Lo:=B-Hi*16;
  Byte2Hex:=HX[Hi]+HX[Lo];
End;

function AwardCheckFor: Boolean;
var A: Word;
{var BB:LongInt;}
type Array10= array[1..10] of Char;
begin
{BB := $f0000000;}
 AwardCheckFor:=False;
 {search for signature in $F000 segment}
 for A:=$0 to $FFFF-SizeOf(Sign) do
  begin
    Hook:=Ptr($F000, A);
    if Copy(Hook^.Sign, 1, Length(Sign))=Sign then
     begin
       AwardCheckFor:=True;
       Break;
     end;
  end;
end;

procedure call_F000_sub (Sub_F000_Off : Word); assembler;
asm
push cs
push offset @@return
push 0F000h
push Sub_F000_Off
retf
@@return:
nop
end;

procedure KBC_12V_Control;
begin
call_F000_sub (Hook^.KBC_12V_Control);
end;
procedure Ct_ROM_Write_Enable;
begin
call_F000_sub (Hook^.Ct_ROM_Write_Enable);
end;
procedure Ct_ROM_Write_Disable;
begin
call_F000_sub (Hook^.Ct_ROM_Write_Disable);
end;
procedure Ct_Enable_ROM_Decode;
begin
call_F000_sub (Hook^.Ct_Enable_ROM_Decode);
end;
procedure Ct_Init;
begin
call_F000_sub (Hook^.Ct_Init);
end;
procedure CT_Disable_ROM_Shadow;
begin
call_F000_sub (Hook^.CT_Disable_ROM_Shadow);
end;
procedure CT_Enable_ROM_Shadow;
begin
call_F000_sub (Hook^.CT_Enable_ROM_Shadow);
end;
procedure Ct_Special_REG_Save;
begin
call_F000_sub (Hook^.Ct_Special_REG_Save);
end;
procedure Ct_After_Program;
begin
call_F000_sub (Hook^.Ct_After_Program);
end;
procedure CT_Disable_CD_Shadow;
begin
call_F000_sub (Hook^.CT_Disable_CD_Shadow);
end;
procedure CT_Enable_CD_Shadow;
begin
call_F000_sub (Hook^.CT_Enable_CD_Shadow);
end;
procedure Aflash_Report_Fun;
begin
call_F000_sub (Hook^.Aflash_Report_Fun);
end;


procedure AwardEnable;
{Var AA:longInt;}
begin
{GotoXY(9,3);
 Writeln;
 AA:=longint(@Hook^.Ct_ROM_Write_Enable);}
 {Write(Byte2Hex(longint(@Hook^.Ct_ROM_Write_Enable)));}


Ct_Init;
Ct_Enable_ROM_Decode;
Ct_ROM_Write_Enable;
{  Hook^.CT_Disable_CD_Shadow;}
{  Hook^.CT_Disable_ROM_Shadow;}
{  Hook^.Ct_Special_REG_Save;}
  LogWrite('Award flash interface - flash enable');
end;

procedure AwardDisable;
begin
{  Hook^.CT_Enable_CD_Shadow; }
Ct_ROM_Write_Disable;
Ct_After_Program;
{  Hook^.CT_Enable_ROM_Shadow; }
  LogWrite('Award flash interface - flash disable');
end;

{begin}
end.
