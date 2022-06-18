const c = @import("nds/c.zig");

extern fn consoleDemoInit() void; // TODO: This should be removed

export fn main(_: c_int, _: [*]const [*:0]const u8) void {
    consoleDemoInit(); // TODO: This should be c.consoleDemoInit();

    _ = c.printf("Hello, Zig");
    while (true) {
        c.swiWaitForVBlank();
    }
}
