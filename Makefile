# Parameters
arch ?= x86_64
target ?= $(arch)-unknown-linux-gnu

# input files
asm_srcs := $(wildcard src/arch/$(arch)/*.asm)
asm_objs := $(patsubst src/arch/$(arch)/%.asm, build/arch/$(arch)/%.o, $(asm_srcs))
ld_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg

# output files
builddir := build
kernel := $(builddir)/kernel-$(arch).bin
iso := $(builddir)/iso-$(arch).iso
rust_os := target/$(target)/debug/libmikeos.a

.PHONY: all clean iso run

all: $(kernel)

clean:
	@rm -rf $(builddir)

iso: $(iso)

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)

$(kernel): cargo $(rust_os) $(asm_objs) $(ld_script)
	@ld -n --gc-sections -T $(ld_script) -o $(kernel) \
		$(asm_objs) $(rust_os)

$(iso): $(kernel) $(grub_cfg)
	@mkdir -p $(builddir)/isofiles/boot/grub
	@cp $(kernel) $(builddir)/isofiles/boot/kernel.bin
	@cp $(grub_cfg) $(builddir)/isofiles/boot/grub
	@grub-mkrescue -o $(iso) $(builddir)/isofiles 2> /dev/null
	@rm -r $(builddir)/isofiles

$(builddir)/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@

cargo:
	@cargo build --target $(target)
