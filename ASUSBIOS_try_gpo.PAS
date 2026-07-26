unit AsusBios; { Unit to use Asus flash interface when exists } {v1.39}

interface
function AsusCheckFor: Boolean;

procedure AsusEnable;
procedure AsusDisable;
{procedure Asus_GPO;  }

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

procedure AsusEnable; Assembler;

{begin
  Hook^.Enable;
  LogWrite('Asus flash interface - flash enable');
end;}
asm
{push    cs
   push offset @@return
   push 0F000h
   push 0F711h
   retf
@@return:
nop
   end;}
                mov     dx, 0E400h
                add     dx, 2Ch
                in      al, dx
                and     al, 0FEh
                out     dx, al


@@try_GPO:
                mov     al, 80h
                mov     ah, 8
                xor     bl, bl

@@set_GPO:
                mov     dx, 0E803h
                out     dx, al
                mov     dl, 4
                mov     al, 91h
                out     dx, al
                xor     dl, dl
                mov     al, 0FFh
                out     dx, al
                mov     dl, 2
                mov     al, 48h
                out     dx, al
                xor     dl, dl
                xor     cx, cx
@@wait_1:
                push    ax
                push    cx
                mov     cx, 0CCh
@@wait_00:
                in      al, 61h
                test    al, 10h
                jz      @@wait_00
@@wait_01:
                in      al, 61h
                test    al, 10h
                jnz     @@wait_01
                loop    @@wait_00
                pop     cx
                pop     ax

                in      al, dx
                test    al, 6
                jnz     @@test_set_GPO
                loop    @@wait_1
@@test_set_GPO:
                test    al, 2
                jz      @@set_GPO
                mov     dl, 5
                in      al, dx
                or      al, ah
                test    bl, 1
                jnz     @@test_1
                not     ah
                and     al, ah
@@test_1:
                mov     dl, 5
                out     dx, al
                and     ch, 0FEh
                mov     dl, 4
                mov     al, 90h
                out     dx, al
                xor     dl, dl
                mov     al, 0FFh
                out     dx, al
                mov     dl, 2
                mov     al, 48h
                out     dx, al
                xor     dl, dl
                xor     cx, cx
@@wait_2:
                push    ax
                push    cx
                mov     cx, 0CCh
@@wait_00_:
                in      al, 61h
                test    al, 10h
                jz      @@wait_00_
@@wait_01_:
                in      al, 61h
                test    al, 10h
                jnz     @@wait_01_
                loop    @@wait_00_
                pop     cx
                pop     ax

                in      al, dx
                test    al, 6
                jnz     @@exit_set_GPO
                loop    @@wait_2
@@exit_set_GPO:

                test    al, 2
                jz      @@try_GPO
                xor     cx, cx
@@ending_wait:
                out     0E1h, al
                loop    @@ending_wait


end;

procedure AsusDisable;
begin
  Hook^.Disable;
  LogWrite('Asus flash interface - flash disable');
end;


Function IPortD( Prt : Word ) : LongInt; Assembler;
Asm
 MOV    DX,Prt
 DB     66H
 IN     AX,DX
 DB     66H
 MOV    DX,AX
 DB     66H
 SHR    DX,16
End;


{
procedure Asus_GPO; Assembler;
asm
                mov     dx, 0E400h
                add     dx, 2Ch
                in      al, dx
                and     al, 0FEh
                out     dx, al

@@try_GPO:
                mov     al, 80h
                mov     ah, 8
                xor     bl, bl

@@set_GPO:
                mov     dx, 0E803h
                out     dx, al
                mov     dl, 4
                mov     al, 91h
                out     dx, al
                xor     dl, dl
                mov     al, 0FFh
                out     dx, al
                mov     dl, 2
                mov     al, 48h
                out     dx, al
                xor     dl, dl
                xor     cx, cx
@@wait_1:
                push    ax
                push    cx
                mov     cx, 0CCh
@@wait_00:
                in      al, 61h
                test    al, 10h
                jz      @@wait_00
@@wait_01:
                in      al, 61h
                test    al, 10h
                jnz     @@wait_01
                loop    @@wait_00
                pop     cx
                pop     ax

                in      al, dx
                test    al, 6
                jnz     @@test_set_GPO
                loop    @@wait_1
@@test_set_GPO:
                test    al, 2
                jz      @@set_GPO
                mov     dl, 5
                in      al, dx
                or      al, ah
                test    bl, 1
                jnz     @@test_1
                not     ah
                and     al, ah
@@test_1:
                mov     dl, 5
                out     dx, al
                and     ch, 0FEh
                mov     dl, 4
                mov     al, 90h
                out     dx, al
                xor     dl, dl
                mov     al, 0FFh
                out     dx, al
                mov     dl, 2
                mov     al, 48h
                out     dx, al
                xor     dl, dl
                xor     cx, cx
@@wait_2:
                push    ax
                push    cx
                mov     cx, 0CCh
@@wait_00_:
                in      al, 61h
                test    al, 10h
                jz      @@wait_00
@@wait_01_:
                in      al, 61h
                test    al, 10h
                jnz     @@wait_01
                loop    @@wait_00
                pop     cx
                pop     ax

                in      al, dx
                test    al, 6
                jnz     @@exit_set_GPO
                loop    @@wait_2
@@exit_set_GPO:

                test    al, 2
                jz      @@try_GPO
                xor     cx, cx
@@ending_wait:
                out     0E1h, al
                loop    @@ending_wait




                mov     eax, 80000070h
                mov     dx, 0CF8h
                out     dx, eax
                mov     dl, 0FDh
                in      al, dx
                and     al, 0BFh
                out     dx, al
                mov     eax, 80002040h
                mov     dx, 0CF8h
                out     dx, eax
                mov     dl, 0FCh
                in      eax, dx
                or      eax, 0F0000001h
                out     dx, eax
end;                                }


{begin}
end.
