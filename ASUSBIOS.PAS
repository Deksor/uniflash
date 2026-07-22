
Unit AsusBios; { Unit to use Asus flash interface when exists } {v1.39}

Interface
Function AsusCheckFor: Boolean;

Procedure AsusEnable;
Procedure AsusDisable;

Implementation

Uses Tools;

Const Sign: array[1..10] Of Char = 'ASUS_FLASH';

Type AsusBIOSHook = Record
  Sign: array[1..16] Of Char;
  X: Word; {???}
  Disable: Procedure ;
  Len: Word;
  Enable: Procedure ;
End;

Type PAsusBIOSHook = ^AsusBIOSHook;
  far;

Var Hook: PAsusBIOSHook;

Function AsusCheckFor: Boolean;

Var A: Word;

Type Array10 = array[1..10] Of Char;
Begin
  AsusCheckFor := False;
 {search for signature in $F000 segment}
  For A:=$0 To $FFFF-SizeOf(Sign) Do
    Begin
      Hook := Ptr($F000, A);
      If Copy(Hook^.Sign, 1, Length(Sign))=Sign Then
        Begin
          AsusCheckFor := True;
          Break;
        End;
    End;
End;

Procedure AsusEnable;
Begin
  Hook^.Enable;
  LogWrite('Asus flash interface - flash enable');
End;

Procedure AsusDisable;
Begin
  Hook^.Disable;
  LogWrite('Asus flash interface - flash disable');
End;

{begin}
End.
