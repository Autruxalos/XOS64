; =============================================================================
; XOS64 - EXIT (Módulo de Terminación de Procesos de 64-bits)
; =============================================================================
[BITS 64]
org 0x12000

_exit_core:
    mov rsi, exit_msg
    mov rbx, 0xB8000
    add rbx, 320                ; Imprimir unas líneas más abajo

.l: lodsb
    or al, al
    jz .shutdown
    mov [rbx], al
    mov byte [rbx+1], 0x0C      ; Texto rojo de advertencia
    add rbx, 2
    jmp .l

.shutdown:
    cli
.halt_loop:
    hlt                         ; Pone al Phenom II en estado de bajo consumo seguro
    jmp .halt_loop

exit_msg db "EXIT: Sistema en estado de suspension seguro (HLT).", 0
