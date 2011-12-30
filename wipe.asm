; simple three pass rm for FreeBSD i386, same method as rm -P
; nasm -f elf wipe.asm ; ld -s -o wipe wipe.o

section .data

fsize dd 0
asize dd 0
fname dd 0
count db 0

section .bss

        buffersize equ 8192
        buffer resb buffersize

section .text
global _start

_start:

        pop     eax             ; arg count
        pop     eax             ; program name
        pop     ecx             ; file to wipe
        jecxz   .sparms
        pop     eax
        or      eax,eax         ; too many args?
        jne     .sparms

        push    dword 2         ; read/write
	push    ecx                                                                    
        mov     eax,5           ; open  
        push    eax  
        int     0x80
        jc      .fail

        mov     ebp,eax
        mov     [fname],ecx

        push    dword 2         ; move to eof
        push    dword 0
        push    dword 0
        push    ebp
        mov     eax,478         ; lseek
        push    eax
        int     0x80
        jc      .fail
        mov     [fsize],eax
        mov     [asize],eax

        push    dword 0         ; move to sof
        push    dword 0
        push    dword 0
        push    ebp
        mov     eax,478         ; lseek
        push    eax
        int     0x80
        jc      .fail
        mov     dword [count],0 ; zero our counter
        call    .filledz
        jmp     .loopy

.fail:
        push    dword 5
        push    dword logo2
        push    dword 1
        mov     eax,4           ; write
        push    eax
        int     0x80
        mov     eax,1           ; exit
        push    eax
        int     0x80

.sparms:
        push    dword 21
        push    dword logo
        push    dword 1         ; stdout
        mov     eax,4           ; write
        push    eax
        int     0x80
        mov     eax,1           ; exit
        push    eax
        int     0x80

.loopy:
        push    dword 5
        push    dword 8192
        push    dword buffer
        push    ebp
        mov     eax,4           ; write
        push    eax
        int     0x80
        test    eax,eax         ; test for eax -1 instead of carry
        js      .fail

        push    ebp
        mov     eax,95
        push    eax
        int     0x80
        test    eax,eax
        js      .fail

        push    dword 0         ; move to sof
        push    dword 0
        push    dword 0
        push    ebp
        mov     eax,478         ; lseek
        push    eax
        int     0x80

        mov     ecx,[fsize]     ; subtract what we wrote from the org fsize
        sub     ecx,8192  
        test    ecx,ecx
        js      .endpass

        mov     [fsize],ecx
        jmp     .loopy

.endpass:
        inc     dword [count]
        cmp     dword [count],1
        je      .filledo
        cmp     dword [count],2
        je      .passtwo
        cmp     dword [count],3
        je      .endloop
        jmp     .loopy

.passtwo:
        call    .filledz
        jmp     .loopy
.filledz:             
        mov     ecx,buffersize                                                             
        mov     esi,buffer                                                                          
        mov     edi,esi                                                                             
.zeros:
        lodsb
        xor     al,al
        stosb                   ; fill buffer with 0x00
        loop    .zeros
        ret

.filledo:             
        mov     ecx,buffersize                                                             
        mov     esi,buffer                                                                          
        mov     edi,esi                                                                             
.ones:
        lodsb
        mov     al,0xff
        stosb                   ; fill buffer with 0xff
        loop    .ones
        jmp     .loopy

.endloop:
        push    ebp
        mov     eax,6           ; close
        push    eax
        int     0x80

        mov     eax,[fname]
        push    eax
        mov     eax,10          ; unlink
        push    eax
        int     0x80

        mov     eax,1           ; exit
        push    eax
        int     0x80


logo db 'usage: wipe filename', 0x0a
logo2 db 'fail', 0x0a
