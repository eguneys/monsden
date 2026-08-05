const std = @import("std");
const Io = std.Io;

const png = @import("png.zig");
const MyAssetsPathLocator = @import("assets.zig").MyAssetsPathLocator;

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

const client_width: i32 = 1280;
const client_height: i32 = 720;

const SetProcessDpiAwarenessContext = win32.user32.SetProcessDpiAwarenessContext;
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = win32.ui.hi_dpi.DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2;

const RECT = win32.foundation.RECT;
const FALSE = win32.foundation.FALSE;

const AdjustWindowRectEx = win32.user32.AdjustWindowRectEx;

const game_width: u32 = 640;
const game_height: u32 = 360;

const SetWindowLongPtrW = win32.user32.SetWindowLongPtrW;
const GetWindowLongPtrW = win32.user32.GetWindowLongPtrW;

const GWLP_USERDATA = win32.ui.windows_and_messaging.GWLP_USERDATA;

const WM_SIZE = win32.ui.windows_and_messaging.WM_SIZE;

const WM_SYSKEYDOWN = win32.ui.windows_and_messaging.WM_SYSKEYDOWN;

const GWL_STYLE = win32.ui.windows_and_messaging.GWL_STYLE;

const VK_RETURN = win32.ui.input.keyboard_and_mouse.VK_RETURN;

const GetWindowRect = win32.user32.GetWindowRect;
const SetWindowPos = win32.user32.SetWindowPos;

const MonitorFromWindow = win32.user32.MonitorFromWindow;

const SWP_NOZORDER = win32.ui.windows_and_messaging.SWP_NOZORDER;
const SWP_FRAMECHANGED = win32.ui.windows_and_messaging.SWP_FRAMECHANGED;

const MONITOR_DEFAULTTONEAREST = win32.graphics.gdi.MONITOR_DEFAULTTONEAREST;
const MONITORINFO = win32.graphics.gdi.MONITORINFO;

const GetMonitorInfoW = win32.user32.GetMonitorInfoW;

const WINDOW_STYLE = win32.ui.windows_and_messaging.WINDOW_STYLE;
const WS_POPUP = win32.ui.windows_and_messaging.WS_POPUP;
const WS_VISIBLE = win32.ui.windows_and_messaging.WS_VISIBLE;

const HWND_TOP = win32.ui.windows_and_messaging.HWND_TOPMOST;

pub fn main(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const allocator = arena;

    const args = try init.minimal.args.toSlice(arena);
    for (args) |arg| {
        std.log.info("arg: {s}", .{arg});
    }

    const io = init.io;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout_writer = &stdout_file_writer.interface;

    try stdout_writer.flush();

    try png.MyComInitialize();
    var mywic_factory = try png.MyWicFactory.init();
    defer mywic_factory.deinit();

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const exePath = try MyAssetsPathLocator.executableDirPath(io, &buf);

    const atlasPngPath = try MyAssetsPathLocator.atlasPngPath(allocator, exePath);
    defer allocator.free(atlasPngPath);

    const atlasPngU16 = try MyAssetsPathLocator.convertToU16WindowsPath(allocator, atlasPngPath);
    defer allocator.free(atlasPngU16);
    //const slice: []const u16 = std.mem.span(atlasPgnU16);

    //std.debug.print("Exe: {s}\n", .{exePath});
    //std.debug.print("AtlasPgn: {s}\n", .{atlasPgnPath});
    //std.debug.print("atlasU16: {f}\n", .{std.unicode.fmtUtf16Le(slice)});

    var pngBuf: [1024 * 100 * 1]u8 = undefined;
    const a = try mywic_factory.png(atlasPngU16, &pngBuf);
    std.debug.print("\n{d}\n", .{a.len});

    // this seems somewhat related to scaling the window
    _ = SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

    var window_rect = RECT{ .left = 0, .top = 0, .right = client_width, .bottom = client_height };
    _ = AdjustWindowRectEx(&window_rect, WS_OVERLAPPEDWINDOW, FALSE, .{});
    const initial_width: u32 = @intCast(window_rect.right - window_rect.left);
    const initial_height: u32 = @intCast(window_rect.bottom - window_rect.top);
    std.debug.print("initial client size: {}x{}\n", .{ initial_width, initial_height });

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
        window_rect.right - window_rect.left,
        window_rect.bottom - window_rect.top,
        null,
        null,
        @ptrCast(hInstance),
        null,
    );

    if (hwnd) |hwndV| {
        _ = ShowWindow(hwndV, SW_SHOW);

        var context: MyDirectXContext = try .init(hwndV);
        defer context.deinit();

        _ = SetWindowLongPtrW(hwnd, GWLP_USERDATA, @bitCast(@intFromPtr(&context)));

        try runGameLoop(&context);
    } else {
        const err = GetLastError();
        std.debug.print("CreateWindowExA failed, GetLastError, {}\n", .{err});
        return error.CreateWindowFailed;
    }
    std.debug.print("Bye.", .{});
}

