; crackme to learn the logic instead of nopping your way through

; user needs to enter the pid of the binary and the date in seconds
; since unix epoch to get the correct result

echo   equ 1<<3
icanon equ 1<<1

section .data
  banner    db   'enter password: '
  bannln    equ  $ - banner
  correct   db   0xa,0xa,'password is correct!',0xa
  correntln equ  $ - correct
  failure   db   0xa,0xa,'password is incorrect!',0xa
  failureln equ  $ - failure
  lookup    db   '0123456789'
  cpuinfo   db   '/proc/cpuinfo',0
  fname     dd   0

section .bss
  cpudata resb  80
  s1leng  resb  10
  s2leng  resb  10
  userin  resb  228
  concat  resb  256
  keybuf  resb  2
  termio  resb  36
  pid     resb  10
  time    resb  16

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

    mov  eax, 20			; sys_getpid
    int  0x80

    mov  ebx, 10
    xor  ecx, ecx

next_digit:				; convert pid int to ascii
    xor  edx, edx
    div  ebx
    push dx
    inc  cx
    test eax, eax
    jnz  next_digit
    lea  edi, [pid]
    mov  [s1leng], cx 
popascii:
    pop  ax
    add  al, '0'
    mov  [edi], al
    inc  edi
    loop popascii

    mov  eax, 26			; sys_ptrace
    xor  ebx, ebx
    xor  ecx, ecx
    mov  edx, 1
    int  0x80
    test eax, eax			; bail and rm if debugged
    jns  nobug
    jmp  bai 
nobug:

    mov  eax, 13			; sys_time
    mov  ebx, [time]
    int  0x80

    mov  ebx, 10
    xor  ecx, ecx

next_digit2:				; convert time int to ascii
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
    je   not_same                       ; if qemu 

    mov  esi, userin
    call getstrlen			; get len of user input
    cmp  ecx, 0
    je   not_same			; exit if no input
    push ecx

    mov  esi, pid 
    mov  edi, concat
    mov  cx, [s1leng]
    cld
    rep  movsb				; copy pid string to new variable

    mov  esi, time
    xor  ecx, ecx
    mov  cx, [s2leng]
    cld
    rep  movsb

    mov  esi, concat
    call getstrlen
    pop  edx
    cmp  ecx, edx
    jne  not_same
    mov  ecx, edx
    xor  edx, edx
    mov  esi, userin
    mov  edi, concat 

loop2:					; compare string to passwd
    cmp  ecx, edx
    je   finished
    mov  al, [esi]
    mov  bl, [edi]
    cmp  al, bl
    jne  not_same
    inc  esi
    inc  edi
    inc  edx
    jmp  loop2

finished:
    mov  eax, 4				; sys_write
    mov  ebx, 1
    mov  ecx, correct
    mov  edx, correntln
    int  0x80
    mov  eax, 1				; sys_exit
    int  0x80

not_same:
    mov  eax, 4				; sys_write
    mov  ebx, 1
    mov  ecx, failure
    mov  edx, failureln
    int  0x80
exit:
    mov  eax, 1				; sys_exit
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

getstrlen:
    mov  ecx, 0
loop:                                   ; get string length from buffer
    lodsb
    or   al, al
    jz   done
    inc  ecx
    jmp  loop
done:
    ret

bai:
    mov  eax, 10
    mov  ebx, [fname]
    int  0x80
    mov  eax, 1
    int  0x80
