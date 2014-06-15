[BITS 16]
[ORG 0]

jmp start
	
start:  
    mov ax, 0x7c0
    mov ds, ax
    mov es, ax
    mov ax, 0x900
    mov ss, ax
    mov ax, 0x0
    mov sp, ax
    cli

    push dword 0x7c0    ; update cs:ip to 0x7c0:ip, for some machine, the default cs is 0x0
    push after_update_cs
    retf

after_update_cs:
    mov si, bootmsg
    call write_message

    sti

    ;mov ax, 0x12
    ;call print_hex
    ;call die 
    ;call taskA
    ;push cs
    ;push taskA
    ;ret

    ; set new int9
;    push es
;    push ds
;    mov ax, 0x0
;    mov ds, ax
;    mov si, 0x9*0x4
;
;    mov di, int9_origin
;    mov cx, 0x2
;    cld
;    rep movsw
;
;    pop ds
;    mov si, int9_new
;
;    mov ax, 0x0
;    mov es, ax
;    mov di, 0x9*0x4
;    mov cx, 0x2
;    cld
;    rep movsw
;    pop es

    mov [current_task], dword 0x0
    call run

die:
    jmp die

run:
    mov ax, [current_task]
    cmp ax, 0
    je run_taskA
    call run_taskB

run_taskA:
    mov bp, [taskA_context+26]
    mov di, [taskA_context+24]
    mov si, [taskA_context+22]
    mov es, [taskA_context+20]
    mov ds, [taskA_context+18]
    mov dx, [taskA_context+16]
    mov cx, [taskA_context+14]
    mov bx, [taskA_context+12]
    mov ax, [taskA_context+10]
    mov sp, [taskA_context+8]
    mov ss, [taskA_context+6]

    ;mov flag, [taskA_context+0]
    ;mov cs, [taskA_context+2]
    ;mov ip, [taskA_context+4]
    push dword [taskA_context+0]  ;flag
    popf
    push dword [taskA_context+2]  ;cs
    push dword [taskA_context+4]  ;ip
    ret


run_taskB:
    mov bp, [taskB_context+26]
    mov di, [taskB_context+24]
    mov si, [taskB_context+22]
    mov es, [taskB_context+20]
    mov ds, [taskB_context+18]
    mov dx, [taskB_context+16]
    mov cx, [taskB_context+14]
    mov bx, [taskB_context+12]
    mov ax, [taskB_context+10]
    mov sp, [taskB_context+8]
    mov ss, [taskB_context+6]

    ;mov flag, [taskB_context+0]
    ;mov cs, [taskB_context+2]
    ;mov ip, [taskB_context+4]
    push dword [taskB_context+0]  ;flag
    popf
    push dword [taskB_context+2]  ;cs
    push dword [taskB_context+4]  ;ip
    ret

taskA:
    mov si, msgA
    call write_message
    jmp taskA

taskB:
    mov si, msgB
    call write_message
    jmp taskB

int9_entry:
    mov si, msgB
    call write_message
    jmp int9_entry
    iret

; -------------------------------------------------------------
	
write_message:
    push ax
again:
    lodsb			; DS:[SI] is read to al
	cmp	al, 0x0
	jz	end_message
	mov	ah, 0x0E	; teletype Mode
	mov	bx, 0007	; white on black attribute
	int	0x10
	jmp	again
	
end_message:
    pop ax
	ret

; print the ax register
print_hex:
    mov si, msgAX
    call write_message
    
    
    push ax
    ; ah
    mov cx, 0x4
    mov bl, 12
    mov dx, 0xf000

hex_again:
    and ax, dx

    push cx
    mov cl, bl
    shr ax, cl
    pop cx

    cmp al,0xA
    jb N0_N9
NA_NF:
    add al, 0x7
N0_N9:
    add al, 0x30
	mov	ah, 0x0E	; teletype Mode
    push bx
	mov	bx, 0007	; white on black attribute
	int	0x10
    pop bx

    pop ax
    push ax

    shr dx, 4
    sub bl, 4
    loop hex_again

    pop ax
    mov si, msgNL
    call write_message
    ret
; -------------------------------------------------------------	

bootmsg     db  'start kernel...', 0xD, 0xA, 0
msgA		db	'task A is running...', 0xD, 0xA, 0
msgB		db	'task B is running...', 0xD, 0xA, 0
msgAX       db  'AX: 0X', 0
msgNL       db 0xD, 0xA, 0

; 0 - taskA; 1 - taskB
current_task    dw 0x0
int9_origin:
    dw 0    ; ip
    dw 0    ; cs
int9_new:
    dw  int9_entry  ; ip
    dw  0x7c0     ; cs

taskA_context:
    dw  0   ; flag
    dw  0x7c0   ; cs
    dw  taskA   ; ip
    dw  0x1100   ; ss   0x10000 - 0x11000
    dw  0   ; sp
    dw  0   ; ax
    dw  0   ; bx
    dw  0   ; cx
    dw  0   ; dx
    dw  0x7c0   ; ds
    dw  0   ; es
    dw  0   ; si
    dw  0   ; di
    dw  0   ; bp
			
taskB_context:
    dw  0   ; flag
    dw  0x7c0   ; cs
    dw  taskB   ; ip
    dw  0x1200  ; ss   0x11000 - 0x12000
    dw  0       ; sp
    dw  0       ; ax
    dw  0       ; bx
    dw  0       ; cx
    dw  0       ; dx
    dw  0x7c0   ; ds
    dw  0       ; es
    dw  0       ; si
    dw  0       ; di
    dw  0       ; bp

	times 510-($-$$) db 0           ;填充文件 0.
	dw 0xAA55                       ;以AA55结束.
	
	
	