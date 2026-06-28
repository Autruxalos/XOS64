; =============================================================================
; XOS64 - CARGADOR DE ARRANQUE ULTRA-MINIMALISTA (Modo Real 16-bits)
; =============================================================================

[BITS 16]
org 0x7C00

_boot_start:
    ; 1. Limpiar registros de segmento heredados de la BIOS
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00               ; Stack seguro justo debajo del bootloader

    ; 2. Cargar XKERNEL64 desde el disco a la memoria RAM (Dirección 0x1000:0x0000 -> 0x10000)
    mov ax, 0x1000               
    mov es, ax                   ; ES = 0x1000
    xor bx, bx                   ; BX = 0x0000 (Dirección de destino en RAM)

    mov ah, 0x02                 ; Función BIOS: Leer sectores
    mov al, 9                    ; Cuántos sectores leer (XKERNEL64 mide < 4.5KB)
    mov ch, 0                    ; Cilindro 0
    mov cl, 2                    ; Empezar en el Sector 2 (El sector 1 es XBOOT)
    mov dh, 0                    ; Cabeza 0
    ; dl contiene automáticamente el número de la unidad de arranque (inyectado por BIOS)
    int 0x13
    jc _disk_error               ; Si el flag de acarreo se activa, hubo error físico

    ; 3. Saltar directamente al Kernel en 0x10000 de forma segmentada
    push 0x1000
    push 0x0000
    retf

_disk_error:
    mov si, error_msg
.l: lodsb
    or al, al
    jz .halt
    mov ah, 0x0E
    int 0x10
    jmp .l
.halt:
    cli
    hlt

error_msg db "ERR: Disco", 0

times 510-($-$$) db 0
dw 0xAA55                        ; Firma de arranque obligatoria MBR
