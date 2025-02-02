TESTPC  SEGMENT
	ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 	ORG 100H
START:  JMP BEGIN

AVAILABLE_MEMORY DB 'Amount of available memory: ', '$'
EXTENDED_MEMORY DB 'Extended memory size: ', '$'
STRING_BYTE DB ' byte ', '$'
MCB_TABLE DB 'MCB table: ', 0DH, 0AH, '$'
ADDRESS DB 'Address:     ', '$'
PSP_ADDRESS DB 'PSP address:      ', '$'
STRING_SIZE DB 'Size: ', '$'
SC_SD DB 'SC/SD: ', '$'
NEW_STRING DB 0DH,0AH,'$'
SPACE_STRING DB ' ', '$'



; ���������
;-----------------------------------------------------
TETR_TO_HEX PROC near 
	and AL,0Fh
	cmp AL,09
	jbe NEXT
	add AL,07
NEXT: add AL,30h
	ret
TETR_TO_HEX ENDP

;-------------------------------
BYTE_TO_HEX PROC near
; ���� � AL ����������� � ��� ������� ����. ����� � AX
	push CX
	mov AH,AL
	call TETR_TO_HEX
	xchg AL,AH
	mov CL,4
	shr AL,CL
	call TETR_TO_HEX ; � AL ������� �����
	pop CX ; � AH ������� �����
	ret
BYTE_TO_HEX ENDP

;-------------------------------
WRD_TO_HEX PROC near
; ������� � 16 �/� 16-�� ���������� �����
; � AX - �����, DI - ����� ���������� �������
	push BX
	mov BH,AH
	call BYTE_TO_HEX
 	mov [DI],AH
 	dec DI
 	mov [DI],AL
	dec DI
 	mov AL,BH
 	call BYTE_TO_HEX
	mov [DI],AH
 	dec DI
 	mov [DI],AL
 	pop BX
	ret
WRD_TO_HEX ENDP

;--------------------------------------------------
BYTE_TO_DEC PROC near
; ������� � 10 �/�, SI - ����� ���� ������� �����
 	push CX
 	push DX
 	xor AH,AH
 	xor DX,DX
 	mov CX,10

loop_bd:div CX
 	or DL,30h
 	mov [SI],DL
 	dec SI
 	xor DX,DX
 	cmp AX,10
 	jae loop_bd
	cmp AL,00h
 	je end_l
 	or AL,30h
 	mov [SI],AL

end_l:  
	pop DX
 	pop CX
 	ret
BYTE_TO_DEC ENDP

PRINT_STRING PROC near
	push ax
   	mov ah, 09h
   	int 21h
	pop ax
   	ret
PRINT_STRING endp


PARAGRAPH_TO_BYTE PROC
	mov bx, 0ah
	xor cx, cx

division_loop:
	div bx
	push dx
	inc cx
	sub dx, dx
	cmp ax, 0h
	jne division_loop

print:
	pop dx			
	add dl,30h		
	mov ah,02h
	int 21h
			
	loop print
	ret
PARAGRAPH_TO_BYTE endp

MEMORY_AVAILABLE PROC near
	mov dx, offset AVAILABLE_MEMORY
	call PRINT_STRING
	mov ah, 4ah
	mov bx, 0ffffh 
	int 21h        
	mov ax, bx
	mov bx, 16
	mul bx		
	call PARAGRAPH_TO_BYTE

	mov dx, offset STRING_BYTE
	call PRINT_STRING

	mov dx, offset NEW_STRING
	call PRINT_STRING
	ret
MEMORY_AVAILABLE endp


MEMORY_EXTENDED proc near
    	mov al, 30h
    	out 70h, al
    	in al, 71h
   	mov al, 31h
    	out 70h, al
    	in al, 71h
    	mov ah, al		
	mov bh, al
	mov ax, bx	
	
	mov dx, offset EXTENDED_MEMORY
	call PRINT_STRING

	mov bx, 010h
	mul bx			

	call PARAGRAPH_TO_BYTE 

	mov dx, offset STRING_BYTE
	call PRINT_STRING

	mov dx, offset NEW_STRING
	call PRINT_STRING
	ret
MEMORY_EXTENDED endp

MCB PROC near
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	mov dx, offset MCB_TABLE
	call PRINT_STRING

MCB_loop:
    	mov ax, es                 
    	mov di, offset ADDRESS
    	add di, 12
    	call WRD_TO_HEX
    	mov dx, offset ADDRESS
    	call PRINT_STRING
	mov dx, offset SPACE_STRING
	call PRINT_STRING

	mov ax, es:[1]   ;PSP
	mov di, offset PSP_ADDRESS
	add di, 16
	call WRD_TO_HEX
	mov dx, offset PSP_ADDRESS
	call PRINT_STRING

	mov dx, offset STRING_SIZE  
	call PRINT_STRING	
	mov ax, es:[3] 
	mov di, offset STRING_SIZE 
	add di, 6
	mov bx, 16
	mul bx
	call PARAGRAPH_TO_BYTE 
	mov dx, offset SPACE_STRING
	call PRINT_STRING

	mov bx, 8         ;SC/SD
	mov dx, offset SC_SD
	call PRINT_STRING
	mov cx, 7

SC_SD_loop:
	mov dl, es:[bx]
	mov ah, 02h
	int 21h
	inc bx
	loop SC_SD_loop
	
	mov dx, offset NEW_STRING 
 	call PRINT_STRING
	
	mov bx, es:[3h]
	mov al, es:[0h]
	cmp al, 5ah
	je MCB_END

	mov ax, es
	inc ax
	add ax, bx
	mov es, ax
	jmp MCB_loop

MCB_END:
	ret
MCB endp

BEGIN:
	call MEMORY_AVAILABLE
	call MEMORY_EXTENDED
	call MCB
	xor al, al
    	mov ah, 4ch
    	int 21h

TESTPC ENDS
END START