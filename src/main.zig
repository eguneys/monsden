const std = @import("std");
const Io = std.Io;

const win32 = @import("win32/zigwin32/win32.zig");

const GetModuleHandleA = win32.kernel32.GetModuleHandleA;
const RegisterClassExA = win32.user32.RegisterClassExA;
const WNDCLASSEXA = win32.ui.windows_and_messaging.WNDCLASSEXA;
const CreateWindowExA = win32.user32.CreateWindowExA;
const GetLastError = win32.kernel32.GetLastError;
const ShowWindow = win32.user32.ShowWindow;

const SW_SHOW = win32.ui.windows_and_messaging.SW_SHOW;

const HWND = win32.foundation.HWND;
const WPARAM = usize;
const LPARAM = isize;
const LRESULT = isize;

const LoadCursorA = win32.user32.LoadCursorA;

const WS_OVERLAPPEDWINDOW = win32.ui.windows_and_messaging.WS_OVERLAPPEDWINDOW;
const CW_USEDEFAULT = win32.ui.windows_and_messaging.CW_USEDEFAULT;

const WM_DESTROY = win32.ui.windows_and_messaging.WM_DESTROY;
const PostQuitMessage = win32.user32.PostQuitMessage;
const DefWindowProcA = win32.user32.DefWindowProcA;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try stdout_writer.flush();

    const hInstance = GetModuleHandleA(null);
    const class_name = "MyWindowClass";

    const wc = WNDCLASSEXA{
        .cbSize = @sizeOf(WNDCLASSEXA),
        .style = .{},
        .lpfnWndProc = processWindowMessage,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = @ptrCast(hInstance),
        .hIcon = null,
        .hCursor = LoadCursorA(null, @ptrFromInt(32512)),
        .hbrBackground = null,
        .lpszMenuName = null,
        .lpszClassName = class_name,
        .hIconSm = null,
    };

    _ = RegisterClassExA(&wc);

    const hwnd = CreateWindowExA(
        .{},
        class_name,
        "Zig Window",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        640,
        480,
        null,
        null,
        @ptrCast(hInstance),
        null,
    );

    if (hwnd) |hwndV| {
        _ = ShowWindow(hwndV, SW_SHOW);
    } else {
        const err = GetLastError();
        std.debug.print("CreateWindowExA failed, GetLastError, {}\n", .{err});
        return error.CreateWindowFailed;
    }

    try runGameLoop();
}

fn processWindowMessage(hwnd: HWND, msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcA(hwnd, msg, wParam, lParam),
    }
}

const MSG = win32.ui.windows_and_messaging.MSG;
const PeekMessageA = win32.user32.PeekMessageA;
const PM_REMOVE = win32.ui.windows_and_messaging.PM_REMOVE;

const WM_QUIT = win32.ui.windows_and_messaging.WM_QUIT;
const TranslateMessage = win32.user32.TranslateMessage;
const DispatchMessageA = win32.user32.DispatchMessageA;

fn runGameLoop() !void {
    var msg: MSG = undefined;

    var running = true;

    while (running) {
        while (PeekMessageA(&msg, null, 0, 0, PM_REMOVE) != 0) {
            if (msg.message == WM_QUIT) {
                running = false;
                break;
            }

            _ = TranslateMessage(&msg);
            _ = DispatchMessageA(&msg);
        }

        if (!running) break;

        // update();
        // render();
    }
}
