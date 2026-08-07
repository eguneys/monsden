const math = @import("math.zig");
const Rect = math.Rect;

pub const SpriteBatch = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        drawSprite: *const fn (ctx: *anyopaque, source_rect: Rect, dest_rect: Rect) void,
        drawBg: *const fn (ctx: *anyopaque, source_rect: Rect, dest_rect: Rect) void,
    };

    const Self = @This();
    pub fn draw_spr(self: Self, sx: f32, sy: f32, sw: f32, sh: f32, dx: f32, dy: f32, scale_x: f32, scale_y: f32) void {
        const source_rect: Rect = .{ .x = sx, .y = sy, .width = sw, .height = sh };
        const dest_rect: Rect = .{ .x = dx, .y = dy, .width = sw * scale_x, .height = sh * scale_y };
        self.vtable.drawSprite(self.ptr, source_rect, dest_rect);
    }
    pub fn draw_bg(self: Self, sx: f32, sy: f32, sw: f32, sh: f32, dx: f32, dy: f32, scale_x: f32, scale_y: f32) void {
        const source_rect: Rect = .{ .x = sx, .y = sy, .width = sw, .height = sh };
        const dest_rect: Rect = .{ .x = dx, .y = dy, .width = sw * scale_x, .height = sh * scale_y };
        self.vtable.drawBg(self.ptr, source_rect, dest_rect);
    }
};

pub const DebugBatch = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        drawLine: *const fn (ctx: *anyopaque, p0: [2]f32, p1: [2]f32, color: [4]f32) void,
        drawRect: *const fn (ctx: *anyopaque, min: [2]f32, max: [2]f32, color: [4]f32) void,
        drawCircle: *const fn (ctx: *anyopaque, center: [2]f32, radius: f32, color: [4]f32) void,
    };

    const Self = @This();
    pub fn draw_line(self: Self, x0: f32, y0: f32, x1: f32, y1: f32) void {
        self.vtable.drawLine(self.ptr, .{ x0, y0 }, .{ x1, y1 }, .{ 0.0, 0.0, 0.0, 1.0 });
    }
    pub fn draw_rect(self: Self, x0: f32, y0: f32, w: f32, h: f32) void {
        self.vtable.drawRect(self.ptr, .{ x0, y0 }, .{ x0 + w, y0 + h }, .{ 0.0, 0.0, 0.0, 1.0 });
    }
    pub fn draw_circle(self: Self, x0: f32, y0: f32, r: f32) void {
        self.vtable.drawCircle(self.ptr, .{ x0, y0 }, r, .{ 0.0, 0.0, 0.0, 1.0 });
    }
};
