; Writing crackme's for fun and no profit ;(

; user must input string 10317600 on june 4/5 2015
; 10317600 / 6 /4 / 20 / 15 = 1433 = first 4 digits of system clock, epoch in seconds

; hash needs to be cracked, but an encoded hint is included.

echo   equ 1<<3
icanon equ 1<<1

section .data
  banner    db   'enter password: '
  bannln    equ  $ - banner
  correct   db   0xa,0xa,'password is correct!',0xa
  correntln equ  $ - correct
  cpuinfo   db   '/proc/cpuinfo',0
  gbuffalo  db   '0bc9598336eed5be38fa81de0994dcf0',0xa				; worthless hash of 'guy on a buffalo'
  flaghash  db   0xfd,0xf6,0xfc,0xfb,0xfe,0xf9,0xfc,0xf6,0xf8,0xaa,0xab		; real encoded hash data
            db   0xab,0xf7,0xff,0xa8,0xff,0xad,0xf7,0xfd,0xfa,0xf8,0xfd		; 382507286dee91f1c934637948664137
            db   0xf9,0xf7,0xfa,0xf6,0xf8,0xf8,0xfa,0xff,0xfd,0xf9,0xc4		; rvasec2015
  hint      db   0xb9,0xa6,0xab,0xbc,0xab,0xee,0xaf,0xa3,0xee,0xa7              ; 'where am i' encoded with same key as flag hash
  failure   db   0xa,0xa,'password is incorrect!',0xa
  failureln equ  $ - failure
  fname     dd   0
  buffalo   db   0xa
            db  "                                    ___,,___",0xa
            db  "                                ,d8888888888b,_",0xa
            db  "                            _,d889'        8888b,",0xa
            db  "                        _,d8888'          8888888b,",0xa
            db  "                    _,d8889'           888888888888b,_",0xa
            db  "                _,d8889'             888888889'688888, /b",0xa
            db  "            _,d8889'               88888889'     `6888d 6,_",0xa
            db  "         ,d88886'              _d888889'           ,8d  b888b,  d\",0xa
            db  "       ,d889'888,             d8889'               8d   9888888Y  )",0xa
            db  "     ,d889'   `88,          ,d88'                 d8    `,88aa88 9",0xa
            db  "    d889'      `88,        ,88'                   `8b     )88a88'",0xa
            db  "   d88'         `88       ,88                   88 `8b,_ d888888",0xa
            db  "  d89            88,      88                  d888b  `88`_  8888",0xa
            db  "  88             88b      88                 d888888 8: (6`) 88')",0xa
            db  "  88             8888b,   88                d888aaa8888, `   'Y'",0xa
            db  "  88b          ,888888888888                 `d88aa `88888b ,d8",0xa
            db  "  `88b       ,88886 `88888888                 d88a  d8a88` `8/",0xa
            db  "   `q8b    ,88'`888  `888''`88          d8b  d8888,` 88/ 9)_6",0xa
            db  "     88  ,88'   `88  88p    `88        d88888888888bd8( Z~/",0xa
            db  "     88b 8p      88 68'      `88      88888888' `688889`",0xa
            db  "     `88 8        `8 8,       `88    888 `8888,   `qp'",0xa
            db  "       8 8,        `q 8b       `88  88'    `888b",0xa
            db  "       q8 8b        '888        `8888'",0xa
            db  "        '888                     `q88b",0xa
            db  "                                  '888'",0xa
            db  '                                                  LOLWAT',0xa	; this is a sweet ass buffalo for users who run strings

section .bss
  cpudata   resb  80
  s2leng    resb  10
  userin    resb  228
  keybuf    resb  2
  termio    resb  36
  time      resb  16
  herp      resb  20
section .text

global _start

_start:
    pop  eax
    pop  eax
    mov  [fname], eax			; save filename

    mov  eax, 4                         ; sys_write
    mov  ebx, 1
    mov  ecx, banner
    mov  edx, bannln
    int  0x80

    pop  eax				; pop first arg off stack for no reason
    cmp  eax, 4				; compare it to 4 for no reason
    je   worked				; go waste time instead of looking for the key
    mov  eax, 5                         ; sys_open
    mov  ebx, cpuinfo                   ; /proc/cpu
    mov  ecx, 0
    int  0x80

    mov  ebx, eax
    mov  eax, 3                         ; sys_read
    mov  ecx, cpudata
    mov  edx, 80
    int  0x80
                                                                                                                                                                          
    mov  al, byte[cpudata+79]
    cmp  al, 'Q'
    je   derp				; bail if qemu (vbox,xen)

    call read_term			; disable keyboard echo
    mov  eax, echo
    not  eax
    and  [termio+12], eax
    call write_term
    call read_term
    mov  eax, icanon
    not  eax
    and  [termio+12], eax
    call write_term

    xor  esi, esi
