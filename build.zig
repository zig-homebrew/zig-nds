const std = @import("std");
const builtin = @import("builtin");

const emulator = "desmume";
const flags = .{"-lnds9"};
const devkitpro = "/opt/devkitpro";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const obj = b.addObject("zig-nds", "src/main.zig");
    obj.setOutputDir("zig-out");
    obj.linkLibC();
    obj.setLibCFile(std.build.FileSource{ .path = "libc.txt" });
    obj.addIncludeDir(devkitpro ++ "/libnds/include");
    obj.addIncludeDir(devkitpro ++ "/portlibs/nds/include");
    obj.addIncludeDir(devkitpro ++ "/portlibs/armv5te/include");
    obj.setTarget(.{
        .cpu_arch = .thumb,
        .os_tag = .freestanding,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.arm946e_s },
    });
    obj.setBuildMode(mode);

    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";
    const elf = b.addSystemCommand(&(.{
        devkitpro ++ "/devkitARM/bin/arm-none-eabi-gcc" ++ extension,
        "-g",
        "-mthumb",
        "-mthumb-interwork",
        "-Wl,-Map,zig-out/zig-nds.map",
        "-specs=" ++ devkitpro ++ "/devkitARM/arm-none-eabi/lib/ds_arm9.specs",
        "zig-out/zig-nds.o",
        "-L" ++ devkitpro ++ "/libnds/lib",
        "-L" ++ devkitpro ++ "/portlibs/nds/lib",
        "-L" ++ devkitpro ++ "/portlibs/armv5te/lib",
    } ++ flags ++ .{
        "-o",
        "zig-out/zig-nds.elf",
    }));

    const nds = b.addSystemCommand(&.{
        devkitpro ++ "/tools/bin/ndstool" ++ extension,
        "-9",
        "zig-out/zig-nds.elf",
        "-c",
        "zig-out/zig-nds.nds",
    });
    nds.stdout_action = .ignore;

    b.default_step.dependOn(&nds.step);
    nds.step.dependOn(&elf.step);
    elf.step.dependOn(&obj.step);

    const run_step = b.step("run", "Run in DeSmuME");
    const desmume = b.addSystemCommand(&.{ emulator, "zig-out/zig-nds.nds" });
    run_step.dependOn(&nds.step);
    run_step.dependOn(&desmume.step);
}
