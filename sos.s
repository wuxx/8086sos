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
    cli ; disable irq

    push dword 0x7c0    ; update cs:ip to 0x7c0:ip, for some machine, the default cs is 0x0
    push after_update_cs
    retf

after_update_cs:
    sti ; enable irq

    in al, 0x21   ; read from port 0x21
    call print_hex

    mov al, 0x00
    out 0x21, al

    nop
    nop
    in al, 0x21
    call print_hex

    ; set new int9
    push es
    push ds
    mov ax, 0x0
    mov ds, ax
    mov si, 0x9*0x4

    mov di, int9_origin
    mov cx, 0x2
    cld
    rep movsw	; ds:si -> es:di

    pop ds
    mov si, int9_new

    mov ax, 0x0
    mov es, ax
    mov di, 0x9*0x4
    mov cx, 0x2
    cld
    rep movsw
    pop es

;die:
;   jmp die

    jmp  run

run:
; 26 flag
; 24 cs
; 22 ip    --- cpu auto save 
; 20 ax
; 18 cx
; 16 dx
; 14 bx
; 12 sp    (the sp before pusha)
; 10 bp
;  8 si
;  6 di    --- inst pusha save
;  4 ds    --- push ds
;  2 es    --- push es
;  0 ss    --- push ss
    ; prepare taskB
    mov ss, [taskB_context +  0]
    mov es, [taskB_context +  2]
    mov ds, [taskB_context +  4]
    mov di, [taskB_context +  6]
    mov si, [taskB_context +  8]
    mov bp, [taskB_context + 10]
    mov sp, [taskB_context + 12]
    mov bx, [taskB_context + 14]
    mov dx, [taskB_context + 16]
    mov cx, [taskB_context + 18]
    mov ax, [taskB_context + 20]
    push word [taskB_context + 26]  ;flag
    push word [taskB_context + 24]  ;cs
    push word [taskB_context + 22]  ;ip
    pusha
    push ds
    push es
    push ss
    mov [next_task+0], ss
    mov [next_task+2], sp

    mov ss, [taskA_context +  0]
    mov es, [taskA_context +  2]
    mov ds, [taskA_context +  4]
    mov di, [taskA_context +  6]
    mov si, [taskA_context +  8]
    mov bp, [taskA_context + 10]
    mov sp, [taskA_context + 12]
    mov bx, [taskA_context + 14]
    mov dx, [taskA_context + 16]
    mov cx, [taskA_context + 18]
    mov ax, [taskA_context + 20]

    push word [taskA_context + 26]  ;flag
    push word [taskA_context + 24]  ;cs
    push word [taskA_context + 22]  ;ip

    mov [current_taskid], ss ; indicate taskA
    iret    ; kick the taskA

taskA:
    mov si, msgA
    call write_message
    call delay
    jmp taskA

taskB:
    mov si, msgB
    call write_message
    call delay
    jmp taskB

delay:
    push ax
    mov ax, 0xFFFF

dloop:
    sub ax, 1
    cmp ax, 0
    je  end_dloop
    pusha
    popa
    jmp dloop

end_dloop:
    pop ax
    ret

int9_entry:
    ; cpu context save
    pusha
    push ds
    push es
    push ss

    mov si, msgB
    call write_message

    ; read scan code
    ; break code = make code | 0x80
    in al, 0x60
    and ax, 0x0080
    jz  kmake
    jmp kbreak

kmake:  ; make code
    ;call print_hex
    mov ax, [next_task+0]
    mov bx, [next_task+2]

    mov [next_task+0], ss
    mov [next_task+2], sp
    mov ss, ax
    mov sp, bx

    mov [current_taskid], ss
    jmp end

kbreak: ; break code
    ;mov ax, 0xb
    ;call print_hex

end:
    ;end of irq
    mov al, 0x20
    mov dx, 0x20
    out dx, al

    ;push word [int9_origin+2] cs
    ;push word [int9_origin+0] ip
    ;retf ; origin int9 handler will iret.

    ; cpu context restore
    pop ss
    pop es
    pop ds
    popa
    iret

;pic_init:
;    cli 
;    mov al, 0x11            ; initialize PICs
;
;    out 0x20, al            ; 8259_MASTER
;    out 0xA0, al            ; 8259_SLAVE
;
;    mov al,   0x20          ; interrupt start 32
;    out 0x21, al
;
;    mov al,   0x28          ; interrupt start 40
;    out 0xA1, al
;
;    mov al,   0x04          ; IRQ 2 of 8259_MASTER
;    out 0x21, al    
;
;    mov al,   0x02          ; to 8259_SLAVE
;    out 0xA1, al
;
;    mov al,   0x01          ; 8086 Mode
;    out 0x21, al
;    out 0xA1, al
;
;    mov al,   0xFF          ; mask all
;    out 0x21, al
;    out 0xA1, al
;    sti 
;    
;    mov si, msgPIC
;    call    write_message

; -------------------------------------------------------------
	
write_message:
    pusha   ;ax bx cx dx sp bp si di
again:
    lodsb			; DS:[SI] is read to al
	cmp	al, 0x0
	jz	end_message
	mov	ah, 0x0E	; teletype Mode
	mov	bx, 0007	; white on black attribute
	int	0x10
	jmp	again
	
end_message:
    popa
	ret

; print the ax register
print_hex:
    pusha
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
    popa
    ret
; -------------------------------------------------------------	

msgA	    db	'task A', 0xD, 0xA, 0
msgB	    db	'task B', 0xD, 0xA, 0
msgAX       db  'AX:0X', 0
msgNL       db  0xD, 0xA, 0

; 0 - taskA; 1 - taskB
current_taskid:
	dw 0x0

int9_origin:
    dw 0    ; ip
    dw 0    ; cs
int9_new:
    dw  int9_entry  ; ip
    dw  0x7c0       ; cs

next_task:
    dw 0x0  ; ss
    dw 0x0  ; sp

; cpu context:
; 26 flag
; 24 cs
; 22 ip    --- cpu auto save 
; 20 ax
; 18 cx
; 16 dx
; 14 bx
; 12 sp    (the sp before pusha)
; 10 bp
;  8 si
;  6 di    --- inst pusha save
;  4 ds    --- push ds
;  2 es    --- push es
;  0 ss    --- push ss
taskA_context:
    dw  0x1000  ; ss   0x10000 - 0x11000
    dw  0       ; es
    dw  0x7c0   ; ds
    dw  0       ; di
    dw  0       ; si
    dw  0       ; bp
    dw  0xfffc  ; sp
    dw  0       ; bx
    dw  0       ; dx
    dw  0       ; cx
    dw  0       ; ax

    dw  taskA   ; ip
    dw  0x7c0   ; cs
    dw  0x200   ; flag, enable irq

taskB_context:
    dw  0x1100  ; ss   0x11000 - 0x12000
    dw  0       ; es
    dw  0x7c0   ; ds
    dw  0       ; di
    dw  0       ; si
    dw  0       ; bp
    dw  0xfffc  ; sp
    dw  0       ; bx
    dw  0       ; dx
    dw  0       ; cx
    dw  0       ; ax

    dw  taskB   ; ip
    dw  0x7c0   ; cs
    dw  0x200   ; flag, enable irq

times 510-($-$$) db 0
dw 0xAA55
	
	
	
