section .multiboot2
header_start:
    dd 0xe85250d6                ; multiboot 2 magic
    dd 0                         ; architecture - i386
    dd header_end - header_start ; header length
    dd 0x100000000 - (0xe85250d6 + 0 + (header_end - header_start)) ; checksum

    ; tags go here
    ; -- no tags for now --

    ; end tag
    dw 0
    dw 0
    dd 8

header_end:
