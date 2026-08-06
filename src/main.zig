const std = @import("std");
const Io = std.Io;

const winMain = @import("my_directx_windows.zig").winMain;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const io = init.io;

    try winMain(io, arena);
}
