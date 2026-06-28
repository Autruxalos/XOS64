[BITS 16]
org 0x0000                      ; Segmentado en 0x1000:0x0000 (Física 0x10000)

_kernel_start:
    cli
    mov ax, 0x1000              ; Sincronizar DS con el segmento actual
    mov ds, ax

    ; 1. Limpiar 12KB de RAM para las tablas de páginas (de 0x9000 a 0xC000)
    mov edi, 0x9000
    xor eax, eax
    mov ecx, 3072
    rep stosd

    ; 2. Construir Identity Mapping de 2MB usando Huge Pages
    ; Mapeamos los primeros 2MB de la RAM de forma idéntica a la física
    mov dword [0x9000], 0xA003  ; PML4[0] apunta a PDPT (0xA000) + Flags (Presente/Escritura)
    mov dword [0xA000], 0xB003  ; PDPT[0] apunta a Page Directory (0xB000) + Flags
    mov dword [0xB000], 0x0083  ; PD[0] apunta a la dirección física 0x0 + Bit Huge Page (0x80)

    ; 3. Cargar la dirección de PML4 en CR3
    mov eax, 0x9000
    mov cr3, eax

    ; 4. Activar extensiones de paginación en CR4 (PAE y PSE)
    mov eax, cr4
    or eax, (1 << 5) | (1 << 4) ; Bit 5 = PAE, Bit 4 = PSE (Obligatorio para páginas de 2MB)
    mov cr4, eax

    ; 5. Activar Long Mode en el registro específico del modelo (EFER)
    mov ecx, 0xC0000080         ; EFER MSR
    rdmsr
    or eax, 1 << 8              ; Bit 8 = LME (Long Mode Enable)
    wrmsr

    ; 6. Activar Paginación y Modo Protegido en CR0
    mov eax, cr0
    or eax, (1 << 31) | 1       ; Bit 31 = PG (Paginación), Bit 0 = PE (Protected Mode)
    mov cr0, eax

    ; 7. Cargar la GDT de 64-bits modificando el puntero con la base física
    lgdt [gdt64_desc]

    ; 8. Salto lejano definitivo al Selector de Código de 64-bits (0x08)
    ; Usamos una transición limpia saltando a la etiqueta de 64-bits
    jmp 0x08:_kernel_64

; =============================================================================
; ENTORNO NATIVO DE 64-BITS (LONG MODE ACTIVE)
; =============================================================================
[BITS 64]
_kernel_64:
    ; Resetear selectores de datos para el espacio de 64-bits
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov gs, ax
    
    ; Establecer el puntero de la pila en una zona segura debajo del Kernel
    mov rsp, 0x7C00

    ; Saltar a la dirección fija donde reside la Shell de 64-bits (LBA 10)
    jmp 0x11000

align 8
gdt64_start:
    dq 0x0000000000000000       ; Descriptor Nulo
    dq 0x00209A0000000000       ; Selector de Código Kernel 64-bits (0x08)
    dq 0x0000920000000000       ; Selector de Datos Kernel 64-bits (0x10)
gdt64_end:

gdt64_desc:
    dw gdt64_end - gdt64_start - 1
    dd gdt64_start + 0x10000    ; Sumamos 0x10000 porque la GDT está cargada en ese offset real
