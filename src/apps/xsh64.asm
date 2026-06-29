; =============================================================================
; XOS64 - XSH (Nativa 64-bits Shell Monolítica)
; =============================================================================
[BITS 64]
org 0x11000                     ; Dirección de carga fija asignada en EXFS64

VGA_BUFFER equ 0xB8000
CMD_LIMIT  equ 32

_xsh_start:
    ; Inicializar registros de segmento para entorno de usuario de 64-bits
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    
    ; Reiniciar la posición del cursor lógico en pantalla
    mov word [cursor_pos], 0

_xsh_loop:
    ; 1. Imprimir el Prompt en pantalla
    mov rsi, prompt
    call print64

    ; 2. Capturar la entrada del teclado
    call readline64

    ; 3. Analizar el buffer y despachar el comando
    call dispatch64

    ; 4. Bucle infinito del entorno interactivo
    jmp _xsh_loop

; =============================================================================
; SUBRUTINA: print64
; =============================================================================
print64:
    push rsi
    push rbx
    push rax

    ; Calcular offset en memoria de video VGA (cursor_pos * 2)
    movzx rbx, word [cursor_pos]
    shl rbx, 1
    add rbx, VGA_BUFFER

.loop_char:
    lodsb                       ; Cargar siguiente caracter en AL
    or al, al
    jz .print_done              ; Si es 0, terminar
    
    cmp al, 10                  ; ¿Es salto de línea ('\n')?
    je .handle_newline

    ; Escribir caracter en el buffer de video
    mov [rbx], al
    mov byte [rbx+1], 0x0F      ; Atributo: Texto blanco
    add rbx, 2
    inc word [cursor_pos]
    jmp .loop_char

.handle_newline:
    ; Avanzar el cursor al inicio de la siguiente fila
    movzx rax, word [cursor_pos]
    mov bl, 80
    div bl                      
    movzx rax, ah               
    neg rax
    add rax, 80
    add [cursor_pos], ax        
    
    ; Recalcular dirección física de video
    movzx rbx, word [cursor_pos]
    shl rbx, 1
    add rbx, VGA_BUFFER
    jmp .loop_char

.print_done:
    pop rax
    pop rbx
    pop rsi
    ret

; =============================================================================
; SUBRUTINA: readline64
; =============================================================================
readline64:
    push rax
    push rcx
    push rdx
    
    xor rcx, rcx                ; Índice del buffer

.kbd_wait:
    in al, 0x64
    test al, 1                  
    jz .kbd_wait

    in al, 0x60
    test al, 0x80               
    jnz .kbd_wait               

    ; --- CONTROL DE TECLAS ---
    cmp al, 0x1C                ; Tecla ENTER
    je .end_line

    cmp al, 0x1E                ; Tecla 'A'
    je .map_a
    cmp al, 0x30                ; Tecla 'B'
    je .map_b
    jmp .kbd_wait               

.map_a:
    mov al, 'A'
    jmp .store_char

.map_b:
    mov al, 'B'
    jmp .store_char

.store_char:
    cmp rcx, CMD_LIMIT - 1
    jae .kbd_wait

    mov [cmd_buffer + rcx], al
    inc rcx

    ; Imprimir el ECO (Líneas limpias sin barra invertida)
    mov [temp_char], al
    push rsi
    mov rsi, temp_char
    call print64
    pop rsi
    jmp .kbd_wait

.end_line:
    mov byte [cmd_buffer + rcx], 0
    
    push rsi
    mov rsi, newline_str
    call print64
    pop rsi

    pop rdx
    pop rcx
    pop rax
    ret

; =============================================================================
; SUBRUTINA: dispatch64
; =============================================================================
dispatch64:
    push rax
    push rsi
    push rdi

    mov al, [cmd_buffer]
    or al, al
    jz .dispatch_done

    cmp al, 'A'
    je .invoke_exit

    cmp al, 'B'
    je .show_test

    jmp .dispatch_done

.invoke_exit:
    jmp 0x12000

.show_test:
    push rsi
    mov rsi, test_msg
    call print64
    pop rsi
    jmp .dispatch_done

