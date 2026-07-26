procedure Asus;

procedure pause;
asm
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
end;

function set_GPO: byte;
asm
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
                call    pause
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
                call    pause
                in      al, dx
                test    al, 6
                jnz     @@exit_set_GPO
                loop    @@wait_2
@@exit_set_GPO:
end;

procedure Flash_Enable_W_by_GPO;
asm
                mov     dx, 0E400h
                add     dx, 2Ch
                in      al, dx
                and     al, 0FEh
                out     dx, al
{
@@try_GPO:
                mov     al, 80h
                mov     ah, 8
                xor     bl, bl
                call    set_GPO
                test    al, 2
                jz      @@try_GPO
                xor     cx, cx
@@ending_wait:
                out     0E1h, al
                loop    @@ending_wait}
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
end;

end;
