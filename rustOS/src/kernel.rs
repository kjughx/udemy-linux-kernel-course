#![no_std]
#![feature(start)]
use core::panic::PanicInfo;

#[start]    

fn start(_argc: isize, _argv: *const *const u8) -> isize {
    0
}


#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    // let mut host_stderr = HStderr::new();

    //logs "panicked at '$reason', src/main.rs:27:4" to the host stderr
    // writeln!(host_stderr, "{}", info).ok();

    loop {}
}
