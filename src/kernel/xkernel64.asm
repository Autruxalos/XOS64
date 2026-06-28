; =============================================================================
; XOS64 - XKERNEL64 (Trampolín a Long Mode de 64-bits)
; =============================================================================
[BITS 16]
org 0x10000

_kernel_start:
    cli

    ; 1. Construir tablas de página (PML4 en 0x9000, PDPT en 0xA000, PD en 0xB000)
    mov edi, 0x9000
    xor eax, eax
    mov ecx, 3072               ; Limpiar 12KB de RAM para las tablas
    rep stosd

    ; Enlazar estructuras de paginación (Identity Mapping de los primeros 2MB)
    mov dword [0x9000], 0xA003  ; PML4[0] -> PDPT
    mov dword [0xA000], 0xB003  ; PDPT[0] -> PD
    mov dword [0xB000], 0x0083  ; PD[0]   -> 2MB Huge Page (Base 0x000000)

    ; 2. Cargar registros de control de arquitectura de la CPU
    mov eax, 0x9000
    mov cr3, eax                ; CR3 apunta a PML4

    mov eax, cr4
    or eax, 1 << 5              ; Activar PAE (Physical Address Extension)
    mov cr4, eax

    ; 3. Activar Long Mode en el Model Specific Register (EFER)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8              ; Activar bit LME (Long Mode Enable)
    wrmsr

    ; 4. Activar Paginación y Modo Protegido simultáneamente
    mov eax, cr0
    or eax, 1 << 31 | 1         ; Activar bits PG y PE
    mov cr0, eax

    ; 5. Cargar GDT Global de 64 bits y saltar
    lgdt [gdt64_desc]
    jmp 0x08:_kernel_64

; =============================================================================
; CONTROLADOR NATIVO DE 64-BITS
; =============================================================================
[BITS 64]
_kernel_64:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; El Kernel ha completado la estabilización del hardware.
    ; Saltamos de inmediato a la dirección física donde reside la Shell.
    jmp 0x11000                 ; La Shell se compila para iniciar en 0x11000

align 4
gdt64_start:
    dq 0x0000000000000000       ; Nulo
    dq 0x00209A0000000000       ; Código Kernel 64 bits (Descriptor 0x08)
    dq 0x0000920000000000       ; Datos Kernel 64 bits (Descriptor 0x10)
gdt64_end:

gdt64_desc:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start
