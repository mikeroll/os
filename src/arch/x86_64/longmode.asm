GLOBAL long_start

section .text
bits 64

long_start:

    ; call rust kmain()
    extern kmain
    call kmain

    mov rax, 0x2f592f412f4b2f4f
    mov qword [0xb8000], rax
    hlt
