const SpriteBatch = @import("draw_spr.zig").SpriteBatch;

pub const Scene = struct {
    batch: SpriteBatch,

    const Self = @This();
    pub fn init(batch: SpriteBatch) Self {
        return .{ .batch = batch };
    }

    pub fn update(self: *Self, dt: f32) void {
        _ = self;
        _ = dt;
    }

    pub fn render(self: *Self) void {
        _ = self;
    }
};
