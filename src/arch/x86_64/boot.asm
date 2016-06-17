GLOBAL start
EXTERN long_start

section .text
BITS 32
start:
    ; init the stack, i.e set the stack pointer to stack_top
    mov esp, stack_top

    ; perform the essential checks
    call check_multiboot
    call check_cpuid
    call check_long_mode
    call check_SSE

    ; enable SSE
    call enable_SSE

    ; set up memory paging
    call setup_page_tables
    call enable_paging

    ; load 64bit GDT
    lgdt [gdt64.pointer]

    ; update selectors from new GDT
    mov ax, gdt64.data
    mov ss, ax
    mov ds, ax
    mov es, ax

    ; a far jump to a 64bit future
    jmp gdt64.code:long_start


; print an error code and halt
fatal_error:
    ; 0xb8000 is a VGA text buffer
    mov dword [0xb8000], 0x4f524f45  ; RE
    mov dword [0xb8004], 0x4f3a4f52  ; :R
    mov dword [0xb8008], 0x4f204f20  ;   (double space)
    mov byte  [0xb800a], al          ; error code from al
    hlt


; === sanity checks ===
check_multiboot:
    ; According to Multiboot 2, the bootloader must write
    ; the magic value 0x36d76289 to eax before loading a kernel
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp fatal_error


check_cpuid:
    ; If we can flip bit 21 in EFLAGS register, then CPUID is available
    pushfd
    pop eax        ; EFLAGS copy is now here

    ; Make another copy to compare later (and as a backup)
    mov ecx, eax

    ; Flip the 21st bit
    xor eax, 1 << 21

    ; Copy back into EFLAGS
    push eax
    popfd

    ; Retrieve it again,
    pushfd
    pop eax

    ; restore the backup
    push ecx
    popfd

    ; and check if the bit stayed flipped
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp fatal_error


check_long_mode:
    ; test if extended processor info in available
    mov eax, 0x80000000    ; implicit argument for cpuid
    cpuid                  ; get highest supported argument
    cmp eax, 0x80000001    ; it needs to be at least 0x80000001
    jb .no_long_mode       ; if it's less, the CPU is too old for long mode

    ; use extended info to test if long mode is available
    mov eax, 0x80000001    ; argument for extended processor info
    cpuid                  ; returns various feature bits in ecx and edx
    test edx, 1 << 29      ; test if the LM-bit is set in the D-register
    jz .no_long_mode       ; If it's not set, there is no long mode
    ret
.no_long_mode:
    mov al, "2"
    jmp fatal_error


check_SSE:
    ; test if SSE is supported
    mov eax, 0x1
    cpuid
    test edx, 1 << 25
    jz .no_SSE
    ret
.no_SSE:
    mov al, "3"
    jmp fatal_error


; === features
enable_SSE:
    mov eax, cr0
    and al, 0xFB           ; disable coprocessor emulation (CR0.EM)
    or al, 1 << 1          ; enable coprocessor monitoring (CR0.MP)
    mov cr0, eax

    mov eax, cr4
    or ax, 3 << 9          ; CR4.OSFXSR (SSE + fast FPU save/restore)
                           ; CR4.OSXMMEXCPT (unmasked SSE exceptions)
    mov cr4, eax

    ret



; === memory management stuff ===
setup_page_tables:
    ; map first PML4 entry to PDP table
    mov eax, pdp_table
    or eax, 0b11 ; present + writable
    mov [pml4_table], eax

    ; map first PDP entry to PD table
    mov eax, pd_table
    or eax, 0b11 ; present + writable
    mov [pdp_table], eax

    ; map each PDT entry to a 2MiB hugepage
    mov ecx, 0
.map_pd_entry:
    ; each loop iteration creates a 64b descriptor in the PD table
    mov eax, 0x200000               ; 2MiB
    mul ecx                         ; eax == 2MiB * ecx
    or eax, 0b10000011              ; present + writable + huge
    mov [pd_table + ecx * 8], eax   ; map ecx-th entry

    inc ecx
    cmp ecx, 512
    jne .map_pd_entry

    ret


enable_paging:
    ; load PML4 table address into CR3
    mov eax, pml4_table
    mov cr3, eax

    ; enable PAE in CR4
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax

    ; set LME (Long Mode Enable bit) in EFER MSR
    mov ecx, 0xC0000080 ; EFER address
    rdmsr
    or eax, 1 << 8      ; set LME bit
    wrmsr

    ; enable paging in CR0
    mov eax, cr0
    or eax, 1 << 31     ; set PG bit
    mov cr0, eax

    ret


section .rodata
gdt64:
    dq 0 ; zero entry
.code: equ $ - gdt64
    ; read allowed + executable + data/code bit + present + 64bit
    dq (1 << 41) | (1 << 43) | (1 << 44) | (1 << 47) | (1 << 53)
.data: equ $ - gdt64
    ; write allowed + present + data/code bit
    dq (1 << 41) | (1 << 44) | (1 << 47)
.pointer:
    dw $ - gdt64 - 1  ; gdt64 length - 1
    dq gdt64          ; gdt64 address

; memory & stack
section .bss
align 4096
pml4_table:
    ; Page-Map Level-4 Table
    resb 4096
pdp_table:
    ; Page-Directory Pointer Table
    resb 4096
pd_table:
    ; Page-Directory Table
    resb 4096

stack_bottom:
    resb 64
stack_top:
