; =============================================================================
; XOS64 - XSH64 (Nativa 64-bits Shell)
; =============================================================================
[BITS 64]
org 0x11000

VGA_BUFFER equ 0xB8000
CMD_LIMIT  equ 32

_xsh_start:
    ; Inicializar cursor simulado en pantalla
    mov word [cursor_pos], 0

_xsh_loop:
    mov rsi, prompt
    call print64
    call readline64
    call dispatch64
    jmp _xsh_loop

print64:
    push rsi
    push rbx
    movzx rbx, word [cursor_pos]
    shl rbx, 1
    add rbx, VGA_BUFFER
.l: lodsb
    or al, al
    jz .done
    cmp al, 10
    je .newline
    mov [rbx], al
    mov byte [rbx+1], 0x0F      ; Texto blanco
    add rbx, 2
    inc word [cursor_pos]
    jmp .l
.newline:
    ; Añadir lógica básica para avanzar de renglón (80 columnas)
    add word [cursor_pos], 80
    movzx rbx, word [cursor_pos]
    shl rbx, 1
    add rbx, VGA_BUFFER
    jmp .l
.done:
    pop rbx
    pop rsi
    ret

readline64:
    xor rcx, rcx
.kbd_wait:
    in al, 0x64
    test al, 1
    jz .kbd_wait
    in al, 0x60
    test al, 0x80
    jnz .kbd_wait               ; Ignorar liberación de tecla
    
    cmp al, 0x1C                ; Código de tecla Enter
    je .end_line
    ; Mapeo ultra simple de Scan Code de la tecla 'A' (0x1E) como demostración
    cmp al, 0x1E
    jne .kbd_wait
    mov al, 'A'
    
    cmp rcx, CMD_LIMIT-1
    jae .kbd_wait
    mov [cmd_buffer + rcx], al
    inc rcx
    ; Mostrar eco en pantalla
    push rsi \ mov rsi, char_a \ call print64 \ pop rsi
    jmp .kbd_wait
.end_line:
    mov byte [cmd_buffer + rcx], 0
    push rsi \ mov rsi, newline_str \ call print64 \ pop rsi
    ret

dispatch64:
    ; Compara si el buffer tiene caracteres ingresados
    mov al, [cmd_buffer]
    or al, al
    jz .ret
    ; Si se presiona una combinación mapeada, se puede invocar a EXIT
    cmp al, 'A'
    je 0x12000                  ; Salta al módulo EXIT cargado en 0x12000
.ret:
    ret

prompt       db "XOS64:/$ ", 0
char_a       db "A", 0
newline_str  db 10, 0
cursor_pos   dw 0
cmd_buffer   times CMD_LIMIT db 0
