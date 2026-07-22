
Unit DMI; { Unit to read SMBIOS/DMI info } {v1.39}

Interface

Var DMI_Board: Record
  Vendor, Name, Version: String;
End;

Var DMI_Board_String: String;

Var DMI_BIOS: Record
  Vendor, Version, Release: String;
End;

Var DMI_System: Record
  Vendor, Name, Version, SerialNo: String;
End;

Function DMI_Info: Boolean;

Implementation

Uses Crt, Tools;

Type PFarChar = ^Char;
  far;

Function StrLen(Str: PFarChar): Word;
assembler;
asm
CLD
LES    DI,Str
MOV    CX,0FFFFH
XOR    AL,AL
REPNE  SCASB
MOV    AX,0FFFEH
SUB    AX,CX
End;

Function StrPas(Str: PFarChar): String;
assembler;
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
End;

Const DMI_Signature = '_DMI_';

Type DMI_Sign = Record
  Sign:   array[1..5] Of Char;
  Chksum: Byte;
  Len:    Word;
  Base:   LongInt;
  Num:    Word;
  Ver:    Byte;
End;

Type DMI_Header = Record
  Type_: Byte;
  Len: Byte;
  Handle: Word;
End;

Type ByteArray = array[0..14] Of Byte;

Type DMIHeadPtr = ^DMI_Header;
  far;

Type PByteArray = ^ByteArray;
  far;

Type PDMISign = ^DMI_Sign;
  far;

Function NoSpaces(S:String): String;
Begin
  While S[Length(S)]=' ' Do
    Delete(S,Length(S),1);
  NoSpaces := S;
End;

Function DMI_String(Head:DMIHeadPtr; S:Byte): String;
Begin
  Head := DMIHeadPtr(FarPointer(LongInt(Head)+Head^.Len));
  If S=0 Then
    Begin
      DMI_String := '';
      Exit;
    End;
  Dec(S);
  While (S>0) And (PByteArray(Head)^[0]<>0) Do
    Begin
      Head := DMIHeadPtr(FarPointer(LongInt(Head)+StrLen(PFarChar(Head))+1));
      Dec(S);
    End;
  DMI_String := StrPas(PFarChar(Head));
End;

Procedure DMI_Decode(Head: DMIHeadPtr);

Var Data: PByteArray;
Begin
  Data := PByteArray(Head);
  Case Head^.Type_ Of 
    0:
       Begin
         DMI_BIOS.Vendor := NoSpaces(DMI_String(Head, Data^[4]));
         DMI_BIOS.Version := NoSpaces(DMI_String(Head, Data^[5]));
         DMI_BIOS.Release := NoSpaces(DMI_String(Head, Data^[8]));
       End;
    1:
       Begin
         DMI_System.Vendor :=  NoSpaces(DMI_String(Head, Data^[4]));
         DMI_System.Name :=    NoSpaces(DMI_String(Head, Data^[5]));
         DMI_System.Version := NoSpaces(DMI_String(Head, Data^[6]));
         DMI_System.SerialNo := NoSpaces(DMI_String(Head, Data^[7]));
       End;
    2:
       Begin
         DMI_Board.Vendor := NoSpaces(DMI_String(Head, Data^[4]));
         DMI_Board.Name :=   NoSpaces(DMI_String(Head, Data^[5]));
         DMI_Board.Version := NoSpaces(DMI_String(Head, Data^[6]));
       End;
  End;
End;

Procedure DMI_Table(Base: Word; Len, Num: Word);

Var Buf: PByteArray;
  Off, I: Word;
  Head: DMIHeadPtr;
Begin
  Off := 0;
  i := 0;
  While (i < Num) And (Off+SizeOf(DMI_Header) <= Len) Do
    Begin
      Head := Ptr($F000, Base+Off);
      Off := Off+Head^.Len;
      Buf := Ptr($F000, Base+Off);
      While (Off < Len-1) And ((Buf^[0] <> 0) Or (Buf^[1] <> 0)) Do
        Begin
          Inc(Off);
          Buf := Ptr($F000, Base+Off);
        End;
      If Off<Len-1 Then DMI_Decode(Head);
      Inc(Off,2);
      Inc(i);
    End;
End;

Function DMI_Checksum(Var Buf): Byte;

Var Sum, i: Byte;
Begin
  Sum := 0;
  {$R-}
  For i:=0 To 14 Do
    Sum := Sum+ByteArray(Buf)[i];
  {$R+}
  DMI_Checksum := Sum;
End;

Function DMI_Info: Boolean;

Var Off: Word;
  DMISign: PDMISign;
Begin
  Off := 0;
  While Off<$FFF0 Do
    Begin
      DMISign := Ptr($F000, Off);
      If (DMISign^.Sign=DMI_Signature) And (DMI_Checksum(DMISign^)=0) Then
        Begin
          DMI_Table(Word(DMISign^.Base), DMISign^.Len, DMISign^.Num);
          DMI_Board_String := DMI_Board.Name;
          If DMI_Board.Vendor<>'' Then DMI_Board_String := DMI_Board.Vendor+' '+
                                                           DMI_Board_String;
          If DMI_Board.Version<>'' Then DMI_Board_String := DMI_Board_String+' '
                                                            +DMI_Board.Version;
          GotoXY(81-Length(DMI_Board_String),24);
          Write(DMI_Board_String);
          If DMISign^.Ver <> 0 Then
            LogWrite('Found DMI '+IntToStr(DMISign^.Ver shr 4)+'.'+IntToStr(
                                                                         DMISign
                                                                            ^.
                                                                            Ver
                                                                            And
                                                                            $0F)
            +' board info: '+DMI_Board_String)
          Else LogWrite('Found DMI board info: '+DMI_Board_String);
          DMI_Info := True;
          Exit;
        End;
      Off := Off+16;
    End;
  LogWrite('DMI not found');
  DMI_Info := False;
End;

{begin}
End.
