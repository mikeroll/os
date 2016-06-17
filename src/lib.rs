#![feature(lang_items)]
#![feature(const_fn)]
#![feature(unique)]
#![no_std]

extern crate rlibc;
extern crate spin;

// no exception handling for now
#[lang = "eh_personality"]
extern "C" fn eh_personality() {}

#[lang = "panic_fmt"]
extern "C" fn panic_fmt() -> ! {
    loop {}
}

#[macro_use]
mod vga;

#[no_mangle]
pub extern "C" fn kmain() {
    vga::clear_screen();
    for _ in 0..327 {
        println!("Hello MikeOS!");
    }
    loop {}
}
