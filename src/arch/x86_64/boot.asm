GLOBAL start

section .text
BITS 32
start:
    ; print an 'OK'
    mov dword [0xb8000], 0x2f4b2f4f
    hlt
