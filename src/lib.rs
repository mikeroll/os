#![feature(lang_items)]
#![no_std]

extern crate rlibc;

// no exception handling for now
#[lang = "eh_personality"]
extern "C" fn eh_personality() {}

#[lang = "panic_fmt"]
extern "C" fn panic_fmt() -> ! {
    loop {}
}


#[no_mangle]
pub extern "C" fn kmain() {
    let hello = b"Hello MikeOS!";
    let color = 0x2f;
    let mut bytes = [color; 26];
    for (i, &chr) in hello.into_iter().enumerate() {
        bytes[i * 2] = chr;
    }

    let buffer_center = (0xb8000 + 1988) as *mut _;
    unsafe { *buffer_center = bytes }
}
