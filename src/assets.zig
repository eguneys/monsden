const std = @import("std");
const Allocator = std.mem.Allocator;
const win32 = @import("win32/zigwin32/win32.zig");

const GetModuleFileNameW = win32.kernel32.GetModuleFileNameW;
pub const MyAssetsPathLocator = struct {
    pub fn executableDirPath(io: std.Io, buf: []u8) ![]u8 {
        const len = try std.process.executableDirPath(io, buf);
        return buf[0..len];
    }

    pub fn assetsPath(allocator: Allocator, exe_dir: []const u8) ![]u8 {
        return try std.fs.path.join(allocator, &.{ exe_dir, "assets" });
    }

    pub fn PngPath(allocator: Allocator, exe_dir: []const u8, png_path: []const u8) ![]u8 {
        return try std.fs.path.join(allocator, &.{ exe_dir, "assets", png_path });
    }

    pub fn convertToU16WindowsPath(allocator: Allocator, path: []const u8) ![:0]u16 {
        return try std.unicode.utf8ToUtf16LeAllocZ(allocator, path);
    }
};
