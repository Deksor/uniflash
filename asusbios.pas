unit AsusBios; { Unit to use Asus flash interface when exists } {v1.39}

interface
function AsusCheckFor: Boolean;

procedure AsusEnable;
procedure AsusDisable;

implementation
uses Tools;
const Sign: array[1..10] of Char='ASUS_FLASH';

type AsusBIOSHook=record
  Sign: array[1..16] of Char;
  X: Word; {???}
  Disable: Procedure;
  Len: Word;
  Enable: Procedure;
end;

var Hook: ^AsusBIOSHook;

function AsusCheckFor: Boolean;
var A: Word;
type Array10= array[1..10] of Char;
begin
 AsusCheckFor:=False;
 {search for signature in $F000 segment}
 for A:=$0 to $FFFF-SizeOf(Sign) do
  begin
    Hook:=Ptr($F000, A);
    if Copy(Hook^.Sign, 1, Length(Sign))=Sign then
     begin
       AsusCheckFor:=True;
       Break;
     end;
  end;
end;

procedure AsusEnable;
begin
  Hook^.Enable;
  LogWrite('Asus flash interface - flash enable');
end;

procedure AsusDisable;
begin
  Hook^.Disable;
  LogWrite('Asus flash interface - flash disable');
end;

{begin}
end.