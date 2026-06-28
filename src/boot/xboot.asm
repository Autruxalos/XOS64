; =============================================================================
; XOS64 - XBOOT (Sector de Arranque MBR - 16-bits Real Mode)
; =============================================================================

[BITS 16]
org 0x7C00

_boot_start:
    ; 1. Inicializar selectores de segmento a 0
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00               ; Stack justo debajo del cargador

    ; 2. Guardar el número de unidad de disco que nos dio la BIOS
    mov [BOOT_DRIVE], dl

    ; 3. Cargar XKERNEL64 y XSH64 (Sectores 2 al 16 del disco) a la RAM 0x10000
    mov ax, 0x1000               ; Segmento 0x1000 (0x1000:0x0000 = 0x10000 física)
    mov es, ax
    xor bx, bx                   ; Offset 0

    mov ah, 0x02                 ; Función BIOS: Leer sectores
    mov al, 15                   ; Cantidad de sectores a leer (Kernel + Shell)
    mov ch, 0                    ; Cilindro 0
    mov cl, 2                    ; Empezar en el Sector 2
    mov dh, 0                    ; Cabeza 0
    mov dl, [BOOT_DRIVE]         ; Unidad de origen
    int 0x13
    jc _disk_error               ; Saltar si el flag de acarreo (CF) indica error

    ; 4. Salto lejano segmentado al inicio de XKERNEL64 (0x10000)
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

; Variables
BOOT_DRIVE db 0
error_msg  db "XOS64 BOOT ERR: Disco", 13, 10, 0

times 510-($-$$) db 0
dw 0xAA55                        ; Firma MBR ejecutable