const WM_ENTERSIZEMOVE = win32.ui.windows_and_messaging.WM_ENTERSIZEMOVE;
const WM_EXITSIZEMOVE = win32.ui.windows_and_messaging.WM_EXITSIZEMOVE;
const WM_TIMER = win32.ui.windows_and_messaging.WM_TIMER;
const SetTimer = win32.user32.SetTimer;
const KillTimer = win32.user32.KillTimer;
const USER_TIMER_MINIMUM = win32.ui.windows_and_messaging.USER_TIMER_MINIMUM;

const RESIZE_TIMER_ID = 1;

const IDXGIDebug = win32.graphics.dxgi.IDXGIDebug;
const DXGIGetDebugInterface1 = win32.dxgi.DXGIGetDebugInterface1;
const IID_IDXGIDebug = win32.graphics.dxgi.IID_IDXGIDebug;
const DXGI_DEBUG_ALL = win32.graphics.dxgi.DXGI_DEBUG_ALL;
const DXGI_DEBUG_RLO_DETAIL = win32.graphics.dxgi.DXGI_DEBUG_RLO_DETAIL;

fn processWindowMessage(hwnd: HWND, msg: u32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        WM_ENTERSIZEMOVE => {
            _ = SetTimer(hwnd, RESIZE_TIMER_ID, USER_TIMER_MINIMUM, null);
            return 0;
        },
        WM_EXITSIZEMOVE => {
            _ = KillTimer(hwnd, RESIZE_TIMER_ID);
            return 0;
        },
        WM_TIMER => {
            if (wParam == RESIZE_TIMER_ID) {
                const user_data = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
                if (user_data == 0) return 0;
                const state: *MyDirectXContext = @ptrFromInt(@as(usize, @bitCast(user_data)));
                state.draw(); // resize buffers already happened in WM_SIZE
            }
            return 0;
        },
        WM_SYSKEYDOWN => {
            if (wParam == @intFromEnum(VK_RETURN) and (lParam & (1 << 29)) != 0) { // bit 29 = ALT
                const user_data = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
                if (user_data == 0) return 0;
                const state: *MyDirectXContext = @ptrFromInt(@as(usize, @bitCast(user_data)));
                state.toggleFullscreen();
                return 0;
            }

            return DefWindowProcA(hwnd, msg, wParam, lParam);
        },
        WM_SIZE => {
            const SIZE_MINIMIZED: usize = 1;
            if (wParam == SIZE_MINIMIZED) return 0;

            const lp: u32 = @truncate(@as(usize, @bitCast(lParam)));
            const new_width: u32 = lp & 0xFFFF;
            const new_height: u32 = (lp >> 16) & 0xFFFF;
            if (new_width == 0 or new_height == 0) return 0;

            // GWLP_USERDATA is 0 for the WM_SIZE messages Windows
            // sends during CreateWindowExW itself, since that's before
            // SetWindowLongPtrW runs in main() -- nothing to resize yet.
            const user_data = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
            if (user_data == 0) return 0;
            const state: *MyDirectXContext = @ptrFromInt(@as(usize, @bitCast(user_data)));

            state.context.OMSetRenderTargets(0, null, null);

            //state.context.ClearState();
            //state.context.Flush();

            //Drop our reference to the old backbuffer RTV before
            // resizing -- ResizeBuffers fails if anything still
            // references the swap chain's buffers.
            if (state.backbuffer_rtv) |old_rtv| {
                _ = old_rtv.IUnknown.Release();
                state.backbuffer_rtv = null;
            }

            const hr = state.swap_chain.ResizeBuffers(0, new_width, new_height, DXGI_FORMAT_UNKNOWN, 0);
            if (hr != HRESULT.S_OK) {
                std.debug.print("ResizeBuffers failed: hr={}\n", .{hr});

                var debug_iface: ?*IDXGIDebug = null;
                if (!DXGIGetDebugInterface1(0, IID_IDXGIDebug, @ptrCast(&debug_iface)).failed) {
                    if (debug_iface) |dbg| {
                        _ = dbg.ReportLiveObjects(DXGI_DEBUG_ALL, DXGI_DEBUG_RLO_DETAIL);
                        _ = dbg.IUnknown.Release();
                    }
                }

                return 0;
            }

            var back_buffer: *ID3D11Texture2D = undefined;
            if (state.swap_chain.GetBuffer(0, IID_ID3D11Texture2D, @ptrCast(&back_buffer)) == HRESULT.S_OK) {
                defer _ = back_buffer.IUnknown.Release();
                var new_rtv: *ID3D11RenderTargetView = undefined;
                if (!state.device.CreateRenderTargetView(@ptrCast(back_buffer), null, @ptrCast(&new_rtv)).failed) {
                    state.backbuffer_rtv = new_rtv;
                    std.debug.print("RenderTargetSetTo{*}\n", .{new_rtv});
                } else {
                    std.debug.print("CreateRenderTargetView", .{});
                }
            } else {
                std.debug.print("GetBuffer failed after resize", .{});
            }
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

fn runGameLoop(cx: *MyDirectXContext) !void {
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

        cx.draw();
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

const D3D11_TEXTURE2D_DESC = win32.graphics.direct3d11.D3D11_TEXTURE2D_DESC;

const ID3D11RenderTargetView = win32.graphics.direct3d11.ID3D11RenderTargetView;

const D3D11_VIEWPORT = win32.graphics.direct3d11.D3D11_VIEWPORT;

const DXGI_FORMAT_R8G8B8A8_UNORM = win32.graphics.dxgi.common.DXGI_FORMAT_R8G8B8A8_UNORM;
const DXGI_SWAP_EFFECT_DISCARD = win32.graphics.dxgi.DXGI_SWAP_EFFECT_DISCARD;

const TRUE = win32.foundation.TRUE;

const HRESULT = win32.zig.HRESULT;

const DXGI_USAGE_RENDER_TARGET_OUTPUT = win32.graphics.dxgi.DXGI_USAGE_RENDER_TARGET_OUTPUT;

const vs_bytecode = @embedFile("shaders/triangle_vs.cso");
const ps_bytecode = @embedFile("shaders/triangle_ps.cso");

const blit_vs_bytecode = @embedFile("shaders/blit_vs.cso");
const blit_ps_bytecode = @embedFile("shaders/blit_ps.cso");

const ID3D11VertexShader = win32.graphics.direct3d11.ID3D11VertexShader;
const ID3D11PixelShader = win32.graphics.direct3d11.ID3D11PixelShader;
const D3D11_INPUT_ELEMENT_DESC = win32.graphics.direct3d11.D3D11_INPUT_ELEMENT_DESC;
const ID3D11InputLayout = win32.graphics.direct3d11.ID3D11InputLayout;
const D3D11_BUFFER_DESC = win32.graphics.direct3d11.D3D11_BUFFER_DESC;
const D3D11_SUBRESOURCE_DATA = win32.graphics.direct3d11.D3D11_SUBRESOURCE_DATA;
const ID3D11Buffer = win32.graphics.direct3d11.ID3D11Buffer;
const D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST = win32.graphics.direct3d.D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST;

const D3D11_USAGE_IMMUTABLE = win32.graphics.direct3d11.D3D11_USAGE_IMMUTABLE;
const D3D11_BIND_VERTEX_BUFFER = win32.graphics.direct3d11.D3D11_BIND_VERTEX_BUFFER;

const DXGI_FORMAT_R32G32B32_FLOAT = win32.graphics.dxgi.common.DXGI_FORMAT_R32G32B32_FLOAT;
const D3D11_INPUT_PER_VERTEX_DATA = win32.graphics.direct3d11.D3D11_INPUT_PER_VERTEX_DATA;

const GetClientRect = win32.user32.GetClientRect;

const ID3D11ShaderResourceView = win32.graphics.direct3d11.ID3D11ShaderResourceView;

const D3D11_SAMPLER_DESC = win32.graphics.direct3d11.D3D11_SAMPLER_DESC;
const ID3D11SamplerState = win32.graphics.direct3d11.ID3D11SamplerState;

const DXGI_FORMAT_UNKNOWN = win32.graphics.dxgi.common.DXGI_FORMAT_UNKNOWN;

const D3D11_USAGE_DEFAULT = win32.graphics.direct3d11.D3D11_USAGE_DEFAULT;

const D3D11_FILTER_MIN_MAX_MIP_LINEAR = win32.graphics.direct3d11.D3D11_FILTER_MIN_MAG_MIP_LINEAR;
const D3D11_TEXTURE_ADDRESS_CLAMP = win32.graphics.direct3d11.D3D11_TEXTURE_ADDRESS_CLAMP;
const D3D11_COMPARISON_NEVER = win32.graphics.direct3d11.D3D11_COMPARISON_NEVER;
const D3D11_FLOAT32_MAX = win32.graphics.direct3d11.D3D11_FLOAT32_MAX;

const D3D11_RASTERIZER_DESC = win32.graphics.direct3d11.D3D11_RASTERIZER_DESC;
const ID3D11RasterizerState = win32.graphics.direct3d11.ID3D11RasterizerState;

const D3D11_FILL_SOLID = win32.graphics.direct3d11.D3D11_FILL_SOLID;
const D3D11_CULL_NONE = win32.graphics.direct3d11.D3D11_CULL_NONE;

const IDXGIFactory = win32.graphics.dxgi.IDXGIFactory;
const IID_IDXGIFactory = win32.graphics.dxgi.IID_IDXGIFactory;

const DXGI_MWA_NO_ALT_ENTER = win32.graphics.dxgi.DXGI_MWA_NO_ALT_ENTER;

const MyDirectXContext = struct {
    backbuffer_rtv: ?*ID3D11RenderTargetView,

    game_rtv: *ID3D11RenderTargetView,

    device: *ID3D11Device,
    context: *ID3D11DeviceContext,
    swap_chain: *IDXGISwapChain,

    input_layout: *ID3D11InputLayout,
    vertex_buffer: *ID3D11Buffer,

    vertex_shader: *ID3D11VertexShader,
    pixel_shader: *ID3D11PixelShader,

    blit_vertex_shader: *ID3D11VertexShader,
    blit_pixel_shader: *ID3D11PixelShader,

    stride: u32,
    vb_offset: u32,
    world_clear_color: [4]f32,
    letterbox_color: [4]f32,
    null_srv: ?*ID3D11ShaderResourceView,

    game_srv: *ID3D11ShaderResourceView,

    sampler: *ID3D11SamplerState,

    rasterizer_state: *ID3D11RasterizerState,

    hwnd: HWND,

    game_viewport: D3D11_VIEWPORT,

    is_fullscreen: bool = false,
    windowed_style: u32 = 0, // WS_OVERLAPPEDWINDOW etc,
    windowed_rect: RECT = undefined,

    const Self = @This();
    fn deinit(self: *Self) void {
        self.context.ClearState();

        _ = self.sampler.IUnknown.Release();
        _ = self.game_rtv.IUnknown.Release();

        _ = self.game_srv.IUnknown.Release();

        _ = self.input_layout.IUnknown.Release();
        _ = self.vertex_buffer.IUnknown.Release();

        _ = self.vertex_shader.IUnknown.Release();
        _ = self.pixel_shader.IUnknown.Release();

        _ = self.blit_vertex_shader.IUnknown.Release();
        _ = self.blit_pixel_shader.IUnknown.Release();

        _ = self.rasterizer_state.IUnknown.Release();

        if (self.backbuffer_rtv) |backbuffer_rtv|
            _ = backbuffer_rtv.IUnknown.Release();

        _ = self.device.IUnknown.Release();
        _ = self.context.IUnknown.Release();
        _ = self.swap_chain.IUnknown.Release();
    }

    fn init(hwnd: HWND) !MyDirectXContext {
        const swap_chain_desc = DXGI_SWAP_CHAIN_DESC{
            .BufferDesc = .{
                .Width = @intCast(client_width),
                .Height = @intCast(client_height),
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

        var factory: *IDXGIFactory = undefined;
        hr = swap_chain.IDXGIObject.GetParent(IID_IDXGIFactory, @ptrCast(&factory));
        if (hr == HRESULT.S_OK) {
            _ = factory.MakeWindowAssociation(hwnd, DXGI_MWA_NO_ALT_ENTER);
            _ = factory.IUnknown.Release();
        }

        if (hr != HRESULT.S_OK) return error.D3D11DeviceCreationFailed;

        // --- Backbuffer render target view (recreated on every WM_SIZE) ---

        var back_buffer: *ID3D11Texture2D = undefined;
        var backbuffer_rtv: *ID3D11RenderTargetView = undefined;
        {
            hr = swap_chain.GetBuffer(0, IID_ID3D11Texture2D, @ptrCast(&back_buffer));
            if (hr != HRESULT.S_OK) return error.GetBackBufferFailed;
            defer _ = back_buffer.IUnknown.Release();

            hr = device.CreateRenderTargetView(@ptrCast(back_buffer), null, @ptrCast(&backbuffer_rtv));
            if (hr != HRESULT.S_OK) return error.CreateRTVFailed;
            errdefer _ = backbuffer_rtv.IUnknown.Release();
        }

        // --- Offscreen "game" render target: fixed at game_width x
        // game_height  for the lifetime of the program.
        var game_tex_desc = D3D11_TEXTURE2D_DESC{
            .Width = game_width,
            .Height = game_height,
            .MipLevels = 1,
            .ArraySize = 1,
            .Format = DXGI_FORMAT_R8G8B8A8_UNORM,
            .SampleDesc = .{ .Count = 1, .Quality = 0 },
            .Usage = D3D11_USAGE_DEFAULT,
            .BindFlags = .{ .RENDER_TARGET = 1, .SHADER_RESOURCE = 1 },
            .CPUAccessFlags = .{},
            .MiscFlags = .{},
        };

        var game_tex: *ID3D11Texture2D = undefined;
        hr = device.CreateTexture2D(&game_tex_desc, null, @ptrCast(&game_tex));
        if (hr != HRESULT.S_OK) return error.CreateGameTextureFailed;
        defer _ = game_tex.IUnknown.Release();

        var game_rtv: *ID3D11RenderTargetView = undefined;
        hr = device.CreateRenderTargetView(@ptrCast(game_tex), null, @ptrCast(&game_rtv));
        if (hr != HRESULT.S_OK) return error.CreateGameRTVFailed;
        errdefer _ = game_rtv.IUnknown.Release();

        var game_srv: *ID3D11ShaderResourceView = undefined;
        hr = device.CreateShaderResourceView(@ptrCast(game_tex), null, @ptrCast(&game_srv));
        if (hr != HRESULT.S_OK) return error.CreateGameSRVFailed;
        errdefer _ = game_srv.IUnknown.Release();

        const game_viewport = D3D11_VIEWPORT{
            .Width = game_width,
            .Height = game_height,
            .MinDepth = 0.0,
            .MaxDepth = 1.0,
            .TopLeftX = 0.0,
            .TopLeftY = 0.0,
        };

        var sampler_desc = D3D11_SAMPLER_DESC{
            .Filter = D3D11_FILTER_MIN_MAX_MIP_LINEAR,
            .AddressU = D3D11_TEXTURE_ADDRESS_CLAMP,
            .AddressV = D3D11_TEXTURE_ADDRESS_CLAMP,
            .AddressW = D3D11_TEXTURE_ADDRESS_CLAMP,
            .ComparisonFunc = D3D11_COMPARISON_NEVER,
            .MaxLOD = D3D11_FLOAT32_MAX,
            .MipLODBias = 0,
            .MaxAnisotropy = 0,
            .BorderColor = [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            .MinLOD = 0,
        };

        var sampler: *ID3D11SamplerState = undefined;
        hr = device.CreateSamplerState(&sampler_desc, @ptrCast(&sampler));
        if (hr != HRESULT.S_OK) return error.CreateSamplerFailed;
        errdefer _ = sampler.IUnknown.Release();

        var rasterizer_desc = D3D11_RASTERIZER_DESC{
            .FillMode = D3D11_FILL_SOLID,
            .CullMode = D3D11_CULL_NONE,
            .DepthClipEnable = TRUE,
            .AntialiasedLineEnable = FALSE,
            .DepthBias = FALSE,
            .DepthBiasClamp = FALSE,
            .FrontCounterClockwise = FALSE,
            .MultisampleEnable = FALSE,
            .ScissorEnable = FALSE,
            .SlopeScaledDepthBias = FALSE,
        };

        var rasterizer_state: *ID3D11RasterizerState = undefined;
        hr = device.CreateRasterizerState(&rasterizer_desc, @ptrCast(&rasterizer_state));
        if (hr != HRESULT.S_OK) return error.CreateRasterizerStateFailed;
        errdefer _ = rasterizer_state.IUnknown.Release();

        // Shader additions

        var vertex_shader: *ID3D11VertexShader = undefined;
        hr = device.CreateVertexShader(vs_bytecode, vs_bytecode.len, null, @ptrCast(&vertex_shader));
        if (hr != HRESULT.S_OK) return error.CreateVertexShaderFailed;
        errdefer _ = vertex_shader.IUnknown.Release();

        var pixel_shader: *ID3D11PixelShader = undefined;
        hr = device.CreatePixelShader(ps_bytecode, ps_bytecode.len, null, @ptrCast(&pixel_shader));
        if (hr != HRESULT.S_OK) return error.CreatePixelShaderFailed;
        errdefer _ = pixel_shader.IUnknown.Release();

        const input_element_descs = [_]D3D11_INPUT_ELEMENT_DESC{
            .{
                .SemanticName = "POSITION",
                .SemanticIndex = 0,
                .Format = DXGI_FORMAT_R32G32B32_FLOAT,
                .InputSlot = 0,
                .AlignedByteOffset = 0,
                .InputSlotClass = D3D11_INPUT_PER_VERTEX_DATA,
                .InstanceDataStepRate = 0,
            },
            .{
                .SemanticName = "COLOR",
                .SemanticIndex = 0,
                .Format = DXGI_FORMAT_R32G32B32_FLOAT,
                .InputSlot = 0,
                .AlignedByteOffset = 12, // 3 floats of POSITION
                .InputSlotClass = D3D11_INPUT_PER_VERTEX_DATA,
                .InstanceDataStepRate = 0,
            },
        };

        var input_layout: *ID3D11InputLayout = undefined;
        hr = device.CreateInputLayout(
            &input_element_descs,
            input_element_descs.len,
            vs_bytecode,
            vs_bytecode.len,
            @ptrCast(&input_layout),
        );
        if (hr != HRESULT.S_OK) return error.CreateInputLayoutFailed;
        errdefer _ = input_layout.IUnknown.Release();

        // --- Vertex buffer: one small hardcoded triangle, in NDC space already
        // (no view/projection matrix yet)
        const Vertex = extern struct {
            pos: [3]f32,
            color: [4]f32,
        };

        const vertices = [_]Vertex{
            .{ .pos = .{ 1.0, 1.0, 0.0 }, .color = .{ 1.0, 0.0, 0.0, 1.0 } },
            .{ .pos = .{ 1.0, -1.0, 0.0 }, .color = .{ 0.0, 1.0, 0.0, 1.0 } },
            .{ .pos = .{ -1.0, -1.0, 0.0 }, .color = .{ 0.0, 0.0, 1.0, 1.0 } },
        };

        var buffer_desc = D3D11_BUFFER_DESC{
            .ByteWidth = @sizeOf(@TypeOf(vertices)),
            .Usage = D3D11_USAGE_IMMUTABLE,
            .BindFlags = D3D11_BIND_VERTEX_BUFFER,
            .CPUAccessFlags = .{},
            .MiscFlags = .{},
            .StructureByteStride = 0,
        };

        var init_data = D3D11_SUBRESOURCE_DATA{
            .pSysMem = &vertices,
            .SysMemPitch = 0,
            .SysMemSlicePitch = 0,
        };

        var vertex_buffer: *ID3D11Buffer = undefined;
        hr = device.CreateBuffer(&buffer_desc, &init_data, @ptrCast(&vertex_buffer));
        if (hr != HRESULT.S_OK) return error.CreateVertexBufferFailed;
        errdefer _ = vertex_buffer.IUnknown.Release();

        // --- Blit Shaders (fullscreen triangle, no vertex buffer needed) ---
        var blit_vertex_shader: *ID3D11VertexShader = undefined;
        hr = device.CreateVertexShader(blit_vs_bytecode, blit_vs_bytecode.len, null, @ptrCast(&blit_vertex_shader));
        if (hr != HRESULT.S_OK) return error.CreateBlitVertexShaderFailed;
        errdefer _ = blit_vertex_shader.IUnknown.Release();

        var blit_pixel_shader: *ID3D11PixelShader = undefined;
        hr = device.CreatePixelShader(blit_ps_bytecode, blit_ps_bytecode.len, null, @ptrCast(&blit_pixel_shader));
        if (hr != HRESULT.S_OK) return error.CreateBlitPixelShaderFailed;
        errdefer _ = blit_pixel_shader.IUnknown.Release();

        const stride: u32 = @sizeOf(Vertex);
        const vb_offset: u32 = 0;
        const world_clear_color = [4]f32{ 0.10, 0.10, 0.35, 1.0 }; // dark blue
        const letterbox_color = [4]f32{ 0.0, 0.0, 0.0, 1.0 }; // black bars
        const null_srv: ?*ID3D11ShaderResourceView = null;

        return .{
            .game_viewport = game_viewport,
            .stride = stride,
            .vb_offset = vb_offset,
            .world_clear_color = world_clear_color,
            .letterbox_color = letterbox_color,
            .null_srv = null_srv,

            .game_srv = game_srv,

            .sampler = sampler,

            .rasterizer_state = rasterizer_state,

            .vertex_shader = vertex_shader,
            .pixel_shader = pixel_shader,

            .blit_vertex_shader = blit_vertex_shader,
            .blit_pixel_shader = blit_pixel_shader,

            .hwnd = hwnd,
            .vertex_buffer = vertex_buffer,
            .input_layout = input_layout,

            .backbuffer_rtv = backbuffer_rtv,
            .game_rtv = game_rtv,

            .context = context,
            .device = device,
            .swap_chain = swap_chain,
        };
    }

    fn draw(self: *Self) void {
        var client_rect: RECT = undefined;
        _ = GetClientRect(self.hwnd, &client_rect);
        const win_w = client_rect.right - client_rect.left;
        const win_h = client_rect.bottom - client_rect.top;
        if (win_w <= 0 or win_h <= 0) return; // minimized -- nothing to draw

        // --- Pass 1: render the world into the fixed-size game target ---
        var raw_rtvs = [_]?*ID3D11RenderTargetView{self.game_rtv};
        const rtvs: ?[*]?*ID3D11RenderTargetView = &raw_rtvs;
        self.context.OMSetRenderTargets(1, rtvs, null);
        self.context.RSSetViewports(1, @ptrCast(&self.game_viewport));
        self.context.RSSetState(self.rasterizer_state);
        self.context.ClearRenderTargetView(self.game_rtv, @ptrCast(&self.world_clear_color[0]));

        self.context.IASetInputLayout(self.input_layout);
        self.context.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

        const strides = &[_]u32{self.stride};
        const vb_offsets = &[_]u32{self.vb_offset};
        self.context.IASetVertexBuffers(0, 1, @ptrCast(&self.vertex_buffer), strides, vb_offsets);

        self.context.VSSetShader(self.vertex_shader, null, 0);
        self.context.PSSetShader(self.pixel_shader, null, 0);
        self.context.Draw(3, 0);

        // -- Pass 2: blit game target onto the backbuffer, integer-scaled
        // centered, with black bars for whatever doesn't divide evenly ---

        var raw_backbuffer_rtvs = [_]?*ID3D11RenderTargetView{self.backbuffer_rtv};
        const backbuffer_rtvs: ?[*]?*ID3D11RenderTargetView = &raw_backbuffer_rtvs;
        self.context.OMSetRenderTargets(1, backbuffer_rtvs, null);
        self.context.ClearRenderTargetView(self.backbuffer_rtv, @ptrCast(&self.letterbox_color[0]));

        const win_w_f: f32 = @floatFromInt(win_w);
        const win_h_f: f32 = @floatFromInt(win_h);
        const game_w_f: f32 = @floatFromInt(game_width);
        const game_h_f: f32 = @floatFromInt(game_height);

        //const scale_x = @divTrunc(win_w, @as(i32, @intCast(game_width)));
        //const scale_y = @divTrunc(win_h, @as(i32, @intCast(game_height)));
        //const scale = @max(1, @min(scale_x, scale_y));

        const scale = @min(win_w_f / game_w_f, win_h_f / game_h_f);

        //const out_w = @as(i32, @intCast(game_width)) * scale;
        //const out_h = @as(i32, @intCast(game_height)) * scale;
        const out_w = game_w_f * scale;
        const out_h = game_h_f * scale;

        //const offset_x = @divTrunc(win_w - out_w, 2);
        //const offset_y = @divTrunc(win_h - out_h, 2);

        const offset_x = (win_w_f - out_w) / 2.0;
        const offset_y = (win_h_f - out_h) / 2.0;

        const Last = struct {
            var w: i32 = -1;
            var h: i32 = -1;
        };
        if (win_w != Last.w or win_h != Last.h) {
            Last.w = win_w;
            Last.h = win_h;
            std.debug.print(
                "client={}x{} scale={} out={}x{} offset={},{}\n",
                .{ win_w, win_h, scale, out_w, out_h, offset_x, offset_y },
            );
        }

        var blit_viewport = D3D11_VIEWPORT{
            .TopLeftX = offset_x,
            .TopLeftY = offset_y,
            .Width = out_w,
            .Height = out_h,
            .MinDepth = 0,
            .MaxDepth = 1.0,
        };

        self.context.RSSetViewports(1, @ptrCast(&blit_viewport));

        self.context.IASetInputLayout(null);
        self.context.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        self.context.VSSetShader(self.blit_vertex_shader, null, 0);
        self.context.PSSetShader(self.blit_pixel_shader, null, 0);

        var raw_srv = [_]?*ID3D11ShaderResourceView{self.game_srv};
        const game_srvs: ?[*]?*ID3D11ShaderResourceView = &raw_srv;
        self.context.PSSetShaderResources(0, 1, game_srvs);

        var raw_sampler = [_]?*ID3D11SamplerState{self.sampler};
        const samplers: ?[*]?*ID3D11SamplerState = &raw_sampler;
        self.context.PSSetSamplers(0, 1, samplers);
        self.context.Draw(3, 0);

        // Unbind the SRV so game_tex is free to be used as a render target
        // again next frame -- a resource can't be bound as both at once.

        var null_srv = [_]?*ID3D11ShaderResourceView{self.null_srv};
        const null_srvs: ?[*]?*ID3D11ShaderResourceView = &null_srv;
        self.context.PSSetShaderResources(0, 1, null_srvs);

        _ = self.swap_chain.Present(1, 0); // 1 = vynsc on
    }

    fn toggleFullscreen(self: *Self) void {
        if (self.is_fullscreen) self.leaveFullscreen() else self.enterFullscreen();
    }

    fn enterFullscreen(self: *Self) void {
        if (self.is_fullscreen) return;
        self.windowed_style = @intCast(GetWindowLongPtrW(self.hwnd, GWL_STYLE));
        _ = GetWindowRect(self.hwnd, &self.windowed_rect);
        std.debug.print("ENTER RECT {}", .{self.windowed_rect});

        const mon = MonitorFromWindow(self.hwnd, MONITOR_DEFAULTTONEAREST);
        var mi: MONITORINFO = undefined;
        mi.cbSize = @sizeOf(MONITORINFO);
        _ = GetMonitorInfoW(mon, &mi);
        const flags = @as(u32, @bitCast(WINDOW_STYLE{ .POPUP = 1, .VISIBLE = 1 }));
        _ = SetWindowLongPtrW(self.hwnd, GWL_STYLE, @as(isize, @intCast(flags)));

        const w = mi.rcMonitor.right - mi.rcMonitor.left;
        const h = mi.rcMonitor.bottom - mi.rcMonitor.top;
        _ = SetWindowPos(
            self.hwnd,
            HWND_TOP,
            mi.rcMonitor.left,
            mi.rcMonitor.top,
            w,
            h,
            //SWP_NOZORDER | SWP_FRAMECHANGED,
            .{ .NOZORDER = 1, .DRAWFRAME = 1 },
        );

        self.is_fullscreen = true;
    }

    fn leaveFullscreen(self: *Self) void {
        if (!self.is_fullscreen) return;

        _ = SetWindowLongPtrW(self.hwnd, GWL_STYLE, self.windowed_style);
        const r = self.windowed_rect;
        std.debug.print("RECT {}", .{self.windowed_rect});
        _ = SetWindowPos(
            self.hwnd,
            null,
            r.left,
            r.top,
            r.right - r.left,
            r.bottom - r.top,
            .{ .NOZORDER = 1, .DRAWFRAME = 1 },
        );

        self.is_fullscreen = false;
    }
};
