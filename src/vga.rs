use core::ptr::Unique;
use core::fmt::Write;
use spin::Mutex;

#[repr(u8)]
#[allow(dead_code)]
pub enum Color {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Brown,
    LightGray,
    DarkGray,
    LightBlue,
    LightGreen,
    LightCyan,
    LightRed,
    Pink,
    Yellow,
    White,
}

#[derive(Clone, Copy)]
struct ColorCode(u8);

impl ColorCode {
    const fn new(fg: Color, bg: Color) -> ColorCode {
        ColorCode((bg as u8) << 4 | (fg as u8))
    }
}

#[repr(C)]
#[derive(Clone, Copy)]
struct Char {
    ascii_char: u8,
    color_code: ColorCode,
}

const BUFFER_HEIGHT: usize = 25;
const BUFFER_WIDTH: usize = 80;

struct Buffer {
    chars: [[Char; BUFFER_WIDTH]; BUFFER_HEIGHT],
}

pub struct Writer {
    row: usize,
    col: usize,
    color_code: ColorCode,
    buffer: Unique<Buffer>,
}

impl Writer {
    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.newline(),
            byte => {
                if self.col == BUFFER_WIDTH - 1 {
                    self.newline()
                };
                self.buffer().chars[self.row][self.col] = Char {
                    ascii_char: byte,
                    color_code: self.color_code,
                };
                self.col += 1;
            }
        }
    }

    fn newline(&mut self) {
        if self.row == BUFFER_HEIGHT - 1 {
            for row in 0..(BUFFER_HEIGHT - 1) {
                let buf = self.buffer();
                buf.chars[row] = buf.chars[row + 1]
            }
        }
        self.row += 1;
        self.col = 0;
        let row = self.row;
        self.clear_row(row);
    }

    pub fn clear_row(&mut self, row: usize) {
        let blankchar = Char {
            ascii_char: b' ',
            color_code: self.color_code,
        };
        self.buffer().chars[row] = [blankchar; BUFFER_WIDTH];
    }

    fn buffer(&mut self) -> &mut Buffer {
        unsafe { self.buffer.get_mut() }
    }
}

impl Write for Writer {
    fn write_str(&mut self, s: &str) -> ::core::fmt::Result {
        for byte in s.bytes() {
            self.write_byte(byte)
        }
        Ok(())
    }
}


pub static WRITER: Mutex<Writer> = Mutex::new(Writer {
    row: 0,
    col: 0,
    color_code: ColorCode::new(Color::White, Color::Black),
    buffer: unsafe { Unique::new(0xb8000 as *mut _) },
});


pub fn clear_screen() {
    for row in 0..BUFFER_HEIGHT {
        WRITER.lock().clear_row(row);
    }
}

macro_rules! print {
    ($($arg:tt)*) => ({
            use core::fmt::Write;
            let mut writer = $crate::vga::WRITER.lock();
            writer.write_fmt(format_args!($($arg)*)).unwrap();
    });
}

macro_rules! println {
    ($fmt:expr) => (print!(concat!($fmt, "\n")));
    ($fmt:expr, $($arg:tt)*) => (print!(concat!($fmt, "\n"), $($arg)*));
}
