; simple "secure" three pass rm

; nasm -f elf wp.asm
; ld -m elf_i386 -s -o wp wp.o

; need to write support for multiple files and directories 

section .data
 fsize     dd 0
 asize     dd 0
 files     dd 0
 
section .bss

 buffersize equ 8192
 buffer resb buffersize

section .text
global _start

 parms   db "Wiper v0.1",0xa
         db "usage: wp filename",0xa
 failure db "Failed",0xa

_start:
        pop     ecx
        cmp     ecx,2
        jne     sparms                  ; make sure there are 2 args

        pop     ebx                     ; program name
        pop     ebx                     ; first argument
        cmp     word [ebx], "-h"
        je      sparms
        cmp     word [ebx], "--"        ; common quest for help
        je      sparms
        push    ebx                     ; sys_unlink wants ascii filename
                                        ; throw it on the stack for later
        mov     eax,5                   ; sys_open
        xor     cx,cx
        mov     cl,2			; rw access
        xor     edx,edx
        int     0x80
        test    eax,eax                 ; test for eax -1 (linux cf)
        js      failed

        mov     ebx,eax
        mov     [files],ebx             ; save input file descriptor 

        mov     eax,19                  ; sys_lseek
        xor     ecx,ecx
        mov     edx,2                   ; end of file
        int     0x80

        mov     [fsize],eax             ; save input file size twice
        mov     [asize],eax

        mov     eax,19                  ; sys_lseek
        cdq           
        xor     ecx,ecx                 ; start of file
        int     0x80
        jmp     overwrite

sparms:
        mov     eax,4                   ; sys_write
        mov     ebx,1
        mov     ecx,parms
        mov     edx,31
        int     0x80                    ; show params
        mov     eax,1                   ; sys_exit
        int     0x80

failed:
        mov     eax,4                   ; sys_write
        mov     ebx,1                              
        mov     ecx,failure             ; ambiguous error message
        mov     edx,7
        int     0x80
        mov     eax,1                   ; sys_exit
        int     0x80

overwrite:
        call    filledz                 ; fill buffer with 0x00                            
        call    loopy                   ; overwrite the file
        mov     ecx,[asize]
        mov     [fsize],ecx             ; restore file size
        call    filledo                 ; fill buffer with 0xff
        call    loopy                   ; overwrite the file
        mov     ecx,[asize]
        mov     [fsize],ecx             ; restore file size
        call    filledz                 ; fill buffer with 0x00
        call    loopy                   ; overwrite the file

        mov     eax,6                   ; sys_close                                            
        mov     ebx,[files]                                                                
        int     0x80                                                                       

        mov     eax,10                  ; sys_unlink
        pop     ebx                     ; get ascii filename
        int     0x80

        mov     eax,1                   ; sys_exit                                         
        int     0x80                                

loopy:
        mov     eax,4                   ; sys_write
        mov     ebx,[files]                        
        mov     ecx,buffer 
        mov     edx,8192  
        int     0x80
        test    eax,eax                 ; test for eax -1 instead of carry
        js      failed
        mov     eax,118                 ; sys_fsync
        int     0x80                               
        test    eax,eax
        js      failed
        
        mov     ecx,[fsize]             ; subtract what we wrote from the
        sub     ecx,8192                ; original filesize
        cmp     ecx,0   
        jle     endloop
        mov     [fsize],ecx
        jmp     loopy

filledz:             
        mov     ecx,buffersize                                                             
        mov     esi,buffer                                                                          
        mov     edi,esi                                                                             
zeros:
        lodsb
        xor     al,al
        stosb                           ; fill buffer with 0x00
        loop    zeros
endloop:
        ret

filledo:             
        mov     ecx,buffersize                                                             
        mov     esi,buffer                                                                          
        mov     edi,esi                                                                             
ones:
        lodsb
        mov     al,0xff
        stosb                           ; fill buffer with 0xff
        loop    ones
        ret
