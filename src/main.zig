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

const ID3D11RenderTargetView = win32.graphics.direct3d11.ID3D11RenderTargetView;

const D3D11_VIEWPORT = win32.graphics.direct3d11.D3D11_VIEWPORT;

const DXGI_FORMAT_R8G8B8A8_UNORM = win32.graphics.dxgi.common.DXGI_FORMAT_R8G8B8A8_UNORM;
const DXGI_SWAP_EFFECT_DISCARD = win32.graphics.dxgi.DXGI_SWAP_EFFECT_DISCARD;

const TRUE = win32.foundation.TRUE;

const HRESULT = win32.zig.HRESULT;

const DXGI_USAGE_RENDER_TARGET_OUTPUT = win32.graphics.dxgi.DXGI_USAGE_RENDER_TARGET_OUTPUT;

const vs_bytecode = @embedFile("shaders/triangle_vs.cso");
const ps_bytecode = @embedFile("shaders/triangle_ps.cso");

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

const MyDirectXContext = struct {
    back_buffer: *ID3D11Texture2D,
    rtv: *ID3D11RenderTargetView,
    device: *ID3D11Device,
    context: *ID3D11DeviceContext,
    swap_chain: *IDXGISwapChain,

    input_layout: *ID3D11InputLayout,
    vertex_buffer: ID3D11Buffer,

    const Self = @This();
    fn deinit(self: *Self) void {
        _ = self.back_buffer.IUnknown.Release();
        _ = self.rtv.IUnknown.Release();

        _ = self.context.IUnknown.Release();
        _ = self.device.IUnknown.Release();
        _ = self.swap_chain.IUnknown.Release();
        _ = self.input_layout.IUnknown.Release();
        _ = self.vertex_buffer.IUnknown.Release();
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

        // Shader additions

        var vertex_shader: *ID3D11VertexShader = undefined;
        hr = device.CreateVertexShader(vs_bytecode, vs_bytecode.len, null, @ptrCast(&vertex_shader));
        if (hr != HRESULT.S_OK) return error.CreateVertexShaderFailed;
        defer _ = vertex_shader.IUnknown.Release();

        var pixel_shader: *ID3D11PixelShader = undefined;
        hr = device.CreatePixelShader(ps_bytecode, ps_bytecode.len, null, @ptrCast(&pixel_shader));
        if (hr != HRESULT.S_OK) return error.CreatePixelShaderFailed;
        defer _ = pixel_shader.IUnknown.Release();

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
            .{ .pos = .{ 0.0, 0.5, 0.0 }, .color = .{ 1.0, 0.0, 0.0, 1.0 } },
            .{ .pos = .{ 0.0, -0.5, 0.0 }, .color = .{ 0.0, 1.0, 0.0, 1.0 } },
            .{ .pos = .{ -0.5, -0.5, 0.0 }, .color = .{ 0.0, 0.0, 1.0, 1.0 } },
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

        var vertex_buffer: ID3D11Buffer = undefined;
        hr = device.CreateBuffer(&buffer_desc, &init_data, @ptrCast(&vertex_buffer));
        if (hr != HRESULT.S_OK) return error.CreateVertexBufferFailed;
        errdefer _ = vertex_buffer.IUnknown.Release();

        // Everything above is set once; only Clear/Draw/Present repeat per frame.

        context.IASetInputLayout(input_layout);
        context.IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
        const stride: u32 = @sizeOf(Vertex);
        const offset: u32 = 0;
        context.IASetVertexBuffers(0, 1, @ptrCast(&vertex_buffer), &.{stride}, &.{offset});
        context.VSSetShader(vertex_shader, null, 0);
        context.PSSetShader(pixel_shader, null, 0);

        return .{
            .vertex_buffer = vertex_buffer,
            .input_layout = input_layout,
            .back_buffer = back_buffer,
            .rtv = rtv,
            .context = context,
            .device = device,
            .swap_chain = swap_chain,
        };
    }

    fn draw(self: Self) void {
        var clear_color = [4]f32{ 0.10, 0.10, 0.35, 1.0 }; // dark blue
        // ClearRenderTargetView expects an optional pointer to f32 (RGBA),
        // so pass a pointer to the first element and cast to the expected type.
        self.context.ClearRenderTargetView(self.rtv, @ptrCast(&clear_color[0]));
        self.context.Draw(3, 0);

        _ = self.swap_chain.Present(1, 0); // 1 = vynsc on
    }
};
