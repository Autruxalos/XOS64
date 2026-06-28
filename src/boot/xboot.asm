[BITS 16]
org 0x7C00

_start:
    ; 1. Guardar la unidad de disco asignada por la BIOS
    mov [BOOT_DRIVE], dl

    ; 2. Limpieza estricta de registros de segmento
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; 3. Cargar XKERNEL64 (8 sectores) en la dirección física 0x10000 (0x1000:0x0000)
    mov ax, 0x1000
    mov es, ax
    xor bx, bx                  ; ES:BX = 0x1000:0x0000

    mov ah, 0x02                ; Función BIOS: Leer sectores
    mov al, 8                   ; 8 sectores (4KB)
    mov ch, 0                   ; Cilindro 0
    mov cl, 2                   ; Sector 2 (Justo después del MBR)
    mov dh, 0                   ; Cabeza 0
    mov dl, [BOOT_DRIVE]        ; Unidad de disco respaldada
    int 0x13
    jc .disk_error

    ; 4. Salto lejano segmentado para despertar al Kernel
    push 0x1000
    push 0x0000
    retf

.disk_error:
    mov si, err_msg
.l: lodsb
    or al, al
    jz .h
    mov ah, 0x0E
    int 0x10
    jmp .l
.h: cli \ hlt

err_msg db "XOS64: Error de lectura de disco.", 0
BOOT_DRIVE db 0

times 510-($-$$) db 0
dw 0xAA55
