code segment
assume cs:code, ds:data, ss:astack

interrupt proc far
jmp start
psp dw 0
keep_ip dw 0
keep_cs dw 0
keep_ss dw 0
keep_sp dw 0
keep_ax dw 0
key_sym db 0
int_id dw 07777
int_stack db 50 dup(" ")
start:

mov keep_ax, ax
mov ax, ss
mov keep_ss, ax
mov keep_sp, sp
mov ax, seg int_stack
mov ss, ax
mov sp, offset start

push ax
push bx
push cx
push dx

in al, 60h
cmp al, 2ah ;shift
je shift
cmp al, 1dh;ctrl 
je ctrl
cmp al, 2ch; z
je z
call dword ptr cs:keep_ip
jmp exit_int

shift:
mov key_sym, 's'
jmp next_key
ctrl:
mov key_sym, 'c'
jmp next_key
z:
mov key_sym, 'O'

next_key:
in al, 61h
mov ah, al
or al, 80h
out 61h, al
xchg al, al
out 61h, al
mov al, 20h
out 20h, al

print_key:
mov ah, 05h
mov cl, key_sym
mov ch, 00h
int 16h
or al, al
jz exit_int
mov ax, 40h
mov es, ax
mov ax, es:[1ah]
mov es:[1ch], ax
jmp print_key

exit_int:	
pop dx
pop cx
pop bx
pop ax

mov sp, keep_sp
mov ax, keep_ss
mov ss, ax
mov ax, keep_ax
mov al, 20h
out 20h, al
iret

last_byte:

interrupt endp

is_int_installed proc near
push ax
push bx
push dx
push si

mov int_installed, 1
mov ah, 35h
mov al, 09h
int 21h
mov si, offset int_id
sub si, offset interrupt
mov dx, es:[bx+si]
cmp dx, 07777
je loaded
mov int_installed, 0

loaded: 
pop si
pop dx
pop bx
pop ax
ret
is_int_installed endp

install_int proc near
push ds
push es
push ax
push bx
push cx
push dx

mov ah, 35h
mov al, 09h
int 21h
mov keep_ip, bx
mov keep_cs, es

mov dx, offset interrupt
mov ax, seg interrupt
mov ds, ax
mov ah, 25h
mov al, 09h
int 21h

;сохраняем наше прерывание до last_byte
mov dx, offset last_byte
mov cl,4
shr dx,cl
inc dx
mov ax, cs
sub ax, psp
add dx, ax
xor ax, ax
mov ah,31h
int 21h

pop dx
pop cx
pop bx
pop ax
pop es
pop ds
ret
install_int endp

uninstall_int proc near
push ds
push es
push ax
push bx
push dx

cli
mov ah,35h
mov al,09h
int 21h
mov dx, es:[offset keep_ip]
mov ax, es:[offset keep_cs]
mov ds, ax
mov ah, 25h
mov al, 09h
int 21h

mov ax, es:[offset psp]
mov es, ax
mov dx, es:[2ch]
mov ah, 49h
int 21h
mov es, dx
mov ah, 49h
int 21h
sti

pop dx
pop bx
pop ax
pop es
pop ds
ret
uninstall_int endp

check_console proc near
push ax	

mov int_installed, 0
mov al, es:[82h]
cmp al, '/'
jne no_key
mov al, es:[83h]
cmp al, 'u'
jne no_key
mov al, es:[84h]
cmp al, 'n'
jne no_key
mov int_installed, 1	

no_key: 
pop     ax
ret
check_console endp

print proc near
push ax
mov ah, 09h
int 21h
pop ax
ret
print endp

main proc far
push ds
xor ax, ax
mov ax, data
mov ds, ax

mov psp, es
call check_console

cmp int_installed, 1
je int_unload

call is_int_installed
cmp int_installed, 0
je int_load
mov dx, offset already_loaded_message
call print
jmp exit

int_load:  
mov dx, offset loaded_message
call print
call install_int
jmp exit

int_unload:     
call is_int_installed
cmp int_installed, 0
je unloaded
call uninstall_int
unloaded:
mov dx, offset unloaded_message
call print

exit:    
pop ds
mov ah, 4ch
int 21h
main endp
code ends

astack segment stack
dw 128 dup(?)
astack ends

data segment
int_installed			   db 0
loaded_message		   db 'Interrupt loaded',0dh,0ah,'$'
unloaded_message	   db 'Interrupt unloaded',0dh,0ah,'$'
already_loaded_message db 'Interrupt already loaded',0dh,0ah,'$'
data ends
end main