.dispatch_done:
    pop rdi
    pop rsi
    pop rax
    ret

; =============================================================================
; SECCIÓN DE DATOS
; =============================================================================
align 8
prompt       db "XOS64:/$ ", 0
newline_str  db 10, 0
test_msg     db "COMANDO INTERNO: Ejecutando sub-rutina de test B.", 10, 0

cursor_pos   dw 0               
temp_char    db 0, 0            

align 8
cmd_buffer   times CMD_LIMIT db 0

; =============================================================================
; COMANDO: exofetch — Visor de Información del Sistema XOS64
; =============================================================================

global xsh_cmd_exofetch
xsh_cmd_exofetch:
    push rsi
    push rdi

    ; --- LÍNEA 1: ARTE + ARQUITECTURA ---
    mov rsi, fetch_ascii_01
    mov bl, 0x0B                ; Cyan para el arte
    call xk_print
    mov rsi, fetch_lbl_arch
    mov bl, 0x0F                ; Blanco para las etiquetas
    call xk_print

    ; --- LÍNEA 2: ARTE + ANCHO DE BUS ---
    mov rsi, fetch_ascii_02
    mov bl, 0x0B
    call xk_print
    mov rsi, fetch_lbl_bus
    mov bl, 0x0F
    call xk_print

    ; --- LÍNEA 3: ARTE + GRÁFICOS ---
    mov rsi, fetch_ascii_03
    mov bl, 0x0B
    call xk_print
    mov rsi, fetch_lbl_vga
    mov bl, 0x0F
    call xk_print

    ; --- LÍNEA 4: ARTE + UPTIME SIMULADO ---
    mov rsi, fetch_ascii_04
    mov bl, 0x0B
    call xk_print
    mov rsi, fetch_lbl_uptime
    mov bl, 0x0F
    call xk_print

    ; --- RESTO DEL ARTE ASCII (Bloque inferior) ---
    mov rsi, fetch_ascii_block
    mov bl, 0x0B
    call xk_print

    pop rdi
    pop rsi
    ret

; =============================================================================
; CONSTANTES Y CADENAS DE TEXTO (Alineadas linealmente en .text)
; =============================================================================

; Formateamos el texto acoplándolo al lado derecho del arte ASCII usando saltos de línea (\n = 10)
fetch_ascii_01:     db "       ,ok0KK0l.       ", 9, 0
fetch_lbl_arch:     db "OS/ARCH:  XOS64 Bare-Metal (x86_64 Long Mode)", 10, 0

fetch_ascii_02:     db "      ;#S#             ", 9, 0
fetch_lbl_bus:      db "BUS:      64-bit Native Paging Mode", 10, 0

fetch_ascii_03:     db "     +###S             ", 9, 0
fetch_lbl_vga:      db "VIDEO:    VGA Standard Text Mode (0xB8000 MMIO)", 10, 0

fetch_ascii_04:     db "   ,S##+SS             ", 9, 0
fetch_lbl_uptime:   db "UPTIME:   Estable (Real-Time Pit Clock Active)", 10, 0

; El resto de tu silueta se imprime limpia abajo
fetch_ascii_block:
    db "  +##?, SS", 10
    db ".*##* SS", 10
    db ":##%.    SS+", 10
    db ";##%      :S%", 10
    db " :*###################################SS%*++?%*+**;", 10
    db "    .*******************S########%********+++%%++++++*%::,", 10
    db "                       ;SS*", 10
    db "                      +%SS,", 10
    db "                      %?S%", 10
    db "                     ,%%.S?", 10
    db "                     ?%, S%", 10
    db "                    *?;  S%", 10
    db "                   ,%+   ?S:", 10
    db "                   %?    ;%S", 10
    db "                  ;?,     ,%%,", 10
    db "                  ?:       ,?%+.", 10
    db "                 *+         .;?*?,,", 10
    db "                 *,            :++++*+..........   .+*", 10
    db "                ,* .::::;;;;;+++;;;+++++*?SS%:", 10, 0
