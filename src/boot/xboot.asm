[BITS 16]
org 0x7C00

_start:
    ; 1. Respaldar la unidad de arranque que nos da la BIOS en DL
    mov [BOOT_DRIVE], dl

    ; 2. Limpieza estricta de registros
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; 3. Resetear el controlador de disco antes de leer (Vital para QEMU y hardware real)
    mov ah, 0
    mov dl, [BOOT_DRIVE]
    int 0x13
    jc .disk_error

    ; 4. Cargar XKERNEL (8 sectores) a la dirección segmentada 0x1000:0x0000 (0x10000 física)
    mov ax, 0x1000               
    mov es, ax
    xor bx, bx                   ; ES:BX = 0x1000:0x0000

    mov ah, 0x02                 ; Función: Leer sectores
    mov al, 8                    ; Cantidad de sectores
    mov ch, 0                    ; Cilindro 0
    mov cl, 2                    ; Empezar en Sector 2 (LBA 1)
    mov dh, 0                    ; Cabeza 0
    mov dl, [BOOT_DRIVE]         ; Recuperar nuestra unidad de disco
    int 0x13
    jc .disk_error

    ; 5. El salto lejano segmentado (Far Jump) que despierta al Kernel
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

; Variable para guardar el número de disco
BOOT_DRIVE db 0

times 510-($-$$) db 0
dw 0xAA55