read_input:
    cmp  esi, 228
    je   endread			; end if buffer is full
    mov  eax, 3				; sys_read
    mov  ebx, 1
    mov  ecx, keybuf
    mov  edx, 1 
    int  0x80
    mov  al, byte[keybuf]
    cmp  al, 0xa
    je   endread			; end if return was pressed
    mov  byte[userin+esi], al
    inc  esi
    jmp  read_input

endread:
    call read_term			; re-enable keyboard echo
    or   dword [termio+12], echo
    call write_term
    call read_term
    or   dword [termio+12], icanon
    call write_term

    mov  eax, 26                        ; sys_ptrace
    xor  ebx, ebx
    xor  ecx, ecx
    mov  edx, 1
    int  0x80
    test eax, eax                       ; bail and rm if debugged
    jns  nobug
    jmp  bai
nobug:

    mov  eax, 13                        ; sys_time
    mov  ebx, [time]
    int  0x80

    mov  ebx, 10
    xor  ecx, ecx

next_digit2:                            ; convert time int to ascii
    xor  edx, edx
    div  ebx
    push dx
    inc  cx
    test eax, eax
    jnz  next_digit2
    lea  edi, [time]
    mov  [s2leng], cx
popascii2:
    pop  ax
    add  al, '0'
    mov  [edi], al
    inc  edi
    loop popascii2

    lea  eax, [userin]			; load up user input and do math 

    mov  esi, eax
    xor  eax, eax
    xor  ecx, ecx

.multiplyLoop:
    xor  ebx, ebx
    mov  bl, [esi+ecx]
    cmp  bl, 48
    jl   .finished
    cmp  bl, 57
    jg   .finished
    cmp  bl, 10
    je   .finished
    cmp  bl, 0
    jz   .finished

    sub  bl, 48
    add  eax, ebx
    mov  ebx, 10
    mul  ebx
    inc  ecx
    jmp  .multiplyLoop

.finished:
    mov  ebx, 10
    div  ebx

    xor  edx, edx
    mov  ecx, 15			; divied input by 15 / 20 / 6 / 4
    div  ecx
    xor  edx, edx
    mov  ecx, 20
    div  ecx
    xor  edx, edx
    mov  ecx, 6
    div  ecx
    xor  edx, edx
    mov  ecx, 4
    div  ecx
    mov  ebx, 10
    xor  ecx, ecx			;conv eax to ascii

next_digit3:
    xor  edx, edx
    div  ebx
    push dx
    inc  cx
    test eax, eax
    jnz  next_digit3
    lea  edi, [herp]
    mov  [s2leng], cx
popascii3:
    pop  ax
    add  al, '0'
    mov  [edi], al
    inc  edi
    loop popascii3

    mov  ecx, 4				; stuck at 4 digits, 5th digit changes from june 4 to 5
    xor  edx, edx
    mov  esi, herp 
    mov  edi, time 

loop2:                                  ; compare user input to first 4 of systime
    cmp  ecx, edx
    je   worked
    mov  al, [esi]
    mov  bl, [edi]
    cmp  al, bl
    jne  failed 
    inc  esi
    inc  edi
    inc  edx
    jmp  loop2

worked:
    mov  eax, 4                         ; sys_write
    mov  ebx, 1
    mov  ecx, correct
    mov  edx, correntln 
    int  0x80

    call encode 

    mov  eax, 4
    mov  ebx, 1
    mov  ecx, flaghash
    mov  edx, 33
    int  0x80
    mov  eax, ebx
    int  0x80
    mov  eax, 10			; maybe you should look at the 10 bytes
    jmp  hint				; at this offset

derp:
    mov  eax,  3			; read user input and do nothing with it
    xor  ebx,  ebx
    mov  ecx,  userin
    mov  edx,  226
    int  0x80

failed:
    mov  eax, 4                         ; sys_write
    mov  ebx, 1
    mov  ecx, failure
    mov  edx, failureln
    int  0x80
    mov  eax, ebx			; sys_exit
    int  0x80
read_term:
    mov  eax, 54			; sys_ioctl
    mov  ebx, 1
    mov  ecx, 5401h
    mov  edx, termio
    int  0x80
    ret

write_term:
    mov  eax, 54			; sys_ioctl
    mov  ebx, 1
    mov  ecx, 5402h
    mov  edx, termio
    int  0x80
    ret

bai:
    mov  eax, 10			; sys_unlink
    mov  ebx, [fname]
    int  0x80
    mov  eax, 4                         ; sys_write
    mov  ebx, 1
    mov  ecx, correct			; annoy user by telling them it's correct
    mov  edx, correntln
    int  0x80
    mov  eax, ebx 
    int  0x80
    ret					; will never hit, dont look at me

encode:
    mov  ecx,33
    mov  esi,flaghash
    mov  edi,esi
encoding:
    lodsb
    not   al
    xor   al, byte [herp]
    stosb
    loop  encoding
    ret
