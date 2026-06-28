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

; =============================================================================
; EXFS64_READ_FILE: Busca y carga un archivo a la RAM usando ATA PIO de 64-bits
; Entrada:  RSI = Puntero al string del nombre (ej: "EXIT64")
;           RDI = Dirección de destino en RAM (ej: 0x12000)
; Salida:   RAX = 1 (Éxito), 0 (No encontrado)
; =============================================================================
exfs64_read_file:
    push rbp
    mov rbp, rsp
    push rbx \ push rcx \ push rdx \ push rdi \ push rsi

    ; 1. Cargar el sector de directorio EXFS64 (LBA 9) en un buffer temporal (0x40000)
    push rsi \ push rdi
    mov rbx, 9                  ; LBA 9
    mov rcx, 1                  ; 1 sector
    mov rdi, 0x40000            ; Buffer temporal de lectura
    call ata_pio_read_sectors
    pop rdi \ pop rsi

    ; 2. Recorrer el directorio buscando el nombre
    mov rbx, 0x40000            ; Dirección base del directorio cargado
    mov rcx, 0                  ; Contador de archivos indexados

.search_loop:
    cmp rcx, EXFS64_MAX_FILES
    jge .not_found
    
    ; Comparar primeros 8 bytes del nombre (Optimización de 64-bits)
    mov r8, [rsi]
    mov r9, [rbx]
    cmp r8, r9
    je .found_file              ; Si coinciden los caracteres, encontramos el archivo
    
    add rbx, 64                 ; Avanzar 64 bytes a la siguiente entrada
    inc rcx
    jmp .search_loop

.found_file:
    ; Extraer metadatos de EXFS64 usando offsets estructurados
    mov rsi, [rbx + 16]         ; RSI = LBA de inicio
    mov rdx, [rbx + 24]         ; RDX = Tamaño en sectores
    ; RDI ya contiene el destino en RAM pasado como argumento

    ; 3. Cargar el contenido real del archivo desde el disco a la RAM destino
    mov rbx, rsi                ; R_LBA
    mov rcx, rdx                ; R_Sectores
    call ata_pio_read_sectors

    mov rax, 1                  ; Código de éxito
    jmp .exit

.not_found:
    xor rax, rax                ; Código de error (0)

.exit:
    pop rsi \ pop rdi \ pop rdx \ push rcx \ pop rbx
    mov rsp, rbp
    pop rbp
    ret

; =============================================================================
; CONTROLADOR DE DISCO ATA PIO NATIVO DE 64-BITS (Hardware Real / QEMU)
; RBX = LBA de inicio, RCX = Cantidad de sectores, RDI = RAM Destino
; =============================================================================
ata_pio_read_sectors:
    push rax \ push rcx \ push rdx \ push rdi

    mov edx, 0x1F2
    mov al, cl                  ; Enviar cantidad de sectores a leer
    out dx, al

    mov eax, ebx                ; EAX contiene el LBA
    mov edx, 0x1F3
    out dx, al                  ; LBA bits 0-7

    mov edx, 0x1F4
    shr eax, 8
    out dx, al                  ; LBA bits 8-15

    mov edx, 0x1F5
    shr eax, 8
    out dx, al                  ; LBA bits 16-23

    mov edx, 0x1F6
    shr eax, 8
    and al, 0x0F
    or al, 0xE0                 ; Configurar modo LBA Master
    out dx, al

    mov edx, 0x1F7
    mov al, 0x20                ; Comando 0x20: Leer Sectores con reintentos
    out dx, al

.retry_sector:
    push rcx
.wait_ready:
    in al, dx
    test al, 0x08               ; Verificar bit DRQ (Data Request Ready)
    jz .wait_ready

    mov ecx, 256                ; 256 words = 512 bytes por sector
    mov edx, 0x1F0              ; Puerto de datos
.read_loop:
    in ax, dx                   ; Leer 2 bytes del hardware
    mov [rdi], ax
    add rdi, 2
    loop .read_loop

    mov edx, 0x1F7              ; Refrescar estado del puerto
    pop rcx
    loop .retry_sector

    pop rdi \ pop rdx \ pop rcx \ pop rax
    ret

