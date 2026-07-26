unit DMI; { Unit to read SMBIOS/DMI info } {v1.39}

interface
var DMI_Board:record
  Vendor, Name, Version: String;
end;
var DMI_Board_String: String;
var DMI_BIOS:record
  Vendor, Version, Release: String;
end;
var DMI_System:record
  Vendor, Name, Version, SerialNo: String;
end;

function DMI_Info:Boolean;

implementation
uses Crt, Tools;

function StrLen(Str: PChar): Word; assembler;
asm
  CLD
  LES    DI,Str
  MOV    CX,0FFFFH
  XOR    AL,AL
  REPNE  SCASB
  MOV    AX,0FFFEH
  SUB    AX,CX
end;

function StrPas(Str: PChar): String; assembler;
asm
   PUSH  DS
   CLD
   LES   DI,Str
   MOV   CX,0FFFFH
   XOR   AL,AL
   REPNE SCASB
   NOT   CX
   DEC   CX
   LDS   SI,Str
   LES   DI,@Result
   MOV   AL,CL
   STOSB
   REP   MOVSB
   POP   DS
end;

const DMI_Signature='_DMI_';

type DMI_Sign=record
  Sign:   array[1..5] of Char;
  Chksum: Byte;
  Len:    Word;
  Base:   LongInt;
  Num:    Word;
  Ver:    Byte;
end;

type DMI_Header=record
  Type_: Byte;
  Len: Byte;
  Handle: Word;
end;

type ByteArray=array[0..14] of Byte;
type DMIHeadPtr=^DMI_Header;
type PByteArray=^ByteArray;

function NoSpaces(S:String): String;
begin
  while S[Length(S)]=' ' do Delete(S,Length(S),1);
  NoSpaces:=S;
end;

function DMI_String(Head:DMIHeadPtr; S:Byte): String;
begin
  Head:=Pointer(LongInt(Head)+Head^.Len);
  if S=0 then begin DMI_String:=''; Exit; end;
  Dec(S);
  while (S>0) and (Byte(Pointer(Head^))<>0) do
   begin
     Head:=Pointer(LongInt(Head)+StrLen(PChar(Head))+1);
     Dec(S);
   end;
  DMI_String:=StrPas(PChar(Head));
end;

procedure DMI_Decode(Head: DMIHeadPtr);
var Data:PByteArray;
begin
  Data:=Pointer(Head);
  case Head^.Type_ of
   0: begin
        DMI_BIOS.Vendor:= NoSpaces(DMI_String(Head, Data^[4]));
        DMI_BIOS.Version:=NoSpaces(DMI_String(Head, Data^[5]));
        DMI_BIOS.Release:=NoSpaces(DMI_String(Head, Data^[8]));
      end;
   1: begin
        DMI_System.Vendor:=  NoSpaces(DMI_String(Head, Data^[4]));
        DMI_System.Name:=    NoSpaces(DMI_String(Head, Data^[5]));
        DMI_System.Version:= NoSpaces(DMI_String(Head, Data^[6]));
        DMI_System.SerialNo:=NoSpaces(DMI_String(Head, Data^[7]));
      end;
   2: begin
        DMI_Board.Vendor:= NoSpaces(DMI_String(Head, Data^[4]));
        DMI_Board.Name:=   NoSpaces(DMI_String(Head, Data^[5]));
        DMI_Board.Version:=NoSpaces(DMI_String(Head, Data^[6]));
      end;
  end;
end;

procedure DMI_Table(Base: Word; Len, Num: Word);
var Buf: PByteArray;
    Off, I: Word;
    Head: DMIHeadPtr;
begin
  Off := 0;
  i := 0;
  while (i < Num) and (Off+SizeOf(DMI_Header) <= Len) do
   begin
     Head:=Ptr($F000, Base+Off);
     Off:=Off+Head^.Len;
     Buf:=Ptr($F000, Base+Off);
     while (Off < Len-1) and ((Buf^[0] <> 0) or (Buf^[1] <> 0)) do
      begin
        Inc(Off);
        Buf:=Ptr($F000, Base+Off);
      end;
     if Off<Len-1 then DMI_Decode(Head);
     Inc(Off,2);
     Inc(i);
   end;
end;

function DMI_Checksum(var Buf):Byte;
var Sum, i: Byte;
begin
  Sum:=0;
  {$R-}
  for i:=0 to 14 do Sum:=Sum+ByteArray(Buf)[i];
  {$R+}
  DMI_Checksum:=Sum;
end;

function DMI_Info: Boolean;
var Off: Word;
    DMISign: ^DMI_Sign;
begin
  Off := 0;
  while Off<$FFF0 do
   begin
     DMISign:=Ptr($F000, Off);
     if (DMISign^.Sign=DMI_Signature) and (DMI_Checksum(DMISign^)=0) then
      begin
        DMI_Table(Word(DMISign^.Base), DMISign^.Len, DMISign^.Num);
        DMI_Board_String:=DMI_Board.Name;
        if DMI_Board.Vendor<>'' then DMI_Board_String:=DMI_Board.Vendor+' '+DMI_Board_String;
        if DMI_Board.Version<>'' then DMI_Board_String:=DMI_Board_String+' '+DMI_Board.Version;
        GotoXY(81-Length(DMI_Board_String),24);
        Write(DMI_Board_String);
        if DMISign^.Ver <> 0 then
         LogWrite('Found DMI '+IntToStr(DMISign^.Ver shr 4)+'.'+IntToStr(DMISign^.Ver and $0F)
          +' board info: '+DMI_Board_String)
        else LogWrite('Found DMI board info: '+DMI_Board_String);
        DMI_Info:=True;
        Exit;
      end;
     Off:=Off+16;
   end;
  LogWrite('DMI not found');
  DMI_Info:=False;
end;

{begin}
end.