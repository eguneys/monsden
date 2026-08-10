const Input = @import("input.zig");
const Camera = @import("camera.zig");
const math = @import("math.zig");
const Rect = math.Rect;

const ds = @import("draw_spr.zig");
const FontBatch = ds.FontBatch;
const DebugBatch = ds.DebugBatch;
const SpriteBatch = ds.SpriteBatch;
const ParallaxBatch = ds.ParallaxBatch;

const GamePlatform = @import("loop.zig").GamePlatform;
const KeyboardState = @import("loop.zig").KeyboardState;

const MyPlatform = @import("my_directx_windows.zig").MyPlatform;

pub const MyDebugBatch = struct {
    const Self = @This();

    platform: MyPlatform,

    fn drawLineImpl(ctx: *anyopaque, p0: [2]f32, p1: [2]f32, color: [4]f32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.debug.drawLine(p0, p1, color);
    }

    fn drawRectImpl(ctx: *anyopaque, min: [2]f32, max: [2]f32, color: [4]f32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.debug.drawRect(min, max, color);
    }
    fn drawCircleImpl(ctx: *anyopaque, center: [2]f32, radius: f32, color: [4]f32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.debug.drawCircle(center, radius, color);
    }

    const vtable = DebugBatch.VTable{
        .drawLine = drawLineImpl,
        .drawRect = drawRectImpl,
        .drawCircle = drawCircleImpl,
    };

    pub fn debugBatch(self: *Self) DebugBatch {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

pub const MySpriteBatch = struct {
    const Self = @This();

    platform: MyPlatform,

    fn drawSpriteImpl(ctx: *anyopaque, source_rect: Rect, dest_rect: Rect) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.batch.drawSprite(&self.platform.resources.texSprites, source_rect, dest_rect) catch unreachable;
    }
    fn drawBgImpl(ctx: *anyopaque, bg_index: u32, camera: Camera) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        //self.platform.batch.drawSprite(&self.platform.resources.texBackground, source_rect, dest_rect) catch unreachable;
        self.platform.parallax.drawBackground(bg_index, self.platform.world_resources.backgrounds[bg_index], camera) catch unreachable;
    }

    const vtable = SpriteBatch.VTable{
        .drawSprite = drawSpriteImpl,
        .drawBg = drawBgImpl,
    };

    pub fn spriteBatch(self: *Self) SpriteBatch {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

pub const MyFontBatch = struct {
    const Self = @This();

    platform: MyPlatform,

    fn drawTextImpl(ctx: *anyopaque, x: f32, y: f32, text: []const u8) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        const color: [4]f32 = .{ 0.0, 0.0, 0.0, 1.0 };

        self.platform.font_batch.drawText(&self.platform.resources.texFontAtlas, &self.platform.resources.fontRasterizer.atlas_table, x, y, text, color) catch unreachable;
    }

    const vtable = FontBatch.VTable{
        .drawText = drawTextImpl,
    };

    pub fn fontBatch(self: *Self) FontBatch {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

pub const MyParallaxBatch = struct {
    const Self = @This();

    platform: MyPlatform,

    fn drawBgImpl(ctx: *anyopaque, bg_index: u32, camera: Camera) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.parallax.SetShaderResourceForTexture(&self.platform.resources.texBackground);
        self.platform.parallax.drawBackground(bg_index, self.platform.world_resources.backgrounds[bg_index], camera) catch unreachable;
    }

    const vtable = ParallaxBatch.VTable{
        .drawBg = drawBgImpl,
    };

    pub fn parallaxBatch(self: *Self) ParallaxBatch {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

pub const MyGamePlatform = struct {
    platform: MyPlatform,

    batch: MySpriteBatch,
    debug: MyDebugBatch,
    font: MyFontBatch,
    parallax: MyParallaxBatch,

    pub fn deinit(self: *Self) void {
        self.platform.deinit();
        self.debug.deinit();
    }

    pub fn init(platform: MyPlatform) Self {
        return .{
            .platform = platform,
            .batch = .{ .platform = platform },
            .debug = .{ .platform = platform },
            .font = .{ .platform = platform },
            .parallax = .{ .platform = platform },
        };
    }

    const Self = @This();
    fn peekMessagesImpl(ctx: *anyopaque) bool {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;

        return MyPlatform.peekMessages();
    }

    fn toggleFullscreenImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        return self.platform.cx.toggleFullscreen();
    }
    fn beginDrawImpl(ctx: *anyopaque, camera: Camera) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.cx.beginPass1(camera) catch unreachable;
    }
    fn endDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.platform.cx.endPass3();
    }
    fn beginPass3Impl(ctx: *anyopaque, camera: Camera) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.cx.beginPass3(camera) catch unreachable;
    }

    fn drawPass2Impl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.cx.drawPass2();
    }
    fn drawPass3Impl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.cx.drawPass3();
    }

    fn onResizeImpl(ctx: *anyopaque, new_width: u32, new_height: u32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        return self.platform.cx.onResize(new_width, new_height);
    }

    fn deinitImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.deinit();
    }

    fn spriteBatchImpl(ctx: *anyopaque) SpriteBatch {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.batch.spriteBatch();
    }

    fn debugBatchImpl(ctx: *anyopaque) DebugBatch {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.debug.debugBatch();
    }
    fn fontBatchImpl(ctx: *anyopaque) FontBatch {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.font.fontBatch();
    }
    fn parallaxBatchImpl(ctx: *anyopaque) ParallaxBatch {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.parallax.parallaxBatch();
    }

    fn beginParallaxDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.parallax.beginBatch();
    }

    fn beginFontDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.font_batch.beginBatchSetupState() catch unreachable;
        self.platform.font_batch.beginBatch() catch unreachable;
    }
    fn endFontDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.font_batch.endBatch() catch unreachable;
    }

    fn beginDebugDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.platform.debug.beginBatch() catch unreachable;
    }
    fn endDebugDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        return self.platform.debug.flush() catch unreachable;
    }

    fn beginSpriteDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.batch.beginBatchSetupState() catch unreachable;
        self.platform.batch.beginBatch() catch unreachable;
    }
    fn endSpriteDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.batch.endBatch() catch unreachable;
    }

    fn onKeyboardSnapshotImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.keyboard.snapshot();
    }

    fn onKeyDownImpl(ctx: *anyopaque, vk: usize) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.keyboard.current[vk] = true;
    }

    fn onKeyUpImpl(ctx: *anyopaque, vk: usize) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.keyboard.current[vk] = false;
    }
    fn onKillFocusImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.platform.keyboard.killFocus();
    }
    fn addInputMappingsImpl(ctx: *const anyopaque, input: *Input) void {
        _ = ctx;
        MyAddInputMappings(input);
    }
    fn keyboardStateImpl(ctx: *anyopaque) *KeyboardState {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.platform.keyboard;
    }

    const vtable = GamePlatform.VTable{
        .peekMessages = peekMessagesImpl,
        .toggleFullscreen = toggleFullscreenImpl,
        .beginDraw = beginDrawImpl,
        .endDraw = endDrawImpl,
        .beginPass3 = beginPass3Impl,
        .drawPass2 = drawPass2Impl,
        .drawPass3 = drawPass3Impl,

        .onResize = onResizeImpl,
        .deinit = deinitImpl,
        .spriteBatch = spriteBatchImpl,
        .debugBatch = debugBatchImpl,
        .fontBatch = fontBatchImpl,
        .parallaxBatch = parallaxBatchImpl,

        .beginParallaxDraw = beginParallaxDrawImpl,

        .beginFontDraw = beginFontDrawImpl,
        .endFontDraw = endFontDrawImpl,
        .beginDebugDraw = beginDebugDrawImpl,
        .endDebugDraw = endDebugDrawImpl,
        .beginSpriteDraw = beginSpriteDrawImpl,
        .endSpriteDraw = endSpriteDrawImpl,

        .onKeyboardSnapshot = onKeyboardSnapshotImpl,
        .onKeyDown = onKeyDownImpl,
        .onKeyUp = onKeyUpImpl,
        .onKillFocus = onKillFocusImpl,

        .addInputMappings = addInputMappingsImpl,
        .keyboardState = keyboardStateImpl,
    };

    pub fn getPlatform(self: *MyGamePlatform) GamePlatform {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};

const win32 = @import("win32/zigwin32/win32.zig");

const VK_W = win32.ui.input.keyboard_and_mouse.VK_W;
const VK_A = win32.ui.input.keyboard_and_mouse.VK_A;
const VK_S = win32.ui.input.keyboard_and_mouse.VK_S;
const VK_D = win32.ui.input.keyboard_and_mouse.VK_D;
const VK_J = win32.ui.input.keyboard_and_mouse.VK_J;
const VK_I = win32.ui.input.keyboard_and_mouse.VK_I;
const VK_Q = win32.ui.input.keyboard_and_mouse.VK_Q;

fn MyAddInputMappings(input: *Input) void {
    input.add_keymapping(@intFromEnum(VK_A), Input.Action.Run_Left);
    input.add_keymapping(@intFromEnum(VK_D), Input.Action.Run_Right);
    input.add_keymapping(@intFromEnum(VK_J), Input.Action.Jump_Up);
    input.add_keymapping(@intFromEnum(VK_Q), Input.Action.Quit);
}
