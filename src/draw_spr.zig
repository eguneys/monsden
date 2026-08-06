const math = @import("math.zig");
const Rect = math.Rect;

pub const SpriteBatch = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        drawSprite: *const fn (ctx: *anyopaque, source_rect: Rect, dest_rect: Rect) void,
    };

    const Self = @This();
    pub fn draw_spr(self: Self, sx: f32, sy: f32, sw: f32, sh: f32, dx: f32, dy: f32, scale_x: f32, scale_y: f32) void {
        const source_rect: Rect = .{ .x = sx, .y = sy, .width = sw, .height = sh };
        const dest_rect: Rect = .{ .x = dx, .y = dy, .width = sw * scale_x, .height = sh * scale_y };
        self.vtable.drawSprite(source_rect, dest_rect);
    }
};
