GLOBAL start

section .text
BITS 32
start:
    ; init the stack, i.e set the stack pointer to stack_top
    mov esp, stack_top

    ; perform the essential checks
    call check_multiboot
    call check_cpuid
    call check_long_mode

    mov dword [0xb8000], 0x2f4b2f4f
    hlt

; print an error code and halt
error:
    ; 0xb8000 is a VGA text buffer
    mov dword [0xb8000], 0x4f524f45  ; RE
    mov dword [0xb8004], 0x4f3a4f52  ; :R
    mov dword [0xb8008], 0x4f204f20  ;   (double space)
    mov byte  [0xb800a], al          ; error code from al
    hlt


; === checks begin ===
check_multiboot:
    ; According to Multiboot 2, the bootloader must write
    ; the magic value 0x36d76289 to eax before loading a kernel
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error


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
    jmp error


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
    jmp error


; this is the stack!
section .bss
stack_bottom:
    resb 64
stack_top:
