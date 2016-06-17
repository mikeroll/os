GLOBAL long_start

section .text
bits 64

long_start:

    ; call rust kmain()
    extern kmain
    call kmain
    hlt
