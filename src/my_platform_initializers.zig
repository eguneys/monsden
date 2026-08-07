const Camera = @import("camera.zig");
const math = @import("math.zig");
const Rect = math.Rect;

const DebugBatch = @import("draw_spr.zig").DebugBatch;
const SpriteBatch = @import("draw_spr.zig").SpriteBatch;
const GamePlatform = @import("loop.zig").GamePlatform;

const MyPlatform = @import("my_directx_windows.zig").MyPlatform;

pub const MyDebugBatch = struct {
    const Self = @This();

    platform: MyPlatform,

    fn drawLineImpl(ctx: *anyopaque, p0: [2]f32, p1: [2]f32, color: [4]f32) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.debug.drawLine(p0, p1, color);
    }

    const vtable = DebugBatch.VTable{
        .drawLine = drawLineImpl,
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
    fn drawBgImpl(ctx: *anyopaque, source_rect: Rect, dest_rect: Rect) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        self.platform.batch.drawSprite(&self.platform.resources.texBackground, source_rect, dest_rect) catch unreachable;
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

pub const MyGamePlatform = struct {
    platform: MyPlatform,

    batch: MySpriteBatch,
    debug: MyDebugBatch,

    camera: Camera,

    pub fn deinit(self: *Self) void {
        self.platform.deinit();
        self.debug.deinit();
    }

    pub fn init(platform: MyPlatform) Self {
        return .{
            .camera = .init(0, 0),
            .platform = platform,
            .batch = .{ .platform = platform },
            .debug = .{ .platform = platform },
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
    fn beginDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.platform.beginDraw();
    }
    fn endDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        return self.platform.endDraw();
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

    fn beginDebugDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.platform.debug.beginBatch() catch unreachable;
    }
    fn endDebugDrawImpl(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));

        return self.platform.debug.flush(self.camera) catch unreachable;
    }

    const vtable = GamePlatform.VTable{
        .peekMessages = peekMessagesImpl,
        .toggleFullscreen = toggleFullscreenImpl,
        .beginDraw = beginDrawImpl,
        .endDraw = endDrawImpl,
        .onResize = onResizeImpl,
        .deinit = deinitImpl,
        .spriteBatch = spriteBatchImpl,
        .debugBatch = debugBatchImpl,
        .beginDebugDraw = beginDebugDrawImpl,
        .endDebugDraw = endDebugDrawImpl,
    };

    pub fn getPlatform(self: *MyGamePlatform) GamePlatform {
        return .{
            .ptr = self,
            .vtable = &vtable,
        };
    }
};
