unit Phoenix; { Unit to use Phoenix flash interface when exists } {v1.43re}

interface
function PhoenixCheckFor : Boolean;

procedure Call_Platform_bin_Sub (Sub_Off : Word);

procedure Platform_Map;
procedure Platform_UnMap;
procedure Platform_Check_exit;
procedure Platform_KBC_12V_Control;

procedure PhoenixEnable;
procedure PhoenixDisable;

implementation
uses Tools, DMI;

type PhoenixPlatformHook=record
 Comment:                array[1..64] of Char;
 SignatureI:             array[1..4] of Char;
 Ver_platform_bin:       array[1..5] of Char;
 Name_of_BIOS:           array[1..9] of Char;
 x052:                   LongInt;
 Size_of_BIOS:           LongInt;
 x05A:                   LongInt;
 x05E:                   LongInt;
 x062:                   LongInt;
 Flash_Types_tbl_off:    LongInt;
 x06A:                   LongInt;
 Flash_ROM_ID_off:       LongInt;
 x072:                   LongInt;
 x076:                   LongInt;
 x07A:                   LongInt;
 Some_Version:           array[1..130] of Char;
 SignatureII:            LongInt;

{ Enable:                 Procedure;
 Disable:                Procedure;       }
 Map:                    Word;
 x106:                   Word;
 UnMap:                  Word;
 x10A:                   Word;

 x10C:                   LongInt;
 x110:                   LongInt;
 x114:                   LongInt;
 Check_exit:             Word;
 x11A:                   Word;
 x11C:                   LongInt;
 x120:                   LongInt;
 KBC_12V_Control:        Word;
 x116:                   Word;
 x128:                   LongInt;
 x12C:                   LongInt;
 x130:                   LongInt;

 buff:                   array[1..4000] of Char;
end;

var
HookPhoenix       : ^PhoenixPlatformHook;

function PhoenixCheckFor: Boolean;
var
A                 : Word;
NumRead           : Word;
ID_Platform_bin   : File{ of byte};
Platform_bin_Name : String;

begin

 PhoenixCheckFor := False;
{
 DMI_Board_String := 'XT6050';
 if (DMI_Board_String = 'XT6050') then
  begin
  Platform_bin_Name := 'XT6050.BIN';

  Assign (ID_Platform_bin, Platform_bin_Name);
  Reset  (ID_Platform_bin, 1);

  BlockRead (ID_Platform_bin, HookPhoenix, FileSize (ID_Platform_bin), NumRead);

  PhoenixCheckFor := True;
  Close  (ID_Platform_bin);
  end;
}
end;

procedure Call_Platform_bin_Sub (Sub_Off : Word); assembler;
asm
push cs
push offset @@return
pop  ax
push cs {0F000h}
push Sub_Off
pop  cx
retf
@@return:
nop
end;

procedure Platform_Map;
begin
Call_Platform_bin_Sub (HookPhoenix^.Map);
end;

procedure Platform_UnMap;
begin
Call_Platform_bin_Sub (HookPhoenix^.UnMap);
end;

procedure Platform_Check_exit;
begin
Call_Platform_bin_Sub (HookPhoenix^.Check_exit);
end;

procedure Platform_KBC_12V_Control;
begin
Call_Platform_bin_Sub (HookPhoenix^.KBC_12V_Control);
end;

procedure PhoenixEnable;
begin
Platform_Map;
{Platform_Check_exit;}
  LogWrite('Phoenix flash interface - flash enable');
end;

procedure PhoenixDisable;
begin
Platform_UnMap;
{Platform_KBC_12V_Control;}
  LogWrite('Phoenix flash interface - flash disable');
end;

{begin}
end.
