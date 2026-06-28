; =============================================================================
; EXFS64 - ESPECIFICACIÓN ESTRUCTURAL DEL SISTEMA DE ARCHIVOS (XOS64)
; =============================================================================

; El directorio de EXFS64 reside fijo en el LBA 9 (Sector 10 del disco)
EXFS64_DIR_LBA    equ 9
EXFS64_MAX_FILES  equ 8          ; Capacidad para 8 archivos en esta etapa base

; Estructura de una entrada de archivo (Total: 64 bytes)
; -----------------------------------------------------------------------------
; Bytes 00-15 (16 bytes): Nombre del archivo (ASCII, rellenado con ceros)
; Bytes 16-23 (8 bytes) : LBA de inicio en el disco (Quadword)
; Bytes 24-31 (8 bytes) : Tamaño del archivo en sectores (Quadword)
; Bytes 32-39 (8 bytes) : Tamaño real del archivo en bytes (Quadword)
; Bytes 40-43 (4 bytes) : Flags / Atributos (0 = Sistema, 1 = XEXE, 2 = XPKG)
; Bytes 44-63 (20 bytes): Reservado para futura expansión (Relleno con ceros)

struc exfs64_entry
    .name:    resb 16
    .lba:     resq 1
    .sectors: resq 1
    .bytes:   resq 1
    .flags:   resd 1
    .pad:     resb 20
endstruc
