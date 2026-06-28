; =============================================================================
; EXFS64 - TABLA DE DIRECTORIO INICIAL (Sector Estático de 512 bytes)
; =============================================================================
[BITS 64]

directory_start:
    ; --- Entrada 1: XSH64 ---
    db "XSH64", 0,0,0,0,0,0,0,0,0,0,0 ; Nombre (16 bytes)
    dq 10                           ; LBA de inicio (Sector 11 del disco)
    dq 8                            ; Tamaño en sectores (4KB asignados)
    dq 4096                         ; Tamaño en bytes
    dd 0                            ; Flags: Archivo del Sistema
    times 20 db 0                   ; Relleno

    ; --- Entrada 2: EXIT64 ---
    db "EXIT64", 0,0,0,0,0,0,0,0,0,0; Nombre (16 bytes)
    dq 18                           ; LBA de inicio (Sector 19 del disco)
    dq 1                            ; Tamaño en sectores (512 bytes)
    dq 512                          ; Tamaño en bytes
    dd 0                            ; Flags: Archivo del Sistema
    times 20 db 0                   ; Relleno

    ; --- Rellenar el resto del sector del directorio con ceros (Entradas vacías) ---
    times 512 - ($ - directory_start) db 0
