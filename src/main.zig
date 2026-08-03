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

        var context: MyDirectXContext = try .init(hwndV);
        defer context.deinit();

        try runGameLoop(context);
    } else {
        const err = GetLastError();
        std.debug.print("CreateWindowExA failed, GetLastError, {}\n", .{err});
        return error.CreateWindowFailed;
    }
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

fn runGameLoop(cx: MyDirectXContext) !void {
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

        var clear_color = [4]f32{ 0.10, 0.10, 0.35, 1.0 }; // dark blue
        // ClearRenderTargetView expects an optional pointer to f32 (RGBA),
        // so pass a pointer to the first element and cast to the expected type.
        cx.context.ClearRenderTargetView(cx.rtv, @ptrCast(&clear_color[0]));

        _ = cx.swap_chain.Present(1, 0); // 1 = vynsc on

        // update();
        // render();
    }
}

const DXGI_SWAP_CHAIN_DESC = win32.graphics.dxgi.DXGI_SWAP_CHAIN_DESC;
const IDXGISwapChain = win32.graphics.dxgi.IDXGISwapChain;
const ID3D11Device = win32.graphics.direct3d11.ID3D11Device;
const ID3D11DeviceContext = win32.graphics.direct3d11.ID3D11DeviceContext;
const D3D_FEATURE_LEVEL = win32.graphics.direct3d.D3D_FEATURE_LEVEL;

const D3D11_CREATE_DEVICE_FLAG = win32.graphics.direct3d11.D3D11_CREATE_DEVICE_FLAG;
const D3D11_CREATE_DEVICE_DEBUG = win32.graphics.direct3d11.D3D11_CREATE_DEVICE_DEBUG;

const D3D11CreateDeviceAndSwapChain = win32.d3d11.D3D11CreateDeviceAndSwapChain;
const D3D_DRIVER_TYPE_HARDWARE = win32.graphics.direct3d.D3D_DRIVER_TYPE_HARDWARE;
const D3D11_SDK_VERSION = win32.graphics.direct3d11.D3D11_SDK_VERSION;

const ID3D11Texture2D = win32.graphics.direct3d11.ID3D11Texture2D;
const IID_ID3D11Texture2D = win32.graphics.direct3d11.IID_ID3D11Texture2D;

const ID3D11RenderTargetView = win32.graphics.direct3d11.ID3D11RenderTargetView;

const D3D11_VIEWPORT = win32.graphics.direct3d11.D3D11_VIEWPORT;

const DXGI_FORMAT_R8G8B8A8_UNORM = win32.graphics.dxgi.common.DXGI_FORMAT_R8G8B8A8_UNORM;
const DXGI_SWAP_EFFECT_DISCARD = win32.graphics.dxgi.DXGI_SWAP_EFFECT_DISCARD;

const TRUE = win32.foundation.TRUE;

const HRESULT = win32.zig.HRESULT;

const DXGI_USAGE_RENDER_TARGET_OUTPUT = win32.graphics.dxgi.DXGI_USAGE_RENDER_TARGET_OUTPUT;

const MyDirectXContext = struct {
    back_buffer: *ID3D11Texture2D,
    rtv: *ID3D11RenderTargetView,
    device: *ID3D11Device,
    context: *ID3D11DeviceContext,
    swap_chain: *IDXGISwapChain,

    const Self = @This();
    fn deinit(self: *Self) void {
        _ = self.back_buffer.IUnknown.Release();
        _ = self.rtv.IUnknown.Release();

        _ = self.context.IUnknown.Release();
        _ = self.device.IUnknown.Release();
        _ = self.swap_chain.IUnknown.Release();
    }

    fn init(hwnd: HWND) !MyDirectXContext {
        const swap_chain_desc = DXGI_SWAP_CHAIN_DESC{
            .BufferDesc = .{
                .Width = 1280,
                .Height = 720,
                .Format = DXGI_FORMAT_R8G8B8A8_UNORM,
                .RefreshRate = .{ .Numerator = 60, .Denominator = 1 },
                .ScanlineOrdering = .UNSPECIFIED,
                .Scaling = .UNSPECIFIED,
            },
            .SampleDesc = .{ .Count = 1, .Quality = 0 },
            .BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT,
            .BufferCount = 1,
            .OutputWindow = hwnd,
            .Windowed = TRUE,
            .SwapEffect = DXGI_SWAP_EFFECT_DISCARD,
            .Flags = 0,
        };

        var swap_chain: *IDXGISwapChain = undefined;
        var device: *ID3D11Device = undefined;
        var context: *ID3D11DeviceContext = undefined;
        var feature_level: D3D_FEATURE_LEVEL = undefined;

        const create_flags: D3D11_CREATE_DEVICE_FLAG = if (@import("builtin").mode == .Debug)
            D3D11_CREATE_DEVICE_DEBUG
        else
            .{};

        var hr = D3D11CreateDeviceAndSwapChain(
            null, // default adapater
            D3D_DRIVER_TYPE_HARDWARE,
            null,
            create_flags,
            null, // let it pick the highest feature level available
            0,
            D3D11_SDK_VERSION,
            &swap_chain_desc,
            @ptrCast(&swap_chain),
            @ptrCast(&device),
            &feature_level,
            @ptrCast(&context),
        );

        if (hr != HRESULT.S_OK) return error.D3D11DeviceCreationFailed;

        var back_buffer: *ID3D11Texture2D = undefined;
        hr = swap_chain.GetBuffer(0, IID_ID3D11Texture2D, @ptrCast(&back_buffer));
        if (hr != HRESULT.S_OK) return error.GetBackBufferFailed;
        errdefer _ = back_buffer.IUnknown.Release();

        var rtv: *ID3D11RenderTargetView = undefined;
        hr = device.CreateRenderTargetView(@ptrCast(back_buffer), null, @ptrCast(&rtv));
        if (hr != HRESULT.S_OK) return error.CreateRTVFailed;
        errdefer _ = rtv.IUnknown.Release();

        context.OMSetRenderTargets(1, @ptrCast(&rtv), null);

        var viewport = D3D11_VIEWPORT{
            .Width = 1280.0,
            .Height = 720.0,
            .MinDepth = 0.0,
            .MaxDepth = 1.0,
            .TopLeftX = 0.0,
            .TopLeftY = 0.0,
        };
        context.RSSetViewports(1, @ptrCast(&viewport));

        return .{
            .back_buffer = back_buffer,
            .rtv = rtv,
            .context = context,
            .device = device,
            .swap_chain = swap_chain,
        };
    }
};
