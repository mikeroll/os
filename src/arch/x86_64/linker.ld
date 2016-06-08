ENTRY(start)

SECTIONS {
    . = 1M;

    .boot : {
        *(.multiboot2)
    }

    .text : {
        *(.text)
    }
}
